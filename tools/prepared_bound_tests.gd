class_name PreparedBoundTests
extends RefCounted

class CountingStore extends ColonyStore:
	var fallback_reads: int=0
	func _read_catchup_commands(path: String, tick: int) -> Dictionary:
		fallback_reads+=1
		return super._read_catchup_commands(path,tick)

static func pair_case(root: String, mode: String) -> Dictionary:
	var stores: Array[ColonyStore]=[CountingStore.new(),PreparedBoundReference.new()]
	var worlds: Array[ColonyWorld]=[ColonyTests.world(),ColonyTests.world()]
	var errors: Array[String]=[];var exact: bool=true
	for index in range(2):
		var store: ColonyStore=stores[index];var world: ColonyWorld=worlds[index];store.directory=root.path_join(mode).path_join(str(index))
		var error: String=store.save(world);exact=error.is_empty() and exact
		if mode=="covered":
			world.queue_command("food_policy",{"enabled":true});world.step();error=store.checkpoint(world);exact=error.is_empty() and exact
		var prepared: ColonyPreparedSnapshot=PreparedSnapshotTests.prepare(world).snapshot
		if mode=="late":world.queue_command("food_policy",{"enabled":true})
		world.step();error=store.checkpoint(world);exact=error.is_empty() and exact
		if mode=="none" or mode=="covered":world.step()
		if mode=="late":world.queue_command("rename",{"target":1,"text":"Mira Reed"});world.step()
		if index==0:
			if mode=="unknown":store._journal_last_command_tick=-1
			if mode=="digest":store._journal_command_digest="wrong"
			if mode=="sequence":store._journal_command_sequence+=1
		if mode=="changed":
			world.queue_command("preference",{"citizen":1,"category":"Cooking","value":3})
			var path: String=store.directory.path_join("journal-%010d.frames" % store.sequence)
			var bytes: PackedByteArray=FileAccess.get_file_as_bytes(path);bytes[-1]=bytes[-1]^1
			var file: FileAccess=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(bytes);file.close()
		var before: String=world.canonical_hash();var trace: Array[Dictionary]=world.command_trace.duplicate(true)
		error=store.commit_prepared(world,prepared);errors.append(error)
		if mode=="changed":exact=exact and error=="Snapshot catch-up journal changed; original durable state retained" and store.sequence==1 and world.canonical_hash()==before and world.command_trace==trace
		else:
			var loaded: Dictionary=AsyncSaveTests.load_saved(store)
			exact=exact and error.is_empty() and loaded.has("world") and loaded.world.payload()==world.payload()
			if loaded.has("world"):
				for tick in range(30):world.step();loaded.world.step()
				exact=exact and loaded.world.payload()==world.payload() and world.invariant_errors().is_empty()
	exact=exact and errors[0]==errors[1] and WriterBuffersTests.equal(stores[0],stores[1]) and worlds[0].payload()==worlds[1].payload()
	if mode!="changed":exact=exact and stores[0]._command_bound_known() and stores[0]._journal_last_command_tick==(1802 if mode=="late" else 0)
	return {"exact":exact,"reads":stores[0].get("fallback_reads")}

static func run(check: Callable) -> void:
	var root: String="user://prepared-bound-%d" % Time.get_ticks_usec()
	var a: Dictionary=pair_case(root,"none");var b: Dictionary=pair_case(root,"covered")
	check.call("SAVE/verified_command_bound_skips_only_proven_empty_catchup_and_matches_full_9905cf2_bytes_metadata_future",a.exact and a.reads==0 and b.exact and b.reads==0)
	var exact: bool=true
	for mode in ["late","unknown","digest","sequence"]:
		var result: Dictionary=pair_case(root,mode);exact=exact and result.exact and result.reads==1
	check.call("SAVE/newer_commands_unknown_digest_or_sequence_keep_original_full_catchup_reader",exact)
	a=pair_case(root,"changed")
	check.call("SAVE/fast_empty_catchup_still_rejects_changed_prefix_without_acknowledging_pending_work",a.exact and a.reads==0)
	var world: ColonyWorld=ColonyTests.world();var store: ColonyStore=ColonyStore.new();store.directory=root.path_join("failed-save")
	var error: String=store.save(world);world.step();error=store.checkpoint(world)
	var bound: Array=[store._journal_last_command_tick,store._journal_command_digest,store._journal_command_sequence]
	world.queue_command("food_policy",{"enabled":true});world.step();var trace: Array[Dictionary]=world.command_trace.duplicate(true)
	var blocked: String=store.directory.path_join("snapshot-0000000002.brackenward.tmp");DirAccess.make_dir_recursive_absolute(blocked)
	var file: FileAccess=FileAccess.open(blocked.path_join("evidence"),FileAccess.WRITE);file.store_string("retain");file.close()
	error=store.save(world)
	exact=not error.is_empty() and bound==[store._journal_last_command_tick,store._journal_command_digest,store._journal_command_sequence] and world.command_trace==trace and FileAccess.get_file_as_string(blocked.path_join("evidence"))=="retain"
	CampaignTests.remove_tree(blocked);error=store.save(world)
	check.call("SAVE/failed_snapshot_preserves_command_bound_and_successful_snapshot_resets_it",exact and error.is_empty() and store._command_bound_known() and store._journal_last_command_tick==0 and store._journal_command_sequence==0 and store._journal_command_digest.is_empty())
	world=ColonyTests.world();store=ColonyStore.new();store.directory=root.path_join("queue");error=store.save(world)
	var queue: ColonySaveQueue=ColonySaveQueue.new();queue.prime(world)
	world.queue_command("food_policy",{"enabled":true});world.step();error=queue.start(store,world);var written: Dictionary=queue.poll(true)
	exact=error.is_empty() and written.error.is_empty() and store._command_bound_known() and store._journal_last_command_tick==1801 and store._journal_command_sequence==store.journal_sequence and store._journal_command_digest==store.journal_digest
	error=queue.start_preparation(world);queue.poll_preparation(true);world.step();error=queue.start(store,world,true);written=queue.poll(true)
	var loaded: Dictionary=AsyncSaveTests.load_saved(store)
	exact=exact and error.is_empty() and written.error.is_empty() and store.sequence==2 and store._command_bound_known() and store._journal_last_command_tick==0 and store._journal_command_sequence==1 and loaded.has("world") and loaded.world.payload()==world.payload()
	var adopted: ColonyStore=ColonyStore.new();adopted.root_directory=root.path_join("adopted");error=adopted.adopt(world,2)
	check.call("SAVE/command_bound_survives_real_queue_capture_poll_prepared_rotation_and_campaign_adoption",exact and error.is_empty() and adopted._command_bound_known() and adopted._journal_last_command_tick==0 and adopted._journal_command_sequence==0)
	CampaignTests.remove_tree(root)
