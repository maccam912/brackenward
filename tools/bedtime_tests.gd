class_name BedtimeTests
extends RefCounted
## Controlled need fixtures; full loops use real portions, walks and bed rest.

static func sleeper(world: ColonyWorld, rest: int, fullness: int) -> Dictionary:
	var person: Dictionary=world.citizens[0];var bed: Dictionary=world.find(world.structures,person.bed)
	person.x=bed.x;person.y=bed.y;person.edge_x=bed.x;person.edge_y=bed.y;person.rest=rest;person.fullness=fullness
	var job: Dictionary=world._job("sleep","","",bed.id,Vector2i(bed.x,bed.y),0)
	job.worker=person.id;job.state="Working";person.job=job.id
	return person

static func run(check: Callable) -> void:
	for night_shift in [false,true]:
		var world: ColonyWorld=ColonyTests.world();var person: Dictionary=sleeper(world,300,1000)
		person.shift="Night shift" if night_shift else "Normal";world.tick=3600 if night_shift else 6600
		for index in range(913): world.tick+=1;world._needs(person)
		ColonyWeather.initialize(world)
		var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world));assert(decoded.has("world"),str(decoded.get("error","")))
		var twin: ColonyWorld=decoded.world
		for index in range(1487):
			world.tick+=1;world._needs(person);twin.tick+=1;twin._needs(twin.citizens[0])
		check.call("BEDTIME/eight_hours_sleep_uses_half_metabolism_with_exact_reload_%s" % night_shift,person.fullness==834 and person.hunger_rem==4800 and world.canonical_hash()==twin.canonical_hash() and world.invariant_errors().is_empty(),str([person.fullness,person.hunger_rem]))
	var world: ColonyWorld=ColonyTests.world();var person: Dictionary=world.citizens[0]
	person.fullness=1000;world.tick=6600
	for index in range(2400): world.tick+=1;world._needs(person)
	check.call("BEDTIME/awake_metabolism_remains_unchanged_even_at_night",person.fullness==667 and person.hunger_rem==2400)
	world=ColonyTests.world();person=world.citizens[0];person.fullness=500;person.rest=300
	world._assign(person)
	check.call("BEDTIME/tired_resident_eats_before_bed_with_real_supplies",world.find(world.jobs,person.job).get("kind")=="eat")
	var slept: bool=false;var woke: bool=false;var sleep_id: int=0
	for index in range(4500):
		world.step()
		var job: Dictionary=world.find(world.jobs,person.job)
		if job.get("kind")=="sleep" and job.state=="Working":
			if sleep_id==0: sleep_id=job.id
			slept=true
		elif slept and world.find(world.jobs,sleep_id).state=="Complete": woke=true;break
	var meals: Array=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="eat" and j.target==person.id and j.state=="Complete")
	check.call("BEDTIME/one_bedtime_meal_then_one_uninterrupted_sleep_to_900",slept and woke and person.rest>=900 and meals.size()==1 and world.find(world.jobs,sleep_id).target==person.bed and person.fullness>350 and person.health==100 and world.invariant_errors().is_empty(),str([slept,woke,person.rest,person.fullness,meals.size(),world.invariant_errors()]))
	world=ColonyTests.world();NeedsPriorityTests.remove_food(world);person=world.citizens[0];person.fullness=500;person.rest=300
	world._assign(person)
	check.call("BEDTIME/no_topup_supplies_never_delay_needed_bed",world.find(world.jobs,person.job).get("kind")=="sleep")
	world=ColonyTests.world();NeedsPriorityTests.remove_food(world);person=world.citizens[0];person.fullness=300;person.rest=300
	world._make_stack("berry",2,"store",world.stores[0].id,Vector2i(66,63),true)
	for index in range(600):
		world.step()
		if world.find(world.jobs,person.job).get("kind")=="sleep": break
	check.call("BEDTIME/raw_food_topup_consumes_real_portions_until_sufficiently_fed",world.find(world.jobs,person.job).get("kind")=="sleep" and person.fullness>=650 and world.ledger.consumed.get("berry",0)==2 and world.invariant_errors().is_empty(),str([person.fullness,world.ledger.consumed]))
	for fullness in [101,200,350]:
		world=ColonyTests.world();person=sleeper(world,300,fullness);var id: int=person.job
		world._assign(person)
		check.call("BEDTIME/routine_hunger_keeps_existing_sleep_%d" % fullness,person.job==id and world.find(world.jobs,id).state=="Working")
	for rest in [100,300,699]:
		world=ColonyTests.world();person=sleeper(world,rest,100);world._assign(person)
		check.call("BEDTIME/critical_fullness_can_wake_for_available_food_at_rest_%d" % rest,world.find(world.jobs,person.job).get("kind")=="eat" and world.invariant_errors().is_empty())
	world=ColonyTests.world();person=sleeper(world,700,350);world._assign(person)
	check.call("BEDTIME/fairly_rested_sleeper_can_get_breakfast",world.find(world.jobs,person.job).get("kind")=="eat")
	for index in range(200): world.step()
	check.call("BEDTIME/breakfast_does_not_immediately_send_rested_resident_back_to_bed",person.fullness>350 and world.find(world.jobs,person.job).get("kind")!="sleep" and world.invariant_errors().is_empty())
	world=ColonyTests.world();NeedsPriorityTests.remove_food(world);person=sleeper(world,300,0)
	var id: int=person.job;world._assign(person)
	check.call("BEDTIME/no_food_does_not_create_wake_sleep_churn",person.job==id)
	for index in range(2100): world.tick+=1;world._needs(person)
	check.call("BEDTIME/sleep_does_not_suspend_zero_fullness_starvation_damage",person.starving_ticks==2100 and person.health==95)
	world=ColonyTests.world();var trip: Dictionary=RegionTests.depart(world,RegionTests.args())
	person=world.find(world.citizens,trip.args.party[0]);person.fullness=350;person.rest=400;person.hunger_rem=0;person.camp_sleeping=true
	var eaten_before: int=trip.eaten;world.tick+=1;ColonyRegion.needs(world,person)
	check.call("BEDTIME/camp_sleeper_keeps_sleep_at_routine_hunger_and_half_drain",person.camp_sleeping and person.fullness==350 and person.hunger_rem==500 and trip.eaten==eaten_before,str([person.fullness,person.hunger_rem,trip.eaten]))
	var source: PackedByteArray=FileAccess.get_file_as_bytes("res://tests/fixtures/content10/campaign-replay-7200.brackenward")
	var previous: Dictionary=ColonyState.unpack(JSON.parse_string(JSON.parse_string(source.get_string_from_utf8()).payload))
	var decoded: Dictionary=ColonyCodec.decode(source)
	check.call("BEDTIME/v10_saved_acknowledgement_changes_only_content_headers",decoded.has("world") and SchemaCompatibility.normalize(decoded.world,previous)==previous,str(decoded.get("error","")))
