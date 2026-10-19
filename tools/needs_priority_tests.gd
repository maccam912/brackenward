class_name NeedsPriorityTests
extends RefCounted
## Controlled need values verify scheduling; these are not colony balance runs.

static func remove_food(world: ColonyWorld) -> void:
	for stack in world.stacks:
		if world.definitions.items[stack.item].fullness>0:
			world._record("consumed",stack.item,stack.count);stack.count=0

static func working_wall(world: ColonyWorld) -> Dictionary:
	world.queue_command("build",{"definition":"wood_wall","x":74,"y":63,"rotation":0})
	for index in range(500):
		world.step()
		for job in world.jobs:
			if job.kind=="build" and job.state=="Working" and job.work>0: return job
	assert(false,"Fixture never started building")
	return {}

static func run(check: Callable) -> void:
	DepletedNeedsTests.run(check)
	for fullness in [350,0]:
		var world: ColonyWorld=ColonyTests.world();var wall: Dictionary=working_wall(world)
		var person: Dictionary=world.find(world.citizens,wall.worker)
		person.fullness=fullness;var before: int=wall.work;world._assign(person,true)
		check.call("NEEDS/hunger_interrupts_owned_wall_%d" % fullness,world.find(world.jobs,person.job).get("kind")=="eat" and wall.worker==0 and wall.work==before and world.invariant_errors().is_empty())
	for rest in [300,100,0]:
		var world: ColonyWorld=ColonyTests.world();var wall: Dictionary=working_wall(world)
		var person: Dictionary=world.find(world.citizens,wall.worker);person.rest=rest
		var before: int=wall.work;world._assign(person)
		var sleep: Dictionary=world.find(world.jobs,person.job)
		check.call("NEEDS/tired_builder_seeks_assigned_bed_before_or_after_critical_%d" % rest,sleep.get("kind")=="sleep" and sleep.target==person.bed and wall.worker==0 and wall.work==before)
		for index in range(600):
			world.step()
			if sleep.state=="Working": break
		var bed: Dictionary=world.find(world.structures,person.bed)
		check.call("NEEDS/actually_walks_into_bed_and_recovers_%d" % rest,sleep.state=="Working" and world.footprint(bed).has(Vector2i(person.x,person.y)) and world.invariant_errors().is_empty(),str([sleep,world.invariant_errors()]))
	var world: ColonyWorld=ColonyTests.world();var wall: Dictionary=working_wall(world)
	var person: Dictionary=world.find(world.citizens,wall.worker)
	remove_food(world);person.fullness=0;person.rest=700;world._assign(person)
	check.call("NEEDS/no_food_stops_construction_and_explains_supply_problem",person.job==0 and person.activity.begins_with("Hungry:") and wall.worker==0 and world.invariant_errors().is_empty())
	var berry: Dictionary=world.resources.filter(func(r:Dictionary)->bool:return r.definition=="berry_bush")[0]
	world._command({"kind":"gather","args":{"target":berry.id}})
	person.preferences.Gathering=3;person.preferences.Building=3;person.pinned_job=wall.id
	world._assign(person)
	check.call("NEEDS/food_gathering_precedes_pinned_wall_at_zero_fullness",world.find(world.jobs,person.job).get("kind")=="gather" and world.find(world.jobs,person.job).target==berry.id and person.pinned_job==wall.id)
	world=ColonyTests.world();wall=working_wall(world);person=world.find(world.citizens,wall.worker)
	remove_food(world);person.fullness=200;person.rest=250;world._assign(person)
	check.call("NEEDS/hunger_without_food_work_does_not_delay_bed_until_collapse",world.find(world.jobs,person.job).get("kind")=="sleep" and world.find(world.jobs,person.job).target==person.bed)
	world=ColonyTests.world();person=world.citizens[0];person.rest=75
	var sleep: Dictionary=world._job("sleep","","",0,Vector2i(person.x,person.y),0)
	sleep.worker=person.id;sleep.state="Working";person.job=sleep.id
	var loaded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world));assert(loaded.has("world"))
	world=loaded.world;person=world.citizens[0];world._assign(person);sleep=world.find(world.jobs,person.job)
	check.call("NEEDS/old_ground_collapse_recovers_to_assigned_bed_after_load",sleep.target==person.bed and sleep.state=="Moving" and world.invariant_errors().is_empty())
	check.call("NEEDS/day_phase_matches_dawn_day_dusk_night_and_wrap",[1500,2100,5100,5700,7200].map(func(at:int)->String:return EnvironmentArt.day_phase(at))==["dawn","day","dusk","night","night"])
