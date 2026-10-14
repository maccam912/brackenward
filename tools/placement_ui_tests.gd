class_name PlacementUITests
extends RefCounted

class CountingPlacementWorld extends ColonyWorld:
	var ui_placement_queries: int = 0
	func _init(catalog: Dictionary) -> void: super(catalog)
	func placement_error(kind: String, anchor: Vector2i, rotation: int, excluded_job: int = 0, excluded_structure: int = 0) -> String:
		if not in_tick: ui_placement_queries+=1
		return super(kind,anchor,rotation,excluded_job,excluded_structure)

static func run(game: GameSession, check: Callable) -> void:
	game._replace_world(ColonyTests.world())
	game.close_inspector()
	game.close_sheet()
	game._tutorial_dismiss()
	var tree: SceneTree = game.get_tree()
	var original_size: Vector2i = tree.root.size
	var original_scale: float = game.text_scale
	game.text_scale = 1.0
	game._build_theme()
	var actions: Dictionary = {
		"stockpile": game.begin_placement,
		"door": func() -> void: game.begin_build("door"),
		"wall": func() -> void: game.begin_build("wood_wall"),
		"floor": func() -> void: game.begin_build("wood_floor"),
		"bed": func() -> void: game.begin_build("bed"),
		"field": game.begin_field,
		"gather": func() -> void: game.begin_gather("tree"),
		"forest": game.begin_forest,
		"pen": game.begin_pen,
		"lodge": game.begin_lodge,
		"furniture_move": func() -> void: game.begin_furniture_move(game.world.structures[0]),
		"cart_move": func() -> void: game.begin_cart_move(ColonyTrade.cart(game.world)),
		"rally": func() -> void: game.begin_defend_rally([1,2],false)
	}
	for viewport_size in [Vector2i(390,844),Vector2i(960,600)]:
		tree.root.size=viewport_size;game.size=Vector2(viewport_size);game._layout()
		await tree.process_frame
		for kind in actions:
			game.view.camera_tile=Vector2(90.25,80.75)
			game.view.tile_size=32.0
			game.view.follow_id=1
			game.show_sheet("Build")
			var anchor: Vector2 = game.view.tile_to_screen(Vector2(90.5,80.5))
			actions[kind].call()
			check.call("UI03/placement_preserves_camera_%s_%d" % [kind,viewport_size.x],game.view.camera_tile==Vector2(90.25,80.75) and game.view.tile_size==32.0 and game.view.follow_id==0 and game.view.tile_to_screen(Vector2(90.5,80.5)).is_equal_approx(anchor) and game.world.pending_commands.is_empty())
			game.cancel_placement()
		for definition in ["door","wood_wall","wood_floor"]:
			game.begin_build(definition)
			await tree.process_frame
			await tree.process_frame
			var point: Vector2 = game.view.size*0.5+Vector2(64,72)
			var tile: Vector2i = game.view.screen_to_tile(point)
			game.view.preview_start=tile-Vector2i(7,3)
			game.view.preview_end=tile-Vector2i(2,3)
			var touch: InputEventScreenTouch = InputEventScreenTouch.new()
			touch.index=0;touch.position=game.view.get_global_transform()*point;touch.pressed=true
			tree.root.push_input(touch)
			touch.pressed=false;tree.root.push_input(touch)
			check.call("UI03/touch_starts_one_cell_%s_%d" % [definition,viewport_size.x],game.view.preview_tiles()==[tile] and game.world.pending_commands.is_empty(),str(game.view.preview_tiles()))
			# A subsequent mouse click also replaces the entire previous stroke.
			var mouse: InputEventMouseButton = InputEventMouseButton.new()
			mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=touch.position+Vector2(32,0)*game.logical_scale;mouse.pressed=true
			tree.root.push_input(mouse)
			mouse.pressed=false;tree.root.push_input(mouse)
			var mouse_tile: Vector2i = game.view.screen_to_tile(game.view.get_global_transform().affine_inverse()*mouse.position)
			check.call("UI03/mouse_replaces_stroke_%s_%d" % [definition,viewport_size.x],game.view.preview_tiles()==[mouse_tile] and game.world.pending_commands.is_empty())
			if definition=="door" and viewport_size.x==960 and DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				tree.root.get_texture().get_image().save_png("res://reports/placement-single-door.png")
			game.confirm_placement();game.confirm_placement()
			check.call("UI03/one_cell_confirm_%s_%d" % [definition,viewport_size.x],game.world.pending_commands.size()==1 and game.world.pending_commands[0].kind=="build_area" and game.world.pending_commands[0].args.tiles==[mouse_tile])
			game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
			game.view.camera_tile=Vector2(90.25,80.75)
	await overlay_camera(game,check)
	await bed_assignment(game,check)
	tree.root.size=original_size;game.size=Vector2(original_size);game.text_scale=original_scale;game._build_theme();game._layout()

