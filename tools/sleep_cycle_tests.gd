class_name SleepCycleTests
extends RefCounted
## Controlled low-rest fixtures; added grain/consumed meals are not balance evidence.
class ObservedWorld extends ColonyWorld:
	var baseline_meals: int=0
	var ineligible_cook_releases: int=0
	func _init(catalog: Dictionary) -> void: super(catalog)
	func _release(job: Dictionary, cancel: bool) -> void:
		var chef: Dictionary=citizens[0]
		if not cancel and job.get("kind")=="cook" and job.get("worker")==chef.id and chef.rest>100 and chef.fullness<=350 and ledger.produced.get("meal",0)<=baseline_meals: ineligible_cook_releases+=1
		super(job,cancel)
static func fixture() -> ObservedWorld:
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/content4-low-rest-cook.brackenward"))
	assert(decoded.has("world"))
	var source: ColonyWorld=decoded.world;var result: ObservedWorld=ObservedWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries();result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	result.baseline_meals=result.ledger.produced.get("meal",0)
	return result
static func run(check: Callable) -> void:
	var source: ObservedWorld=fixture()
	check.call("SLEEP/frozen_v4_low_rest_fixture_loads_with_exact_header_only_migration",source.citizens[0].rest==200 and source.citizens[0].fullness==200 and source.tick==1800 and source.invariant_errors().is_empty())
	for fullness in [0,200,350]:
		var world: ObservedWorld=fixture();world.citizens[0].fullness=fullness
		for index in range(3000 if fullness==0 else 600):
			world.step()
			if world.citizens[0].fullness>350 and world.ledger.produced.get("meal",0)>=world.baseline_meals+2: break
		check.call("SLEEP/no_owned_cook_churn_when_sleep_is_ineligible_%d" % fullness,world.ineligible_cook_releases==0,str(world.ineligible_cook_releases))
		check.call("SLEEP/real_low_rest_cook_finishes_meals_and_eats_%d" % fullness,world.ledger.produced.get("meal",0)>=world.baseline_meals+2 and world.citizens[0].fullness>350 and world.citizens[0].health>=(95 if fullness==0 else 100) and world.invariant_errors().is_empty(),str([world.ledger.produced.get("meal",0)-world.baseline_meals,world.citizens[0].fullness,world.citizens[0].rest,world.citizens[0].activity,world.invariant_errors()]))
	for pair in [[750,200],[0,50]]:
		var world: ObservedWorld=fixture();var chef: Dictionary=world.citizens[0];chef.fullness=pair[0];chef.rest=pair[1]
		world._assign(chef)
		check.call("SLEEP/eligible_ordinary_or_critical_rest_still_sleeps_%d_%d" % pair,world.find(world.jobs,chef.job).get("kind")=="sleep" and world.invariant_errors().is_empty())
	var world: ObservedWorld=fixture();var chef: Dictionary=world.citizens[0]
	world._make_stack("meal",1,"ground",0,Vector2i(chef.x,chef.y),true);world._assign(chef)
	check.call("SLEEP/feasible_food_keeps_priority_over_ordinary_rest",world.find(world.jobs,chef.job).get("kind")=="eat" and world.invariant_errors().is_empty())
	world=fixture();chef=world.citizens[0];chef.fullness=0
	var job: Dictionary=world._job("sleep","","",0,Vector2i(chef.x,chef.y),0);job.worker=chef.id;job.state="Working";chef.job=job.id
	world.find(world.structures,chef.bed).user=0;chef.bed=0
	var before: String=world.canonical_hash();world._assign(chef)
	check.call("SLEEP/no_feasible_food_preserves_existing_sleep",world.canonical_hash()==before and chef.job==job.id)

static func paced_world(kind: String, rest: int, at_tick: int = 6900) -> ColonyWorld:
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/content5-rested-sleepers.brackenward"))
	assert(decoded.has("world"))
	var world: ColonyWorld=decoded.world;world.tick=at_tick
	var person: Dictionary=world.citizens[0];var job: Dictionary=world.find(world.jobs,person.job)
	person.rest=rest;person.rest_rem=0
	if kind=="ground":
		world.find(world.structures,person.bed).user=0;person.bed=0
		person.x=90;person.y=80;person.edge_x=90;person.edge_y=80
		job.target=0;job.x=90;job.y=80;job.work_x=90;job.work_y=80
	else:
		world.find(world.structures,person.bed).definition=kind
	return world

