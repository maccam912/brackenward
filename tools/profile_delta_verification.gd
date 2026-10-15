extends SceneTree
## Matched comparison of the unchanged recovery oracle and read-only writer check.
func _initialize() -> void:call_deferred("run")

func verify(method: String, base: Dictionary, patch: Dictionary, target: Dictionary) -> bool:
	if method=="reconstruct":
		var restored: Dictionary=ColonyDelta.restore(base,patch)
		return restored.has("state") and restored.state==target
	return ColonyDelta.matches(base,patch,target)

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not FileAccess.file_exists(args[0]) or FileAccess.file_exists(args[1]):printerr("Usage: -- SNAPSHOT NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprints();var input_sha: String=FileAccess.get_sha256(args[0])
	var loaded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not loaded.has("world"):printerr(loaded);quit(2);return
	var world: ColonyWorld=loaded.world;var capture: ColonyCapture=ColonyCapture.new();var base: Dictionary=capture.capture(world,[])
	var initial: String=world.canonical_hash()
	for index in range(360):world.step()
	var target: Dictionary=capture.capture(world,[]);var canonical: String=world.canonical_hash()
	if not world.invariant_errors().is_empty():printerr("Advanced world failed invariants");quit(2);return
	var frame: PackedByteArray=ColonyJournal.frame({"sequence":"1","kind":"tick","tick":world.tick,"delta":{"version":1,"base_tick":base.tick,"campaign_id":world.session_id,"parent":initial,"patch":ColonyDelta.make(base,target)}})
	var parsed: Dictionary=ColonyJournal.read(frame)
	if parsed.has("error"):printerr(parsed);quit(2);return
	var patch: Dictionary=parsed.records[0].delta.patch
	if not verify("reconstruct",base,patch,target) or not verify("read_only",base,patch,target):printerr("Warmup differs");quit(2);return
	var rows: Array=[];var passed: bool=true
	for pair in range(4):
		for method in (["reconstruct","read_only"] if pair%2==0 else ["read_only","reconstruct"]):
			var thread: Thread=Thread.new();var before: int=OS.get_static_memory_usage();var peak: int=before;var started: int=Time.get_ticks_usec()
			if thread.start(verify.bind(method,base,patch,target))!=OK:printerr("Worker startup failed");quit(2);return
			while thread.is_alive():peak=maxi(peak,OS.get_static_memory_usage());OS.delay_usec(1000)
			var exact: bool=thread.wait_to_finish();var elapsed: int=Time.get_ticks_usec()-started
			rows.append({"pair":pair,"method":method,"elapsed_us":elapsed,"sampled_peak_engine_heap_growth":peak-before,"ending_engine_heap_growth":OS.get_static_memory_usage()-before,"exact_reparsed_patch_matches":exact})
			passed=passed and exact;thread=null
	var unchanged: bool=source==fingerprints() and input_sha==FileAccess.get_sha256(args[0]) and world.canonical_hash()==canonical
	var report: Dictionary={"passed":passed and unchanged,"source":source,"input_sha256":input_sha,"initial_canonical_hash":initial,"final_canonical_hash":canonical,"ticks_advanced":360,"journal_frame_bytes":frame.size(),"rows":rows,"unchanged":unchanged,"engine":Engine.get_version_info().string,"scope":"Four alternating background checks of the same reparsed journal and immutable captures after 360 real simulation ticks. Roughly 1 ms sampled engine heap; no physical PSS/FPS/thermal certification. External recovery still uses unchanged complete reconstruction."}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if report.passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["tools/profile_delta_verification.gd","project.godot","toolchain.lock.json"]:result[path]=FileAccess.get_sha256("res://"+path)
	for folder in ["src","data/catalogs"]:collect("res://"+folder,result)
	return result

func collect(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["gd","json"]:result[folder.path_join(file)]=FileAccess.get_sha256(folder.path_join(file))
	for subdirectory in DirAccess.get_directories_at(folder):collect(folder.path_join(subdirectory),result)