static func overlay_camera(game: GameSession, check: Callable) -> void:
	var tree: SceneTree = game.get_tree()
	for viewport_size in [Vector2i(390,844),Vector2i(640,360)]:
		tree.root.size=viewport_size;game.size=Vector2(viewport_size);game._layout()
		for center in [Vector2.ZERO,Vector2(90.25,80.75),Vector2(128,128)]:
			game._replace_world(ColonyWorld.new(ColonyCatalog.load_data(),"overlay-camera-%d-%d" % [viewport_size.x,int(center.x)]))
			game.close_sheet();game.close_inspector();game._tutorial_begin();game._refresh_guidance()
			await tree.process_frame
			game.view.follow_id=0;game.view.center_camera(center)
			var marker: Vector2 = center+Vector2(0.5,0.5)
			var before: Vector2 = game.view.tile_to_screen(marker)
			var suffix: String = "%d_%d" % [viewport_size.x,int(center.x)]
			check.call("UI03/active_guidance_camera_fixture_"+suffix,game.guidance_panel.visible and game.view.focus_offset!=Vector2.ZERO)
			game.show_sheet("Build");game.begin_build("door")
			await tree.process_frame
			check.call("UI03/guidance_to_placement_preserves_visible_map_"+suffix,game.view.camera_center().is_equal_approx(center) and game.view.tile_to_screen(marker).is_equal_approx(before) and game.view.preview_start==game.view.screen_to_tile(game.view.size*0.5))
			game.cancel_placement()
			await tree.process_frame
			check.call("UI03/closing_placement_keeps_visible_map_"+suffix,game.view.camera_center().is_equal_approx(center) and game.view.tile_to_screen(marker).is_equal_approx(before))
			game.select_citizen(1)
			game._layout();game.close_inspector();game._layout()
			check.call("UI03/inspector_layout_does_not_shift_free_camera_"+suffix,game.view.camera_center().is_equal_approx(center) and game.view.tile_to_screen(marker).is_equal_approx(before))
			game._save_settings();game.view.center_camera(Vector2(40,40));game._restore_camera()
			check.call("UI03/preferences_restore_actual_visible_center_"+suffix,game.view.camera_center().is_equal_approx(center) and game.view.tile_to_screen(marker).is_equal_approx(before))
		game.view.follow_id=1;game.select_citizen(1);game._layout();game.view._process(0.0)
		var person: Dictionary = game.world.citizens[0]
		var point: Vector2 = Vector2(person.x+0.5,person.y+0.5)
		var followed: Vector2 = game.view.tile_to_screen(point)
		var desired: Vector2 = game.view.camera_center()
		game.show_sheet("Build");await tree.process_frame
		game.begin_build("door");await tree.process_frame
		check.call("UI03/placement_stops_follow_without_losing_original_view_%d" % viewport_size.x,game.view.follow_id==0 and game.view.camera_center().is_equal_approx(desired) and game.view.tile_to_screen(point).is_equal_approx(followed))
		game.cancel_placement()
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()