static func pacing(check: Callable) -> void:
	var world: ColonyWorld=paced_world("bedroll",1000)
	var original_tick: int=world.tick;world.step()
	check.call("REST/fully_rested_old_sleepers_wake_on_first_tick_even_at_night",world.tick==original_tick+1 and world.citizens.all(func(p:Dictionary)->bool:return p.job==0 and p.rest==1000) and world.invariant_errors().is_empty())
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/content5-mixed-tiredness.brackenward"));world=decoded.world
	for person in world.citizens: world._assign(person)
	check.call("REST/night_only_tired_residents_seek_sleep",world.citizens.slice(0,2).all(func(p:Dictionary)->bool:return world.find(world.jobs,p.job).get("kind")=="sleep") and world.citizens.slice(2).all(func(p:Dictionary)->bool:return world.find(world.jobs,p.job).get("kind")!="sleep"))
	var person: Dictionary=world.citizens[2];person.rest=450;person.shift="Night shift"
	check.call("REST/night_shift_prefers_daytime_only_when_tired",ColonyRest.wants_sleep(person,4200) and not ColonyRest.wants_sleep(person,6900))
	person.rest=750
	check.call("REST/energetic_night_shift_does_not_sleep_just_for_the_clock",not ColonyRest.wants_sleep(person,4200))
	person.rest=400;person.shift="Normal"
	check.call("REST/preparing_traveler_can_rest_early_without_changing_ordinary_threshold",ColonyRest.wants_sleep(person,3600,true) and not ColonyRest.wants_sleep(person,3600))
	for pair in [["bed",2400],["bedroll",3000],["ground",4000]]:
		world=paced_world(pair[0],300,6600)
		person=world.citizens[0];var sleeper: Dictionary=world.find(world.jobs,person.job);var sleeper_id: int=sleeper.id
		for index in range(pair[1]-1): world.step()
		check.call("REST/physical_%s_recovers_gradually_until_rested" % pair[0],person.rest==899 and person.job==sleeper_id and sleeper.state=="Working" and person.health>0,str([person.rest,person.activity,sleeper.state]))
		world.step()
		check.call("REST/physical_%s_wakes_exactly_at_900_without_clock_wait" % pair[0],person.rest==900 and sleeper.state=="Complete" and person.job!=sleeper_id and world.invariant_errors().is_empty(),str([person.rest,person.activity,sleeper.state,world.invariant_errors()]))
	world=paced_world("bedroll",300,6600);person=world.citizens[0];var sleeper: int=person.job
	for index in range(2400): world.step()
	check.call("REST/sunrise_does_not_wake_a_still_tired_sleeper",world.tick==9000 and person.rest==780 and person.job==sleeper and world.find(world.jobs,sleeper).state=="Working")
	world=ColonyTests.world();person=world.citizens[0];person.rest=900;person.fullness=1000;person.rest_rem=0
	for index in range(2401): world.tick+=1;world._needs(person)
	var halfway: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world));var resumed: ColonyWorld=halfway.world
	for index in range(2399):
		world.tick+=1;world._needs(person)
		resumed.tick+=1;resumed._needs(resumed.citizens[0])
	check.call("REST/sixteen_awake_hours_spend_six_hundred_points_with_exact_fractional_reload",person.rest==300 and person.rest_rem==0 and resumed.canonical_hash()==world.canonical_hash() and world.invariant_errors().is_empty(),str([person.rest,person.rest_rem]))
	var hungry: ObservedWorld=fixture();var chef: Dictionary=hungry.citizens[0]
	var current: Dictionary=hungry.find(hungry.jobs,chef.job)
	if not current.is_empty(): hungry._release(current,false)
	var rest_job: Dictionary=hungry._job("sleep","","",0,Vector2i(chef.x,chef.y),0)
	rest_job.worker=chef.id;rest_job.state="Working";chef.job=rest_job.id;chef.fullness=0;chef.rest=299
	hungry._assign(chef)
	check.call("REST/hungry_sleeper_recovers_minimum_rest_before_work",chef.job==rest_job.id and rest_job.target==chef.bed and rest_job.state=="Moving")
	chef.rest=300;hungry._create_work();hungry._assign(chef)
	check.call("REST/hungry_sleeper_can_prepare_food_after_minimum_rest",hungry.find(hungry.jobs,chef.job).get("kind")=="cook" and rest_job.state=="Canceled" and hungry.invariant_errors().is_empty(),str([hungry.find(hungry.jobs,chef.job).get("kind"),rest_job.state,hungry.invariant_errors()]))
	for index in range(3000):
		hungry.step()
		if chef.fullness>350 and hungry.ledger.produced.get("meal",0)>hungry.baseline_meals: break
	check.call("REST/slow_rest_does_not_trap_the_only_cook_asleep_while_starving",chef.fullness>350 and hungry.ledger.produced.get("meal",0)>hungry.baseline_meals and hungry.invariant_errors().is_empty(),str([chef.fullness,chef.rest,chef.activity]))
