class_name ColonyNature
extends RefCounted
const MATURITY: int = 57600

static func initial_state(tick: int = 1800) -> Dictionary:
	return {"trees":{},"forests":[],"fishing":{"day":(tick-1800)/7200,"river":0,"piers":{}}}

static func tree(world: ColonyWorld, id: int) -> Dictionary:
	return world.nature_state.trees.get(id,{"planted":false,"age":0})

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	if kind == "forest":
		if args.value not in [50,75,100] or args.tiles.is_empty(): return "Forest reserve must be 50, 75 or 100 percent"
		for p in args.tiles:
			if not ColonyWorld.inside(p) or world.is_water(p): return "Forest zone needs land"
			if world.nature_state.forests.any(func(z:Dictionary)->bool:return z.tiles.has(p)): return "Forest zones cannot overlap"
		var tiles: Array = []
		for p in args.tiles:
			if not tiles.has(p): tiles.append(p)
		world.nature_state.forests.append({"id":world._id(),"tiles":tiles,"reserve":args.value,"enabled":true})
		return "accepted"
	if kind == "forest_policy":
		var zone: Dictionary = world.find(world.nature_state.forests,args.target)
		if zone.is_empty() or args.value not in [50,75,100]: return "Missing forest or invalid reserve"
		zone.reserve = args.value; zone.enabled = args.enabled
		for job in world.jobs:
			if job.order == zone.id and job.kind in ["gather","plant_tree"] and job.state not in ["Complete","Canceled"]: world._release(job,true)
		return "accepted"
	var resource: Dictionary = world.find(world.resources,args.target)
	if resource.is_empty() or resource.definition != "tree" or resource.remaining > 0: return "Choose a stump or sapling"
	if world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.target == resource.id and j.kind in ["plant_tree","clear_sapling"] and j.state not in ["Complete","Canceled"]): return "Tree work already marked"
	var state: Dictionary = tree(world,resource.id)
	if kind == "replant_tree" and state.planted: return "Tree is already growing"
	if kind == "clear_sapling" and not state.planted: return "No sapling to clear"
	var p: Vector2i = Vector2i(resource.x,resource.y)
	if not plantable(world,p): return "Tree needs an empty land tile outside storage, fields and paths"
	world._job("plant_tree" if kind == "replant_tree" else "clear_sapling","Growing" if kind == "replant_tree" else "Gathering","Field",resource.id,p,4000 if kind == "replant_tree" else 2000)
	return "accepted"

static func plantable(world: ColonyWorld, p: Vector2i) -> bool:
	if not world.walkable(p): return false
	if world.generator_version > 0 and world.terrain_state.paths.has(p): return false
	for structure in world.structures:
		if structure.health<=0: continue
		if world.footprint(structure).has(p): return false
	if world.fields.any(func(f:Dictionary)->bool:return f.x == p.x and f.y == p.y): return false
	return not world.stores.any(func(s:Dictionary)->bool:return s.tiles.has(p))

static func advance(world: ColonyWorld) -> void:
	var day: int = (world.tick-1800)/7200
	if world.nature_state.fishing.day != day: world.nature_state.fishing = {"day":day,"river":0,"piers":{}}
	if ColonyAgriculture.season(world.tick) == 3: return
	var occupied: Dictionary = {}
	var indexed: bool = false
	for id in world.nature_state.trees:
		var state: Dictionary = world.nature_state.trees[id]
		if not state.planted: continue
		# Structures, fields and stores cannot change during this advance call.
		# Mature trees can change navigation, so walkability is still checked live.
		if not indexed:
			for structure in world.structures:
				if structure.health>0:
					for point in world.footprint(structure): occupied[point]=true
			for field in world.fields: occupied[Vector2i(field.x,field.y)]=true
			for store in world.stores:
				for point in store.tiles: occupied[point]=true
			indexed=true
		var resource: Dictionary = world.find(world.resources,id)
		var point: Vector2i = Vector2i(resource.x,resource.y)
		if not world.walkable(point) or (world.generator_version>0 and world.terrain_state.paths.has(point)) or occupied.has(point): continue
		state.age += 1
		if state.age >= MATURITY:
			state.age = MATURITY; state.planted = false; resource.remaining = 8
			world.navigation_dirty = true
			world.emit_fact({"tick":world.tick,"actor":0,"job":0,"kind":"tree_mature","text":"A replanted tree matured after eight non-winter days."})

