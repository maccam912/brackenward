class_name AsyncSaveTests
extends RefCounted

class GatedQueue extends ColonySaveQueue:
	var gate: Semaphore = Semaphore.new()
	func _write(writer: ColonyStore, captured: Dictionary, trace: Array[Dictionary], catalog: Dictionary, full_snapshot: bool) -> Dictionary:
		gate.wait()
		return super._write(writer,captured,trace,catalog,full_snapshot)

static func run(tree: SceneTree, check: Callable) -> void:
	var root: String = "user://async-save-tests-%d" % Time.get_ticks_usec()
	var world: ColonyWorld = ColonyTests.world()
	var store: ColonyStore = ColonyStore.new();store.directory=root.path_join("campaign")
	check.call("SAVE/async_fixture_snapshot",store.save(world).is_empty())
	world.queue_command("preference",{"citizen":1,"category":"Cooking","value":3});world.step()
	var captured_hash: String = world.canonical_hash()
	var captured_tick: int = world.tick
	var queue: GatedQueue = GatedQueue.new()
	check.call("SAVE/async_capture_starts_one_writer",queue.start(store,world).is_empty() and queue.busy() and not queue.start(store,world).is_empty())
	var later: int = world.queue_command("preference",{"citizen":2,"category":"Building","value":3});world.step()
	for frame in range(4): await tree.process_frame
	check.call("SAVE/async_wait_never_blocks_frames_or_acknowledges_early",queue.poll().is_empty() and store.journal_tick==1800 and world.receipts.get(later)=="accepted")
	queue.gate.post()
	var result: Dictionary = queue.poll(true)
	var recovered: Dictionary = load_saved(store)
	check.call("SAVE/async_recovers_exact_capture_while_live_sim_advances",result.error.is_empty() and result.tick==captured_tick and recovered.has("world") and recovered.world.canonical_hash()==captured_hash and world.tick==captured_tick+1,str(recovered.get("error","")))
	check.call("SAVE/async_keeps_commands_accepted_after_capture",world.command_trace.size()==1 and world.command_trace[0].command.id==later)
	check.call("SAVE/async_next_checkpoint_starts",queue.start(store,world).is_empty())
	queue.gate.post();result=queue.poll(true);recovered=load_saved(store)
	check.call("SAVE/async_next_checkpoint_recovers_newer_commands_once",result.error.is_empty() and recovered.has("world") and recovered.world.canonical_hash()==world.canonical_hash() and world.command_trace.is_empty() and store.journal_sequence==4)
	world.step();captured_hash=world.canonical_hash()
	check.call("SAVE/async_full_snapshot_starts",queue.start(store,world,true).is_empty())
	queue.gate.post();result=queue.poll(true);recovered=load_saved(store)
	check.call("SAVE/async_full_snapshot_rotates_verified_generations",result.error.is_empty() and result.snapshot and store.sequence==2 and recovered.has("world") and recovered.world.canonical_hash()==captured_hash)
	# A real filesystem failure must leave the live trace available for retry.
	var failing: ColonyStore = ColonyStore.new();failing.directory=root.path_join("failed-campaign")
	var blocked: String = failing.directory.path_join("snapshot-0000000001.brackenward.tmp")
	DirAccess.make_dir_recursive_absolute(blocked)
	var file: FileAccess = FileAccess.open(blocked.path_join("evidence"),FileAccess.WRITE);file.store_string("retain");file.close()
	world.queue_command("preference",{"citizen":3,"category":"Growing","value":3});world.step()
	var pending_trace: Array[Dictionary] = world.command_trace.duplicate(true)
	queue.start(failing,world);queue.gate.post();result=queue.poll(true)
	check.call("SAVE/async_failed_write_keeps_live_trace_and_sequence",not result.error.is_empty() and failing.sequence==0 and world.command_trace==pending_trace and FileAccess.get_file_as_string(blocked.path_join("evidence"))=="retain")
	CampaignTests.remove_tree(blocked)
	queue.start(failing,world);queue.gate.post();result=queue.poll(true);recovered=load_saved(failing)
	check.call("SAVE/async_failed_write_retries_latest_state",result.error.is_empty() and recovered.has("world") and recovered.world.canonical_hash()==world.canonical_hash() and world.command_trace.is_empty())
	prefix_integrity(root,check)
	verified_generation_integrity(root,check)
	# A conservative size hint crosses the worker boundary, then refreshes from
	# the smaller snapshot without trapping future saves in full-snapshot mode.
	var hinted: ColonyStore = ColonyStore.new();hinted.directory=root.path_join("oversized-hint")
	world=ColonyTests.world();hinted.save(world);hinted.journal_state_oversized=true;world.step()
	queue.start(hinted,world);queue.gate.post();result=queue.poll(true);recovered=load_saved(hinted)
	check.call("SAVE/async_oversize_hint_rotates_and_refreshes_from_actual_payload",result.error.is_empty() and result.snapshot and hinted.sequence==2 and not hinted.journal_state_oversized and recovered.has("world") and recovered.world.canonical_hash()==world.canonical_hash())
	world.step();queue.start(hinted,world);queue.gate.post();result=queue.poll(true);recovered=load_saved(hinted)
	check.call("SAVE/async_smaller_world_returns_to_journaling",result.error.is_empty() and not result.snapshot and hinted.sequence==2 and hinted.journal_sequence==1 and recovered.has("world") and recovered.world.canonical_hash()==world.canonical_hash())
	CampaignTests.remove_tree(root)

