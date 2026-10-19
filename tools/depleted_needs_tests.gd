class_name DepletedNeedsTests
extends RefCounted
## Recovery uses ordinary commands, physical food, movement and saved remainders.

static func run(check: Callable) -> void:
	for resource_kind: String in ["berry_bush","mushroom_patch"]:
		for on_break: bool in [false,true]:
			food_order(check,resource_kind,on_break)
	break_priority(check)
	cooking(check)
	exhaustion(check)
	empty_needs(check)

static func food_order(check: Callable, resource_kind: String, on_break: bool) -> void:
	var world: ColonyWorld=ColonyTests.world()
	NeedsPriorityTests.remove_food(world)
	var person: Dictionary=world.citizens[0]
	person.fullness=0;person.rest=900;person.preferences.Gathering=3
	if on_break: person.break_until=world.tick+1800
	for other: Dictionary in world.citizens:
		if other.id!=person.id:
			other.preferences.Gathering=0;other.preferences.Cooking=0;other.preferences.Hauling=0
	var leisure: Dictionary=world._job("leisure","","",person.id,Vector2i(person.x,person.y),0)
	leisure.worker=person.id;leisure.state="Working";person.job=leisure.id
	var sources: Array=world.resources.filter(func(r:Dictionary)->bool:return r.definition==resource_kind)
	assert(not sources.is_empty(),"Missing resource fixture: "+resource_kind)
	var resource: Dictionary=sources[0]
	var item: String=world.definitions.resources[resource_kind].item
	world.queue_command("gather",{"target":resource.id})
	for index in range(40):
		world.step()
		if world.find(world.jobs,person.job).get("kind")=="gather": break
	var gather: Dictionary=world.find(world.jobs,person.job)
	var label: String="%s_break_%s" % [resource_kind,on_break]
	check.call("DEPLETED/new_food_order_interrupts_leisure_"+label,gather.get("kind")=="gather" and gather.target==resource.id and leisure.state=="Canceled",str([person.activity,gather]))
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	assert(decoded.has("world"),str(decoded.get("error","")))
	var twin: ColonyWorld=decoded.world
	for index in range(1200):
		world.step();twin.step()
		if world.ledger.consumed.get(item,0)>0: break
	check.call("DEPLETED/gathers_and_eats_before_break_expires_"+label,world.ledger.produced.get(item,0)>0 and world.ledger.consumed.get(item,0)>0 and person.fullness>0 and (not on_break or person.break_until>world.tick) and world.canonical_hash()==twin.canonical_hash() and world.invariant_errors().is_empty(),str([person.activity,person.fullness,world.tick,world.invariant_errors()]))

static func break_priority(check: Callable) -> void:
	for fullness: int in [0,200]:
		var world: ColonyWorld=ColonyTests.world()
		NeedsPriorityTests.remove_food(world)
		var person: Dictionary=world.citizens[0]
		person.fullness=fullness;person.rest=900;person.break_until=world.tick+1800;person.preferences.Gathering=3
		var resource: Dictionary=world.resources.filter(func(r:Dictionary)->bool:return r.definition=="berry_bush")[0]
		world._command({"kind":"gather","args":{"target":resource.id}})
		world._assign(person)
		check.call("DEPLETED/only_critical_hunger_overrides_break_%d" % fullness,world.find(world.jobs,person.job).get("kind")==("gather" if fullness==0 else "leisure") and person.break_until>world.tick)
		var current_id: int=person.job
		world._assign(person)
		check.call("DEPLETED/break_or_food_work_keeps_its_job_%d" % fullness,person.job==current_id)
		person.preferences.Gathering=0
		world._release(world.find(world.jobs,person.job),false);world._assign(person)
		check.call("DEPLETED/food_work_still_honors_disabled_preferences_%d" % fullness,world.find(world.jobs,person.job).get("kind")!="gather" and world.invariant_errors().is_empty())

