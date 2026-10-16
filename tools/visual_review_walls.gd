extends SceneTree
## Connected-material gallery in a disposable world, including junctions and ruins.
func _initialize() -> void:call_deferred("capture")

func capture() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=1:printerr("Usage: -- OUTPUT_PREFIX");quit(2);return
	root.size=Vector2i(1100,800)
	var world: ColonyWorld=ColonyTests.world()
	world.structures.clear();world.resources.clear();world.citizens.clear();world.stacks.clear();world.stores.clear()
	world.tick=3600
	var row: int=0
	for kind in ["wood_wall","stone_wall","palisade","fence"]:
		var y: int=43+row*6
		for x in range(45,55):world._structure(kind,Vector2i(x,y),0)
		for dy in range(1,4):world._structure(kind,Vector2i(45,y+dy),0);world._structure(kind,Vector2i(50,y+dy),0)
		world._structure(kind,Vector2i(50,y-1),0)
		world._structure(kind,Vector2i(57,y),0)
		world._structure(kind,Vector2i(59,y),0).health=0
		for x in range(46,50):
			for dy in range(1,4):world._structure("wood_floor" if row%2==0 else "stone_path",Vector2i(x,y+dy),0)
		row+=1
	var view: WorldView=WorldView.new();root.add_child(view);view.size=Vector2(root.size)
	view.setup(world);view.set_process(false);view.quality="Battery";view.reduced_motion=true
	var baseline: String=world.canonical_hash()
	for scale in [28,48]:
		view.tile_size=scale;view.center_camera(Vector2(52,53));view._process(0)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s-%d.png" % [args[0],scale])
	if world.canonical_hash()!=baseline:printerr("Gallery mutated world");quit(1);return
	view.queue_free();await process_frame;print("VISUAL_WALL_REVIEW_COMPLETE");quit()
