class_name M2Navigation
extends RefCounted
## Four-neighbor A*, ordered by f, h, then row-major tile ID.
const NEIGHBORS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func path(start: Vector2i, goal: Vector2i, passable: Callable) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not passable.call(goal):
		return empty
	var frontier: Array[Vector2i] = [start]
	var costs: Dictionary = {start: 0}
	var parents: Dictionary = {}
	var visited: Dictionary = {}
	while not frontier.is_empty() and visited.size() < 16384:
		frontier.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var ah: int = absi(a.x - goal.x) + absi(a.y - goal.y)
			var bh: int = absi(b.x - goal.x) + absi(b.y - goal.y)
			var af: int = costs[a] + ah
			var bf: int = costs[b] + bh
			return af < bf or (af == bf and (ah < bh or (ah == bh and a.y * 128 + a.x < b.y * 128 + b.x))))
		var point: Vector2i = frontier.pop_front()
		if visited.has(point):
			continue
		visited[point] = true
		if point == goal:
			var route: Array[Vector2i] = []
			while point != start:
				route.push_front(point)
				point = parents[point]
			return route
		for delta in NEIGHBORS:
			var neighbor: Vector2i = point + delta
			if visited.has(neighbor) or not passable.call(neighbor):
				continue
			var cost: int = costs[point] + 1
			if not costs.has(neighbor) or cost < costs[neighbor]:
				costs[neighbor] = cost
				parents[neighbor] = point
				frontier.append(neighbor)
	return empty
