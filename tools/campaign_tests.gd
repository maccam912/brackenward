class_name CampaignTests
extends RefCounted

static func remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for child in DirAccess.get_directories_at(path): remove_tree(path.path_join(child))
	for file in DirAccess.get_files_at(path): DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)

static func run(check: Callable) -> void:
	check.call("SAVE/schema_field_order_is_irrelevant_but_names_are_exact",ColonyCodec._keys({"job":2,"id":1},["id","job"]) and not ColonyCodec._keys({"id":1,"wrong":2},["id","job"]) and not ColonyCodec._keys({0:1},["0"]))
	var root: String = "user://campaign-tests-%d" % Time.get_ticks_usec()
	var store: ColonyStore = ColonyStore.new()
	store.root_directory = root
	store.select_slot(1)
	var w: ColonyWorld = ColonyTests.world()
	check.call("SAVE/campaign_staged_adoption",store.adopt(w,1).is_empty() and ColonyStore.occupied(1,root) and not ColonyStore.occupied(2,root))
	var expected: String = w.canonical_hash()
	for index in range(1,11):
		check.call("SAVE/named_slot_%d" % index,store.save_named(w,index,"Spring snapshot %d" % index).is_empty())
	check.call("SAVE/eleventh_named_slot_rejected",not store.save_named(w,11,"Overflow").is_empty())
	var rows: Array[Dictionary] = store.named_snapshots()
	var retained: Dictionary = {}
	for row in rows:
		retained[row.index] = FileAccess.get_file_as_bytes(store.directory.path_join(row.file))
	check.call("SAVE/occupied_named_requires_choice",not store.save_named(w,1,"Unconfirmed overwrite").is_empty() and FileAccess.get_file_as_bytes(store.directory.path_join(rows[0].file)) == retained[1])
	for name in ["Caf\u00e9", "Bad\tname", "Bad\nname"]:
		check.call("SAVE/unsupported_named_text_never_replaces_existing_%d" % name.hash(),store.save_named(w,1,name,true).contains("Basic Latin") and FileAccess.get_file_as_bytes(store.directory.path_join(rows[0].file))==retained[1])
	for i in range(5): w.step()
	check.call("SAVE/confirmed_named_replaces_only_one",store.save_named(w,1,"Later spring",true).is_empty() and store.named_snapshots()[0].name == "Later spring")
	var unchanged: bool = true
	rows = store.named_snapshots()
	for row in rows.slice(1):
		unchanged = unchanged and FileAccess.get_file_as_bytes(store.directory.path_join(row.file)) == retained[row.index]
	check.call("SAVE/other_nine_named_unchanged",unchanged)
	for i in range(5):
		w.step()
		store.save(w)
	check.call("SAVE/three_autosaves_separate_from_ten_named",store._generations().size() == 3 and store.named_snapshots().filter(func(r:Dictionary)->bool:return r.valid).size() == 10)
	var named: Dictionary = store.load_named(2)
	check.call("SAVE/named_snapshot_restores_exact_world",named.has("world") and named.world.canonical_hash() == expected and named.snapshot_name == "Spring snapshot 2")
	var other: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data(),"independent-campaign-2")
	check.call("SAVE/independent_campaign_two",store.adopt(other,2).is_empty())
	var independent_bytes: PackedByteArray = FileAccess.get_file_as_bytes(store.directory.path_join("snapshot-0000000001.brackenward"))
	check.call("SAVE/occupied_campaign_requires_confirmation",not store.adopt(other,1).is_empty())
	var replacement: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data(),"replacement-campaign-1")
	check.call("SAVE/campaign_replacement_verified_before_adoption",store.adopt(replacement,1,true).is_empty())
	var archive_found: bool = false
	for directory in DirAccess.get_directories_at(root):
		if directory.begins_with("replaced-slot-1-"):
			var archive: ColonyStore = ColonyStore.new()
			archive.directory = root.path_join(directory)
			archive_found = archive.named_snapshots().filter(func(r:Dictionary)->bool:return r.valid).size() == 10
	check.call("SAVE/previous_campaign_archived_with_named_saves",archive_found)
	check.call("SAVE/unrelated_campaign_unchanged",FileAccess.get_file_as_bytes(root.path_join("slot-2/snapshot-0000000001.brackenward")) == independent_bytes)
	check.call("SAVE/fifth_campaign_slot_supported",store.adopt(ColonyTests.world(),5).is_empty() and ColonyStore.occupied(5,root))
	check.call("SAVE/sixth_campaign_slot_rejected",not store.adopt(ColonyTests.world(),6).is_empty())
	var preferences: DeviceSettings = DeviceSettings.new()
	preferences.path = root.path_join("settings.json")
	preferences.values.last_slot = 2
	preferences.values.text_scale = 1.25
	preferences.values.left_handed = true
	preferences.values.cameras[1] = [50.0,60.0,24.0]
	check.call("SETTINGS/device_preferences_verify_before_replace",preferences.save_local().is_empty())
	var loaded: DeviceSettings = DeviceSettings.new()
	loaded.path = preferences.path
	loaded.load_local()
	check.call("SETTINGS/restart_retains_last_campaign_and_camera",loaded.values == preferences.values)
	store.adopt(ColonyTests.world(),3)
	loaded.load_local()
	check.call("SETTINGS/import_does_not_replace_device_preferences",loaded.values == preferences.values)
	var corrupt: FileAccess = FileAccess.open(preferences.path,FileAccess.WRITE)
	corrupt.store_string("{truncated")
	corrupt.close()
	loaded = DeviceSettings.new()
	loaded.path = preferences.path
	loaded.load_local()
	check.call("SETTINGS/corrupt_preferences_use_defaults_preserve_evidence",loaded.values.last_slot == 1 and FileAccess.get_file_as_string(preferences.path) == "{truncated")
	journal_bounds(check, root)
	adoption_baseline(check,root.path_join("adoption-baseline"))
	remove_tree(root)

