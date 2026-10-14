extends SceneTree
## CPU timings for actual foreground callbacks; not a GPU/device release gate.
const AssignmentProfile = preload("res://tools/profile_assignment.gd")
class TraceWorld extends AssignmentProfile.AssignmentWorld:
	var phases: Dictionary = {}
	var slow_jobs: Array[Dictionary] = []
	var tick_us: Array[int] = []
	func note(label: String, started: int) -> void:
		elapsed("assignment/"+label,started)
	func _profile(label: String, action: Callable) -> void:
		var started: int = Time.get_ticks_usec();action.call();elapsed(label,started)
	func elapsed(label: String, started: int) -> void:
		phases[label]=phases.get(label,0)+Time.get_ticks_usec()-started
	func step() -> void:
		var started: int = Time.get_ticks_usec();super.step();elapsed("simulation",started)
		tick_us.append(Time.get_ticks_usec()-started)
	func _create_work() -> void:
		var started: int = Time.get_ticks_usec();super._create_work();elapsed("create_work",started)
	func _assign(citizen: Dictionary) -> void:
		var started: int = Time.get_ticks_usec();super._assign(citizen);elapsed("assign",started)
	func _reserve(job: Dictionary, citizen: Dictionary, context: Dictionary = {}) -> bool:
		var started: int = Time.get_ticks_usec();var result: bool = super._reserve(job,citizen,context);elapsed("reserve/"+job.kind,started);return result
	func _destination(item: String, quantity: int, from: Vector2i, tags: Array = [], context: Dictionary = {}) -> Dictionary:
		var started: int = Time.get_ticks_usec();var result: Dictionary = super._destination(item,quantity,from,tags,context);elapsed("destination",started);return result
	func _work(citizen: Dictionary, job: Dictionary) -> void:
		var origin: Vector2i = Vector2i(citizen.x,citizen.y)
		var state: String = job.state
		var started: int = Time.get_ticks_usec();super._work(citizen,job);elapsed("work",started)
		var duration: int = Time.get_ticks_usec()-started
		if duration>10000 and slow_jobs.size()<64: slow_jobs.append({"tick":tick,"duration_us":duration,"person":citizen.id,"job":job.id,"kind":job.kind,"before":state,"after":job.state,"origin":origin,"work_goal":Vector2i(job.work_x,job.work_y),"source":job.source,"reason":job.reason})
	func roofed(point: Vector2i) -> bool:
		if not rooms_dirty: return super.roofed(point)
		var started: int = Time.get_ticks_usec();var result: bool = super.roofed(point);elapsed("rooms",started);return result
	func accessible(point: Vector2i) -> bool:
		if not navigation_dirty and not reachability_dirty: return super.accessible(point)
		var started: int = Time.get_ticks_usec();var result: bool = super.accessible(point);elapsed("reachability",started);return result

class ProfileAudio extends ColonyAudio:
	var update_us: Array[int] = []
	func _process(delta: float) -> void:
		var started: int = Time.get_ticks_usec();super(delta);update_us.append(Time.get_ticks_usec()-started)

class ProfileView extends WorldView:
	var update_us: Array[int] = []
	var draw_us: Array[int] = []
	func _process(delta: float) -> void:
		if draw_command_us>0: draw_us.append(draw_command_us)
		var started: int = Time.get_ticks_usec();super(delta);update_us.append(Time.get_ticks_usec()-started)

