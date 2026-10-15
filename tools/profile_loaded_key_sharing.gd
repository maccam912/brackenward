extends SceneTree
## Read-only input attribution probe; never called by the game or save loader.
## Rekeys one isolated decoded world to share String buffers without changing types/order.
func _initialize() -> void:call_deferred("run")

func state_text(world: ColonyWorld) -> String:
	return JSON.stringify(ColonyState.pack(world.payload()),"",false)

func share_keys(value: Variant, pool: Dictionary, stats: Dictionary, depth: int=0) -> void:
	if depth>32:stats.depth_limit+=1;return
	if value is Dictionary:
		stats.dictionaries+=1
		if value.is_read_only():stats.read_only+=1;return
		var keys: Array=value.keys()
		if keys.size()<=128 and keys.all(func(key:Variant)->bool:return key is String):
			var replacements: Array=[];var items: Array=[]
			for key: String in keys:
				items.append(value[key]);stats.string_key_slots+=1
				if pool.has(key):
					replacements.append(pool[key]);stats.shared_slots+=1
				else:
					replacements.append(key)
					if pool.size()<2048:pool[key]=key
			# Reinsert every key in its original order, retaining all value/container identities.
			for key: String in keys:value.erase(key)
			for index in range(keys.size()):value[replacements[index]]=items[index]
		else:stats.skipped_key_sets+=1
		for child in value.values():share_keys(child,pool,stats,depth+1)
	elif value is Array:
		stats.arrays+=1
		if value.is_read_only():stats.read_only+=1;return
		for child in value:share_keys(child,pool,stats,depth+1)

func apply_sharing(world: ColonyWorld) -> Dictionary:
	var pool: Dictionary={}
	var stats: Dictionary={"dictionaries":0,"arrays":0,"read_only":0,"depth_limit":0,"string_key_slots":0,"shared_slots":0,"skipped_key_sets":0}
	share_keys(world.payload(),pool,stats)
	stats.pool_keys=pool.size()
	return stats

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not FileAccess.file_exists(args[0]) or FileAccess.file_exists(args[1]):printerr("Usage: -- SNAPSHOT NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprints();var input_sha: String=FileAccess.get_sha256(args[0])
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"):printerr(decoded);quit(2);return
	var world: ColonyWorld=decoded.world;decoded={}
	var expected: String=state_text(world);var canonical: String=world.canonical_hash()
	var before: int=OS.get_static_memory_usage();var started: int=Time.get_ticks_usec()
	var stats: Dictionary=apply_sharing(world)
	var elapsed: int=Time.get_ticks_usec()-started;var after: int=OS.get_static_memory_usage()
	var exact: bool=state_text(world)==expected and world.canonical_hash()==canonical and world.invariant_errors().is_empty()
	var unchanged: bool=source==fingerprints() and input_sha==FileAccess.get_sha256(args[0])
	var report: Dictionary={"passed":exact and unchanged and stats.depth_limit==0,"source":source,"input_sha256":input_sha,"canonical_hash":canonical,"engine_heap_before_bytes":before,"engine_heap_after_bytes":after,"engine_heap_change_bytes":after-before,"elapsed_us":elapsed,"statistics":stats,"complete_unsorted_state_text_equal":exact,"input_and_source_unchanged":unchanged,"engine":Engine.get_version_info().string,"scope":"Attribution probe only, no production pooling. One isolated decoded world rekeys String keys through a per-operation2048-key pool; integer/mixed/large/readonly key sets unchanged. Every value/type/container and key insertion order retained. Flat unsorted serialized baseline retains no key buffers; pool/transient containers released before ending heap read. Full canonical/state/invariants and immutable input/source checked afterward. Contended desktop engine heap, not Android PSS or a loader CPU comparison."}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if report.passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","toolchain.lock.json","tools/profile_loaded_key_sharing.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	for folder in ["src","data/catalogs"]:collect("res://"+folder,result)
	return result

func collect(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["gd","json"]:result[folder.path_join(file)]=FileAccess.get_sha256(folder.path_join(file))
	for subdirectory in DirAccess.get_directories_at(folder):collect(folder.path_join(subdirectory),result)