static func cooking(check: Callable) -> void:
	var loaded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/content3-hungry-cook.brackenward"))
	assert(loaded.has("world"),str(loaded.get("error","")))
	var world: ColonyWorld=loaded.world;var person: Dictionary=world.citizens[0]
	person.fullness=0;person.rest=900;person.break_until=world.tick+1800
	var before: int=world.ledger.produced.get("meal",0)
	for index in range(1500):
		world.step()
		if person.fullness>0: break
	check.call("DEPLETED/starving_cook_finishes_and_eats_during_morale_break",world.ledger.produced.get("meal",0)>before and person.fullness>0 and person.break_until>world.tick and world.invariant_errors().is_empty(),str([person.activity,person.fullness,world.invariant_errors()]))

static func exhaustion(check: Callable) -> void:
	for health: int in [100,40]:
		for fullness: int in [1000,0]:
			var fresh: ColonyWorld=ColonyTests.world();var tired: ColonyWorld=ColonyTests.world()
			var a: Dictionary=fresh.citizens[0];var b: Dictionary=tired.citizens[0]
			a.health=health;b.health=health;a.fullness=fullness;b.fullness=fullness;b.rest=0
			fresh._walk(a,Vector2i(a.x+1,a.y));tired._walk(b,Vector2i(b.x+1,b.y))
			check.call("DEPLETED/zero_energy_walks_at_half_speed_without_double_need_penalty_%d_%d" % [health,fullness],b.progress>0 and b.progress*(2 if fullness>0 else 1)==a.progress,str([a.progress,b.progress]))
	for fullness: int in [1000,0]:
		var world: ColonyWorld=ColonyTests.world();var person: Dictionary=world.citizens[0]
		person.rest=0;person.fullness=fullness;person.break_until=world.tick+1800
		if fullness==0: NeedsPriorityTests.remove_food(world)
		var origin: Vector2i=Vector2i(person.x,person.y)
		for index in range(12): world.step()
		check.call("DEPLETED/empty_energy_makes_mid_route_progress_%d" % fullness,person.progress>0 and world.find(world.jobs,person.job).get("kind")=="sleep")
		var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
		assert(decoded.has("world"),str(decoded.get("error","")))
		var twin: ColonyWorld=decoded.world
		var slept: bool=false
		for index in range(800):
			world.step();twin.step()
			var job: Dictionary=world.find(world.jobs,person.job)
			if job.get("kind")=="sleep" and job.state=="Working" and person.rest>0:
				slept=true;break
		var bed: Dictionary=world.find(world.structures,person.bed)
		check.call("DEPLETED/empty_energy_reaches_assigned_bed_and_recovers_%d" % fullness,slept and Vector2i(person.x,person.y)!=origin and world.footprint(bed).has(Vector2i(person.x,person.y)) and world.canonical_hash()==twin.canonical_hash() and world.invariant_errors().is_empty(),str([person.activity,person.rest,world.invariant_errors()]))

static func empty_needs(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	NeedsPriorityTests.remove_food(world)
	var person: Dictionary=world.citizens[0]
	person.fullness=0;person.rest=0;person.break_until=world.tick+4000;person.preferences.Gathering=3
	for other: Dictionary in world.citizens:
		if other.id!=person.id:
			other.preferences.Gathering=0;other.preferences.Cooking=0;other.preferences.Hauling=0
	var resource: Dictionary=world.resources.filter(func(r:Dictionary)->bool:return r.definition=="berry_bush")[0]
	world.queue_command("gather",{"target":resource.id})
	for index in range(12): world.step()
	check.call("DEPLETED/both_empty_still_prioritizes_critical_sleep",world.find(world.jobs,person.job).get("kind")=="sleep")
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	assert(decoded.has("world"),str(decoded.get("error","")))
	var twin: ColonyWorld=decoded.world
	var slept: bool=false
	for index in range(3200):
		world.step();twin.step()
		var current: Dictionary=world.find(world.jobs,person.job)
		slept=slept or (current.get("kind")=="sleep" and current.state=="Working")
		if world.ledger.consumed.get("berry",0)>0: break
	check.call("DEPLETED/both_empty_sleeps_then_gathers_and_eats_while_on_break",slept and person.rest>100 and person.fullness>0 and world.ledger.produced.get("berry",0)>0 and world.ledger.consumed.get("berry",0)>0 and person.break_until>world.tick and world.canonical_hash()==twin.canonical_hash() and world.invariant_errors().is_empty(),str([person.activity,person.rest,person.fullness,world.invariant_errors()]))
