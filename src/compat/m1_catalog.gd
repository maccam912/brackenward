# Frozen M1 compatibility implementation. Never rebalance this replay version.
class_name M1Catalog
extends RefCounted
## I/O boundary. M1World receives validated immutable definitions as values.

static func load_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalogs/m1.json"))
	assert(parsed is Dictionary, "Missing M1 catalog")
	var result: Dictionary = {"version": parsed.version}
	for kind in ["items", "buildings", "resources", "recipes"]:
		result[kind] = {}
		for definition: Dictionary in parsed[kind]:
			result[kind][definition.id] = _integers(definition)
	return result

static func _integers(value: Variant) -> Variant:
	if value is float:
		assert(value == floor(value))
		return int(value)
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[key] = _integers(value[key])
		return result
	if value is Array:
		return value.map(_integers)
	return value
