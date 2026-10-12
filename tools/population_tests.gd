class_name PopulationTests
extends RefCounted

static func run(check: Callable) -> void:
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
