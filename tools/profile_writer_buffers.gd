extends SceneTree

class OriginalCaptured extends WriterBuffersReference:
	var owned_capture: Dictionary={}
	func _retain_payload(world: RefCounted) -> Dictionary:
		assert(owned_capture.is_read_only() and owned_capture==world.payload())
		return owned_capture

const FIELDS: Array[String]=["sequence","journal_tick","journal_sequence","journal_length","journal_digest","recovered","journal_payload","journal_parent_hash","journal_size_bound","snapshot_tick"]
func _initialize() -> void:call_deferred("run")
func work(store: ColonyStore, world: ColonyWorld, ready: Semaphore, go: Semaphore) -> Dictionary:
	ready.post();go.wait()
	var started: int=Time.get_ticks_usec()
	return {"error":store.checkpoint(world),"elapsed_us":Time.get_ticks_usec()-started}
func one(which: int, input: String, template: ColonyStore, captured: Dictionary, catalog: Dictionary, directory: String, expected: PackedByteArray) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(directory)
	for name in DirAccess.get_files_at(input):DirAccess.copy_absolute(input.path_join(name),directory.path_join(name))
	var store: ColonyStore=OriginalCaptured.new() if which==0 else ColonySaveQueue.CapturedStore.new()
	store.set("owned_capture",captured);store.directory=directory
	for key in FIELDS:store.set(key,template.get(key))
	for path in template.verified_generations:store.verified_generations[directory.path_join(path.get_file())]=template.verified_generations[path]
	for path in template.verified_journals:store.verified_journals[directory.path_join(path.get_file())]=template.verified_journals[path]
	var frozen: ColonyWorld=ColonySaveQueue._world(captured,catalog)
	for frame in range(3):await process_frame
	var ready: Semaphore=Semaphore.new();var go: Semaphore=Semaphore.new();var worker: Thread=Thread.new()
	if worker.start(work.bind(store,frozen,ready,go))!=OK:return {"error":"Thread start failed"}
	ready.wait();var baseline: int=OS.get_static_memory_usage();var maximum: int=baseline
	go.post()
	while worker.is_alive():maximum=maxi(maximum,OS.get_static_memory_usage());await process_frame
	var result: Dictionary=worker.wait_to_finish();var ending: int=OS.get_static_memory_usage();maximum=maxi(maximum,ending)
	var journal: PackedByteArray=FileAccess.get_file_as_bytes(directory.path_join("journal-%010d.frames" % store.sequence))
	var state: Dictionary={}
	for key in FIELDS:state[key]=store.get(key)
	var recovered: Dictionary=AsyncSaveTests.load_saved(store)
	return {"which":which,"elapsed_us":result.elapsed_us,"peak_growth_bytes":maximum-baseline,"ending_growth_bytes":ending-baseline,"error":result.error,"exact_appended_frame":journal.slice(template.journal_length)==expected,"journal_sha256":ColonyJournal._hash(journal).hex_encode(),"metadata_hash":JSON.stringify(ColonyState.pack(state),"",false).sha256_text(),"exact_recovery":recovered.has("world") and recovered.world.payload()==captured,"input_unchanged":frozen.payload()==captured}
func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=3 or FileAccess.file_exists(args[2]):quit(2);return
	var source: Dictionary=fingerprints();var input_hash: Dictionary={}
	for name in DirAccess.get_files_at(args[0]):input_hash[name]=FileAccess.get_sha256(args[0].path_join(name))
	var template: ColonyStore=ColonyStore.new();template.directory=args[0]
	var base: Dictionary=template.load_latest()
	if not base.has("world"):print(base);quit(2);return
	# Recovery intentionally requires a fresh snapshot. This benchmark models an
	# already verified in-memory writer instead, deriving every anchor from the
	# fully validated original snapshot/prefix and their exact bytes/digests.
	var snapshot_path: String=args[0].path_join("snapshot-0000000022.brackenward")
	var snapshot: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(snapshot_path))
	var prefix_path: String=args[0].path_join("journal-0000000022.frames")
	var prefix: PackedByteArray=FileAccess.get_file_as_bytes(prefix_path);var prior: Dictionary=ColonyJournal.read(prefix)
	if not snapshot.has("world") or prior.has("error") or prior.records.size()!=12 or base.world.tick!=26426:print("Invalid original base");quit(2);return
	template.journal_payload=base.world.payload().duplicate(true);template.snapshot_tick=snapshot.world.tick
	template.journal_sequence=12;template.journal_length=prefix.size();template.journal_digest=FileAccess.get_sha256(prefix_path)
	template.journal_parent_hash=prior.digests[-1];template.journal_size_bound=FileAccess.get_file_as_bytes(snapshot_path).size()+2*prefix.size();template.recovered=false
	template.verified_generations[snapshot_path]=FileAccess.get_sha256(snapshot_path)
	snapshot={};prefix=PackedByteArray();prior={}
	var frame: PackedByteArray=FileAccess.get_file_as_bytes(args[1]);var frame_hash: String=ColonyJournal._hash(frame).hex_encode()
	var parsed: Dictionary=ColonyJournal.read(frame,13)
	if not base.has("world") or parsed.has("error"):print("Input chain failed");quit(2);return
	var target: Dictionary=ColonyJournal.replay(base.world,parsed.records,template.journal_parent_hash,parsed.digests,template.journal_payload)
	if not target.has("world"):print(target);quit(2);return
	var captured: Dictionary=ColonyCapture.new().capture(target.world,[]);var catalog: Dictionary=target.world.definitions
	ColonyCapture._freeze(template.journal_payload)
	base={};target={};parsed={}
	var scratch: String="user://profile-writer-buffers-%d" % Time.get_ticks_usec()
	var rows: Array=[];var expected: String="";var metadata: String="";var passed: bool=true
	for pair in range(4):
		for which in ([0,1] if pair%2==0 else [1,0]):
			var row: Dictionary=await one(which,args[0],template,captured,catalog,scratch.path_join("%d-%d" % [pair,which]),frame);row.pair=pair
			if expected.is_empty():expected=row.get("journal_sha256","");metadata=row.get("metadata_hash","")
			passed=passed and row.get("error","missing").is_empty() and row.get("exact_appended_frame",false) and row.get("exact_recovery",false) and row.get("input_unchanged",false) and row.get("journal_sha256","")==expected and row.get("metadata_hash","")==metadata
			rows.append(row)
	for name in input_hash:passed=passed and input_hash[name]==FileAccess.get_sha256(args[0].path_join(name))
	passed=passed and source==fingerprints() and frame_hash==FileAccess.get_sha256(args[1])
	var report: Dictionary={"passed":passed,"rows":rows,"source":source,"input_chain_sha256":input_hash,"target_frame_sha256":frame_hash,"scope":"Four alternating complete original7698c08/current checkpoint pairs on same retained real snapshot12-frame prefix and13th target marker. Both use production-equivalent owned read-only capture retention. Actual disk append/readback/match included, native heap sampled while worker runs,3frame holder drain. Exact appended bytes,metadata,complete recovery and unchanged input/source. No physical/FPS/PSS or whole-session gate claim."}
	var file: FileAccess=FileAccess.open(args[2],FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report))
	if passed:CampaignTests.remove_tree(scratch)
	quit(0 if passed else 1)
func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","src/persistence/colony_store.gd","src/persistence/colony_save_queue.gd","src/persistence/colony_journal.gd","src/persistence/colony_delta.gd","src/persistence/colony_capture.gd","src/persistence/colony_codec.gd","tools/writer_buffers_reference.gd","tools/writer_buffers_tests.gd","tools/profile_writer_buffers.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	return result
