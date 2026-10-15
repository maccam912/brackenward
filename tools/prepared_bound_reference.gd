class_name PreparedBoundReference
extends ColonyStore

func checkpoint(world: ColonyWorld) -> String:
	if sequence == 0 or recovered:
		return save(world)
	if not journal_payload.is_empty() and journal_payload.session_id!=world.session_id:
		return "Journal belongs to a different campaign; select its own campaign slot"
	if world.tick<journal_tick:
		return "Journal progress is newer than this world; save it as a separate snapshot"
	if world.tick == journal_tick:
		return ""
	if journal_payload.is_empty() or world.tick-snapshot_tick>72000:
		return save(world)
	var snapshot_path: String = directory.path_join("snapshot-%010d.brackenward" % sequence)
	var snapshot_digest: String = FileAccess.get_sha256(snapshot_path)
	if snapshot_digest.is_empty() or snapshot_digest!=verified_generations.get(snapshot_path):
		recovered=true
		return "Snapshot changed since verification; current state and original evidence retained"
	var records: PackedByteArray = PackedByteArray()
	var next_sequence: int = journal_sequence
	for entry in world.command_trace:
		if entry.tick > journal_tick:
			next_sequence += 1
			var command_frame: PackedByteArray = ColonyJournal._frame_bounded({"sequence": str(next_sequence), "kind": "command", "tick": entry.tick, "command": entry.command})
			if command_frame.decode_u32(0) > ColonyJournal.MAX_RECORD or records.size() + command_frame.size() > ColonyJournal.MAX_JOURNAL:
				records=PackedByteArray();command_frame=PackedByteArray()
				return save(world)
			records.append_array(command_frame)
			command_frame=PackedByteArray()
	next_sequence += 1
	var delta: Dictionary = {"version":1,"base_tick":journal_tick,"campaign_id":world.session_id,"parent":journal_parent_hash,"patch":_make_delta(journal_payload,world)}
	var tick_frame: PackedByteArray = ColonyJournal._frame_bounded({"sequence": str(next_sequence), "kind": "tick", "tick": world.tick, "delta":delta})
	# Serialization owns its bytes; do not retain the producer patch while the
	# independently read-back patch is decoded and checked on this same worker.
	delta={}
	# Large valid campaigns still fit snapshots after outgrowing one journal frame.
	# Rotate before opening an append handle, preserving the previous durable data
	# and command trace if creation or verification of the new snapshot fails.
	if tick_frame.decode_u32(0) > ColonyJournal.MAX_RECORD or records.size() + tick_frame.size() > ColonyJournal.MAX_JOURNAL or journal_size_bound+2*(records.size()+tick_frame.size())>ColonyCodec.MAX_BYTES-4096:
		records=PackedByteArray();tick_frame=PackedByteArray()
		return save(world)
	records.append_array(tick_frame)
	var next_parent_hash: String=tick_frame.slice(tick_frame.size()-32).hex_encode()
	tick_frame=PackedByteArray()
	var path: String = directory.path_join("journal-%010d.frames" % sequence)
	var prior_length: int = 0
	if not FileAccess.file_exists(path) and journal_sequence>0:
		recovered=true
		return "Durable journal is missing; current state retained for a new verified snapshot"
	if FileAccess.file_exists(path):
		var existing: FileAccess = FileAccess.open(path, FileAccess.READ)
		if existing == null:
			return "Could not read durable journal length"
		prior_length = existing.get_length()
		existing.close()
		if prior_length + records.size() > ColonyJournal.MAX_JOURNAL:
			records=PackedByteArray()
			return save(world)
		var digest: String = FileAccess.get_sha256(path)
		if not journal_digest.is_empty():
			if prior_length!=journal_length or digest!=journal_digest:
				recovered=true
				return "Journal changed since verification; original evidence retained"
		else:
			var prior: Dictionary = ColonyJournal.read(FileAccess.get_file_as_bytes(path))
			if prior.has("error") or prior.get("torn_tail",false) or prior.records.size()!=journal_sequence:
				recovered=true
				return "Journal prefix verification failed; original evidence retained"
			if prior_length>0:
				recovered=true
				return "Journal prefix has no verified state anchor; recover it before appending"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE_READ)
	if file == null:
		return "Could not open durable journal"
	file.seek_end()
	file.store_buffer(records)
	file.flush()
	var error: Error = file.get_error()
	file.seek(prior_length)
	var appended: PackedByteArray = file.get_buffer(records.size())
	var complete_length: int = file.get_length()
	file.close()
	if error != OK:
		recovered = true # Retry creates an immutable snapshot, never appends after a torn tail.
		return "Journal write failed: " + error_string(error)
	# Previously verified frames are protected by the prefix digest. Reparse
	# only the newly written tail instead of every prior full-state checkpoint.
	var verified: Dictionary = ColonyJournal._read_owned(appended,journal_sequence+1)
	if appended!=records or complete_length!=prior_length+records.size() or verified.has("error") or verified.get("torn_tail", false):
		recovered = true
		return "Journal verification failed; current state retained in memory"
	var records_size: int=records.size()
	appended=PackedByteArray();records=PackedByteArray()
	var markers: Array = verified.records.filter(func(record:Dictionary)->bool:return record.kind=="tick")
	if markers.size()!=1 or not ColonyDelta.matches(journal_payload,markers[0].delta.patch,world.payload()):
		recovered=true
		return "Journal delta did not reproduce the captured state; current state retained in memory"
	markers=[];verified={}
	journal_tick = world.tick
	journal_sequence = next_sequence
	journal_length=complete_length;journal_digest=FileAccess.get_sha256(path)
	verified_journals[path]=snapshot_digest+":"+journal_digest;rejected_journals.erase(path)
	journal_payload=_retain_payload(world)
	journal_parent_hash=next_parent_hash
	# A replacement cannot grow the canonical envelope by more than twice its
	# encoded patch size. This upper bound forces a full checked save before the
	# recovery state could exceed the snapshot's 64 MiB limit.
	journal_size_bound+=2*records_size
	world.command_trace.clear()
	return ""


