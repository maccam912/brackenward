extends SceneTree
## Construct and validate the isolated load fixture; never touches player saves.
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()!=2 or args[0]!="--snapshot" or args[1].is_empty(): quit(2);return
	var fixture: Dictionary = StressFixture.make()
	if not fixture.has("world"): printerr(fixture);quit(1);return
	var bytes: PackedByteArray = ColonyCodec.encode(fixture.world)
	DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
	var file: FileAccess = FileAccess.open(args[1],FileAccess.WRITE)
	if file==null: printerr("Cannot create isolated stress snapshot");quit(1);return
	file.store_buffer(bytes);file.close()
	var written: PackedByteArray = FileAccess.get_file_as_bytes(args[1])
	if written!=bytes: printerr("Stress snapshot readback mismatch");quit(1);return
	print(JSON.stringify({"scope":fixture.scope,"counts":fixture.counts,"canonical_hash":fixture.world.canonical_hash(),"snapshot_bytes":bytes.size(),"snapshot_sha256":FileAccess.get_sha256(args[1])}))
	quit(0)
