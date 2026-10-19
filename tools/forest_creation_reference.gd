class_name ForestCreationReference
extends RefCounted
## Complete forest/fishing creation pass from 783de14.

static func create_jobs(world: ColonyWorld) -> void:
	for zone in world.nature_state.forests:
		if not zone.enabled: continue
		var area: Dictionary = {}
		for p in zone.tiles: area[p] = true
		var trees: Array = world.resources.filter(func(r:Dictionary)->bool:return r.definition == "tree" and not ColonyNature.tree(world,r.id).cleared and area.has(Vector2i(r.x,r.y)))
		var minimum: int = (trees.size()*zone.reserve+99)/100
		var mature: Array = trees.filter(func(r:Dictionary)->bool:return r.remaining > 0)
		var ordered: Dictionary = {}
		for job in world.jobs:
			if job.kind == "gather" and job.state not in ["Complete","Canceled"]: ordered[job.target] = true
		var queued: int = mature.filter(func(r:Dictionary)->bool:return ordered.has(r.id)).size()
		for resource in trees:
			var p: Vector2i = Vector2i(resource.x,resource.y)
			if resource.remaining == 0 and not ColonyNature.tree(world,resource.id).cleared and not ColonyNature.tree(world,resource.id).planted and ColonyNature.plantable(world,p) and not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.target == resource.id and j.kind in ["plant_tree","clear_stump"] and j.state not in ["Complete","Canceled"]):
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
		if world.nonempty_stacks().filter(func(s:Dictionary)->bool:return s.count > 0 and s.location == "output" and s.owner == pier.id).size() >= 2: continue
		world._job("fish","Gathering","Field",pier.id,Vector2i(pier.x,pier.y),12000)
		committed += 2
