class_name Content6Migration
extends RefCounted
const MANIFEST: String="res://tests/fixtures/content6/preservation.json"
const SOURCE: String="e4003fb1eb532f76b2d747975075244f09a221d4"

static func audit() -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not parsed is Dictionary or parsed.get("source_commit")!=SOURCE or parsed.get("content")!="colony-v6" or parsed.get("schema")!=23 or not parsed.get("snapshots") is Array or parsed.snapshots.size()!=6:
		return {"passed":false,"error":"Missing frozen v6 acknowledgement manifest","rows":[]}
	var rows: Array=[];var seen: Dictionary={};var passed: bool=parsed.catalog_hash==ColonyCatalog.load_data("res://data/catalogs/colony_v6.json").content_hash
	for entry in parsed.snapshots:
		var row: Dictionary=Content3Migration.snapshot(entry)
		passed=passed and not seen.has(entry.file) and row.get("passed",false) and row.get("source_content")=="colony-v6" and row.get("source_schema")==23
		seen[entry.file]=true;rows.append(row)
	var evidence: Array=[]
	for name in parsed.delta:
		var digest: String=FileAccess.get_sha256("res://tests/fixtures/"+name)
		evidence.append({"file":name,"sha256":digest,"expected":parsed.delta[name],"passed":digest==parsed.delta[name]})
	var producer_digest: String=FileAccess.get_sha256("res://tools/record_content6_defense_fixture.gd")
	evidence.append({"file":"tools/record_content6_defense_fixture.gd","sha256":producer_digest,"expected":parsed.producer_sha256,"passed":producer_digest==parsed.producer_sha256})
	var base_bytes: PackedByteArray=FileAccess.get_file_as_bytes("res://tests/fixtures/content6/delta-base.brackenward")
	var header: Dictionary=JSON.parse_string(base_bytes.get_string_from_utf8())
	var base: Dictionary=ColonyCodec.decode(base_bytes)
	var journal: Dictionary=ColonyJournal.read(FileAccess.get_file_as_bytes("res://tests/fixtures/content6/delta.frames"))
	var final: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/content6/delta-final.brackenward"))
	var recovered: Dictionary={}
	if base.has("world") and not journal.has("error") and not journal.get("torn_tail",false):recovered=ColonyJournal.replay(base.world,journal.records,header.sha256,journal.digests,ColonyJournal.snapshot_base(header))
	var exact_delta: bool=final.has("world") and recovered.has("world") and recovered.world.tick==2400 and recovered.world.canonical_hash()==final.world.canonical_hash()
	passed=passed and evidence.size()==4 and evidence.all(func(row:Dictionary)->bool:return row.passed) and exact_delta
	return {"passed":passed,"source_commit":SOURCE,"target_content":ColonyWorld.CONTENT_VERSION,"target_catalog_hash":ColonyCatalog.load_data().content_hash,"target_schema":ColonyWorld.SCHEMA_REVISION,"delta_fold_preserved":exact_delta,"scope":"Six frozen v6 acknowledgements and a 600-tick journal load without rerunning combat. Only content headers normalize; complete saved fields, source bytes, producer and round trips stay exact. Corrected self-defense applies to future ticks only.","rows":rows,"evidence":evidence}
