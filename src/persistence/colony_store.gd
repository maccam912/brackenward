class_name ColonyStore
extends PrototypeStore
var journal_tick: int = 0
var journal_sequence: int = 0
var journal_length: int = 0
var journal_digest: String = ""
var recovered: bool = false
var journal_payload: Dictionary = {}
var journal_parent_hash: String = ""
var journal_size_bound: int = 0
var snapshot_tick: int = 0
var encoded_payload_hash: String = ""
var encoded_snapshot_bytes: int = 0
var verified_journals: Dictionary = {}
var rejected_journals: Dictionary = {}
var slot: int = 1
const CAMPAIGN_ROOT: String = "user://campaigns"
var root_directory: String = CAMPAIGN_ROOT

func _init() -> void:
	select_slot(1)

func select_slot(number: int) -> void:
	assert(number >= 1 and number <= 5)
	slot = number
	directory = root_directory.path_join("slot-%d" % number)
	sequence = 0
	journal_tick = 0
	journal_sequence = 0
	journal_length=0;journal_digest=""
	recovered = false
	journal_payload={};journal_parent_hash="";journal_size_bound=0;snapshot_tick=0
	verified_journals={};rejected_journals={}

static func occupied(number: int, root: String = CAMPAIGN_ROOT) -> bool:
	var paths: Array[String] = [root.path_join("slot-%d" % number)]
	if number == 1 and root == CAMPAIGN_ROOT:
		paths.append("user://m1")
	for path in paths:
		if not DirAccess.dir_exists_absolute(path):
			continue
		for name in DirAccess.get_files_at(path):
			if name.begins_with("snapshot-") and name.ends_with(".brackenward"):
				return true
	return false

func encode(world: RefCounted) -> PackedByteArray:
	var payload: String = JSON.stringify(ColonyState.pack(world.payload()),"",true)
	encoded_payload_hash=payload.sha256_text()
	var bytes: PackedByteArray = ColonyCodec.wrap_payload(world,payload,"",sequence)
	encoded_snapshot_bytes=bytes.size()
	return bytes

func decode(bytes: PackedByteArray) -> Dictionary:
	return ColonyCodec.decode(bytes)

func save(world: RefCounted) -> String:
	var sequence_before: int = sequence
	var error: String = super.save(world)
	if not error.is_empty():
		sequence = sequence_before
		return error
	journal_tick = world.tick
	journal_sequence = 0
	journal_length=0;journal_digest=""
	journal_payload=_retain_payload(world)
	journal_parent_hash=encoded_payload_hash;journal_size_bound=encoded_snapshot_bytes;snapshot_tick=world.tick
	world.command_trace.clear()
	recovered = false
	return ""

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
	var delta: Dictionary = {"version":1,"base_tick":journal_tick,"campaign_id":world.session_id,"parent":journal_parent_hash,"patch":ColonyDelta.make(journal_payload,world.payload())}
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

func _next_sequence() -> int:
	var next: int = super._next_sequence()
	if not DirAccess.dir_exists_absolute(directory): return next
	# An interrupted prepared rotation can leave a journal without a published
	# snapshot. Reserve its sequence, including retained staging evidence.
	for name in DirAccess.get_files_at(directory):
		if not (name.begins_with("snapshot-") and (name.ends_with(".brackenward") or name.ends_with(".brackenward.tmp"))) and not (name.begins_with("journal-") and (name.ends_with(".frames") or name.ends_with(".frames.tmp"))): continue
		var digits: String = name.substr(name.find("-")+1,10)
		if digits.length()==10 and digits.is_valid_int(): next=maxi(next,int(digits)+1)
	return next

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
		var marker: PackedByteArray = ColonyJournal._frame_bounded({"sequence":str(count),"kind":"tick","tick":world.tick,"delta":{"version":1,"base_tick":prepared.payload.tick,"campaign_id":world.session_id,"parent":parent,"patch":ColonyDelta.make(prepared.payload,world.payload())}})
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

