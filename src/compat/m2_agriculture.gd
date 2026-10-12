class_name M2Agriculture
extends RefCounted

static func designate(world: M2World, args: Dictionary) -> String:
	if not world.definitions.crops.has(args.crop):
		return "unknown_crop"
	var definition: Dictionary = world.definitions.crops[args.crop]
	if definition.unlock != "initial" and not world.researched.has(definition.unlock):
		return "Requires " + definition.unlock.capitalize() + " research"
	if not definition.seasons.has(season(world.tick)):
		return "Dormant: first sowing season is " + ["Spring", "Summer", "Autumn", "Winter"][definition.seasons[0]]
	if args.tiles.is_empty():
		return "empty_field"
	for point: Vector2i in args.tiles:
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
			"yield_count": definition.yield_count, "fertility": 1000, "replant": true, "reason": "Waiting for preparation"})
	return "accepted"

static func season(tick: int) -> int:
	return (tick / 7200 / 8) % 4

static func advance(world: M2World) -> void:
	for resource in world.resources:
		if resource.remaining == 0 and resource.regrow_at > 0:
			if season(world.tick) == 3 and resource.definition in ["berry_bush", "herb_patch", "tree"]:
				resource.regrow_at += 1
			elif world.tick >= resource.regrow_at:
				resource.remaining = world.definitions.resources[resource.definition].yield_count
				resource.regrow_at = 0
				world.navigation_dirty = true
	for field in world.fields:
		if not field.planted:
			continue
		var definition: Dictionary = world.definitions.crops[field.crop]
		if field.ripe_tick > 0:
			var elapsed: int = world.tick - field.ripe_tick
			if elapsed > 14400 and (elapsed - 14400) % 7200 == 0:
				field.yield_count = maxi(0, field.yield_count - 1)
				if field.yield_count == 0:
					field.planted = false
					field.growth = 0
					field.ripe_tick = 0
			continue
		if not definition.seasons.has(season(world.tick)):
			field.reason = "Dormant until " + ["Spring", "Summer", "Autumn", "Winter"][definition.seasons[0]]
			continue
		if world.roofed(Vector2i(field.x, field.y)) != definition.roof:
			field.reason = "Roof required" if definition.roof else "Remove roof for outdoor crops"
			continue
		var rate: int = field.fertility * (500 if world.weather == "drought" else 1000) / 1000
		field.growth_rem += rate
		field.growth += field.growth_rem / 7200
		field.growth_rem %= 7200
		field.reason = "Growing"
		if field.growth >= definition.growth:
			field.growth = definition.growth
			field.ripe_tick = world.tick
			field.reason = "Ripe: harvest before losses after 2 days"

static func create_jobs(world: M2World) -> void:
	for field in world.fields:
		var operation: String = "prepare" if not field.prepared else ("sow" if not field.planted else ("harvest" if field.ripe_tick > 0 else ""))
		if operation.is_empty() or (operation == "sow" and (not field.replant or not world.definitions.crops[field.crop].seasons.has(season(world.tick)))):
			continue
		var exists: bool = false
		for job in world.jobs:
			if job.target == field.id and job.kind in ["prepare", "sow", "harvest"] and job.state not in ["Complete", "Canceled"]:
				exists = true
		if not exists:
			world._job(operation, "Growing", "Field", field.id, Vector2i(field.x, field.y), world.definitions.crops[field.crop][operation + "_milli"])

static func complete(world: M2World, _citizen: Dictionary, job: Dictionary) -> void:
	if job.kind == "replant":
		var resource: Dictionary = world.find(world.resources, job.target)
		resource.regrow_at = world.tick + 57600
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
			world._make_stack(definition.item, field.yield_count, "ground", 0, Vector2i(job.work_x, job.work_y), true)
			field.planted = false
			field.growth = 0
			field.ripe_tick = 0