static func adoption_baseline(check: Callable, root: String) -> void:
	var world: ColonyWorld=ColonyTests.world()
	var error: String=ColonyGeneration.configure(world,104729,"meadow_reach")
	var store: ColonyStore=ColonyStore.new();store.root_directory=root
	if error.is_empty():error=store.adopt(world,1)
	check.call("SAVE/adoption_keeps_independent_verified_payload_base",error.is_empty() and store.journal_payload==world.payload() and not is_same(store.journal_payload.citizens,world.citizens),error)
	if not error.is_empty():return
	var path: String=store.directory.path_join("snapshot-0000000001.brackenward")
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(path)
	var envelope: Dictionary=JSON.parse_string(bytes.get_string_from_utf8())
	check.call("SAVE/adoption_rebases_verified_path_and_complete_snapshot_metadata",store.verified_generations.get(path,"")==FileAccess.get_sha256(path) and store.journal_parent_hash==envelope.sha256 and store.journal_size_bound==bytes.size() and store.snapshot_tick==world.tick and store.journal_tick==world.tick and store.journal_sequence==0 and store.journal_length==0 and store.journal_digest.is_empty())
	world.queue_command("preference",{"citizen":1,"category":"Cooking","value":3})
	check.call("SAVE/adopted_base_does_not_alias_new_paused_commands",store.journal_payload.get("next_command_id",0)==1 and store.journal_payload.get("pending_commands",[]).is_empty() and world.next_command_id==2)
	world.step();error=store.checkpoint(world)
	check.call("SAVE/first_adopted_tick_appends_verified_delta_instead_of_replacing_base",error.is_empty() and store.sequence==1 and store.journal_sequence>0 and store.journal_tick==world.tick and FileAccess.get_file_as_bytes(path)==bytes,error)
	var loaded: ColonyStore=ColonyStore.new();loaded.directory=store.directory
	var recovered: Dictionary=loaded.load_latest()
	check.call("SAVE/adopted_first_delta_recovers_exact_state",recovered.has("world") and recovered.world.canonical_hash()==world.canonical_hash(),str(recovered.get("error","")))

static func history_fixture(count: int) -> ColonyWorld:
	var world: ColonyWorld = ColonyTests.world()
	# Dense but valid historical evidence crosses byte limits without faking
	# resources, reservations, job completion, or a large checked-in save file.
	for index in range(count):
		world.emit_fact({"tick":world.tick,"actor":0,"job":0,"kind":"history_fixture","text":"Retained evidence %d: " % index + "x".repeat(8000)})
	return world

