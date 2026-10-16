extends SceneTree
func _initialize() -> void:
	var result: Dictionary = Content7Migration.audit()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()==2 and args[0]=="--audit":
		var file: FileAccess = FileAccess.open(args[1],FileAccess.WRITE);file.store_string(JSON.stringify(result,"\t",true)+"\n");file.close()
	print(JSON.stringify(result));quit(0 if result.passed else 1)
