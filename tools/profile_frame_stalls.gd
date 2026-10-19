extends SceneTree
## Paired local CPU observations; not physical Android frame certification.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or FileAccess.file_exists(args[1]): printerr("Usage: -- SNAPSHOT NEW_REPORT");quit(2);return
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"): printerr(decoded.get("error","Cannot load profile input"));quit(2);return
	var source: Dictionary=fingerprint();var input_sha: String=FileAccess.get_sha256(args[0])
	var world: ColonyWorld=decoded.world;var canonical: String=world.canonical_hash()
	var captured: Dictionary=ColonyCapture.new().capture(world,[])
	var frozen: ColonyWorld=ColonySaveQueue._world(captured,world.definitions)
	var root: String="user://frame-stall-profile-%d" % Time.get_ticks_usec()
	var rows: Array=[];var exact: bool=true
	# Same-tick publication isolates time occupying the durable writer. The
	# prepared method measures its separate CPU work too; it does not vanish.
	for pair in range(4):
		for method in (["full","prepared"] if pair%2==0 else ["prepared","full"]):
			var store: ColonySaveQueue.CapturedStore=ColonySaveQueue.CapturedStore.new()
			store.owned_capture=captured;store.directory=root.path_join("%d-%s" % [pair,method])
			var error: String=store.save(frozen)
			var preparation: Dictionary={};var preparation_us: int=0
			if method=="prepared":
				var preparation_started: int=Time.get_ticks_usec()
				preparation=ColonyPreparedSnapshot.prepare(captured,world.definitions)
				preparation_us=Time.get_ticks_usec()-preparation_started
			var started: int=Time.get_ticks_usec()
			if error.is_empty(): error=store.save(frozen) if method=="full" else store.commit_prepared(frozen,preparation.snapshot)
			var elapsed: int=Time.get_ticks_usec()-started
			var recovered: Dictionary=AsyncSaveTests.load_saved(store)
			var matches: bool=error.is_empty() and recovered.has("world") and recovered.world.payload()==captured
			exact=exact and matches;rows.append({"stage":"snapshot_writer_same_tick","pair":pair,"method":method,"elapsed_us":elapsed,"separate_preparation_us":preparation_us,"exact_recovery":matches,"error":error})
	var forest: ColonyWorld=ForestCreationTests.fixture()
	for pair in range(4):
		var results: Dictionary={}
		for method in (["original","indexed"] if pair%2==0 else ["indexed","original"]):
			var state: ColonyWorld=ForestCreationTests.clone(forest)
			# Warm navigation before timing the repeated work-creation pass.
			state.walkable(Vector2i(40,30));state.unfinished_jobs();state.in_tick=true
			var started: int=Time.get_ticks_usec()
			for repeat in range(10):
				if method=="original":ForestCreationReference.create_jobs(state)
				else:ColonyNature.create_jobs(state)
			var elapsed: int=Time.get_ticks_usec()-started
			state.in_tick=false;results[method]=state.payload()
			rows.append({"stage":"forest_creation_10_passes","pair":pair,"method":method,"elapsed_us":elapsed})
		exact=exact and results.original==results.indexed
	var unchanged: bool=source==fingerprint() and input_sha==FileAccess.get_sha256(args[0]) and canonical==world.canonical_hash()
	var result: Dictionary={"passed":exact and unchanged,"scope":"Paired native headless CPU/disk observations; forest synthetic, full saves from frozen input; not phone frame, thermal or battery certification","engine":Engine.get_version_info().string,"source":source,"input_sha256":input_sha,"input_jobs":world.jobs.size(),"input_tick":world.tick,"unchanged":unchanged,"rows":rows}
	DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(result,"\t",true));file.close();CampaignTests.remove_tree(root)
	print(JSON.stringify(result));quit(0 if result.passed else 1)

func fingerprint() -> Dictionary:
	var result: Dictionary={}
	for path in ["src/sim/colony_nature.gd","src/game_session.gd","src/persistence/colony_store.gd","src/persistence/colony_save_queue.gd","tools/forest_creation_tests.gd","tools/forest_creation_reference.gd","tools/profile_frame_stalls.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	return result
