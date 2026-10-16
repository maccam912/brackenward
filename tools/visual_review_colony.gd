extends SceneTree
## Read-only art review of a recorded campaign in a disposable daylight copy.
func _initialize() -> void:call_deferred("capture")

func capture() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2:printerr("Usage: -- SNAPSHOT OUTPUT_PREFIX");quit(2);return
	var input_hash: String=FileAccess.get_sha256(args[0])
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"):printerr(decoded);quit(2);return
	var world: ColonyWorld=decoded.world
	world.tick=(world.tick/7200)*7200+3600
	var baseline: String=world.canonical_hash()
	root.size=Vector2i(1100,720)
	var view: WorldView=WorldView.new();root.add_child(view)
	view.size=Vector2(root.size);view.setup(world);view.set_process(false)
	view.quality="Battery";view.reduced_motion=true
	var cart: Dictionary=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]
	for scale in [24,40]:
		view.tile_size=scale;view.center_camera(Vector2(cart.x+1,cart.y+1));view._process(0)
		await save_view("%s-camp-%d.png" % [args[1],scale])
	if not world.fields.is_empty():
		var center: Vector2=Vector2.ZERO
		for field in world.fields:center+=Vector2(field.x,field.y)
		view.tile_size=32;view.center_camera(center/world.fields.size());view._process(0)
		await save_view(args[1]+"-fields.png")
	if world.canonical_hash()!=baseline or FileAccess.get_sha256(args[0])!=input_hash:
		printerr("Review changed simulation or input snapshot");quit(1);return
	print("VISUAL_COLONY_REVIEW_COMPLETE structures=",world.structures.size()," residents=",world.citizens.size()," input_sha=",input_hash)
	view.queue_free();await process_frame;quit()

func save_view(path: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
