extends SceneTree
## Attribute the candidate's sampled peak to actual production phase calls.
func _initialize() -> void:call_deferred("run")

func sample(stage: String, operation: Callable, baseline: int) -> Dictionary:
	var thread: Thread=Thread.new();var before: int=OS.get_static_memory_usage();var peak: int=before;var started: int=Time.get_ticks_usec()
	if thread.start(operation)!=OK:return {"error":"Cannot start phase worker"}
	while thread.is_alive():peak=maxi(peak,OS.get_static_memory_usage());OS.delay_usec(1000)
	var value: Variant=thread.wait_to_finish();peak=maxi(peak,OS.get_static_memory_usage())
	return {"value":value,"row":{"stage":stage,"elapsed_us":Time.get_ticks_usec()-started,"peak_growth_from_phase_start":peak-before,"peak_growth_from_prepare_start":peak-baseline,"ending_growth_from_prepare_start":OS.get_static_memory_usage()-baseline}}

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not FileAccess.file_exists(args[0]) or FileAccess.file_exists(args[1]):printerr("Usage: -- SNAPSHOT NEW_REPORT");quit(2);return
	var loaded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not loaded.has("world"):printerr(loaded);quit(2);return
	var world: ColonyWorld=loaded.world;var captured: Dictionary=ColonyCapture.new().capture(world,[])
	var control: Dictionary=ColonyPreparedSnapshot.prepare(captured,world.definitions)
	if not control.has("snapshot"):printerr(control);quit(2);return
	var expected_digest: String=control.snapshot.digest;control={}
	var baseline: int=OS.get_static_memory_usage();var rows: Array=[]
	var sampled: Dictionary=sample("full_capture_validation",func()->Dictionary:return ColonyCodec.restore(captured),baseline)
	if not sampled.get("value",{}).has("world") or sampled.value.world.payload()!=captured:printerr("Validation failed");quit(2);return
	rows.append(sampled.row);sampled={}
	sampled=sample("encode_nested_blocks",func()->Dictionary:return ColonySnapshotTree.encode(captured),baseline)
	var encoded: Dictionary=sampled.value
	if encoded.has("error"):printerr(encoded);quit(2);return
	rows.append(sampled.row);sampled={}
	sampled=sample("verify_actual_serialized_blocks",func()->Dictionary:return ColonySnapshotTree.matches(encoded.bytes,encoded.tree,captured),baseline)
	if not sampled.value.get("matched",false):printerr(sampled.value);quit(2);return
	rows.append(sampled.row);sampled={};encoded.tree={}
	sampled=sample("materialize_payload_text",func()->String:return encoded.bytes.get_string_from_utf8(),baseline)
	var payload: String=sampled.value;rows.append(sampled.row);sampled={};encoded={}
	var identity: ColonyWorld=ColonyWorld.new(world.definitions);identity.session_id=captured.session_id;identity.generator_version=captured.generator_version
	sampled=sample("wrap_reference_envelope",func()->PackedByteArray:return ColonyCodec.wrap_payload(identity,payload),baseline)
	var reference_bytes: PackedByteArray=sampled.value;var reference_hash: String=digest(reference_bytes);var reference: Dictionary=JSON.parse_string(reference_bytes.get_string_from_utf8());var timestamp: String=reference.timestamp;reference={};rows.append(sampled.row);sampled={};reference_bytes=PackedByteArray()
	sampled=sample("wrap_bounded_envelope",func()->PackedByteArray:return ColonySnapshotEnvelope.wrap(identity,payload,"",0,timestamp),baseline)
	var bytes: PackedByteArray=sampled.value;rows.append(sampled.row);sampled={}
	var report: Dictionary={"passed":payload.sha256_text()==expected_digest and not bytes.is_empty() and bytes.size()<=ColonyCodec.MAX_BYTES and digest(bytes)==reference_hash,"input_sha256":FileAccess.get_sha256(args[0]),"canonical_hash":expected_digest,"rows":rows,"payload_characters":payload.length(),"envelope_bytes":bytes.size(),"source":{"src/persistence/colony_snapshot_tree.gd":FileAccess.get_sha256("res://src/persistence/colony_snapshot_tree.gd"),"src/persistence/colony_snapshot_envelope.gd":FileAccess.get_sha256("res://src/persistence/colony_snapshot_envelope.gd"),"src/persistence/colony_snapshot_encoding.gd":FileAccess.get_sha256("res://src/persistence/colony_snapshot_encoding.gd"),"src/persistence/colony_codec.gd":FileAccess.get_sha256("res://src/persistence/colony_codec.gd"),"tools/profile_snapshot_capture_stages.gd":FileAccess.get_sha256("res://tools/profile_snapshot_capture_stages.gd")},"scope":"One diagnostic pass using actual production phase calls, plus a separate reference-envelope call with its output released before the bounded call. Roughly 1 ms sampled process engine heap. Thread startup adds phase overhead; reference parsing/digest checks occur outside sampled calls and add diagnostic overhead. This is attribution, not a whole-native benchmark."}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot write report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if report.passed else 1)

func digest(bytes: PackedByteArray) -> String:
	var context: HashingContext=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(bytes);return context.finish().hex_encode()
