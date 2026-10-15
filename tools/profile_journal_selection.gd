extends SceneTree
## Actual retained native journals; complete a230331 parsing is the reference.
func _initialize() -> void:call_deferred("run")

func verify(method: String, bytes: PackedByteArray, after_tick: int, count: int, expected: Array) -> bool:
	if method=="complete":
		var full: Dictionary=JournalSelectionTests.original_read(bytes)
		return not full.has("error") and not full.torn_tail and full.records.size()==count and full.records.filter(func(r:Dictionary)->bool:return r.kind=="command" and r.tick>after_tick)==expected
	var selected: Dictionary=ColonyJournal.commands_after(bytes,after_tick)
	return not selected.has("error") and not selected.torn_tail and selected.total_records==count and selected.commands==expected

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not FileAccess.file_exists(args[0]) or FileAccess.file_exists(args[1]):printerr("Usage: -- JOURNAL NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprints();var input_sha: String=FileAccess.get_sha256(args[0]);var bytes: PackedByteArray=FileAccess.get_file_as_bytes(args[0])
	var control: Dictionary=JournalSelectionTests.original_read(bytes)
	if control.has("error") or control.torn_tail or control.records.is_empty():printerr("Require a complete valid native journal");quit(2);return
	var count: int=control.records.size();var after_tick: int=maxi(1800,control.records[-1].tick-20)
	var expected: Array=control.records.filter(func(r:Dictionary)->bool:return r.kind=="command" and r.tick>after_tick);ColonyCapture._freeze(expected);control={}
	if not verify("complete",bytes,after_tick,count,expected) or not verify("selected",bytes,after_tick,count,expected):printerr("Warmup differs");quit(2);return
	var rows: Array=[];var passed: bool=true
	for pair in range(4):
		for method in (["complete","selected"] if pair%2==0 else ["selected","complete"]):
			var thread: Thread=Thread.new();var before: int=OS.get_static_memory_usage();var peak: int=before;var started: int=Time.get_ticks_usec()
			if thread.start(verify.bind(method,bytes,after_tick,count,expected))!=OK:printerr("Worker startup failed");quit(2);return
			while thread.is_alive():peak=maxi(peak,OS.get_static_memory_usage());OS.delay_usec(1000)
			var exact: bool=thread.wait_to_finish();var elapsed: int=Time.get_ticks_usec()-started
			rows.append({"pair":pair,"method":method,"elapsed_us":elapsed,"sampled_peak_engine_heap_growth":peak-before,"ending_engine_heap_growth":OS.get_static_memory_usage()-before,"exact_frame_count_and_commands":exact})
			passed=passed and exact;thread=null
	var unchanged: bool=source==fingerprints() and input_sha==FileAccess.get_sha256(args[0])
	var report: Dictionary={"passed":passed and unchanged,"source":source,"reference_commit":"a23033150de2bc6eb2c1581df6c84cce9c43f210","input_sha256":input_sha,"journal_bytes":bytes.size(),"record_count":count,"selected_after_tick":after_tick,"selected_commands":expected.size(),"rows":rows,"unchanged":unchanged,"engine":Engine.get_version_info().string,"scope":"Four alternating background pairs over one unchanged complete native-53 journal. Every frame is parsed/checksummed/schema-checked; only retained private decoded data differs. Roughly 1 ms sampled engine heap on a host with ordinary campaign workers. External recovery and on-disk evidence are unchanged; not a native soak or physical Android PSS/FPS/battery/thermal certificate."}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if report.passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["tools/profile_journal_selection.gd","tools/journal_selection_tests.gd","project.godot","toolchain.lock.json"]:result[path]=FileAccess.get_sha256("res://"+path)
	for folder in ["src","data/catalogs"]:collect("res://"+folder,result)
	return result

func collect(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["gd","json"]:result[folder.path_join(file)]=FileAccess.get_sha256(folder.path_join(file))
	for subdirectory in DirAccess.get_directories_at(folder):collect(folder.path_join(subdirectory),result)
