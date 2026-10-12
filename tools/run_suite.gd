extends SceneTree

var suite: String = ""
var failures: Array[String] = []
var cases: Array[Dictionary] = []
var started: int = 0

func _initialize() -> void:
	started = Time.get_ticks_msec()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] != "--suite" or not args[1] in ["unit", "integration", "ui", "colony", "survival"]:
		printerr("Usage: -- --suite unit|integration|ui|colony|survival. Unknown flags/suites are errors.")
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
	var game: GameSession = load("res://scenes/game.tscn").instantiate()
	game.world = PrototypeWorld.new()
	game.runner = SimRunner.new(game.world)
	game.store = PrototypeStore.new()
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
		colony_game.set_speed(4)
		colony_game.runner.advance_frame(0.1)
	check("M1/UI_gather_creates_real_job", colony_game.world.jobs.any(func(job: Dictionary) -> bool: return job.kind == "gather"))
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
		root.get_texture().get_image().save_png("res://reports/m2-landscape.png")
		root.size = Vector2i(390, 844)
		colony_game.size = Vector2(390, 844)
		colony_game.view.camera_tile = Vector2(68, 63)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/m2-portrait.png")
	colony_game.queue_free()
	await process_frame
