class_name ColonyMigrations
extends RefCounted
## Pure forward migrations. M1 first advances through the frozen M2 migrator.
static func from_m2(data: Dictionary, content_hash: String) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	result.content = ColonyWorld.CONTENT_VERSION
	result.content_hash = content_hash
	result["schema_revision"] = 1
	result["generator_version"] = 0
	result["site_id"] = "meadow_reach"
	result["weather_state"] = {}
	for citizen in result.citizens: citizen["move_base_rem"] = 0
	return result