class ProfileSession extends GameSession:
	var processed_delta_seconds: float = 0.0
	var quiet_sleep_frames: int = 0
	var quiet_sleep_ticks: int = 0
	var quiet_sleep_first_stop: Dictionary = {}
	var observe_quiet_sleep: bool = false
	func _make_soundscape() -> ColonyAudio:
		return ProfileAudio.new()
	func _make_world_view() -> WorldView:
		return ProfileView.new()
	var frame_us: Array[int] = []
	var capture_us: Array[int] = []
	var preparation_us: Array[int] = []
	var finish_us: Array[int] = []
	var slow_storage_pauses: int = 0
	var trace_spikes: bool = false
	var slow_frames: Array[Dictionary] = []
	var ui_phases: Dictionary = {}
	var phase_peaks: Dictionary = {}
	var guidance_us: Array[int] = []
	var preview_us: Array[int] = []
	func _preview_text() -> String:
		var started: int = Time.get_ticks_usec();var result: String = super._preview_text()
		var duration: int = Time.get_ticks_usec()-started;preview_us.append(duration)
		if trace_spikes: ui_phases.preview=ui_phases.get("preview",0)+duration
		return result
	func _process(delta: float) -> void:
		processed_delta_seconds+=delta
		if trace_spikes: world.phases.clear();ui_phases.clear()
		var before: int = runner.speed
		var before_tick: int = world.tick
		var started: int = Time.get_ticks_usec()
		super(delta)
		if observe_quiet_sleep and runner.has_method("playback_speed") and runner.get("frame_speed")==12:
			quiet_sleep_frames+=1;quiet_sleep_ticks+=world.tick-before_tick
			if not runner.get("sleep_fast_forward") and quiet_sleep_first_stop.is_empty(): quiet_sleep_first_stop={"tick":world.tick,"awake":not runner.call("_all_asleep"),"selected_speed":runner.speed}
		var duration: int = Time.get_ticks_usec()-started
		frame_us.append(duration)
		if trace_spikes:
			for phase in world.phases: phase_peaks[phase]=maxi(phase_peaks.get(phase,0),world.phases[phase])
		if trace_spikes and duration>50000 and slow_frames.size()<64: slow_frames.append({"tick":world.tick,"duration_us":duration,"delta":delta,"phases_inclusive":world.phases.duplicate(),"ui_phases_inclusive":ui_phases.duplicate(),"writer":save_queue.busy(),"preparing":save_queue.preparing()})
		if before>0 and runner.speed==0 and notice.begins_with("Saving is slow"): slow_storage_pauses+=1
	func _start_background_save(full_snapshot: bool) -> void:
		var started: int = Time.get_ticks_usec()
		super(full_snapshot)
		capture_us.append(Time.get_ticks_usec()-started)
	func _finish_background_save(wait: bool = false, report_error: bool = true) -> String:
		var started: int = Time.get_ticks_usec()
		var result: String = super(wait,report_error)
		finish_us.append(Time.get_ticks_usec()-started)
		return result
	func _start_snapshot_preparation() -> void:
		var started: int = Time.get_ticks_usec()
		super()
		preparation_us.append(Time.get_ticks_usec()-started)
	func _refresh_guidance() -> void:
		var started: int = Time.get_ticks_usec();super._refresh_guidance()
		var duration: int = Time.get_ticks_usec()-started
		guidance_us.append(duration)
		if trace_spikes: ui_phases.guidance=ui_phases.get("guidance",0)+duration

var seconds: int = 12
var snapshot: String = ""
var report_path: String = "reports/foreground-profile.json"
var trace_spikes: bool = false
var speed: int = 1
var camera: String = "close"
var quality: String = "Balanced"
var center: Vector2 = Vector2(68,63)
var tutorial: String = "none"
var preview_setup: String = "none"
var quiet_sleep: bool = false

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()%2!=0: quit(2);return
	for index in range(0,args.size(),2):
		match args[index]:
			"--seconds":
				if not args[index+1].is_valid_int(): quit(2);return
				seconds=int(args[index+1])
			"--snapshot": snapshot=args[index+1]
			"--report": report_path=args[index+1]
			"--trace-spikes":
				if args[index+1] not in ["true","false"]: quit(2);return
				trace_spikes=args[index+1]=="true"
			"--quiet-sleep":
				if args[index+1] not in ["true","false"]: quit(2);return
				quiet_sleep=args[index+1]=="true"
			"--speed": speed=int(args[index+1]) if args[index+1].is_valid_int() else -1
			"--camera": camera=args[index+1]
			"--quality": quality=args[index+1]
			"--tutorial": tutorial=args[index+1]
			"--preview": preview_setup=args[index+1]
			"--center":
				var parts: PackedStringArray = args[index+1].split(",")
				if parts.size()!=2 or not parts[0].is_valid_int() or not parts[1].is_valid_int(): quit(2);return
				center=Vector2(int(parts[0]),int(parts[1]))
			_: quit(2);return
	if seconds<3 or seconds>1800 or speed not in [1,2,4] or camera not in ["close","far"] or quality not in ["Battery","Balanced","Smooth"]: quit(2);return
	if center.x<0 or center.x>127 or center.y<0 or center.y>127: quit(2);return
	if tutorial!="none" and not ColonyTutorial.TITLES.has(tutorial): quit(2);return
	if preview_setup not in ["none","canceled_floor"]: quit(2);return
	call_deferred("run")

