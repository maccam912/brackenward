class_name M2Rooms
extends RefCounted

static func compute(world: M2World) -> Dictionary:
	var boundaries: Dictionary = {}
	for structure in world.structures:
		if structure.definition != "supply_cart" and world.definitions.buildings[structure.definition].room_boundary:
			for point in world.footprint(structure):
				boundaries[point] = true
	var visited: Dictionary = boundaries.duplicate()
	var roofed: Dictionary = {}
	for y in range(128):
		for x in range(128):
			var start: Vector2i = Vector2i(x, y)
			if visited.has(start):
				continue
			var queue: Array[Vector2i] = [start]
			var cursor: int = 0
			var interior: Array[Vector2i] = []
			var open: bool = false
			visited[start] = true
			while cursor < queue.size():
				var point: Vector2i = queue[cursor]
				cursor += 1
				interior.append(point)
				open = open or point.x in [0, 127] or point.y in [0, 127] or M2World.is_water(point)
				for delta in M2Navigation.NEIGHBORS:
					var neighbor: Vector2i = point + delta
					if M2World.inside(neighbor) and not visited.has(neighbor):
						visited[neighbor] = true
						queue.append(neighbor)
			if not open and interior.size() <= 64:
				for point in interior:
					roofed[point] = start.y * 128 + start.x
	return roofed
