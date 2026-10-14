class_name Content4Migration
extends RefCounted
const MANIFEST: String="res://tests/fixtures/content4-preservation.json"
static func audit() -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not parsed is Dictionary or parsed.get("source_commit")!="fdadd7b1762843351a0dd02c0367049359f7cf1f" or not parsed.get("snapshots") is Array or parsed.snapshots.size()!=5:
		return {"passed":false,"error":"Missing reviewed v4 acknowledgement manifest","rows":[]}
	var rows: Array=[];var seen: Dictionary={};var passed: bool=true
	for entry in parsed.snapshots:
		var row: Dictionary=Content3Migration.snapshot(entry)
		passed=passed and not seen.has(entry.file) and row.get("passed",false) and row.get("source_content")=="colony-v4" and row.get("source_schema")==23
		seen[entry.file]=true;rows.append(row)
	var evidence: Array=[]
	for name in parsed.delta:
		var digest: String=FileAccess.get_sha256("res://tests/fixtures/"+name)
		evidence.append({"file":name,"sha256":digest,"expected":parsed.delta[name],"passed":digest==parsed.delta[name]})
	var producer_digest: String=FileAccess.get_sha256("res://tools/record_content4_sleep_fixture.gd")
	evidence.append({"file":"tools/record_content4_sleep_fixture.gd","sha256":producer_digest,"expected":parsed.producer_sha256,"passed":producer_digest==parsed.producer_sha256})
	passed=passed and evidence.all(func(row:Dictionary)->bool:return row.passed)
	return {"passed":passed,"source_commit":parsed.source_commit,"target_content":ColonyWorld.CONTENT_VERSION,"target_catalog_hash":ColonyCatalog.load_data().content_hash,"target_schema":ColonyWorld.SCHEMA_REVISION,"scope":"Five frozen v4 acknowledgements load without advancing time; only content headers normalize. All fields, source bytes, producer and round trips remain exact. Future sleep eligibility changes independently.","rows":rows,"evidence":evidence}
