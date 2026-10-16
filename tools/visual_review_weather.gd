extends SceneTree
## Weather art gallery; no player save and no simulation/weather RNG advances.
func _initialize() -> void:call_deferred("capture")

func capture() -> void:
	root.size=Vector2i(1100,720)
	var world: ColonyWorld=ColonyTests.world();ColonyGeneration.configure(world,104729,"meadow_reach")
	var view: WorldView=WorldView.new();root.add_child(view);view.size=Vector2(root.size)
	view.setup(world);view.set_process(false);view.tile_size=24
	var cart: Dictionary=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]
	view.center_camera(Vector2(cart.x-4,cart.y+2))
	for weather in ["clear","rain","fog","snow","cold_snap","drought","flood"]:
		world.weather=weather;world.tick=3600+Array(["clear","rain","fog","snow","cold_snap","drought","flood"]).find(weather)
		var baseline: String=world.canonical_hash()
		for mode in ["static","moving"]:
			view.quality="Battery" if mode=="static" else "Balanced";view.reduced_motion=mode=="static";view._process(0.5)
			await process_frame;await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/visual-polish/weather-%s-%s.png" % [weather,mode])
		if world.canonical_hash()!=baseline:printerr("Weather rendering mutated world");quit(1);return
	view.queue_free();await process_frame;print("VISUAL_WEATHER_REVIEW_COMPLETE");quit()
