extends SceneTree
## Alternating full-tick pairs against the frozen per-bed A* reference.
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var source_before: Dictionary=source_evidence()
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>1200:
		printerr("Usage: -- SNAPSHOT TICKS (1..1200)");quit(2);return
	var snapshot_sha: String=FileAccess.get_sha256(args[0])
	var loaded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not loaded.has("world"): printerr(loaded);quit(2);return
	var pairs: Array=[];var exact: bool=true
	for pair in range(4):
		var row: Dictionary={"order":["full","fast"] if pair%2==0 else ["fast","full"]}
		for mode in row.order:
			var world: ColonyWorld=CareReadTests.clone(loaded.world,mode=="full")
			var started: int=Time.get_ticks_usec()
			for tick in range(int(args[1])): world.step()
			row[mode+"_us"]=Time.get_ticks_usec()-started
			row[mode+"_hash"]=world.canonical_hash()
			row[mode+"_invariants"]=world.invariant_errors()
		row["exact"]=row.full_hash==row.fast_hash and row.full_invariants.is_empty() and row.fast_invariants.is_empty()
		exact=row.exact and exact;pairs.append(row)
	var source_unchanged: bool=source_before==source_evidence()
	exact=exact and source_unchanged and FileAccess.get_sha256(args[0])==snapshot_sha
	print(JSON.stringify({"scope":"Alternating headless complete-tick CPU pairs against retained per-bed A*; not a frame or device certification","snapshot":args[0],"snapshot_sha256":snapshot_sha,"ticks":int(args[1]),"pairs":pairs,"exact":exact,"source_evidence":source_before,"source_unchanged":source_unchanged}))
	quit(0 if exact else 1)

func source_evidence() -> Dictionary:
	var files: Dictionary={}
	for directory in ["src","data"]: source_directory(directory,files)
	for path in ["project.godot","tools/care_read_tests.gd","tools/profile_care.gd"]:
		files[path]=FileAccess.get_sha256("res://"+path)
	return {"sha256":JSON.stringify(files,"",true).sha256_text(),"files":files.size(),"scope":"src, data, project settings, independent oracle and executed pair harness"}

func source_directory(path: String, files: Dictionary) -> void:
	for name in DirAccess.get_files_at("res://"+path):
		if name.ends_with(".uid") or name.ends_with(".import"): continue
		var file: String=path.path_join(name);files[file]=FileAccess.get_sha256("res://"+file)
	for name in DirAccess.get_directories_at("res://"+path): source_directory(path.path_join(name),files)
