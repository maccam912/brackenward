class_name ColonyOwnedJson
extends RefCounted
## Consumes only fresh private JSON parser containers. Retains String key types/order.
## Each load has a bounded pool; no global cache or live-world/capture aliases.
const MAX_KEYS: int=2048
const MAX_RECORD_KEYS: int=128

static func unpack(value: Variant, field: String="", depth: int=0) -> Variant:
	return _unpack(value,field,depth,{})

static func _unpack(value: Variant, field: String, depth: int, pool: Dictionary) -> Variant:
	if depth>32:return null
	if value is Dictionary:
		if value.is_read_only():return null
		if value.has("$tile"):return ColonyState.unpack(value,field,depth)
		if value.has("$map"):
			if value.size()!=1 or not value["$map"] is Array:return null
			var pairs: Array=value["$map"];value.clear()
			for pair in pairs:
				if not pair is Array or pair.size()!=2:return null
				var key: Variant=ColonyState.unpack(pair[0],"id",depth+1)
				var item: Variant=_unpack(pair[1],"",depth+1,pool)
				if key==null or item==null or value.has(key):return null
				value[key]=item
			return value
		if value.size()<=MAX_RECORD_KEYS:
			var keys: Array=value.keys();var items: Array=value.values()
			value.clear()
			for index in range(keys.size()):
				var key: String=keys[index]
				var item: Variant=_unpack(items[index],key,depth+1,pool)
				if item==null:return null
				var shared: Variant=pool.get(key)
				if shared==null:
					shared=key
					if pool.size()<MAX_KEYS:pool[key]=key
				value[shared]=item
		else:
			for key in value:
				var item: Variant=_unpack(value[key],key,depth+1,pool)
				if item==null:return null
				value[key]=item
		return value
	if value is Array:
		if value.is_read_only():return null
		for index in range(value.size()):
			var item: Variant=_unpack(value[index],field,depth+1,pool)
			if item==null:return null
			value[index]=item
		return value
	return ColonyState.unpack(value,field,depth)
