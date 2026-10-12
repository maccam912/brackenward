class_name ColonyMigrations
extends RefCounted
## Pure forward migration from the publicly downloadable M1 development snapshot.
static func from_m1(data: Dictionary, content_hash: String) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	result.content = "m2-survival-1"
	result["content_hash"] = content_hash
	result.fields = []
	result.researched = []
	result.weather = "clear"
	for citizen in result.citizens:
		for field in ["leisure_ticks", "leisure_day", "bed_sleep_ticks", "bed_memory_until", "raw_memory_until", "preferred_work", "preferred_memory_until", "food_tags_day", "break_clock", "break_until", "break_cooldown", "departure_clock", "departure_until", "pinned_job", "yesterday_leisure", "leisure_memory_until", "warm_until"]:
			citizen[field] = 0
		citizen.shift = "Normal"
		citizen.pending_shift = ""
		citizen.mood_terms = {}
		citizen.food_tags = []
		citizen.departed = false
	for structure in result.structures:
		structure.heat_ticks = 0
	return result
