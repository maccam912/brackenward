extends SceneTree
## Disposable river scene: forecast and actual water use the authoritative mask.
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(1000,720)
	var world: ColonyWorld=ColonyTests.world();world.tick=3600;world.weather="flood"
	ColonyGeneration.configure(world,104729,"reed_bend");world.tick=3600;world.weather="flood"
	ColonyWeather.initialize(world)
	var focus: Vector2i=world.weather_state.flooded[world.weather_state.flooded.size()/2]
	var person: Dictionary=world.citizens[0]
	person.x=focus.x;person.y=focus.y;person.edge_x=focus.x;person.edge_y=focus.y
	world._make_stack("cloth",12,"ground",0,focus+Vector2i(1,0),true)
	var view: WorldView=WorldView.new();root.add_child(view);view.size=Vector2(root.size)
	view.setup(world);view.set_process(false);view.tile_size=32;view.quality="Battery";view.reduced_motion=true
	view.center_camera(Vector2(focus))
	var mask: Array=world.weather_state.flooded.duplicate()
	for mode in ["dry","forecast","flooded","flooded-forecast"]:
		world.weather_state.flooded=mask.duplicate() if mode.begins_with("flooded") else []
		world.tick+=1;view.forecast_mask.assign(mask if mode.ends_with("forecast") else [])
		var baseline: String=world.canonical_hash();view._process(0)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/visual-polish/flood-%s.png" % mode)
		if world.canonical_hash()!=baseline:printerr("Flood rendering mutated world");quit(1);return
	view.queue_free();await process_frame;print("VISUAL_FLOOD_REVIEW_COMPLETE");quit()
