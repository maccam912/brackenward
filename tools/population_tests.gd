class_name PopulationTests
extends RefCounted

static func run(check: Callable) -> void:
	beds(check)
	var world: ColonyWorld = ColonyTests.world()
	var twin: ColonyWorld = ColonyTests.world()
	var a: Dictionary = ColonyPopulation.offer(world)
	var b: Dictionary = ColonyPopulation.offer(twin)
	check.call("POP/seeded_offer_is_identical",a==b and world.population_state==twin.population_state)
	check.call("POP/one_preferred_level_two_and_other_level_one",a.candidate.skills[ColonyPopulation.PRIMARY[a.candidate.preferred]]==2 and a.candidate.skills.values().filter(func(n:int)->bool:return n==1).size()==1 and a.candidate.skills.values().filter(func(n:int)->bool:return n==0).size()==5)
	check.call("POP/two_distinct_compatible_traits",a.candidate.traits.size()==2 and a.candidate.traits[0]!=a.candidate.traits[1] and not (a.candidate.traits.has("Sociable") and a.candidate.traits.has("Private")))
	check.call("POP/free_reachable_bed_is_required",ColonyPopulation.acceptance(world,a).error.contains("bed"))
	world._structure("bedroll",Vector2i(74,64),0)
	check.call("POP/starting_food_supports_a_fifth_resident",ColonyPopulation.acceptance(world,a).error.is_empty())
	var old_gear: int = world.total("toolkit")
	world.queue_command("newcomer",{"target":a.id,"accept":true});world.step()
	var person: Dictionary = world.citizens[-1]
	check.call("POP/accept_registers_nonsequential_id_and_worn_gear",world.citizens.size()==5 and person.id>4 and person.equipment.weapon.is_empty() and person.equipment.toolkit=="toolkit" and person.equipment.cloak=="cloak" and world.total("toolkit")==old_gear+1 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	check.call("POP/relationships_and_policies_register_new_id",world.social_state.pairs.size()==10 and world.equipment_state.has(person.id) and world.equipment_state[person.id].toolkit.replacements)
	check.call("POP/rations_wait_for_physical_cart_arrival",a.state=="Accepted" and world.total("travel_ration")==8 and (person.x in [0,127] or person.y in [0,127]))
	check.call("POP/starting_needs_follow_newcomer_contract",person.fullness==800 and person.rest==800 and person.morale==600)
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/fifth_resident_mid_arrival_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	for i in range(2500):
		world.step()
		if a.state=="Arrived": break
	check.call("POP/physical_arrival_deposits_four_rations_once",a.state=="Arrived" and world.total("travel_ration")==12 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="arrival" and j.state=="Complete") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var repeated: int = world.queue_command("newcomer",{"target":a.id,"accept":true});world.step()
	check.call("POP/repeat_accept_cannot_duplicate_person_or_supplies",world.citizens.size()==5 and world.total("travel_ration")==12 and world.receipts[repeated].contains("no longer"))
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/arrived_resident_and_relationships_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world=ColonyTests.world();a=ColonyPopulation.offer(world);world._structure("bedroll",Vector2i(74,64),0)
	for stack in world.stacks:
		if stack.item=="meal": world._record("consumed","meal",stack.count);stack.count=0
	check.call("POP/food_gate_prices_enlarged_household",ColonyPopulation.acceptance(world,a).error.contains("5 residents"))
	world=ColonyTests.world();a=ColonyPopulation.offer(world)
	world.queue_command("newcomer",{"target":a.id,"accept":false});world.step()
	check.call("POP/decline_has_no_population_or_inventory_change",a.state=="Declined" and world.citizens.size()==4 and world.total("toolkit")==4 and world.total("travel_ration")==8)
	world=ColonyTests.world();a=ColonyPopulation.offer(world)
	world.tick=a.deadline;ColonyWeather.initialize(world);ColonyPopulation.advance(world)
	check.call("POP/two_day_offer_expiry",a.state=="Expired" and world.citizens.size()==4)
	world=ColonyTests.world();world.tick=23999;ColonyWeather.initialize(world);world.step()
	check.call("POP/day_four_offer_uses_game_calendar",world.population_state.offers.size()==1 and world.population_state.offers[0].created==24000)
	var original: Dictionary = world.population_state.duplicate(true)
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/waiting_offer_stream_and_name_permutation_saved",decoded.has("world") and decoded.world.population_state==original,str(decoded.get("error","")))
	world=ColonyTests.world();var seen: Dictionary = {};var variety: Dictionary = {}
	for i in range(96):
		var candidate: Dictionary = ColonyPopulation.generate(world)
		variety[candidate.preferred]=true
		if i<24: seen[candidate.name]=true
	check.call("POP/seeded_names_cycle_all_twenty_four_and_categories",seen.size()==24 and variety.size()==8)
	var old: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-care.brackenward"))
	check.call("SAVE/population_migration_preserves_initial_four_and_care",old.has("world") and old.world.citizens.size()==4 and old.world.citizens[2].health==27 and old.world.population_state.offers.is_empty(),str(old.get("error","")))
	world=ColonyTests.world()
	var cart: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]
	world._make_stack("meal",200,"store",cart.id,Vector2i(cart.x,cart.y),true)
	for index in range(16):
		world._structure("bedroll",Vector2i(75,65+index),0)
		a=ColonyPopulation.offer(world)
		var accepted: String = ColonyPopulation.command(world,{"target":a.id,"accept":true})
		check.call("POP/resident_%d_has_real_id_and_bed" % (index+5),accepted=="accepted" and world.citizens.size()==index+5)
		person=world.citizens[-1];person.x=cart.x;person.y=cart.y
		ColonyPopulation.arrival_work(world,person,world.find(world.jobs,person.job))
	a=ColonyPopulation.offer(world)
	check.call("POP/twenty_resident_hard_cap",ColonyPopulation.acceptance(world,a).error.contains("Twenty") and ColonyPopulation.command(world,{"target":a.id,"accept":true}).contains("Twenty") and world.citizens.size()==20)
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/twenty_residents_and_190_relationships_roundtrip",decoded.has("world") and world.social_state.pairs.size()==190 and world.equipment_state.size()==20 and world.invariant_errors().is_empty(),str(decoded.get("error",world.invariant_errors())))

