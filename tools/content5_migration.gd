class_name Content5Migration
extends RefCounted
const MANIFEST: String="res://tests/fixtures/content5-preservation.json"
static func audit() -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not parsed is Dictionary or parsed.get("source_commit")!="245f9359d8220ed17a94f544b7a79f85052c7d86" or not parsed.get("snapshots") is Array or parsed.snapshots.size()!=6:
		return {"passed":false,"error":"Missing reviewed v5 acknowledgement manifest","rows":[]}
	var rows: Array=[];var seen: Dictionary={};var passed: bool=true
	for entry in parsed.snapshots:
		var row: Dictionary=Content3Migration.snapshot(entry)
		passed=passed and not seen.has(entry.file) and row.get("passed",false) and row.get("source_content")=="colony-v5" and row.get("source_schema")==23
		seen[entry.file]=true;rows.append(row)
	var evidence: Array=[]
	for name in parsed.delta:
		var digest: String=FileAccess.get_sha256("res://tests/fixtures/"+name)
		evidence.append({"file":name,"sha256":digest,"expected":parsed.delta[name],"passed":digest==parsed.delta[name]})
	var producer_digest: String=FileAccess.get_sha256("res://tools/record_content5_sleep_fixture.gd")
	evidence.append({"file":"tools/record_content5_sleep_fixture.gd","sha256":producer_digest,"expected":parsed.producer_sha256,"passed":producer_digest==parsed.producer_sha256})
	passed=passed and evidence.all(func(row:Dictionary)->bool:return row.passed)
	return {"passed":passed,"source_commit":parsed.source_commit,"target_content":ColonyWorld.CONTENT_VERSION,"target_catalog_hash":ColonyCatalog.load_data().content_hash,"target_schema":ColonyWorld.SCHEMA_REVISION,"scope":"Six frozen v5 acknowledgements load without advancing time; only content headers normalize. All fields, source bytes, producer and round trips remain exact. Future rest rates and sleep thresholds change independently.","rows":rows,"evidence":evidence}
