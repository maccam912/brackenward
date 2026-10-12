# Frozen M1 compatibility implementation. Never rebalance this replay version.
class_name M1Codec
extends RefCounted
const FORMAT: String = "brackenward-development-colony"
const MAX_BYTES: int = 64 * 1024 * 1024
const VERSION: int = 1

static func encode(world: M1World) -> PackedByteArray:
	var payload: String = JSON.stringify(ColonyState.pack(world.payload()), "", true)
	return JSON.stringify({"format": FORMAT, "version": VERSION, "content": M1World.CONTENT_VERSION,
		"engine": "4.7.2.ed1daf0bf", "payload": payload, "sha256": payload.sha256_text()}, "", true).to_utf8_buffer()

static func decode(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty() or bytes.size() > MAX_BYTES:
		return {"error": "Colony snapshot is empty or exceeds 64 MiB"}
	var parser: JSON = JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {"error": "Malformed colony snapshot"}
	var envelope: Dictionary = parser.data
	if not _keys(envelope, ["format", "version", "content", "engine", "payload", "sha256"]) or envelope.format != FORMAT or envelope.version != VERSION or envelope.content != M1World.CONTENT_VERSION:
		return {"error": "Unsupported development save format/content. M0 touch fixtures remain separate."}
	if not envelope.payload is String or not envelope.sha256 is String or envelope.payload.sha256_text() != envelope.sha256:
		return {"error": "Snapshot checksum mismatch"}
	if parser.parse(envelope.payload) != OK:
		return {"error": "Malformed simulation payload"}
	var decoded: Variant = ColonyState.unpack(parser.data)
	if not decoded is Dictionary:
		return {"error": "Invalid integer, coordinate or state encoding"}
	var data: Dictionary = decoded
	var world: M1World = M1World.new(M1Catalog.load_data())
	var error: String = _validate(data, world)
	if not error.is_empty():
		return {"error": error}
	for field in data:
		if field != "content":
			if data[field] is Array:
				world.get(field).assign(data[field])
			else:
				world.set(field, data[field])
	var errors: Array[String] = world.invariant_errors()
	if not errors.is_empty():
		return {"error": "Invalid colony invariants: " + str(errors)}
	return {"world": world}

static func _keys(record: Dictionary, keys: Array) -> bool:
	var actual: Array = record.keys()
	actual.sort()
	var expected: Array = keys.duplicate()
	expected.sort()
	return actual == expected

static func _record(value: Variant, template: Dictionary) -> bool:
	if not value is Dictionary or not _keys(value, template.keys()):
		return false
	for key in template:
		if typeof(value[key]) != typeof(template[key]):
			return false
	return true

static func _validate(data: Dictionary, world: M1World) -> String:
	if not _record(data, world.payload()) or data.content != M1World.CONTENT_VERSION or data.tick < 1800 or data.seed < 0 or data.seed > 4294967295 or data.next_id > 1000000000 or data.next_command_id > 1000000000 or data.session_id.length() > 80:
		return "Invalid world header or unknown fields"
	if data.citizens.size() != 4 or data.structures.size() > 16384 or data.resources.size() > 16384 or data.stacks.size() > 100000 or data.jobs.size() > 100000 or data.pending_commands.size() > 4096 or data.facts.size() > 100000:
		return "Invalid record counts"
	for index in range(4):
		var citizen: Variant = data.citizens[index]
		if not _record(citizen, world.citizens[index]) or citizen.id != index + 1 or citizen.name.length() > 64:
			return "Invalid citizen schema"
		if not _keys(citizen.skills, M1World.SKILLS) or not _keys(citizen.xp, M1World.SKILLS) or not _keys(citizen.preferences, M1World.CATEGORIES) or not _keys(citizen.equipment, ["toolkit", "cloak", "weapon"]):
			return "Invalid skills/preferences/equipment"
		for skill in M1World.SKILLS:
			if not citizen.skills[skill] is int or citizen.skills[skill] < 0 or citizen.skills[skill] > 5 or not citizen.xp[skill] is int or citizen.xp[skill] < 0:
				return "Invalid skill values"
		for category in M1World.CATEGORIES:
			if not citizen.preferences[category] is int or citizen.preferences[category] not in [0, 1, 2, 3]:
				return "Invalid job preferences"
		if citizen.progress < 0 or citizen.progress > 9999 or citizen.edge_x < 0 or citizen.edge_x >= 128 or citizen.edge_y < 0 or citizen.edge_y >= 128 or citizen.health < 0 or citizen.health > 100:
			return "Invalid citizen movement/health"
		if citizen.hunger_rem < 0 or citizen.hunger_rem >= 7200 or citizen.rest_rem < 0 or citizen.rest_rem >= 300 or citizen.move_rem < 0 or citizen.move_rem >= 1000 or citizen.injury_rem < 0 or citizen.injury_rem >= 1000 or citizen.travel_credit < 0 or citizen.travel_credit >= 10000 or citizen.starving_ticks < 0:
			return "Invalid need/movement remainder"
		if citizen.route_goal.size() not in [0, 2] or citizen.traits.size() != 2:
			return "Invalid route goal or traits"
		for coordinate in citizen.route_goal:
			if not coordinate is int or coordinate < 0 or coordinate >= 128:
				return "Invalid route goal"
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
			if not M1World.inside(point):
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
		if not _record(job, job_template) or job.kind not in ["gather", "haul", "cook", "build", "eat", "sleep"] or not _position(job) or job.work < 0 or job.work > job.required or job.worker < 0 or job.worker > 4 or job.state not in ["Ready", "Blocked", "Fetching", "Moving", "Working", "Delivering", "Complete", "Canceled"]:
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
		var schemas: Dictionary = {"stockpile": ["tiles"], "build": ["definition", "x", "y", "rotation"], "gather": ["target"], "cancel": ["target"], "preference": ["citizen", "category", "value"], "food_policy": ["enabled"]}
		if not schemas.has(command.kind) or not _keys(command.args, schemas[command.kind]):
			return "Unknown pending command arguments"
		for key in command.args:
			var value: Variant = command.args[key]
			if key in ["target", "citizen", "x", "y", "rotation", "value"] and not value is int:
				return "Invalid command quantity"
			if key in ["definition", "category"] and not value is String:
				return "Invalid command definition"
			if key == "enabled" and not value is bool:
				return "Invalid policy toggle"
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
	return record.x >= 0 and record.y >= 0 and record.x < 128 and record.y < 128