func commit_prepared(world: ColonyWorld, prepared: ColonyPreparedSnapshot) -> String:
	if prepared==null or not prepared.matches(world): return "Prepared snapshot no longer matches this campaign"
	# First make the newest capture durable on the existing chain. The slower
	# encoding/validation has already happened without occupying this writer.
	var error: String = checkpoint(world)
	if not error.is_empty(): return error
	if snapshot_tick>prepared.payload.tick: return "" # Oversized delta already made a newer full snapshot.
	if world.tick==prepared.payload.tick and world.payload()!=prepared.payload: return save(world)
	var next: int = _next_sequence()
	var snapshot_path: String = directory.path_join("snapshot-%010d.brackenward" % next)
	var journal_path: String = directory.path_join("journal-%010d.frames" % next)
	var bytes: PackedByteArray = ColonySnapshotEnvelope.wrap_bytes(world,prepared.encoded_payload,"",next)
	if bytes.is_empty() or bytes.size()>ColonyCodec.MAX_BYTES: return "Prepared snapshot exceeds the recovery size limit"
	var frames: PackedByteArray = PackedByteArray()
	var count: int = 0
	var parent: String = prepared.digest
	if world.tick>prepared.payload.tick:
		var old_path: String = directory.path_join("journal-%010d.frames" % sequence)
		var original: PackedByteArray = FileAccess.get_file_as_bytes(old_path)
		if original.size()!=journal_length or original.is_empty() or FileAccess.get_sha256(old_path)!=journal_digest: return "Snapshot catch-up journal changed; original durable state retained"
		var parsed: Dictionary = ColonyJournal.commands_after(original,prepared.payload.tick)
		# Parsed commands own private containers; the old journal bytes are no
		# longer needed during catch-up serialization or read-back verification.
		original=PackedByteArray()
		if parsed.has("error") or parsed.get("torn_tail",false) or parsed.total_records!=journal_sequence: return "Snapshot catch-up journal failed verification"
		for record in parsed.commands:
			count+=1
			frames.append_array(ColonyJournal._frame_bounded({"sequence":str(count),"kind":"command","tick":record.tick,"command":record.command}))
		parsed={}
		count+=1
		var marker: PackedByteArray = ColonyJournal._frame_bounded({"sequence":str(count),"kind":"tick","tick":world.tick,"delta":{"version":1,"base_tick":prepared.payload.tick,"campaign_id":world.session_id,"parent":parent,"patch":_make_delta(prepared.payload,world)}})
		if marker.decode_u32(0)>ColonyJournal.MAX_RECORD or frames.size()+marker.size()>ColonyJournal.MAX_JOURNAL or bytes.size()+2*(frames.size()+marker.size())>ColonyCodec.MAX_BYTES-4096:
			bytes=PackedByteArray();frames=PackedByteArray();marker=PackedByteArray()
			return save(world)
		frames.append_array(marker)
		parent=marker.slice(marker.size()-32).hex_encode()
		marker=PackedByteArray()
		var verified: Dictionary = ColonyJournal._read_owned(frames)
		if verified.has("error") or verified.get("torn_tail",false) or verified.records.size()!=count: return "Prepared catch-up marker failed verification"
		if not ColonyDelta.matches(prepared.payload,verified.records[-1].delta.patch,world.payload()): return "Prepared catch-up marker differs from the current capture"
		verified={}
	error=_write_prepared_bytes(snapshot_path+".tmp",bytes)
	if not error.is_empty(): return error
	if not frames.is_empty():
		error=_write_prepared_bytes(journal_path+".tmp",frames)
		if not error.is_empty(): return error
		var journal_error: Error = DirAccess.rename_absolute(journal_path+".tmp",journal_path)
		if journal_error!=OK: return "Could not publish prepared catch-up journal: "+error_string(journal_error)
	# Publish the snapshot last: recovery cannot select an old preparation tick
	# without its already verified catch-up state after a crash.
	var snapshot_error: Error = DirAccess.rename_absolute(snapshot_path+".tmp",snapshot_path)
	if snapshot_error!=OK: return "Could not publish prepared snapshot: "+error_string(snapshot_error)
	sequence=next;snapshot_tick=prepared.payload.tick
	journal_sequence=count;journal_length=frames.size();journal_digest=FileAccess.get_sha256(journal_path) if count>0 else ""
	journal_tick=world.tick;journal_payload=_retain_payload(world);journal_parent_hash=parent
	journal_size_bound=bytes.size()+2*frames.size();recovered=false
	verified_generations[snapshot_path]=FileAccess.get_sha256(snapshot_path)
	if count>0: verified_journals[journal_path]=verified_generations[snapshot_path]+":"+journal_digest
	world.command_trace.clear()
	_prune_generations()
	return ""
