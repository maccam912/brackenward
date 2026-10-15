class_name SnapshotCaptureTests
extends RefCounted
## Independent complete decoded-tree reference retained from 6685958.

static func original(captured: Dictionary, catalog: Dictionary) -> Dictionary:
	if not captured.is_read_only():return {"error":"Snapshot preparation needs an owned immutable capture"}
	if captured.get("content_hash")!=catalog.get("content_hash"):return {"error":"Snapshot preparation catalog differs from immutable capture"}
	if not captured.get("session_id") is String or not captured.get("generator_version") is int:return {"error":"Invalid snapshot identity metadata"}
	var encoded: Dictionary=ColonySnapshotEncoding.encode(captured)
	if encoded.has("error"):return encoded
	var decoded: Dictionary=original_decode(encoded.bytes,encoded.fields)
	if decoded.has("error"):return decoded
	var verified: Dictionary=ColonyCodec.restore(decoded.data)
	if not verified.has("world") or verified.world.payload()!=captured:return {"error":"Snapshot preparation failed full validation: "+str(verified.get("error","state mismatch"))}
	# Release the complete private validation tree before materializing the full
	# UTF-32 payload/envelope. Each serialized component and punctuation byte
	# has already been read from the actual encoded buffer and checked above.
	verified={};decoded={};encoded.fields=[]
	var result: LegacyPreparedSnapshot=LegacyPreparedSnapshot.new()
	result.payload=captured;result.text=encoded.bytes.get_string_from_utf8();encoded={}
	result.digest=result.text.sha256_text()
	var identity: ColonyWorld=ColonyWorld.new(catalog)
	identity.session_id=captured.session_id;identity.generator_version=captured.generator_version
	var bytes: PackedByteArray=ColonyCodec.wrap_payload(identity,result.text)
	if bytes.is_empty() or bytes.size()>ColonyCodec.MAX_BYTES:return {"error":"Colony snapshot is empty or exceeds 64 MiB"}
	result.validated=true
	return {"snapshot":result}

static func original_decode(bytes: PackedByteArray, fields: Array) -> Dictionary:
	if bytes.size()<2 or bytes.size()>ColonyCodec.MAX_BYTES or bytes[0]!=123:return {"error":"Invalid owned snapshot payload"}
	var data: Dictionary={};var cursor: int=1;var previous: String=""
	for field: Dictionary in fields:
		if not data.is_empty():
			if cursor>=bytes.size() or bytes[cursor]!=44:return {"error":"Missing snapshot field separator"}
			cursor+=1
		if field.key_start!=cursor or field.key_end<=cursor or field.key_end>=bytes.size():return {"error":"Snapshot field span differs"}
		var key_parser: JSON=JSON.new()
		if key_parser.parse(bytes.slice(cursor,field.key_end).get_string_from_utf8())!=OK or not key_parser.data is String:return {"error":"Invalid snapshot field name"}
		var key: String=key_parser.data;key_parser=null
		if key!=field.key or data.has(key) or (not data.is_empty() and key<=previous) or bytes[field.key_end]!=58:return {"error":"Snapshot key/order differs"}
		previous=key;cursor=field.key_end+1
		if field.array:
			if cursor>=bytes.size() or bytes[cursor]!=91:return {"error":"Snapshot array opener differs"}
			cursor+=1;data[key]=[]
		elif field.blocks.size()!=1:return {"error":"Snapshot scalar needs one complete value"}
		for index in range(field.blocks.size()):
			if index>0:
				if not field.array or cursor>=bytes.size() or bytes[cursor]!=44:return {"error":"Missing snapshot block separator"}
				cursor+=1
			var span: Array=field.blocks[index]
			if span.size()!=2 or span[0]!=cursor or span[1]<=cursor or span[1]>bytes.size():return {"error":"Snapshot value span differs"}
			var part: String=bytes.slice(cursor,span[1]).get_string_from_utf8()
			if field.array:part="["+part+"]"
			var parser: JSON=JSON.new()
			if parser.parse(part)!=OK:return {"error":"Malformed owned snapshot value"}
			part=""
			# Root fields start at depth one, matching whole-payload decoding.
			var value: Variant=ColonyPreparedSnapshot._unpack_owned_json(parser.data,key,1);parser=null
			if value==null or (field.array and not value is Array):return {"error":"Invalid integer, coordinate or state encoding"}
			if field.array:data[key].append_array(value)
			else:data[key]=value
			value=null;cursor=span[1]
		if field.array:
			if cursor>=bytes.size() or bytes[cursor]!=93:return {"error":"Snapshot array closer differs"}
			cursor+=1
	if cursor!=bytes.size()-1 or bytes[cursor]!=125:return {"error":"Snapshot trailing bytes differ"}
	return {"data":data}

