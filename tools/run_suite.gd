extends SceneTree

var suite: String = ""
var failures: Array[String] = []
var cases: Array[Dictionary] = []
var started: int = 0

func _initialize() -> void:
	started = Time.get_ticks_msec()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] != "--suite" or not args[1] in ["unit", "integration", "ui", "colony", "survival", "persistence", "seasons", "people", "production", "care", "generation", "nature", "wildlife", "domestic", "construction", "equipment", "maintenance", "population", "trade", "region", "fire", "defense", "director", "opportunity", "charter", "chronicle", "scheduler", "tutorial"]:
		printerr("Usage: -- --suite unit|integration|ui|colony|survival|persistence|seasons|people|production|care|generation|nature|wildlife|domestic|construction|equipment|maintenance|population|trade|region|fire|defense|director|opportunity|charter|chronicle|scheduler|tutorial. Unknown flags/suites are errors.")
		quit(2)
		return
	suite = args[1]
	call_deferred("run")

func check(name: String, condition: bool, detail: String = "") -> void:
	cases.append({"name": name, "passed": condition, "detail": detail})
	if not condition:
		failures.append(name + ": " + detail)
		printerr("FAIL ", name, " ", detail)
	else:
		print("PASS ", name)

func run() -> void:
	match suite:
		"unit": unit()
		"integration": integration()
		"ui": await ui()
		"colony": ColonyTests.run(check)
		"survival": SurvivalTests.run(check)
		"persistence": CampaignTests.run(check)
		"seasons": SeasonTests.run(check)
		"people": SocialTests.run(check)
		"production": ProductionTests.run(check)
		"care": CareTests.run(check)
		"generation": GenerationTests.run(check)
		"nature": NatureTests.run(check)
		"wildlife": WildlifeTests.run(check)
		"domestic": DomesticTests.run(check)
		"construction": ConstructionTests.run(check)
		"equipment": EquipmentTests.run(check)
		"maintenance": MaintenanceTests.run(check)
		"population": PopulationTests.run(check)
		"trade": TradeTests.run(check)
		"region": RegionTests.run(check)
		"fire": FireTests.run(check)
		"defense": DefenseTests.run(check)
		"director": DirectorTests.run(check)
		"opportunity": OpportunityTests.run(check)
		"charter": CharterTests.run(check)
		"chronicle": ChronicleTests.run(check)
		"scheduler": SchedulerTests.run(check)
		"tutorial": TutorialTests.run(check)
	DirAccess.make_dir_recursive_absolute("res://reports")
	var report: String = '<testsuite name="%s" tests="%d" failures="%d">\n' % [suite, cases.size(), failures.size()]
	for item in cases:
		report += '  <testcase name="%s">' % item.name.xml_escape(true)
		if not item.passed:
			report += '<failure message="%s"/>' % item.detail.xml_escape(true)
		report += "</testcase>\n"
	report += "</testsuite>\n"
	var file: FileAccess = FileAccess.open("res://reports/%s.xml" % suite, FileAccess.WRITE)
	file.store_string(report)
	file.close()
	print("Discovered/run: %d; failures: %d; elapsed: %d ms; engine: %s; content: %s; host: %s" % [cases.size(), failures.size(), Time.get_ticks_msec() - started, Engine.get_version_info().string, ColonyWorld.CONTENT_VERSION + " (M0 regression fixture retained)", OS.get_name()])
	quit(0 if failures.is_empty() and not cases.is_empty() else 1)

func unit() -> void:
	var rng: ParkMiller = ParkMiller.new(1)
	check("SIM02/park_miller_golden", [rng.next(), rng.next(), rng.next()] == [48271, 182605794, 1291394886])
	check("SIM02/stream_isolation", ParkMiller.derive(0, 1, "meadow_reach", "terrain") != ParkMiller.derive(0, 1, "meadow_reach", "weather"))
	var world: PrototypeWorld = PrototypeWorld.new()
	world.queue_designation([Vector2i(74, 54)], 1)
	world.queue_designation([Vector2i(75, 54)], 1)
	check("M0/paused_command_pending", world.designations.is_empty())
	world.step()
	check("M0/command_idempotence", world.designations == [Vector2i(74, 54)] and world.receipts.size() == 1)
	world.queue_designation([Vector2i(76, 54)], 2, "other-session")
	world.step()
	check("M0/wrong_session", world.receipts[2] == "wrong_session" and world.designations.size() == 1)
	world.queue_designation([Vector2i(77, 54), Vector2i(33, 54)], 3)
	world.step()
	check("M0/atomic_invalid_area", world.receipts[3] == "invalid_tile" and world.designations.size() == 1)
	var gesture: GestureState = GestureState.new()
	gesture.begin(0, Vector2(10, 10))
	gesture.move(0, Vector2(20, 10))
	check("UI01/pan_never_taps", gesture.end(0, Vector2(20, 10)).is_empty())
	gesture.begin(0, Vector2(10, 10))
	gesture.begin(1, Vector2(100, 10))
	gesture.end(1, Vector2(100, 10))
	check("UI01/second_finger_suppresses_tap", gesture.end(0, Vector2(10, 10)).is_empty())
	gesture.begin(0, Vector2(10, 10))
	check("UI01/long_press_chooser", gesture.elapse(0.46).get("kind") == "chooser")
	check("UI01/long_press_never_taps", gesture.end(0, Vector2(10, 10)).is_empty())
	gesture.mode = "paint"
	gesture.begin(0, Vector2(10, 10))
	check("UI01/paint_is_preview", gesture.move(0, Vector2(100, 100)).get("kind") == "paint")
	gesture.cancel()
	check("UI01/interruption_cancels", gesture.end(0, Vector2(100, 100)).is_empty())
	var runner: SimRunner = SimRunner.new(PrototypeWorld.new())
	runner.set_speed(4)
	check("M0/tick_cap", runner.advance_frame(1.0) == 8)
	var queued_ticks: int = runner.world.tick
	for i in range(4):
		runner.advance_frame(0.0)
	check("M0/backlog_not_dropped", runner.world.tick == queued_ticks + 32)
	runner.pause()
	var paused_tick: int = runner.world.tick
	runner.advance_frame(3600)
	check("SAVE07/no_paused_time", runner.world.tick == paused_tick and runner.accumulator == 0.0)
	var bytes: PackedByteArray = PrototypeCodec.encode(world)
	var decoded: Dictionary = PrototypeCodec.decode(bytes)
	check("SAVE01/prototype_roundtrip", decoded.has("world") and decoded.world.canonical_hash() == world.canonical_hash(), str(decoded.get("error", "payload mismatch: " + JSON.stringify(world.payload()) + " versus " + (JSON.stringify(decoded.world.payload()) if decoded.has("world") else "missing"))))
	var corrupt: PackedByteArray = bytes.duplicate()
	corrupt[corrupt.size() / 2] ^= 1
	check("SAVE05/checksum_reject", PrototypeCodec.decode(corrupt).has("error"))
	check("SAVE05/size_limit", PrototypeCodec.decode(PackedByteArray()).has("error"))
	var payload: Dictionary = world.payload()
	payload.citizens[0].x = 1.5
	var bad_payload: String = JSON.stringify(payload)
	var envelope: Dictionary = {"format": PrototypeCodec.FORMAT, "version": 1, "payload": bad_payload, "sha256": bad_payload.sha256_text()}
	check("SAVE05/fractional_position_reject", PrototypeCodec.decode(JSON.stringify(envelope).to_utf8_buffer()).has("error"))

