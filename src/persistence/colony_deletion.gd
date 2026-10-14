class_name ColonyDeletion
extends RefCounted
## Review exact private files, detach atomically by rename, then reclaim storage.
const REMOVED_PREFIX: String = "deleted-save-"

func has_saves(store: ColonyStore, number: int) -> bool:
	if number<1 or number>5: return false
	if DirAccess.dir_exists_absolute(store.root_directory.path_join("slot-%d" % number)): return true
	if number==1 and store.root_directory==ColonyStore.CAMPAIGN_ROOT and DirAccess.dir_exists_absolute("user://m1"): return true
	if not DirAccess.dir_exists_absolute(store.root_directory): return false
	for name in DirAccess.get_directories_at(store.root_directory):
		if name.begins_with("replaced-slot-%d-" % number) and name.trim_prefix("replaced-slot-%d-" % number).is_valid_int(): return true
	return false

func preview(store: ColonyStore, number: int, snapshot: int = 0) -> Dictionary:
	if number<1 or number>5 or snapshot<0 or snapshot>10: return {"error":"Unknown campaign or snapshot slot"}
	var targets: Array[String] = []
	var directory: String=store.root_directory.path_join("slot-%d" % number)
	if snapshot==0:
		if DirAccess.dir_exists_absolute(directory): targets.append(directory)
		if number==1 and store.root_directory==ColonyStore.CAMPAIGN_ROOT and DirAccess.dir_exists_absolute("user://m1"): targets.append("user://m1")
		for name in DirAccess.get_directories_at(store.root_directory) if DirAccess.dir_exists_absolute(store.root_directory) else PackedStringArray():
			if name.begins_with("replaced-slot-%d-" % number) and name.trim_prefix("replaced-slot-%d-" % number).is_valid_int(): targets.append(store.root_directory.path_join(name))
	else:
		for name in DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray():
			if name.begins_with("manual-%02d-" % snapshot) and (name.ends_with(".brackenward") or name.ends_with(".brackenward.tmp")): targets.append(directory.path_join(name))
	targets.sort()
	var result: Dictionary={"slot":number,"snapshot":snapshot,"targets":targets,"files":[],"directories":[],"bytes":0,"error":""}
	for target in targets:
		var error: String=_inspect(target,result,0)
		if not error.is_empty(): return {"error":error}
	result["token"]=JSON.stringify(result,"",true).sha256_text()
	return result

func _inspect(path: String, result: Dictionary, depth: int) -> String:
	if depth>32 or result.files.size()>10000: return "Save folder is too large to review safely"
	var parent: DirAccess=DirAccess.open(path.get_base_dir())
	if parent==null or parent.is_link(path.get_file()): return "Cannot delete an unreadable or linked save path"
	if DirAccess.dir_exists_absolute(path):
		var folder: DirAccess=DirAccess.open(path)
		if folder==null: return "Cannot read save folder"
		folder.include_hidden=true
		result.directories.append(path)
		var names: Array[String]=[]
		for name in folder.get_files(): names.append(name)
		for name in folder.get_directories(): names.append(name)
		names.sort()
		for name in names:
			var error: String=_inspect(path.path_join(name),result,depth+1)
			if not error.is_empty(): return error
	else:
		var file: FileAccess=FileAccess.open(path,FileAccess.READ)
		if file==null: return "Cannot read a save selected for deletion"
		var length: int=file.get_length();file.close()
		var digest: String=FileAccess.get_sha256(path)
		if digest.is_empty(): return "Cannot verify a save selected for deletion"
		result.files.append({"path":path,"bytes":length,"sha256":digest});result.bytes+=length
	return ""

func commit(store: ColonyStore, reviewed: Dictionary) -> Dictionary:
	if not reviewed.has("token"): return {"deleted":false,"error":"Review the saves before deleting"}
	var current: Dictionary=preview(store,reviewed.slot,reviewed.snapshot)
	if current.has("error") and not current.error.is_empty(): return {"deleted":false,"error":current.error}
	if current.get("token")!=reviewed.token: return {"deleted":false,"error":"Saves changed since review. Review them again before deleting."}
	if current.targets.is_empty(): return {"deleted":false,"error":"These saves have already been removed"}
	var detached: Array[Dictionary]=[]
	var deletion_id: String=Crypto.new().generate_random_bytes(16).hex_encode()
	for target in current.targets:
		var destination: String=target.get_base_dir().path_join(REMOVED_PREFIX+"%s-%d-%d" % [deletion_id,reviewed.slot,detached.size()])
		var error: Error=_rename(target,destination)
		if error!=OK:
			var failed_rollback: bool=false
			for entry in detached:
				if _rename(entry.to,entry.from)!=OK: failed_rollback=true
			return {"deleted":false,"unsafe_to_resume":failed_rollback,"error":"Could not remove saves: "+error_string(error)+( "; some files need deletion cleanup before recovery" if failed_rollback else "; previous saves restored")}
		detached.append({"from":target,"to":destination})
	var cleanup_error: String=""
	for entry in detached:
		var error: String=_erase(entry.to)
		if not error.is_empty(): cleanup_error=error
	return {"deleted":true,"error":cleanup_error}

func _rename(source: String, destination: String) -> Error:
	return DirAccess.rename_absolute(source,destination)

func _remove(path: String) -> Error:
	return DirAccess.remove_absolute(path)

func _erase(path: String) -> String:
	var parent: DirAccess=DirAccess.open(path.get_base_dir())
	if parent==null or parent.is_link(path.get_file()): return "Linked/unreadable deleted files retained; cleanup stopped"
	if DirAccess.dir_exists_absolute(path):
		var folder: DirAccess=DirAccess.open(path)
		if folder==null: return "Could not reopen deleted save folder"
		folder.include_hidden=true
		for name in folder.get_files():
			var error: String=_erase(path.path_join(name))
			if not error.is_empty(): return error
		for name in folder.get_directories():
			var error: String=_erase(path.path_join(name))
			if not error.is_empty(): return error
	var error: Error=_remove(path)
	return "" if error==OK else "Campaign/snapshot removed from its slot, but some files remain. Retry deletion cleanup: "+error_string(error)

func cleanup_paths(store: ColonyStore) -> Array[String]:
	var result: Array[String]=[]
	var directories: Array[String]=[store.root_directory]
	for number in range(1,6): directories.append(store.root_directory.path_join("slot-%d" % number))
	if store.root_directory==ColonyStore.CAMPAIGN_ROOT: directories.append("user://")
	for directory in directories:
		if not DirAccess.dir_exists_absolute(directory): continue
		for name in DirAccess.get_files_at(directory)+DirAccess.get_directories_at(directory):
			if _removed_name(name): result.append(directory.path_join(name))
	return result

func _removed_name(name: String) -> bool:
	if not name.begins_with(REMOVED_PREFIX): return false
	var parts: PackedStringArray=name.trim_prefix(REMOVED_PREFIX).split("-")
	return parts.size()==3 and parts[0].length()==32 and parts[0].is_valid_hex_number(false) and parts[1].is_valid_int() and int(parts[1]) in range(1,6) and parts[2].is_valid_int() and int(parts[2])>=0

func cleanup(store: ColonyStore) -> String:
	for path in cleanup_paths(store):
		var error: String=_erase(path)
		if not error.is_empty(): return error
	return ""
