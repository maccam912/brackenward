extends SceneTree
## Construct and validate the isolated load fixture; never touches player saves.
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() not in [2,4] or args[0]!="--snapshot" or args[1].is_empty() or (args.size()==4 and (args[2]!="--use-rations" or args[3] not in ["true","false"])):
		printerr("Usage: -- --snapshot NEW_PATH [--use-rations true|false]");quit(2);return
	if FileAccess.file_exists(args[1]): printerr("Snapshot output already exists; choose a new path");quit(2);return
	var use_rations: bool=args.size()==4 and args[3]=="true"
	var fixture: Dictionary = StressFixture.make(use_rations)
	if not fixture.has("world"): printerr(fixture);quit(1);return
	var bytes: PackedByteArray = ColonyCodec.encode(fixture.world)
	DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
	var file: FileAccess = FileAccess.open(args[1],FileAccess.WRITE)
	if file==null: printerr("Cannot create isolated stress snapshot");quit(1);return
	file.store_buffer(bytes);file.close()
	var written: PackedByteArray = FileAccess.get_file_as_bytes(args[1])
	if written!=bytes: printerr("Stress snapshot readback mismatch");quit(1);return
	print(JSON.stringify({"scope":fixture.scope,"rations_requested":use_rations,"counts":fixture.counts,"canonical_hash":fixture.world.canonical_hash(),"snapshot_bytes":bytes.size(),"snapshot_sha256":FileAccess.get_sha256(args[1])}))
	quit(0)