func _retain_payload(world: RefCounted) -> Dictionary:
	# Direct callers own a mutable world and need an independent durable base.
	return world.payload().duplicate(true)

func _write_prepared_bytes(path: String, bytes: PackedByteArray) -> String:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file==null: return "Could not stage prepared snapshot: "+error_string(FileAccess.get_open_error())
	file.store_buffer(bytes);file.flush()
	var error: Error = file.get_error();file.close()
	if error!=OK or FileAccess.get_file_as_bytes(path)!=bytes: return "Prepared snapshot write/read-back failed; previous durable state retained"
	return ""

func load_latest() -> Dictionary:
	var generations: PackedStringArray = _generations()
	if generations.is_empty() and directory == CAMPAIGN_ROOT.path_join("slot-1") and root_directory == CAMPAIGN_ROOT and DirAccess.dir_exists_absolute("user://m1"):
		var earlier: ColonyStore = ColonyStore.new()
		earlier.directory = "user://m1"
		var migrated: Dictionary = earlier.load_latest()
		if migrated.has("world"):
			sequence = 0
			journal_tick = migrated.world.tick
			recovered = true
			migrated["recovery"] = "Recovered the earlier colony. Its original files remain in user://m1. The next verified snapshot adopts campaign slot 1."
		return migrated
	generations.reverse()
	var earlier_errors: Array[String] = []
	for name in generations:
		var snapshot_bytes: PackedByteArray = FileAccess.get_file_as_bytes(directory.path_join(name))
		var parser: JSON = JSON.new()
		var header: Variant = parser.data if parser.parse(snapshot_bytes.get_string_from_utf8()) == OK else null
		var legacy: bool = header is Dictionary and (header.get("version") == 1 or header.get("version") == 2)
		var migrating: bool = legacy or (header is Dictionary and (header.get("version")==3 or header.get("version")==4))
		if header is Dictionary and header.get("version") == ColonyCodec.VERSION and header.get("payload") is String:
			var original_state: Variant = JSON.parse_string(header.payload)
			migrating = original_state is Dictionary and (original_state.get("schema_revision",0) < ColonyWorld.SCHEMA_REVISION or original_state.get("content") != ColonyWorld.CONTENT_VERSION)
		var decoded: Dictionary = (M1Codec.decode(snapshot_bytes) if header.get("version") == 1 else M2Codec.decode(snapshot_bytes)) if legacy else decode(snapshot_bytes)
		if decoded.has("error"):
			earlier_errors.append(name + ": " + decoded.error)
			continue
		var snapshot_sequence: int = int(name.get_basename().trim_prefix("snapshot-"))
		var journal_path: String = directory.path_join("journal-%010d.frames" % snapshot_sequence)
		if FileAccess.file_exists(journal_path):
			var journal: Dictionary = ColonyJournal.read(FileAccess.get_file_as_bytes(journal_path))
			if journal.has("error"):
				earlier_errors.append(journal.error)
				continue
			decoded = ColonyJournal.replay(decoded.world, journal.records,header.get("sha256",""),journal.digests,ColonyJournal.snapshot_base(header))
			if decoded.has("error"):
				earlier_errors.append(decoded.error)
				continue
			if not journal.get("torn_tail",false): verified_journals[journal_path]=FileAccess.get_sha256(directory.path_join(name))+":"+FileAccess.get_sha256(journal_path)
		if legacy:
			decoded = ColonyCodec.decode(M1Codec.encode(decoded.world) if decoded.world is M1World else M2Codec.encode(decoded.world))
			if decoded.has("error"):
				earlier_errors.append(decoded.error)
				continue
		if migrating:
			var backup_error: String = _backup(directory.path_join(name),directory.path_join("migration-backup-"+name))
			if backup_error.is_empty() and FileAccess.file_exists(journal_path):
				backup_error = _backup(journal_path,directory.path_join("migration-backup-"+journal_path.get_file()))
			if not backup_error.is_empty():
				return {"error":backup_error}
		sequence = snapshot_sequence
		journal_tick = decoded.world.tick
		recovered = true
		decoded.world.command_trace.clear()
		decoded["recovery"] = "Recovered through tick %d. Original files retained.%s" % [journal_tick, " Earlier damaged generation: " + str(earlier_errors) if not earlier_errors.is_empty() else ""]
		return decoded
	return {"error": "No valid colony generation/journal. Original files retained: " + str(earlier_errors)}

