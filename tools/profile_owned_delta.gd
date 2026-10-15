extends SceneTree
func _initialize() -> void:call_deferred("run")
func work(which: int, before: Dictionary, after: Dictionary, ready: Semaphore, go: Semaphore) -> Dictionary:
	ready.post();go.wait();var started: int=Time.get_ticks_usec()
	var patch: Dictionary=OwnedDeltaReference.make(before,after) if which==0 else ColonyDelta._make_owned(before,after)
	return {"patch":patch,"elapsed_us":Time.get_ticks_usec()-started}
func one(which: int, before: Dictionary, after: Dictionary) -> Dictionary:
	for frame in range(3):await process_frame
	var ready: Semaphore=Semaphore.new();var go: Semaphore=Semaphore.new();var worker: Thread=Thread.new()
	if worker.start(work.bind(which,before,after,ready,go))!=OK:return {"error":"Thread start"}
	ready.wait();var baseline: int=OS.get_static_memory_usage();var maximum: int=baseline;go.post()
	while worker.is_alive():maximum=maxi(maximum,OS.get_static_memory_usage());await process_frame
	var result: Dictionary=worker.wait_to_finish();var ending: int=OS.get_static_memory_usage();maximum=maxi(maximum,ending)
	return {"which":which,"elapsed_us":result.elapsed_us,"peak_growth_bytes":maximum-baseline,"ending_growth_bytes":ending-baseline,"hash":JSON.stringify(ColonyState.pack(result.patch),"",false).sha256_text(),"matches":ColonyDelta.matches(before,result.patch,after),"restores":ColonyDelta.restore(before,result.patch).get("state")==after}
func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=3 or FileAccess.file_exists(args[2]):quit(2);return
	var source: Dictionary=fingerprints()
	var store: ColonyStore=ColonyStore.new();store.directory=args[0];var base: Dictionary=store.load_latest()
	var frame: PackedByteArray=FileAccess.get_file_as_bytes(args[1]);var parsed: Dictionary=ColonyJournal.read(frame,13)
	var prefix: Dictionary=ColonyJournal.read(FileAccess.get_file_as_bytes(args[0].path_join("journal-0000000022.frames")))
	if not base.has("world") or parsed.has("error") or prefix.has("error"):print("Invalid fixture");quit(2);return
	var target: Dictionary=ColonyJournal.replay(base.world,parsed.records,prefix.digests[-1],parsed.digests,base.world.payload())
	if not target.has("world"):print(target);quit(2);return
	var before: Dictionary=ColonyCapture.new().capture(base.world,[]);var after: Dictionary=ColonyCapture.new().capture(target.world,[])
	var original_before: String=JSON.stringify(ColonyState.pack(before),"",false).sha256_text();var original_after: String=JSON.stringify(ColonyState.pack(after),"",false).sha256_text()
	base={};target={};prefix={};parsed={}
	var rows: Array=[];var expected: String="";var passed: bool=true
	for pair in range(4):
		for which in ([0,1] if pair%2==0 else [1,0]):
			var row: Dictionary=await one(which,before,after);row.pair=pair
			if expected.is_empty():expected=row.get("hash","")
			passed=passed and row.get("matches",false) and row.get("restores",false) and row.get("hash","")==expected;rows.append(row)
	passed=passed and source==fingerprints() and original_before==JSON.stringify(ColonyState.pack(before),"",false).sha256_text() and original_after==JSON.stringify(ColonyState.pack(after),"",false).sha256_text()
	var report: Dictionary={"passed":passed,"rows":rows,"source":source,"harness_sha256":FileAccess.get_sha256(get_script().resource_path),"delta_source_sha256":FileAccess.get_sha256("res://src/persistence/colony_delta.gd"),"target_frame_sha256":ColonyJournal._hash(frame).hex_encode(),"scope":"Final production comparison on fully validated real26426/26466 world captures. Complete independent original2446783 delta source versus private owned writer helper. Exact unsorted patch hash,full matches/restore,input unchanged;4alternating pairs with3frame holder drain. Host concurrency declared with evidence;no physical/FPS/PSS or whole-session inference."}
	var file: FileAccess=FileAccess.open(args[2],FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","src/persistence/colony_delta.gd","src/persistence/colony_store.gd","src/persistence/colony_save_queue.gd","src/persistence/colony_capture.gd","tools/owned_delta_reference.gd","tools/owned_delta_tests.gd","tools/profile_owned_delta.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	return result
