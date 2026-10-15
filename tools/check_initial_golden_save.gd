extends SceneTree
## Read-only exported-app boundary check; normalize only the random campaign ID.
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not FileAccess.file_exists(args[0]) or FileAccess.file_exists(args[1]):printerr("Usage: -- INITIAL_SNAPSHOT NEW_REPORT");quit(2);return
	var input_sha: String=FileAccess.get_sha256(args[0]);var source: Dictionary=fingerprints()
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"):printerr("Initial snapshot failed full codec validation: "+str(decoded.get("error","")));quit(2);return
	var world: ColonyWorld=decoded.world
	if world.generator_version!=2 or world.tick!=1800 or world.care_state.mode!="Standard" or not world.pending_commands.is_empty() or not world.command_trace.is_empty():printerr("Require an untouched revision-2 Standard colony at its initial tick");quit(2);return
	var golden: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/generation-v2-goldens.json"))
	var matches: Array=golden.maps.filter(func(row:Dictionary)->bool:return row.site==world.site_id and row.seed==world.seed)
	if matches.size()!=1:printerr("Initial save does not name a reviewed boundary seed/site");quit(2);return
	var reference: ColonyWorld=ColonyTests.world();var error: String=ColonyGeneration.configure(reference,world.seed,world.site_id)
	if not error.is_empty() or reference.canonical_hash()!=matches[0].canonical_hash:printerr("Reference generation differs from the inspected golden; no expectations changed");quit(2);return
	var original_hash: String=world.canonical_hash();world.session_id=reference.session_id
	var normalized_hash: String=world.canonical_hash();var different: Array=[]
	for field in reference.payload():
		if world.payload()[field]!=reference.payload()[field]:different.append(field)
	var unchanged: bool=input_sha==FileAccess.get_sha256(args[0]) and source==fingerprints()
	var result: Dictionary={"passed":normalized_hash==matches[0].canonical_hash and different.is_empty() and unchanged,"scope":"Initial exported-app colony compared with independently validated and visually inspected boundary expectations. Only the random campaign/session ID is normalized in a private decoded world. No simulation ticks, player files or golden values are changed; this is not device gameplay/performance certification.","seed":world.seed,"site":world.site_id,"generator_version":world.generator_version,"tick":world.tick,"input_sha256":input_sha,"original_canonical_hash":original_hash,"normalized_canonical_hash":normalized_hash,"expected_canonical_hash":matches[0].canonical_hash,"different_fields":different,"unchanged":unchanged,"engine":Engine.get_version_info().string,"source":source}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create the new initial-save report");quit(2);return
	file.store_string(JSON.stringify(result,"\t",true));file.close();print(JSON.stringify(result));quit(0 if result.passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["tools/check_initial_golden_save.gd","tests/fixtures/generation-v2-goldens.json","src/generation/colony_generation.gd","src/sim/colony_world.gd","src/persistence/colony_codec.gd","data/catalogs/colony_v6.json"]:result[path]=FileAccess.get_sha256("res://"+path)
	return result
