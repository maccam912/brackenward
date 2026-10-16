class_name ColonyAgriculture
extends RefCounted

static func designate(world: ColonyWorld, args: Dictionary) -> String:
	if not world.definitions.crops.has(args.crop):
		return "unknown_crop"
	var definition: Dictionary = world.definitions.crops[args.crop]
	if definition.unlock != "initial" and not world.researched.has(definition.unlock):
		return "Requires " + definition.unlock.capitalize() + " research"
	if not definition.seasons.has(season(world.tick)):
		return "Dormant: first sowing season is " + ["Spring", "Summer", "Autumn", "Winter"][definition.seasons[0]]
	if args.tiles.is_empty():
		return "empty_field"
	var planned: Dictionary = planned_tiles(world)
	for point: Vector2i in args.tiles:
		if planned.has(point): return "Field overlaps planned construction or a move destination: cancel that order first"
		if world.domestic_state.pens.any(func(p:Dictionary)->bool:return p.tiles.has(point)): return "Field overlaps pen"
		if not world.walkable(point) or world.roofed(point) != definition.roof:
			return "Requires roofed soil" if definition.roof else "Requires open soil"
		for store in world.stores:
			if store.tiles.has(point):
				return "Field overlaps storage"
		for structure in world.structures:
			if world.footprint(structure).has(point):
				return "Field overlaps a structure"
		for field in world.fields:
			if Vector2i(field.x, field.y) == point:
				return "Existing field: clear its order before repainting"
	var seen: Dictionary = {}
	for point: Vector2i in args.tiles:
		if seen.has(point):
			continue
		seen[point] = true
		world.fields.append({"id": world._id(), "crop": args.crop, "x": point.x, "y": point.y,
			"prepared": false, "planted": false, "growth": 0, "growth_rem": 0, "ripe_tick": 0,
			"yield_count": definition.yield_count, "fertility": world.soil_fertility(point), "replant": true, "reason": "Waiting for preparation"})
	return "accepted"

static func planned_tiles(world: ColonyWorld) -> Dictionary:
	var result: Dictionary = {}
	for job in world.unfinished_jobs():
		if job.state in ["Complete","Canceled"]: continue
		var tiles: Array = world.footprint(job) if job.kind=="build" else (ColonyMaintenance.move_footprint(world,job) if job.kind in ["move_furniture","cart_move"] else [])
		for tile in tiles: result[tile]=true
	return result

static func season(tick: int) -> int:
	return (tick / 7200 / 8) % 4

static func advance(world: ColonyWorld) -> void:
	var current_season: int = season(world.tick)
	# Irrigation only affects drought. Build this local view once so destroyed or
	# moved wells are observed on the next tick without a persisted cache.
	var wells: Array = world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition=="well") if world.weather=="drought" else []
	for resource in world._regrowth_resources():
		if resource.remaining == 0 and resource.regrow_at > 0:
			if current_season == 3 and resource.definition in ["berry_bush", "herb_patch", "tree"]:
				resource.regrow_at += 1
			elif world.tick >= resource.regrow_at:
				resource.remaining = world.definitions.resources[resource.definition].yield_count
				resource.regrow_at = 0
				world.resource_query_dirty=true
				world.navigation_dirty = true
	for field in world.fields:
		if not field.planted:
			continue
		var definition: Dictionary = world.definitions.crops[field.crop]
		if world.is_flooded(Vector2i(field.x,field.y)):
			field.reason = "Flooded until 18:00: growth paused"
			continue
		if field.ripe_tick > 0:
			var elapsed: int = world.tick - field.ripe_tick
			if elapsed > 14400 and (elapsed - 14400) % 7200 == 0:
				field.yield_count = maxi(0, field.yield_count - 1)
				if field.yield_count == 0:
					field.planted = false
					field.growth = 0
					field.ripe_tick = 0
			continue
		if not definition.seasons.has(current_season):
			field.reason = "Dormant until " + ["Spring", "Summer", "Autumn", "Winter"][definition.seasons[0]]
			continue
		if world.roofed(Vector2i(field.x, field.y)) != definition.roof:
			field.reason = "Roof required" if definition.roof else "Remove roof for outdoor crops"
			continue
		var watered: bool = wells.any(func(s:Dictionary)->bool:return absi(s.x-field.x)+absi(s.y-field.y) <= 8)
		var rate: int = field.fertility * (500 if world.weather == "drought" and not watered else 1000) / 1000
		field.growth_rem += rate
		field.growth += field.growth_rem / 7200
		field.growth_rem %= 7200
		field.reason = "Growing: drought, half rate; build a well within 8 tiles" if world.weather == "drought" and not watered else ("Growing: well stabilizes drought" if world.weather == "drought" else "Growing")
		if field.growth >= definition.growth:
			field.growth = definition.growth
			field.ripe_tick = world.tick
			field.reason = "Ripe: harvest before losses after 2 days"