static func journal_bounds(check: Callable, root: String) -> void:
	# Rejected public commands remain audit records, and may themselves exceed a
	# frame even when the resulting authoritative world is small and valid.
	var small: ColonyWorld = ColonyTests.world()
	var command_store: ColonyStore = ColonyStore.new()
	command_store.directory=root.path_join("large-command")
	command_store.save(small)
	var command_id: int = small.queue_command("pin_moment",{"text":"x".repeat(ColonyJournal.MAX_RECORD)})
	small.step()
	check.call("SAVE/oversized_rejected_command_rotates_valid_state",small.receipts[command_id].contains("256") and command_store.checkpoint(small).is_empty() and command_store.sequence==2 and command_store.journal_sequence==0 and small.command_trace.is_empty() and not FileAccess.file_exists(command_store.directory.path_join("journal-0000000001.frames")))
	var command_recovery: Dictionary = command_store.load_latest()
	check.call("SAVE/oversized_command_recovery_keeps_rejection_receipt",command_recovery.has("world") and command_recovery.world.canonical_hash()==small.canonical_hash())
	var world: ColonyWorld = history_fixture(150)
	var store: ColonyStore = ColonyStore.new()
	store.directory = root.path_join("large-checkpoints")
	var encoded: PackedByteArray = ColonyCodec.encode(world)
	var frame: PackedByteArray = ColonyJournal.frame({"sequence":"1","kind":"tick","tick":world.tick,"state":world.payload()})
	check.call("SAVE/large_history_is_valid_snapshot_above_frame_limit",encoded.size()<ColonyCodec.MAX_BYTES and not ColonyCodec.decode(encoded).has("error") and frame.decode_u32(0)>ColonyJournal.MAX_RECORD)
	check.call("SAVE/large_history_initial_snapshot",store.save(world).is_empty())
	var previous_path: String = store.directory.path_join("snapshot-%010d.brackenward" % store.sequence)
	var previous_bytes: PackedByteArray = FileAccess.get_file_as_bytes(previous_path)
	world.queue_command("food_policy",{"enabled":true})
	world.step()
	check.call("SAVE/large_history_uses_bounded_exact_delta",store.checkpoint(world).is_empty() and store.sequence==1 and store.journal_sequence==2 and store.journal_tick==world.tick and world.command_trace.is_empty() and FileAccess.file_exists(store.directory.path_join("journal-0000000001.frames")) and FileAccess.get_file_as_bytes(previous_path)==previous_bytes)
	var reader: ColonyStore = ColonyStore.new()
	reader.directory=store.directory
	var restored: Dictionary = reader.load_latest()
	check.call("SAVE/oversized_checkpoint_recovers_exact_acknowledged_state",restored.has("world") and restored.world.canonical_hash()==world.canonical_hash(),str(restored.get("error","")))
	# A real filesystem failure must not advance bookkeeping or discard commands.
	# A genuinely large change still exceeds a frame and must rotate, preserving
	# both the earlier snapshot and its already acknowledged delta journal.
	for index in range(300): world.emit_fact({"tick":world.tick,"actor":0,"job":0,"kind":"history_fixture","text":"New retained evidence %d: " % index+"y".repeat(8000)})
	var old_journal: String = store.directory.path_join("journal-0000000001.frames")
	var old_journal_hash: String = FileAccess.get_sha256(old_journal)
	var obstruction: String = store.directory.path_join("snapshot-0000000002.brackenward.tmp")
	DirAccess.make_dir_recursive_absolute(obstruction)
	world.queue_command("food_policy",{"enabled":false})
	world.step()
	var trace: Array = world.command_trace.duplicate(true)
	var committed_tick: int = store.journal_tick
	var failure: String = store.checkpoint(world)
	check.call("SAVE/failed_large_rotation_keeps_generation_and_pending_trace",not failure.is_empty() and store.sequence==1 and store.journal_sequence==2 and store.journal_tick==committed_tick and world.command_trace==trace and FileAccess.get_file_as_bytes(previous_path)==previous_bytes and FileAccess.get_sha256(old_journal)==old_journal_hash,failure)
	DirAccess.remove_absolute(obstruction)
	check.call("SAVE/large_rotation_retries_same_generation_safely",store.checkpoint(world).is_empty() and store.sequence==2 and store.journal_sequence==0 and world.command_trace.is_empty())
	restored=reader.load_latest()
	check.call("SAVE/retried_large_rotation_recovers_exact_state",restored.has("world") and restored.world.canonical_hash()==world.canonical_hash())
	# Fill a real, correctly framed journal just below its aggregate bound. Every
	# checkpoint carries the same valid state; repeated tick markers are supported.
	world=history_fixture(80)
	store=ColonyStore.new()
	store.directory=root.path_join("aggregate-checkpoints")
	check.call("SAVE/aggregate_rotation_initial_snapshot",store.save(world).is_empty())
	var path: String = store.directory.path_join("journal-0000000001.frames")
	var handle: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	var record: Dictionary = {"sequence":"1","kind":"tick","tick":world.tick,"state":world.payload()}
	var written: int = 0
	var count: int = 0
	while true:
		record.sequence=str(count+1)
		frame=ColonyJournal.frame(record)
		if written+frame.size()>ColonyJournal.MAX_JOURNAL: break
		handle.store_buffer(frame)
		written+=frame.size()
		count+=1
	# Delta markers are much smaller than full states. Fill the remaining gap
	# with one real rejected public command so another checkpoint cannot fit.
	var remaining: int = ColonyJournal.MAX_JOURNAL-written
	if remaining>1024:
		world.queue_command("pin_moment",{"text":"x".repeat(remaining-512)})
		world.step()
		var entry: Dictionary = world.command_trace[-1]
		frame=ColonyJournal.frame({"sequence":str(count+1),"kind":"command","tick":entry.tick,"command":entry.command})
		handle.store_buffer(frame);written+=frame.size();count+=1
	handle.flush()
	handle.close()
	store.journal_sequence=count
	var old_hash: String = FileAccess.get_sha256(path)
	check.call("SAVE/aggregate_fixture_uses_valid_bounded_frames",count>1 and frame.decode_u32(0)<=ColonyJournal.MAX_RECORD and written<=ColonyJournal.MAX_JOURNAL and written+frame.size()>ColonyJournal.MAX_JOURNAL)
	world.queue_command("food_policy",{"enabled":true})
	world.step()
	obstruction=store.directory.path_join("snapshot-0000000002.brackenward.tmp")
	DirAccess.make_dir_recursive_absolute(obstruction)
	trace=world.command_trace.duplicate(true)
	committed_tick=store.journal_tick
	failure=store.checkpoint(world)
	check.call("SAVE/failed_aggregate_rotation_never_appends_or_loses_sequence",not failure.is_empty() and store.sequence==1 and store.journal_sequence==count and store.journal_tick==committed_tick and world.command_trace==trace and FileAccess.get_sha256(path)==old_hash,failure)
	DirAccess.remove_absolute(obstruction)
	check.call("SAVE/full_journal_rotates_before_append",store.checkpoint(world).is_empty() and store.sequence==2 and store.journal_sequence==0 and store.journal_tick==world.tick and world.command_trace.is_empty() and FileAccess.get_sha256(path)==old_hash)
	world.queue_command("food_policy",{"enabled":false})
	world.step()
	check.call("SAVE/rotation_starts_fresh_command_and_tick_sequences",store.checkpoint(world).is_empty() and store.sequence==2 and store.journal_sequence==2)
	var parsed: Dictionary = ColonyJournal.read(FileAccess.get_file_as_bytes(store.directory.path_join("journal-0000000002.frames")))
	check.call("SAVE/fresh_journal_has_contiguous_sequence",not parsed.has("error") and not parsed.get("torn_tail",true) and parsed.records.size()==2 and parsed.records[0].sequence=="1" and parsed.records[1].sequence=="2")
	reader.directory=store.directory
	restored=reader.load_latest()
	check.call("SAVE/aggregate_rotation_continues_exact_recovery",restored.has("world") and restored.world.canonical_hash()==world.canonical_hash(),str(restored.get("error","")))
