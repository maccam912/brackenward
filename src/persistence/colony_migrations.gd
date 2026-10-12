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

static func upgrade_current(data: Dictionary, template: ColonyWorld) -> Dictionary:
	if data.get("schema_revision") != 1: return data
	var header: Dictionary = template.payload().duplicate()
	header.erase("social_state")
	if not ColonyCodec._record(data,header) or data.citizens.size() != 4: return data
	var citizen_template: Dictionary = template.citizens[0].duplicate()
	for key in ColonySocial.citizen_defaults(): citizen_template.erase(key)
	for citizen in data.citizens:
		if not ColonyCodec._record(citizen,citizen_template): return data
	var result: Dictionary = data.duplicate(true)
	result.schema_revision = 2
	for citizen in result.citizens:
		for key in ColonySocial.citizen_defaults(): citizen[key] = ColonySocial.citizen_defaults()[key]
	for job in result.jobs:
		if not job is Dictionary: return data
		job["worker_days"] = {}
	result["social_state"] = ColonySocial.initial_state(result.citizens,result.tick)
	return result