func _generation_recoverable(path: String, snapshot_digest: String) -> bool:
	var journal_path: String = path.get_base_dir().path_join(path.get_file().replace("snapshot-","journal-").replace(".brackenward",".frames"))
	if not FileAccess.file_exists(journal_path): return true
	var digest: String = FileAccess.get_sha256(journal_path)
	var evidence: String = snapshot_digest+":"+digest
	if not digest.is_empty() and verified_journals.get(journal_path)==evidence: return true
	if not digest.is_empty() and rejected_journals.get(journal_path)==evidence: return false
	var journal: Dictionary = ColonyJournal.read(FileAccess.get_file_as_bytes(journal_path))
	var valid: bool = not journal.has("error") and not journal.get("torn_tail",false)
	if valid:
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		var header: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		# Unchecked legacy simulators stay preserved until normal recovery verifies
		# them. Pruning must retain both members of a damaged snapshot/journal pair.
		valid=header is Dictionary and header.get("version")!=1 and header.get("version")!=2
		if valid:
			var decoded: Dictionary = decode(bytes)
			valid=decoded.has("world")
			if valid: valid=not ColonyJournal.replay(decoded.world,journal.records,header.get("sha256",""),journal.digests,ColonyJournal.snapshot_base(header)).has("error")
	if valid:
		verified_journals[journal_path]=evidence;rejected_journals.erase(journal_path)
	else:
		rejected_journals[journal_path]=evidence;verified_journals.erase(journal_path)
	return valid

func _generation_pruned(path: String, snapshot_digest: String) -> void:
	var journal_path: String = path.get_base_dir().path_join(path.get_file().replace("snapshot-","journal-").replace(".brackenward",".frames"))
	if not FileAccess.file_exists(journal_path): return
	var evidence: String = snapshot_digest+":"+FileAccess.get_sha256(journal_path)
	if verified_journals.get(journal_path)==evidence:
		DirAccess.remove_absolute(journal_path)
		verified_journals.erase(journal_path);rejected_journals.erase(journal_path)

func _backup(source: String, destination: String) -> String:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(source)
	if FileAccess.file_exists(destination):
		return "" if FileAccess.get_file_as_bytes(destination) == bytes else "Migration backup differs: original files retained"
	var file: FileAccess = FileAccess.open(destination,FileAccess.WRITE)
	if file == null:
		return "Could not retain migration backup: original files unchanged"
	file.store_buffer(bytes)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return "" if error == OK and FileAccess.get_file_as_bytes(destination) == bytes else "Migration backup verification failed"

func named_snapshots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var files: PackedStringArray = DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray()
	files.sort()
	files.reverse()
	for index in range(1,11):
		var record: Dictionary = {"index":index,"exists":false,"valid":false,"name":"Empty","file":"","tick":0}
		for name in files:
			if not name.begins_with("manual-%02d-" % index) or not name.ends_with(".brackenward"):
				continue
			record.exists = true
			var decoded: Dictionary = decode(FileAccess.get_file_as_bytes(directory.path_join(name)))
			if not decoded.has("error"):
				record.valid = true
				record.name = decoded.snapshot_name
				record.tick = decoded.world.tick
				record.file = name
				break
		if record.exists and not record.valid:
			record.name = "Damaged snapshot; original retained"
		result.append(record)
	return result

