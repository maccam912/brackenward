class_name ColonyCapture
extends RefCounted
## Reuse owned immutable records; no mutable simulation tree crosses threads.
const TABLES: Array[String] = ["citizens","structures","resources","stacks","jobs","stores","fields"]
const BLOCK_SIZE: int = 256
var world_id: int = 0
var previous: Dictionary = {}
var tables: Dictionary = {}

func capture(world: ColonyWorld, retired: Array) -> Dictionary:
	if world_id!=world.get_instance_id():
		retired.append(previous);retired.append(tables)
		previous={};tables={};world_id=world.get_instance_id()
	var source: Dictionary = world.payload()
	var result: Dictionary = {}
	for field in source:
		if field in TABLES:
			result[field]=_records(field,source[field],retired)
		elif field=="chronicle_state":
			var chronicle: Dictionary = {}
			var old: Dictionary = previous.get(field,{})
			for key in source[field]:
				chronicle[key]=_records("chronicle_facts",source[field][key],retired) if key=="facts" else _reuse(source[field][key],old.get(key))
			chronicle.make_read_only();result[field]=chronicle
		else:
			result[field]=_reuse(source[field],previous.get(field))
	result.make_read_only()
	retired.append(previous);previous=result
	return result

func _records(name: String, source: Array, retired: Array) -> Array:
	var old: Dictionary = tables.get(name,{"records":[],"blocks":[]})
	var blocks: Array = []
	var result: Array = []
	var by_id: Dictionary = {}
	var indexed: bool = false
	for start in range(0,source.size(),BLOCK_SIZE):
		var block: Array = source.slice(start,mini(start+BLOCK_SIZE,source.size()))
		var block_index: int = start/BLOCK_SIZE
		if block_index<old.blocks.size() and block==old.blocks[block_index]:
			# Native block equality skips hundreds of script calls for old history.
			block=old.blocks[block_index]
		else:
			for offset in range(block.size()):
				var record: Dictionary = block[offset]
				var index: int = start+offset
				var candidate: Variant = old.records[index] if index<old.records.size() else null
				if candidate!=null and candidate.id!=record.id:
					if not indexed:
						for previous_record in old.records: by_id[previous_record.id]=previous_record
						indexed=true
					candidate=by_id.get(record.id)
				block[offset]=_reuse(record,candidate)
			block.make_read_only()
		blocks.append(block);result.append_array(block)
	result.make_read_only()
	blocks.make_read_only()
	retired.append(old);tables[name]={"records":result,"blocks":blocks}
	return result

static func _reuse(source: Variant, old: Variant) -> Variant:
	if typeof(source)==typeof(old) and source==old: return old
	if not (source is Dictionary or source is Array): return source
	var owned: Variant = source.duplicate(true)
	_freeze(owned)
	return owned

static func _freeze(owned: Variant) -> void:
	if owned is Dictionary:
		for key in owned: _freeze(owned[key])
		owned.make_read_only()
	elif owned is Array:
		for value in owned: _freeze(value)
		owned.make_read_only()
