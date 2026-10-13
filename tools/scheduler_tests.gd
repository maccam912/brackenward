class_name SchedulerTests
extends RefCounted

static func run(check: Callable) -> void:
	var ordered: ColonyWorld = ColonyTests.world()
	var reversed: ColonyWorld = ColonyTests.world()
	reversed.citizens.reverse()
	for index in range(20): ordered.step();reversed.step()
	check.call("SCHED/citizen_storage_order_does_not_change_tick_results",ordered.canonical_hash()==reversed.canonical_hash())
	automatic_cooking(check)
	var world: ColonyWorld = ColonyTests.world()
	var person: Dictionary = world.citizens[0]
	world.tick=24*7200;world.weather="cold_snap";person.x=90;person.y=90
	var eating: Dictionary = world._job("eat","","",person.id,Vector2i(90,90),2000)
	var progress: int = 0
	for index in range(20): progress+=world._rate(person,eating)
	check.call("SCHED/eating_takes_two_unmodified_wu_even_when_cold",progress==2000,str(progress))
	world=ColonyTests.world();person=world.citizens[0];person.drafted=true;person.break_until=world.tick+1800
	world._assign(person)
	check.call("SCHED/taking_break_cannot_be_overridden_by_drafting",world.find(world.jobs,person.job).get("kind")=="leisure",str(world.find(world.jobs,person.job).get("kind")))
	world=ColonyTests.world();person=world.citizens[0];person.drafted=true;person.stand_fast=true;person.health=30
	world._assign(person)
	check.call("SCHED/stand_fast_between_twenty_and_forty_honors_explicit_squad_order",world.find(world.jobs,person.job).get("kind")=="defend",str(world.find(world.jobs,person.job).get("kind")))
	world=ColonyTests.world();person=world.citizens[0];person.drafted=true;person.fullness=300
	world._assign(person)
	check.call("SCHED/drafted_defense_precedes_ordinary_hunger",world.find(world.jobs,person.job).get("kind")=="defend",str(world.find(world.jobs,person.job).get("kind")))
	world=ColonyTests.world();person=world.citizens[0];person.drafted=true;person.fullness=0
	world._assign(person)
	check.call("SCHED/critical_hunger_still_precedes_drafted_defense",world.find(world.jobs,person.job).get("kind")=="eat")
	world=ColonyTests.world();person=world.citizens[0];person.drafted=true;person.rally=Vector2i(69,65);person.x=69;person.y=65
	DefenseTests.raid(world);world.defense_state.enemies[0].x=70;world.defense_state.enemies[0].y=65;world.danger_cache_tick=-1
	world._assign(person)
	check.call("SCHED/fresh_draft_inside_danger_starts_defending_without_a_flee_detour",world.find(world.jobs,person.job).get("kind")=="defend")
	world=ColonyTests.world();person=world.citizens[0];person.rest=500
	var sleep_job: Dictionary = world._job("sleep","","",person.bed,Vector2i(person.x,person.y),0)
	sleep_job.worker=person.id;sleep_job.state="Working";person.job=sleep_job.id
	ColonyCare.hurt(world,world.citizens[1],90,true);ColonyCare.create_jobs(world)
	world._assign(person)
	check.call("SCHED/emergency_rescue_interrupts_noncritical_sleep",world.find(world.jobs,person.job).get("emergency",false),str(world.find(world.jobs,person.job).get("kind")))
	world=ColonyTests.world();world.tick=5400;person=world.citizens[0];person.preferences.Building=0
	var unrelated: Dictionary = world._job("build","Building","Build",0,Vector2i(74,74),16000);unrelated.priority=3
	world._assign(person)
	check.call("SCHED/urgent_disabled_category_cannot_suppress_leisure",world.find(world.jobs,person.job).get("kind")=="leisure")
	world=ColonyTests.world();world.tick=5400;person=world.citizens[0]
	unrelated=world._job("build","Building","Build",0,Vector2i(74,74),16000);unrelated.priority=3;unrelated.definition="bed";unrelated.inputs={"iron":1}
	world._assign(person)
	check.call("SCHED/urgent_missing_inputs_cannot_suppress_leisure",world.find(world.jobs,person.job).get("kind")=="leisure" and unrelated.state=="Blocked",str(world.find(world.jobs,person.job).get("kind")))
	work_position(check)
	reachable_food(check)
	confined_escape(check)