func run() -> void:
	var source_before: Dictionary = source_evidence()
	var world: ColonyWorld
	if snapshot.is_empty():
		world=ColonyTests.world()
		var error: String = ColonyGeneration.configure(world,104729,"meadow_reach")
		if not error.is_empty(): printerr(error);quit(2);return
	else:
		var decoded: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes(snapshot))
		if not decoded.has("world"): printerr(decoded);quit(2);return
		world=decoded.world
	if trace_spikes:
		var measured: TraceWorld = TraceWorld.new(world.definitions)
		for field in world.payload():
			if field in ["content","content_hash"]: continue
			if world.get(field) is Array: measured.get(field).assign(world.get(field))
			else: measured.set(field,world.get(field))
		if measured.canonical_hash()!=world.canonical_hash(): printerr("Trace-world capture mismatch");quit(2);return
		measured.record_indexes.clear();measured.reset_job_queries();measured.reset_stack_queries()
		measured.navigation_dirty=true;measured.reachability_dirty=true;measured.rooms_dirty=true;world=measured
	var scratch: String = "user://foreground-profile-%d" % Time.get_ticks_usec()
	var game: ProfileSession = ProfileSession.new()
	game.trace_spikes=trace_spikes
	game.observe_quiet_sleep=quiet_sleep
	game.world=world;game.runner=SimRunner.new(world)
	game.store.root_directory=scratch;game.store.select_slot(1);game.settings.path=scratch.path_join("settings.json")
	root.size=Vector2i(960,600);game.size=Vector2(root.size)
	root.add_child(game);game.close_sheet();game._tutorial_dismiss()
	if game.settings.values.has("quiet_sleep_speed"):
		game.settings.values.quiet_sleep_speed=quiet_sleep;game._apply_device_settings()
	elif quiet_sleep:
		printerr("This frozen source does not support automatic sleep speed");quit(2);return
	if tutorial!="none":
		ColonyTutorial.replay(game._tutorial_state(),tutorial);game._refresh_guidance()
	if preview_setup=="canceled_floor":
		game.begin_build("wood_floor")
		game.view.preview_start=Vector2i(50,48);game.view.preview_end=Vector2i(65,63)
		game._preview_text();game.cancel_placement()
		if not world.pending_commands.is_empty() or game.placement.visible: printerr("Preview setup submitted work or stayed visible");quit(2);return
	for key in game.settings.values.auto_pauses: game.settings.values.auto_pauses[key]=false
	game.settings.values.quality=quality;game._apply_device_settings()
	game.view.center_camera(center)
	if camera=="far": game.view.zoom_at(0.01,game.view.size*0.5)
	var initial_counts: Dictionary = StressFixture.counts(world)
	if not game.save_local().is_empty(): quit(2);return
	var warmup_end: int = Time.get_ticks_usec()+1000000
	while Time.get_ticks_usec()<warmup_end: await process_frame
	game.frame_us.clear();game.capture_us.clear();game.finish_us.clear();game.preparation_us.clear()
	game.guidance_us.clear();game.preview_us.clear()
	game.phase_peaks.clear();game.slow_frames.clear()
	if trace_spikes: world.tick_us.clear();world.slow_jobs.clear();world.phases.clear()
	game.view.update_us.clear();game.view.draw_us.clear();game.view.draw_command_us=0;game.soundscape.update_us.clear()
	game.diagnostics.reset()
	game.quiet_sleep_frames=0;game.quiet_sleep_ticks=0;game.quiet_sleep_first_stop.clear()
	game.processed_delta_seconds=0.0
	var initial_tick: int = world.tick
	game.runner.set_speed(speed)
	var measurement_started: int = Time.get_ticks_usec()
	while Time.get_ticks_usec()-measurement_started<seconds*1000000: await process_frame
	var measured_wall_seconds: float = float(Time.get_ticks_usec()-measurement_started)/1000000.0
	var final_speed: int = game.runner.speed
	var final_accumulator: float = game.runner.accumulator
	var measured_finish: Array[int] = game.finish_us.duplicate()
	var measured_diagnostics: Dictionary = game._performance_report()
	var drain_started: int = Time.get_ticks_usec()
	game.runner.pause();game._finish_background_save(true)
	var drain_us: int = Time.get_ticks_usec()-drain_started
	var result: Dictionary = {"scope":"Foreground CPU callbacks; no physical Android or GPU certification","host":OS.get_name(),"snapshot":snapshot,"seconds":seconds,"initial_tick":initial_tick,"final_tick":world.tick,"frames":stats(game.frame_us),"save_capture":stats(game.capture_us),"save_finish":stats(measured_finish),"post_measurement_save_drain_us":drain_us,"snapshot_preparation_capture":stats(game.preparation_us),"slow_storage_pauses":game.slow_storage_pauses,"storage_error":game.storage_error,"invariants":world.invariant_errors(),"trace_spikes":trace_spikes,"slow_frames":game.slow_frames,"phase_peaks_us":game.phase_peaks,"slow_jobs":world.slow_jobs if trace_spikes else []}
	result["audio_update_frames"]=stats(game.soundscape.update_us)
	result["requested_speed"]=speed;result["camera"]=camera;result["quality"]=quality
	result["automatic_sleep_acceleration"]=quiet_sleep
	result["quiet_sleep_frames"]=game.quiet_sleep_frames;result["quiet_sleep_ticks"]=game.quiet_sleep_ticks;result["quiet_sleep_first_stop"]=game.quiet_sleep_first_stop
	result["tutorial_requested"]=tutorial;result["tutorial_final"]=game._tutorial_state().active if game._tutorial_state().enabled else "none"
	result["guidance_refresh"]=stats(game.guidance_us)
	result["preview_setup"]=preview_setup;result["placement_final_visible"]=game.placement.visible
	result["preview_refresh"]=stats(game.preview_us)
	result["camera_center"]=[game.view.camera_center().x,game.view.camera_center().y];result["tile_size"]=game.view.tile_size
	result["initial_counts"]=initial_counts;result["final_counts"]=StressFixture.counts(world)
	result["final_speed"]=final_speed;result["remaining_logical_backlog_seconds"]=final_accumulator
	result["simulation_ticks"]=stats(world.tick_us) if trace_spikes else {}
	result["measured_wall_seconds"]=measured_wall_seconds
	result["processed_delta_seconds"]=game.processed_delta_seconds
	result["source_evidence"]=source_before
	result["source_unchanged"]=source_before==source_evidence()
	result["snapshot_sha256"]=FileAccess.get_sha256(snapshot) if not snapshot.is_empty() else ""
	if not result.source_unchanged: result.storage_error="Profile source changed during measurement"
	result["view_update_frames"]=stats(game.view.update_us)
	result["view_draw_frames"]=stats(game.view.draw_us)
	result["in_game_diagnostics"]=measured_diagnostics
	if not await game.soundscape.drain(): result.storage_error="Audio streaming shutdown did not drain"
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file: FileAccess = FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(result,"\t",true));file.close()
	print(JSON.stringify(result))
	game.queue_free();await process_frame;CampaignTests.remove_tree(scratch)
	quit(0 if result.storage_error.is_empty() and result.invariants.is_empty() else 1)

func stats(values: Array[int]) -> Dictionary:
	if values.is_empty(): return {"count":0}
	values.sort()
	return {"count":values.size(),"p50_us":values[values.size()/2],"p95_us":values[mini(values.size()-1,values.size()*95/100)],"max_us":values[-1],"over_50ms":values.filter(func(value:int)->bool:return value>50000).size()}

func source_evidence() -> Dictionary:
	var files: Dictionary = {}
	for directory in ["src","data","scenes","assets/exported"]: source_directory(directory,files)
	for path in ["project.godot","tools/profile_foreground.gd","tools/profile_assignment.gd","tools/profile_campaign.gd","tools/stress_fixture.gd"]:
		files[path]=FileAccess.get_sha256("res://"+path)
	files["executed_profile_script"]=FileAccess.get_sha256(get_script().resource_path)
	return {"sha256":JSON.stringify(files,"",true).sha256_text(),"files":files.size(),"scope":"src, data, scenes, exported media, project settings, profiling/fixture sources and exact executed profiler bytes"}

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
