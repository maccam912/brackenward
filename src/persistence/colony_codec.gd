class_name ColonyCodec
extends RefCounted
const FORMAT: String = "brackenward-development-colony"
const MAX_BYTES: int = 64 * 1024 * 1024
const VERSION: int = 3

static func encode(world: ColonyWorld, snapshot_name: String = "", sequence: int = 0) -> PackedByteArray:
	var payload: String = JSON.stringify(ColonyState.pack(world.payload()), "", true)
	return JSON.stringify({"format": FORMAT, "version": VERSION, "content": ColonyWorld.CONTENT_VERSION,
		"content_hash":world.definitions.content_hash, "snapshot_name":snapshot_name, "engine": "4.7.2.ed1daf0bf", "generator_version":world.generator_version, "campaign_id":world.session_id, "sequence":str(sequence), "timestamp":Time.get_datetime_string_from_system(true), "payload": payload, "sha256": payload.sha256_text()}, "", true).to_utf8_buffer()

static func decode(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty() or bytes.size() > MAX_BYTES:
		return {"error": "Colony snapshot is empty or exceeds 64 MiB"}
	var parser: JSON = JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {"error": "Malformed colony snapshot"}
	var envelope: Dictionary = parser.data
	if (envelope.get("version") == 1 or envelope.get("version") == 2):
		var legacy: Dictionary = M2Codec.decode(bytes)
		if legacy.has("error"): return legacy
		return restore(ColonyMigrations.from_m2(legacy.world.payload(),ColonyCatalog.load_data().content_hash),legacy.get("snapshot_name",""),true)
	var keys: Array = ["format","version","content","content_hash","snapshot_name","engine","generator_version","campaign_id","sequence","timestamp","payload","sha256"]
	if not _keys(envelope,keys) or envelope.format != FORMAT or envelope.version != VERSION or envelope.content != ColonyWorld.CONTENT_VERSION:
		return {"error":"Unsupported save version/content: this build supports version 3 plus M1/M2 migration"}
	if not envelope.generator_version is float or envelope.generator_version != 0 or not envelope.campaign_id is String or not envelope.sequence is String or not envelope.sequence.is_valid_int() or envelope.sequence.length() > 15 or envelope.sequence.begins_with("-") or not envelope.timestamp is String or envelope.timestamp.length() > 40:
		return {"error":"Invalid snapshot metadata"}
	if not envelope.payload is String or not envelope.sha256 is String or envelope.payload.sha256_text() != envelope.sha256:
		return {"error": "Snapshot checksum mismatch"}
	if not envelope.get("snapshot_name","") is String or envelope.get("snapshot_name","").length() > 64:
		return {"error":"Invalid snapshot name"}
	if parser.parse(envelope.payload) != OK:
		return {"error": "Malformed simulation payload"}
	var decoded: Variant = ColonyState.unpack(parser.data)
	if not decoded is Dictionary:
		return {"error": "Invalid integer, coordinate or state encoding"}
	var data: Dictionary = decoded
	if envelope.content_hash != ColonyCatalog.load_data().content_hash or data.get("session_id") != envelope.campaign_id:
		return {"error":"Catalog or campaign identity mismatch; original save retained"}
	return restore(data,envelope.get("snapshot_name",""))

static func restore(data: Dictionary, snapshot_name: String = "", initialize_weather: bool = false) -> Dictionary:
	var world: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data())
	if initialize_weather and data.get("weather_state") == {}:
		# Only pure legacy migration supplies the empty initial schedule.
		world.tick = data.tick
		world.seed = data.seed
		world.weather = data.weather
		ColonyWeather.initialize(world)
		data.weather_state = world.weather_state.duplicate(true)
	var error: String = _validate(data, world)
	if not error.is_empty():
		return {"error": error}
	for field in data:
		if field not in ["content","content_hash"]:
			if data[field] is Array:
				world.get(field).assign(data[field])
			else:
				world.set(field, data[field])
	world.record_indexes.clear()
	var errors: Array[String] = world.invariant_errors()
	if not errors.is_empty():
		return {"error": "Invalid colony invariants: " + str(errors)}
	return {"world":world,"snapshot_name":snapshot_name}

