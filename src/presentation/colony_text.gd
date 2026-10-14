class_name ColonyText
extends RefCounted
## English presentation messages. Never rewrite names, facts, saves or command IDs.
static var messages: Dictionary = {}

static func catalog() -> Dictionary:
	if messages.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalogs/en_ui.json"))
		if not parsed is Dictionary: push_error("Invalid UI message catalog");return {}
		messages=parsed
	return messages

static func text(key: String, values: Dictionary = {}) -> String:
	var entry: Variant = catalog().get(key)
	if not entry is String:
		push_error("Missing UI text key: "+key);return key
	return format_template(entry,values)

static func plural(key: String, count: int, values: Dictionary = {}) -> String:
	var entry: Variant = catalog().get(key)
	if not entry is Dictionary or not entry.has("one") or not entry.has("other"):
		push_error("Missing UI plural key: "+key);return key
	var parameters: Dictionary = values.duplicate()
	parameters.count=count
	return format_template(entry.one if count==1 else entry.other,parameters)

static func format_template(template: String, values: Dictionary) -> String:
	# Substitute only tokens from the template. A user's braces in an inserted
	# name/note remain literal even when another parameter has the same name.
	var result: String = "";var cursor: int = 0
	while true:
		var opening: int = template.find("{",cursor)
		if opening<0: return result+template.substr(cursor)
		var closing: int = template.find("}",opening+1)
		if closing<0: push_error("Unclosed UI message parameter");return template
		var parameter: String = template.substr(opening+1,closing-opening-1)
		if not values.has(parameter): push_error("Missing UI message parameter: "+parameter);return template
		result+=template.substr(cursor,opening-cursor)+str(values[parameter])
		cursor=closing+1
	return result
