class_name ColonyWeather
extends RefCounted
const KINDS: Array[String] = ["clear","rain","fog","snow","drought","flood","cold_snap"]

static func initialize(world: ColonyWorld) -> void:
	var day: int = world.tick / 7200
	world.weather_state = {"rng":ParkMiller.derive(world.seed,world.generator_version,world.site_id,"weather"),"days":[],"flooded":[],"last_flood_day":-1,"reserved_major_days":[]}
	for future in range(day,day+4):
		var entry: Dictionary = _day(world,future)
		if future == day:
			entry.kind = world.weather
			entry.mask = flood_mask(world) if world.weather == "flood" else []
		world.weather_state.days.append(entry)
	if world.weather == "flood" and world.tick % 7200 >= 1800 and world.tick % 7200 < 5400:
		world.weather_state.flooded = world.weather_state.days[0].mask.duplicate()
		world.weather_state.last_flood_day = day
	world.flood_cache_valid = false

static func _day(world: ColonyWorld, day: int) -> Dictionary:
	var kind: String = ["clear","rain","clear"][day] if day < 3 else "clear"
	if day >= 3:
		var season: int = (day / 8) % 4
		var weights: Array = [["clear",45],["rain",35],["fog",20]]
		if season == 1: weights = [["clear",65],["rain",20],["drought",15]]
		elif season == 3: weights = [["clear",35],["snow",50],["cold_snap",15]]
		elif day >= 6: weights.append(["flood",10])
		var rng: ParkMiller = ParkMiller.new(world.weather_state.rng)
		var total: int = 0
		for weight in weights: total += weight[1]
		var roll: int = rng.bounded(total)
		world.weather_state.rng = rng.state
		for weight in weights:
			if roll < weight[1]:
				kind = weight[0]
				break
			roll -= weight[1]
		if kind in ["flood","cold_snap"]:
			var eligible: bool = day >= 6
			for previous in world.weather_state.days:
				if previous.kind in ["flood","cold_snap"] and absi(previous.day-day) < 4: eligible = false
			for major in world.weather_state.reserved_major_days:
				if absi(major-day) <= 2: eligible = false
			# Forecasts reserve exact incident onsets, including evening fires.
			# A calendar-day gap of three can still be less than 72 hours.
			var onset: int = day*7200+(1800 if kind=="flood" else 0)
			for major in world.director_state.get("history",[]):
				if major.started>0 and absi(major.started-onset)<21600: eligible=false
			var current: Dictionary = world.director_state.get("major",{})
			if not current.is_empty():
				var start: int = current.started if current.started>0 else current.due
				if absi(start-onset)<21600: eligible=false
			if not eligible: kind = "snow" if season == 3 else "rain"
	return {"day":day,"kind":kind,"mask":flood_mask(world) if kind == "flood" else []}

static func flood_mask(world: ColonyWorld) -> Array[Vector2i]:
	var mask: Array[Vector2i] = []
	var connected: Dictionary = {}
	var queue: Array[Vector2i] = []
	# Bridge tiles remain river sources for the flood overlay.
	for y in range(128):
		for x in range(128):
			var river: Vector2i = Vector2i(x,y)
			if (world.generator_version > 0 and world.elevation(river) == 0) or (world.generator_version == 0 and x in range(32,36)):
				connected[river] = 0
				queue.append(river)
	var cursor: int = 0
	while cursor < queue.size():
		var point: Vector2i = queue[cursor]
		cursor += 1
		for delta in ColonyNavigation.NEIGHBORS:
			var neighbor: Vector2i = point+delta
			if ColonyWorld.inside(neighbor) and not connected.has(neighbor) and world.elevation(neighbor) == 1 and connected[point] < 6:
				connected[neighbor] = connected[point]+1
				queue.append(neighbor)
	for y in range(128):
		for x in range(128):
			var point: Vector2i = Vector2i(x,y)
			if world.elevation(point) == 1 and connected.has(point): mask.append(point)
	return mask

