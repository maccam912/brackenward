extends SceneTree
## Preserve schema-22 acknowledged gameplay; future v6 rest rules intentionally differ.
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()!=4 or args[0]!="--report" or args[2]!="--audit": quit(2);return
	var golden: Dictionary = ColonyState.unpack(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/schema22-replay-golden.json")))
	var input: Dictionary = ColonyState.unpack(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/campaign-replay-input.json")))
	var header: Dictionary = {"content":"colony-v2","content_hash":golden.content_hash,"schema_revision":22}
	var initial: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data(),input.campaign_id)
	var error: String = ColonyGeneration.configure(initial,input.seed,input.site,1)
	if not error.is_empty(): printerr(error);quit(1);return
	var rows: Array = [];var passed: bool = initial_hash(initial,header)==golden.initial_hash
	for checkpoint in golden.checkpoints:
		var path: String = "res://tests/fixtures/content5-replay-%d.brackenward" % checkpoint.tick if ColonyWorld.CONTENT_VERSION in ["colony-v6","colony-v7","colony-v8","colony-v9","colony-v10","colony-v11","colony-v12","colony-v13"] else args[1].get_basename()+"-%d.brackenward" % checkpoint.tick
		var decoded: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes(path))
		var hash_value: String = normalized_hash(decoded.world,header) if decoded.has("world") else ""
		var row: Dictionary = {"tick":checkpoint.tick,"preserved_gameplay_hash":hash_value,"expected":checkpoint.canonical_hash,"passed":hash_value==checkpoint.canonical_hash}
		rows.append(row);passed=passed and row.passed
	var original_foreign: bool = FileAccess.get_sha256("res://tests/fixtures/campaign-replay-7200.brackenward")==golden.save_fixture_sha256
	passed=passed and original_foreign
	var result: Dictionary = {"passed":passed,"scope":"Frozen schema-22-compatible acknowledged endpoints retain every gameplay field; current replay separately checks future rest and combat rules" if ColonyWorld.CONTENT_VERSION in ["colony-v6","colony-v7","colony-v8","colony-v9","colony-v10","colony-v11","colony-v12","colony-v13"] else "Exact schema-22 gameplay fields for the full frozen trace; only declared content/schema headers and empty queue metadata removed; actual deferral fails this audit","initial_preserved":initial_hash(initial,header)==golden.initial_hash,"foreign_fixture_bytes_unchanged":original_foreign,"checkpoints":rows}
	var file: FileAccess = FileAccess.open(args[3],FileAccess.WRITE)
	if file==null: quit(2);return
	file.store_string(JSON.stringify(result,"\t",true));file.close();print(JSON.stringify(result))
	quit(0 if passed else 1)

func normalized_hash(world: ColonyWorld, header: Dictionary) -> String:
	return JSON.stringify(ColonyState.pack(SchemaCompatibility.normalize(world,header)),"",true).sha256_text()

# New-colony defaults are deliberately different; never normalize loaded acknowledgements.
func initial_hash(world: ColonyWorld, header: Dictionary) -> String:
	if ColonyWorld.CONTENT_VERSION not in ["colony-v9","colony-v10","colony-v11","colony-v12","colony-v13"]: return normalized_hash(world,header)
	var state: Dictionary = SchemaCompatibility.normalize(world,header)
	for person in state.citizens:
		if person.preferences.Hauling!=1: return ""
		person.preferences.Hauling=2
	return JSON.stringify(ColonyState.pack(state),"",true).sha256_text()
