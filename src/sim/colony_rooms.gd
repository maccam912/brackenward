class_name ColonyRooms
extends RefCounted

static func compute(world: ColonyWorld) -> Dictionary:
	var side: int = ColonyWorld.SIZE
	var visited: PackedByteArray = PackedByteArray();visited.resize(side*side);visited.fill(0)
	for structure in world.structures:
		if structure.health<=0: continue
		if structure.definition != "supply_cart" and world.definitions.buildings[structure.definition].room_boundary:
			for point in world.footprint(structure):
				if ColonyWorld.inside(point): visited[point.y*side+point.x]=1
	var roofed: Dictionary = {}
	var queue: PackedInt32Array = PackedInt32Array();queue.resize(side*side)
	var steps: Array[int] = [-side,1,side,-1]
	for start in range(side*side):
		if visited[start]: continue
		var cursor: int = 0
		var tail: int = 1
		var open: bool = false
		queue[0]=start;visited[start]=1
		while cursor<tail:
			var index: int = queue[cursor];cursor+=1
			var column: int = index%side
			open=open or index<side or index>=side*(side-1) or column==0 or column==side-1 or world.is_water(Vector2i(column,index/side))
			# Same north/east/south/west traversal and row-major component IDs.
			for direction in range(4):
				var next: int = index+steps[direction]
				if next<0 or next>=side*side or (direction==1 and column==side-1) or (direction==3 and column==0) or visited[next]: continue
				visited[next]=1;queue[tail]=next;tail+=1
		if not open and tail<=64:
			for cursor_index in range(tail):
				var index: int = queue[cursor_index]
				roofed[Vector2i(index%side,index/side)]=start
	for structure in world.structures:
		if structure.health>0 and world.definitions.buildings[structure.definition].built_in_roof:
			for point in world.footprint(structure):
				if not roofed.has(point): roofed[point]=-structure.id
	return roofed