static func advance(world: ColonyWorld) -> void:
	var day: int = world.tick / 7200
	if world.tick % 7200 == 0:
		while world.weather_state.days[0].day < day-3: world.weather_state.days.pop_front()
		world.weather_state.days.append(_day(world,day+3))
		for entry in world.weather_state.days:
			if entry.day == day: world.weather = entry.kind
		world.facts.append({"tick":world.tick,"actor":0,"job":0,"kind":"weather","text":"Today's weather: "+world.weather.replace("_"," ")})
	if world.weather == "flood" and world.tick % 7200 == 1800 and world.weather_state.last_flood_day != day:
		var mask: Array = []
		for entry in world.weather_state.days:
			if entry.day == day: mask = entry.mask
		world.weather_state.flooded = mask.duplicate()
		world.weather_state.last_flood_day = day
		world.flood_cache_valid = false
		for field in world.fields:
			if field.ripe_tick > 0 and world.is_flooded(Vector2i(field.x,field.y)): field.yield_count -= field.yield_count / 2
		var lost: int = 0
		var interrupted: Dictionary = {}
		# Capture exposure before canceling work, so newly dropped carried food
		# is not charged a second loss during the same onset transaction.
		var exposed: Array = world.stacks.filter(func(stack:Dictionary)->bool:return vulnerable(world,stack))
		for stack in exposed:
			var quantity: int = stack.count / 2
			if quantity == 0: continue
			stack.count -= quantity
			lost += quantity
			world._record("lost",stack.item,quantity)
			for id in stack.reservations.keys(): interrupted[id] = true
			if stack.location == "escrow": interrupted[stack.owner] = true
		for id in interrupted:
			var job: Dictionary = world.find(world.jobs,id)
			world._release(job,false)
			world._block(job,"Flood damaged inputs: move supplies onto high ground")
		world.facts.append({"tick":world.tick,"actor":0,"job":0,"kind":"flood","text":"Floodwater until 18:00; %d food units lost on low ground. High ground and protected stores are safe." % lost})
	if world.tick % 7200 == 5400 and not world.weather_state.flooded.is_empty():
		world.weather_state.flooded = []
		world.flood_cache_valid = false

static func vulnerable(world: ColonyWorld, stack: Dictionary, mask: Array = []) -> bool:
	var point: Vector2i = Vector2i(stack.x,stack.y)
	if stack.count <= 0 or (world.definitions.items[stack.item].fullness == 0 and world.definitions.items[stack.item].tags.is_empty()) or not (world.is_flooded(point) if mask.is_empty() else mask.has(point)): return false
	if stack.location == "carry": return false
	if stack.location == "store":
		var structure: Dictionary = world.find(world.structures,stack.owner)
		if not structure.is_empty() and (structure.definition in ["supply_cart","granary","cellar"] or (structure.definition == "covered_rack" and world.roofed(point))): return false
		return not world.roofed(point)
	if stack.location == "escrow": return not world.roofed(point)
	if stack.location == "output": return not world.roofed(point)
	return stack.location == "ground"

static func describe(kind: String) -> String:
	return {"clear":"Normal travel and growth.","rain":"Wet soil: 15 ticks per tile; paths stay usable.","fog":"Bow range is reduced by 2; threats remain visible.","snow":"Travel takes 12 ticks per ordinary tile.","drought":"Crop growth halved outside well coverage.","flood":"06:00-18:00: striped low ground floods. Ripe crops and unprotected food lose half once. Move food or harvest early.","cold_snap":"Temperature drops 10 C. Keep hearth fuel and warm workspaces."}[kind]

static func validate(data: Variant, tick: int = 1800) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["rng","days","flooded","last_flood_day","reserved_major_days"]): return false
	if not data.rng is int or data.rng <= 0 or data.rng >= ParkMiller.MODULUS or not data.days is Array or data.days.size() < 4 or data.days.size() > 7 or not data.flooded is Array or data.flooded.size() > 16384 or not data.last_flood_day is int or not data.reserved_major_days is Array: return false
	var previous: int = -1
	for day in data.days:
		if not day is Dictionary or not ColonyCodec._keys(day,["day","kind","mask"]) or not day.day is int or day.day < 0 or day.day <= previous or (previous >= 0 and day.day != previous+1) or day.kind not in KINDS or not day.mask is Array or day.mask.size() > 16384: return false
		previous = day.day
		for point in day.mask:
			if not point is Vector2i: return false
	for point in data.flooded:
		if not point is Vector2i: return false
	for day in data.reserved_major_days:
		if not day is int or day < 0: return false
	return data.days[0].day <= tick / 7200 and data.days[-1].day == tick / 7200 + 3

static func valid_geometry(world: ColonyWorld, data: Dictionary) -> bool:
	var expected: Array[Vector2i] = []
	var needs_mask: bool = not data.flooded.is_empty() or data.days.any(func(d:Dictionary)->bool:return d.kind == "flood")
	if needs_mask: expected = flood_mask(world)
	for day in data.days:
		if day.mask != (expected if day.kind == "flood" else []): return false
	return data.flooded.is_empty() or data.flooded == expected
