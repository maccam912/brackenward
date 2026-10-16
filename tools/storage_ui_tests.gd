class_name StorageUITests
extends RefCounted

static func run(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree=previous.get_tree()
	var original_size: Vector2i=tree.root.size
	var processing: bool=previous.is_processing();var visible: bool=previous.visible
	previous.set_process(false);previous.hide();tree.root.size=Vector2i(960,600)
	var world: ColonyWorld=ColonyTests.world()
	world.queue_command("stockpile",{"tiles":[Vector2i(90,80),Vector2i(91,80),Vector2i(90,81),Vector2i(91,81)]});world.step()
	world.tick=3600
	var storage: Dictionary=world.stores[-1]
	world._make_stack("cloth",1,"store",storage.id,Vector2i(90,80),true)
	var scratch: String="user://storage-art-test-%d" % Time.get_ticks_usec()
	var game: GameSession=load("res://scenes/game.tscn").instantiate()
	game.world=world;game.runner=SimRunner.new(world)
	game.store.root_directory=scratch;game.store.select_slot(1);game.settings.path=scratch.path_join("settings.json")
	tree.root.add_child(game);game.set_process(false);game.view.set_process(false)
	game.close_sheet(false);game._tutorial_dismiss();game._refresh_guidance();game.runner.pause()
	game.view.tile_size=48;game.view.center_camera(Vector2(90.5,80.5));game.view._process(0)
	var baseline: String=world.canonical_hash();var camera: Vector2=game.view.camera_center()
	if DisplayServer.get_name()!="headless":
		await tree.process_frame;await tree.process_frame;await RenderingServer.frame_post_draw
		var sample: Vector2i=Vector2i(game.view.get_global_transform()*game.view.tile_to_screen(Vector2(90+6.5/16,80+9.5/16)))
		var image: Image=tree.root.get_texture().get_image()
		var pixel: Color=image.get_pixelv(sample)
		check.call("STORAGE/UI_stockpile_overlay_preserves_actual_cloth_color",pixel.is_equal_approx(Color("716D88")),str(pixel))
		game.view.inspected_object=storage.id;game.view._process(0)
		await tree.process_frame;await RenderingServer.frame_post_draw
		pixel=tree.root.get_texture().get_image().get_pixelv(sample)
		check.call("STORAGE/UI_selected_zone_grid_does_not_tint_item_interiors",pixel.is_equal_approx(Color("716D88")),str(pixel))
		game.view.inspected_object=0
	game.runner.set_speed(2)
	game._map_intent({"kind":"tap","tile":Vector2i(90,80),"point":game.view.tile_to_screen(Vector2(90.5,80.5))})
	check.call("STORAGE/UI_stockpile_tap_opens_storage_without_moving_camera_or_world",game.sheet!=null and game.sheet_title_key=="ui.sheet.storage" and game.view.inspected_object==storage.id and game.view.inspected_tiles==storage.tiles and game.runner.speed==0 and game.view.camera_center()==camera and world.canonical_hash()==baseline)
	game.close_sheet()
	check.call("STORAGE/UI_closing_stockpile_restores_speed_and_clears_inspection",game.runner.speed==2 and game.view.inspected_object==0 and game.view.inspected_tiles.is_empty() and world.canonical_hash()==baseline)
	await game.soundscape.drain();game.queue_free();await tree.process_frame
	CampaignTests.remove_tree(scratch);tree.root.size=original_size
	previous.visible=visible;previous.set_process(processing);previous._apply_device_settings()
