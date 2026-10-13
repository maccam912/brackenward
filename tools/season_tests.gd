class_name SeasonTests
extends RefCounted

static func run(check: Callable) -> void:
	var w: ColonyWorld = ColonyTests.world()
	check.call("WEATHER/initial_three_known_days",w.weather_state.days.slice(0,3).map(func(d:Dictionary)->String:return d.kind) == ["clear","rain","clear"])
	var first: Dictionary = w.weather_state.duplicate(true)
	var restored: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("WEATHER/forecast_rng_survives_reload",restored.has("world") and restored.world.weather_state == first)
	var extremes: Array[int] = []
	var early_safe: bool = true
	var same_forecasts: bool = true
	for day in range(1,300):
		w.tick = day*7200
		ColonyWeather.advance(w)
		if restored.has("world"):
			restored.world.tick = w.tick
			ColonyWeather.advance(restored.world)
			same_forecasts = same_forecasts and restored.world.weather_state == w.weather_state
		if w.weather in ["flood","cold_snap"]:
			extremes.append(day)
			if day < 6: early_safe = false
	var spacing: bool = true
	for i in range(1,extremes.size()): spacing = spacing and extremes[i]-extremes[i-1] >= 4
	check.call("WEATHER/three_hundred_days_same_after_reload",same_forecasts)
	check.call("WEATHER/extremes_start_day_seven_spaced_four_days",early_safe and spacing and not extremes.is_empty(),str(extremes))
	check.call("WEATHER/forecast_always_three_days_ahead",w.weather_state.days[-1].day == 302 and ColonyWeather.validate(w.weather_state,w.tick))
	var mask: Array[Vector2i] = ColonyWeather.flood_mask(w)
	check.call("FLOOD/low_connected_band_only",mask.size() == 1024 and mask.all(func(p:Vector2i)->bool:return w.elevation(p) == 1) and not mask.has(Vector2i(74,54)) and not mask.has(Vector2i(33,63)))
	w = ColonyTests.world()
	w.queue_command("field",{"crop":"turnip","tiles":[Vector2i(38,54)]})
	w.step()
	var field: Dictionary = w.fields[0]
	field.planted = true
	field.growth = w.definitions.crops.turnip.growth
	field.ripe_tick = w.tick
	field.yield_count = 4
	w._make_stack("berry",5,"ground",0,Vector2i(38,54),true)
	w._make_stack("wood",5,"ground",0,Vector2i(38,54),true)
	w._make_stack("herb",5,"ground",0,Vector2i(38,54),true)
	w._make_stack("berry",5,"ground",0,Vector2i(74,54),true)
	var cart: Dictionary = w._structure("supply_cart",Vector2i(39,55),0)
	w.stores.append({"id":cart.id,"tiles":[Vector2i(39,55)],"capacity":300,"priority":2,"filters":w.definitions.items.keys()})
	w._make_stack("meal",6,"store",cart.id,Vector2i(39,55),true)
	w._make_stack("berry",4,"carry",1,Vector2i(38,54),true)
	w.weather = "flood"
	w.tick = 6*7200+1799
	ColonyWeather.initialize(w)
	w.tick += 1
	var preview: Array = w.weather_state.days[0].mask.duplicate()
	var before: int = w.total("berry")
	var before_meals: int = w.total("meal")
	var wood: int = w.total("wood")
	var herb: int = w.total("herb")
	ColonyWeather.advance(w)
	check.call("FLOOD/preview_equals_actual_coverage",preview == w.weather_state.flooded)
	check.call("FLOOD/ripe_yield_and_odd_food_loss_once",field.yield_count == 2 and w.total("berry") == before-2)
	check.call("FLOOD/protected_cart_carry_high_ground_and_nonfood",w.total("meal") == before_meals and w.total("wood") == wood and w.total("herb") == herb)
	ColonyWeather.advance(w)
	check.call("FLOOD/repeated_onset_cannot_duplicate_loss",field.yield_count == 2 and w.total("berry") == before-2 and w.invariant_errors().is_empty(),str(w.invariant_errors()))
	field.ripe_tick = 0
	field.growth = 1000
	ColonyAgriculture.advance(w)
	check.call("FLOOD/crops_pause_with_explanation",field.growth == 1000 and field.reason.begins_with("Flooded"))
	w.tick = 6*7200+5400
	ColonyWeather.advance(w)
	check.call("FLOOD/ends_at_eighteen",w.weather_state.flooded.is_empty() and not w.is_flooded(Vector2i(38,54)))
	for kind in ["clear","rain","snow"]:
		w = ColonyTests.world()
		w.weather = kind
		var actor: Dictionary = w.citizens[0]
		actor.traits = ["Kind","Homebody"]
		actor.x = 80; actor.y = 80; actor.edge_x = 80; actor.edge_y = 80
		var cost: int = {"clear":10,"rain":15,"snow":12}[kind]
		var reached: bool = false
		for i in range(cost):
			w.path_requests = 0
			reached = w._walk(actor,Vector2i(81,80))
			if i < cost-1 and reached: break
		check.call("MOVE/exact_%s_tile_ticks" % kind,reached and actor.x == 81 and actor.move_base_rem == 0)
	w = ColonyTests.world()
	w.queue_command("field",{"crop":"turnip","tiles":[Vector2i(74,54)]})
	for i in range(300): w.step()
	w.queue_command("early_harvest",{"target":w.fields[0].id})
	w.step()
	check.call("CROP/early_harvest_below_half_rejected",w.receipts[2].contains("50%") and not w.jobs.any(func(j:Dictionary)->bool:return j.kind == "harvest"))
	for i in range(9000): w.step()
	w.queue_command("early_harvest",{"target":w.fields[0].id})
	for i in range(600): w.step()
	check.call("CROP/early_harvest_real_work_and_proportional_output",w.receipts[3] == "accepted" and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "harvest" and j.definition == "early_harvest" and j.state == "Complete") and w.ledger.produced.get("vegetable",0) == 2 and w.invariant_errors().is_empty(),str(w.ledger.produced))
	var fixture: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m3-weather.brackenward"))
	check.call("SAVE/M3_android_recovery_fixture_roundtrip",fixture.has("world") and fixture.world.tick == 3135 and ColonyCodec.decode(ColonyCodec.encode(fixture.world)).world.canonical_hash() == fixture.world.canonical_hash(),str(fixture.get("error","")))
	legacy_and_journal(check)
	irrigation_mutations(check)

