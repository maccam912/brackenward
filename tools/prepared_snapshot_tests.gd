class_name PreparedSnapshotTests
extends RefCounted

class GatedQueue extends ColonySaveQueue:
	var prepare_gate: Semaphore = Semaphore.new()
	var write_gate: Semaphore = Semaphore.new()
	func _prepare(request: ColonySaveQueue.WorkRequest) -> Dictionary:
		prepare_gate.wait()
		return super._prepare(request)
	func _write_prepared(writer: ColonyStore, captured: Dictionary, trace: Array[Dictionary], catalog: Dictionary, snapshot: ColonyPreparedSnapshot) -> Dictionary:
		write_gate.wait()
		return super._write_prepared(writer,captured,trace,catalog,snapshot)

static func prepare(world: ColonyWorld) -> Dictionary:
	return ColonyPreparedSnapshot.prepare(ColonyCapture.new().capture(world,[]),world.definitions)

static func run(check: Callable) -> void:
	var root: String = "user://prepared-snapshot-tests-%d" % Time.get_ticks_usec()
	var world: ColonyWorld = ColonyTests.world()
	var store: ColonyStore = ColonyStore.new();store.directory=root.path_join("catchup")
	store.save(world)
	var result: Dictionary = prepare(world)
	check.call("SAVE/preparation_is_immutable_fully_validated_and_has_no_disk_side_effect",result.has("snapshot") and result.snapshot.matches(world) and store.sequence==1 and store._generations().size()==1 and FileAccess.file_exists(store.directory.path_join("snapshot-0000000001.brackenward")))
	var prepared: ColonyPreparedSnapshot = result.snapshot
	world.queue_command("preference",{"citizen":1,"category":"Cooking","value":3});world.step();store.checkpoint(world)
	world.queue_command("food_policy",{"enabled":true});world.step()
	world.queue_command("rename",{"target":1,"text":"Mira Reed"});world.step()
	world.queue_command("preference",{"citizen":2,"category":"Building","value":3})
	var expected: String = world.canonical_hash()
	var error: String = store.commit_prepared(world,prepared)
	var recovered: Dictionary = AsyncSaveTests.load_saved(store)
	check.call("SAVE/prepared_rotation_catches_up_to_newest_capture_without_replay",error.is_empty() and store.sequence==2 and store.snapshot_tick==1800 and store.journal_tick==1803 and recovered.has("world") and recovered.world.canonical_hash()==expected and not world.pending_commands.is_empty(),str(error)+str(recovered.get("error","")))
	var path: String = store.directory.path_join("snapshot-0000000002.brackenward")
	var base: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes(path))
	var journal: Dictionary = ColonyJournal.read(FileAccess.get_file_as_bytes(store.directory.path_join("journal-0000000002.frames")))
	check.call("SAVE/prepared_rotation_preserves_intervening_command_evidence_and_new_parent",base.world.tick==1800 and journal.records.size()==4 and journal.records.filter(func(r:Dictionary)->bool:return r.kind=="command").map(func(r:Dictionary)->String:return r.command.kind)==["preference","food_policy","rename"] and journal.records[-1].delta.parent==prepared.digest and journal.records[-1].delta.base_tick==1800 and store.journal_sequence==4)
	world.step();recovered.world.step()
	check.call("SAVE/prepared_recovery_continues_pending_command_exactly_once",world.canonical_hash()==recovered.world.canonical_hash() and world.receipts[world.next_command_id-1]=="accepted")
	check.call("SAVE/preparation_rejects_mutable_source",ColonyPreparedSnapshot.prepare(world.payload(),world.definitions).has("error"))
	var invalid: Dictionary = world.payload().duplicate(true);invalid.citizens[0].rest=-1;ColonyCapture._freeze(invalid)
	check.call("SAVE/preparation_runs_full_schema_validation",ColonyPreparedSnapshot.prepare(invalid,world.definitions).has("error"))
	var other: ColonyWorld = ColonyWorld.new(world.definitions,"other-preparation-campaign")
	check.call("SAVE/prepared_rotation_rejects_foreign_campaign_before_writing",not store.commit_prepared(other,prepared).is_empty() and store.sequence==2)
	var bad: ColonyPreparedSnapshot = prepare(world).snapshot;bad.text+=" "
	check.call("SAVE/prepared_rotation_rechecks_validated_payload_digest",not store.commit_prepared(world,bad).is_empty() and store.sequence==2)
	world=ColonyTests.world();store=ColonyStore.new();store.directory=root.path_join("unchanged")
	prepared=prepare(world).snapshot
	check.call("SAVE/prepared_initial_campaign_writes_current_exact_snapshot",store.commit_prepared(world,prepared).is_empty() and store.sequence==2 and store.journal_sequence==0 and AsyncSaveTests.load_saved(store).world.canonical_hash()==world.canonical_hash())
	world.step();prepared=prepare(world).snapshot
	world.queue_command("preference",{"citizen":1,"category":"Care","value":3})
	check.call("SAVE/prepared_same_tick_pending_change_uses_exact_full_snapshot",store.commit_prepared(world,prepared).is_empty() and AsyncSaveTests.load_saved(store).world.canonical_hash()==world.canonical_hash() and not world.pending_commands.is_empty())
	failure_and_orphan(root,check)
	CampaignTests.remove_tree(root)

