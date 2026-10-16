extends SceneTree
## Reproducible native environment contact views; never opens a player's save.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size=Vector2i(1100,720)
	var world: ColonyWorld=ColonyTests.world()
	ColonyGeneration.configure(world,104729,"meadow_reach")
	world.tick=3600
	var view: WorldView=WorldView.new()
	root.add_child(view);view.size=Vector2(1100,720);view.setup(world);view.set_process(false)
	view.tile_size=32;view.quality="Battery";view.reduced_motion=true
	var cart: Dictionary=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]
	view.center_camera(Vector2(cart.x,cart.y));view._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/camp.png")
	for hour in [6,18,0]:
		world.tick=hour*300;view._process(0)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/visual-polish/camp-hour-%02d.png" % hour)
	world.tick=3600
	var water: Vector2i=Vector2i.ZERO
	var best: float=INF
	for y in range(10,118):
		for x in range(10,118):
			if world.terrain_state.elevation[y*128+x]!=0: continue
			var distance: float=Vector2(x-cart.x,y-cart.y).length_squared()
			if distance<best: best=distance;water=Vector2i(x,y)
	view.center_camera(Vector2(water));view._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/river.png")
	for season in range(4):
		world.tick=season*8*7200+3600;view._process(0)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/visual-polish/season-%d.png" % season)
	world.tick=0;view._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/river-night.png")
	view.queue_free();await process_frame
	print("VISUAL_REVIEW_COMPLETE");quit()
