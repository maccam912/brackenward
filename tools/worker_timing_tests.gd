class_name WorkerTimingTests
extends RefCounted

class GatedQueue extends ColonySaveQueue:
	var write_gate: Semaphore=Semaphore.new()
	var write_done: Semaphore=Semaphore.new()
	var prepare_gate: Semaphore=Semaphore.new()
	var prepare_done: Semaphore=Semaphore.new()
	func _write(writer: ColonyStore, captured: Dictionary, trace: Array[Dictionary], catalog: Dictionary, full_snapshot: bool) -> Dictionary:
		write_gate.wait()
		return super._write(writer,captured,trace,catalog,full_snapshot)
	func _execute(request: WorkRequest) -> Dictionary:
		var result: Dictionary=super._execute(request)
		write_done.post()
		return result
	func _prepare(request: WorkRequest) -> Dictionary:
		prepare_gate.wait()
		var result: Dictionary=super._prepare(request)
		prepare_done.post()
		return result

static func wait_wall(tree: SceneTree, microseconds: int) -> void:
	# A timer created late in a long startup frame can consume that frame's
	# earlier delta. Gate wall-latency assertions on monotonic elapsed time.
	var deadline: int=Time.get_ticks_usec()+microseconds
	while Time.get_ticks_usec()<deadline:
		await tree.create_timer(maxf(float(deadline-Time.get_ticks_usec())/1000000.0,0.001)).timeout

static func run(tree: SceneTree, check: Callable) -> void:
	var root: String="user://worker-timing-tests-%d" % Time.get_ticks_usec()
	var world: ColonyWorld=ColonyTests.world()
	var store: ColonyStore=ColonyStore.new();store.directory=root.path_join("campaign")
	var error: String=store.save(world)
	if not error.is_empty():check.call("PERF/worker_timing_fixture",false,error);return
	var game: GameSession=GameSession.new();game.world=world;game.runner=SimRunner.new(world);game.store=store
	var queue: GatedQueue=GatedQueue.new();queue.prime(world);game.save_queue=queue
	world.step();var captured_tick: int=world.tick;var captured_hash: String=world.canonical_hash()
	game.runner.set_speed(4);game.runner.sleep_fast_forward=true
	var started: int=Time.get_ticks_usec();game._start_background_save(false)
	world.queue_command("food_policy",{"enabled":true});world.step();game.runner.pause()
	game.diagnostics.tick=world.tick;game.diagnostics.speed=0
	await wait_wall(tree,60000)
	queue.write_gate.post();queue.write_done.wait()
	var finished_upper: int=Time.get_ticks_usec()-started
	# The completed worker can sit unpolled. This delay must not inflate its time.
	await wait_wall(tree,40000)
	var live: Dictionary=world.payload().duplicate(true)
	error=game._finish_background_save(true,false)
	var row: Dictionary=game.diagnostics.samples.get("save_worker:12",{})
	var recovered: Dictionary=AsyncSaveTests.load_saved(store)
	check.call("PERF/worker_wall_latency_includes_blocked_worker_but_excludes_later_poll_delay",error.is_empty() and row.get("count")==1 and row.sum_us>=60000 and row.sum_us<=finished_upper and recovered.has("world") and recovered.world.canonical_hash()==captured_hash,str({"error":error,"row":row,"finished_upper":finished_upper,"recovered_hash":recovered.world.canonical_hash() if recovered.has("world") else "missing","expected_hash":captured_hash}))
	var events: Array=game.diagnostics.slow_events.filter(func(e:Dictionary)->bool:return e.stage=="save_worker")
	check.call("PERF/completed_save_keeps_captured_tick_and_12x_when_polled_paused",events.size()==1 and events[0].tick==str(captured_tick) and events[0].speed==12 and world.payload()==live and game.runner.speed==0 and not game.diagnostics.samples.has("save_worker:0"),str({"events":events,"capture":captured_tick,"world_unchanged":world.payload()==live,"speed":game.runner.speed}))
	game._finish_background_save(true,false)
	check.call("PERF/worker_completion_is_recorded_once",game.diagnostics.samples["save_worker:12"].count==1)

	queue=GatedQueue.new();queue.prime(world);game.save_queue=queue
	game.runner.set_speed(2);captured_tick=world.tick;live=world.payload().duplicate(true)
	game._start_snapshot_preparation();game.runner.pause()
	await wait_wall(tree,60000)
	queue.prepare_gate.post();queue.prepare_done.wait()
	game._finish_background_save(true,false)
	row=game.diagnostics.samples.get("snapshot_worker:2",{})
	events=game.diagnostics.slow_events.filter(func(e:Dictionary)->bool:return e.stage=="snapshot_worker")
	check.call("PERF/explicit_join_records_original_preparation_context_without_world_changes",row.get("count")==1 and row.sum_us>=60000 and events.size()==1 and events[0].tick==str(captured_tick) and events[0].speed==2 and not queue.preparing() and not queue.ready(world) and world.payload()==live,str({"row":row,"events":events,"capture":captured_tick,"world_unchanged":world.payload()==live}))
	game._finish_background_save(true,false)
	check.call("PERF/discarded_preparation_completion_is_not_recorded_twice",game.diagnostics.samples["snapshot_worker:2"].count==1)

	# Failure is timed too, without acknowledging live commands or opening UI.
	var failing: ColonyStore=ColonyStore.new();failing.directory=root.path_join("failed")
	var blocked: String=failing.directory.path_join("snapshot-0000000001.brackenward.tmp")
	DirAccess.make_dir_recursive_absolute(blocked)
	var file: FileAccess=FileAccess.open(blocked.path_join("evidence"),FileAccess.WRITE);file.store_string("retain");file.close()
	queue=GatedQueue.new();queue.prime(world);game.save_queue=queue;game.store=failing;game.runner.set_speed(4)
	live=world.payload().duplicate(true);game._start_background_save(false);queue.write_gate.post()
	error=game._finish_background_save(true,false);row=game.diagnostics.samples.get("save_worker:4",{})
	check.call("PERF/failed_worker_is_timed_without_acknowledging_or_mutating_world",not error.is_empty() and row.get("count")==1 and row.sum_us>=0 and world.payload()==live and failing.sequence==0 and not game.saving_disabled and FileAccess.get_file_as_string(blocked.path_join("evidence"))=="retain")
	# Headless callers supply no presentation speed; never fabricate poll context.
	game.store=store;game.save_queue=ColonySaveQueue.new();game.save_queue.prime(world)
	game.save_queue.start(store,world);game._finish_background_save(true,false)
	check.call("PERF/queue_without_presentation_context_does_not_inherit_current_speed",game.diagnostics.samples["save_worker:4"].count==1 and game.diagnostics.samples["save_worker:12"].count==1 and not game.diagnostics.samples.has("save_worker:0"))
	game.free();CampaignTests.remove_tree(root)
