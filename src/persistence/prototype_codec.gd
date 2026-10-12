class_name PrototypeCodec
extends RefCounted

const MAX_BYTES: int = 1024 * 1024
const FORMAT: String = "brackenward-m0"

static func encode(world: PrototypeWorld) -> PackedByteArray:
	var payload: String = JSON.stringify(world.payload(), "", true)
	return JSON.stringify({"format": FORMAT, "version": 1, "payload": payload,
		"sha256": payload.sha256_text()}, "", true).to_utf8_buffer()

static func decode(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty() or bytes.size() > MAX_BYTES:
		return {"error": "Invalid file size (limit 1 MiB for the touch prototype)."}
	var parser: JSON = JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK:
		return {"error": "Invalid JSON save envelope."}
	var envelope: Variant = parser.data
	if not envelope is Dictionary or not _keys(envelope, ["format", "version", "payload", "sha256"]):
		return {"error": "Invalid save envelope."}
	if envelope.format != FORMAT or envelope.version != 1:
		return {"error": "This build reads only M0 touch-prototype saves, version 1."}
	if not envelope.payload is String or not envelope.sha256 is String or envelope.payload.sha256_text() != envelope.sha256:
		return {"error": "Save checksum does not match. Original file is unchanged."}
	if parser.parse(envelope.payload) != OK:
		return {"error": "Invalid JSON prototype payload."}
	var data: Variant = parser.data
	if not data is Dictionary or not _keys(data, ["content", "tick", "seed", "session_id", "next_command_id", "citizens", "designations", "receipts", "pending"]):
		return {"error": "Invalid prototype state."}
	if data.content != PrototypeWorld.CONTENT_VERSION or not data.session_id is String or data.session_id.length() > 64 or data.session_id.is_empty():
		return {"error": "Incompatible prototype content or session."}
	if not _decimal(data.tick, 1800, 2147483647) or not _decimal(data.seed, 0, 4294967295) or not _decimal(data.next_command_id, 1, 2147483647):
		return {"error": "Invalid clock, seed, or sequence."}
	if not data.citizens is Array or data.citizens.size() != 4:
		return {"error": "The prototype requires four travelers."}
	var ids: Dictionary = {}
	for citizen: Variant in data.citizens:
		if not citizen is Dictionary or not _keys(citizen, ["id", "name", "x", "y", "progress", "direction", "steps"]):
			return {"error": "Invalid traveler record."}
		if not _decimal(citizen.id, 1, 4) or ids.has(citizen.id) or not citizen.name is String or citizen.name != ["Mira", "Oren", "Tavi", "Sela"][int(citizen.id) - 1]:
			return {"error": "Invalid traveler identity."}
		ids[citizen.id] = true
		if not _integer(citizen.x, 0, 127) or not _integer(citizen.y, 0, 127) or not _integer(citizen.progress, 0, 9999) or not _integer(citizen.steps, 0, 4) or not _integer(citizen.direction, -1, 1) or int(citizen.direction) == 0:
			return {"error": "Invalid traveler position."}
		if PrototypeWorld.is_water(Vector2i(citizen.x, citizen.y)):
			return {"error": "Traveler on impassable water."}
	if not _tiles(data.designations) or not data.receipts is Dictionary or data.receipts.size() > 4096 or not data.pending is Array or data.pending.size() > 128:
		return {"error": "Invalid designation or command counts."}
	for id: Variant in data.receipts:
		if not _decimal(id, 1, int(data.next_command_id) - 1) or not data.receipts[id] in ["accepted", "wrong_session", "invalid_tile"]:
			return {"error": "Invalid command receipt."}
	for command: Variant in data.pending:
		if not command is Dictionary or not _keys(command, ["id", "session", "tiles"]) or not _decimal(command.id, 1, int(data.next_command_id) - 1) or not command.session is String or command.session.length() > 64 or not _tiles(command.tiles):
			return {"error": "Invalid pending command."}
	var world: PrototypeWorld = PrototypeWorld.new()
	world.tick = int(data.tick)
	world.seed = int(data.seed)
	world.session_id = data.session_id
	world.next_command_id = int(data.next_command_id)
	world.citizens.clear()
	for record: Dictionary in data.citizens:
		var citizen: Dictionary = record.duplicate(true)
		for key in ["id", "x", "y", "progress", "direction", "steps"]:
			citizen[key] = int(citizen[key])
		world.citizens.append(citizen)
	world.citizens.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	for tile: Array in data.designations:
		world.designations.append(Vector2i(tile[0], tile[1]))
	for id: String in data.receipts:
		world.receipts[int(id)] = data.receipts[id]
	for command: Dictionary in data.pending:
		var tiles: Array[Vector2i] = []
		for tile: Array in command.tiles:
			tiles.append(Vector2i(tile[0], tile[1]))
		world.pending_commands.append({"id": int(command.id), "session": command.session, "tiles": tiles})
	return {"world": world}

static func _keys(data: Dictionary, keys: Array) -> bool:
	return data.size() == keys.size() and keys.all(func(key: String) -> bool: return data.has(key))

static func _integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func _decimal(value: Variant, low: int, high: int) -> bool:
	if not value is String or value.is_empty() or value.length() > 10 or not value.is_valid_int():
		return false
	return str(int(value)) == value and int(value) >= low and int(value) <= high

static func _tiles(value: Variant) -> bool:
	if not value is Array or value.size() > 16384:
		return false
	var seen: Dictionary = {}
	for tile: Variant in value:
		if not tile is Array or tile.size() != 2 or not _integer(tile[0], 0, 127) or not _integer(tile[1], 0, 127):
			return false
		var point: Vector2i = Vector2i(tile[0], tile[1])
		if PrototypeWorld.is_water(point) or seen.has(point):
			return false
		seen[point] = true
	return true
