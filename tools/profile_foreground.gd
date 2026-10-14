extends SceneTree
## CPU timings for actual foreground callbacks; not a GPU/device release gate.
const CampaignProfile = preload("res://tools/profile_campaign.gd")
class TraceWorld extends CampaignProfile.ProfileWorld:
	var phases: Dictionary = {}
	var slow_jobs: Array[Dictionary] = []
	func _profile(label: String, action: Callable) -> void:
		var started: int = Time.get_ticks_usec();action.call();elapsed(label,started)
	func elapsed(label: String, started: int) -> void:
		phases[label]=phases.get(label,0)+Time.get_ticks_usec()-started
	func step() -> void:
		var started: int = Time.get_ticks_usec();super.step();elapsed("simulation",started)
	func _create_work() -> void:
		var started: int = Time.get_ticks_usec();super._create_work();elapsed("create_work",started)
	func _assign(citizen: Dictionary) -> void:
		var started: int = Time.get_ticks_usec();super._assign(citizen);elapsed("assign",started)
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

class ProfileSession extends GameSession:
	var frame_us: Array[int] = []
	var capture_us: Array[int] = []
	var preparation_us: Array[int] = []
	var finish_us: Array[int] = []
	var slow_storage_pauses: int = 0
	var trace_spikes: bool = false
	var slow_frames: Array[Dictionary] = []
	var ui_phases: Dictionary = {}
	var phase_peaks: Dictionary = {}
	func _process(delta: float) -> void:
		if trace_spikes: world.phases.clear();ui_phases.clear()
		var before: int = runner.speed
		var started: int = Time.get_ticks_usec()
		super(delta)
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
		if trace_spikes: ui_phases.guidance=ui_phases.get("guidance",0)+Time.get_ticks_usec()-started

var seconds: int = 12
var snapshot: String = ""
var report_path: String = "reports/foreground-profile.json"
var trace_spikes: bool = false

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
			_: quit(2);return
	if seconds<3 or seconds>120: quit(2);return
	call_deferred("run")

func run() -> void:
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
		measured.reset_job_queries();measured.reset_stack_queries();world=measured
	var scratch: String = "user://foreground-profile-%d" % Time.get_ticks_usec()
	var game: ProfileSession = ProfileSession.new()
	game.trace_spikes=trace_spikes
	game.world=world;game.runner=SimRunner.new(world)
	game.store.root_directory=scratch;game.store.select_slot(1);game.settings.path=scratch.path_join("settings.json")
	root.size=Vector2i(960,600);game.size=Vector2(root.size)
	root.add_child(game);game.close_sheet();game._tutorial_dismiss()
	if not game.save_local().is_empty(): quit(2);return
	game.frame_us.clear();game.capture_us.clear();game.finish_us.clear();game.preparation_us.clear()
	var initial_tick: int = world.tick
	game.runner.set_speed(1)
	await create_timer(seconds).timeout
	game.runner.pause();game._finish_background_save(true)
	var result: Dictionary = {"scope":"Foreground CPU callbacks; no physical Android or GPU certification","host":OS.get_name(),"snapshot":snapshot,"seconds":seconds,"initial_tick":initial_tick,"final_tick":world.tick,"frames":stats(game.frame_us),"save_capture":stats(game.capture_us),"save_finish":stats(game.finish_us),"snapshot_preparation_capture":stats(game.preparation_us),"slow_storage_pauses":game.slow_storage_pauses,"storage_error":game.storage_error,"invariants":world.invariant_errors(),"trace_spikes":trace_spikes,"slow_frames":game.slow_frames,"phase_peaks_us":game.phase_peaks,"slow_jobs":world.slow_jobs if trace_spikes else []}
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file: FileAccess = FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(result,"\t",true));file.close()
	print(JSON.stringify(result))
	game.queue_free();await process_frame;CampaignTests.remove_tree(scratch)
	quit(0 if result.storage_error.is_empty() and result.invariants.is_empty() else 1)

func stats(values: Array[int]) -> Dictionary:
	if values.is_empty(): return {"count":0}
	values.sort()
	return {"count":values.size(),"p50_us":values[values.size()/2],"p95_us":values[mini(values.size()-1,values.size()*95/100)],"max_us":values[-1],"over_50ms":values.filter(func(value:int)->bool:return value>50000).size()}
