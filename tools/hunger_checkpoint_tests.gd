class_name HungerCheckpointTests
extends RefCounted

static func held_load() -> ColonyWorld:
	return ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/content7-work/held-load.brackenward")).world

static func cook_fixture() -> ColonyWorld:
	var world: ColonyWorld = ColonyTests.world()
	var person: Dictionary = world.citizens[0]
	world._make_stack("berry",4,"ground",0,Vector2i(person.x,person.y),true)
	var hearth: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	var recipe: Dictionary = world.definitions.recipes.cook_meals
	var job: Dictionary = world._job("cook","Cooking","Cooking",hearth.id,Vector2i(hearth.x,hearth.y),recipe.work_milli)
	job.inputs={"berry":4,"wood":1};job.output=recipe.outputs.duplicate()
	assert(world._reserve(job,person));person.job=job.id
	return world

static func run(check: Callable) -> void:
	var world: ColonyWorld = held_load();var person: Dictionary = world.citizens[0]
	var job: Dictionary = world.find(world.jobs,person.job)
	world._assign(person)
	check.call("HUNGER/loaded_hauler_keeps_delivery_and_its_reservations",person.job==job.id and job.state=="Delivering" and world._food_load(person,job))
	for index in range(500):
		if person.job!=job.id: break
		world._work(person,job)
	world._assign(person)
	check.call("HUNGER/hauler_deposits_whole_load_then_eats",job.state=="Complete" and world.find(world.jobs,person.job).get("kind")=="eat" and world.stacks.any(func(s:Dictionary)->bool:return s.item=="stone" and s.count==8 and s.location=="store") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=cook_fixture();person=world.citizens[0];job=world.find(world.jobs,person.job)
	for index in range(500):
		world._work(person,job)
		if world._food_load(person,job): break
	var held: int = 0
	for stack in world.stacks:
		if stack.location=="carry" and stack.owner==person.id: held+=stack.count
	person.fullness=300;world._assign(person)
	check.call("HUNGER/mixed_input_fetch_delivers_partial_armload_before_eating",held>0 and held<5 and person.job==job.id and job.state=="Delivering")
	for index in range(500):
		if person.job!=job.id: break
		world._work(person,job)
	var escrow: int = 0
	for stack in world.stacks:
		if stack.location=="escrow" and stack.owner==job.id: escrow+=stack.count
	check.call("HUNGER/eats_at_exact_deposit_before_another_pickup_or_work_tick",world.find(world.jobs,person.job).get("kind")=="eat" and job.state=="Ready" and job.work==0 and escrow==held and not world._food_load(person,job) and world.invariant_errors().is_empty(),str([escrow,held,job.state,world.invariant_errors()]))
	world=cook_fixture();person=world.citizens[0];job=world.find(world.jobs,person.job)
	for index in range(1000):
		world._work(person,job)
		if job.state=="Working": break
	var meals_before: int = world.ledger.produced.get("meal",0)
	job.work=job.required-100;person.fullness=300
	world._assign(person)
	check.call("HUNGER/cook_finishes_started_batch_before_meal",person.job==job.id and job.state=="Working")
	for index in range(20):
		if job.state=="Complete": break
		world._work(person,job)
	world._assign(person)
	check.call("HUNGER/finished_batch_commits_inputs_output_once_then_eats",job.state=="Complete" and world.ledger.produced.meal-meals_before==job.output.meal and world.find(world.jobs,person.job).get("kind")=="eat" and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	for kind in ["build","research"]:
		world=ColonyTests.world();person=world.citizens[0];person.fullness=300
		job=world._job(kind,"Building" if kind=="build" else "Research","Build" if kind=="build" else "Study",0,Vector2i(person.x,person.y),100000)
		job.worker=person.id;person.job=job.id;job.state="Working";job.work=950
		if kind=="build": job.definition="wood_floor"
		if kind=="research": job.definition="storecraft";world.production_state.project=job.definition;world.production_state.progress[job.definition]=950
		world._assign(person)
		check.call("HUNGER/"+kind+"_finishes_current_fractional_wu",person.job==job.id)
		world._work(person,job)
		check.call("HUNGER/"+kind+"_stops_at_next_wu_retaining_progress_and_xp",job.state=="Ready" and job.work>=1000 and job.work<2000 and job.pending_xp.get(person.id,0)>0 and world.find(world.jobs,person.job).get("kind")=="eat")
	for urgent in ["starving","exhausted","emergency"]:
		world=held_load();person=world.citizens[0];job=world.find(world.jobs,person.job)
		if urgent=="starving": person.fullness=0
		elif urgent=="exhausted": person.rest=100
		else: ColonyCare.hurt(world,world.citizens[1],90,true);ColonyCare.create_jobs(world)
		world._assign(person)
		check.call("HUNGER/"+urgent+"_still_interrupts_loaded_delivery",person.job!=job.id and job.worker==0 and not world._food_load(person,job) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=held_load();person=world.citizens[0];job=world.find(world.jobs,person.job)
	for stack in world.stacks:
		if stack.item=="meal": world._record("consumed","meal",stack.count);stack.count=0
	world._assign(person)
	check.call("HUNGER/no_feasible_food_pauses_unrelated_delivery_with_clear_reason",person.job==0 and job.worker==0 and person.activity.begins_with("Hungry:"))
	world=held_load();var twin: ColonyWorld=ColonyCodec.decode(ColonyCodec.encode(world)).world
	for index in range(800): world.step();twin.step()
	check.call("HUNGER/save_mid_delivery_continues_identically_and_eats",world.canonical_hash()==twin.canonical_hash() and world.citizens[0].fullness>350 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