static func create_jobs(world: ColonyWorld) -> void:
	for zone in world.nature_state.forests:
		if not zone.enabled: continue
		var area: Dictionary = {}
		for p in zone.tiles: area[p] = true
		var trees: Array = world.resources.filter(func(r:Dictionary)->bool:return r.definition == "tree" and area.has(Vector2i(r.x,r.y)))
		var minimum: int = (trees.size()*zone.reserve+99)/100
		var mature: Array = trees.filter(func(r:Dictionary)->bool:return r.remaining > 0)
		var ordered: Dictionary = {}
		for job in world.jobs:
			if job.kind == "gather" and job.state not in ["Complete","Canceled"]: ordered[job.target] = true
		var queued: int = mature.filter(func(r:Dictionary)->bool:return ordered.has(r.id)).size()
		for resource in trees:
			var p: Vector2i = Vector2i(resource.x,resource.y)
			if resource.remaining == 0 and not tree(world,resource.id).planted and plantable(world,p) and not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.target == resource.id and j.kind == "plant_tree" and j.state not in ["Complete","Canceled"]):
				var replant: Dictionary = world._job("plant_tree","Growing","Field",resource.id,p,4000)
				replant.order = zone.id
		for resource in mature:
			if queued >= mature.size()-minimum: break
			if ordered.has(resource.id): continue
			var cut: Dictionary = world._job("gather","Gathering","Field",resource.id,Vector2i(resource.x,resource.y),16000)
			cut.definition = "tree"; cut.order = zone.id
			queued += 1
	var fish: Dictionary = world.nature_state.fishing
	var pending: Array = world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.kind == "fish" and j.state not in ["Complete","Canceled"])
	var committed: int = fish.river+pending.size()*2
	for pier in world.structures:
		if pier.health<=0: continue
		if pier.definition != "fishing_pier" or not pier.cooking or committed >= 16: continue
		if pending.any(func(j:Dictionary)->bool:return j.target == pier.id) or fish.piers.get(pier.id,0) >= 8: continue
		if world.stacks.filter(func(s:Dictionary)->bool:return s.count > 0 and s.location == "output" and s.owner == pier.id).size() >= 2: continue
		world._job("fish","Gathering","Field",pier.id,Vector2i(pier.x,pier.y),12000)
		committed += 2

static func reserve(world: ColonyWorld, job: Dictionary) -> bool:
	if job.kind == "fish":
		var pier: Dictionary = world.find(world.structures,job.target)
		if pier.is_empty() or not pier.cooking: return world._block(job,"Fishing pier suspended or missing")
		if world.nature_state.fishing.river >= 16 or world.nature_state.fishing.piers.get(pier.id,0) >= 8: return world._block(job,"Daily catch limit reached: fish recover at 06:00")
	else:
		var resource: Dictionary = world.find(world.resources,job.target)
		if resource.is_empty() or resource.remaining > 0 or not plantable(world,Vector2i(resource.x,resource.y)): return world._block(job,"Stump tile occupied or tree already mature")
	return true

static func complete(world: ColonyWorld, job: Dictionary) -> void:
	match job.kind:
		"plant_tree": world.nature_state.trees[job.target] = {"planted":true,"age":0}
		"clear_sapling": world.nature_state.trees[job.target] = {"planted":false,"age":0}
		"fish":
			world.nature_state.fishing.river += 2
			world.nature_state.fishing.piers[job.target] = world.nature_state.fishing.piers.get(job.target,0)+2
			world._make_stack("fish",2,"output",job.target,Vector2i(job.work_x,job.work_y),true)

static func validate(data: Variant, resources: Array, structures: Array, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["trees","forests","fishing"]) or not data.trees is Dictionary or not data.forests is Array or data.forests.size() > 16384 or not data.fishing is Dictionary: return false
	for id in data.trees:
		var state: Variant = data.trees[id]
		if not id is int or not state is Dictionary or not ColonyCodec._keys(state,["planted","age"]) or not state.planted is bool or not state.age is int or state.age < 0 or state.age > MATURITY or not resources.any(func(r:Dictionary)->bool:return r.id == id and r.definition == "tree"): return false
	var occupied: Dictionary = {}
	for zone in data.forests:
		if not zone is Dictionary or not ColonyCodec._keys(zone,["id","tiles","reserve","enabled"]) or not zone.id is int or not zone.tiles is Array or zone.tiles.is_empty() or zone.tiles.size() > 16384 or zone.reserve not in [50,75,100] or not zone.enabled is bool or not zone.tiles.all(func(p:Variant)->bool:return p is Vector2i): return false
		for p in zone.tiles:
			if not ColonyWorld.inside(p) or occupied.has(p): return false
			occupied[p] = true
	var fish: Dictionary = data.fishing
	if not ColonyCodec._keys(fish,["day","river","piers"]) or not fish.day is int or fish.day < 0 or not fish.river is int or fish.river < 0 or fish.river > 16 or fish.river%2 != 0 or not fish.piers is Dictionary: return false
	if fish.day != (tick-1800)/7200 and (fish.river > 0 or not fish.piers.is_empty()): return false
	var total: int = 0
	for id in fish.piers:
		if not id is int or not structures.any(func(s:Dictionary)->bool:return s.id == id and s.definition == "fishing_pier") or not fish.piers[id] is int or fish.piers[id] < 0 or fish.piers[id] > 8 or fish.piers[id]%2 != 0: return false
		total += fish.piers[id]
	return total == fish.river
