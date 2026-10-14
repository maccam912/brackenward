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
		for index in range(600): world.step()
		check.call("SLEEP/no_owned_cook_churn_when_sleep_is_ineligible_%d" % fullness,world.ineligible_cook_releases==0,str(world.ineligible_cook_releases))
		check.call("SLEEP/real_low_rest_cook_finishes_meals_and_eats_%d" % fullness,world.ledger.produced.get("meal",0)>=world.baseline_meals+2 and world.citizens[0].fullness>350 and world.citizens[0].health==100 and world.invariant_errors().is_empty(),str([world.ledger.produced.get("meal",0)-world.baseline_meals,world.citizens[0].fullness,world.citizens[0].rest,world.citizens[0].activity,world.invariant_errors()]))
	for pair in [[750,200],[0,50]]:
		var world: ObservedWorld=fixture();var chef: Dictionary=world.citizens[0];chef.fullness=pair[0];chef.rest=pair[1]
		world._assign(chef)
		check.call("SLEEP/eligible_ordinary_or_critical_rest_still_sleeps_%d_%d" % pair,world.find(world.jobs,chef.job).get("kind")=="sleep" and world.invariant_errors().is_empty())
	var world: ObservedWorld=fixture();var chef: Dictionary=world.citizens[0]
	world._make_stack("meal",1,"ground",0,Vector2i(chef.x,chef.y),true);world._assign(chef)
	check.call("SLEEP/feasible_food_keeps_priority_over_ordinary_rest",world.find(world.jobs,chef.job).get("kind")=="eat" and world.invariant_errors().is_empty())
	world=fixture();chef=world.citizens[0];chef.fullness=0
	var job: Dictionary=world._job("sleep","","",0,Vector2i(chef.x,chef.y),0);job.worker=chef.id;job.state="Working";chef.job=job.id
	var before: String=world.canonical_hash();world._assign(chef)
	check.call("SLEEP/no_feasible_food_preserves_existing_sleep",world.canonical_hash()==before and chef.job==job.id)
