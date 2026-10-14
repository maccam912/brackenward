extends SceneTree
## CPU timings for actual foreground callbacks; not a GPU/device release gate.
class ProfileSession extends GameSession:
	var frame_us: Array[int] = []
	var capture_us: Array[int] = []
	var slow_storage_pauses: int = 0
	func _process(delta: float) -> void:
		var before: int = runner.speed
		var started: int = Time.get_ticks_usec()
		super(delta)
		frame_us.append(Time.get_ticks_usec()-started)
		if before>0 and runner.speed==0 and notice.begins_with("Saving is slow"): slow_storage_pauses+=1
	func _start_background_save(full_snapshot: bool) -> void:
		var started: int = Time.get_ticks_usec()
		super(full_snapshot)
		capture_us.append(Time.get_ticks_usec()-started)

var seconds: int = 12
var snapshot: String = ""
var report_path: String = "reports/foreground-profile.json"

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
	var scratch: String = "user://foreground-profile-%d" % Time.get_ticks_usec()
	var game: ProfileSession = ProfileSession.new()
	game.world=world;game.runner=SimRunner.new(world)
	game.store.root_directory=scratch;game.store.select_slot(1);game.settings.path=scratch.path_join("settings.json")
	root.size=Vector2i(960,600);game.size=Vector2(root.size)
	root.add_child(game);game.close_sheet();game._tutorial_dismiss()
	if not game.save_local().is_empty(): quit(2);return
	game.frame_us.clear();game.capture_us.clear()
	var initial_tick: int = world.tick
	game.runner.set_speed(1)
	await create_timer(seconds).timeout
	game.runner.pause();game._finish_background_save(true)
	var result: Dictionary = {"scope":"Foreground CPU callbacks; no physical Android or GPU certification","host":OS.get_name(),"snapshot":snapshot,"seconds":seconds,"initial_tick":initial_tick,"final_tick":world.tick,"frames":stats(game.frame_us),"save_capture":stats(game.capture_us),"slow_storage_pauses":game.slow_storage_pauses,"storage_error":game.storage_error,"invariants":world.invariant_errors()}
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file: FileAccess = FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(result,"\t",true));file.close()
	print(JSON.stringify(result))
	game.queue_free();await process_frame;CampaignTests.remove_tree(scratch)
	quit(0 if result.storage_error.is_empty() and result.invariants.is_empty() else 1)

func stats(values: Array[int]) -> Dictionary:
	if values.is_empty(): return {"count":0}
	values.sort()
	return {"count":values.size(),"p50_us":values[values.size()/2],"p95_us":values[mini(values.size()-1,values.size()*95/100)],"max_us":values[-1],"over_50ms":values.filter(func(value:int)->bool:return value>50000).size()}
