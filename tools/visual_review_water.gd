extends SceneTree
## Verify actual two-frame water pixels and static accessibility modes.
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(800,480)
	var world: ColonyWorld=ColonyTests.world();ColonyGeneration.configure(world,104729,"meadow_reach")
	world.structures.clear();world.resources.clear();world.citizens.clear();world.stacks.clear();world.stores.clear();world.tick=3600
	var center: Vector2i=Vector2i.ZERO;var nearest: float=INF
	for y in range(10,118):
		for x in range(10,118):
			if world.terrain_state.elevation[y*128+x]!=0:continue
			var distance: float=Vector2(x-64,y-64).length_squared()
			if distance<nearest:nearest=distance;center=Vector2i(x,y)
	var baseline: String=world.canonical_hash()
	var view: WorldView=WorldView.new();root.add_child(view);view.size=Vector2(root.size);view.setup(world);view.set_process(false);view.tile_size=40;view.center_camera(Vector2(center))
	for mode in ["Balanced","Battery","Reduced"]:
		view.quality="Battery" if mode=="Battery" else "Balanced";view.reduced_motion=mode=="Reduced";view._process(0)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		var first: Image=root.get_texture().get_image()
		first.save_png("res://reports/visual-polish/water-%s-a.png" % mode.to_lower())
		await create_timer(0.9).timeout;await RenderingServer.frame_post_draw
		var second: Image=root.get_texture().get_image()
		second.save_png("res://reports/visual-polish/water-%s-b.png" % mode.to_lower())
		var changed: bool=first.get_data()!=second.get_data()
		if changed!=(mode=="Balanced"):push_error("Unexpected water animation in "+mode);quit(1);return
		print("WATER_PIXELS mode=",mode," changed=",changed)
	if world.canonical_hash()!=baseline:push_error("Water review mutated world");quit(1);return
	view.queue_free();await process_frame
	print("VISUAL_WATER_REVIEW_COMPLETE state_unchanged=true");quit()
