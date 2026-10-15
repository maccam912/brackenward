extends SceneTree
func _initialize() -> void:call_deferred("run")
func candidate(record: Dictionary) -> PackedByteArray:
	return ColonyJournal._frame_bounded(record)

func work(which: int, record: Dictionary, ready: Semaphore, go: Semaphore) -> Dictionary:
	ready.post();go.wait();var started: int=Time.get_ticks_usec()
	var result: PackedByteArray=JournalReadReference.frame(record) if which==0 else candidate(record)
	return {"bytes":result,"elapsed_us":Time.get_ticks_usec()-started}
func one(which: int, record: Dictionary, expected: PackedByteArray) -> Dictionary:
	for frame in range(3):await process_frame
	var ready: Semaphore=Semaphore.new();var go: Semaphore=Semaphore.new();var worker: Thread=Thread.new()
	if worker.start(work.bind(which,record,ready,go))!=OK:return {"error":"Thread start failed"}
	ready.wait();var baseline: int=OS.get_static_memory_usage();var maximum: int=baseline;go.post()
	while worker.is_alive():maximum=maxi(maximum,OS.get_static_memory_usage());await process_frame
	var result: Dictionary=worker.wait_to_finish();var ending: int=OS.get_static_memory_usage();maximum=maxi(maximum,ending)
	return {"which":which,"elapsed_us":result.elapsed_us,"peak_growth_bytes":maximum-baseline,"ending_growth_bytes":ending-baseline,"exact_original_bytes":result.bytes==expected,"output_sha256":ColonyJournal._hash(result.bytes).hex_encode()}
func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or FileAccess.file_exists(args[1]):quit(2);return
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(args[0]);var decoded: Dictionary=ColonyJournal.read(bytes,13)
	if decoded.has("error"):print(decoded);quit(2);return
	var record: Dictionary=decoded.records[0];var unchanged: String=JSON.stringify(ColonyState.pack(record),"",false).sha256_text();decoded={}
	var source: Dictionary=fingerprints();var rows: Array=[];var passed: bool=true
	for pair in range(4):
		for which in ([0,1] if pair%2==0 else [1,0]):
			var row: Dictionary=await one(which,record,bytes);row.pair=pair;rows.append(row);passed=passed and row.get("exact_original_bytes",false)
	passed=passed and source==fingerprints() and unchanged==JSON.stringify(ColonyState.pack(record),"",false).sha256_text() and bytes==FileAccess.get_file_as_bytes(args[0])
	var report: Dictionary={"passed":passed,"rows":rows,"source":source,"input_sha256":ColonyJournal._hash(bytes).hex_encode(),"scope":"Four alternating full independent original journal frame vs production bounded writer encoder. Fresh parsed real sequence13 marker, exact byte equality,3frame holder drain, sampled native heap includes thread lifecycle. Host concurrency declared with the evidence; no physical/FPS/PSS or whole-session inference."}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if passed else 1)
func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","src/persistence/colony_journal.gd","src/persistence/colony_journal_encoding.gd","src/persistence/colony_store.gd","src/sim/colony_state.gd","tools/journal_read_reference.gd","tools/journal_frame_tests.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	result.harness=FileAccess.get_sha256(get_script().resource_path);return result
