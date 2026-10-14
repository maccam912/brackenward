class_name PlacementUITests
extends RefCounted

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
	tree.root.size=original_size;game.size=Vector2(original_size);game.text_scale=original_scale;game._build_theme();game._layout()
