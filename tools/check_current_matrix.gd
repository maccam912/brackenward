extends SceneTree
## Read-only current-schema loading audit of independently verified Winter saves.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()!=4 or args[0]!="--directory" or args[2]!="--report":
		printerr("Usage: -- --directory AUDITED_MATRIX_DIRECTORY --report OUTPUT_JSON");quit(2);return
	var directory: String = args[1];var report_path: String = args[3]
	var audit: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("audit.json")))
	if not audit is Dictionary or audit.get("passed")!=30 or not audit.get("complete_matrix",false) or not audit.get("rows") is Array or audit.rows.size()!=30:
		printerr("An independently audited thirty-run matrix is required");quit(2);return
	var rows: Array = [];var seen: Dictionary = {};var passed: bool = true
	for entry in audit.rows:
		var name: String = "%s-%d-final.brackenward" % [entry.site,entry.seed]
		var path: String = directory.path_join(name)
		var original_digest: String = FileAccess.get_sha256(path)
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		var envelope: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		var decoded: Dictionary = ColonyCodec.decode(bytes)
		var row: Dictionary = {"file":name,"input_sha256":original_digest,"passed":false}
		if not seen.has(name) and decoded.has("world") and envelope is Dictionary and entry.get("audit_pass",false):
			var world: ColonyWorld = decoded.world
			var original: Dictionary = ColonyState.unpack(JSON.parse_string(envelope.payload))
			var canonical: String = world.canonical_hash()
			var preserved: String = JSON.stringify(ColonyState.pack(SchemaCompatibility.normalize(world,original)),"",true).sha256_text()
			var roundtrip: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
			row["canonical_hash"]=canonical;row["tick"]=world.tick
			row["preserved_gameplay_hash"]=preserved;row["source_content"]=original.content
			row["invariants"]=world.invariant_errors()
			row["passed"]=original.schema_revision==ColonyWorld.SCHEMA_REVISION and preserved==entry.canonical_hash and preserved==envelope.sha256 and row.invariants.is_empty() and roundtrip.has("world") and roundtrip.world.canonical_hash()==canonical and FileAccess.get_sha256(path)==row.input_sha256
		else: row["error"]=decoded.get("error","Duplicate or unaudited source evidence")
		seen[name]=true;rows.append(row);passed=passed and row.passed
		print("CURRENT SAVE %d/30 %s %s" % [rows.size(),name,"PASS" if row.passed else "FAIL"])
	var result: Dictionary = {"scope":"Frozen Winter saves decode, retain every gameplay field under their original content header, pass invariants and round-trip without advancing time or rewriting source files; the declared content header may upgrade. This is not a rerun of Winter survival under later rules.","source_commit":audit.commit,"target_schema":ColonyWorld.SCHEMA_REVISION,"target_version":ProjectSettings.get_setting("application/config/version"),"passed":passed and seen.size()==30,"rows":rows}
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var output: FileAccess = FileAccess.open(report_path,FileAccess.WRITE)
	if output==null: printerr("Cannot write current-save audit evidence");quit(2);return
	output.store_string(JSON.stringify(result,"\t",true));output.close()
	quit(0 if result.passed else 1)