static func ui(game: GameSession, check: Callable) -> void:
	await early_rotation_ui(game,check)
	game._replace_world(ColonyTests.world());game.close_sheet();game.close_inspector();game._tutorial_dismiss();game.save_local()
	var queue: GatedQueue = GatedQueue.new();queue.prime(game.world);game.save_queue=queue
	game.autosave_elapsed=30.0;game.journal_elapsed=0.0;game.durable_at=game.save_clock
	game.runner.set_speed(1);game._process(0.1)
	check.call("SAVE/UI_full_snapshot_prepares_without_occupying_writer",queue.preparing() and not queue.busy() and game.runner.speed==1)
	game._start_background_save(false)
	var error: String = game._finish_background_save()
	while queue.busy():
		await game.get_tree().process_frame
		game._finish_background_save()
	check.call("SAVE/UI_journal_remains_durable_while_preparation_waits",error.is_empty() and game.store.journal_tick>1800 and queue.preparing() and game.runner.speed==1)
	game.world.queue_command("preference",{"citizen":1,"category":"Cooking","value":3});game.world.step()
	var expected: String = game.world.canonical_hash()
	queue.prepare_gate.post();game.suspend()
	var recovered: Dictionary = AsyncSaveTests.load_saved(game.store)
	check.call("SAVE/UI_background_joins_preparation_and_saves_latest_exact_state",not queue.preparing() and not queue.busy() and not queue.ready(game.world) and recovered.has("world") and recovered.world.canonical_hash()==expected and game.runner.speed==0)
	game.resume_from_background();game.close_sheet()
	check.call("SAVE/UI_prepared_background_return_stays_paused",game.runner.speed==0 and game.world.canonical_hash()==expected)
	game.save_queue=ColonySaveQueue.new();game.save_queue.prime(game.world)

static func early_rotation_ui(game: GameSession, check: Callable) -> void:
	game._replace_world(ColonyTests.world());game.close_sheet();game.close_inspector();game._tutorial_dismiss();game.save_local()
	game.world.step();game._start_background_save(false);game._finish_background_save(true)
	var queue: GatedQueue=GatedQueue.new();queue.prime(game.world);game.save_queue=queue
	game.store.journal_size_bound=ColonyCodec.MAX_BYTES-8*ColonyJournal.MAX_RECORD-1
	check.call("SAVE/UI_rotation_headroom_keeps_ordinary_small_journals",not game.store.snapshot_rotation_due())
	game.store.journal_size_bound+=1
	game.autosave_elapsed=0.0;game.journal_elapsed=0.0;game.durable_at=game.save_clock
	game.runner.set_speed(2);game.diagnostics.reset();game._process(0.1)
	check.call("SAVE/UI_large_journal_prepares_before_thirty_second_timer",queue.preparing() and not queue.busy() and game.autosave_elapsed<30.0 and game.runner.speed==2)
	game.journal_elapsed=1.0;game._process(0.0)
	while queue.busy():
		await game.get_tree().process_frame
		game._finish_background_save()
	check.call("SAVE/UI_large_journal_still_checkpoints_during_slow_preparation",game.store.journal_tick==queue.captured_tick and queue.preparing() and game.runner.speed==2)
	queue.prepare_gate.post();queue.poll_preparation(true)
	game.world.step();game.journal_elapsed=1.0
	var captures: int=game.diagnostics.samples.get("save_capture:2",{}).get("count",0)
	game._process(0.0)
	var expected: String=game.world.canonical_hash()
	check.call("SAVE/UI_regular_checkpoint_consumes_ready_preparation_once",queue.busy() and queue.writing_snapshot and not queue.ready(game.world) and game.autosave_elapsed==0.0 and game.diagnostics.samples["save_capture:2"].count==captures+1)
	game._process(0.0)
	check.call("SAVE/UI_prepared_writer_does_not_capture_a_duplicate_preparation",not queue.preparing() and game.diagnostics.samples["snapshot_capture:2"].count==1)
	queue.write_gate.post()
	while queue.busy():
		await game.get_tree().process_frame
		game._finish_background_save()
	var recovered: Dictionary=AsyncSaveTests.load_saved(game.store)
	check.call("SAVE/UI_early_rotation_recovers_exact_captured_progress",not queue.writing_snapshot and recovered.has("world") and recovered.world.canonical_hash()==expected and not game.store.snapshot_rotation_due())
	game.runner.pause();game.save_queue=ColonySaveQueue.new();game.save_queue.prime(game.world)

