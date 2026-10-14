extends SceneTree
## Verify a frozen schema-21 campaign matrix without advancing or rewriting it.
var directory: String = ""
var report_path: String = ""
var allow_deferral: bool = false

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() not in [4,6] or args[0]!="--directory" or args[2]!="--report":
		printerr("Usage: -- --directory FROZEN_REPORT_DIRECTORY --report OUTPUT_JSON [--allow-work-deferral true]");quit(2);return
	if args.size()==6:
		if args[4]!="--allow-work-deferral" or args[5]!="true": quit(2);return
		allow_deferral=true
	directory=args[1];report_path=args[3]
	call_deferred("run")

func run() -> void:
	var audit: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("audit.json")))
	if not audit is Dictionary or audit.get("passed")!=30 or not audit.get("complete_matrix",false):
		printerr("A completed, independently audited thirty-run matrix is required");quit(2);return
	var rows: Array = []
	var passed: bool = true
	for entry in audit.rows:
		var name: String = "%s-%d-final.brackenward" % [entry.site,entry.seed]
		var path: String = directory.path_join(name)
		var original_digest: String = FileAccess.get_sha256(path)
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		var envelope: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		var decoded: Dictionary = ColonyCodec.decode(bytes)
		var row: Dictionary = {"file":name,"source_commit":audit.commit,"input_sha256":original_digest,"source_canonical_hash":entry.canonical_hash,"passed":false}
		if decoded.has("world") and envelope is Dictionary and envelope.get("sha256")==entry.canonical_hash:
			var old: Dictionary = ColonyState.unpack(JSON.parse_string(envelope.payload))
			var world: ColonyWorld = decoded.world
			var normalized: Dictionary = SchemaCompatibility.normalize(world,old,allow_deferral)
			var canonical: String = world.canonical_hash()
			var roundtrip: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
			row["current_canonical_hash"]=canonical
			var preserved: String = JSON.stringify(ColonyState.pack(normalized),"",true).sha256_text()
			row["preserved_intent_hash" if allow_deferral else "preserved_gameplay_hash"]=preserved
			row["queued_orders"]=world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.state=="Queued").size()
			row["execution_state_preserved"]=row.queued_orders==0
			row["passed"]=old.schema_revision==21 and preserved==entry.canonical_hash and roundtrip.has("world") and roundtrip.world.canonical_hash()==canonical and FileAccess.get_sha256(path)==original_digest
		else: row["error"]=decoded.get("error","source checksum evidence mismatch")
		passed=passed and row.passed;rows.append(row)
		print("UPGRADE %d/30 %s %s" % [rows.size(),name,"PASS" if row.passed else "FAIL"])
	var result: Dictionary = {"scope":"Schema-21 late Winter saves preserve every acknowledged gameplay field under their original header, removing only declared appearance and empty queue metadata; any actual deferral fails preservation; no time advances or source writes","source_commit":audit.commit,"target_schema":ColonyWorld.SCHEMA_REVISION,"passed":passed and rows.size()==30,"rows":rows}
	result["declared_work_deferral_allowed"]=allow_deferral
	result["unchanged_execution_states"]=rows.filter(func(row:Dictionary)->bool:return row.get("execution_state_preserved",false)).size()
	if allow_deferral: result.scope="Schema-21 late Winter saves preserve every original order, quantity, ownership, progress and history field after reconstructing only explicitly reported capacity deferral; this is an intent-preserving upgrade audit, not unchanged execution or a new-content Winter survival pass"
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file: FileAccess = FileAccess.open(report_path,FileAccess.WRITE)
	if file==null: printerr("Unable to write upgrade matrix evidence");quit(2);return
	file.store_string(JSON.stringify(result,"\t",true));file.close()
	quit(0 if result.passed else 1)
