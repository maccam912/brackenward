class_name ColonyNavigation
extends RefCounted
## Four-neighbor A*, ordered by f, h, then row-major tile ID.
const NEIGHBORS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func path(start: Vector2i, goal: Vector2i, passable: Callable, edge: Callable = Callable()) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not passable.call(goal):
		return empty
	# Entries retain their insertion cost so a decreased route can leave a stale
	# entry behind. The heap preserves the original f, h, row-major ordering.
	var frontier: Array[Vector4i] = [Vector4i(start.x,start.y,0,absi(start.x-goal.x)+absi(start.y-goal.y))]
	var costs: Dictionary = {start: 0}
	var parents: Dictionary = {}
	var visited: Dictionary = {}
	while not frontier.is_empty() and visited.size() < 16384:
		var entry: Vector4i = _pop(frontier)
		var point: Vector2i = Vector2i(entry.x,entry.y)
		if visited.has(point) or costs[point]!=entry.z:
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
			if visited.has(neighbor) or not passable.call(neighbor) or (edge.is_valid() and not edge.call(point,neighbor)):
				continue
			var cost: int = costs[point] + 1
			if not costs.has(neighbor) or cost < costs[neighbor]:
				costs[neighbor] = cost
				parents[neighbor] = point
				_push(frontier,Vector4i(neighbor.x,neighbor.y,cost,absi(neighbor.x-goal.x)+absi(neighbor.y-goal.y)))
	return empty

static func _before(a: Vector4i, b: Vector4i) -> bool:
	var af: int = a.z+a.w
	var bf: int = b.z+b.w
	return af<bf or (af==bf and (a.w<b.w or (a.w==b.w and a.y*128+a.x<b.y*128+b.x)))

static func _push(heap: Array[Vector4i], entry: Vector4i) -> void:
	var index: int = heap.size()
	heap.append(entry)
	while index>0:
		var parent: int = (index-1)/2
		if not _before(entry,heap[parent]): break
		heap[index]=heap[parent]
		index=parent
	heap[index]=entry

static func _pop(heap: Array[Vector4i]) -> Vector4i:
	var first: Vector4i = heap[0]
	var tail: Vector4i = heap.pop_back()
	if heap.is_empty(): return first
	var index: int = 0
	while index*2+1<heap.size():
		var child: int = index*2+1
		if child+1<heap.size() and _before(heap[child+1],heap[child]): child+=1
		if not _before(heap[child],tail): break
		heap[index]=heap[child]
		index=child
	heap[index]=tail
	return first
