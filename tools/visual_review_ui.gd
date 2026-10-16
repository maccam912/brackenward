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
		game.show_sheet("Work")
		await save_view("work-%dx%d" % [viewport_size.x,viewport_size.y])
		game.show_new_colony(2)
		await save_view("new-colony-%dx%d" % [viewport_size.x,viewport_size.y])
		var site_choice: CycleChoiceButton=game.sheet_body.find_children("*","CycleChoiceButton",true,false)[0]
		for selected in [1,2]:
			site_choice.select(selected)
			await save_view("new-colony-site%d-%dx%d" % [selected,viewport_size.x,viewport_size.y])
		game._storage_sheet(game.world.stores[0])
		await save_view("storage-%dx%d" % [viewport_size.x,viewport_size.y])
		game.show_sheet("People")
		await save_view("people-%dx%d" % [viewport_size.x,viewport_size.y])
		game.show_person(game.world.citizens[0].id)
		await save_view("person-%dx%d" % [viewport_size.x,viewport_size.y])
		game.close_sheet(false)
		game.select_citizen(game.world.citizens[0].id)
		await save_view("resident-%dx%d" % [viewport_size.x,viewport_size.y])
		game.close_inspector(false)
	root.size=Vector2i(390,844)
	await process_frame
	game.text_scale=1.5;game._build_theme();game._layout()
	game.show_sheet("Build")
	await save_view("build-390x844-text150")
	game.show_sheet("Work")
	await save_view("work-390x844-text150")
	game._storage_sheet(game.world.stores[0])
	await save_view("storage-390x844-text150")
	game.show_sheet("People")
	await save_view("people-390x844-text150")
	game.show_person(game.world.citizens[0].id)
	await save_view("person-390x844-text150")
	game.show_new_colony(2)
	await save_view("new-colony-390x844-text150")
	var harvested: Dictionary=game.world.resources.filter(func(r:Dictionary)->bool:return r.definition=="berry_bush")[0]
	harvested.remaining=0;harvested.regrow_at=game.world.tick+14400
	game._resource_sheet(harvested)
	await save_view("harvested-390x844-text150")
	await game.soundscape.drain()
	game.queue_free();await process_frame
	print("VISUAL_UI_REVIEW_COMPLETE");quit()

func save_view(label: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/%s.png" % label)
