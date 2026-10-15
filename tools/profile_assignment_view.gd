extends SceneTree
## Complete original assignment search versus an equivalent direct filter loop.
const Reference = preload("res://tools/assignment_view_reference.gd")

func _initialize() -> void:call_deferred("run")

func clone(source: ColonyWorld, original: bool) -> ColonyWorld:
	var result: ColonyWorld=Reference.new(source.definitions) if original else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]:continue
		var value: Variant=source.get(field)
		if value is Array:result.get(field).assign(value.duplicate(true))
		elif value is Dictionary:result.set(field,value.duplicate(true))
		else:result.set(field,value)
	result.reset_job_queries();result.reset_stack_queries();result.reset_resource_queries();result.record_indexes.clear()
	result.navigation_dirty=true;result.rooms_dirty=true;result.reachability_dirty=true
	return result

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","tools/profile_assignment_view.gd","tools/assignment_view_reference.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	for folder in ["src","data/catalogs"]:collect("res://"+folder,result)
	return result

func collect(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["gd","json"]:result[folder.path_join(file)]=FileAccess.get_sha256(folder.path_join(file))
	for subdirectory in DirAccess.get_directories_at(folder):collect(folder.path_join(subdirectory),result)

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=3 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>7200 or FileAccess.file_exists(args[2]):printerr("Usage: -- SNAPSHOT|fresh TICKS NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprints();var input_sha: String=FileAccess.get_sha256(args[0]) if args[0]!="fresh" else ""
	var decoded: Dictionary
	if args[0]=="fresh":
		decoded={"world":ColonyTests.world()};var error: String=ColonyGeneration.configure(decoded.world,104729,"meadow_reach")
		if not error.is_empty():printerr(error);quit(2);return
	else:decoded=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"):printerr(decoded);quit(2);return
	var initial: String=decoded.world.canonical_hash();var expected: String="";var rows: Array=[];var passed: bool=true
	for pair in range(4):
		for original in ([true,false] if pair%2==0 else [false,true]):
			var world: ColonyWorld=clone(decoded.world,original);var started: int=Time.get_ticks_usec()
			for index in range(int(args[1])):world.step()
			var elapsed: int=Time.get_ticks_usec()-started
			var exact_text: String=JSON.stringify(ColonyState.pack(world.payload()),"",false)
			if expected.is_empty():expected=exact_text
			var exact: bool=exact_text==expected and world.invariant_errors().is_empty();passed=passed and exact
			rows.append({"pair":pair,"original":original,"elapsed_us":elapsed,"exact_unsorted_state":exact,"canonical_hash":world.canonical_hash()})
	var unchanged: bool=source==fingerprints() and decoded.world.canonical_hash()==initial and (args[0]=="fresh" or input_sha==FileAccess.get_sha256(args[0]))
	var report: Dictionary={"passed":passed and unchanged,"source":source,"input":args[0],"input_sha256":input_sha,"initial_canonical_hash":initial,"initial_tick":decoded.world.tick,"ticks":int(args[1]),"rows":rows,"source_input_unchanged":unchanged,"engine":Engine.get_version_info().string,"reference_commit":"f88776342883a93f7a3a3d90e282e4c6252198bf","scope":"Four alternating ordinary complete-tick pairs,full original assignment-search method retained independently. Candidate filters into a new array with a direct typed loop; direct calls retain original callback filtering. Exact complete unsorted state/invariants and unchanged source/input/base world. No native GUI/emulator/other benchmark active; scheduling/diskcache included,no isolated CPU/frame or physical Android certification."}
	var file: FileAccess=FileAccess.open(args[2],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print("Assignment filter profile: ",report.passed);quit(0 if report.passed else 1)
