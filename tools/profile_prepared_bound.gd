extends SceneTree

class OriginalCaptured extends PreparedBoundReference:
	var owned_capture: Dictionary={}
	func _retain_payload(world: RefCounted) -> Dictionary:
		assert(owned_capture.is_read_only() and owned_capture==world.payload())
		return owned_capture
	func _make_delta(before: Dictionary, world: ColonyWorld) -> Dictionary:
		assert(owned_capture.is_read_only() and owned_capture==world.payload())
		return ColonyDelta._make_owned(before,owned_capture)

class CurrentCaptured extends ColonySaveQueue.CapturedStore:
	var fallback_reads: int=0
	func _read_catchup_commands(path: String, tick: int) -> Dictionary:
		fallback_reads+=1
		return super._read_catchup_commands(path,tick)

const FIELDS: Array[String]=["sequence","journal_tick","journal_sequence","journal_length","journal_digest","journal_payload","journal_parent_hash","journal_size_bound","snapshot_tick","recovered"]
func _initialize() -> void:call_deferred("run")
func work(store: ColonyStore, world: ColonyWorld, prepared: ColonyPreparedSnapshot, ready: Semaphore, go: Semaphore) -> Dictionary:
	ready.post();go.wait();var started: int=Time.get_ticks_usec()
	return {"error":store.commit_prepared(world,prepared),"elapsed_us":Time.get_ticks_usec()-started}
func one(which: int, input: String, provenance: Dictionary, output: String, label: String) -> Dictionary:
	var scratch: String="user://profile-prepared-bound-%d-%s" % [Time.get_ticks_usec(),label]
	var store: ColonyStore=OriginalCaptured.new() if which==0 else CurrentCaptured.new();store.directory=scratch;store.sequence=21
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(input.path_join("original-snapshot.brackenward")))
	if not decoded.has("world"):return {"error":"Invalid source snapshot"}
	var world: ColonyWorld=decoded.world;decoded={};var catalog: Dictionary=world.definitions
	var capturer: ColonyCapture=ColonyCapture.new();var retired: Array=[]
	var captured: Dictionary=capturer.capture(world,retired);retired=[];store.set("owned_capture",captured)
	var frozen: ColonyWorld=ColonySaveQueue._world(captured,catalog)
	if not store.save(frozen).is_empty() or store.sequence!=22:return {"error":"Could not initialize exact generation22"}
	var prepared: ColonyPreparedSnapshot
	var exact_prefix: bool=true
	for index in range(provenance.frames.size()):
		if index==provenance.frames.size()-1:prepared=ColonyPreparedSnapshot.prepare(captured,catalog).snapshot
		var frame: PackedByteArray=FileAccess.get_file_as_bytes(input.path_join("markers").path_join(provenance.frames[index].file))
		var parsed: Dictionary=ColonyJournal.read(frame,index+1)
		if parsed.has("error") or parsed.records.size()!=1 or parsed.records[0].kind!="tick":return {"error":"Invalid original marker"}
		var rebuilt: Dictionary=ColonyJournal.replay(world,parsed.records,store.journal_parent_hash,parsed.digests,world.payload())
		if not rebuilt.has("world"):return {"error":"Original marker replay failed"}
		world=rebuilt.world;rebuilt={};parsed={}
		captured=capturer.capture(world,retired);retired=[];store.set("owned_capture",captured);frozen=ColonySaveQueue._world(captured,catalog)
		if index<provenance.frames.size()-1:
			var prior_length: int=store.journal_length
			if not store.checkpoint(frozen).is_empty():return {"error":"Could not recreate verified prefix"}
			var file: FileAccess=FileAccess.open(scratch.path_join("journal-0000000022.frames"),FileAccess.READ);file.seek(prior_length)
			exact_prefix=exact_prefix and file.get_buffer(frame.size())==frame;file.close()
		frame=PackedByteArray()
	world=null;capturer=null;retired=[]
	# A real queue leaves the foreground store's durable base alive until poll.
	var foreground_base: Dictionary=store.journal_payload
	var foreground_hash: String=JSON.stringify(ColonyState.pack(foreground_base),"",false).sha256_text()
	for drain in range(3):await process_frame
	var ready: Semaphore=Semaphore.new();var go: Semaphore=Semaphore.new();var worker: Thread=Thread.new()
	if worker.start(work.bind(store,frozen,prepared,ready,go))!=OK:return {"error":"Thread start failed"}
	ready.wait();var baseline: int=OS.get_static_memory_usage();var maximum: int=baseline;go.post()
	while worker.is_alive():maximum=maxi(maximum,OS.get_static_memory_usage());await process_frame
	var result: Dictionary=worker.wait_to_finish();var ending: int=OS.get_static_memory_usage();maximum=maxi(maximum,ending)
	var state: Dictionary={}
	for key in FIELDS:state[key]=store.get(key)
	var snapshot_path: String=scratch.path_join("snapshot-%010d.brackenward" % store.sequence)
	var journal_path: String=scratch.path_join("journal-%010d.frames" % store.sequence)
	var header: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(snapshot_path));header.erase("timestamp")
	var restored: Dictionary=AsyncSaveTests.load_saved(store)
	var foreground_unchanged: bool=foreground_hash==JSON.stringify(ColonyState.pack(foreground_base),"",false).sha256_text()
	var passed: bool=foreground_unchanged and result.error.is_empty() and exact_prefix and FileAccess.get_sha256(scratch.path_join("journal-0000000022.frames"))==provenance.source_journal_sha256 and store.sequence==23 and restored.has("world") and restored.world.payload()==captured
	var destination: String=output.path_join(label);DirAccess.make_dir_recursive_absolute(destination)
	for path in [snapshot_path,journal_path]:DirAccess.copy_absolute(path,destination.path_join(path.get_file()))
	var row: Dictionary={"which":which,"passed":passed,"elapsed_us":result.elapsed_us,"peak_growth_bytes":maximum-baseline,"ending_growth_bytes":ending-baseline,"error":result.error,"exact_original_prefix_generated":exact_prefix,"foreground_base_unchanged":foreground_unchanged,"prepared_tick":prepared.payload.tick,"snapshot_without_timestamp_hash":JSON.stringify(header,"",true).sha256_text(),"journal_sha256":FileAccess.get_sha256(journal_path),"metadata_hash":JSON.stringify(ColonyState.pack(state),"",false).sha256_text(),"exact_recovery":restored.has("world") and restored.world.payload()==captured,"fallback_reads":store.get("fallback_reads") if which==1 else 1,"final_tick":frozen.tick,"artifacts":destination}
	if passed:CampaignTests.remove_tree(scratch)
	return row
