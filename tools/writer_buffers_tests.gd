class_name WriterBuffersTests
extends RefCounted

static func stores(root: String) -> Array[ColonyStore]:
	var original: ColonyStore=WriterBuffersReference.new();original.directory=root.path_join("original")
	var current: ColonyStore=ColonyStore.new();current.directory=root.path_join("current")
	return [original,current]

static func equal(a: ColonyStore, b: ColonyStore) -> bool:
	for key in ["sequence","journal_tick","journal_sequence","journal_length","journal_digest","journal_payload","journal_parent_hash","journal_size_bound","snapshot_tick","recovered","encoded_payload_hash","encoded_snapshot_bytes"]:
		if a.get(key)!=b.get(key):return false
	var names: PackedStringArray=DirAccess.get_files_at(a.directory)
	if names!=DirAccess.get_files_at(b.directory):return false
	for name in names:
		var left: PackedByteArray=FileAccess.get_file_as_bytes(a.directory.path_join(name));var right: PackedByteArray=FileAccess.get_file_as_bytes(b.directory.path_join(name))
		if name.ends_with(".brackenward"):
			var x: Dictionary=JSON.parse_string(left.get_string_from_utf8());var y: Dictionary=JSON.parse_string(right.get_string_from_utf8())
			x.erase("timestamp");y.erase("timestamp")
			if x!=y:return false
		elif left!=right:return false
	return true

static func recover_exact(pair: Array[ColonyStore], worlds: Array[ColonyWorld]) -> bool:
	for index in range(2):
		var loaded: Dictionary=AsyncSaveTests.load_saved(pair[index])
		if not loaded.has("world") or loaded.world.payload()!=worlds[index].payload():return false
		for tick in range(60):loaded.world.step();worlds[index].step()
		if loaded.world.payload()!=worlds[index].payload() or not loaded.world.invariant_errors().is_empty():return false
	return worlds[0].payload()==worlds[1].payload()

static func run(check: Callable) -> void:
	var root: String="user://writer-buffers-%d" % Time.get_ticks_usec()
	var pair: Array[ColonyStore]=stores(root.path_join("checkpoints"))
	var worlds: Array[ColonyWorld]=[ColonyTests.world(),ColonyTests.world()]
	var exact: bool=true
	for index in range(2):exact=exact and pair[index].save(worlds[index]).is_empty()
	for batch in range(4):
		for index in range(2):
			worlds[index].queue_command("preference",{"citizen":1,"category":"Cooking","value":batch%4})
			for tick in range(30):worlds[index].step()
			exact=exact and pair[index].checkpoint(worlds[index]).is_empty()
		exact=exact and equal(pair[0],pair[1]) and worlds[0].payload()==worlds[1].payload() and worlds[0].command_trace.is_empty() and worlds[1].command_trace.is_empty()
	check.call("SAVE/shorter_writer_buffer_lifetimes_keep_full_7698c08_checkpoint_bytes_metadata_recovery_and_future",exact and recover_exact(pair,worlds))
	pair=stores(root.path_join("catchup"));worlds=[ColonyTests.world(),ColonyTests.world()];exact=true
	for index in range(2):
		exact=exact and pair[index].save(worlds[index]).is_empty()
		var prepared: ColonyPreparedSnapshot=PreparedSnapshotTests.prepare(worlds[index]).snapshot
		worlds[index].queue_command("food_policy",{"enabled":true});worlds[index].step()
		exact=exact and pair[index].checkpoint(worlds[index]).is_empty()
		worlds[index].queue_command("rename",{"target":1,"text":"Mira Reed"});worlds[index].step()
		worlds[index].queue_command("preference",{"citizen":2,"category":"Building","value":3})
		exact=exact and pair[index].commit_prepared(worlds[index],prepared).is_empty() and pair[index].sequence==2 and pair[index].journal_sequence==3 and not worlds[index].pending_commands.is_empty()
	check.call("SAVE/shorter_catchup_buffers_keep_command_evidence_parent_bytes_pending_order_and_complete_future",exact and equal(pair[0],pair[1]) and recover_exact(pair,worlds))
	pair=stores(root.path_join("fallback"));worlds=[ColonyTests.world(),ColonyTests.world()];exact=true
	var errors: Array[String]=[]
	for index in range(2):
		exact=exact and pair[index].save(worlds[index]).is_empty()
		worlds[index].queue_command("food_policy",{"enabled":true});worlds[index].step()
		pair[index].journal_size_bound=ColonyCodec.MAX_BYTES-4097
		var blocked: String=pair[index].directory.path_join("snapshot-0000000002.brackenward.tmp")
		DirAccess.make_dir_recursive_absolute(blocked)
		var file: FileAccess=FileAccess.open(blocked.path_join("evidence"),FileAccess.WRITE);file.store_string("retain");file.close()
		var trace: Array[Dictionary]=worlds[index].command_trace.duplicate(true)
		errors.append(pair[index].checkpoint(worlds[index]))
		exact=exact and not errors[-1].is_empty() and pair[index].sequence==1 and pair[index].journal_tick==1800 and worlds[index].command_trace==trace and FileAccess.get_file_as_string(blocked.path_join("evidence"))=="retain"
		CampaignTests.remove_tree(blocked)
		exact=exact and pair[index].checkpoint(worlds[index]).is_empty() and pair[index].sequence==2 and pair[index].journal_sequence==0 and worlds[index].command_trace.is_empty()
	check.call("SAVE/early_buffer_retirement_keeps_failed_full_rotation_trace_evidence_and_successful_retry",exact and errors[0]==errors[1] and equal(pair[0],pair[1]) and recover_exact(pair,worlds))
	CampaignTests.remove_tree(root)
