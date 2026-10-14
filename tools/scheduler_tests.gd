class_name SchedulerTests
extends RefCounted

static func run(check: Callable) -> void:
	WorkBudgetTests.run(check)
	MovementCostTests.run(check)
	StorageQueryTests.run(check)
	obstructed_start(check)
	StackQueryTests.run(check)
	JobQueryTests.run(check)
	DiningTests.run(check)
	var ordered: ColonyWorld = ColonyTests.world()
	var reversed: ColonyWorld = ColonyTests.world()
	reversed.citizens.reverse()
	for index in range(20): ordered.step();reversed.step()
	check.call("SCHED/citizen_storage_order_does_not_change_tick_results",ordered.canonical_hash()==reversed.canonical_hash())
	automatic_cooking(check)
	hungry_sleepers(check)
	unreachable_bed(check)
	shared_eating_tile(check)
	personal_job_lifecycle(check)
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

static func hungry_sleepers(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	world.tick=6600
	var person: Dictionary = world.citizens[0]
	var bed: Dictionary = world.find(world.structures,person.bed)
	person.x=bed.x;person.y=bed.y;person.rest=100;person.fullness=350
	var sleeping: Dictionary = world._job("sleep","","",bed.id,Vector2i(bed.x,bed.y),0)
	sleeping.worker=person.id;sleeping.state="Working";person.job=sleeping.id
	world._assign(person)
	check.call("SCHED/critical_sleep_precedes_ordinary_hunger",person.job==sleeping.id)
	person.rest=500
	world._assign(person)
	check.call("SCHED/sleepers_seek_available_food_at_350",world.find(world.jobs,person.job).get("kind")=="eat")
	check.call("SCHED/interrupted_sleep_retires_its_personal_job",sleeping.state=="Canceled" and sleeping.worker==0)
	var ate: bool = false
	var resumed_sleep: bool = false
	var minimum_fullness: int = person.fullness
	for index in range(1800):
		world.step()
		minimum_fullness=mini(minimum_fullness,person.fullness)
		ate=ate or person.fullness>350
		resumed_sleep=resumed_sleep or (ate and world.find(world.jobs,person.job).get("kind")=="sleep")
	check.call("SCHED/night_meal_finishes_and_sleep_resumes_without_starvation",ate and resumed_sleep and minimum_fullness>0 and person.health==100,"minimum fullness=%d, ate=%s, slept=%s" % [minimum_fullness,ate,resumed_sleep])
	check.call("SCHED/night_meal_preserves_material_accounting",world.invariant_errors().is_empty(),str(world.invariant_errors()))

static func unreachable_bed(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var person: Dictionary = world.citizens[0]
	var bed: Dictionary = world.find(world.structures,person.bed)
	person.x=72;person.y=54;person.edge_x=72;person.edge_y=54
	person.rest=299;person.fullness=1000
	for delta in ColonyNavigation.NEIGHBORS:
		world._structure("wood_wall",Vector2i(bed.x,bed.y)+delta,0)
	world._assign(person)
	var sleep_job: Dictionary = world.find(world.jobs,person.job)
	world._work(person,sleep_job)
	check.call("SCHED/unreachable_bed_falls_back_to_safe_ground",sleep_job.state=="Working" and sleep_job.target==0 and sleep_job.worker==person.id and person.bed==bed.id and sleep_job.reason.contains("Assigned bed unreachable"))
	check.call("SCHED/disconnected_route_preserves_one_request_slot_and_ground_fallback",world.path_requests==1 and world.accessible(Vector2i(person.x,person.y)) and not world.accessible(Vector2i(bed.x,bed.y)))
	var job_count: int = world.jobs.size()
	for index in range(300):
		world._needs(person)
		world._assign(person)
		world._work(person,sleep_job)
		ColonyLiving.advance(world)
	check.call("SCHED/ground_fallback_restores_exact_rate_without_retry_jobs",person.rest==379 and world.jobs.size()==job_count and person.activity.contains("clear access or reassign bed"),str([person.rest,world.jobs.size(),job_count,person.activity]))
	check.call("SCHED/ground_sleep_never_earns_assigned_bed_memory",person.bed_sleep_ticks==0 and person.bed_memory_until==0 and not world.facts.any(func(f:Dictionary)->bool:return f.kind=="rested_in_bed"))
	var restored: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/unreachable_bed_fallback_roundtrip",restored.has("world") and restored.world.canonical_hash()==world.canonical_hash() and world.invariant_errors().is_empty(),str(restored.get("error",world.invariant_errors())))
	world=ColonyTests.world();person=world.citizens[0];person.rest=299;person.fullness=1000
	world._assign(person);sleep_job=world.find(world.jobs,person.job)
	for index in range(600):
		world._work(person,sleep_job)
		if sleep_job.state=="Working": break
	check.call("SCHED/reachable_assigned_bed_still_used",sleep_job.target==person.bed and sleep_job.state=="Working" and sleep_job.reason.is_empty())

static func shared_eating_tile(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var cart: Dictionary = ColonyTrade.cart(world)
	for person in world.citizens:
		for category in person.preferences: person.preferences[category]=0
	var sleeper: Dictionary = world.citizens[0]
	sleeper.x=cart.x;sleeper.y=cart.y;sleeper.rest=100;sleeper.fullness=1000
	var sleep_job: Dictionary = world._job("sleep","","",0,Vector2i(cart.x,cart.y),0)
	sleep_job.worker=sleeper.id;sleep_job.state="Working";sleeper.job=sleep_job.id
	for person in [world.citizens[1],world.citizens[2]]:
		person.x=cart.x;person.y=cart.y;person.edge_x=cart.x;person.edge_y=cart.y;person.fullness=300;person.rest=700
		world._assign(person)
	check.call("SCHED/hunger_can_reserve_food_on_a_sleepers_tile",world.find(world.jobs,world.citizens[1].job).get("kind")=="eat" and sleeper.job==sleep_job.id)
	check.call("SCHED/two_colocated_residents_can_eat_with_distinct_food",world.find(world.jobs,world.citizens[2].job).get("kind")=="eat" and world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="eat" and j.worker>0).size()==2 and world.stacks.reduce(func(n:int,s:Dictionary)->int:return n+world._reserved(s),0)==2)
	for index in range(10): world.step()
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/shared_eating_tile_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash() and world.invariant_errors().is_empty(),str(decoded.get("error",world.invariant_errors())))
	for index in range(590):
		world.step()
		if decoded.has("world"): decoded.world.step()
	check.call("SCHED/shared_tile_eaters_finish_without_starving_or_duplication",world.citizens[1].fullness>350 and world.citizens[2].fullness>350 and world.ledger.consumed.get("meal",0)==2 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	check.call("SAVE/shared_tile_eating_continuation_is_exact",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash())

static func personal_job_lifecycle(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var person: Dictionary = world.citizens[0]
	person.fullness=300;person.rest=1000
	for category in person.preferences: person.preferences[category]=0
	var occupied: Dictionary = world._job("leisure","","",world.citizens[1].id,Vector2i(person.x,person.y),0)
	occupied.worker=world.citizens[1].id;occupied.state="Working";world.citizens[1].job=occupied.id
	for attempt in range(3): world._assign(person);world.tick+=10
	var attempts: Array = world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="eat")
	check.call("SCHED/shared_meal_position_does_not_create_retry_jobs",attempts.size()==1 and attempts[0].worker==person.id and attempts[0].state=="Fetching")
	check.call("SCHED/shared_meal_position_reserves_one_portion",world.stacks.reduce(func(n:int,s:Dictionary)->int:return n+world._reserved(s),0)==1 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();person=world.citizens[0]
	var food: Dictionary = world._food(person)
	var eating: Dictionary = world._job("eat","","",person.id,Vector2i(person.x,person.y),2000)
	eating.inputs={food.item:1};eating.source=food.id
	var reserved: bool = world._reserve(eating,person)
	check.call("SCHED/interrupted_meal_fixture_reserves",reserved)
	if not reserved: return
	person.job=eating.id;person.x=food.x;person.y=food.y;person.progress=0;world._work(person,eating)
	var carried: Array = world.stacks.filter(func(s:Dictionary)->bool:return s.location=="carry" and s.job==eating.id and s.count>0)
	world._release(eating,false)
	check.call("SCHED/interrupted_meal_drops_real_food_at_resident",eating.state=="Canceled" and person.job==0 and carried.size()==1 and carried[0].location=="ground" and carried[0].x==person.x and carried[0].y==person.y and carried[0].count==1 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();person=world.citizens[0];food=world._food(person)
	eating=world._job("eat","","",person.id,Vector2i(person.x,person.y),2000);eating.inputs={food.item:1};eating.source=food.id
	reserved=world._reserve(eating,person);person.job=eating.id
	food.age=world.definitions.items[food.item].shelf_ticks
	ColonyLiving.advance(world)
	check.call("SCHED/spoiled_personal_meal_stays_canceled_with_cause",reserved and eating.state=="Canceled" and eating.reason.contains("spoiled") and person.job==0 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();person=world.citizens[0]
	var old_sleep: Dictionary = world._job("sleep","","",person.bed,Vector2i(person.x,person.y),0)
	var old_leisure: Dictionary = world._job("leisure","","",person.id,Vector2i(person.x,person.y),0);old_leisure.state="Blocked";old_leisure.reason="No route"
	var complete: Dictionary = world._job("leisure","","",person.id,Vector2i(person.x,person.y),0);complete.state="Complete"
	var complete_before: Dictionary = complete.duplicate(true)
	var active: Dictionary = world._job("sleep","","",person.bed,Vector2i(person.x,person.y),0);active.worker=person.id;active.state="Working";person.job=active.id
	var ordinary: Dictionary = world._job("gather","Gathering","Field",world.resources[0].id,Vector2i(world.resources[0].x,world.resources[0].y),16000);ordinary.state="Blocked";ordinary.reason="No route"
	var restored: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SCHED/legacy_personal_job_fixture_loads",restored.has("world"),str(restored.get("error","")))
	if not restored.has("world"): return
	world=restored.world;world._create_work()
	check.call("SCHED/loaded_orphans_retire_without_pruning_history",world.find(world.jobs,old_sleep.id).state=="Canceled" and world.find(world.jobs,old_leisure.id).state=="Canceled" and world.find(world.jobs,complete.id)==complete_before)
	check.call("SCHED/reconciliation_preserves_owned_rest_and_blocked_colony_work",world.find(world.jobs,active.id).state=="Working" and world.citizens[0].job==active.id and world.find(world.jobs,ordinary.id).state=="Blocked" and world.invariant_errors().is_empty(),str(world.invariant_errors()))

static func work_position(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var person: Dictionary = world.citizens[0]
	person.x=48;person.y=70
	var resource: Dictionary = world.resources[0];resource.x=70;resource.y=70;world.navigation_dirty=true
	var fuel: Dictionary = world._make_stack("wood",20,"ground",0,Vector2i(61,70),true)
	ColonyFire.ignite(world,"stack",fuel.id)
	var gather: Dictionary = world._job("gather","Gathering","Field",resource.id,Vector2i(70,70),16000)
	var accepted: bool = world._reserve(gather,person)
	check.call("SCHED/unsafe_nearest_position_does_not_hide_safe_work_position",accepted and ColonyDanger.safe(world,Vector2i(gather.work_x,gather.work_y)),gather.reason)
	for inside_room in [false,true]:
		world=ColonyTests.world();person=world.citizens[0]
		var wall: Dictionary = {}
		for y in range(79,83):
			for x in range(79,83):
				if x not in [79,82] and y not in [79,82]: continue
				var built: Dictionary = world._structure("wood_wall",Vector2i(x,y),0)
				if Vector2i(x,y)==Vector2i(80,79): wall=built
		person.x=80;person.y=80 if inside_room else 84
		person.edge_x=person.x;person.edge_y=person.y
		var task: Dictionary = world._job("demolish","Building","Build",wall.id,Vector2i(wall.x,wall.y),3000)
		task.definition="wood_wall"
		accepted=world._reserve(task,person)
		check.call("SCHED/maintenance_can_work_from_inside_sealed_room" if inside_room else "SCHED/maintenance_skips_closer_sealed_side_of_wall",accepted and Vector2i(task.work_x,task.work_y)==Vector2i(80,80 if inside_room else 78),task.reason)

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

static func obstructed_start(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var person: Dictionary = world.citizens[0]
	var origin: Vector2i = Vector2i(person.x,person.y)
	world._structure("wood_wall",origin,0)
	var goal: Vector2i = origin+Vector2i.RIGHT
	var arrived: bool = false
	for attempt in range(12):
		arrived=world._walk(person,goal)
		if arrived: break
	check.call("SCHED/obstructed_start_can_still_step_out_through_normal_astar",arrived and Vector2i(person.x,person.y)==goal and world.path_requests==1)
