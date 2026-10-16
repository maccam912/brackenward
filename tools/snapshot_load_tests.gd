class_name SnapshotLoadTests
extends RefCounted
## Complete 487bb1d decode body; only method name and class-qualified calls differ.
const FORMAT: String=ColonyCodec.FORMAT
const MAX_BYTES: int=ColonyCodec.MAX_BYTES
const VERSION: int=ColonyCodec.VERSION

static func original(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty() or bytes.size() > MAX_BYTES:
		return {"error": "Colony snapshot is empty or exceeds 64 MiB"}
	var parser: JSON = JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {"error": "Malformed colony snapshot"}
	var envelope: Dictionary = parser.data
	if (envelope.get("version") == 1 or envelope.get("version") == 2):
		var legacy: Dictionary = M2Codec.decode(bytes)
		if legacy.has("error"): return legacy
		return ColonyCodec.restore(ColonyMigrations.from_m2(legacy.world.payload(),ColonyCatalog.load_data().content_hash,ColonyCatalog.load_data().items.keys()),legacy.get("snapshot_name",""),true)
	var keys: Array = ["format","version","content","content_hash","snapshot_name","engine","generator_version","campaign_id","sequence","timestamp","payload","sha256"]
	if not ColonyCodec._keys(envelope,keys) or envelope.format != FORMAT or (envelope.version!=3 and envelope.version!=4 and envelope.version!=VERSION) or (envelope.content != ColonyWorld.CONTENT_VERSION and envelope.content not in ["colony-v1","colony-v2","colony-v3","colony-v4","colony-v5","colony-v6","colony-v7"] and not (envelope.version == 3 and envelope.content == "m3-people-seasons-1")):
		return {"error":"Unsupported save version %s / content %s. This build supports envelope 5, content %s and earlier colony migration. Original files retained." % [str(envelope.get("version","?")).left(16),str(envelope.get("content","?")).left(64),ColonyWorld.CONTENT_VERSION]}
	if envelope.generator_version is float and envelope.generator_version==floor(envelope.generator_version) and envelope.generator_version>ColonyGeneration.VERSION:
		return {"error":"Campaign uses generator version %d; this build supports up to %d. Update Brackenward to open it. Original files retained." % [int(envelope.generator_version),ColonyGeneration.VERSION]}
	if not envelope.generator_version is float or (envelope.generator_version != 0 and envelope.generator_version != 1 and envelope.generator_version != 2) or not envelope.campaign_id is String or not envelope.sequence is String or not envelope.sequence.is_valid_int() or envelope.sequence.length() > 15 or envelope.sequence.begins_with("-") or not envelope.timestamp is String or envelope.timestamp.length() > 40:
		return {"error":"Invalid snapshot metadata"}
	if not envelope.payload is String or not envelope.sha256 is String or envelope.payload.sha256_text() != envelope.sha256:
		return {"error": "Snapshot checksum mismatch"}
	if not envelope.get("snapshot_name","") is String or envelope.get("snapshot_name","").length() > 64:
		return {"error":"Invalid snapshot name"}
	if parser.parse(envelope.payload) != OK:
		return {"error": "Malformed simulation payload"}
	var decoded: Variant = ColonyState.unpack(parser.data)
	if not decoded is Dictionary:
		return {"error": "Invalid integer, coordinate or state encoding"}
	var data: Dictionary = decoded
	if envelope.content_hash != data.get("content_hash") or data.get("session_id") != envelope.campaign_id or data.get("generator_version") != int(envelope.generator_version):
		return {"error":"Catalog or campaign identity mismatch; original save retained"}
	return ColonyCodec.restore(data,envelope.get("snapshot_name",""))

static func equivalent(bytes: PackedByteArray) -> bool:
	var before: PackedByteArray=bytes.duplicate()
	var baseline: Dictionary=original(bytes);var current: Dictionary=ColonyCodec.decode(bytes)
	if bytes!=before:return false
	if baseline.has("error"):return current==baseline
	return current.has("world") and current.world.payload()==baseline.world.payload() and current.get("snapshot_name","")==baseline.get("snapshot_name","")

static func run(check: Callable) -> void:
	var paths: Array[String]=[];SnapshotByteTests.collect("res://tests/fixtures",paths)
	var exact: bool=true
	for path in paths:
		var sha: String=FileAccess.get_sha256(path)
		exact=exact and equivalent(FileAccess.get_file_as_bytes(path)) and FileAccess.get_sha256(path)==sha
	check.call("SAVE/owned_external_decode_matches_complete_487bb1d_for_43_immutable_fixtures",exact and paths.size()==43)
	var world: ColonyWorld=ColonyTests.world();world.citizens[0].name="Sun ☀ 雨😀 \"quoted\" \\ {id}"
	var bytes: PackedByteArray=ColonyCodec.encode(world,"Saved ☀ 雨😀 \\ \"quoted\"",42)
	check.call("SAVE/owned_external_decode_keeps_unicode_names_snapshot_metadata_and_complete_state",equivalent(bytes))
	var envelope: Dictionary=JSON.parse_string(bytes.get_string_from_utf8())
	var cases: Array=[PackedByteArray(),"[]".to_utf8_buffer(),"{}".to_utf8_buffer()]
	for field in ["format","version","content","content_hash","snapshot_name","engine","generator_version","campaign_id","sequence","timestamp","payload","sha256"]:
		var missing: Dictionary=envelope.duplicate(true);missing.erase(field);cases.append(JSON.stringify(missing).to_utf8_buffer())
	for pair in [["format","other"],["version",6],["content","colony-v99"],["content_hash","0".repeat(64)],["generator_version",3],["generator_version",1.5],["campaign_id","other"],["sequence","-1"],["sequence","1234567890123456"],["timestamp",1],["timestamp","x".repeat(41)],["snapshot_name","x".repeat(65)],["payload",[]],["sha256","0".repeat(64)]]:
		var changed: Dictionary=envelope.duplicate(true);changed[pair[0]]=pair[1];cases.append(JSON.stringify(changed).to_utf8_buffer())
	exact=true
	for value: PackedByteArray in cases:exact=exact and equivalent(value) and ColonyCodec.decode(value).has("error")
	check.call("SAVE/owned_external_decode_preserves_envelope_identity_checksum_bounds_and_rejection_messages",exact and cases.size()==29)
	var invalid_payloads: Array=["null","[]","1","{",'{"tick":"01"}']
	for mutation in ["id","coordinate","map","depth","null","health","reference"]:
		var packed: Dictionary=ColonyState.pack(world.payload())
		match mutation:
			"id":packed.citizens[0].id="01"
			"coordinate":packed.citizens[0].route=[{"$tile":[128,0]}]
			"map":packed.citizens[0].route=[{"$map":[["1",true],["1",false]]}]
			"depth":
				var nested: Variant=true
				for index in range(34):nested=[nested]
				packed["extra"]=nested
			"null":packed.citizens[0].name=null
			"health":packed.citizens[0].health=101
			"reference":packed.citizens[0].bed="99999999"
		invalid_payloads.append(JSON.stringify(packed))
	exact=true
	for text: String in invalid_payloads:
		var changed: Dictionary=envelope.duplicate(true);changed.payload=text;changed.sha256=text.sha256_text()
		var input: PackedByteArray=JSON.stringify(changed).to_utf8_buffer()
		exact=exact and equivalent(input) and ColonyCodec.decode(input).has("error")
	check.call("SAVE/owned_external_decode_keeps_full_payload_encoding_schema_and_reference_validation",exact and invalid_payloads.size()==12)
	var capture: Dictionary=ColonyCapture.new().capture(world,[]);var before: Dictionary=capture.duplicate(true)
	var restored: Dictionary=ColonyCodec.restore(capture)
	check.call("SAVE/ordinary_restore_does_not_consume_shared_or_read_only_capture",restored.has("world") and capture==before and capture.is_read_only() and restored.world.payload()==capture)
