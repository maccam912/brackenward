class_name Content3Migration
extends RefCounted
## Loading acknowledgements is separate from replaying future corrected rules.
const MANIFEST: String = "res://tests/fixtures/content3-preservation.json"

static func snapshot(entry: Dictionary) -> Dictionary:
	var path: String = "res://tests/fixtures/"+entry.file
	var original_digest: String = FileAccess.get_sha256(path)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var envelope: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	var decoded: Dictionary = ColonyCodec.decode(bytes)
	var row: Dictionary = {"file":entry.file,"input_sha256":original_digest,"passed":false}
	if not envelope is Dictionary or not decoded.has("world"):
		row["error"]=decoded.get("error","Invalid source envelope");return row
	var original: Dictionary = ColonyState.unpack(JSON.parse_string(envelope.payload))
	var world: ColonyWorld = decoded.world
	var preserved: Dictionary = SchemaCompatibility.normalize(world,original)
	var preserved_hash: String = JSON.stringify(ColonyState.pack(preserved),"",true).sha256_text()
	var current_hash: String = world.canonical_hash()
	var roundtrip: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	row.merge({"source_content":original.content,"source_schema":original.schema_revision,"tick":world.tick,"preserved_gameplay_hash":preserved_hash,"current_hash":current_hash,"invariants":world.invariant_errors()})
	row.passed=original_digest==entry.sha256 and envelope.sha256==entry.canonical_hash and preserved_hash==entry.canonical_hash and row.invariants.is_empty() and roundtrip.has("world") and roundtrip.world.canonical_hash()==current_hash and FileAccess.get_sha256(path)==original_digest
	return row

static func audit() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not parsed is Dictionary or not parsed.get("snapshots") is Array or parsed.snapshots.size()!=5:
		return {"passed":false,"error":"Missing reviewed v3 migration manifest","rows":[]}
	var rows: Array = [];var passed: bool = true
	for entry in parsed.snapshots:
		var row: Dictionary = snapshot(entry)
		rows.append(row);passed=passed and row.passed
	var golden: Dictionary = ColonyState.unpack(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/schema22-replay-golden.json")))
	var path: String = "res://tests/fixtures/campaign-replay-7200.brackenward"
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var foreign: Dictionary = snapshot({"file":path.get_file(),"sha256":golden.save_fixture_sha256,"canonical_hash":envelope.sha256})
	rows.append(foreign);passed=passed and foreign.passed
	return {"passed":passed,"source_commit":parsed.source_commit,"target_content":ColonyWorld.CONTENT_VERSION,"target_catalog_hash":ColonyCatalog.load_data().content_hash,"target_schema":ColonyWorld.SCHEMA_REVISION,"scope":"Frozen acknowledgements load without advancing time; only declared content/schema headers and older additive metadata are normalized for exact field comparison. Future scheduling uses the corrected v4 rules. Source bytes and full current round trips are verified.","rows":rows}
