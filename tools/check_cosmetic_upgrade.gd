extends SceneTree
## Verify a frozen schema-21 campaign matrix without advancing or rewriting it.
var directory: String = ""
var report_path: String = ""

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()!=4 or args[0]!="--directory" or args[2]!="--report":
		printerr("Usage: -- --directory FROZEN_REPORT_DIRECTORY --report OUTPUT_JSON");quit(2);return
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
			var normalized: Dictionary = world.payload().duplicate(true)
			normalized.schema_revision=21
			for person in normalized.citizens: person.erase("appearance")
			var canonical: String = world.canonical_hash()
			var roundtrip: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
			row["current_canonical_hash"]=canonical
			row["preserved_gameplay_hash"]=JSON.stringify(ColonyState.pack(normalized),"",true).sha256_text()
			row["passed"]=old.schema_revision==21 and row.preserved_gameplay_hash==entry.canonical_hash and roundtrip.has("world") and roundtrip.world.canonical_hash()==canonical and FileAccess.get_sha256(path)==original_digest
		else: row["error"]=decoded.get("error","source checksum evidence mismatch")
		passed=passed and row.passed;rows.append(row)
		print("UPGRADE %d/30 %s %s" % [rows.size(),name,"PASS" if row.passed else "FAIL"])
	var result: Dictionary = {"scope":"Schema-21 late Winter saves preserve all acknowledged fields except declared cosmetic additions/header; no time advances or source writes","source_commit":audit.commit,"target_schema":ColonyWorld.SCHEMA_REVISION,"passed":passed and rows.size()==30,"rows":rows}
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file: FileAccess = FileAccess.open(report_path,FileAccess.WRITE)
	if file==null: printerr("Unable to write upgrade matrix evidence");quit(2);return
	file.store_string(JSON.stringify(result,"\t",true));file.close()
	quit(0 if result.passed else 1)
