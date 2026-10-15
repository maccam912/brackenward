class_name SnapshotEncodingTests
extends RefCounted
## Full-tree preparation retained from e8336e4; independent of the bounded encoder.

static func original(captured: Dictionary, catalog: Dictionary) -> Dictionary:
	if not captured.is_read_only():return {"error":"Snapshot preparation needs an owned immutable capture"}
	if captured.get("content_hash")!=catalog.get("content_hash"):return {"error":"Snapshot preparation catalog differs from immutable capture"}
	if not captured.get("session_id") is String or not captured.get("generator_version") is int:return {"error":"Invalid snapshot identity metadata"}
	var result: LegacyPreparedSnapshot=LegacyPreparedSnapshot.new()
	result.payload=captured;result.text=JSON.stringify(ColonyState.pack(captured),"",true);result.digest=result.text.sha256_text()
	# Check the exact normal envelope bound, then release its temporary escaped
	# text/bytes before parsing the payload. Nothing external supplied this header.
	var identity: ColonyWorld=ColonyWorld.new(catalog)
	identity.session_id=captured.session_id;identity.generator_version=captured.generator_version
	var bytes: PackedByteArray=ColonyCodec.wrap_payload(identity,result.text)
	if bytes.is_empty() or bytes.size()>ColonyCodec.MAX_BYTES:return {"error":"Colony snapshot is empty or exceeds 64 MiB"}
	bytes=PackedByteArray();identity=null
	var parser: JSON=JSON.new()
	if parser.parse(result.text)!=OK:return {"error":"Malformed simulation payload"}
	var data: Variant=ColonyPreparedSnapshot._unpack_owned_json(parser.data)
	parser=null
	if not data is Dictionary:return {"error":"Invalid integer, coordinate or state encoding"}
	var verified: Dictionary=ColonyCodec.restore(data)
	if not verified.has("world") or verified.world.payload()!=captured:return {"error":"Snapshot preparation failed full validation: "+str(verified.get("error","state mismatch"))}
	result.validated=true
	return {"snapshot":result}