static func run(check: Callable) -> void:
	for count in [0,1,255,256,257,511,512,513]:
		var source: Dictionary={"id":123,"empty":[],"receipts":{1:"accepted",2:[]},"rows":[]}
		for index in range(count):source.rows.append({"id":index+1,"name":"literal {id} \"quoted\" \\ text\nSun ☀ 雨","tile":Vector2i(index%128,(index/128)%128),"flags":[true,false],"amount":index})
		ColonyCapture._freeze(source)
		var legacy: Dictionary=ColonySnapshotEncoding.encode(source);var encoded: Dictionary=ColonySnapshotTree.encode(source)
		var decoded: Dictionary=original_decode(encoded.bytes,legacy.fields)
		check.call("SAVE/capture_tree_exact_at_array_boundary_%d" % count,encoded.bytes==legacy.bytes and encoded.bytes.get_string_from_utf8()==JSON.stringify(ColonyState.pack(source),"",true) and decoded.get("data")==source and ColonySnapshotTree.matches(encoded.bytes,encoded.tree,source).get("matched",false),str(encoded.get("error","")))
	var nested: Dictionary={"terrain_state":{"habitats":{"pine":[],"berry":[]},"empty":{}},"escaped \"☀\\\n":{"values":[Vector2i(3,4)]}}
	for index in range(1025):nested.terrain_state.habitats.pine.append(Vector2i(index%128,(index/128)%128))
	ColonyCapture._freeze(nested)
	var legacy: Dictionary=ColonySnapshotEncoding.encode(nested);var encoded: Dictionary=ColonySnapshotTree.encode(nested)
	var habitat: Dictionary=encoded.tree.fields[1].node.fields[1].node.fields[1].node
	check.call("SAVE/capture_tree_bounds_nested_habitat_arrays_and_preserves_exact_native_text",encoded.bytes==legacy.bytes and original_decode(encoded.bytes,legacy.fields).get("data")==nested and ColonySnapshotTree.matches(encoded.bytes,encoded.tree,nested).get("matched",false) and habitat.kind=="array" and habitat.blocks.size()==5)
	var source: Dictionary={"rows":[]}
	for index in range(513):source.rows.append(index)
	ColonyCapture._freeze(source);encoded=ColonySnapshotTree.encode(source);legacy=ColonySnapshotEncoding.encode(source)
	var bad: PackedByteArray=encoded.bytes.duplicate();bad[0]=91
	check.call("SAVE/capture_tree_rejects_changed_root_byte",ColonySnapshotTree.matches(bad,encoded.tree,source).has("error") and original_decode(bad,legacy.fields).has("error"))
	bad=encoded.bytes.duplicate();bad[encoded.tree.fields[0].key_end]=44
	check.call("SAVE/capture_tree_rejects_changed_key_colon",ColonySnapshotTree.matches(bad,encoded.tree,source).has("error") and original_decode(bad,legacy.fields).has("error"))
	bad=encoded.bytes.duplicate();bad[encoded.tree.fields[0].node.blocks[0][1]]=59
	check.call("SAVE/capture_tree_rejects_changed_block_separator",ColonySnapshotTree.matches(bad,encoded.tree,source).has("error") and original_decode(bad,legacy.fields).has("error"))
	bad=encoded.bytes.duplicate();bad.append(32)
	check.call("SAVE/capture_tree_rejects_unconsumed_trailing_bytes",ColonySnapshotTree.matches(bad,encoded.tree,source).has("error") and original_decode(bad,legacy.fields).has("error"))
	bad=encoded.bytes.duplicate();bad[encoded.tree.fields[0].node.blocks[0][0]]=57
	check.call("SAVE/capture_tree_rejects_valid_json_with_different_values",original_decode(bad,legacy.fields).has("data") and ColonySnapshotTree.matches(bad,encoded.tree,source).has("error"))
	var exact: bool=true
	for mutation in ["skip","rename","duplicate","kind","end"]:
		var tree: Dictionary=encoded.tree.duplicate(true)
		if mutation=="skip":tree.fields[0].node.blocks.remove_at(1)
		elif mutation=="rename":tree.fields[0].key="other"
		elif mutation=="duplicate":tree.fields.append(tree.fields[0])
		elif mutation=="kind":tree.fields[0].node.kind="atom"
		else:tree.fields[0].node.end-=1
		exact=exact and ColonySnapshotTree.matches(encoded.bytes,tree,source).has("error")
	check.call("SAVE/capture_tree_rejects_skipped_relabelled_duplicate_wrong_kind_and_span_metadata",exact)
	exact=true
	for target in [{"rows":[0]}, {"rows":[]}, {"rows":source.rows,"extra":true}, {}, {"rows":{}}]:
		ColonyCapture._freeze(target);exact=exact and ColonySnapshotTree.matches(encoded.bytes,encoded.tree,target).has("error")
	check.call("SAVE/capture_tree_requires_exact_array_count_field_coverage_and_types",exact)
	check.call("SAVE/capture_tree_rejects_mutable_expected_and_non_string_root_keys",ColonySnapshotTree.matches(encoded.bytes,encoded.tree,{"rows":source.rows}).has("error") and ColonySnapshotTree.encode({1:"bad"}).has("error"))
	grammar(check)
	exact=true;var deep: Variant="leaf"
	for depth in range(35):
		deep={"nested":deep};source={"value":deep};ColonyCapture._freeze(source)
		var unpacked: Variant=ColonyState.unpack(JSON.parse_string(JSON.stringify(ColonyState.pack(source),"",true)))
		encoded=ColonySnapshotTree.encode(source)
		var compared: Dictionary=encoded if encoded.has("error") else ColonySnapshotTree.matches(encoded.bytes,encoded.tree,source)
		exact=exact and ((unpacked==null and compared.has("error")) or (unpacked==source and compared.get("matched",false)))
	check.call("SAVE/capture_tree_preserves_complete_root_depth_limit",exact)
	exact=true
	for value in [null,1.5,9007199254740992.0,{"id":"01"},{"id":"-1"},{"id":"1234567890123456"},{"$tile":[-1,0]},{"$tile":[128,0]},{"$tile":[0,0],"extra":1},{"$map":[["1",true],["1",false]]},{"$tile":[1,2]},{"$map":[["1",true]]},[{"$tile":[1,2]}],[{"$map":[["1",true]]}]]:
		source={"value":value};ColonyCapture._freeze(source);encoded=ColonySnapshotTree.encode(source)
		exact=exact and ColonySnapshotTree.matches(encoded.bytes,encoded.tree,source).has("error")
	check.call("SAVE/capture_tree_preserves_invalid_values_and_tagged_dictionary_semantics",exact)
	validated_capture(check)
	immutable_corpus(check)
	envelopes(check)

