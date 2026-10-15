extends SceneTree
## Compare full preparation with a payload-only validation experiment.
## Original implementation is retained independently in PreparationReadTests.

func _initialize() -> void:
	call_deferred("run")


func worker(method: String, captured: Dictionary, catalog: Dictionary) -> Dictionary:
	return PreparationReadTests.original(captured,catalog) if method=="original" else ColonyPreparedSnapshot.prepare(captured,catalog)

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or FileAccess.file_exists(args[1]):printerr("Usage: -- SNAPSHOT NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprint();var input_sha: String=FileAccess.get_sha256(args[0])
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"):printerr(decoded);quit(2);return
	var world: ColonyWorld=decoded.world;var canonical: String=world.canonical_hash()
	var captured: Dictionary=ColonyCapture.new().capture(world,[])
	var rows: Array=[];var passed: bool=true;var expected_text: String=""
	for pair in range(4):
		for method in (["original","candidate"] if pair%2==0 else ["candidate","original"]):
			var thread: Thread=Thread.new();var before: int=OS.get_static_memory_usage();var peak: int=before;var started: int=Time.get_ticks_usec()
			if thread.start(worker.bind(method,captured,world.definitions))!=OK:printerr("Thread startup failed");quit(2);return
			while thread.is_alive():
				peak=maxi(peak,OS.get_static_memory_usage());OS.delay_usec(1000)
			var result: Dictionary=thread.wait_to_finish();var elapsed: int=Time.get_ticks_usec()-started
			var exact: bool=false
			if result.has("snapshot"):
				if expected_text.is_empty():expected_text=result.snapshot.text
				exact=result.snapshot.text==expected_text and result.snapshot.digest==canonical and result.snapshot.validated and is_same(result.snapshot.payload,captured)
			rows.append({"pair":pair,"method":method,"elapsed_us":elapsed,"sampled_peak_engine_heap_growth":peak-before,"complete_result_equal":exact})
			passed=passed and exact;result={};thread=null
	var invalid: Dictionary=captured.duplicate(true);invalid.citizens[0].rest=-1;ColonyCapture._freeze(invalid)
	var invalid_rejected: bool=worker("original",invalid,world.definitions).has("error") and worker("candidate",invalid,world.definitions).has("error")
	var unchanged: bool=source==fingerprint() and input_sha==FileAccess.get_sha256(args[0]) and world.canonical_hash()==canonical
	var report: Dictionary={"passed":passed and unchanged and invalid_rejected,"source":source,"input_sha256":input_sha,"canonical_hash":canonical,"rows":rows,"invalid_schema_rejected":invalid_rejected,"unchanged":unchanged,"engine":Engine.get_version_info().string,"scope":"Headless background preparation comparison; sampled engine heap and CPU only, no save writes or simulation progress. Exact source fingerprints identify the compared runtime and original paths; physical gates remain separate."}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if report.passed else 1)

func fingerprint() -> Dictionary:
	var result: Dictionary={}
	for path in ["src/persistence/colony_prepared_snapshot.gd","src/persistence/colony_codec.gd","tools/preparation_read_tests.gd","tools/legacy_prepared_snapshot.gd","tools/profile_snapshot_preparation.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	return result