static func automatic_cooking(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var hearth: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	var person: Dictionary = world.citizens[0]
	# Exercise the actual hauling lifecycle, which leaves emptied source records.
	for index in range(2):
		var batch: Dictionary = world._make_stack("meal",2,"output",hearth.id,Vector2i(hearth.x,hearth.y),true)
		var haul: Dictionary = world._job("haul","Hauling","",batch.id,Vector2i(batch.x,batch.y),0);haul.source=batch.id
		var reserved: bool = world._reserve(haul,person)
		check.call("SCHED/empty_output_fixture_haul_%d_reserves" % index,reserved)
		if not reserved: return
		person.job=haul.id;person.x=batch.x;person.y=batch.y;person.progress=0
		world._work(person,haul)
		person.x=haul.work_x;person.y=haul.work_y;person.progress=0;world._work(person,haul)
		check.call("SCHED/empty_output_fixture_haul_%d_finishes" % index,haul.state=="Complete" and batch.count==0 and batch.location=="output")
	for stack in world.stacks:
		if stack.item=="meal": world._record("consumed","meal",stack.count);stack.count=0
	world._make_stack("berry",8,"ground",0,Vector2i(66,63),true)
	world._create_work()
	check.call("SCHED/automatic_hearth_restarts_after_two_emptied_batches",world.jobs.any(func(j:Dictionary)->bool:return j.kind=="cook" and j.state=="Ready") and world.invariant_errors().is_empty(),str(world.invariant_errors()))

static func work_position(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var person: Dictionary = world.citizens[0]
	person.x=48;person.y=70
	var resource: Dictionary = world.resources[0];resource.x=70;resource.y=70;world.navigation_dirty=true
	var fuel: Dictionary = world._make_stack("wood",20,"ground",0,Vector2i(61,70),true)
	ColonyFire.ignite(world,"stack",fuel.id)
	var gather: Dictionary = world._job("gather","Gathering","Field",resource.id,Vector2i(70,70),16000)
	var accepted: bool = world._reserve(gather,person)
	check.call("SCHED/unsafe_nearest_position_does_not_hide_safe_work_position",accepted and ColonyDanger.safe(world,Vector2i(gather.work_x,gather.work_y)),gather.reason)

static func reachable_food(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var person: Dictionary = world.citizens[0]
	var inaccessible: Dictionary = world._make_stack("meal",1,"ground",0,Vector2i(90,90),true);inaccessible.age=100
	for delta in ColonyNavigation.NEIGHBORS: world._structure("stone_wall",Vector2i(90,90)+delta,0)
	world.navigation_dirty=true
	var food: Dictionary = world._food(person)
	check.call("SCHED/unreachable_old_food_does_not_hide_available_meals",not food.is_empty() and food.id!=inaccessible.id and world.accessible(Vector2i(food.x,food.y)),str(food.get("id",0)))

static func confined_escape(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var person: Dictionary = world.citizens[0]
	for x in range(80,85):
		world._structure("stone_wall",Vector2i(x,79),0);world._structure("stone_wall",Vector2i(x,81),0)
	world._structure("stone_wall",Vector2i(79,80),0);world._structure("stone_wall",Vector2i(85,80),0)
	world.navigation_dirty=true;person.x=80;person.y=80
	var fuel: Dictionary = world._make_stack("wood",20,"ground",0,Vector2i(80,80),true);ColonyFire.ignite(world,"stack",fuel.id)
	var escaped: bool = ColonyDanger.escape(world,person)
	var job: Dictionary = world.find(world.jobs,person.job)
	check.call("SCHED/confined_resident_moves_to_safest_reachable_tile",escaped and job.get("kind")=="escape" and Vector2i(job.x,job.y)==Vector2i(84,80),str(job))
	if escaped:
		world._release(job,true);person.x=84;person.y=80
		check.call("SCHED/safest_confined_tile_explains_need_for_an_exit",not ColonyDanger.escape(world,person) and person.activity.contains("clear an exit"))