static func prefix_integrity(root: String, check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var store: ColonyStore = ColonyStore.new();store.directory=root.path_join("prefix-integrity")
	store.save(world);world.step();store.checkpoint(world)
	var path: String = store.directory.path_join("journal-0000000001.frames")
	var damaged: PackedByteArray = FileAccess.get_file_as_bytes(path);damaged[12]=damaged[12]^1
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE);file.store_buffer(damaged);file.close()
	world.queue_command("preference",{"citizen":1,"category":"Cooking","value":3});world.step()
	var pending: Array[Dictionary] = world.command_trace.duplicate(true)
	var error: String = store.checkpoint(world)
	check.call("SAVE/tail_verification_detects_changed_prior_bytes",not error.is_empty() and store.recovered and store.journal_tick==1801 and world.command_trace==pending and FileAccess.get_file_as_bytes(path)==damaged)
	check.call("SAVE/changed_prefix_retry_rotates_without_overwrite",store.checkpoint(world).is_empty() and store.sequence==2 and FileAccess.get_file_as_bytes(path)==damaged and load_saved(store).world.canonical_hash()==world.canonical_hash())
	var tail: PackedByteArray = ColonyJournal.frame({"sequence":"4","kind":"tick","tick":1802})
	check.call("SAVE/tail_reader_requires_exact_initial_sequence",not ColonyJournal.read(tail,4).has("error") and ColonyJournal.read(tail,3).has("error") and ColonyJournal.read(tail,0).has("error"))

static func verified_generation_integrity(root: String, check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var store: ColonyStore = ColonyStore.new();store.directory=root.path_join("verified-generations")
	for index in range(3): store.save(world);world.step()
	var path: String = store.directory.path_join("snapshot-0000000001.brackenward")
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path);bytes[12]=bytes[12]^1
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE);file.store_buffer(bytes);file.close()
	check.call("SAVE/generation_cache_rechecks_bytes_before_pruning",store.save(world).is_empty() and not store.verified_generations.has(path) and FileAccess.get_file_as_bytes(path)==bytes and store._generations().size()==4)
	world.step();store.save(world)
	check.call("SAVE/generation_cache_retains_three_valid_and_corrupt_evidence",store._generations().size()==4 and FileAccess.get_file_as_bytes(path)==bytes and load_saved(store).world.canonical_hash()==world.canonical_hash())

static func load_saved(store: ColonyStore) -> Dictionary:
	var reader: ColonyStore = ColonyStore.new();reader.directory=store.directory
	return reader.load_latest()

static func ui(game: GameSession, check: Callable) -> void:
	game._replace_world(ColonyTests.world());game.close_inspector();game.close_sheet();game._tutorial_dismiss()
	game.save_local()
	var queue: GatedQueue = GatedQueue.new()
	game.save_queue=queue;game.journal_elapsed=0.0;game.autosave_elapsed=0.0
	game.durable_at=game.save_clock
	game.runner.set_speed(1)
	game._process(1.0)
	check.call("SAVE/UI_periodic_save_runs_on_worker",queue.busy() and game.runner.speed>0)
	for frame in range(4): await game.get_tree().process_frame
	check.call("SAVE/UI_frames_continue_during_slow_storage",queue.busy() and game.is_inside_tree())
	game._process(2.0)
	check.call("SAVE/UI_slow_storage_pauses_simulation_with_explanation",game.runner.speed==0 and game.notice.contains("Saving is slow") and queue.busy())
	game.set_speed(1)
	check.call("SAVE/UI_slow_storage_cannot_resume_before_durable_capture",game.runner.speed==0)
	queue.gate.post();game._finish_background_save(true)
	check.call("SAVE/UI_finished_older_save_keeps_newer_live_progress",game.world.tick>=game.store.journal_tick and not queue.busy())
	game.save_local()
	game.save_queue=ColonySaveQueue.new()
	game.set_speed(1)
	check.call("SAVE/UI_latest_verified_save_allows_explicit_resume",game.runner.speed==1)
	game.runner.pause()
	game.world.step();game._start_background_save(false)
	game.world.queue_command("preference",{"citizen":1,"category":"Cooking","value":3});game.world.step()
	var final_hash: String = game.world.canonical_hash()
	game.suspend()
	var recovered: Dictionary = load_saved(game.store)
	check.call("SAVE/UI_background_joins_writer_then_saves_latest_tick",not game.save_queue.busy() and game.runner.speed==0 and recovered.has("world") and recovered.world.canonical_hash()==final_hash)
	game.resume_from_background();game.close_sheet()
	check.call("SAVE/UI_background_return_remains_paused",game.runner.speed==0 and game.world.canonical_hash()==final_hash)
