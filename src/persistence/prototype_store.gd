class_name PrototypeStore
extends RefCounted

var directory: String = "user://m0"
var sequence: int = 0
var verified_generations: Dictionary = {}

func save(world: RefCounted) -> String:
	var error: Error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return "Could not create save directory: %s" % error_string(error)
	sequence = _next_sequence()
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
	verified_generations[final_path]=FileAccess.get_sha256(final_path)
	_prune_generations()
	return ""

func _next_sequence() -> int:
	var generations: PackedStringArray = _generations()
	return maxi(sequence,int(generations[-1].get_basename().trim_prefix("snapshot-")) if not generations.is_empty() else 0)+1

func _prune_generations() -> void:
	var generations: PackedStringArray = _generations()
	# Prune only valid old generations after a verified replacement exists.
	var valid: PackedStringArray = []
	for name in generations:
		var path: String = directory.path_join(name)
		var digest: String = FileAccess.get_sha256(path)
		# Immutable generations already decoded by this writer only need their
		# bytes checked again. Changed files still undergo full validation.
		if (not digest.is_empty() and verified_generations.get(path,"")==digest) or not decode(FileAccess.get_file_as_bytes(path)).has("error"):
			verified_generations[path]=digest
			if _generation_recoverable(path,digest): valid.append(name)
		else:
			verified_generations.erase(path)
	while valid.size() > 3:
		var path: String = directory.path_join(valid[0])
		var digest: String = verified_generations.get(path,"")
		if DirAccess.remove_absolute(path)==OK: _generation_pruned(path,digest)
		verified_generations.erase(path)
		valid.remove_at(0)

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

func _generation_recoverable(_path: String, _digest: String) -> bool:
	return true

func _generation_pruned(_path: String, _digest: String) -> void:
	pass

func decode(bytes: PackedByteArray) -> Dictionary:
	return PrototypeCodec.decode(bytes)