static func beds(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var person: Dictionary = world.citizens[0]
	var previous: Dictionary = world.find(world.structures,person.bed)
	var bed: Dictionary = world._structure("bed",Vector2i(74,64),0)
	var point: Vector2i = Vector2i(person.x,person.y)
	var ledger: Dictionary = world.ledger.duplicate(true)
	var order: int = world.queue_command("assign_bed",{"citizen":person.id,"target":bed.id})
	var paused: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("BED/pending_assignment_saves_without_applying_while_paused",person.bed==previous.id and paused.has("world") and paused.world.pending_commands==world.pending_commands and paused.world.schema_revision==21,str(paused.get("error","")))
	world.step()
	check.call("BED/public_assignment_releases_old_owner_without_moving_or_granting_goods",world.receipts[order]=="accepted" and person.bed==bed.id and bed.user==person.id and previous.user==0 and Vector2i(person.x,person.y)==point and world.ledger==ledger)
	var original: String = world.canonical_hash()
	check.call("BED/repeating_current_assignment_is_idempotent",ColonyBeds.command(world,{"citizen":person.id,"target":bed.id})=="accepted" and world.canonical_hash()==original)
	check.call("BED/occupied_assignment_explains_owner_without_displacement",ColonyBeds.command(world,{"citizen":2,"target":bed.id}).contains(person.name) and world.canonical_hash()==original)
	check.call("BED/rejects_missing_resident_wrong_structure_and_malformed_arguments",not ColonyBeds.quote(world,999999,bed.id).is_empty() and ColonyBeds.quote(world,1,ColonyTrade.cart(world).id).contains("bed") and ColonyBeds.command(world,{"citizen":"1","target":bed.id})!="accepted" and world.canonical_hash()==original)
	person.away=true
	check.call("BED/away_assignment_waits_for_return",ColonyBeds.quote(world,1,bed.id).contains("returns"))
	person.away=false;bed.health=0
	check.call("BED/destroyed_bed_cannot_be_assigned",ColonyBeds.quote(world,1,bed.id).contains("completed"))
	bed.health=200
	ColonyFire.ignite(world,"structure",bed.id)
	check.call("BED/burning_bed_cannot_be_assigned",ColonyBeds.quote(world,1,bed.id).contains("Extinguish"))
	world=ColonyTests.world();person=world.citizens[0];bed=world._structure("bed",Vector2i(80,80),0)
	for y in range(79,82):
		for x in range(79,83):
			if x in [79,82] or y in [79,81]: world._structure("wood_wall",Vector2i(x,y),0)
	check.call("BED/sealed_bed_rejects_with_clear_access_action",ColonyBeds.quote(world,1,bed.id).contains("unreachable") and person.bed!=bed.id and bed.user==0)
	world=ColonyTests.world();person=world.citizens[0];bed=world._structure("bed",Vector2i(70,65),0)
	person.fullness=1000;person.rest=200;person.bed_memory_until=world.tick+100;person.bed_sleep_ticks=100
	var sleep: Dictionary = world._job("sleep","","",person.bed,Vector2i(person.x,person.y),0)
	sleep.worker=person.id;sleep.state="Working";person.job=sleep.id
	person.progress=500;person.edge_x=person.x+1;person.edge_y=person.y
	check.call("BED/reassignment_retargets_existing_sleep_without_resetting_edge_progress",ColonyBeds.command(world,{"citizen":1,"target":bed.id})=="accepted" and sleep.state=="Moving" and sleep.target==bed.id and sleep.work_x==bed.x and person.progress==500 and person.x==65 and person.bed_sleep_ticks==0 and person.bed_memory_until==world.tick+100)
	var loaded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/bed_reassignment_mid_edge_roundtrips_exactly",loaded.has("world") and loaded.world.canonical_hash()==world.canonical_hash(),str(loaded.get("error","")))
	for tick in range(160): world.step()
	check.call("BED/reassigned_sleeper_walks_to_new_bed_and_rests_there",sleep.state=="Working" and Vector2i(person.x,person.y)==Vector2i(bed.x,bed.y) and person.rest>200 and person.bed_sleep_ticks>0)
	check.call("BED/unassign_uses_ground_sleep_and_releases_bed",ColonyBeds.command(world,{"citizen":1,"target":0})=="accepted" and person.bed==0 and bed.user==0 and sleep.target==0 and person.bed_sleep_ticks==0 and ColonyBeds.description(world,person).contains("80/hour"))
	world.step();loaded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/unassigned_sleep_roundtrip_and_conservation",loaded.has("world") and loaded.world.canonical_hash()==world.canonical_hash() and world.invariant_errors().is_empty(),str(loaded.get("error",world.invariant_errors())))
	person.rest=50
	check.call("BED/reassignment_preserves_exhausted_nearest_ground_sleep",ColonyBeds.command(world,{"citizen":1,"target":bed.id})=="accepted" and person.bed==bed.id and sleep.target==0 and sleep.reason.contains("Exhausted") and Vector2i(sleep.work_x,sleep.work_y)==Vector2i(person.x,person.y))
	world=ColonyTests.world()
	var request: Dictionary = ColonyPopulation.offer(world)
	var roll: Dictionary = world._structure("bedroll",Vector2i(74,64),0)
	var outdoor: Dictionary = world._structure("bed",Vector2i(80,80),0)
	bed=quiet_room(world)
	check.call("BED/newcomer_prefers_roofed_bed_over_older_roll_and_outdoor_bed",ColonyPopulation.acceptance(world,request).get("bed")==bed.id and roll.id<outdoor.id and outdoor.id<bed.id)
	bed.user=1
	check.call("BED/newcomer_next_prefers_free_real_bed",ColonyPopulation.acceptance(world,request).get("bed")==outdoor.id)
	world=ColonyTests.world();person=world.citizens[0];bed=quiet_room(world)
	var quiet: Dictionary = {"actor":1,"kind":"quiet_bed"}
	check.call("BED/quiet_bed_request_can_be_fulfilled_by_public_assignment",not ColonySocial.fulfilled(world,quiet) and ColonyBeds.command(world,{"citizen":1,"target":bed.id})=="accepted" and ColonySocial.fulfilled(world,quiet))
	var legacy: PackedByteArray = FileAccess.get_file_as_bytes("res://tests/fixtures/campaign-replay-7200.brackenward")
	var payload: Dictionary = ColonyState.unpack(JSON.parse_string(JSON.parse_string(legacy.get_string_from_utf8()).payload))
	loaded=ColonyCodec.decode(legacy)
	var expected: Dictionary = payload.duplicate(true);expected.schema_revision=21
	check.call("SAVE/schema_twenty_upgrade_only_changes_revision",loaded.has("world") and loaded.world.payload()==expected and payload.schema_revision==20,str(loaded.get("error","")))

static func quiet_room(world: ColonyWorld) -> Dictionary:
	for y in range(75,79):
		for x in range(75,79):
			if x in [75,78] or y in [75,78]: world._structure("door" if Vector2i(x,y)==Vector2i(77,78) else "wood_wall",Vector2i(x,y),0)
	return world._structure("bed",Vector2i(76,76),0)
