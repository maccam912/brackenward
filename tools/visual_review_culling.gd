extends SceneTree
## Deterministic native views for before/after renderer equivalence checks.
func _initialize() -> void:call_deferred("capture")

func capture() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2:printerr("Usage: -- SNAPSHOT OUTPUT_PREFIX");quit(2);return
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"):printerr(decoded);quit(2);return
	var world: ColonyWorld=decoded.world
	root.size=Vector2i(960,600)
	var view: WorldView=WorldView.new();root.add_child(view)
	view.size=Vector2(960,600);view.setup(world);view.set_process(false)
	view.quality="Battery";view.reduced_motion=true;view.tile_size=16
	var index: int=0
	for center in [Vector2(68,63),Vector2(15,15),Vector2(110,110),Vector2(68,63)]:
		view.center_camera(center)
		var baseline: String=world.canonical_hash();view._process(0)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s-%d.png" % [args[1],index])
		if world.canonical_hash()!=baseline:printerr("Renderer changed world");quit(1);return
		index+=1
	view.queue_free();await process_frame
	print("VISUAL_CULLING_REVIEW_COMPLETE");quit()