static func envelopes(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();var timestamp: String="2026-10-15T06:00:00"
	var names: Array=["","literal \"payload\":\"\" ☀\\\n"]
	var values: Array=["","plain","\"\\/\b\f\n\r\t☀雨😀\u2028\u2029"]
	var controls: String=""
	for code in range(32):controls+=String.chr(code)
	values.append(controls)
	for count in [4095,4096,4097,8191,8192,8193]:values.append("x".repeat(count-1)+"😀")
	values.append(("\"\\☀\n/".repeat(1500)))
	var exact: bool=true
	for payload: String in values:
		for name: String in names:
			var reference: PackedByteArray=JSON.stringify({"format":ColonyCodec.FORMAT,"version":ColonyCodec.VERSION,"content":ColonyWorld.CONTENT_VERSION,"content_hash":world.definitions.content_hash,"snapshot_name":name,"engine":"4.7.2.ed1daf0bf","generator_version":world.generator_version,"campaign_id":world.session_id,"sequence":"123456789012345","timestamp":timestamp,"payload":payload,"sha256":payload.sha256_text()},"",true).to_utf8_buffer()
			var actual: PackedByteArray=ColonySnapshotEnvelope.wrap(world,payload,name,123456789012345,timestamp)
			exact=exact and actual==reference
	check.call("SAVE/capture_envelope_matches_native_json_controls_unicode_escaping_headers_and_boundaries",exact)
	# The private bounded wrapper rejects excessive output without returning a
	# truncated/oversized envelope; normal external decoding keeps the same cap.
	var huge: String="x".repeat(ColonyCodec.MAX_BYTES)
	check.call("SAVE/capture_envelope_rejects_output_above_unchanged_64_mib_cap",ColonySnapshotEnvelope.wrap(world,huge).is_empty())

static func grammar(check: Callable) -> void:
	# Independently build hostile private descriptors rather than using the writer.
	# An empty block must not hide a missing value in malformed whole JSON.
	var source: Dictionary={"rows":[1,2]};ColonyCapture._freeze(source)
	var exact: bool=true
	for raw in ["{\"rows\":[1, ,2]}","{\"rows\":[1,,2]}"]:
		var bytes: PackedByteArray=raw.to_utf8_buffer();var parser: JSON=JSON.new()
		var malformed: bool=parser.parse(raw)!=OK
		var blocks: Array=[[9,10],[11,12],[13,14]] if raw.contains(" ") else [[9,11],[12,13]]
		var tree: Dictionary={"kind":"dict","start":0,"end":bytes.size(),"fields":[{"key":"rows","key_start":1,"key_end":7,"node":{"kind":"array","start":8,"end":bytes.size()-1,"blocks":blocks}}]}
		exact=exact and malformed and ColonySnapshotTree.matches(bytes,tree,source).has("error")
	check.call("SAVE/capture_tree_rejects_empty_and_incomplete_value_blocks_in_malformed_json",exact)
	var oversized: Dictionary={"rows":[]}
	for index in range(257):oversized.rows.append(index)
	ColonyCapture._freeze(oversized);var encoded: Dictionary=ColonySnapshotTree.encode(oversized)
	encoded.tree.fields[0].node.blocks=[[encoded.tree.fields[0].node.blocks[0][0],encoded.tree.fields[0].node.blocks[1][1]]]
	check.call("SAVE/capture_tree_rejects_oversized_private_block_even_with_equal_values",ColonySnapshotTree.matches(encoded.bytes,encoded.tree,oversized).has("error"))

static func validated_capture(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();var captured: Dictionary=ColonyCapture.new().capture(world,[])
	var canonical: String=world.canonical_hash();var verified: Dictionary=ColonyCodec.restore(captured)
	check.call("SAVE/capture_tree_full_validation_reads_owned_capture_without_mutation",verified.has("world") and verified.world.payload()==captured and world.canonical_hash()==canonical and captured.is_read_only())
	verified={}
	var candidate: Dictionary=ColonyPreparedSnapshot.prepare(captured,world.definitions);var baseline: Dictionary=original(captured,world.definitions)
	check.call("SAVE/capture_tree_prepares_same_validated_text_digest_and_capture_identity",candidate.has("snapshot") and baseline.has("snapshot") and candidate.snapshot.text==baseline.snapshot.text and candidate.snapshot.digest==canonical and candidate.snapshot.matches(world) and is_same(candidate.snapshot.payload,captured),str(candidate.get("error","")))
	var exact: bool=true
	for field in ["rest","ledger","header","generator","reference","schema"]:
		var invalid: Dictionary=captured.duplicate(true)
		if field=="rest":invalid.citizens[0].rest=-1
		elif field=="ledger":invalid.ledger.consumed.wood=999
		elif field=="header":invalid.unlisted_field=1
		elif field=="generator":invalid.generator_version=3
		elif field=="reference":invalid.citizens[0].bed=999999
		else:invalid.schema_revision=22
		ColonyCapture._freeze(invalid)
		exact=exact and original(invalid,world.definitions).has("error") and ColonyPreparedSnapshot.prepare(invalid,world.definitions).has("error")
	check.call("SAVE/capture_tree_keeps_full_schema_reference_conservation_version_and_migration_rejection",exact)

static func immutable_corpus(check: Callable) -> void:
	var exact: bool=true;var count: int=0
	for name in DirAccess.get_files_at("res://tests/fixtures"):
		if not name.ends_with(".brackenward"):continue
		count+=1;var path: String="res://tests/fixtures/"+name;var sha: String=FileAccess.get_sha256(path)
		var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(path))
		if not decoded.has("world"):exact=false;continue
		var world: ColonyWorld=decoded.world;var before: String=world.canonical_hash();var captured: Dictionary=ColonyCapture.new().capture(world,[])
		var baseline: Dictionary=original(captured,world.definitions);var candidate: Dictionary=ColonyPreparedSnapshot.prepare(captured,world.definitions)
		if not candidate.has("snapshot") or not baseline.has("snapshot"):exact=false;continue
		var reference: PackedByteArray=ColonyCodec.wrap_payload(world,baseline.snapshot.text)
		var timestamp: String=JSON.parse_string(reference.get_string_from_utf8()).timestamp
		var bytes: PackedByteArray=ColonySnapshotEnvelope.wrap(world,candidate.snapshot.text,"",0,timestamp)
		var restored: Dictionary=ColonyCodec.decode(bytes)
		exact=exact and bytes==reference and restored.has("world") and restored.world.canonical_hash()==before and candidate.snapshot.text==baseline.snapshot.text and candidate.snapshot.digest==before and candidate.snapshot.validated and is_same(candidate.snapshot.payload,captured) and world.canonical_hash()==before and FileAccess.get_sha256(path)==sha
	check.call("SAVE/capture_tree_matches_32_immutable_save_states_and_unchanged_external_codec",exact and count==32)
