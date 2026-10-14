extends SceneTree
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()!=2 or args[0]!="--audit": printerr("Usage: -- --audit OUTPUT_JSON");quit(2);return
	var result: Dictionary = Content3Migration.audit()
	DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
	var file: FileAccess = FileAccess.open(args[1],FileAccess.WRITE)
	if file==null: printerr("Cannot write migration audit");quit(2);return
	file.store_string(JSON.stringify(result,"\t",true));file.close()
	print(JSON.stringify(result))
	quit(0 if result.passed else 1)
