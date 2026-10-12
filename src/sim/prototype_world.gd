class_name PrototypeWorld
extends RefCounted
## M0 fixture, deliberately separate from the later colony simulation/save format.

const SIZE: int = 128
const CONTENT_VERSION: String = "m0-touch-1"
var tick: int = 1800
var seed: int = 104729
var session_id: String = "m0-local"
var next_command_id: int = 1
var citizens: Array[Dictionary] = []
var designations: Array[Vector2i] = []
var receipts: Dictionary = {}
var pending_commands: Array[Dictionary] = []

func _init() -> void:
	for i in range(4):
		citizens.append({"id": i + 1, "name": ["Mira", "Oren", "Tavi", "Sela"][i],
			"x": 65 + i, "y": 65, "progress": 0, "direction": 1, "steps": 0})

func queue_designation(tiles: Array[Vector2i], command_id: int = 0, expected_session: String = "") -> int:
	var id: int = command_id if command_id > 0 else next_command_id
	next_command_id = maxi(next_command_id, id + 1)
	pending_commands.append({"id": id, "session": session_id if expected_session.is_empty() else expected_session, "tiles": tiles.duplicate()})
	return id

func step() -> void:
	tick += 1
	pending_commands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	for command in pending_commands:
		if receipts.has(command.id):
			continue
		var reason: String = "accepted"
		if command.session != session_id:
			reason = "wrong_session"
		else:
			for tile: Vector2i in command.tiles:
				if not inside(tile) or is_water(tile):
					reason = "invalid_tile"
					break
		if reason == "accepted":
			for tile: Vector2i in command.tiles:
				if not designations.has(tile):
					designations.append(tile)
			designations.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y * SIZE + a.x < b.y * SIZE + b.x)
		receipts[command.id] = reason
	pending_commands.clear()
	for citizen in citizens:
		citizen.progress += 1000
		if citizen.progress >= 10000:
			citizen.progress -= 10000
			citizen.x += citizen.direction
			citizen.steps += 1
			if citizen.steps == 5:
				citizen.steps = 0
				citizen.direction *= -1

static func inside(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < SIZE and tile.y < SIZE

static func is_water(tile: Vector2i) -> bool:
	return tile.x >= 32 and tile.x <= 35 and tile.y != 63 and tile.y != 64

func payload() -> Dictionary:
	var tiles: Array = []
	for tile in designations:
		tiles.append([tile.x, tile.y])
	var saved_citizens: Array = []
	for citizen in citizens:
		var record: Dictionary = citizen.duplicate(true)
		record.id = str(record.id)
		saved_citizens.append(record)
	var saved_receipts: Dictionary = {}
	for id: int in receipts:
		saved_receipts[str(id)] = receipts[id]
	var pending: Array = []
	for command in pending_commands:
		var command_tiles: Array = []
		for tile: Vector2i in command.tiles:
			command_tiles.append([tile.x, tile.y])
		pending.append({"id": str(command.id), "session": command.session, "tiles": command_tiles})
	return {"content": CONTENT_VERSION, "tick": str(tick), "seed": str(seed), "session_id": session_id,
		"next_command_id": str(next_command_id), "citizens": saved_citizens, "designations": tiles,
		"receipts": saved_receipts, "pending": pending}

func canonical_hash() -> String:
	return JSON.stringify(payload(), "", true).sha256_text()
