extends SceneTree
## Native tree life-stage gallery in a disposable world.
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(800,480)
	var world: ColonyWorld=ColonyTests.world()
	world.structures.clear();world.resources.clear();world.citizens.clear();world.stacks.clear();world.stores.clear()
	world.tick=3600
	for stage in range(3):
		var id: int=world._id()
		world.resources.append({"id":id,"definition":"tree","x":48+stage*4,"y":50,"remaining":8 if stage==2 else 0,"regrow_at":0})
		world.nature_state.trees[id]={"planted":stage==1,"age":0 if stage<2 else 57600,"cleared":false}
	var baseline: String=world.canonical_hash()
	var view: WorldView=WorldView.new();root.add_child(view);view.size=Vector2(root.size);view.setup(world);view.set_process(false)
	view.quality="Battery";view.reduced_motion=true
	for scale in [24,48]:
		view.tile_size=scale;view.center_camera(Vector2(52,49));view._process(0)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/visual-polish/regrowth-stages-%d.png" % scale)
	if world.canonical_hash()!=baseline:push_error("Regrowth gallery mutated world");quit(1);return
	view.queue_free();await process_frame
	print("VISUAL_REGROWTH_REVIEW_COMPLETE state_unchanged=true");quit()
