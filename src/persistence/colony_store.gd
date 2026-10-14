class_name ColonyStore
extends PrototypeStore
var journal_tick: int = 0
var journal_sequence: int = 0
var journal_length: int = 0
var journal_digest: String = ""
var recovered: bool = false
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
	return ColonyCodec.encode(world,"",sequence)

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
	world.command_trace.clear()
	recovered = false
	# Delete only journals whose verified snapshot is no longer retained.
	var snapshots: PackedStringArray = _generations()
	for name in DirAccess.get_files_at(directory):
		if name.begins_with("journal-") and name.ends_with(".frames") and not snapshots.has(name.replace("journal-", "snapshot-").replace(".frames", ".brackenward")):
			DirAccess.remove_absolute(directory.path_join(name))
	return ""

func checkpoint(world: ColonyWorld) -> String:
	if sequence == 0 or recovered:
		return save(world)
	if world.tick == journal_tick:
		return ""
	var records: PackedByteArray = PackedByteArray()
	var next_sequence: int = journal_sequence
	for entry in world.command_trace:
		if entry.tick > journal_tick:
			next_sequence += 1
			var command_frame: PackedByteArray = ColonyJournal.frame({"sequence": str(next_sequence), "kind": "command", "tick": entry.tick, "command": entry.command})
			if command_frame.decode_u32(0) > ColonyJournal.MAX_RECORD or records.size() + command_frame.size() > ColonyJournal.MAX_JOURNAL:
				return save(world)
			records.append_array(command_frame)
	next_sequence += 1
	var tick_frame: PackedByteArray = ColonyJournal.frame({"sequence": str(next_sequence), "kind": "tick", "tick": world.tick, "state":world.payload()})
	# Large valid campaigns still fit snapshots after outgrowing one journal frame.
	# Rotate before opening an append handle, preserving the previous durable data
	# and command trace if creation or verification of the new snapshot fails.
	if tick_frame.decode_u32(0) > ColonyJournal.MAX_RECORD or records.size() + tick_frame.size() > ColonyJournal.MAX_JOURNAL:
		return save(world)
	records.append_array(tick_frame)
	var path: String = directory.path_join("journal-%010d.frames" % sequence)
	var prior_length: int = 0
	if FileAccess.file_exists(path):
		var existing: FileAccess = FileAccess.open(path, FileAccess.READ)
		if existing == null:
			return "Could not read durable journal length"
		prior_length = existing.get_length()
		existing.close()
		if prior_length + records.size() > ColonyJournal.MAX_JOURNAL:
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
	var verified: Dictionary = ColonyJournal.read(appended,journal_sequence+1)
	if appended!=records or complete_length!=prior_length+records.size() or verified.has("error") or verified.get("torn_tail", false):
		recovered = true
		return "Journal verification failed; current state retained in memory"
	journal_tick = world.tick
	journal_sequence = next_sequence
	journal_length=complete_length;journal_digest=FileAccess.get_sha256(path)
	world.command_trace.clear()
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
		var migrating: bool = legacy or (header is Dictionary and header.get("version") == 3)
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
			decoded = ColonyJournal.replay(decoded.world, journal.records)
			if decoded.has("error"):
				earlier_errors.append(decoded.error)
				continue
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
	if index < 1 or index > 10 or name.strip_edges().is_empty() or name.length() > 64:
		return "Choose a snapshot slot 1–10 and a name of 1–64 characters"
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
	journal_tick = world.tick
	world.command_trace.clear()
	return ""