func integration() -> void:
	var hashes: Array[String] = []
	for speed in [1, 2, 4]:
		var world: PrototypeWorld = PrototypeWorld.new()
		world.queue_designation([Vector2i(74, 54), Vector2i(75, 54)])
		var runner: SimRunner = SimRunner.new(world)
		runner.set_speed(speed)
		for frame in range(72000 / speed):
			runner.advance_frame(0.1)
		hashes.append(world.canonical_hash())
	check("SIM01/prototype_72000_ticks_speeds", hashes[0] == hashes[1] and hashes[1] == hashes[2], str(hashes))
	var world: PrototypeWorld = PrototypeWorld.new()
	world.queue_designation([Vector2i(74, 54)])
	for i in range(137):
		world.step()
	world.queue_designation([Vector2i(75, 54)])
	var restored: PrototypeWorld = PrototypeCodec.decode(PrototypeCodec.encode(world)).world
	for i in range(723):
		world.step()
		restored.step()
	check("SAVE01/pending_and_motion_replay", world.canonical_hash() == restored.canonical_hash())
	var store: PrototypeStore = PrototypeStore.new()
	store.directory = "user://test-m0-%d" % Time.get_ticks_usec()
	check("SAVE02/first_generation", store.save(world).is_empty())
	for i in range(4):
		world.step()
		store.save(world)
	check("SAVE02/three_verified_generations", DirAccess.get_files_at(store.directory).size() == 3)
	var generations: PackedStringArray = DirAccess.get_files_at(store.directory)
	generations.sort()
	var interrupted: FileAccess = FileAccess.open(store.directory.path_join("snapshot-9999999999.brackenward.tmp"), FileAccess.WRITE)
	interrupted.store_string("partial")
	interrupted.close()
	check("SAVE02/temporary_ignored", store.load_latest().world.canonical_hash() == world.canonical_hash())
	var damaged: FileAccess = FileAccess.open(store.directory.path_join(generations[-1]), FileAccess.WRITE)
	damaged.store_string("truncated")
	damaged.close()
	check("SAVE02/earlier_generation_recovered", store.load_latest().has("world"))
	for name in DirAccess.get_files_at(store.directory):
		DirAccess.remove_absolute(store.directory.path_join(name))
	DirAccess.remove_absolute(store.directory)