static func bed_assignment(game: GameSession, check: Callable) -> void:
	var tree: SceneTree = game.get_tree()
	for viewport_size in [Vector2i(390,844),Vector2i(640,360)]:
		game._replace_world(ColonyTests.world());game.close_sheet();game.close_inspector();game._tutorial_dismiss()
		tree.root.size=viewport_size;game.size=Vector2(viewport_size);game.text_scale=1.5;game._build_theme();game._layout()
		var world: ColonyWorld = game.world
		var bed: Dictionary = world._structure("bed",Vector2i(74,64),0)
		game.show_person(1)
		var choices: Array = game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Assign bed")
		check.call("BED/UI_person_offers_bed_control_%d" % viewport_size.x,choices.size()==1)
		choices[0].pressed.emit();await tree.process_frame
		var choose: Array = game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Choose 74,64")
		check.call("BED/UI_lists_actual_free_bed_without_pending_order_%d" % viewport_size.x,choose.size()==1 and world.pending_commands.is_empty() and game.runner.speed==0)
		choose[0].pressed.emit();await tree.process_frame
		var confirm: Array = game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Assign this bed")
		check.call("BED/UI_assignment_has_visible_large_text_confirmation_%d" % viewport_size.x,confirm.size()==1 and confirm[0].size.y>=48 and game.sheet.get_global_rect().encloses(confirm[0].get_global_rect()))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			tree.root.get_texture().get_image().save_png("res://reports/bed-assignment-%d.png" % viewport_size.x)
		confirm[0].pressed.emit()
		check.call("BED/UI_assignment_queues_one_public_command_%d" % viewport_size.x,world.pending_commands.size()==1 and world.pending_commands[0].kind=="assign_bed" and world.citizens[0].bed!=bed.id)
		game.set_speed(1);game.runner.advance_frame(0.1);game.runner.pause();game._process(0.0)
		check.call("BED/UI_assignment_applies_on_resume_%d" % viewport_size.x,world.citizens[0].bed==bed.id and bed.user==1)
		game.show_bed_choice(2,bed.id)
		check.call("BED/UI_occupied_choice_explains_named_owner_%d" % viewport_size.x,game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Mira")) and not game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Assign this bed"))
		game.show_station(bed)
		var unassign: Array = game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Unassign bed")
		unassign[0].pressed.emit()
		var clear: Array = game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Unassign")
		check.call("BED/UI_unassign_explains_ground_rate_before_order_%d" % viewport_size.x,clear.size()==1 and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("80 rest/hour")) and world.pending_commands.is_empty())
		clear[0].pressed.emit();game.set_speed(1);game.runner.advance_frame(0.1);game.runner.pause();game._process(0.0)
		check.call("BED/UI_unassign_releases_real_bed_%d" % viewport_size.x,world.citizens[0].bed==0 and bed.user==0)
	game._replace_world(ColonyTests.world());game.close_sheet();game.close_inspector();game._tutorial_dismiss()


static func inactive_preview(game: GameSession, check: Callable) -> void:
	var world: CountingPlacementWorld = CountingPlacementWorld.new(ColonyTests.world().definitions)
	game._replace_world(world);game.close_sheet();game._tutorial_dismiss()
	var previous_saving_disabled: bool = game.saving_disabled;game.saving_disabled=true
	game.begin_build("wood_floor");game.view.preview_start=Vector2i(50,48);game.view.preview_end=Vector2i(65,63)
	world.ui_placement_queries=0;game._advance_frame(0.0)
	check.call("PLACE/UI_visible_area_really_validates_its_cells",world.ui_placement_queries>0 and game.preview_label.text.contains("16×16"))
	game.cancel_placement();world.ui_placement_queries=0
	var before_tick: int = world.tick
	game.runner.set_speed(1)
	for index in range(50): game._advance_frame(0.1)
	game.runner.pause()
	check.call("PLACE/UI_canceled_area_does_no_hidden_validation_as_time_advances",world.ui_placement_queries==0 and world.tick>before_tick and not game.placement.visible and world.pending_commands.is_empty() and world.invariant_errors().is_empty(),str([world.ui_placement_queries,world.tick,before_tick,world.invariant_errors()]))
	game.begin_build("wood_floor");game.view.preview_start=Vector2i(50,48);game.view.preview_end=Vector2i(51,49)
	world.ui_placement_queries=0;game._advance_frame(0.0)
	check.call("PLACE/UI_reopened_preview_refreshes_its_new_geometry",world.ui_placement_queries>0 and game.preview_label.text.contains("2×2"))
	game.confirm_placement();var command_id: int = game.submitted_command
	world.ui_placement_queries=0;game.runner.set_speed(1)
	for index in range(50): game._advance_frame(0.1)
	game.runner.pause()
	check.call("PLACE/UI_confirmed_area_does_no_hidden_validation_while_work_runs",command_id>0 and world.receipts.get(command_id)=="accepted" and world.ui_placement_queries==0 and not game.placement.visible and world.invariant_errors().is_empty(),str([command_id,world.receipts,world.ui_placement_queries,world.invariant_errors()]))
	game.saving_disabled=previous_saving_disabled

