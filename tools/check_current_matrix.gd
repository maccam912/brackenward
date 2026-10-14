extends SceneTree
## Read-only loading audit of independently verified Winter or Charter endpoints.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() not in [4,6] or args[0]!="--directory" or args[2]!="--report" or (args.size()==6 and (args[4]!="--kind" or args[5]!="charter")):
		printerr("Usage: -- --directory AUDITED_DIRECTORY --report OUTPUT_JSON [--kind charter]");quit(2);return
	var directory: String = args[1];var report_path: String = args[3]
	var charter: bool=args.size()==6
	var required: int=4 if charter else 30
	var audit: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("audit.json")))
	if not audit is Dictionary or not audit.get("rows") is Array or audit.rows.size()!=required:
		printerr("An independently audited complete endpoint matrix is required");quit(2);return
	if charter:
		var source: Variant=JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("source.json")))
		var done: Variant=JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("completion.json")))
		if audit.get("passed")!=true or not source is Dictionary or not done is Dictionary or source.get("commit")!=audit.get("source_commit") or done.get("source_unchanged")!=true or done.get("total")!=4 or done.get("passed")!=4:
			printerr("Frozen Charter source/completion proof is required");quit(2);return
	elif audit.get("passed")!=30 or not audit.get("complete_matrix",false):
		printerr("An independently audited thirty-run Winter matrix is required");quit(2);return
	var rows: Array = [];var seen: Dictionary = {};var passed: bool = true
	for entry in audit.rows:
		var name: String = ("%s-%s-final.brackenward" % [entry.site,entry.mode.to_lower()]) if charter else ("%s-%d-final.brackenward" % [entry.site,entry.seed])
		var path: String = directory.path_join(name)
		var original_digest: String = FileAccess.get_sha256(path)
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		var envelope: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		var decoded: Dictionary = ColonyCodec.decode(bytes)
		var row: Dictionary = {"file":name,"input_sha256":original_digest,"passed":false}
		if not seen.has(name) and decoded.has("world") and envelope is Dictionary and entry.get("pass" if charter else "audit_pass",false):
			var world: ColonyWorld = decoded.world
			var original: Dictionary = ColonyState.unpack(JSON.parse_string(envelope.payload))
			var canonical: String = world.canonical_hash()
			var preserved: String = JSON.stringify(ColonyState.pack(SchemaCompatibility.normalize(world,original)),"",true).sha256_text()
			var roundtrip: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
			row["canonical_hash"]=canonical;row["tick"]=world.tick
			row["preserved_gameplay_hash"]=preserved;row["source_content"]=original.content
			row["invariants"]=world.invariant_errors()
			row["passed"]=(not charter or original_digest==entry.get("snapshot_sha256","")) and original.schema_revision==ColonyWorld.SCHEMA_REVISION and preserved==entry.canonical_hash and preserved==envelope.sha256 and row.invariants.is_empty() and roundtrip.has("world") and roundtrip.world.canonical_hash()==canonical and FileAccess.get_sha256(path)==row.input_sha256
		else: row["error"]=decoded.get("error","Duplicate or unaudited source evidence")
		seen[name]=true;rows.append(row);passed=passed and row.passed
		print("CURRENT SAVE %d/%d %s %s" % [rows.size(),required,name,"PASS" if row.passed else "FAIL"])
	var result: Dictionary = {"scope":"Frozen endpoint saves decode, retain every gameplay field under their original content header, pass invariants and round-trip without advancing time or rewriting source files; the declared content header may upgrade. This is not a new Winter/Charter simulation under later rules.","source_commit":audit.get("commit",audit.get("source_commit","")),"target_schema":ColonyWorld.SCHEMA_REVISION,"target_version":ProjectSettings.get_setting("application/config/version"),"target_content":ColonyWorld.CONTENT_VERSION,"kind":"charter" if charter else "winter","passed":passed and seen.size()==required,"rows":rows}
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var output: FileAccess = FileAccess.open(report_path,FileAccess.WRITE)
	if output==null: printerr("Cannot write current-save audit evidence");quit(2);return
	output.store_string(JSON.stringify(result,"\t",true));output.close()
	quit(0 if result.passed else 1)