static func _keys(record: Dictionary, keys: Array) -> bool:
	var actual: Array = record.keys().map(func(key: Variant) -> String: return str(key))
	actual.sort()
	var expected: Array = keys.map(func(key: Variant) -> String: return str(key))
	expected.sort()
	return actual == expected

static func _record(value: Variant, template: Dictionary) -> bool:
	if not value is Dictionary or not _keys(value, template.keys()):
		return false
	for key in template:
		if typeof(value[key]) != typeof(template[key]):
			return false
	return true

static func _validate(data: Dictionary, world: ColonyWorld) -> String:
	if not _record(data, world.payload()) or data.content != ColonyWorld.CONTENT_VERSION or data.content_hash != world.definitions.content_hash or data.tick < 1800 or data.seed < 0 or data.seed > 4294967295 or data.next_id > 1000000000 or data.next_command_id > 1000000000 or data.session_id.length() > 80 or data.schema_revision != 1 or data.generator_version != 0 or data.site_id != "meadow_reach" or not ColonyWeather.validate(data.weather_state,data.tick):
		return "Invalid world header or unknown fields"
	if data.citizens.size() != 4 or data.fields.size() > 16384 or data.structures.size() > 16384 or data.resources.size() > 16384 or data.stacks.size() > 100000 or data.jobs.size() > 100000 or data.pending_commands.size() > 4096 or data.facts.size() > 100000:
		return "Invalid record counts"
	if not ColonyWeather.valid_geometry(world,data.weather_state): return "Forecast flood coverage does not match saved geography"
	if not data.researched.all(func(value:Variant)->bool:return value is String and value in ["woodcraft","storecraft","farming","herbalism","weaving","masonry","metalwork","trailcraft","husbandry","signalcraft","commonlife","valley_charter"]) or data.weather not in ["clear","rain","fog","snow","drought","flood","cold_snap"]:
		return "Unknown research/weather state"
	for index in range(4):
		var citizen: Variant = data.citizens[index]
		if not _record(citizen, world.citizens[index]) or citizen.id != index + 1 or citizen.name.length() > 64:
			return "Invalid citizen schema"
		if not _keys(citizen.skills, ColonyWorld.SKILLS) or not _keys(citizen.xp, ColonyWorld.SKILLS) or not _keys(citizen.preferences, ColonyWorld.CATEGORIES) or not _keys(citizen.equipment, ["toolkit", "cloak", "weapon"]):
			return "Invalid skills/preferences/equipment"
		for skill in ColonyWorld.SKILLS:
			if not citizen.skills[skill] is int or citizen.skills[skill] < 0 or citizen.skills[skill] > 5 or not citizen.xp[skill] is int or citizen.xp[skill] < 0:
				return "Invalid skill values"
		for category in ColonyWorld.CATEGORIES:
			if not citizen.preferences[category] is int or citizen.preferences[category] not in [0, 1, 2, 3]:
				return "Invalid job preferences"
		if citizen.progress < 0 or citizen.progress > 9999 or citizen.edge_x < 0 or citizen.edge_x >= 128 or citizen.edge_y < 0 or citizen.edge_y >= 128 or citizen.health < 0 or citizen.health > 100:
			return "Invalid citizen movement/health"
		if citizen.hunger_rem < 0 or citizen.hunger_rem >= 7200 or citizen.rest_rem < 0 or citizen.rest_rem >= 300 or citizen.move_base_rem < 0 or citizen.move_base_rem >= 120 or citizen.move_rem < 0 or citizen.move_rem >= 1000 or citizen.injury_rem < 0 or citizen.injury_rem >= 1000 or citizen.travel_credit < 0 or citizen.travel_credit >= 10000 or citizen.starving_ticks < 0:
			return "Invalid need/movement remainder"
		if citizen.route_goal.size() not in [0, 2] or citizen.traits.size() != 2:
			return "Invalid route goal or traits"
		for coordinate in citizen.route_goal:
			if not coordinate is int or coordinate < 0 or coordinate >= 128:
				return "Invalid route goal"
		if citizen.shift not in ["Normal","Night shift"] or citizen.pending_shift not in ["","Normal","Night shift"]:
			return "Unknown work shift"
		for trait_name in citizen.traits:
			if not trait_name is String or trait_name not in ["Kind", "Homebody", "Steady", "Sociable", "Outdoorsy", "Restless", "Curious", "Private"]:
				return "Unknown trait"
		if citizen.equipment.toolkit not in ["", "toolkit", "forged_toolkit"] or citizen.equipment.cloak not in ["", "cloak"] or citizen.equipment.weapon not in ["", "spear", "bow"]:
			return "Unknown equipment"
		for point in citizen.route:
			if not point is Vector2i:
				return "Invalid route"
	for structure in data.structures:
		if not _record(structure, world.structures[0]) or (structure.definition != "supply_cart" and not world.definitions.buildings.has(structure.definition)) or structure.rotation not in [0, 1, 2, 3] or not _position(structure):
			return "Invalid structure"
		if structure.fuel < 0 or structure.fuel > 8:
			return "Invalid hearth fuel"
		for point in world.footprint(structure):
			if not ColonyWorld.inside(point):
				return "Building footprint outside map"
	for resource in data.resources:
		if not _record(resource, world.resources[0]) or not world.definitions.resources.has(resource.definition) or not _position(resource) or resource.remaining < 0:
			return "Invalid resource"
		if resource.remaining > world.definitions.resources[resource.definition].yield_count:
			return "Invalid remaining yield"
	for stack in data.stacks:
		if not _record(stack, world.stacks[0]) or not world.definitions.items.has(stack.item) or stack.count < 0 or stack.count > 100000 or not _position(stack) or stack.location not in ["ground", "store", "carry", "escrow", "output"] or stack.age < 0:
			return "Invalid item stack"
		for reservation in stack.reservations.values():
			if not reservation is int or reservation < 1:
				return "Invalid reservation"
	var job_template: Dictionary = world._job("gather", "Gathering", "Field", world.resources[0].id, Vector2i(1, 1), 1000)
	for job in data.jobs:
		if not _record(job, job_template) or job.kind not in ["gather", "haul", "cook", "build", "eat", "sleep", "prepare", "sow", "harvest", "replant", "leisure", "depart", "fuel"] or not _position(job) or job.work < 0 or job.work > job.required or job.worker < 0 or job.worker > 4 or job.state not in ["Ready", "Blocked", "Fetching", "Moving", "Working", "Delivering", "Complete", "Canceled"]:
			return "Invalid job"
		if job.kind == "build" and not world.definitions.buildings.has(job.definition):
			return "Unknown building definition"
		if job.kind == "build" and (job.inputs != world.definitions.buildings[job.definition].materials or job.required != world.definitions.buildings[job.definition].work_milli):
			return "Construction contract mismatch"
		if job.kind == "eat" and (job.required != 2000 or job.inputs.size() != 1):
			return "Eating contract mismatch"
		if job.kind == "cook":
			var food_count: int = 0
			for item in job.inputs:
				if item in world.definitions.recipes.cook_meals.alternatives and job.inputs[item] is int:
					food_count += job.inputs[item]
			if job.required != 8000 or job.output != {"meal": 2} or job.inputs.get("wood", 0) != 1 or food_count != 4:
				return "Cooking contract mismatch"
		for item in job.inputs:
			if not world.definitions.items.has(item) or not job.inputs[item] is int or job.inputs[item] < 1 or job.inputs[item] > 1000:
				return "Invalid job inputs"
		for item in job.output:
			if not world.definitions.items.has(item) or not job.output[item] is int or job.output[item] < 1 or job.output[item] > 50:
				return "Invalid job outputs"
		for worker in job.rate_remainders:
			var remainders: Variant = job.rate_remainders[worker]
			if not worker is int or worker < 1 or worker > 4 or not remainders is Array or remainders.size() != 4:
				return "Invalid work remainders"
			for remainder in remainders:
				if not remainder is int or remainder < 0 or remainder >= 1000:
					return "Invalid work remainders"
		for worker in job.pending_xp:
			if not worker is int or worker < 1 or worker > 4 or not job.pending_xp[worker] is int or job.pending_xp[worker] < 0:
				return "Invalid pending XP"
	for store in data.stores:
		if not _record(store, world.stores[0]) or store.capacity < 1 or store.capacity > 100000 or store.priority not in [1, 2, 3] or store.tiles.is_empty():
			return "Invalid storage"
		for point in store.tiles:
			if not point is Vector2i:
				return "Invalid stockpile tile"
		for item in store.filters:
			if not world.definitions.items.has(item):
				return "Unknown storage filter"
	for field in data.fields:
		var expected: Array = ["id", "crop", "x", "y", "prepared", "planted", "growth", "growth_rem", "ripe_tick", "yield_count", "fertility", "replant", "reason"]
		if not field is Dictionary or not _keys(field, expected) or not world.definitions.crops.has(field.get("crop", "")) or not _position(field):
			return "Invalid field schema"
		for key in ["id", "x", "y", "growth", "growth_rem", "ripe_tick", "yield_count", "fertility"]:
			if not field[key] is int or field[key] < 0:
				return "Invalid field values"
		if field.growth_rem >= 7200 or field.growth > world.definitions.crops[field.crop].growth or field.yield_count > world.definitions.crops[field.crop].yield_count or field.fertility not in [750,1000,1250]:
			return "Invalid crop growth"
		for key in ["prepared", "planted", "replant"]:
			if not field[key] is bool:
				return "Invalid field flags"
	if not _keys(data.ledger, ["produced", "consumed", "spoiled"]):
		return "Invalid inventory ledger"
	for entries in data.ledger.values():
		if not entries is Dictionary:
			return "Invalid inventory ledger"
		for item in entries:
			if not world.definitions.items.has(item) or not entries[item] is int or entries[item] < 0:
				return "Invalid inventory ledger"
	for command in data.pending_commands:
		if not command is Dictionary or not _keys(command, ["id", "session", "kind", "args"]) or not command.id is int or command.id < 1 or not command.session is String or not command.kind is String or not command.args is Dictionary:
			return "Invalid pending command"
		# Preserve only commands generated by the concrete development UI.
		var schemas: Dictionary = {"stockpile": ["tiles"], "build": ["definition", "x", "y", "rotation"], "gather": ["target"], "gather_area": ["definition", "tiles"], "cancel": ["target"], "preference": ["citizen", "category", "value"], "food_policy": ["enabled"], "field": ["tiles", "crop"], "schedule": ["citizen", "shift"], "priority": ["target", "value"], "clear_field": ["target"], "early_harvest": ["target"], "stock_filter": ["target", "filters", "priority"], "pin": ["target", "citizen"]}
		if not schemas.has(command.kind) or not _keys(command.args, schemas[command.kind]):
			return "Unknown pending command arguments"
		for key in command.args:
			var value: Variant = command.args[key]
			if key in ["target", "citizen", "x", "y", "rotation", "value", "priority"] and not value is int:
				return "Invalid command quantity"
			if key in ["definition", "category", "crop", "shift"] and not value is String:
				return "Invalid command definition"
			if key == "enabled" and not value is bool:
				return "Invalid policy toggle"
			if key == "filters" and (not value is Array or not value.all(func(item: Variant)->bool:return item is String and world.definitions.items.has(item))):
				return "Invalid storage filter"
			if key == "tiles":
				if not value is Array or value.size() > 16384:
					return "Invalid command tiles"
				for point in value:
					if not point is Vector2i:
						return "Invalid command tiles"
	for fact in data.facts:
		if not fact is Dictionary or not _keys(fact, ["tick", "actor", "job", "kind", "text"]) or not fact.tick is int or not fact.actor is int or not fact.job is int or not fact.text is String or not fact.kind is String:
			return "Invalid journal fact"
	return ""

static func _position(record: Dictionary) -> bool:
	return record.get("x") is int and record.get("y") is int and record.x >= 0 and record.y >= 0 and record.x < 128 and record.y < 128