static func confirmed_orders(game: GameSession, check: Callable) -> void:
	var original_size: Vector2i=game.get_tree().root.size
	game._replace_world(ColonyTests.world());game.close_sheet();game.close_inspector();game._tutorial_dismiss()
	var previous_saving_disabled: bool = game.saving_disabled;game.saving_disabled=true
	var world: ColonyWorld = game.world
	var tick: int = world.tick
	var needs: Array = world.citizens.map(func(c:Dictionary)->Array:return [c.fullness,c.rest,c.health])
	game.begin_field();game.view.preview_start=Vector2i(90,80);game.view.preview_end=Vector2i(91,81)
	game.confirm_placement();game.confirm_placement()
	check.call("PLACE/paused_confirm_marks_field_without_simulating",world.tick==tick and world.pending_commands.size()==1 and game.view.confirmed_cells.size()==4 and not game.placement.visible and game.runner.speed==0)
	game.begin_placement();game.view.preview_start=Vector2i(94,80);game.view.preview_end=Vector2i(95,81)
	check.call("PLACE/second_order_enabled_without_any_tick",not game.confirm_button.disabled and world.tick==tick)
	game.confirm_placement();game.confirm_placement()
	check.call("PLACE/two_paused_orders_each_submit_once_and_keep_all_marks",world.pending_commands.size()==2 and game.view.confirmed_cells.size()==8 and world.tick==tick and world.citizens.map(func(c:Dictionary)->Array:return [c.fullness,c.rest,c.health])==needs)
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("PLACE/queued_paused_orders_round_trip_without_time_or_resources",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash())
	game._replace_world(decoded.world);game.close_sheet();game._tutorial_dismiss();game.view.refresh_confirmed_orders()
	check.call("PLACE/recovered_pending_orders_rebuild_immediate_marks",game.view.confirmed_cells.size()==8 and game.world.tick==tick)
	world=game.world;world.step();game._advance_frame(0.0);game.view.refresh_confirmed_orders()
	check.call("PLACE/receipts_replace_pending_marks_with_real_orders",world.receipts.values().all(func(v:String)->bool:return v=="accepted") and game.view.confirmed_cells.is_empty() and world.fields.size()==4 and world.designations.size()==4)
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss();world=game.world
	game.begin_build("door");game.view.preview_start=Vector2i(90,80);game.view.preview_end=game.view.preview_start;game.confirm_placement()
	check.call("PLACE/confirmed_door_has_single_cell_marker",game.view.confirmed_cells.has(Vector2i(90,80)) and game.view.confirmed_buildings.size()==1)
	game.begin_build("wood_wall");game.view.preview_start=Vector2i(90,80);game.view.preview_end=game.view.preview_start;game.confirm_placement()
	check.call("PLACE/paused_overlap_explained_and_not_double_queued",world.pending_commands.size()==1 and game.placement.visible and game.view.rejected_build_tiles.has(Vector2i(90,80)))
	game.view.preview_start=Vector2i(91,80);game.view.preview_end=game.view.preview_start;game.confirm_placement()
	check.call("PLACE/adjacent_paused_wall_can_be_confirmed",world.pending_commands.size()==2 and game.view.confirmed_cells.size()==2 and not game.placement.visible and game.view.rejected_build_tiles.is_empty())
	game.begin_build("wood_floor");game.view.preview_start=Vector2i(90,80);game.view.preview_end=game.view.preview_start;game.confirm_placement()
	check.call("PLACE/floor_can_be_confirmed_beneath_pending_door",world.pending_commands.size()==3)
	world.step();game._advance_frame(0.0)
	check.call("PLACE/all_consecutive_build_receipts_reconcile",game.placement_commands.is_empty() and game.submitted_command==0 and world.receipts.values().all(func(v:String)->bool:return v=="accepted") and world.invariant_errors().is_empty(),str(world.receipts))
	for speed in [0,1,2,4]:
		for via_menu in [false,true]:
			game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss();game.runner.set_speed(speed)
			if via_menu: game.show_sheet("Build");game.show_sheet("Construction")
			game.begin_field();game.view.preview_start=Vector2i(90,80);game.view.preview_end=game.view.preview_start
			check.call("PLACE/preview_pauses_from_%d_menu_%s" % [speed,str(via_menu)],game.runner.speed==0)
			game.confirm_placement()
			check.call("PLACE/confirmation_restores_exact_speed_%d_menu_%s" % [speed,str(via_menu)],game.runner.speed==speed and game.world.tick==1800)
	game.runner.pause();game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
	game.runner.set_speed(4);game.begin_field();game.set_speed(0);game.confirm_placement()
	check.call("PLACE/explicit_pause_during_preview_cancels_auto_resume",game.runner.speed==0)
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss();game.runner.set_speed(4);game.begin_field()
	game._storage_failed("Controlled placement storage failure");game.storage_error="";game.close_sheet();game.confirm_placement()
	check.call("PLACE/storage_failure_cancels_placement_auto_resume",game.runner.speed==0)
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss();game.runner.set_speed(4);game.begin_field()
	game.suspend();game.resume_from_background();game.close_sheet();game.confirm_placement()
	check.call("PLACE/background_return_cancels_placement_auto_resume",game.runner.speed==0)
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss();game.runner.set_speed(4);game.begin_field()
	game._replace_world(ColonyTests.world());game.confirm_placement()
	check.call("PLACE/world_replacement_clears_placement_resume_and_preview",game.runner.speed==0 and not game.placement.visible and game.world.pending_commands.is_empty())
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss();game.runner.set_speed(4);game.begin_field();game.cancel_placement()
	check.call("PLACE/cancel_keeps_time_paused",game.runner.speed==0 and game.world.pending_commands.is_empty())
	for viewport_size in [Vector2i(390,844),Vector2i(960,600)]:
		game.get_tree().root.size=viewport_size;game.size=Vector2(viewport_size);game._layout();game.view.follow_id=0;game.view.center_camera(Vector2(70,64));game.view.tile_size=16
		var point: Vector2=game.view.size*0.4
		var anchor: Vector2=(point-game.view.size*0.5-game.view.focus_offset)/game.view.tile_size+game.view.camera_tile
		game.view.zoom_at(0.001,point)
		check.call("ZOOM/eight_times_wider_and_anchor_preserved_%d" % viewport_size.x,game.view.tile_size==2 and game.view.tile_to_screen(anchor).is_equal_approx(point))
		game._save_settings();var camera: Array=game.settings.values.cameras[game.store.slot-1].duplicate()
		game.view.tile_size=32;game._restore_camera()
		check.call("ZOOM/far_zoom_is_retained_in_device_preferences_%d" % viewport_size.x,game.view.tile_size==2 and game.view.camera_center().is_equal_approx(Vector2(camera[0],camera[1])))
		game.view.zoom_at(10000,point)
		check.call("ZOOM/maximum_close_zoom_remains_64_%d" % viewport_size.x,game.view.tile_size==64)
	game.view.tile_size=32;game.view.center_camera(Vector2(90,80))
	var sample: Vector2i=Vector2i(game.view.get_global_transform()*game.view.tile_to_screen(Vector2(90.4,80.4)))
	var before_pixel: Color
	if DisplayServer.get_name()!="headless":
		await game.get_tree().process_frame
		await RenderingServer.frame_post_draw
		before_pixel=game.get_tree().root.get_texture().get_image().get_pixelv(sample)
	game.begin_build("door");game.view.preview_start=Vector2i(90,80);game.view.preview_end=game.view.preview_start;game.confirm_placement()
	await game.get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var image: Image=game.get_tree().root.get_texture().get_image()
		image.save_png("res://reports/placement-confirmed-paused.png")
		check.call("PLACE/native_confirmed_marker_changes_actual_pixels_while_paused",game.runner.speed==0 and game.view.confirmed_cells.has(Vector2i(90,80)) and image.get_pixelv(sample)!=before_pixel,str([before_pixel,image.get_pixelv(sample)]))
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss();game.saving_disabled=previous_saving_disabled
	game.get_tree().root.size=original_size;game.size=Vector2(original_size);game._layout()
