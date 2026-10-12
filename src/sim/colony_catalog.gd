class_name ColonyCatalog
extends RefCounted
## I/O boundary. ColonyWorld receives validated immutable definitions as values.

static func load_data(path: String = "res://data/catalogs/colony_v2.json") -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "Missing colony catalog")
	var result: Dictionary = {"version": parsed.version, "content_hash": JSON.stringify(_integers(parsed),"",true).sha256_text()}
	for kind in ["items", "buildings", "resources", "recipes", "crops", "research", "animals", "enemies", "expeditions", "communities", "events", "charter"]:
		result[kind] = {}
		for definition: Dictionary in parsed.get(kind,[]):
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
