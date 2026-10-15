extends SceneTree
## Read-only subsystem diagnosis with an ordinary complete-tick twin.
const Campaign = preload("res://tools/profile_campaign.gd")

class PhaseWorld extends Campaign.ProfileWorld:
	var phases: Dictionary={}
	var current_phases: Dictionary={}
	var worst_ticks: Array=[]
	var tick_total_us: int=0
	func _profile(label: String, action: Callable) -> void:
		var started: int=Time.get_ticks_usec();action.call();var elapsed: int=Time.get_ticks_usec()-started
		if not phases.has(label):phases[label]={"calls":0,"total_us":0,"max_us":0,"max_tick":0,"over_4ms":0,"over_16ms":0,"over_50ms":0}
		var row: Dictionary=phases[label];row.calls+=1;row.total_us+=elapsed
		if elapsed>row.max_us:row.max_us=elapsed;row.max_tick=tick
		if elapsed>4000:row.over_4ms+=1
		if elapsed>16000:row.over_16ms+=1
		if elapsed>50000:row.over_50ms+=1
		current_phases[label]=current_phases.get(label,0)+elapsed
	func step() -> void:
		current_phases.clear();var started: int=Time.get_ticks_usec();super.step();var elapsed: int=Time.get_ticks_usec()-started
		tick_total_us+=elapsed
		if worst_ticks.size()==32 and elapsed<=worst_ticks[-1].elapsed_us:return
		worst_ticks.append({"tick":tick,"elapsed_us":elapsed,"phases_us":current_phases.duplicate(),"path_requests":path_requests,"jobs":jobs.size(),"stacks":stacks.size()})
		worst_ticks.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.elapsed_us>b.elapsed_us)
		if worst_ticks.size()>32:worst_ticks.pop_back()

func _initialize() -> void:call_deferred("run")

func clone(source: ColonyWorld) -> PhaseWorld:
	var result: PhaseWorld=PhaseWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]:continue
		var value: Variant=source.get(field)
		if value is Array:result.get(field).assign(value.duplicate(true))
		elif value is Dictionary:result.set(field,value.duplicate(true))
		else:result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	return result

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","tools/colony_tests.gd","tools/profile_campaign.gd","tools/profile_tick_phases.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	for folder in ["src","data/catalogs"]:collect("res://"+folder,result)
	return result

func collect(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["gd","json"]:result[folder.path_join(file)]=FileAccess.get_sha256(folder.path_join(file))
	for subdirectory in DirAccess.get_directories_at(folder):collect(folder.path_join(subdirectory),result)

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=3 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>7200 or FileAccess.file_exists(args[2]):printerr("Usage: -- SNAPSHOT|fresh TICKS NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprints();var input_sha: String=FileAccess.get_sha256(args[0]) if args[0]!="fresh" else ""
	var decoded: Dictionary
	if args[0]=="fresh":
		decoded={"world":ColonyTests.world()};var error: String=ColonyGeneration.configure(decoded.world,104729,"meadow_reach")
		if not error.is_empty():printerr(error);quit(2);return
	else:decoded=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"):printerr(decoded);quit(2);return
	var ordinary: ColonyWorld=decoded.world;var measured: PhaseWorld=clone(ordinary)
	var initial_hash: String=ordinary.canonical_hash();var initial_tick: int=ordinary.tick
	var started: int=Time.get_ticks_usec()
	for index in range(int(args[1])):ordinary.step()
	var baseline_us: int=Time.get_ticks_usec()-started;started=Time.get_ticks_usec()
	for index in range(int(args[1])):measured.step()
	var measured_us: int=Time.get_ticks_usec()-started
	var exact: bool=JSON.stringify(ColonyState.pack(ordinary.payload()),"",false)==JSON.stringify(ColonyState.pack(measured.payload()),"",false)
	var invariants: Array=measured.invariant_errors();var unchanged: bool=source==fingerprints() and (args[0]=="fresh" or input_sha==FileAccess.get_sha256(args[0]))
	var report: Dictionary={"passed":exact and invariants.is_empty() and unchanged,"scope":"Headless subsystem wall timings with complete unsorted-state ordinary twin; callback/observer overhead included,host scheduling included,no save worker/GPU/physical/frame certification. The native75 thirty-minute2x probe may share host. Profile tick source equivalence is checked separately.","input":args[0],"input_sha256":input_sha,"source":source,"initial_tick":initial_tick,"initial_hash":initial_hash,"ticks":int(args[1]),"final_tick":measured.tick,"canonical_hash":measured.canonical_hash(),"baseline_us":baseline_us,"measured_us":measured_us,"profiled_tick_total_us":measured.tick_total_us,"exact_unsorted_state":exact,"invariants":invariants,"source_input_unchanged":unchanged,"phases":measured.phases,"worst_ticks":measured.worst_ticks,"engine":Engine.get_version_info().string}
	var file: FileAccess=FileAccess.open(args[2],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print("Tick phase profile: ",report.passed," ordinary_us=",baseline_us," instrumented_us=",measured_us)
	quit(0 if report.passed else 1)