static func irrigation_mutations(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	ColonyAgriculture.designate(world,{"crop":"turnip","tiles":[Vector2i(74,54)]})
	var field: Dictionary = world.fields[0]
	field.prepared=true;field.planted=true;field.fertility=1000
	world.weather="drought"
	ColonyAgriculture.advance(world)
	var well: Dictionary = world._structure("well",Vector2i(75,54),0)
	ColonyAgriculture.advance(world)
	check.call("CROP/new_well_changes_next_tick_drought_growth",field.growth_rem==1500 and field.reason=="Growing: well stabilizes drought")
	well.health=0
	ColonyAgriculture.advance(world)
	well.health=100;well.x=95
	ColonyAgriculture.advance(world)
	check.call("CROP/destroyed_or_moved_well_stops_irrigation_immediately",field.growth_rem==2500 and field.reason.contains("half rate"))
	world.weather="clear"
	ColonyAgriculture.advance(world)
	check.call("CROP/clear_weather_restores_full_growth_without_well",field.growth_rem==3500 and field.reason=="Growing")

static func legacy_and_journal(check: Callable) -> void:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://tests/fixtures/m2-fields-and-work.brackenward")
	var legacy: Dictionary = M2Codec.decode(bytes)
	var migrated: Dictionary = ColonyCodec.decode(bytes)
	check.call("SAVE/M2_public_fixture_forward_migration",legacy.has("world") and migrated.has("world") and legacy.world.tick == migrated.world.tick and legacy.world.fields == migrated.world.fields and legacy.world.ledger.produced.keys().all(func(item:Variant)->bool:return migrated.world.ledger.produced.get(item) == legacy.world.ledger.produced[item]),str(migrated.get("error","")))
	var root: String = "user://m3-compat-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	var old: M2World = M2World.new(M2Catalog.load_data())
	var original: PackedByteArray = M2Codec.encode(old)
	var file: FileAccess = FileAccess.open(root.path_join("snapshot-0000000001.brackenward"),FileAccess.WRITE)
	file.store_buffer(original); file.close()
	old.queue_command("gather_area",{"definition":"tree","tiles":[Vector2i(55,54),Vector2i(53,54)]})
	for i in range(75): old.step()
	file = FileAccess.open(root.path_join("journal-0000000001.frames"),FileAccess.WRITE)
	file.store_buffer(ColonyJournal.frame({"sequence":"1","kind":"command","tick":old.command_trace[0].tick,"command":old.command_trace[0].command}))
	file.store_buffer(ColonyJournal.frame({"sequence":"2","kind":"tick","tick":old.tick}))
	file.close()
	var store: ColonyStore = ColonyStore.new()
	store.directory = root
	var result: Dictionary = store.load_latest()
	var expected: Dictionary = ColonyCodec.decode(M2Codec.encode(old))
	check.call("SAVE/M2_journal_replays_original_rules_before_migration",result.has("world") and expected.has("world") and result.world.canonical_hash() == expected.world.canonical_hash(),str(result.get("error","")))
	check.call("SAVE/M2_original_and_journal_backups_retained",FileAccess.get_file_as_bytes(root.path_join("migration-backup-snapshot-0000000001.brackenward")) == original and FileAccess.file_exists(root.path_join("migration-backup-journal-0000000001.frames")))
	var w: ColonyWorld = ColonyTests.world()
	store = ColonyStore.new(); store.directory = root.path_join("current")
	store.save(w)
	w.queue_command("gather_area",{"definition":"tree","tiles":[Vector2i(55,54)]})
	for i in range(80): w.step()
	store.checkpoint(w)
	result = store.load_latest()
	check.call("SAVE/current_journal_restores_verified_state_without_balance_replay",result.has("world") and result.world.canonical_hash() == w.canonical_hash())
	var record: Dictionary = {"sequence":"1","kind":"tick","tick":w.tick,"state":w.payload().duplicate(true)}
	record.state.session_id = "wrong-campaign"
	var parsed: Dictionary = ColonyJournal.read(ColonyJournal.frame(record))
	check.call("SAVE/journal_checkpoint_rejects_foreign_campaign",parsed.has("records") and ColonyJournal.replay(w,parsed.records).has("error"))
	CampaignTests.remove_tree(root)
