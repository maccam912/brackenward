extends SceneTree
## Complete original/current external decode on immutable input bytes.
func _initialize() -> void:call_deferred("run")

func worker(method: String, bytes: PackedByteArray) -> Dictionary:
	return SnapshotMigrationTests.original(bytes) if method=="original" else ColonyCodec.decode(bytes)

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not FileAccess.file_exists(args[0]) or FileAccess.file_exists(args[1]):printerr("Usage: -- SNAPSHOT NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprints();var input_sha: String=FileAccess.get_sha256(args[0]);var bytes: PackedByteArray=FileAccess.get_file_as_bytes(args[0])
	var control: Dictionary=worker("original",bytes)
	if not control.has("world"):printerr(control);quit(2);return
	var expected: Dictionary=control.world.payload().duplicate(true);var canonical: String=control.world.canonical_hash();control={}
	var warmup: Dictionary=worker("candidate",bytes)
	if not warmup.has("world") or warmup.world.payload()!=expected:printerr("Candidate warmup differs");quit(2);return
	warmup={}
	var rows: Array=[];var passed: bool=true
	for pair in range(4):
		for method in (["original","candidate"] if pair%2==0 else ["candidate","original"]):
			var thread: Thread=Thread.new();var before: int=OS.get_static_memory_usage();var peak: int=before;var started: int=Time.get_ticks_usec()
			if thread.start(worker.bind(method,bytes))!=OK:printerr("Worker startup failed");quit(2);return
			while thread.is_alive():peak=maxi(peak,OS.get_static_memory_usage());OS.delay_usec(1000)
			var result: Dictionary=thread.wait_to_finish();var elapsed: int=Time.get_ticks_usec()-started;var ending: int=OS.get_static_memory_usage()-before
			var exact: bool=result.has("world") and result.world.payload()==expected and result.world.canonical_hash()==canonical
			rows.append({"pair":pair,"method":method,"elapsed_us":elapsed,"sampled_peak_engine_heap_growth":peak-before,"ending_engine_heap_growth":ending,"complete_payload_equal":exact})
			passed=passed and exact;result={};thread=null
	var corpus: Array=[];var paths: Array[String]=[];SnapshotByteTests.collect("res://tests/fixtures",paths)
	for path: String in paths:
		var sha: String=FileAccess.get_sha256(path);var exact: bool=SnapshotMigrationTests.equivalent(FileAccess.get_file_as_bytes(path)) and sha==FileAccess.get_sha256(path)
		corpus.append({"file":path.trim_prefix("res://tests/fixtures/"),"passed":exact,"input_sha256":sha});passed=passed and exact
	var unchanged: bool=source==fingerprints() and input_sha==FileAccess.get_sha256(args[0]) and bytes==FileAccess.get_file_as_bytes(args[0])
	var report: Dictionary={"passed":passed and unchanged and corpus.size()==43,"reference_commit":"fd29cfe852960ed0dad87873e747975aaad157ef","source":source,"input_sha256":input_sha,"canonical_hash":canonical,"rows":rows,"immutable_fixture_corpus":corpus,"unchanged":unchanged,"engine":Engine.get_version_info().string,"scope":"Four alternating background full-decode pairs on retained bytes, plus43 immutable fixtures. Originalfd29cfe decoder body retained; public restore keeps its original copy behavior. Only the fresh owned parser path avoids a deep copy for validated header-only migration; every schema/reference/invariant check and saved field remains. Roughly1-ms process engine-heap sampling; ending memory read before diagnostic payload/hash equality. Frozen native/Winter/Charter work shares host. Not whole-native or physical Android PSS/frame/battery/thermal certification."}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if report.passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","toolchain.lock.json","tools/snapshot_migration_tests.gd","tools/profile_snapshot_migration.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	for folder in ["src","data/catalogs"]:collect("res://"+folder,result)
	return result

func collect(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["gd","json"]:result[folder.path_join(file)]=FileAccess.get_sha256(folder.path_join(file))
	for subdirectory in DirAccess.get_directories_at(folder):collect(folder.path_join(subdirectory),result)
