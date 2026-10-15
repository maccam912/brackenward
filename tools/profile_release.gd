extends SceneTree
## Complete ordinary ticks; the reference keeps the complete defdc91 release method.
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=3 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>7200 or FileAccess.file_exists(args[2]):printerr("Usage: -- SNAPSHOT|fresh TICKS NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprints();var input_sha: String=FileAccess.get_sha256(args[0]) if args[0]!="fresh" else ""
	var decoded: Dictionary
	if args[0]=="fresh":
		decoded={"world":ColonyTests.world()}
		var error: String=ColonyGeneration.configure(decoded.world,104729,"meadow_reach")
		if not error.is_empty():printerr(error);quit(2);return
	else:decoded=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"):printerr(decoded);quit(2);return
	var initial: String=decoded.world.canonical_hash();var expected: String="";var rows: Array=[];var passed: bool=true
	for pair in range(4):
		for original in ([true,false] if pair%2==0 else [false,true]):
			var world: ColonyWorld=ReleaseReadTests.clone(decoded.world,original)
			var started: int=Time.get_ticks_usec()
			for tick in range(int(args[1])):world.step()
			var elapsed: int=Time.get_ticks_usec()-started
			var exact_text: String=JSON.stringify(ColonyState.pack(world.payload()),"",false)
			if expected.is_empty():expected=exact_text
			var exact: bool=exact_text==expected and world.invariant_errors().is_empty()
			passed=passed and exact;rows.append({"pair":pair,"original":original,"elapsed_us":elapsed,"complete_unsorted_state_equal":exact,"canonical_hash":world.canonical_hash()})
	var unchanged: bool=source==fingerprints() and decoded.world.canonical_hash()==initial and (args[0]=="fresh" or input_sha==FileAccess.get_sha256(args[0]))
	var report: Dictionary={"passed":passed and unchanged,"source":source,"input_sha256":input_sha,"initial_canonical_hash":initial,"ticks":int(args[1]),"rows":rows,"unchanged":unchanged,"engine":Engine.get_version_info().string,"reference_commit":"defdc91173be693e9aad43a0e370ec9ea55d3898","scope":"Four alternating complete-tick pairs; reference retains the complete original release method. Candidate hoists stable reservation policy/job ID and reads each stack location once. Every historical record and metadata mutation remains; every complete unsorted payload and invariant matches. Source/input/base world unchanged. Current67 native4x probe and bounded headless checks may share host; not isolated CPU/frame or physical Android certification."}
	var file: FileAccess=FileAccess.open(args[2],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if report.passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","toolchain.lock.json","tools/release_read_tests.gd","tools/profile_release.gd","tools/colony_tests.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	for folder in ["src","data/catalogs"]:collect("res://"+folder,result)
	return result

func collect(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["gd","json"]:result[folder.path_join(file)]=FileAccess.get_sha256(folder.path_join(file))
	for subdirectory in DirAccess.get_directories_at(folder):collect(folder.path_join(subdirectory),result)