func ui() -> void:
	var ui_m0_directory: String = "user://ui-m0-%d" % Time.get_ticks_usec()
	var ui_colony_directory: String = "user://ui-colony-%d" % Time.get_ticks_usec()
	var game: GameSession = load("res://scenes/game.tscn").instantiate()
	game.world = PrototypeWorld.new()
	game.runner = SimRunner.new(game.world)
	game.store = PrototypeStore.new()
	game.store.directory = ui_m0_directory
	game.settings.path = ui_m0_directory.path_join("settings.json")
	root.add_child(game)
	await process_frame
	await process_frame
	game.close_sheet()
	var sizes: Array[Vector2i] = [Vector2i(360, 640), Vector2i(390, 844), Vector2i(640, 360), Vector2i(800, 1280), Vector2i(1280, 800), Vector2i(960, 600)]
	for viewport_size in sizes:
		root.size = viewport_size
		game.size = Vector2(viewport_size)
		for scale_factor in [1.0, 1.25, 1.5]:
			game.text_scale = scale_factor
			game.test_insets = Vector4(8, 12, 8, 12)
			game._build_theme()
			game._layout()
			await process_frame
			await process_frame
			var hit_targets: bool = true
			for item in game.controls:
				if is_instance_valid(item) and item.is_visible_in_tree():
					hit_targets = hit_targets and item.size.x >= 48 and item.size.y >= 48
			check("UI05/targets_%dx%d_%d" % [viewport_size.x, viewport_size.y, int(scale_factor * 100)], hit_targets)
			var navigation_visible: bool = true
			for item: Button in game.nav.get_children():
				navigation_visible = navigation_visible and item.position.x + item.size.x <= game.content.size.x + 1 and item.position.y + item.size.y <= game.nav.size.y + 1
			check("UI05/navigation_%dx%d_%d" % [viewport_size.x, viewport_size.y, int(scale_factor * 100)], navigation_visible, str(game.nav.get_children().map(func(item: Button) -> Array: return [item.text, item.position, item.size, item.get_combined_minimum_size()])))
			game.show_sheet("Menu")
			await process_frame
			await process_frame
			check("UI05/sheet_%dx%d_%d" % [viewport_size.x, viewport_size.y, int(scale_factor * 100)], game.sheet.size.x <= game.content.size.x and game.sheet.size.y <= game.content.size.y - 64, str([game.sheet.size, game.sheet.get_combined_minimum_size(), game.content.size, game.sheet.get_child(0).get_child(0).get_child(0).size]))
			game.close_sheet()
			game.begin_placement()
			await process_frame
			await process_frame
			check("UI03/confirm_clear_%dx%d_%d" % [viewport_size.x, viewport_size.y, int(scale_factor * 100)], not game.confirm_button.get_global_rect().intersects(game.speeds.get_global_rect()) and game.confirm_button.get_global_rect().end.y <= game.nav.get_global_rect().position.y)
			game.cancel_placement()
	root.size = Vector2i(960, 600)
	game.size = Vector2(960, 600)
	game.test_insets = Vector4.ZERO
	game.text_scale = 1.0
	game._build_theme()
	game._layout()
	game.begin_placement()
	var original_start: Vector2i = game.view.preview_start
	var original_end: Vector2i = game.view.preview_end
	game.view.gestures.begin(0, Vector2(100, 100))
	root.size = Vector2i(390, 844)
	game.size = Vector2(390, 844)
	await process_frame
	await process_frame
	check("UI06/rotation_preserves_preview", game.view.preview_start == original_start and game.view.preview_end == original_end and game.world.pending_commands.is_empty() and game.runner.speed == 0 and game.view.gestures.fingers.is_empty())
	root.size = Vector2i(960, 600)
	game.size = Vector2(960, 600)
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		var sample: Vector2 = game.view.get_global_transform() * game.view.tile_to_screen(Vector2(75.5, 54.5))
		game.view.preview_visible = false
		game.view.queue_redraw()
		await RenderingServer.frame_post_draw
		var before: Color = root.get_texture().get_image().get_pixelv(Vector2i(sample))
		game.view.preview_visible = true
		game.view.queue_redraw()
		await RenderingServer.frame_post_draw
		var after: Color = root.get_texture().get_image().get_pixelv(Vector2i(sample))
		check("UI03/preview_visible_over_terrain", before != after, str([before, after]))
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(200, 200)
	touch.pressed = true
	game.view._gui_input(touch)
	var emulated_mouse: InputEventMouseButton = InputEventMouseButton.new()
	emulated_mouse.device = -1
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	emulated_mouse.position = touch.position
	game.view._gui_input(emulated_mouse)
	check("UI01/touch_mouse_not_second_finger", game.view.gestures.fingers.size() == 1 and not game.view.gestures.multiple)
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(280, 240)
	game.view._gui_input(drag)
	touch.position = drag.position
	touch.pressed = false
	game.view._gui_input(touch)
	check("UI01/real_handler_preview_only", game.world.pending_commands.is_empty() and game.view.preview_visible)
	game.confirm_placement()
	game.confirm_placement()
	check("UI01/confirm_double_tap", game.world.pending_commands.size() == 1)
	game.set_speed(4)
	game.runner.advance_frame(0.1)
	check("M0/confirmed_area_applied", not game.world.designations.is_empty())
	var saved_tick: int = game.world.tick
	game.suspend()
	game.runner.advance_frame(3600)
	game.resume_from_background()
	check("SAVE07/resume_paused", game.world.tick == saved_tick and game.runner.speed == 0 and game.view.gestures.fingers.is_empty())
	game.close_sheet()
	game.speeds.get_child(0).grab_focus()
	var pause_key: InputEventKey = InputEventKey.new()
	pause_key.keycode = KEY_SPACE
	pause_key.pressed = true
	root.push_input(pause_key)
	check("UI12/space_over_button_focus", game.runner.speed == game.runner.previous_speed)
	root.push_input(pause_key)
	check("UI12/space_pauses_once", game.runner.speed == 0)
	game.select_citizen(1)
	game.view.follow_id = 1
	await process_frame
	await process_frame
	check("UI05/inspector_inside_viewport", game.inspector.position.y + game.inspector.size.y <= game.content.size.y - game.nav.size.y)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/m0-landscape.png")
		root.size = Vector2i(360, 640)
		game.size = Vector2(360, 640)
		game._layout()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/m0-portrait.png")
	game.queue_free()
	await process_frame
	var colony_game: GameSession = load("res://scenes/game.tscn").instantiate()
	colony_game.store.root_directory = ui_colony_directory
	colony_game.store.select_slot(1)
	colony_game.settings.path = ui_colony_directory.path_join("settings.json")
	root.add_child(colony_game)
	await process_frame
	colony_game.close_sheet()
	colony_game.show_sheet("Work")
	var gather_button: Button
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text == "Gather wood":
			gather_button = child
	check("M1/UI_gather_action_exists", gather_button != null)
	if gather_button != null:
		gather_button.pressed.emit()
		check("UI/gather_button_opens_preview_without_job",colony_game.placement.visible and colony_game.placement_kind == "gather" and colony_game.world.pending_commands.is_empty())
		var start: Vector2 = colony_game.view.tile_to_screen(Vector2(51.5,54.5))
		var end: Vector2 = colony_game.view.tile_to_screen(Vector2(55.5,57.5))
		colony_game.view.gestures.begin(0,start)
		colony_game.view._apply_intent(colony_game.view.gestures.move(0,end))
		colony_game.view._apply_intent(colony_game.view.gestures.end(0,end))
		check("UI/gather_rectangle_selects_six_trees",colony_game.world.gather_targets("tree",colony_game.view.preview_tiles()).size() == 6 and colony_game.world.pending_commands.is_empty(),colony_game._preview_text())
		await process_frame
		await process_frame
		colony_game.view.preview_start = Vector2i(55,54)
		colony_game.view.preview_end = colony_game.view.preview_start
		var routed_start: Vector2 = colony_game.view.get_global_transform() * start
		var routed_end: Vector2 = colony_game.view.get_global_transform() * end
		var native_touch: InputEventScreenTouch = InputEventScreenTouch.new()
		native_touch.index = 0
		native_touch.pressed = true
		native_touch.position = routed_start
		root.push_input(native_touch)
		var native_drag: InputEventScreenDrag = InputEventScreenDrag.new()
		native_drag.index = 0
		native_drag.position = routed_end
		native_drag.relative = routed_end-routed_start
		root.push_input(native_drag)
		native_touch.position = routed_end
		native_touch.pressed = false
		root.push_input(native_touch)
		check("UI/viewport_routes_touch_rectangle",colony_game.world.gather_targets("tree",colony_game.view.preview_tiles()).size() == 6,colony_game._preview_text())
		colony_game.confirm_placement()
		colony_game.confirm_placement()
		check("UI/gather_rectangle_single_transaction",colony_game.world.pending_commands.size() == 1 and colony_game.world.pending_commands[0].kind == "gather_area")
		colony_game.set_speed(4)
		colony_game.runner.advance_frame(0.1)
	check("M1/UI_gather_creates_real_job", colony_game.world.jobs.filter(func(job: Dictionary) -> bool: return job.kind == "gather").size() == 6)
	colony_game._process(0.0)
	colony_game.begin_build("bed")
	colony_game.confirm_placement()
	colony_game.confirm_placement()
	check("M1/UI_blueprint_single_submit", colony_game.world.pending_commands.size() == 1)
	colony_game.set_speed(4)
	colony_game.runner.advance_frame(0.1)
	for tick_index in range(1600):
		colony_game.world.step()
	check("M1/UI_real_materials_built", colony_game.world.structures.any(func(structure: Dictionary) -> bool: return structure.definition == "bed") and colony_game.world.ledger.consumed.get("wood", 0) == 6)
	colony_game._process(0.0)
	for viewport_size in sizes:
		root.size = viewport_size
		colony_game.size = Vector2(viewport_size)
		for scale_factor in [1.0, 1.25, 1.5]:
			colony_game.text_scale = scale_factor
			colony_game._build_theme()
			colony_game.begin_build("bed")
			await process_frame
			await process_frame
			check("M1/UI_build_toolbar_%dx%d_%d" % [viewport_size.x, viewport_size.y, int(scale_factor * 100)], not colony_game.confirm_button.get_global_rect().intersects(colony_game.speeds.get_global_rect()) and colony_game.rotation_button.get_global_rect().end.y <= colony_game.nav.get_global_rect().position.y, str([colony_game.rotation_button.get_global_rect(), colony_game.nav.get_global_rect()]))
			colony_game.cancel_placement()
	colony_game._process(0.0)
	colony_game.begin_field()
	colony_game.confirm_placement()
	colony_game.confirm_placement()
	check("M2/UI_field_single_submit",colony_game.world.pending_commands.size() == 1)
	colony_game.set_speed(4)
	colony_game.runner.advance_frame(0.1)
	check("M2/UI_field_tiles_created",colony_game.world.fields.size() == 16)
	for tick_index in range(17000): colony_game.world.step()
	check("M2/UI_fields_produced_real_food",colony_game.world.ledger.produced.get("vegetable",0) > 0)
	colony_game._process(0.0)
	colony_game.runner.pause()
	colony_game._name_snapshot(1,false,"")
	var name_entry: LineEdit
	for child in colony_game.sheet_body.get_children():
		if child is LineEdit: name_entry = child
	name_entry.text = "Quiet"
	name_entry.caret_column = name_entry.text.length()
	name_entry.grab_focus()
	var space: InputEventKey = InputEventKey.new()
	space.keycode = KEY_SPACE
	space.unicode = 32
	space.pressed = true
	root.push_input(space)
	check("SAVE/UI_name_space_keeps_simulation_paused",name_entry.text == "Quiet " and colony_game.runner.speed == 0)
	name_entry.text += "spring"
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text == "Save snapshot": child.pressed.emit()
	check("SAVE/UI_named_snapshot_saved",colony_game.store.named_snapshots()[0].name == "Quiet spring")
	var real_directory: String = colony_game.store.directory
	var blocked_path: String = ui_colony_directory.path_join("not-a-directory")
	var blocker: FileAccess = FileAccess.open(blocked_path,FileAccess.WRITE)
	blocker.store_string("retained")
	blocker.close()
	colony_game.store.directory = blocked_path
	colony_game.save_local()
	check("SAVE/UI_write_failure_pauses_and_offers_choices",colony_game.sheet_name == "Save problem" and colony_game.runner.speed == 0 and FileAccess.get_file_as_string(blocked_path) == "retained")
	colony_game.close_sheet()
	colony_game.set_speed(4)
	check("SAVE/UI_closing_error_never_implicitly_resumes",colony_game.sheet_name == "Save problem" and colony_game.runner.speed == 0)
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text == "Continue without saving": child.pressed.emit()
	colony_game._process(0.0)
	check("SAVE/UI_explicit_unsaved_mode_has_persistent_notice",colony_game.saving_disabled and colony_game.notice_label.text.begins_with("Unsaved progress"))
	colony_game.store.directory = real_directory
	colony_game.save_local()
	check("SAVE/UI_verified_retry_restores_saving",not colony_game.saving_disabled and colony_game.storage_error.is_empty())
	var import_bytes: PackedByteArray = colony_game.store.encode(colony_game.world)
	var original_session: String = colony_game.world.session_id
	colony_game._accept_import(import_bytes)
	check("SAVE/UI_import_waits_for_campaign_choice",colony_game.sheet_name == "Import campaign" and colony_game.world.session_id == original_session and not ColonyStore.occupied(2,ui_colony_directory))
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text == "Import into campaign 2": child.pressed.emit()
	check("SAVE/UI_import_clones_into_independent_slot",colony_game.store.slot == 2 and colony_game.world.session_id != original_session and ColonyStore.occupied(1,ui_colony_directory) and ColonyStore.occupied(2,ui_colony_directory))
	root.size = Vector2i(960, 600)
	colony_game.size = Vector2(960, 600)
	colony_game.text_scale = 1.0
	colony_game._build_theme()
	colony_game.view.camera_tile = Vector2(73, 59)
	colony_game.select_citizen(2)
	colony_game.set_speed(0)
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var citizen: Dictionary = colony_game.world.citizens[0]
		citizen.x = 75
		citizen.y = 55
		citizen.progress = 0
		colony_game.view.camera_tile = Vector2(75,55)
		await process_frame
		var actor_sample: Vector2 = colony_game.view.get_global_transform()*colony_game.view.tile_to_screen(Vector2(75.5,55.5))-Vector2(0,colony_game.view.tile_size)
		colony_game.view.actor_layer.visible = false
		await RenderingServer.frame_post_draw
		var without_actor: Color = root.get_texture().get_image().get_pixelv(Vector2i(actor_sample))
		colony_game.view.actor_layer.visible = true
		await RenderingServer.frame_post_draw
		var with_actor: Color = root.get_texture().get_image().get_pixelv(Vector2i(actor_sample))
		check("M2/UI_worker_visible_over_field",without_actor != with_actor,str([without_actor,with_actor]))
		root.get_texture().get_image().save_png("res://reports/m2-landscape.png")
		root.size = Vector2i(390, 844)
		colony_game.size = Vector2(390, 844)
		colony_game.view.camera_tile = Vector2(75,55)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/m2-portrait.png")
	colony_game.close_inspector()
	colony_game.show_sheet("Work")
	var assignment_button: Button
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text.begins_with("Tavi | Gathering"): assignment_button = child
	assignment_button.pressed.emit()
	check("PEOPLE/UI_work_preferences_one_tap",colony_game.sheet_name == "Tavi - Work" and colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button).size() == 12)
	var gathering: Button
	var care: Button
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text.begins_with("Gathering:"): gathering = child
		if child is Button and child.text.begins_with("Care:"): care = child
	var initial_gathering: int = colony_game.world.citizens[2].preferences.Gathering
	gathering.pressed.emit()
	gathering.pressed.emit()
	care.pressed.emit()
	check("WORK/UI_multiple_paused_preferences_are_queued",colony_game.world.pending_commands.size() == 3 and gathering.text == "Gathering: Last (pending)" and colony_game.world.citizens[2].preferences.Gathering == initial_gathering)
	colony_game.close_sheet()
	colony_game.set_speed(1)
	colony_game.runner.advance_frame(0.1)
	colony_game._process(0)
	colony_game.runner.pause()
	check("WORK/UI_paused_preference_batch_applies_in_order",colony_game.world.citizens[2].preferences.Gathering == 1 and colony_game.world.citizens[2].preferences.Care == 3 and colony_game.world.pending_commands.is_empty())
	colony_game.show_person(1)
	check("PEOPLE/UI_person_has_relationships_and_morale",colony_game.sheet_name == "Mira" and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text == "Relationships"))
	var saved_social_payload: Dictionary = colony_game.world.payload().duplicate(true)
	colony_game.world.tick = 3*7200+2400
	ColonyWeather.initialize(colony_game.world)
	ColonySocial.advance(colony_game.world)
	colony_game.show_person(1)
	var decline: Button
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text == "Decline without penalty": decline = child
	check("REQUEST/UI_offer_requires_explicit_acceptance",decline != null and colony_game.world.social_state.requests[-1].state == "Offered")
	decline.pressed.emit()
	colony_game.set_speed(1)
	colony_game.runner.advance_frame(0.1)
	colony_game._process(0)
	colony_game.runner.pause()
	check("REQUEST/UI_decline_has_no_penalty",colony_game.world.social_state.requests[-1].state == "Declined" and colony_game.world.citizens[0].broken_promise_until == 0)
	var restored_social: Dictionary = ColonyCodec.restore(saved_social_payload)
	check("REQUEST/UI_fixture_restore_keeps_valid_chronology",restored_social.has("world"),str(restored_social.get("error","")))
	if not restored_social.has("world"): return
	colony_game.world=restored_social.world;colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	var weather_hash: String = colony_game.world.canonical_hash()
	var workstation: Dictionary = colony_game.world._structure("workbench",Vector2i(90,63),0)
	colony_game._map_intent({"kind":"tap","tile":Vector2i(90,63),"point":colony_game.view.tile_to_screen(Vector2(90.5,63.5))})
	check("PRODUCTION/UI_map_opens_actual_station",colony_game.sheet_name == "Workbench")
	colony_game.show_recipe_policy(workstation,colony_game.world.definitions.recipes.make_toolkit)
	var options: Array = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is CycleChoiceButton)
	options[0].select(1); options[1].select(2)
	for child in colony_game.sheet_body.get_children():
		if child is SpinBox: child.value = 2
		if child is Button and child.text == "Add order": child.pressed.emit()
	check("PRODUCTION/UI_policy_queues_one_real_order",colony_game.world.pending_commands.size() == 1 and colony_game.world.pending_commands[0].args.mode == "Maintain" and colony_game.world.pending_commands[0].args.priority == 3)
	colony_game.set_speed(1); colony_game.runner.advance_frame(0.1); colony_game._process(0); colony_game.runner.pause()
	check("PRODUCTION/UI_policy_applies_on_tick",colony_game.world.production_state.orders.size() == 1 and colony_game.world.production_state.orders[0].quantity == 2)
	colony_game.show_research()
	check("RESEARCH/UI_lists_all_twelve_unlocks",colony_game.sheet_name == "Research" and colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Label and n.text.begins_with("Unlocks:")).size() == 12)
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text == "Study Woodcraft": child.pressed.emit(); break
	check("RESEARCH/UI_select_is_pending",colony_game.world.pending_commands.size() == 1 and colony_game.world.pending_commands[0].kind == "research_select" and colony_game.world.production_state.project == "")
	colony_game.set_speed(1); colony_game.runner.advance_frame(0.1); colony_game._process(0); colony_game.runner.pause()
	check("RESEARCH/UI_select_sets_actual_project",colony_game.world.production_state.project == "woodcraft")
	weather_hash = colony_game.world.canonical_hash()
	colony_game.show_weather()
	await process_frame
	check("WEATHER/UI_forecast_is_paused_read_only",colony_game.sheet_name == "Weather forecast" and colony_game.runner.speed == 0 and colony_game.world.canonical_hash() == weather_hash)
	colony_game.close_sheet()
	colony_game.show_sheet("Work")
	await process_frame
	await process_frame
	var scroll: ScrollContainer = colony_game.sheet_body.get_parent()
	var taps: Dictionary = {"count":0}
	var row: Button = colony_game.button("Scroll gesture test",func()->void:taps.count += 1,colony_game.sheet_body)
	colony_game.sheet_body.move_child(row,5)
	await process_frame
	await process_frame
	var scrolling_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	scrolling_touch.index = 0
	scrolling_touch.pressed = true
	scrolling_touch.position = row.get_global_rect().get_center()
	root.push_input(scrolling_touch)
	var emulated_press: InputEventMouseButton = InputEventMouseButton.new()
	emulated_press.device = -1
	emulated_press.button_index = MOUSE_BUTTON_LEFT
	emulated_press.pressed = true
	emulated_press.position = scrolling_touch.position
	root.push_input(emulated_press)
	var scrolling_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	scrolling_drag.index = 0
	scrolling_drag.position = scrolling_touch.position-Vector2(0,100)
	scrolling_drag.relative = Vector2(0,-100)
	root.push_input(scrolling_drag)
	scrolling_touch.pressed = false
	scrolling_touch.position = scrolling_drag.position
	root.push_input(scrolling_touch)
	emulated_press.pressed = false
	emulated_press.position = scrolling_touch.position
	root.push_input(emulated_press)
	check("UI/scrolling_cancels_action_release",taps.count == 0)
	await process_frame
	await process_frame
	emulated_press.position = row.get_global_rect().get_center()
	emulated_press.pressed = true
	root.push_input(emulated_press)
	emulated_press.pressed = false
	root.push_input(emulated_press)
	check("UI/tap_after_scroll_activates_once",taps.count == 1,str(taps.count))
	check("UI/touch_scroll_starts_on_action_row",scroll.scroll_vertical > 0 and colony_game.sheet_name == "Work" and colony_game.world.pending_commands.is_empty(),str(scroll.scroll_vertical))
	colony_game.close_sheet()
	var entry: Dictionary = colony_game.world.weather_state.days[-1]
	entry.kind = "flood"
	entry.mask = ColonyWeather.flood_mask(colony_game.world)
	colony_game.show_weather()
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text == "View flood area": child.pressed.emit()
	check("WEATHER/UI_flood_preview_uses_forecast_mask",colony_game.view.forecast_mask == entry.mask and colony_game.sheet == null and colony_game.runner.speed == 0)
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/m3-flood-preview.png")
	colony_game.show_new_colony(3)
	var seed_entry: LineEdit
	var site_options: Array = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is CycleChoiceButton)
	check("GEN/UI_choice_keeps_large_touch_target",site_options[0].custom_minimum_size.y >= 48)
	await process_frame
	await process_frame
	var choice_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	choice_touch.index = 0; choice_touch.pressed = true; choice_touch.position = site_options[0].get_global_rect().get_center()
	root.push_input(choice_touch)
	var choice_mouse: InputEventMouseButton = InputEventMouseButton.new()
	choice_mouse.device = -1; choice_mouse.button_index = MOUSE_BUTTON_LEFT; choice_mouse.pressed = true; choice_mouse.position = choice_touch.position
	root.push_input(choice_mouse)
	var choice_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	choice_drag.index = 0; choice_drag.position = choice_touch.position-Vector2(0,50); choice_drag.relative = Vector2(0,-50)
	root.push_input(choice_drag)
	choice_touch.pressed = false; choice_touch.position = choice_drag.position; root.push_input(choice_touch)
	choice_mouse.pressed = false; choice_mouse.position = choice_touch.position; root.push_input(choice_mouse)
	await process_frame
	check("UI/swiping_choice_does_not_change_value",site_options[0].selected == 0)
	choice_touch.pressed = true; choice_touch.position = site_options[0].get_global_rect().get_center(); root.push_input(choice_touch)
	choice_mouse.pressed = true; choice_mouse.position = choice_touch.position; root.push_input(choice_mouse)
	choice_touch.pressed = false; root.push_input(choice_touch)
	choice_mouse.pressed = false; root.push_input(choice_mouse)
	await process_frame
	await process_frame
	check("UI/tapping_choice_after_swipe_changes_once",site_options[0].selected == 1,str(site_options[0].selected))
	for child in colony_game.sheet_body.get_children():
		if child is LineEdit: seed_entry = child
	seed_entry.text = "4294967296"
	colony_game.sheet_body.get_node("CreateColony").pressed.emit()
	check("GEN/UI_rejects_out_of_range_seed_without_creation",colony_game.creation_thread == null and colony_game.sheet_name == "New colony")
	seed_entry.text = "1"; site_options[0].select(1); site_options[1].select(1)
	colony_game.sheet_body.get_node("CreateColony").pressed.emit()
	check("GEN/UI_creation_runs_off_ui_thread_paused",colony_game.creation_thread != null and colony_game.runner.speed == 0)
	colony_game.set_speed(4)
	check("GEN/UI_generation_cannot_resume_previous_colony",colony_game.runner.speed == 0)
	for frame in range(180):
		await process_frame
		if colony_game.creation_thread == null: break
	check("GEN/UI_new_site_seed_mode_and_independent_slot",colony_game.creation_thread == null and colony_game.store.slot == 3 and colony_game.world.seed == 1 and colony_game.world.site_id == "pine_shelf" and colony_game.world.care_state.mode == "Hearthside" and colony_game.world.generator_version == 1 and ColonyStore.occupied(2,ui_colony_directory))
	colony_game.begin_field()
	check("GEN/UI_field_preview_uses_transformed_starter_patch",colony_game.view.preview_tiles().all(func(p:Vector2i)->bool:return colony_game.world.terrain_state.starter_field.has(p)))
	colony_game.cancel_placement()
	colony_game.world.care_state.mode = "Standard"
	colony_game.begin_forest()
	colony_game.confirm_placement(); colony_game.confirm_placement()
	check("NATURE/UI_forest_rectangle_single_command",colony_game.world.pending_commands.size() == 1 and colony_game.world.pending_commands[0].kind == "forest")
	colony_game.set_speed(1); colony_game.runner.advance_frame(0.1); colony_game._process(0); colony_game.runner.pause()
	colony_game.show_forest(colony_game.world.nature_state.forests[0])
	check("NATURE/UI_forest_shows_reserve_and_replanting",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("eight non-winter days")))
	var pier_card: Dictionary = colony_game.world._structure("fishing_pier",Vector2i(31,48),0)
	colony_game.show_station(pier_card)
	check("NATURE/UI_pier_exposes_both_limits_and_recovery",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("entire river") and n.text.contains("06:00")))
	colony_game.close_sheet()
	colony_game.show_wildlife()
	check("ANIMAL/UI_all_sixteen_wildlife_selectable",colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button).size()==16)
	var boar_card: Dictionary = colony_game.world.wildlife_state.animals.filter(func(a:Dictionary)->bool:return a.definition=="boar")[0]
	colony_game._wildlife_sheet(boar_card)
	check("HUNT/UI_boar_risk_and_escort_explained",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("12 damage")) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Hunt with armed escort"))
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Solo hunt risk…": child.pressed.emit(); break
	check("HUNT/UI_solo_requires_separate_confirmation",colony_game.sheet_name=="Solo boar hunt" and colony_game.world.pending_commands.is_empty())
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Confirm solo hunt": child.pressed.emit(); break
	check("HUNT/UI_confirmation_retains_chosen_hunter",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="hunt" and colony_game.world.pending_commands[0].args.solo and colony_game.world.pending_commands[0].args.citizen>0)
	colony_game.set_speed(1); colony_game.runner.advance_frame(0.1); colony_game._process(0); colony_game.runner.pause()
	ColonyCare.hurt(colony_game.world,colony_game.world.citizens[2],90,true)
	colony_game._process(0)
	check("CARE/UI_critical_alert_opens_paused_care",colony_game.sheet_name == "Injuries and care" and colony_game.runner.speed == 0)
	check("CARE/UI_explains_bleeding_and_off_override",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.begins_with("Bleeding:")) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Treat now pins one visible override")))
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text == "Treat with Mira": child.pressed.emit(); break
	check("CARE/UI_treat_command_requires_one_explicit_choice",colony_game.world.pending_commands.size() == 1 and colony_game.world.pending_commands[0].kind == "treat_now")
	colony_game.set_speed(1); colony_game.runner.advance_frame(0.1); colony_game._process(0); colony_game.runner.pause()
	check("CARE/UI_treatment_pin_accepted",colony_game.world.citizens[0].pinned_job > 0)
	for person in colony_game.world.citizens: ColonyCare.hurt(colony_game.world,person,1000,false)
	colony_game._process(0)
	check("DEATH/UI_epilogue_pauses_and_retains_choices",colony_game.sheet_name == "Colony epilogue" and colony_game.runner.speed == 0 and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text == "New colony with this seed"))
	colony_game.show_sheet("Menu"); colony_game._process(0)
	check("DEATH/UI_return_menu_stays_available",colony_game.sheet_name == "Menu" and colony_game.world.care_state.ended)
	colony_game.set_speed(4)
	check("DEATH/UI_terminal_colony_cannot_resume",colony_game.runner.speed == 0 and colony_game.sheet_name == "Colony epilogue")
	colony_game.world=DomesticTests.setup();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.view.refresh_terrain();colony_game.submitted_command=0
	var domestic_pen: Dictionary = colony_game.world.domestic_state.pens[0]
	var ui_hen: Dictionary = ColonyDomestic.acquire(colony_game.world,"hen",domestic_pen.id,domestic_pen.tiles[0]).animal
	var ui_goat: Dictionary = ColonyDomestic.acquire(colony_game.world,"pack_goat",domestic_pen.id,domestic_pen.tiles[0]).animal
	colony_game.show_pen(domestic_pen)
	check("PEN/UI_capacity_feed_and_collection_explained",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("2/6 animals") and n.text.contains("06:00")) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("4 WU")))
	colony_game.view.tile_size=8
	colony_game._map_intent({"kind":"chooser","tile":domestic_pen.tiles[0],"point":colony_game.view.tile_to_screen(Vector2(domestic_pen.tiles[0])+Vector2(0.5,0.5))})
	check("UI02/overlapping_domestic_animals_have_named_choices",colony_game.sheet_name=="Select object" and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text==ui_hen.name) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text==ui_goat.name))
	colony_game.show_domestic_animal(ui_goat)
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Slaughter…": child.pressed.emit();break
	check("ANIMALS/UI_slaughter_names_animal_before_confirmation",colony_game.sheet_name=="Slaughter "+ui_goat.name and colony_game.world.pending_commands.is_empty())
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Confirm slaughter "+ui_goat.name: child.pressed.emit();break
	check("ANIMALS/UI_slaughter_confirmation_submits_once",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="slaughter" and colony_game.world.pending_commands[0].args.target==ui_goat.id)
	colony_game.runner.set_speed(1);colony_game.runner.advance_frame(0.1);colony_game._process(0);colony_game.runner.pause()
	colony_game.begin_pen();colony_game.confirm_placement();colony_game.confirm_placement()
	check("PEN/UI_rectangle_confirm_one_atomic_command",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="pen")
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.view.refresh_terrain();colony_game.submitted_command=0
	colony_game.begin_build("wood_wall");colony_game.view.preview_start=Vector2i(74,54);colony_game.view.preview_end=Vector2i(77,56)
	check("BUILD/UI_drag_uses_axis_aligned_line",colony_game.view.preview_tiles()==[Vector2i(74,54),Vector2i(75,54),Vector2i(76,54),Vector2i(77,54)])
	check("BUILD/UI_line_shows_count_and_total_cost",colony_game._preview_text().contains("Confirm 4 valid") and colony_game._preview_text().contains("8 wood"))
	colony_game.confirm_placement();colony_game.confirm_placement()
	check("BUILD/UI_line_confirm_one_atomic_command",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="build_area" and colony_game.world.pending_commands[0].args.tiles.size()==4)
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	colony_game.begin_lodge();colony_game.view.preview_start=Vector2i(84,72);colony_game.view.fit_build_preview()
	check("BUILD/UI_lodge_full_footprint_and_exact_cost",colony_game.view.preview_tiles().size()==48 and colony_game._preview_text().contains("W73 F8") and colony_game._preview_text().contains("206 WU"))
	colony_game.confirm_placement()
	check("BUILD/UI_lodge_confirm_one_atomic_command",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="lodge")
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0;colony_game.world.researched.append("husbandry")
	colony_game.world._structure("wood_wall",Vector2i(75,63),0)
	colony_game.begin_build("fence");colony_game.view.preview_start=Vector2i(74,63);colony_game.view.preview_end=Vector2i(76,63)
	colony_game._preview_text();colony_game.confirm_placement()
	check("BUILD/UI_omitted_cells_keep_visible_reason",colony_game.view.rejected_build_tiles.has(Vector2i(75,63)) and not colony_game.view.rejected_build_tiles[Vector2i(75,63)].is_empty())
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	colony_game.show_person(1)
	check("GEAR/UI_person_links_equipment",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Equipment"))
	colony_game.world._make_stack("forged_toolkit",1,"store",colony_game.world.stores[0].id,Vector2i(66,63),true)
	colony_game.show_equipment(1)
	check("GEAR/UI_fetch_work_policy_and_gear_effects_explained",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("2 WU") and n.text.contains("Hauling")) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Toolkit upgrades: Off"))
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Equip Forged toolkit": child.pressed.emit();break
	check("GEAR/UI_named_equip_submits_one_command",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="equip" and colony_game.world.pending_commands[0].args.target==1 and colony_game.world.pending_commands[0].args.item=="forged_toolkit")
	colony_game.runner.set_speed(1);colony_game.runner.advance_frame(0.1);colony_game._process(0);colony_game.runner.pause();colony_game.show_equipment(1)
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Toolkit upgrades: Off": child.pressed.emit();break
	check("GEAR/UI_upgrade_is_explicit_policy_command",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="equipment_policy" and colony_game.world.pending_commands[0].args.upgrades)
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	var maintenance_wall: Dictionary = colony_game.world._structure("wood_wall",Vector2i(74,54),0);maintenance_wall.health=129
	colony_game.show_maintenance(maintenance_wall)
	check("REPAIR/UI_exact_health_material_and_wu_quote",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("51 health") and n.text.contains("2 wood") and n.text.contains("5.1 WU")))
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Demolish…": child.pressed.emit();break
	check("DEMOLISH/UI_separate_confirmation_before_removal",colony_game.world.pending_commands.is_empty() and colony_game.sheet_name.begins_with("Demolish"))
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Confirm demolition": child.pressed.emit();break
	check("DEMOLISH/UI_confirm_submits_one_target",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="demolish" and colony_game.world.pending_commands[0].args.target==maintenance_wall.id)
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	var move_table: Dictionary = colony_game.world._structure("table",Vector2i(74,54),0)
	colony_game.show_maintenance(move_table)
	check("MOVE/UI_retained_materials_and_cancel_consequence",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("physically carried") and n.text.contains("Canceling after dismantling")))
	colony_game.begin_furniture_move(move_table)
	check("MOVE/UI_destination_preview_quotes_full_wu",colony_game._preview_text().contains("Move Table") and colony_game._preview_text().contains("20 WU") and colony_game._preview_text().contains("retained"))
	colony_game.confirm_placement();colony_game.confirm_placement()
	check("MOVE/UI_destination_confirm_submits_once",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="move_furniture" and colony_game.world.pending_commands[0].args.target==move_table.id)
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	colony_game.begin_cart_move(colony_game.world.structures[4]);colony_game.view.preview_start=Vector2i(74,68);colony_game.view.fit_build_preview()
	check("CART/UI_quote_full_work_and_retained_goods",colony_game._preview_text().contains("20 WU") and colony_game._preview_text().contains("stay aboard") and not colony_game.rotation_button.visible)
	colony_game.confirm_placement();colony_game.confirm_placement()
	check("CART/UI_destination_confirm_submits_once",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="cart_move")
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	var newcomer: Dictionary = ColonyPopulation.offer(colony_game.world)
	colony_game.show_newcomers()
	check("POP/UI_shortage_links_to_bed_and_food",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Build sleeping place") and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Food forecast"))
	colony_game.world._structure("bedroll",Vector2i(74,64),0);colony_game.show_newcomers()
	var accept_newcomer: Button = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text.begins_with("Accept "))[0]
	accept_newcomer.pressed.emit()
	check("POP/UI_accept_queues_exact_candidate",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="newcomer" and colony_game.world.pending_commands[0].args.target==newcomer.id)
	colony_game.world.step();colony_game.select_citizen(colony_game.world.citizens[-1].id)
	var newcomer_selected: bool = colony_game.view.selected_id==colony_game.world.citizens[-1].id and colony_game.inspector_details.text.contains(colony_game.world.citizens[-1].name)
	colony_game.show_person(colony_game.world.citizens[-1].id)
	check("POP/UI_new_id_is_selectable_and_inspectable",newcomer_selected and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Equipment"))
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	var trader: Dictionary = TradeTests.merchant(colony_game.world)
	colony_game.show_valley()
	check("TRADE/UI_merchant_and_relations_are_visible",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Trade with Orchard Kin") and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Requested delivery")))
	colony_game._preview_trade(trader,{"meal":5},{"wood":19},0,false)
	check("TRADE/UI_short_payment_has_no_accept",not colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Accept exchange"))
	colony_game._preview_trade(trader,{"meal":5},{"wood":21},0,false)
	check("TRADE/UI_exact_price_and_surplus_gift",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Price 20") and n.text.contains("surplus gift 1")))
	var accept_trade: Button = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Accept exchange")[0]
	accept_trade.pressed.emit();accept_trade.pressed.emit()
	check("TRADE/UI_confirmation_queues_one_atomic_exchange",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="trade" and colony_game.world.pending_commands[0].args.buy=={"meal":5} and colony_game.world.pending_commands[0].args.pay=={"wood":21})
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	colony_game.show_valley()
	check("REGION/UI_valley_links_map_and_current_trip",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Regional map") and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Expedition status"))
	colony_game.show_region()
	var region_scroll: ScrollContainer = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is ScrollContainer)[0]
	var region_grid: GridContainer = region_scroll.get_child(0)
	check("REGION/UI_81_map_tiles_and_48_dp_targets",region_grid.get_child_count()==81 and region_grid.get_children().all(func(n:Node)->bool:return n is Button and n.custom_minimum_size.x>=48 and n.custom_minimum_size.y>=48))
	await process_frame;await process_frame
	region_scroll.pointer=0;region_scroll.start=region_scroll.get_global_rect().get_center();region_scroll.scroll_origin=region_scroll.scroll_vertical;region_scroll.horizontal_origin=0
	var horizontal_drag: InputEventScreenDrag = InputEventScreenDrag.new();horizontal_drag.index=0;horizontal_drag.position=region_scroll.start-Vector2(160,0);horizontal_drag.relative=Vector2(-160,0)
	region_scroll._input(horizontal_drag)
	check("REGION/UI_map_pans_horizontally_without_selecting",region_scroll.scroll_horizontal>0 and colony_game.world.pending_commands.is_empty())
	region_scroll.pointer=-1;region_scroll.dragging=false;region_scroll.suppress_mouse=false
	colony_game.show_expedition_prepare("berry_hollow",false);await process_frame;await process_frame
	check("EXP/UI_preparation_fits_viewport_width",colony_game.sheet.get_rect().end.x<=colony_game.content.size.x+1,str(colony_game.sheet.get_rect())+" / "+str(colony_game.content.size))
	colony_game.show_expedition_preview(RegionTests.args("berry_hollow",[1,2,3]))
	check("EXP/UI_home_worker_shortage_blocks_packing",not colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Start packing"))
	colony_game.show_expedition_preview(RegionTests.args())
	check("EXP/UI_exact_time_food_and_capacity_preview",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("18 hours") and n.text.contains("8 travel_ration") and n.text.contains("capacity 24")))
	var pack_expedition: Button = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Start packing")[0]
	pack_expedition.pressed.emit();pack_expedition.pressed.emit()
	check("EXP/UI_packing_confirmation_submits_once",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="expedition_prepare")
	colony_game.world.step();colony_game.submitted_command=0;colony_game.show_expeditions()
	check("EXP/UI_depart_waits_for_real_party_and_cargo",not colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Depart"))
	var ui_trip: Dictionary = ColonyRegion.active(colony_game.world)
	RegionTests.until(colony_game.world,ui_trip,"Ready");colony_game.show_expeditions()
	var depart_expedition: Button = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Depart")[0]
	depart_expedition.pressed.emit()
	check("EXP/UI_separate_depart_command",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="expedition_depart" and not colony_game.world.pending_commands[0].args.unprepared)
	colony_game.world.step();RegionTests.until(colony_game.world,ui_trip,"Decision",false);colony_game.view._process(0)
	check("EXP/UI_off_map_residents_hide_and_home_workers_stay_visible",not colony_game.view.actors[1].visible and not colony_game.view.actors[2].visible and colony_game.view.actors[0].visible and colony_game.view.actors[3].visible)
	colony_game._process(0)
	check("EXP/UI_decision_opens_with_free_choice_and_recall",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Choose continue") and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text.begins_with("Recall without")))
	var continue_route: Button = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Choose continue")[0]
	continue_route.pressed.emit()
	check("EXP/UI_confirm_choice_queues_exact_response",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="expedition_choice" and colony_game.world.pending_commands[0].args.definition=="continue")

	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	var ui_burning_wall: Dictionary = colony_game.world._structure("wood_wall",Vector2i(74,54),0)
	ColonyFire.ignite(colony_game.world,"structure",ui_burning_wall.id);colony_game.seen_fire_alert=0;colony_game._process(0)
	check("FIRE/UI_new_fire_opens_response_panel",colony_game.sheet_name=="Fire and water" and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Work preferences"))
	check("FIRE/UI_water_effort_and_interruption_are_explained",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("fetch 2 WU") and n.text.contains("apply 8 WU") and n.text.contains("retains applied effort")))
	check("FIRE/UI_well_and_camera_recovery_actions",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Build a well") and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text.begins_with("Look at fire")))

	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	var ui_raid: Dictionary = DefenseTests.raid(colony_game.world)
	colony_game.show_defense()
	check("DEFEND/UI_party_price_and_colony_actions",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Offer supplies") and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Shelter everyone") and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("supplies price 16")))
	colony_game.show_squad([2,3])
	var review_stand_fast: Button = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Review Stand fast")[0]
	review_stand_fast.pressed.emit()
	check("DEFEND/UI_stand_fast_has_explicit_warning",colony_game.sheet_name=="Stand fast warning" and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("retreat at forty") and n.text.contains("disabled")))
	colony_game.begin_defend_rally([2,3],false);colony_game.confirm_placement();colony_game.confirm_placement()
	check("DEFEND/UI_rally_queues_one_draft_command",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="draft" and colony_game.world.pending_commands[0].args.citizens==[2,3] and not colony_game.world.pending_commands[0].args.stand_fast)
	colony_game.world.pending_commands.clear();colony_game.submitted_command=0
	var ui_neutral: Dictionary = colony_game.world.defense_state.enemies[0];ColonyDefense.hurt(colony_game.world,ui_neutral,999,2)
	colony_game.show_enemy(ui_neutral)
	check("RAID/UI_neutral_offers_care_and_no_focus_attack",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Voluntary treatment") and not colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text.begins_with("Focus")))
	colony_game.show_incidents()
	check("DIRECTOR/UI_public_pressure_and_spacing",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Pressure")) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("incident")))
	colony_game.show_raid_offer(ui_raid)
	check("RAID/UI_supply_panel_has_concrete_price_no_placeholder",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Need 16 barter") and not n.text.contains("%d")))
	colony_game.world=ColonyTests.world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	var ui_opportunity: Dictionary = ColonyOpportunities.offer(colony_game.world,"stranded_carrier")
	colony_game.show_valley()
	check("STORY/UI_valley_opens_visitor_opportunities",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Visitor opportunities"))
	colony_game.show_opportunities()
	check("STORY/UI_exact_work_reward_and_deadline",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("eight wood") and n.text.contains("twelve Building WU") and n.text.contains("four cloth")) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("hours left")))
	var accept_opportunity: Button = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text.begins_with("Accept "))[0]
	accept_opportunity.pressed.emit();accept_opportunity.pressed.emit()
	check("STORY/UI_accept_one_reserved_transaction",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="minor_event" and colony_game.world.pending_commands[0].args=={"target":ui_opportunity.id,"accept":true})
	colony_game.world.step();colony_game.submitted_command=0;colony_game.show_opportunities()
	check("STORY/UI_accepted_work_can_be_inspected",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text.begins_with("Task:")))
	await process_frame;await process_frame
	root.get_texture().get_image().save_png("res://reports/opportunity-ui.png")
	colony_game.world=CharterTests.supper_world();colony_game.runner=SimRunner.new(colony_game.world);colony_game.view.world=colony_game.world;colony_game.submitted_command=0
	var charter_ui_hash: String = colony_game.world.canonical_hash()
	colony_game.show_charter()
	check("CHARTER/UI_day_one_checklist_is_read_only",colony_game.world.canonical_hash()==charter_ui_hash and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Day thirty-three")))
	await process_frame;await process_frame
	root.get_texture().get_image().save_png("res://reports/charter-ui.png")
	colony_game.show_supper()
	check("CHARTER/UI_cost_window_waves_and_recovery_explained",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("two meals per home resident") and n.text.contains("18:00-20:00")) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("eaten food stays consumed") and n.text.contains("+60")))
	var reserve_supper: Array = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Reserve meals and evening")
	check("CHARTER/UI_eligible_supper_has_action",reserve_supper.size()==1)
	if not reserve_supper.is_empty(): reserve_supper[0].pressed.emit();reserve_supper[0].pressed.emit()
	check("CHARTER/UI_double_tap_reserves_once",colony_game.world.pending_commands.size()==1 and colony_game.world.pending_commands[0].kind=="start_supper")
	colony_game.world.step();colony_game.submitted_command=0;colony_game.show_supper()
	check("CHARTER/UI_pending_supper_shows_actual_bank",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("16 meals still reserved")) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Cancel supper"))
	colony_game.show_rename(0)
	var settlement_name: LineEdit = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is LineEdit)[0]
	settlement_name.text="Fern Refuge"
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Save name": child.pressed.emit();break
	colony_game.world.step();colony_game.submitted_command=0
	check("CHRONICLE/UI_rename_is_command_with_actual_name",ColonyChronicle.display_name(colony_game.world,0)=="Fern Refuge")
	colony_game.show_pin_moment()
	var moment_note: LineEdit = colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is LineEdit)[0]
	moment_note.text="Our first supper is planned."
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Pin this moment": child.pressed.emit();break
	colony_game.world.step();colony_game.submitted_command=0
	var ui_pin: Dictionary = colony_game.world.chronicle_state.facts[-1]
	check("CHRONICLE/UI_pin_records_authored_text",ui_pin.kind=="pin_moment" and ui_pin.text.contains(moment_note.text))
	colony_game.show_fact(ui_pin.id)
	check("CHRONICLE/UI_details_no_invented_cause",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("No immediate cause was recorded")))
	var cause_id: int = colony_game.world.emit_fact({"tick":colony_game.world.tick,"actor":1,"job":0,"kind":"rescue","text":"Ada completed a rescue."},{"causes":[ui_pin.id],"participants":[1,2],"changes":{"herb":-1}})
	colony_game.show_fact(cause_id)
	check("CHRONICLE/UI_details_explicit_links_and_delta",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Why: event "+str(ui_pin.id)) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("herb") and n.text.contains("-1")))
	await process_frame;await process_frame
	root.get_texture().get_image().save_png("res://reports/chronicle-ui.png")
	var memory_event: int = colony_game.world.emit_fact({"tick":colony_game.world.tick,"actor":1,"job":0,"kind":"supper_complete","text":"Mira shared a communal supper."},{"participants":[1]})
	ColonyChronicle.remember(colony_game.world,"supper",memory_event)
	colony_game.world.charter_state.supper_memories[1]=colony_game.world.tick+600
	colony_game.show_person_history(1)
	check("CHRONICLE/UI_active_memory_has_exact_modifier_expiry_and_link",colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("+60 morale target") and n.text.contains("2.0 hours remaining")) and colony_game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Remember this event"))
	colony_game.world.charter_state.completed.assign(["shelter","provision","connection","refuge"])
	colony_game.show_charter_appearance()
	check("CHARTER/UI_four_cosmetic_controls",colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text.begins_with("Apply ")).size()==4)
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Apply Settlement banner": child.pressed.emit();break
	colony_game.world.step();colony_game.submitted_command=0
	check("CHARTER/UI_appearance_uses_command",colony_game.world.charter_state.appearances.has("shelter"))
	colony_game.world.charter_state.appearances.assign(["shelter","provision","connection","refuge"])
	colony_game.close_sheet();colony_game.view.camera_tile=Vector2(67,64);colony_game.view.tile_size=48
	await process_frame;await process_frame
	root.get_texture().get_image().save_png("res://reports/charter-cart.png")
	colony_game.world.charter_state.ending=true
	colony_game.show_charter_ending()
	check("CHARTER/UI_ending_pauses_and_offers_four_actions",colony_game.runner.speed==0 and colony_game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text in ["Continue settlement","Save and leave","New seed","View settlement"]).size()==4)
	colony_game.set_speed(1)
	check("CHARTER/UI_ending_waits_for_continue",colony_game.runner.speed==0)
	for child in colony_game.sheet_body.get_children():
		if child is Button and child.text=="Continue settlement": child.pressed.emit();break
	colony_game.set_speed(1);colony_game.runner.advance_frame(0.1);colony_game.runner.pause()
	check("CHARTER/UI_continue_keeps_colony",colony_game.world.charter_state.continued and colony_game.world.citizens.size()==8)
	colony_game.queue_free()
	await process_frame
	if failures.is_empty():
		for directory in [ui_m0_directory,ui_colony_directory]:
			if not DirAccess.dir_exists_absolute(directory):
				continue
			CampaignTests.remove_tree(directory)
