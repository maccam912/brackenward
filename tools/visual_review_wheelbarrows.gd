extends SceneTree
## Isolated graphical review; never opens a player's campaign or settings.
var destination: String="res://reports/visual-polish/wheelbarrows"

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(destination)
	var game: GameSession=load("res://scenes/game.tscn").instantiate()
	game.store.root_directory="user://wheelbarrow-review-%d" % Time.get_ticks_usec()
	game.store.select_slot(1);game.settings.path=game.store.root_directory.path_join("settings.json")
	root.add_child(game);game.set_process(false);game.runner.pause();game.close_sheet(false)
	game.world.tick=3600
	var bench: Dictionary=game.world._structure("workbench",Vector2i(74,59),0)
	for viewport_size in [Vector2i(390,844),Vector2i(1100,720)]:
		root.size=viewport_size
		await process_frame
		game._layout();game._refresh_clock();game.show_research()
		await save_view("research-%d" % viewport_size.x)
		game.world.researched.append("wheelbarrows");game.show_station(bench)
		await save_view("craft-%d" % viewport_size.x)
		if game.world.citizens[0].equipment.transport.is_empty(): WheelbarrowTests.equip(game.world,game.world.citizens[0])
		game.show_equipment(1)
		await save_view("equipment-%d" % viewport_size.x)
		game.close_sheet(false)
		var person: Dictionary=game.world.citizens[0]
		var job: Dictionary=WheelbarrowTests.hauling(game.world)
		game.world._reserve(job,person);person.job=job.id
		for tick in range(1000):
			game.world._work(person,job)
			if job.state=="Delivering": break
		game.view.tile_size=64;game.view.center_camera(Vector2(person.x,person.y));game.view.selected_id=1;game.view._process(0)
		await save_view("hauling-%d" % viewport_size.x)
		game.world._release(job,true);game.world.researched.clear()
	game.queue_free();await process_frame
	print("WHEELBARROW VISUAL PASS");quit()

func save_view(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error: Error=root.get_texture().get_image().save_png(destination.path_join(name+".png"))
	assert(error==OK)