static func create_jobs(world: ColonyWorld) -> void:
	# Historical jobs remain saved evidence. Index unfinished field operations
	# once rather than scanning that full history again for every crop tile.
	var pending: Dictionary = {}
	for job in world.unfinished_jobs():
		if job.kind in ["prepare", "sow", "harvest"] and job.state not in ["Complete", "Canceled"]:
			pending[job.target]=true
	for field in world.fields:
		var operation: String = "prepare" if not field.prepared else ("sow" if not field.planted else ("harvest" if field.ripe_tick > 0 else ""))
		if operation.is_empty() or (operation == "sow" and (not field.replant or not world.definitions.crops[field.crop].seasons.has(season(world.tick)))):
			continue
		if not pending.has(field.id):
			world._job(operation, "Growing", "Field", field.id, Vector2i(field.x, field.y), world.definitions.crops[field.crop][operation + "_milli"])
			pending[field.id]=true

static func complete(world: ColonyWorld, _citizen: Dictionary, job: Dictionary) -> void:
	if job.kind == "replant":
		var resource: Dictionary = world.find(world.resources, job.target)
		resource.regrow_at = world.tick + 57600
		world.resource_query_dirty=true
		return
	var field: Dictionary = world.find(world.fields, job.target)
	var definition: Dictionary = world.definitions.crops[field.crop]
	match job.kind:
		"prepare": field.prepared = true
		"sow":
			field.planted = true
			field.growth = 0
			field.growth_rem = 0
			field.ripe_tick = 0
			field.yield_count = definition.yield_count
		"harvest":
			var quantity: int = field.yield_count
			if job.definition == "early_harvest": quantity = mini(quantity,maxi(1,definition.yield_count * field.growth / definition.growth))
			world._make_stack(definition.item, quantity, "ground", 0, Vector2i(job.work_x, job.work_y), true)
			field.planted = false
			field.growth = 0
			field.ripe_tick = 0

## Old saves store crop tiles individually. Edge-connected matching crops form
## a visible plot without inventing membership or changing acknowledged saves.
static func plot(world: ColonyWorld, field: Dictionary) -> Array[Dictionary]:
	var cells: Dictionary={}
	for cell: Dictionary in world.fields:
		if cell.crop==field.crop: cells[Vector2i(cell.x,cell.y)]=cell
	var result: Array[Dictionary]=[]
	var pending: Array[Vector2i]=[Vector2i(field.x,field.y)]
	var cursor: int=0
	while cursor<pending.size():
		var point: Vector2i=pending[cursor];cursor+=1
		if not cells.has(point): continue
		result.append(cells[point]);cells.erase(point)
		for direction: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if cells.has(point+direction): pending.append(point+direction)
	return result

static func clear(world: ColonyWorld, target: int, whole_plot: bool) -> String:
	var field: Dictionary=world.find(world.fields,target)
	if field.is_empty(): return "missing_field"
	var removed: Array[Dictionary]=[]
	if whole_plot: removed=plot(world,field)
	else: removed.append(field)
	var ids: Dictionary={}
	for cell: Dictionary in removed: ids[cell.id]=true
	for job: Dictionary in world.unfinished_jobs():
		if job.kind in ["prepare","sow","harvest"] and ids.has(job.target): world._release(job,true)
	world.fields.assign(world.fields.filter(func(cell:Dictionary)->bool:return not ids.has(cell.id)))
	world.record_indexes.clear()
	return "accepted"
