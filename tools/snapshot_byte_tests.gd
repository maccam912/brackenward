class_name SnapshotByteTests
extends RefCounted
## Complete 1270652 preparation body with its original String-backed record.
static func original(captured: Dictionary, catalog: Dictionary) -> Dictionary:
	if not captured.is_read_only():return {"error":"Snapshot preparation needs an owned immutable capture"}
	if captured.get("content_hash")!=catalog.get("content_hash"):return {"error":"Snapshot preparation catalog differs from immutable capture"}
	if not captured.get("session_id") is String or not captured.get("generator_version") is int:return {"error":"Invalid snapshot identity metadata"}
	# Full validation can read the owned immutable capture directly. Proving
	# every serialized value equals this validated state avoids retaining a
	# second complete decoded world; external decoding is unchanged.
	var verified: Dictionary=ColonyCodec.restore(captured)
	if not verified.has("world") or verified.world.payload()!=captured:return {"error":"Snapshot preparation failed full validation: "+str(verified.get("error","state mismatch"))}
	verified={}
	var encoded: Dictionary=ColonySnapshotTree.encode(captured)
	if encoded.has("error"):return encoded
	var compared: Dictionary=ColonySnapshotTree.matches(encoded.bytes,encoded.tree,captured)
	if compared.has("error"):return compared
	encoded.tree={}
	var result: LegacyPreparedSnapshot=LegacyPreparedSnapshot.new()
	result.payload=captured;result.text=encoded.bytes.get_string_from_utf8();encoded={}
	result.digest=result.text.sha256_text()
	var identity: ColonyWorld=ColonyWorld.new(catalog)
	identity.session_id=captured.session_id;identity.generator_version=captured.generator_version
	var bytes: PackedByteArray=ColonySnapshotEnvelope.wrap(identity,result.text)
	if bytes.is_empty() or bytes.size()>ColonyCodec.MAX_BYTES:return {"error":"Colony snapshot is empty or exceeds 64 MiB"}
	result.validated=true
	return {"snapshot":result}

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();var timestamp: String="2026-10-15T12:00:00"
	var texts: Array=["","plain","\"\\/\b\f\n\r\t☀雨😀\u2028\u2029"]
	for length in [4093,4094,4095,4096,4097,8191,8192,8193]:
		for value in ["☀","😀","雨\\\"\n"]:texts.append("x".repeat(length)+value+"tail")
	var exact: bool=true
	for text: String in texts:
		var bytes: PackedByteArray=text.to_utf8_buffer();var before: PackedByteArray=bytes.duplicate()
		var expected: PackedByteArray=ColonySnapshotEnvelope.wrap(world,text,"literal \"payload\":\"\" ☀\\",123456789012345,timestamp)
		var actual: PackedByteArray=ColonySnapshotEnvelope.wrap_bytes(world,bytes,"literal \"payload\":\"\" ☀\\",123456789012345,timestamp)
		exact=exact and actual==expected and bytes==before and ColonySnapshotEnvelope.hash_payload(bytes)==text.sha256_text()
	check.call("SAVE/byte_payload_envelope_keeps_native_unicode_escaping_and_multibyte_boundaries",exact)
	var oversized: PackedByteArray=PackedByteArray();oversized.resize(ColonyCodec.MAX_BYTES+1)
	var rejected_input: bool=ColonySnapshotEnvelope.wrap_bytes(world,oversized).is_empty()
	oversized.resize(ColonyCodec.MAX_BYTES);oversized.fill(120)
	check.call("SAVE/byte_envelope_rejects_oversized_input_and_actual_output_at_original_cap",rejected_input and ColonySnapshotEnvelope.wrap_bytes(world,oversized).is_empty())
	oversized=PackedByteArray()
	var captured: Dictionary=ColonyCapture.new().capture(world,[]);var candidate: Dictionary=ColonyPreparedSnapshot.prepare(captured,world.definitions);var baseline: Dictionary=original(captured,world.definitions)
	check.call("SAVE/byte_preparation_retains_exact_utf8_payload_capture_digest_and_legacy_text_view",candidate.has("snapshot") and baseline.has("snapshot") and candidate.snapshot.encoded_payload==baseline.snapshot.text.to_utf8_buffer() and candidate.snapshot.text==baseline.snapshot.text and candidate.snapshot.digest==baseline.snapshot.digest and candidate.snapshot.matches(world) and is_same(candidate.snapshot.payload,captured))
	var damaged: ColonyPreparedSnapshot=ColonyPreparedSnapshot.prepare(captured,world.definitions).snapshot
	var bytes: PackedByteArray=damaged.encoded_payload.duplicate();bytes[0]=91;damaged.encoded_payload=bytes
	check.call("SAVE/byte_prepared_snapshot_rechecks_actual_byte_digest_before_publication",not damaged.matches(world))
	damaged=ColonyPreparedSnapshot.prepare(captured,world.definitions).snapshot;damaged.text+=" "
	check.call("SAVE/legacy_text_setter_tampering_still_invalidates_byte_prepared_snapshot",not damaged.matches(world) and damaged.encoded_payload[-1]==32)
	var paths: Array[String]=[];collect("res://tests/fixtures",paths)
	exact=true
	for path in paths:
		var input_sha: String=FileAccess.get_sha256(path);var loaded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(path))
		if not loaded.has("world"):exact=false;continue
		var saved: ColonyWorld=loaded.world;var hash_before: String=saved.canonical_hash();var capture: Dictionary=ColonyCapture.new().capture(saved,[])
		baseline=original(capture,saved.definitions);candidate=ColonyPreparedSnapshot.prepare(capture,saved.definitions)
		if not baseline.has("snapshot") or not candidate.has("snapshot"):exact=false;continue
		var expected: PackedByteArray=ColonySnapshotEnvelope.wrap(saved,baseline.snapshot.text,"bytes fixture",42,timestamp)
		var actual: PackedByteArray=ColonySnapshotEnvelope.wrap_bytes(saved,candidate.snapshot.encoded_payload,"bytes fixture",42,timestamp)
		var decoded: Dictionary=ColonyCodec.decode(actual)
		exact=exact and actual==expected and candidate.snapshot.encoded_payload==baseline.snapshot.text.to_utf8_buffer() and candidate.snapshot.digest==hash_before and is_same(candidate.snapshot.payload,capture) and candidate.snapshot.matches(saved) and decoded.has("world") and decoded.world.canonical_hash()==hash_before and saved.canonical_hash()==hash_before and FileAccess.get_sha256(path)==input_sha
	check.call("SAVE/byte_preparation_and_normal_envelope_match_all_47_recursive_immutable_fixtures",exact and paths.size()==47)

static func collect(folder: String, paths: Array[String]) -> void:
	for name in DirAccess.get_files_at(folder):
		if name.ends_with(".brackenward"):paths.append(folder.path_join(name))
	for directory in DirAccess.get_directories_at(folder):collect(folder.path_join(directory),paths)
