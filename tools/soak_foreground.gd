extends SceneTree
## Bounded native longevity probe. Product diagnostics stay bounded; no per-frame arrays.
## Engine heap/RSS are local proxies, never Android PSS/battery/thermal certification.
var snapshot: String = ""
var report_path: String = "reports/foreground-soak.json"
var seconds: int = 1800
var warmup_seconds: int = 60
var sample_seconds: int = 60
var speed: int = 2
var samples: Array[Dictionary] = []
var sampler_max_us: int = 0
var scratch: String = ""

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()%2!=0: quit(2);return
	for index in range(0,args.size(),2):
		var value: String=args[index+1]
		match args[index]:
			"--snapshot": snapshot=value
			"--report": report_path=value
			"--seconds","--warmup","--sample-seconds","--speed":
				if not value.is_valid_int(): quit(2);return
				match args[index]:
					"--seconds": seconds=int(value)
					"--warmup": warmup_seconds=int(value)
					"--sample-seconds": sample_seconds=int(value)
					"--speed": speed=int(value)
			_: quit(2);return
	if snapshot.is_empty() or seconds<3 or seconds>1800 or warmup_seconds<1 or warmup_seconds>120 or sample_seconds<1 or sample_seconds>300 or speed not in [1,2,4]:
		printerr("Usage: --snapshot FILE --report NEW.json [--seconds 3..1800 --warmup 1..120 --sample-seconds 1..300 --speed 1|2|4]");quit(2);return
	if DisplayServer.get_name()=="headless": printerr("A graphical native session is required");quit(2);return
	for path in [report_path,report_path.get_basename()+"-latest.json",report_path.get_basename()+"-final.brackenward"]:
		if FileAccess.file_exists(path): printerr("Use a new report path; earlier evidence is retained");quit(2);return
	call_deferred("run")

func resident_bytes() -> Variant:
	if OS.get_name() not in ["macOS","Linux"]: return null
	var output: Array = []
	var code: int = OS.execute("ps",PackedStringArray(["-o","rss=","-p",str(OS.get_process_id())]),output,true)
	if code!=0 or output.is_empty() or not str(output[0]).strip_edges().is_valid_int(): return null
	return int(str(output[0]).strip_edges())*1024

func sample(game: GameSession, elapsed: float, phase: String = "running") -> Dictionary:
	var started: int=Time.get_ticks_usec()
	var errors: Array[String]=game.world.invariant_errors()
	var rss: Variant=resident_bytes()
	var heap: int=OS.get_static_memory_usage()
	var result: Dictionary={"phase":phase,"elapsed_seconds":elapsed,"tick":game.world.tick,"speed":game.runner.speed,"engine_heap_bytes":heap if heap>0 else null,"rss_bytes":rss,"counts":StressFixture.counts(game.world),"job_records":game.world.jobs.size(),"stack_records":game.world.stacks.size(),"invariants":errors,"storage_error":game.storage_error,"saving_disabled":game.saving_disabled}
	result["sampler_us"]=Time.get_ticks_usec()-started
	sampler_max_us=maxi(sampler_max_us,result.sampler_us)
	samples.append(result)
	return result

func write_json(path: String, value: Dictionary) -> bool:
	var directory: String=path.get_base_dir()
	if not directory.is_empty(): DirAccess.make_dir_recursive_absolute(directory)
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null: printerr("Cannot write soak report: "+str(FileAccess.get_open_error()));return false
	var body: String=JSON.stringify(value,"\t",true)
	file.store_string(body);file.close()
	return FileAccess.get_file_as_string(path)==body

