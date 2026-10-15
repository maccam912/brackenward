extends SceneTree
## Compare retained 6685958 preparation with validated-capture block comparison.
func _initialize() -> void:call_deferred("run")

func worker(method: String, captured: Dictionary, catalog: Dictionary) -> Dictionary:
	return SnapshotCaptureTests.original(captured,catalog) if method=="original" else ColonyPreparedSnapshot.prepare(captured,catalog)

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not FileAccess.file_exists(args[0]) or FileAccess.file_exists(args[1]):printerr("Usage: -- SNAPSHOT NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprints();var input_sha: String=FileAccess.get_sha256(args[0])
	var loaded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not loaded.has("world"):printerr(loaded);quit(2);return
	var world: ColonyWorld=loaded.world;var canonical: String=world.canonical_hash();var captured: Dictionary=ColonyCapture.new().capture(world,[])
	var control: Dictionary=worker("original",captured,world.definitions)
	if not control.has("snapshot"):printerr(control);quit(2);return
	var expected: String=control.snapshot.text;control={}
	var warmup: Dictionary=worker("candidate",captured,world.definitions)
	if not warmup.has("snapshot") or warmup.snapshot.text!=expected:printerr("Candidate warmup differs");quit(2);return
	warmup={}
	var rows: Array=[];var passed: bool=true
	for pair in range(4):
		for method in (["original","candidate"] if pair%2==0 else ["candidate","original"]):
			var thread: Thread=Thread.new();var before: int=OS.get_static_memory_usage();var peak: int=before;var started: int=Time.get_ticks_usec()
			if thread.start(worker.bind(method,captured,world.definitions))!=OK:printerr("Worker startup failed");quit(2);return
			while thread.is_alive():peak=maxi(peak,OS.get_static_memory_usage());OS.delay_usec(1000)
			var result: Dictionary=thread.wait_to_finish();var elapsed: int=Time.get_ticks_usec()-started
			var exact: bool=result.has("snapshot") and result.snapshot.validated and result.snapshot.text==expected and result.snapshot.digest==canonical and is_same(result.snapshot.payload,captured)
			rows.append({"pair":pair,"method":method,"elapsed_us":elapsed,"sampled_peak_engine_heap_growth":peak-before,"ending_engine_heap_growth":OS.get_static_memory_usage()-before,"exact_full_text":exact})
			passed=passed and exact;result={};thread=null
	var corpus: Array=[]
	for name in DirAccess.get_files_at("res://tests/fixtures"):
		if not name.ends_with(".brackenward"):continue
		var path: String="res://tests/fixtures/"+name;var sha: String=FileAccess.get_sha256(path);var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(path))
		if not decoded.has("world"):corpus.append({"file":name,"passed":false});passed=false;continue
		var saved: ColonyWorld=decoded.world;var saved_hash: String=saved.canonical_hash();var owned: Dictionary=ColonyCapture.new().capture(saved,[])
		var old: Dictionary=worker("original",owned,saved.definitions);var candidate: Dictionary=worker("candidate",owned,saved.definitions)
		var exact: bool=old.has("snapshot") and candidate.has("snapshot") and candidate.snapshot.text==old.snapshot.text and candidate.snapshot.digest==saved_hash and candidate.snapshot.validated and saved.canonical_hash()==saved_hash and FileAccess.get_sha256(path)==sha
		corpus.append({"file":name,"passed":exact,"input_sha256":sha,"canonical_hash":saved_hash});passed=passed and exact
	var unchanged: bool=source==fingerprints() and input_sha==FileAccess.get_sha256(args[0]) and world.canonical_hash()==canonical
	var report: Dictionary={"passed":passed and unchanged and corpus.size()==32,"reference_commit":"6685958cc27e85dd0a5ab6ef836e939ed160a2b6","source":source,"input_sha256":input_sha,"canonical_hash":canonical,"rows":rows,"immutable_fixture_corpus":corpus,"unchanged":unchanged,"engine":Engine.get_version_info().string,"scope":"Four alternating headless background-preparation pairs and 32 immutable save fixtures. Baselines include retained reference text. Roughly 1 ms sampled process engine heap; host concurrency is declared separately. The complete 6685958 decoded-tree factory and decoder are retained references; encode and public codec remain unchanged. Exact actual block/capture equality plus full schema/reference/conservation validation is required. Not a native soak, Android PSS/frame-rate or physical certification."}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if report.passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","toolchain.lock.json","tools/legacy_prepared_snapshot.gd","tools/profile_snapshot_capture.gd","tools/snapshot_capture_tests.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	for folder in ["src","data/catalogs"]:collect("res://"+folder,result)
	return result

func collect(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["gd","json"]:result[folder.path_join(file)]=FileAccess.get_sha256(folder.path_join(file))
	for subdirectory in DirAccess.get_directories_at(folder):collect(folder.path_join(subdirectory),result)