func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=3 or FileAccess.file_exists(args[2]) or DirAccess.dir_exists_absolute(args[1]):quit(2);return
	DirAccess.make_dir_recursive_absolute(args[1]);var source: Dictionary=fingerprints()
	var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0].path_join("input-provenance.json")))
	var inputs: Dictionary={"original-snapshot.brackenward":FileAccess.get_sha256(args[0].path_join("original-snapshot.brackenward"))}
	for entry: Dictionary in provenance.frames:inputs["markers/"+entry.file]=FileAccess.get_sha256(args[0].path_join("markers").path_join(entry.file))
	var rows: Array=[];var expected: Dictionary={};var passed: bool=true
	for pair in range(4):
		for which in ([0,1] if pair%2==0 else [1,0]):
			var row: Dictionary=await one(which,args[0],provenance,args[1],"%d-%d" % [pair,which]);row.pair=pair
			if expected.is_empty():expected=row
			passed=passed and row.get("passed",false) and row.get("snapshot_without_timestamp_hash","")==expected.get("snapshot_without_timestamp_hash","") and row.get("journal_sha256","")==expected.get("journal_sha256","") and row.get("metadata_hash","")==expected.get("metadata_hash","") and (which==0 or row.get("fallback_reads",-1)==0)
			rows.append(row)
	for path in inputs:passed=passed and inputs[path]==FileAccess.get_sha256(args[0].path_join(path))
	passed=passed and source==fingerprints()
	var report: Dictionary={"passed":passed,"rows":rows,"source":source,"inputs_sha256":inputs,"scope":"Four alternating complete original9905cf2/current prepared rotations. Each case recreates all30prefix frames through real save/checkpoint and readback,then measures31st append+prepared catchup+publish. Both use production-equivalent owned immutable capture/delta retention,prepare at30th marker,and explicitly hold foreground durable base through measurement. Exact original8.2MB journal reconstructed; candidate bound derives from actual verified writes,never injected. Source/input,full recovery,wire journal,authoritative metadata and snapshot with only wall timestamp normalized match. Thread lifecycle/sampled heap/diskcache included,no physical/FPS/PSS/session gate claim."}
	var file: FileAccess=FileAccess.open(args[2],FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if passed else 1)
func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","src/persistence/colony_store.gd","src/persistence/colony_save_queue.gd","src/persistence/colony_delta.gd","src/persistence/colony_journal.gd","src/persistence/colony_journal_encoding.gd","src/persistence/colony_capture.gd","src/persistence/colony_prepared_snapshot.gd","src/persistence/colony_snapshot_encoding.gd","src/persistence/colony_snapshot_tree.gd","tools/prepared_bound_reference.gd","tools/prepared_bound_tests.gd","tools/profile_prepared_bound.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	return result