func save_named(world: ColonyWorld, index: int, name: String, replace: bool = false) -> String:
	if index < 1 or index > 10 or name.strip_edges().is_empty() or not ColonyChronicle._printable(name,64):
		return "Choose a snapshot slot 1-10 and a name of 1-64 printable Basic Latin characters"
	var rows: Array[Dictionary] = named_snapshots()
	if rows[index-1].exists and not replace:
		return "This named snapshot is occupied. Explicitly choose which snapshot to replace."
	var error: Error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return "Could not create campaign directory"
	var generation: int = 1
	for file in DirAccess.get_files_at(directory):
		if file.begins_with("manual-") and file.ends_with(".brackenward"):
			generation = maxi(generation,int(file.get_basename().get_slice("-",2))+1)
	var path: String = directory.path_join("manual-%02d-%010d.brackenward" % [index,generation])
	var bytes: PackedByteArray = ColonyCodec.encode(world,name.strip_edges())
	var handle: FileAccess = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if handle == null:
		return "Could not open named snapshot"
	handle.store_buffer(bytes)
	handle.flush()
	error = handle.get_error()
	handle.close()
	if error != OK or decode(FileAccess.get_file_as_bytes(path+".tmp")).has("error"):
		return "Named snapshot failed verification; earlier saves retained"
	error = DirAccess.rename_absolute(path+".tmp",path)
	if error != OK:
		return "Could not finalize named snapshot"
	# Only a confirmed replacement and verified successor may prune a valid old
	# snapshot in that one slot. Corrupt evidence and all other slots are retained.
	if replace:
		for file in DirAccess.get_files_at(directory):
			var old: String = directory.path_join(file)
			if file.begins_with("manual-%02d-" % index) and file.ends_with(".brackenward") and old != path and not decode(FileAccess.get_file_as_bytes(old)).has("error"):
				DirAccess.remove_absolute(old)
	return ""

func load_named(index: int) -> Dictionary:
	if index < 1 or index > 10:
		return {"error":"Unknown named snapshot slot"}
	var row: Dictionary = named_snapshots()[index-1]
	return decode(FileAccess.get_file_as_bytes(directory.path_join(row.file))) if row.valid else {"error":"No valid named snapshot here; original files retained"}

func adopt(world: ColonyWorld, number: int, replace: bool = false) -> String:
	if number < 1 or number > 5:
		return "Unknown campaign slot"
	if occupied(number,root_directory) and not replace:
		return "Campaign occupied: choose an empty slot or explicitly confirm replacement"
	var staging: ColonyStore = ColonyStore.new()
	staging.root_directory = root_directory
	staging.directory = root_directory.path_join("import-staging-%d" % Time.get_ticks_usec())
	var save_error: String = staging.save(world)
	if not save_error.is_empty():
		return save_error
	var target: String = root_directory.path_join("slot-%d" % number)
	var archive: String = root_directory.path_join("replaced-slot-%d-%d" % [number,Time.get_ticks_usec()])
	var archived: bool = false
	if DirAccess.dir_exists_absolute(target):
		var error: Error = DirAccess.rename_absolute(target,archive)
		if error != OK:
			return "Could not retain the previous campaign; verified staged import retained"
		archived = true
	var error: Error = DirAccess.rename_absolute(staging.directory,target)
	if error != OK:
		if archived:
			DirAccess.rename_absolute(archive,target)
		return "Could not adopt import; previous campaign and verified staging retained"
	select_slot(number)
	sequence = staging.sequence
	# The verified staged save is already this campaign's durable baseline.
	# Keep its payload/metadata through the move so same-tick queued commands
	# are detected and the first advanced tick can append a verified delta.
	for field in ["journal_tick","journal_sequence","journal_length","journal_digest","journal_payload","journal_parent_hash","journal_size_bound","snapshot_tick"]:
		set(field,staging.get(field))
	verified_generations={}
	for path: String in staging.verified_generations:
		verified_generations[directory.path_join(path.get_file())]=staging.verified_generations[path]
	world.command_trace.clear()
	return ""
