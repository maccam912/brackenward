extends SceneTree
## Isolated native UI captures for visual review; no player save/settings access.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game: GameSession=load("res://scenes/game.tscn").instantiate()
	game.store.root_directory="user://visual-review-%d" % Time.get_ticks_usec()
	game.store.select_slot(1);game.settings.path=game.store.root_directory.path_join("settings.json")
	ColonyGeneration.configure(game.world,104729,"meadow_reach");game.world.tick=3600
	root.add_child(game);game.set_process(false);game.runner.pause();game.close_sheet(false)
	var cart: Dictionary=game.world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]
	for viewport_size in [Vector2i(1100,720),Vector2i(390,844)]:
		root.size=viewport_size
		await process_frame
		game._layout();game._refresh_guidance()
		game.view.tile_size=32;game.view.center_camera(Vector2(cart.x,cart.y));game.view._process(0)
		game._refresh_clock()
		await save_view("hud-%dx%d" % [viewport_size.x,viewport_size.y])
		game.show_sheet("Build")
		await save_view("build-%dx%d" % [viewport_size.x,viewport_size.y])
		game.close_sheet(false)
		game.select_citizen(game.world.citizens[0].id)
		await save_view("resident-%dx%d" % [viewport_size.x,viewport_size.y])
		game.close_inspector(false)
	await game.soundscape.drain()
	game.queue_free();await process_frame
	print("VISUAL_UI_REVIEW_COMPLETE");quit()

func save_view(label: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/%s.png" % label)
