class_name ColonyDelta
extends RefCounted
## Exact data patches. These never rerun simulation or discard saved history.
const MAX_RECORDS: int = 100000
const MAX_DEPTH: int = 32

static func make(before: Dictionary, after: Dictionary) -> Dictionary:
	return _diff(before,after)

static func restore(before: Dictionary, patch: Dictionary) -> Dictionary:
	var result: Dictionary = _apply(before.duplicate(true),patch,0)
	if result.has("error"): return result
	if not result.value is Dictionary: return {"error":"Delta root is not a world record"}
	return {"state":result.value}

static func _clone(value: Variant) -> Variant:
	return value.duplicate(true) if value is Dictionary or value is Array else value

static func _diff(before: Variant, after: Variant) -> Dictionary:
	if typeof(before)==typeof(after) and before==after: return {}
	if after is int: return {"set_int":str(after)}
	if before is Dictionary and after is Dictionary and not before.is_empty() and not after.is_empty():
		var changed: Dictionary = {}
		var erased: Dictionary = {}
		for key in before:
			if not after.has(key): erased[key]=true
		for key in after:
			var part: Dictionary = _diff(before.get(key),after[key])
			if not part.is_empty(): changed[key]=part
		return {"map":changed,"erase":erased}
	if before is Array and after is Array and not before.is_empty() and not after.is_empty() and _record_array(before) and _record_array(after):
		var previous: Dictionary = {}
		for record in before: previous[record.id]=record
		var prefix: int = 0
		while prefix<mini(before.size(),after.size()) and before[prefix].id==after[prefix].id: prefix+=1
		var tail: Array[int] = []
		var changed: Dictionary = {}
		for index in range(after.size()):
			var record: Dictionary = after[index]
			if index>=prefix: tail.append(record.id)
			if not previous.has(record.id) or previous[record.id]!=record: changed[record.id]=record.duplicate(true)
		return {"records":{"prefix":prefix,"tail_ids":tail,"changes":changed}}
	return {"set":_clone(after)}

static func _record_array(value: Array) -> bool:
	if value.size()>MAX_RECORDS: return false
	var ids: Dictionary = {}
	for record in value:
		if not record is Dictionary or not record.get("id") is int or record.id<=0 or ids.has(record.id): return false
		ids[record.id]=true
	return true

static func _apply(before: Variant, patch: Dictionary, depth: int) -> Dictionary:
	if depth>MAX_DEPTH: return {"error":"Delta nesting exceeds recovery bound"}
	if patch.is_empty(): return {"value":before}
	if patch.size()==1 and patch.has("set_int"):
		if not patch.set_int is String or patch.set_int.length()>20 or not patch.set_int.is_valid_int() or str(int(patch.set_int))!=patch.set_int: return {"error":"Invalid delta integer encoding"}
		return {"value":int(patch.set_int)}
	if patch.size()==1 and patch.has("set"):
		if patch.set==null or not (patch.set is Dictionary or patch.set is Array or patch.set is int or patch.set is String or patch.set is bool or patch.set is Vector2i): return {"error":"Unsupported delta value"}
		return {"value":_clone(patch.set)}
	if ColonyCodec._keys(patch,["map","erase"]):
		if not before is Dictionary or not patch.map is Dictionary or not patch.erase is Dictionary: return {"error":"Invalid dictionary delta"}
		for key in patch.erase:
			if not patch.erase[key] is bool or not patch.erase[key] or not before.has(key) or patch.map.has(key): return {"error":"Invalid delta field removal"}
			before.erase(key)
		for key in patch.map:
			if not (key is String or key is int) or not patch.map[key] is Dictionary: return {"error":"Invalid delta field update"}
			var result: Dictionary = _apply(before.get(key),patch.map[key],depth+1)
			if result.has("error"): return result
			before[key]=result.value
		return {"value":before}
	if ColonyCodec._keys(patch,["records"]):
		if not before is Array or not _record_array(before) or not patch.records is Dictionary: return {"error":"Invalid record-array delta"}
		var data: Dictionary = patch.records
		if not ColonyCodec._keys(data,["prefix","tail_ids","changes"]) or not data.prefix is int or data.prefix<0 or data.prefix>before.size() or not data.tail_ids is Array or data.prefix+data.tail_ids.size()>MAX_RECORDS or not data.changes is Dictionary: return {"error":"Invalid record-array delta bounds"}
		var available: Dictionary = {}
		for record in before: available[record.id]=record
		for id in data.changes:
			var record: Variant = data.changes[id]
			if not id is int or id<=0 or not record is Dictionary or record.get("id")!=id or not record.get("id") is int: return {"error":"Invalid delta record identity"}
			available[id]=record.duplicate(true)
		var order: Array = []
		for index in range(data.prefix): order.append(before[index].id)
		order.append_array(data.tail_ids)
		var seen: Dictionary = {}
		var records: Array = []
		for id in order:
			if not id is int or id<=0 or seen.has(id) or not available.has(id): return {"error":"Duplicate or missing delta record"}
			seen[id]=true;records.append(available[id])
		for id in data.changes:
			if not seen.has(id): return {"error":"Unused delta record update"}
		return {"value":records}
	return {"error":"Unknown delta operation"}
