class_name SurvivalTests
extends RefCounted

static func run(check: Callable) -> void:
	turnip_growth(check)
	LivingHeatTests.run(check)
	RoomGeometryTests.run(check)
	var w: ColonyWorld = ColonyTests.world()
	w.queue_command("field", {"crop":"turnip", "tiles":[Vector2i(74,54)]})
	w.step()
	var field: Dictionary = w.fields[0]
	field.prepared = true
	field.planted = true
	for fertility in [750,1000,1250]:
		field.fertility = fertility
		field.growth = 0
		field.growth_rem = 0
		for i in range(7200):
			w.tick += 1
			ColonyAgriculture.advance(w)
		check.call("M2/crop_day_growth_%d" % fertility, field.growth == fertility and field.growth_rem == 0)
	w.tick = 25 * 7200
	var before: int = field.growth
	for i in range(7200):
		w.tick += 1
		ColonyAgriculture.advance(w)
	check.call("M2/off_season_growth_pauses", field.growth == before and field.reason.begins_with("Dormant"))
	w = ColonyTests.world()
	var berry: Dictionary = w._make_stack("berry",4,"ground",0,Vector2i(70,65),true)
	berry.age = 21598
	w.step()
	berry.location = "store"
	berry.owner = w.stores[0].id
	w.step()
	check.call("M2/moving_food_never_refreshes_age", berry.count == 0 and w.ledger.spoiled.get("berry",0) == 4 and w.invariant_errors().is_empty())
	w = ColonyTests.world()
	var forecast: Dictionary = FoodForecast.calculate(w)
	check.call("M2/stored_runway_excludes_rations",forecast.portions == 24 and forecast.ticks == 21600)
	w.use_rations = true
	forecast = FoodForecast.calculate(w)
	check.call("M2/explicit_reserve_policy_adds_one_day",forecast.portions == 32 and forecast.ticks == 28800)
	for stack in w.stacks:
		if stack.item == "meal": stack.age = 28800-150
	w.use_rations = false
	forecast = FoodForecast.calculate(w)
	check.call("M2/runway_simulates_expiring_food",forecast.portions == 24 and forecast.ticks == 150)
	for store_kind in ["granary","cellar"]:
		w = ColonyTests.world()
		var storage: Dictionary = w._structure(store_kind,Vector2i(72,68),0)
		w.stores.append({"id":storage.id,"tiles":[Vector2i(72,68)],"capacity":600,"priority":2,"filters":w.definitions.items.keys()})
		var fruit: Dictionary = w._make_stack("berry",1,"store",storage.id,Vector2i(72,68),true)
		for i in range(100):
			w.tick += 1
			ColonyLiving.advance(w)
		check.call("M2/preservation_age_"+store_kind,fruit.age == (50 if store_kind == "granary" else 25) and fruit.age_rem == 0)
	w = ColonyTests.world()
	w.tick = 24*7200
	for resident in w.citizens:
		resident.x = 70
		resident.y = 62
	for i in range(1800):
		w.tick += 1
		ColonyLiving.advance(w)
	check.call("M2/heating_consumes_one_real_wood_per_six_hours",w.structures[5].fuel == 3 and w.total("wood") == 43 and w.invariant_errors().is_empty())
	w.weather = "cold_snap"
	check.call("M2/hearth_protects_cold_snap",w.comfortable(w.citizens[0]))
	w.citizens[0].x = 90
	w.citizens[0].y = 90
	var cold_job: Dictionary = w._job("gather","Gathering","Field",w.resources[0].id,Vector2i(50,54),16000)
	check.call("M2/cold_outdoor_work_slowdown",not w.comfortable(w.citizens[0]) and w._rate(w.citizens[0],cold_job) == 80 and w.citizens[0].health == 100)
	w = ColonyTests.world()
	w.queue_command("build",{"definition":"bed","x":74,"y":63,"rotation":0})
	w.step()
	var pinned: Dictionary = w.jobs[0]
	w.queue_command("pin",{"target":pinned.id,"citizen":2})
	w.step()
	for i in range(50): w.step()
	check.call("M2/pinned_task_uses_requested_worker",pinned.worker == 2 and w.citizens[1].job == pinned.id)
	w.queue_command("cancel",{"target":pinned.id})
	w.step()
	check.call("M2/cancel_expires_pin",w.citizens[1].pinned_job == 0 and w.invariant_errors().is_empty())
	w = ColonyTests.world()
	var eater: Dictionary = w._job("eat","","",1,Vector2i(65,65),2000)
	eater.state = "Working"
	eater.worker = 1
	w.citizens[0].job = eater.id
	w.queue_command("schedule",{"citizen":1,"shift":"Night shift"})
	w.step()
	check.call("M2/shift_waits_for_needs_task",w.citizens[0].shift == "Normal" and w.citizens[0].pending_shift == "Night shift")
	w._complete(w.citizens[0],eater)
	check.call("M2/shift_applies_after_needs_task",w.citizens[0].shift == "Night shift" and w.citizens[0].pending_shift.is_empty())
	w = ColonyTests.world()
	w.queue_designation([Vector2i(68,68),Vector2i(68,69)])
	w.step()
	var general: Dictionary = w.stores[1]
	w.queue_command("stock_filter",{"target":w.stores[0].id,"filters":w.definitions.items.keys().filter(func(item:String)->bool:return item != "fiber"),"priority":2})
	w.step()
	for i in range(800): w.step()
	check.call("M2/invalid_store_filter_moves_real_goods",w.stacks.any(func(stack:Dictionary)->bool:return stack.item == "fiber" and stack.count > 0 and stack.location == "store" and stack.owner == general.id) and w.total("fiber") == 12 and w.invariant_errors().is_empty())
	# Roof detection includes friendly doors as boundaries and reacts to removal.
	w = ColonyTests.world()
	for x in range(74,79):
		for y in [66,70]: w._structure("wood_wall",Vector2i(x,y),0)
	for y in range(67,70):
		for x in [74,78]: w._structure("wood_wall",Vector2i(x,y),0)
	var door: Dictionary = w.structures[-1]
	door.definition = "door"
	check.call("M2/room_enclosed_with_friendly_door", w.roofed(Vector2i(76,68)) and w.room_tiles.size() == 9)
	w.structures.erase(door)
	w.rooms_dirty = true
	check.call("M2/removing_boundary_unroofs_room", not w.roofed(Vector2i(76,68)))
	# The original downloadable M1 fixture migrates without editing its bytes.
	var original: PackedByteArray = FileAccess.get_file_as_bytes("res://tests/fixtures/m1-held-inputs.brackenward")
	var migrated: Dictionary = ColonyCodec.decode(original)
	check.call("M2/M1_snapshot_migration", migrated.has("world") and migrated.world.jobs[0].work == 0 and migrated.world.fields.is_empty() and FileAccess.get_file_as_bytes("res://tests/fixtures/m1-held-inputs.brackenward") == original, str(migrated.get("error","")))
	# Old journals replay under frozen M1 rules, then migrate as one snapshot.
	var legacy: M1World = M1World.new(M1Catalog.load_data())
	var initial: PackedByteArray = M1Codec.encode(legacy)
	legacy.queue_command("build", {"definition":"bed","x":74,"y":63,"rotation":0})
	for i in range(71): legacy.step()
	var store: ColonyStore = ColonyStore.new()
	store.directory = "user://migrate-journal-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(store.directory)
	var file: FileAccess = FileAccess.open(store.directory.path_join("snapshot-0000000001.brackenward"),FileAccess.WRITE)
	file.store_buffer(initial)
	file.close()
	file = FileAccess.open(store.directory.path_join("journal-0000000001.frames"),FileAccess.WRITE)
	file.store_buffer(ColonyJournal.frame({"sequence":"1","kind":"command","tick":legacy.command_trace[0].tick,"command":legacy.command_trace[0].command}))
	file.store_buffer(ColonyJournal.frame({"sequence":"2","kind":"tick","tick":legacy.tick}))
	file.close()
	var recovered: Dictionary = store.load_latest()
	var expected: Dictionary = ColonyCodec.decode(M1Codec.encode(legacy))
	check.call("M2/M1_journal_replay_before_migration", recovered.has("world") and expected.has("world") and recovered.world.canonical_hash() == expected.world.canonical_hash(), str(recovered.get("error","")))
	for name in DirAccess.get_files_at(store.directory):
		DirAccess.remove_absolute(store.directory.path_join(name))
	DirAccess.remove_absolute(store.directory)
	# Four-day turnips need early foraging as well as the field. Use real orders.
	# Competent first-week plan: prepare/sow twenty-four starter turnip tiles, preserve
	# default cooking, and grow/harvest/haul every cycle through the real scheduler.
	w = ColonyTests.world()
	var tiles: Array[Vector2i] = []
	for y in range(52,58):
		for x in range(74,78): tiles.append(Vector2i(x,y))
	w.queue_command("field", {"crop":"turnip", "tiles":tiles})
	for resource in w.resources:
		if resource.definition in ["berry_bush","mushroom_patch"]: w.queue_command("gather",{"target":resource.id})
	var invariant_failures: Array[String] = []
	var minimum_health: int = 100
	for i in range(57600):
		w.step()
		if i % 300 == 0:
			invariant_failures.append_array(w.invariant_errors())
			for citizen in w.citizens:
				minimum_health = mini(minimum_health,citizen.health)
	check.call("M2/eight_day_four_person_sustainable_colony", minimum_health == 100 and w.citizens.all(func(c:Dictionary)->bool:return not c.departed) and w.ledger.produced.get("vegetable",0) >= 96 and w.ledger.produced.get("meal",0) > 24, str({"health":minimum_health,"produced":w.ledger.produced,"food":w.available("meal")}))
	check.call("M2/eight_day_inventory_conservation", invariant_failures.is_empty(),str(invariant_failures.slice(0,8)))
	var roundtrip: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("M2/fields_and_needs_roundtrip", roundtrip.has("world") and roundtrip.world.canonical_hash() == w.canonical_hash(),str(roundtrip.get("error","")))

static func turnip_growth(check: Callable) -> void:
	for fertility in [750,1000,1250]:
		var world: ColonyWorld = ColonyTests.world()
		ColonyAgriculture.designate(world,{"crop":"turnip","tiles":[Vector2i(74,54)]})
		var field: Dictionary = world.fields[0];field.prepared=true;field.planted=true;field.fertility=fertility
		var started: int = world.tick
		var duration: int = (4000*7200+fertility-1)/fertility
		for index in range(duration-1):
			world.tick+=1;ColonyAgriculture.advance(world)
			if index==14399: check.call("CROP/turnips_still_growing_after_two_days_at_%d_fertility" % fertility,field.ripe_tick==0)
		check.call("CROP/turnips_do_not_ripen_before_exact_duration_%d" % fertility,field.ripe_tick==0 and field.growth<4000)
		world.tick+=1;ColonyAgriculture.advance(world)
		check.call("CROP/turnips_ripen_after_several_days_at_%d_fertility" % fertility,field.ripe_tick==started+duration and field.growth==4000 and duration>=23040)
