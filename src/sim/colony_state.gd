class_name ColonyState
extends RefCounted
## JSON-safe representation preserving integer-keyed maps and exact runtime IDs.
const IDS: Array[String] = ["id", "target", "worker", "source", "destination", "owner", "job", "bed", "actor", "tick", "next_id", "next_command_id", "created", "retry", "regrow_at", "ripe_tick", "bed_memory_until", "raw_memory_until", "preferred_memory_until", "break_until", "break_cooldown", "departure_until", "pinned_job", "leisure_memory_until", "warm_until"]

static func pack(value: Variant, field: String = "") -> Variant:
	if value is Vector2i:
		return {"$tile": [value.x, value.y]}
	if value is int and field in IDS:
		return str(value)
	if value is Dictionary:
		var result: Dictionary = {}
		if not value.is_empty() and value.keys()[0] is int:
			var pairs: Array = []
			var keys: Array = value.keys()
			keys.sort()
			for key: int in keys:
				pairs.append([str(key), pack(value[key])])
			return {"$map": pairs}
		for key in value:
			result[key] = pack(value[key], key)
		return result
	if value is Array:
		return value.map(func(item: Variant) -> Variant: return pack(item, field))
	return value

static func unpack(value: Variant, field: String = "", depth: int = 0) -> Variant:
	if depth > 32:
		return null
	if value is String and field in IDS:
		if value.is_empty() or not value.is_valid_int() or value.begins_with("-") or value.begins_with("+") or (value.length() > 1 and value.begins_with("0")) or value.length() > 15:
			return null
		return int(value)
	if value is float:
		return int(value) if value == floor(value) and absf(value) < 9007199254740992.0 else null
	if value is Dictionary:
		if value.has("$tile"):
			if value.size() != 1 or not value["$tile"] is Array or value["$tile"].size() != 2:
				return null
			var x: Variant = unpack(value["$tile"][0], "", depth + 1)
			var y: Variant = unpack(value["$tile"][1], "", depth + 1)
			return Vector2i(x, y) if x is int and y is int and x >= 0 and x < 128 and y >= 0 and y < 128 else null
		if value.has("$map"):
			if value.size() != 1 or not value["$map"] is Array:
				return null
			var result: Dictionary = {}
			for pair: Variant in value["$map"]:
				if not pair is Array or pair.size() != 2:
					return null
				var key: Variant = unpack(pair[0], "id", depth + 1)
				var item: Variant = unpack(pair[1], "", depth + 1)
				if key == null or item == null or result.has(key):
					return null
				result[key] = item
			return result
		var result: Dictionary = {}
		for key in value:
			var item: Variant = unpack(value[key], key, depth + 1)
			if item == null:
				return null
			result[key] = item
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			var decoded: Variant = unpack(item, field, depth + 1)
			if decoded == null:
				return null
			result.append(decoded)
		return result
	return value if value is String or value is bool or value is int else null