static func run(check: Callable) -> void:
	for count in [0,1,255,256,257,511,512,513]:
		var source: Dictionary={"id":123,"empty":[],"receipts":{1:"accepted",2:[]},"rows":[]}
		for index in range(count):source.rows.append({"id":index+1,"name":"literal {id} \"quoted\" \\ text\nSun ☀ 雨","tile":Vector2i(index%128,(index/128)%128),"flags":[true,false],"amount":index})
		var expected: String=JSON.stringify(ColonyState.pack(source),"",true)
		var encoded: Dictionary=ColonySnapshotEncoding.encode(source)
		var decoded: Dictionary=ColonySnapshotEncoding.decode_owned(encoded.bytes,encoded.fields)
		check.call("SAVE/bounded_payload_exact_at_array_boundary_%d" % count,encoded.bytes.get_string_from_utf8()==expected and decoded.has("data") and decoded.data==source and decoded.data==ColonyState.unpack(JSON.parse_string(expected)),str(decoded.get("error","")))
	var source: Dictionary={"rows":[]}
	for index in range(513):source.rows.append(index)
	var encoded: Dictionary=ColonySnapshotEncoding.encode(source)
	var bad: PackedByteArray=encoded.bytes.duplicate();bad[0]=91
	check.call("SAVE/bounded_payload_rejects_changed_root_byte",ColonySnapshotEncoding.decode_owned(bad,encoded.fields).has("error"))
	bad=encoded.bytes.duplicate();bad[encoded.fields[0].key_end]=44
	check.call("SAVE/bounded_payload_rejects_changed_key_colon",ColonySnapshotEncoding.decode_owned(bad,encoded.fields).has("error"))
	bad=encoded.bytes.duplicate();bad[encoded.fields[0].blocks[0][1]]=59
	check.call("SAVE/bounded_payload_rejects_changed_block_separator",ColonySnapshotEncoding.decode_owned(bad,encoded.fields).has("error"))
	bad=encoded.bytes.duplicate();bad.append(32)
	check.call("SAVE/bounded_payload_rejects_unconsumed_trailing_bytes",ColonySnapshotEncoding.decode_owned(bad,encoded.fields).has("error"))
	var fields: Array=encoded.fields.duplicate(true);fields[0].blocks.remove_at(1)
	check.call("SAVE/bounded_payload_rejects_skipped_middle_block",ColonySnapshotEncoding.decode_owned(encoded.bytes,fields).has("error"))
	fields=encoded.fields.duplicate(true);fields[0].key="different"
	check.call("SAVE/bounded_payload_rejects_relabelled_serialized_key",ColonySnapshotEncoding.decode_owned(encoded.bytes,fields).has("error"))
	fields=encoded.fields.duplicate(true);fields.append(fields[0])
	check.call("SAVE/bounded_payload_rejects_duplicate_or_extra_fields",ColonySnapshotEncoding.decode_owned(encoded.bytes,fields).has("error"))
	check.call("SAVE/bounded_payload_rejects_non_string_root_key",ColonySnapshotEncoding.encode({1:"bad"}).has("error"))
	var exact: bool=true;var nested: Variant="leaf"
	for depth in range(35):
		nested=[nested];source={"rows":nested}
		var expected: Variant=ColonyState.unpack(JSON.parse_string(JSON.stringify(ColonyState.pack(source),"",true)))
		encoded=ColonySnapshotEncoding.encode(source);var decoded: Dictionary=ColonySnapshotEncoding.decode_owned(encoded.bytes,encoded.fields)
		exact=exact and ((expected==null and decoded.has("error")) or (decoded.has("data") and decoded.data==expected))
	check.call("SAVE/bounded_payload_keeps_original_complete_root_depth_limit",exact)
	exact=true
	for value in [null,1.5,9007199254740992.0,{"id":"01"},{"id":"-1"},{"id":"1234567890123456"},{"$tile":[-1,0]},{"$tile":[128,0]},{"$tile":[0,0],"extra":1},{"$map":[["1",true],["1",false]]}]:
		source={"rows":[value]};encoded=ColonySnapshotEncoding.encode(source)
		exact=exact and ColonySnapshotEncoding.decode_owned(encoded.bytes,encoded.fields).has("error")
	check.call("SAVE/bounded_payload_preserves_invalid_integer_map_tile_rejection",exact)
	source={"rows":[{"id":42,"name":"unchanged"}]};ColonyCapture._freeze(source)
	encoded=ColonySnapshotEncoding.encode(source);var decoded: Dictionary=ColonySnapshotEncoding.decode_owned(encoded.bytes,encoded.fields)
	decoded.data.rows[0].name="private change"
	check.call("SAVE/bounded_decode_owns_mutable_records_without_capture_alias",source.rows[0].name=="unchanged" and source.is_read_only() and not decoded.data.is_read_only() and not is_same(source.rows,decoded.data.rows))
	var stress: Dictionary=StressFixture.make(true)
	if not stress.has("world"):check.call("SAVE/bounded_stress_setup",false,str(stress));return
	var generated: ColonyWorld=ColonyTests.world();var generation_error: String=ColonyGeneration.configure(generated,104729,"pine_shelf")
	if not generation_error.is_empty():check.call("SAVE/bounded_generated_setup",false,generation_error);return
	for world in [ColonyTests.world(),stress.world,generated]:
		var before: String=world.canonical_hash();var captured: Dictionary=ColonyCapture.new().capture(world,[])
		var baseline: Dictionary=original(captured,world.definitions);var candidate: Dictionary=ColonySnapshotEncoding.prepare(captured,world.definitions)
		check.call("SAVE/bounded_full_prepare_keeps_exact_validated_payload_%d_people_gen%d" % [world.citizens.size(),world.generator_version],baseline.has("snapshot") and candidate.has("snapshot") and candidate.snapshot.text==baseline.snapshot.text and candidate.snapshot.digest==before and candidate.snapshot.matches(world) and is_same(candidate.snapshot.payload,captured),str(candidate.get("error","")))
		if not candidate.has("snapshot"):continue
		var restored: Dictionary=ColonyCodec.decode(ColonyCodec.wrap_payload(world,candidate.snapshot.text))
		check.call("SAVE/bounded_output_passes_unchanged_full_external_codec_%d_people_gen%d" % [world.citizens.size(),world.generator_version],restored.has("world") and restored.world.canonical_hash()==before and world.canonical_hash()==before,str(restored.get("error","")))
	var world: ColonyWorld=ColonyTests.world();var capture: Dictionary=ColonyCapture.new().capture(world,[])
	check.call("SAVE/bounded_preparation_rejects_mutable_live_payload",ColonySnapshotEncoding.prepare(world.payload(),world.definitions).has("error"))
	exact=true
	for field in ["rest","ledger","header","generator"]:
		var invalid: Dictionary=capture.duplicate(true)
		if field=="rest":invalid.citizens[0].rest=-1
		elif field=="ledger":invalid.ledger.consumed.wood=999
		elif field=="header":invalid.unlisted_field=1
		else:invalid.generator_version=3
		ColonyCapture._freeze(invalid)
		exact=exact and original(invalid,world.definitions).has("error") and ColonySnapshotEncoding.prepare(invalid,world.definitions).has("error")
	check.call("SAVE/bounded_preparation_keeps_full_schema_conservation_and_version_rejection",exact)
