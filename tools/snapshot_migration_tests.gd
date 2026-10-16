class_name SnapshotMigrationTests
extends RefCounted
## Complete fd29cfe decode body; restore keeps its original copy semantics.
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
		envelope={};parser=null
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
	return ColonyCodec.restore(data,snapshot_name)

static func equivalent(bytes: PackedByteArray) -> bool:
	var before: PackedByteArray=bytes.duplicate();var old: Dictionary=original(bytes);var current: Dictionary=ColonyCodec.decode(bytes)
	if bytes!=before:return false
	if old.has("error"):return old==current
	return current.has("world") and current.world.payload()==old.world.payload() and current.get("snapshot_name","")==old.get("snapshot_name","")

static func run(check: Callable) -> void:
	var paths: Array[String]=[];SnapshotByteTests.collect("res://tests/fixtures",paths)
	var exact: bool=true
	for path: String in paths:
		var sha: String=FileAccess.get_sha256(path)
		exact=exact and equivalent(FileAccess.get_file_as_bytes(path)) and FileAccess.get_sha256(path)==sha
	check.call("SAVE/owned_header_migration_matches_complete_fd29cfe_decode_for_43_immutable_fixtures",exact and paths.size()==43)
	var world: ColonyWorld=ColonyTests.world();var previous: Dictionary=world.payload().duplicate(true)
	previous.content="colony-v6";previous.content_hash=ColonyCatalog.load_data("res://data/catalogs/colony_v6.json").content_hash
	var expected: Dictionary=previous.duplicate(true);ColonyCapture._freeze(previous)
	var restored: Dictionary=ColonyCodec.restore(previous)
	exact=restored.has("world") and previous==expected and previous.is_read_only()
	if restored.has("world"):
		var current: Dictionary=restored.world.payload().duplicate(true);current.content=previous.content;current.content_hash=previous.content_hash
		exact=exact and current==previous
		restored.world.step()
		exact=exact and previous==expected and restored.world.tick==previous.tick+1 and restored.world.invariant_errors().is_empty()
	check.call("SAVE/public_previous_content_restore_keeps_shared_capture_and_independent_future_state",exact)
	var bytes: PackedByteArray=ColonyCodec.encode(world,"Header migration ☀",42)
	var envelope: Dictionary=JSON.parse_string(bytes.get_string_from_utf8());var cases: Array=[]
	for problem in ["catalog","schema","reference","future_schema"]:
		var data: Dictionary=expected.duplicate(true)
		match problem:
			"catalog":data.content_hash="0".repeat(64)
			"schema":data.citizens[0].health=101
			"reference":data.citizens[0].bed=99999999
			"future_schema":data.schema_revision=ColonyWorld.SCHEMA_REVISION+1
		var changed: Dictionary=envelope.duplicate(true);changed.content=data.content;changed.content_hash=data.content_hash
		changed.payload=JSON.stringify(ColonyState.pack(data),"",true);changed.sha256=changed.payload.sha256_text()
		cases.append(JSON.stringify(changed).to_utf8_buffer())
	exact=true
	for input: PackedByteArray in cases:exact=exact and equivalent(input) and ColonyCodec.decode(input).has("error")
	check.call("SAVE/owned_header_migration_keeps_catalog_schema_reference_and_future_version_rejections",exact and cases.size()==4)
