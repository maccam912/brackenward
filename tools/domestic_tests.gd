class_name DomesticTests
extends RefCounted

static func setup() -> ColonyWorld:
	var world: ColonyWorld = ColonyTests.world()
	world.researched.append("husbandry")
	for x in range(73,81):
		world._structure("fence",Vector2i(x,51),0);world._structure("fence",Vector2i(x,57),0)
	for y in range(52,57):
		world._structure("pen_gate" if y==54 else "fence",Vector2i(73,y),0);world._structure("fence",Vector2i(80,y),0)
	world._structure("barn",Vector2i(75,53),0)
	var tiles: Array[Vector2i] = []
	for y in range(52,57):
		for x in range(74,80): tiles.append(Vector2i(x,y))
	world.queue_command("pen",{"tiles":tiles});world.step()
	return world

static func run(check: Callable) -> void:
	var world: ColonyWorld = setup()
	var pen: Dictionary = world.domestic_state.pens[0]
	check.call("PEN/enclosed_thirty_tiles_and_six_shelter_slots",ColonyDomestic.status(world,pen).capacity==6 and not pen.breeding)
	var broken: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="fence" and s.x==80 and s.y==54)[0]
	world.structures.erase(broken);world.record_indexes.clear();world.navigation_dirty=true
	check.call("PEN/open_perimeter_explains_repair",ColonyDomestic.acquire_error(world,"hen",pen.id).contains("perimeter"))
	world=setup();pen=world.domestic_state.pens[0]
	world.researched.clear()
	check.call("PEN/husbandry_required_before_acquisition",ColonyDomestic.acquire_error(world,"hen",pen.id).contains("Husbandry"))
	world.researched.append("husbandry")
	var hen: Dictionary = ColonyDomestic.acquire(world,"hen",pen.id,Vector2i(66,63)).animal
	var goat: Dictionary = ColonyDomestic.acquire(world,"pack_goat",pen.id,Vector2i(66,63)).animal
	var grain: Dictionary = world._make_stack("grain",16,"store",world.stores[0].id,Vector2i(66,63),true)
	grain.age=500
	for i in range(700): world.step()
	check.call("ANIMALS/handlers_lead_through_gate_to_pen",pen.tiles.has(Vector2i(hen.x,hen.y)) and pen.tiles.has(Vector2i(goat.x,goat.y)) and world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="lead_animal" and j.state=="Complete").size()==2)
	check.call("ANIMALS/feed_transport_keeps_real_age_and_ledger",ColonyDomestic.feed_count(world,hen.barn)==6 and world.stacks.any(func(s:Dictionary)->bool:return s.location=="animal_feed" and s.count==6 and s.age>=500) and world.ledger.consumed.get("grain",0)==0 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/pens_animals_and_feed_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world.tick=9000;ColonyWeather.initialize(world);ColonyDomestic.advance(world);ColonyDomestic.advance(world)
	check.call("ANIMALS/dawn_feed_once_and_pending_products",ColonyDomestic.feed_count(world,hen.barn)==3 and hen.pending==1 and goat.pending==2 and world.ledger.consumed.get("grain",0)==3)
	check.call("ANIMALS/products_require_collection_work",world.total("egg")==0 and world.total("milk")==0)
	for i in range(450): world.step()
	check.call("ANIMALS/four_wu_collection_mints_physical_outputs",world.ledger.produced.get("egg",0)==1 and world.ledger.produced.get("milk",0)==2 and world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="collect_animal" and j.state=="Complete" and j.required==4000).size()==2 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	goat.away=true
	world.tick=16200;ColonyWeather.initialize(world);ColonyDomestic.advance(world)
	check.call("ANIMALS/expedition_goat_has_no_home_feed_or_milk",goat.pending==0 and goat.last_fed==1)
	world=setup();pen=world.domestic_state.pens[0]
	hen=ColonyDomestic.acquire(world,"hen",pen.id,pen.tiles[0]).animal
	for day in range(1,3): world.tick=day*7200+1800;ColonyDomestic.advance(world)
	check.call("ANIMALS/two_unfed_days_have_visible_grace",hen.health==25 and hen.unfed==2 and pen.reason.contains("Feed"))
	world.tick=23400;ColonyDomestic.advance(world)
	check.call("ANIMALS/third_unfed_day_loses_ten_health",hen.health==15)
	world._make_stack("vegetable",2,"animal_feed",hen.barn,Vector2i(75,53),true)
	world.tick=30600;ColonyDomestic.advance(world)
	check.call("ANIMALS/fresh_feed_restores_ten_per_day",hen.health==25 and hen.unfed==0)
	for i in range(3): world.tick += 7200;world._make_stack("grain",1,"animal_feed",hen.barn,Vector2i(75,53),true);ColonyDomestic.advance(world)
	check.call("ANIMALS/uncollected_products_cap_at_two_days",hen.pending==2)
	world=setup();pen=world.domestic_state.pens[0]
	for i in range(6): ColonyDomestic.acquire(world,"hen",pen.id,pen.tiles[0])
	check.call("PEN/seventh_animal_rejected_without_spare_shelter",ColonyDomestic.acquire_error(world,"hen",pen.id).contains("spare"))
	world=setup();pen=world.domestic_state.pens[0]
	hen=ColonyDomestic.acquire(world,"hen",pen.id,pen.tiles[0]).animal
	var mate: Dictionary = ColonyDomestic.acquire(world,"hen",pen.id,pen.tiles[1]).animal
	hen.last_fed=0;mate.last_fed=0;world.domestic_state.feed_day=0
	world.queue_command("breeding",{"target":pen.id,"enabled":true});world.step()
	check.call("ANIMALS/breeding_starts_eight_day_timer",pen.breeding and pen.next_birth==world.tick+57600)
	world.tick=pen.next_birth;ColonyWeather.initialize(world);ColonyDomestic._breed(world)
	var baby: Dictionary = world.domestic_state.animals[-1]
	check.call("ANIMALS/one_juvenile_and_four_day_maturity",world.domestic_state.animals.size()==3 and baby.juvenile_until==world.tick+28800 and baby.pending==0)
	check.call("ANIMALS/juvenile_integer_feed_alternates",ColonyDomestic.demand(world,baby,baby.born/7200)==0 and ColonyDomestic.demand(world,baby,baby.born/7200+1)==1)
	world.tick=baby.juvenile_until
	check.call("ANIMALS/mature_hen_uses_full_feed",ColonyDomestic.demand(world,baby,world.tick/7200)==1)
	world=setup();pen=world.domestic_state.pens[0]
	for i in range(6):
		var adult: Dictionary = ColonyDomestic.acquire(world,"hen",pen.id,pen.tiles[0]).animal;adult.last_fed=0
	world.domestic_state.feed_day=0;pen.breeding=true;pen.next_birth=world.tick
	ColonyDomestic._breed(world)
	check.call("ANIMALS/blocked_birth_has_no_queued_burst",world.domestic_state.animals.size()==6 and pen.next_birth==world.tick+57600 and not pen.reason.is_empty())
	world.domestic_state.animals[0].health=0;ColonyDomestic._breed(world)
	check.call("ANIMALS/later_free_slot_does_not_trigger_old_birth",world.domestic_state.animals.size()==6)
	world=setup();pen=world.domestic_state.pens[0]
	goat=ColonyDomestic.acquire(world,"pack_goat",pen.id,pen.tiles[0]).animal
	world.queue_command("slaughter",{"target":goat.id})
	for i in range(700): world.step()
	check.call("ANIMALS/slaughter_ten_wu_exact_goat_yields",goat.health==0 and world.ledger.produced.get("meat",0)==8 and world.ledger.produced.get("leather",0)==3 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="slaughter" and j.state=="Complete" and j.required==10000) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var result: int = world.queue_command("field",{"tiles":[pen.tiles[0]],"crop":"turnip"});world.step()
	check.call("PEN/field_cannot_overlap_pen",world.receipts[result].contains("pen"))
	result=world.queue_command("stockpile",{"tiles":[pen.tiles[0]]});world.step()
	check.call("PEN/stockpile_cannot_overlap_pen",world.receipts[result].contains("pen"))
	var old: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-care.brackenward"))
	check.call("SAVE/domestic_migration_retains_care_and_wildlife",old.has("world") and old.world.citizens[2].health==27 and old.world.wildlife_state.animals.size()==16 and old.world.domestic_state.animals.is_empty())
	world=setup();pen=world.domestic_state.pens[0]
	hen=ColonyDomestic.acquire(world,"hen",pen.id,pen.tiles[0]).animal
	broken=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="fence" and s.x==80 and s.y==54)[0]
	world.structures.erase(broken);world.record_indexes.clear();world.navigation_dirty=true
	world._make_stack("grain",2,"animal_feed",hen.barn,Vector2i(75,53),true)
	world.tick=9000;ColonyWeather.initialize(world);ColonyDomestic.advance(world)
	check.call("ANIMALS/open_fence_does_not_disable_accessible_feed",hen.last_fed==1 and hen.pending==1 and hen.health==25)
	var damaged: Dictionary = world.payload().duplicate(true);damaged.domestic_state.animals[0].barn=999999
	check.call("SAVE/rejects_unknown_animal_shelter",ColonyCodec.restore(damaged).has("error"))
	world._make_stack("grain",24,"animal_feed",hen.barn,Vector2i(75,53),true)
	check.call("SAVE/rejects_overfull_feed_buffer",ColonyCodec.decode(ColonyCodec.encode(world)).has("error"))
