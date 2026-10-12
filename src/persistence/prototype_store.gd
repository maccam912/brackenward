class_name PrototypeStore
extends RefCounted

var directory: String = "user://m0"
var sequence: int = 0

func save(world: RefCounted) -> String:
	var error: Error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return "Could not create save directory: %s" % error_string(error)
	var generations: PackedStringArray = _generations()
	if not generations.is_empty():
		sequence = maxi(sequence, int(generations[-1].get_basename().trim_prefix("snapshot-")))
	sequence += 1
	var final_path: String = directory.path_join("snapshot-%010d.brackenward" % sequence)
	var temporary: String = final_path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "Could not open save: %s" % error_string(FileAccess.get_open_error())
	file.store_buffer(encode(world))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return "Could not write save: %s" % error_string(write_error)
	var verified: Dictionary = decode(FileAccess.get_file_as_bytes(temporary))
	if verified.has("error"):
		return "Save verification failed: " + verified.error
	error = DirAccess.rename_absolute(temporary, final_path)
	if error != OK:
		return "Could not finalize save: %s" % error_string(error)
	generations = _generations()
	# Prune only valid old generations after a verified replacement exists.
	var valid: PackedStringArray = []
	for name in generations:
		if not decode(FileAccess.get_file_as_bytes(directory.path_join(name))).has("error"):
			valid.append(name)
	while valid.size() > 3:
		DirAccess.remove_absolute(directory.path_join(valid[0]))
		valid.remove_at(0)
	return ""

func load_latest() -> Dictionary:
	var generations: PackedStringArray = _generations()
	generations.reverse()
	for name in generations:
		var decoded: Dictionary = decode(FileAccess.get_file_as_bytes(directory.path_join(name)))
		if not decoded.has("error"):
			return decoded
	return {"error": "No valid touch-prototype save was found."}

func _generations() -> PackedStringArray:
	var result: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(directory):
		return result
	for name in DirAccess.get_files_at(directory):
		if name.begins_with("snapshot-") and name.ends_with(".brackenward"):
			result.append(name)
	result.sort()
	return result

func encode(world: RefCounted) -> PackedByteArray:
	return PrototypeCodec.encode(world)

func decode(bytes: PackedByteArray) -> Dictionary:
	return PrototypeCodec.decode(bytes)