static func failure_and_orphan(root: String, check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var store: ColonyStore = ColonyStore.new();store.directory=root.path_join("failed-publish")
	store.save(world)
	var prepared: ColonyPreparedSnapshot = prepare(world).snapshot
	world.queue_command("food_policy",{"enabled":true});world.step()
	var blocked: String = store.directory.path_join("snapshot-0000000002.brackenward")
	DirAccess.make_dir_recursive_absolute(blocked)
	var evidence: FileAccess = FileAccess.open(blocked.path_join("evidence"),FileAccess.WRITE);evidence.store_string("retain");evidence.close()
	var expected: String = world.canonical_hash()
	var error: String = store.commit_prepared(world,prepared)
	var reader: ColonyStore = ColonyStore.new();reader.directory=store.directory
	check.call("SAVE/prepared_failed_publication_keeps_newest_old_chain_recoverable",not error.is_empty() and store.sequence==1 and store.journal_tick==world.tick and reader.load_latest().world.canonical_hash()==expected and FileAccess.get_file_as_string(blocked.path_join("evidence"))=="retain")
	var orphan: String = store.directory.path_join("journal-0000000002.frames")
	var original: PackedByteArray = FileAccess.get_file_as_bytes(orphan)
	check.call("SAVE/prepared_failed_publish_retains_catchup_and_staging_evidence",not original.is_empty() and FileAccess.file_exists(store.directory.path_join("snapshot-0000000002.brackenward.tmp")))
	CampaignTests.remove_tree(blocked)
	check.call("SAVE/next_snapshot_skips_orphan_and_staged_sequence_without_overwriting",store.save(world).is_empty() and store.sequence==3 and FileAccess.get_file_as_bytes(orphan)==original and reader.load_latest().world.canonical_hash()==expected)

static func asynchronous(tree: SceneTree, check: Callable) -> void:
	var root: String = "user://prepared-async-tests-%d" % Time.get_ticks_usec()
	var world: ColonyWorld = ColonyTests.world()
	var store: ColonyStore = ColonyStore.new();store.directory=root
	store.save(world)
	var queue: GatedQueue = GatedQueue.new();queue.prime(world)
	check.call("SAVE/slow_preparation_does_not_occupy_file_writer",queue.start_preparation(world).is_empty() and queue.preparing() and not queue.busy() and not queue.ready(world))
	for index in range(3):
		world.queue_command("food_policy",{"enabled":index%2==0});world.step()
		var error: String = queue.start(store,world)
		var completed: Dictionary = queue.poll(true)
		check.call("SAVE/ordinary_checkpoint_stays_durable_during_slow_preparation_%d" % index,error.is_empty() and completed.error.is_empty() and store.journal_tick==world.tick and queue.preparing() and AsyncSaveTests.load_saved(store).world.canonical_hash()==world.canonical_hash())
	for frame in range(3): await tree.process_frame
	check.call("SAVE/blocked_preparation_poll_keeps_frames_responsive",queue.poll_preparation().is_empty() and not queue.ready(world))
	queue.prepare_gate.post()
	var prepared_result: Dictionary = queue.poll_preparation(true)
	check.call("SAVE/preparation_recovers_its_original_owned_capture",prepared_result.error.is_empty() and queue.ready(world) and queue.prepared.payload.tick==1800 and queue.prepared.payload.use_rations==false)
	world.queue_command("preference",{"citizen":1,"category":"Cooking","value":3});world.step()
	var captured_tick: int = world.tick
	var expected: String = world.canonical_hash()
	var error: String = queue.start(store,world,true)
	var later: int = world.queue_command("preference",{"citizen":2,"category":"Building","value":3});world.step()
	check.call("SAVE/prepared_writer_never_acknowledges_later_live_tick",error.is_empty() and queue.poll().is_empty() and store.journal_tick<captured_tick and world.receipts[later]=="accepted")
	queue.write_gate.post()
	var completed: Dictionary = queue.poll(true)
	var recovered: Dictionary = AsyncSaveTests.load_saved(store)
	check.call("SAVE/prepared_writer_acknowledges_exact_catchup_and_retains_newer_command",completed.error.is_empty() and completed.tick==captured_tick and completed.snapshot and recovered.has("world") and recovered.world.canonical_hash()==expected and world.command_trace.size()==1 and world.command_trace[0].command.id==later and store.snapshot_tick==1800)
	queue.start(store,world);completed=queue.poll(true)
	check.call("SAVE/next_checkpoint_after_prepared_rotation_keeps_parent_chain",completed.error.is_empty() and AsyncSaveTests.load_saved(store).world.canonical_hash()==world.canonical_hash() and world.command_trace.is_empty())
	queue.start_preparation(world);queue.prepare_gate.post();queue.discard_preparation()
	check.call("SAVE/explicit_save_can_join_and_discard_unused_preparation",not queue.preparing() and not queue.ready(world) and not queue.busy() and store.save(world).is_empty() and AsyncSaveTests.load_saved(store).world.canonical_hash()==world.canonical_hash())
	CampaignTests.remove_tree(root)
