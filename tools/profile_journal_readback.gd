extends SceneTree
func _initialize() -> void:call_deferred("run")
func decode_case(which: int, bytes: PackedByteArray, sequence: int, ready: Semaphore, go: Semaphore) -> Dictionary:
	ready.post();go.wait()
	var started: int=Time.get_ticks_usec()
	var result: Dictionary=JournalReadReference.read(bytes,sequence) if which==0 else ColonyJournal._read_owned(bytes,sequence)
	return {"value":result,"elapsed_us":Time.get_ticks_usec()-started}
func one(which: int, bytes: PackedByteArray, sequence: int) -> Dictionary:
	# Let completed coroutine/Thread holders release before measuring the next case.
	for drain_frame in range(3):await process_frame
	var ready: Semaphore=Semaphore.new();var go: Semaphore=Semaphore.new();var worker: Thread=Thread.new()
	var error: Error=worker.start(decode_case.bind(which,bytes,sequence,ready,go))
	if error!=OK:return {"error":"Could not start worker"}
	ready.wait();var baseline: int=OS.get_static_memory_usage();var maximum: int=baseline
	go.post()
	while worker.is_alive():
		maximum=maxi(maximum,OS.get_static_memory_usage());await process_frame
	var result: Dictionary=worker.wait_to_finish();var ending: int=OS.get_static_memory_usage();maximum=maxi(maximum,ending)
	return {"which":which,"elapsed_us":result.elapsed_us,"peak_growth_bytes":maximum-baseline,"ending_growth_bytes":ending-baseline,"output_hash":JSON.stringify(ColonyState.pack(result.value),"",false).sha256_text(),"decoded":not result.value.has("error"),"record_count":result.value.get("records",[]).size()}
func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=3 or not args[1].is_valid_int() or FileAccess.file_exists(args[2]):quit(2);return
	var source: Dictionary=fingerprints()
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(args[0]);var initial: String=ColonyJournal._hash(bytes).hex_encode()
	var warm: PackedByteArray=ColonyJournal.frame({"sequence":"1","kind":"tick","tick":1800,"delta":{"version":1,"base_tick":1800,"campaign_id":"warm","parent":"a".repeat(64),"patch":{}}})
	JournalReadReference.read(warm);ColonyJournal._read_owned(warm)
	var rows: Array=[];var expected: String="";var passed: bool=true
	for pair in range(4):
		for which in ([0,1] if pair%2==0 else [1,0]):
			var row: Dictionary=await one(which,bytes,int(args[1]));row.pair=pair
			if expected.is_empty():expected=row.get("output_hash","")
			passed=passed and row.get("decoded",false) and row.get("output_hash","")==expected;rows.append(row)
	passed=passed and initial==ColonyJournal._hash(bytes).hex_encode() and source==fingerprints()
	var report: Dictionary={"passed":passed,"rows":rows,"input_sha256":initial,"first_sequence":int(args[1]),"harness_sha256":FileAccess.get_sha256(get_script().resource_path),"source":fingerprints(),"scope":"Four alternating complete original126407a/public and private writer-reader pairs on unchanged real input. Native heap sampling on main thread while worker decodes,three-frame holder drain between cases; output hashes/unsorted packed types/order exact. Thread lifecycle and sampling remain in measurement scope. No physical/FPS/PSS or whole-checkpoint claim."}
	var file: FileAccess=FileAccess.open(args[2],FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","tools/profile_journal_readback.gd","tools/journal_read_reference.gd","tools/journal_read_tests.gd","src/persistence/colony_journal.gd","src/persistence/colony_store.gd","src/persistence/colony_prepared_snapshot.gd","src/sim/colony_state.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	return result
