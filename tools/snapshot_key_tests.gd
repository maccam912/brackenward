class_name SnapshotKeyTests
extends RefCounted
## Complete 357fa04 decode body and unchanged independent prior converter.
const FORMAT: String=ColonyCodec.FORMAT
const MAX_BYTES: int=ColonyCodec.MAX_BYTES
const VERSION: int=ColonyCodec.VERSION

# Accept the current released catalog versions; retain the reference parser body.
static func original(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty() or bytes.size() > MAX_BYTES:
		return {"error": "Colony snapshot is empty or exceeds 64 MiB"}
	var parser: JSON = JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {"error": "Malformed colony snapshot"}
	var envelope: Dictionary = parser.data
	if (envelope.get("version") == 1 or envelope.get("version") == 2):
		envelope={};parser=null
		var legacy: Dictionary = M2Codec.decode(bytes)
		if legacy.has("error"): return legacy
		return ColonyCodec.restore(ColonyMigrations.from_m2(legacy.world.payload(),ColonyCatalog.load_data().content_hash,ColonyCatalog.load_data().items.keys()),legacy.get("snapshot_name",""),true)
	var keys: Array = ["format","version","content","content_hash","snapshot_name","engine","generator_version","campaign_id","sequence","timestamp","payload","sha256"]
	if not ColonyCodec._keys(envelope,keys) or envelope.format != FORMAT or (envelope.version!=3 and envelope.version!=4 and envelope.version!=VERSION) or (envelope.content != ColonyWorld.CONTENT_VERSION and envelope.content not in ["colony-v1","colony-v2","colony-v3","colony-v4","colony-v5","colony-v6","colony-v7","colony-v8","colony-v9","colony-v10","colony-v11"] and not (envelope.version == 3 and envelope.content == "m3-people-seasons-1")):
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
	# Only this fresh parser owns the JSON containers. Release the checked text
	# before unpacking, then reuse those containers without a second full tree.
	# restore() still accepts ordinary callers' data without consuming it.
	envelope.erase("payload")
	var decoded: Variant = ColonyPreparedSnapshot._unpack_owned_json(parser.data)
	parser=null
	if not decoded is Dictionary:
		return {"error": "Invalid integer, coordinate or state encoding"}
	var data: Dictionary = decoded
	if envelope.content_hash != data.get("content_hash") or data.get("session_id") != envelope.campaign_id or data.get("generator_version") != int(envelope.generator_version):
		return {"error":"Catalog or campaign identity mismatch; original save retained"}
	var snapshot_name: String=envelope.get("snapshot_name","")
	envelope={};decoded=null
	return ColonyCodec._restore_owned_json(data,snapshot_name)

static func equivalent(bytes: PackedByteArray) -> bool:
	var before: PackedByteArray=bytes.duplicate();var prior: Dictionary=original(bytes);var current: Dictionary=ColonyCodec.decode(bytes)
	if bytes!=before:return false
	if prior.has("error"):return prior==current
	return current.has("world") and current.get("snapshot_name","")==prior.get("snapshot_name","") and current.world.payload()==prior.world.payload() and JSON.stringify(ColonyState.pack(current.world.payload()),"",false)==JSON.stringify(ColonyState.pack(prior.world.payload()),"",false)

static func run(check: Callable) -> void:
	var paths: Array[String]=[];SnapshotByteTests.collect("res://tests/fixtures",paths)
	var exact: bool=true
	for path: String in paths:
		var sha: String=FileAccess.get_sha256(path)
		exact=exact and equivalent(FileAccess.get_file_as_bytes(path)) and FileAccess.get_sha256(path)==sha
	check.call("SAVE/shared_string_keys_match_complete_357fa04_decoder_and_order_for_50_immutable_fixtures",exact and paths.size()==50)
	var cases: Array=[{},[],true,false,0,1.5,{"id":"7","name":"Sun ☀ 雨😀 {id}","route":[{"$tile":[127,0]}],"tail_ids":["1","2"]},{"id":"01"},{"id":"-1"},{"id":"1234567890123456"},{"$tile":[128,0]},{"$tile":[1,2],"extra":true},{"$map":[["1",{"id":"7"}],["2",["nested"]]]},{"$map":[["1",true],["1",false]]},{"$map":[["01",true]]},{"$map":[["1"]]},{"$map":false},{"name":null}]
	var nested: Variant=true
	for index in range(34):nested=[nested]
	cases.append(nested)
	var large: Dictionary={}
	for index in range(129):large["field_%d" % index]={"id":"7"}
	cases.append(large);exact=true
	for value: Variant in cases:
		var json: String=JSON.stringify(value)
		exact=exact and ColonyPreparedSnapshot._unpack_owned_json(JSON.parse_string(json))==ColonyOwnedJson.unpack(JSON.parse_string(json))
	var frozen: Dictionary={"id":"7"};frozen.make_read_only()
	var frozen_array: Array=[true];frozen_array.make_read_only()
	exact=exact and ColonyOwnedJson.unpack(frozen)==null and frozen.id=="7" and ColonyOwnedJson.unpack(frozen_array)==null
	check.call("SAVE/shared_key_conversion_preserves_integer_map_tile_unicode_depth_null_and_readonly_boundaries",exact and cases.size()==20)
	var records: Array=[]
	for index in range(5000):records.append({"record_key_%d" % index:index,"same":true})
	var original_order: String=JSON.stringify(ColonyState.pack(records),"",false)
	var owned: Array=JSON.parse_string(JSON.stringify(records));var first: Dictionary=owned[0];var pool: Dictionary={}
	var result: Variant=ColonyOwnedJson._unpack(owned,"",0,pool)
	check.call("SAVE/shared_key_pool_stays_bounded_and_retains_private_container_identity_types_and_insertion_order",is_same(result,owned) and is_same(first,result[0]) and pool.size()==ColonyOwnedJson.MAX_KEYS and pool.keys().all(func(key:Variant)->bool:return key is String) and JSON.stringify(ColonyState.pack(result),"",false)==original_order)
	var bytes: PackedByteArray=ColonyCodec.encode(ColonyTests.world());var prior: ColonyWorld=original(bytes).world;var current: ColonyWorld=ColonyCodec.decode(bytes).world
	for tick in range(720):prior.step();current.step()
	check.call("SAVE/shared_key_loaded_world_keeps_complete_future_ticks_and_roundtrip",current.payload()==prior.payload() and current.invariant_errors().is_empty() and ColonyCodec.decode(ColonyCodec.encode(current)).world.payload()==current.payload())