func run() -> void:
	var source_before: Dictionary=source_evidence()
	var harness_path: String=get_script().resource_path
	var harness_sha: String=FileAccess.get_sha256(harness_path)
	var input_sha: String=FileAccess.get_sha256(snapshot)
	if input_sha.is_empty() or harness_sha.is_empty(): printerr("Cannot hash soak inputs");quit(2);return
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(snapshot))
	if not decoded.has("world"): printerr(decoded);quit(2);return
	var world: ColonyWorld=decoded.world
	var input_counts: Dictionary=StressFixture.counts(world)
	var input_canonical: String=world.canonical_hash()
	scratch="user://foreground-soak-%d-%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	if DirAccess.dir_exists_absolute(scratch): printerr("Scratch path already exists");quit(2);return
	var game: GameSession=GameSession.new()
	game.world=world;game.runner=SimRunner.new(world)
	game.store.root_directory=scratch;game.store.select_slot(1);game.settings.path=scratch.path_join("settings.json")
	root.size=Vector2i(960,600);game.size=Vector2(root.size);root.add_child(game)
	game.close_sheet();game._tutorial_dismiss()
	for key in game.settings.values.auto_pauses: game.settings.values.auto_pauses[key]=false
	if game.settings.values.has("quiet_sleep_speed"): game.settings.values.quiet_sleep_speed=false
	game.settings.values.quality="Balanced";game._apply_device_settings();game.view.center_camera(Vector2(68,72))
	# Let native startup focus/window notifications settle while time is paused.
	# Any later focus loss still stops the probe through the real product code.
	var bootstrap_started: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-bootstrap_started<1000000: await process_frame
	var bootstrap: Dictionary={"tick":world.tick,"backgrounded":game.backgrounded,"sheet":game.sheet_name,"notice":game.notice}
	if game.backgrounded: printerr("Native window did not enter the foreground");quit(2);return
	game.close_sheet()
	var stop_reason: String=game.save_local()
	if not stop_reason.is_empty(): printerr(stop_reason);quit(2);return
	game.runner.set_speed(speed)
	var warmup_started: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-warmup_started<warmup_seconds*1000000:
		await process_frame
		if game.runner.speed!=speed or game.saving_disabled or not game.storage_error.is_empty(): stop_reason="Warmup paused or storage failed: speed=%d backgrounded=%s sheet=%s notice=%s runner=%s" % [game.runner.speed,str(game.backgrounded),game.sheet_name,game.notice,game.runner.notice];break
	var warmup_diagnostics: Dictionary=game._performance_report() if not stop_reason.is_empty() else {}
	game.diagnostics.reset()
	var started: int=Time.get_ticks_usec()
	var initial_tick: int=world.tick
	var frames_before: int=Engine.get_frames_drawn()
	var fps_window_frames: int=frames_before;var fps_window_us: int=started
	var fps_windows: int=0;var lowest_window_fps: Variant=null
	var low_fps_streak: float=0.0;var max_low_fps_streak: float=0.0
	var first: Dictionary=sample(game,0.0,"start")
	if not first.invariants.is_empty(): stop_reason="Initial invariant failure"
	var next_sample: int=started+sample_seconds*1000000
	var last: Dictionary=first
	while stop_reason.is_empty() and Time.get_ticks_usec()-started<seconds*1000000:
		await process_frame
		var now: int=Time.get_ticks_usec()
		if now-fps_window_us>=1000000:
			var window_seconds: float=float(now-fps_window_us)/1000000.0
			var drawn: int=Engine.get_frames_drawn()
			var fps: float=float(drawn-fps_window_frames)/window_seconds
			lowest_window_fps=fps if lowest_window_fps==null else minf(lowest_window_fps,fps)
			low_fps_streak=low_fps_streak+window_seconds if fps<24.0 else 0.0
			max_low_fps_streak=maxf(max_low_fps_streak,low_fps_streak)
			fps_windows+=1;fps_window_frames=drawn;fps_window_us=now
			if low_fps_streak>30.0: stop_reason="Drawn frame rate stayed below 24 FPS for over thirty seconds";break
		if game.runner.speed!=speed: stop_reason="Simulation paused or changed speed";break
		if game.saving_disabled or not game.storage_error.is_empty(): stop_reason="Storage failed";break
		if Time.get_ticks_usec()>=next_sample:
			last=sample(game,float(Time.get_ticks_usec()-started)/1000000.0)
			if not last.invariants.is_empty(): stop_reason="Sampled invariant failure"
			if not write_json(report_path.get_basename()+"-latest.json",{"probe_pass":false,"completed":false,"release_gate_pass":false,"scope":"Partial native longevity evidence; not a completed soak","requested_seconds":seconds,"samples":samples,"stop_reason":stop_reason}): stop_reason="Progress report failed"
			print(JSON.stringify({"soak_elapsed_seconds":last.elapsed_seconds,"tick":last.tick,"engine_heap_bytes":last.engine_heap_bytes,"rss_bytes":last.rss_bytes,"residents":last.counts.residents}))
			next_sample=Time.get_ticks_usec()+sample_seconds*1000000
	var elapsed: float=float(Time.get_ticks_usec()-started)/1000000.0
	var drawn_frames: int=Engine.get_frames_drawn()-frames_before
	var diagnostics: Dictionary=game._performance_report()
	var final_speed: int=game.runner.speed
	var backlog: float=game.runner.accumulator
	game.runner.pause();game._finish_background_save(true)
	last=sample(game,elapsed,"post_measurement_drain")
	var final_hash: String=world.canonical_hash()
	var final_bytes: PackedByteArray=ColonyCodec.encode(world)
	var restored: Dictionary=ColonyCodec.decode(final_bytes)
	var roundtrip: bool=restored.has("world") and restored.world.canonical_hash()==final_hash
	var save_path: String=report_path.get_basename()+"-final.brackenward"
	var file: FileAccess=FileAccess.open(save_path,FileAccess.WRITE)
	var snapshot_written: bool=file!=null
	if file!=null:
		file.store_buffer(final_bytes);file.close()
		snapshot_written=FileAccess.get_file_as_bytes(save_path)==final_bytes
	var drained: bool=await game.soundscape.drain()
	var source_unchanged: bool=source_before==source_evidence() and harness_sha==FileAccess.get_sha256(harness_path) and input_sha==FileAccess.get_sha256(snapshot)
	var heaps: Array=samples.filter(func(s:Dictionary)->bool:return s.engine_heap_bytes!=null).map(func(s:Dictionary)->int:return s.engine_heap_bytes)
	var heap_growth: Variant=null if heaps.is_empty() else heaps[-1]-heaps[0]
	var peak_growth: Variant=null if heaps.is_empty() else heaps.max()-heaps[0]
	var memory_proxy_pass: bool=peak_growth!=null and peak_growth<=20*1024*1024
	var population_kept: bool=samples.all(func(s:Dictionary)->bool:return s.counts.residents>=input_counts.residents)
	var completed: bool=elapsed>=seconds and stop_reason.is_empty()
	var fps_floor_proxy_pass: bool=fps_windows>0 and max_low_fps_streak<=30.0
	var logical_ticks: int=world.tick-initial_tick
	var nominal_ticks: int=floori(elapsed*speed*10)
	var logical_time_kept_up: bool=logical_ticks>=nominal_ticks-2
	var passed: bool=completed and fps_floor_proxy_pass and population_kept and logical_time_kept_up and final_speed==speed and last.invariants.is_empty() and game.storage_error.is_empty() and not game.saving_disabled and roundtrip and snapshot_written and drained and source_unchanged and memory_proxy_pass
	var result: Dictionary={"format":"brackenward-native-soak","version":1,"scope":"Native source longevity and sampled engine-heap/RSS proxies; no Android PSS, GPU, battery, thermal, all-alert or physical release certification","probe_pass":passed,"completed":completed,"release_gate_pass":false,"standard_30min_2x_case":seconds==1800 and speed==2 and warmup_seconds>=60,"requested_seconds":seconds,"measured_wall_seconds":elapsed,"warmup_seconds":warmup_seconds,"bootstrap":bootstrap,"warmup_failure_diagnostics":warmup_diagnostics,"sample_seconds":sample_seconds,"requested_speed":speed,"final_speed":final_speed,"logical_ticks":logical_ticks,"nominal_ticks":nominal_ticks,"logical_time_kept_up":logical_time_kept_up,"initial_tick":initial_tick,"final_tick":world.tick,"remaining_logical_backlog_seconds":backlog,"snapshot":snapshot,"snapshot_sha256":input_sha,"input_canonical_hash":input_canonical,"input_counts":input_counts,"final_canonical_hash":final_hash,"final_snapshot":save_path,"final_snapshot_sha256":FileAccess.get_sha256(save_path) if snapshot_written else null,"roundtrip_verified":roundtrip,"samples":samples,"engine_heap_growth_bytes":heap_growth,"peak_sampled_engine_heap_growth_bytes":peak_growth,"engine_heap_proxy_within_20_mib":memory_proxy_pass,"population_kept":population_kept,"drawn_frames":drawn_frames,"fps_windows":fps_windows,"lowest_window_fps":lowest_window_fps,"max_consecutive_low_fps_window_seconds":max_low_fps_streak,"fps_floor_proxy_pass":fps_floor_proxy_pass,"sampler_max_us":sampler_max_us,"diagnostics":diagnostics,"source_evidence":source_before,"harness_sha256":harness_sha,"source_unchanged":source_unchanged,"audio_drained":drained,"stop_reason":stop_reason,"scratch_retained":null if passed else ProjectSettings.globalize_path(scratch)}
	if not write_json(report_path,result): passed=false
	print(JSON.stringify({"probe_pass":passed,"completed":completed,"report":report_path,"elapsed":elapsed,"heap_growth":heap_growth,"peak_heap_growth":peak_growth,"logical_time_kept_up":logical_time_kept_up,"stop_reason":stop_reason}))
	game.queue_free();await process_frame
	if passed: CampaignTests.remove_tree(scratch)
	quit(0 if passed else 1)

func source_evidence() -> Dictionary:
	var files: Dictionary = {}
	for directory in ["src","data","scenes","assets/exported"]: source_directory(directory,files)
	for path in ["project.godot","tools/profile_foreground.gd","tools/profile_campaign.gd","tools/stress_fixture.gd"]:
		files[path]=FileAccess.get_sha256("res://"+path)
	files["executed_soak_script"]=FileAccess.get_sha256(get_script().resource_path)
	return {"sha256":JSON.stringify(files,"",true).sha256_text(),"files":files.size(),"scope":"src, data, scenes, exported media, project settings, profiling/fixture sources and exact executed soak bytes"}

func source_directory(path: String, files: Dictionary) -> void:
	var directory: DirAccess = DirAccess.open("res://"+path)
	directory.list_dir_begin()
	var name: String = directory.get_next()
	while not name.is_empty():
		if not name.begins_with("."):
			var child: String = path.path_join(name)
			if directory.current_is_dir(): source_directory(child,files)
			else: files[child]=FileAccess.get_sha256("res://"+child)
		name=directory.get_next()
	directory.list_dir_end()
