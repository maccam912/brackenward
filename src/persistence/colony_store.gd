class_name ColonyStore
extends PrototypeStore
var journal_tick: int = 0
var journal_sequence: int = 0
var recovered: bool = false

func _init() -> void:
	directory = "user://m1"

func encode(world: RefCounted) -> PackedByteArray:
	return ColonyCodec.encode(world)

func decode(bytes: PackedByteArray) -> Dictionary:
	return ColonyCodec.decode(bytes)

func save(world: RefCounted) -> String:
	var error: String = super.save(world)
	if not error.is_empty():
		return error
	journal_tick = world.tick
	journal_sequence = 0
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
	var sequence_before: int = journal_sequence
	for entry in world.command_trace:
		if entry.tick > journal_tick:
			journal_sequence += 1
			records.append_array(ColonyJournal.frame({"sequence": str(journal_sequence), "kind": "command", "tick": entry.tick, "command": entry.command}))
	journal_sequence += 1
	records.append_array(ColonyJournal.frame({"sequence": str(journal_sequence), "kind": "tick", "tick": world.tick}))
	var path: String = directory.path_join("journal-%010d.frames" % sequence)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file == null:
		journal_sequence = sequence_before
		return "Could not open durable journal"
	file.seek_end()
	file.store_buffer(records)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		recovered = true # Retry creates an immutable snapshot, never appends after a torn tail.
		return "Journal write failed: " + error_string(error)
	var verified: Dictionary = ColonyJournal.read(FileAccess.get_file_as_bytes(path))
	if verified.has("error") or verified.get("torn_tail", false):
		recovered = true
		return "Journal verification failed; current state retained in memory"
	journal_tick = world.tick
	world.command_trace.clear()
	return ""

func load_latest() -> Dictionary:
	var generations: PackedStringArray = _generations()
	generations.reverse()
	var earlier_errors: Array[String] = []
	for name in generations:
		var snapshot_bytes: PackedByteArray = FileAccess.get_file_as_bytes(directory.path_join(name))
		var parser: JSON = JSON.new()
		var header: Variant = parser.data if parser.parse(snapshot_bytes.get_string_from_utf8()) == OK else null
		var legacy: bool = header is Dictionary and header.get("content") == "m1-loop-1"
		var decoded: Dictionary = M1Codec.decode(snapshot_bytes) if legacy else decode(snapshot_bytes)
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
			decoded = ColonyCodec.decode(M1Codec.encode(decoded.world))
			if decoded.has("error"):
				earlier_errors.append(decoded.error)
				continue
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
