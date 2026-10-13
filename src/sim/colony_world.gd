class_name ColonyWorld
extends RefCounted
## Authoritative M1 simulation. No nodes, rendering, I/O, wall clock or global RNG.
const SIZE: int = 128
const CONTENT_VERSION: String = "colony-v2"
const SCHEMA_REVISION: int = 18
const CATEGORIES: Array[String] = ["Care", "Cooking", "Growing", "Gathering", "Animals", "Building", "Crafting", "Hauling", "Research", "Guard"]
const SKILLS: Array[String] = ["Field", "Build", "Craft", "Cooking", "Care", "Study", "Guard"]
const THRESHOLDS: Array[int] = [0, 400, 1200, 2400, 4000, 6000]
var definitions: Dictionary
var tick: int = 1800
var seed: int = 104729
var session_id: String = "m1-local"
var next_id: int = 5
var next_command_id: int = 1
var citizens: Array[Dictionary] = []
var structures: Array[Dictionary] = []
var resources: Array[Dictionary] = []
var stacks: Array[Dictionary] = []
var jobs: Array[Dictionary] = []
var stores: Array[Dictionary] = []
var fields: Array[Dictionary] = []
var researched: Array[String] = []
var room_tiles: Dictionary = {}
var rooms_dirty: bool = true
var schema_revision: int = SCHEMA_REVISION
var social_state: Dictionary = {}
var production_state: Dictionary = {}
var care_state: Dictionary = {}
var care_destinations: Dictionary = {}
var population_state: Dictionary = {}
var trade_state: Dictionary = {}
var region_state: Dictionary = {}
var fire_state: Dictionary = ColonyFire.initial_state()
var defense_state: Dictionary = {}
var director_state: Dictionary = {}
var equipment_state: Dictionary = {}
var construction_state: Dictionary = ColonyConstruction.initial_state()
var domestic_state: Dictionary = ColonyDomestic.initial_state()
var wildlife_state: Dictionary = ColonyWildlife.initial_state()
var danger_cache_tick: int = -1
var danger_cache: Array[Vector2i] = []
var nature_state: Dictionary = ColonyNature.initial_state()
var terrain_state: Dictionary = ColonyGeneration.empty_state()
var generator_version: int = 0
var site_id: String = "meadow_reach"
var weather_state: Dictionary = {}
var flood_cache: Dictionary = {}
var flood_cache_valid: bool = false
var weather: String = "clear"
var navigation_dirty: bool = true
var solid_tiles: Dictionary = {}
var reachable_home: Dictionary = {}
var reachability_dirty: bool = true
var record_indexes: Dictionary = {}
var designations: Array[Vector2i] = []
var receipts: Dictionary = {}
var pending_commands: Array[Dictionary] = []
var facts: Array[Dictionary] = []
var ledger: Dictionary = {"produced":{},"recovered":{},"traded_in":{},"expedition_gain":{},"consumed":{},"spoiled":{},"lost":{},"traded_out":{},"looted":{}}
var use_rations: bool = false
var path_requests: int = 0
var command_trace: Array[Dictionary] = []
var in_tick: bool = false
var committing_work: bool = false
var work_commits: Array[Dictionary] = []

func _init(catalog: Dictionary, session: String = "m1-test") -> void:
	definitions = catalog.duplicate(true)
	session_id = session
	var levels: Array[Dictionary] = [{"Cooking": 3, "Care": 2, "Craft": 1}, {"Build": 3, "Craft": 2, "Guard": 1}, {"Field": 3, "Guard": 2, "Care": 1}, {"Study": 3, "Craft": 2, "Field": 1}]
	var traits: Array[Array] = [["Kind", "Homebody"], ["Steady", "Sociable"], ["Outdoorsy", "Restless"], ["Curious", "Private"]]
	for index in range(4):
		var skills: Dictionary = {}
		var xp: Dictionary = {}
		for skill in SKILLS:
			skills[skill] = levels[index].get(skill, 0)
			xp[skill] = THRESHOLDS[skills[skill]] * 1000
		var preferences: Dictionary = {}
		for category in CATEGORIES:
			preferences[category] = 1 if category in ["Research", "Guard"] else 2
		var preferred: String = ["Cooking", "Building", "Gathering", "Research"][index]
		preferences[preferred] = 3
		if index == 0:
			preferences.Care = 3
		citizens.append(citizen_record(index+1,["Mira","Oren","Tavi","Sela"][index],Vector2i(65+index,65),skills,xp,traits[index],preferred,preferences,["Vegetable","Grain","Berry","Mushroom"][index],"spear" if index in [0,3] else "bow"))
	for citizen in citizens:
		citizen.merge(ColonyCombat.citizen_defaults())
		for item in citizen.equipment.values():
			if not item.is_empty(): _record("produced",item,1)
	for index in range(4):
		var anchor: Vector2i = [Vector2i(62, 59), Vector2i(64, 59), Vector2i(62, 61), Vector2i(64, 61)][index]
		var bed: Dictionary = _structure("bedroll", anchor, 0)
		bed.user = index + 1
		citizens[index].bed = bed.id
	var cart: Dictionary = _structure("supply_cart", Vector2i(66, 63), 0)
	stores.append({"id": cart.id, "tiles": [Vector2i(66, 63)], "capacity": 300, "priority": 2, "filters": definitions.items.keys()})
	var hearth: Dictionary = _structure("hearth", Vector2i(70, 62), 0)
	hearth.fuel = 4
	_record("produced", "wood", 4)
	for item in {"meal": 24, "wood": 40, "stone": 30, "fiber": 12, "herb": 8, "travel_ration": 8}:
		_make_stack(item, {"meal": 24, "wood": 40, "stone": 30, "fiber": 12, "herb": 8, "travel_ration": 8}[item], "store", cart.id, Vector2i(66, 63), true)
	# Authored M1 resource fixture. The complete seeded/site generator follows later.
	var kinds: Array[String] = ["tree", "berry_bush", "mushroom_patch", "herb_patch", "stone_node"]
	for index in range(48):
		var kind: String = kinds[0 if index < 30 else (1 if index < 38 else (2 if index < 44 else (3 if index < 46 else 4)))]
		var point: Vector2i = Vector2i(55 - (index % 6) * 2, 54 + (index / 6) * 3)
		resources.append({"id": _id(), "definition": kind, "x": point.x, "y": point.y, "remaining": definitions.resources[kind].yield_count, "regrow_at": 0})

	director_state=ColonyDirector.initial_state(seed,generator_version,site_id)
	defense_state=ColonyDefense.initial_state(seed,generator_version,site_id)
	region_state=ColonyRegion.initial_state(seed,generator_version,site_id)
	trade_state=ColonyTrade.initial_state(seed,generator_version,site_id)
	population_state=ColonyPopulation.initial_state(seed,generator_version,site_id)
	equipment_state=ColonyEquipment.initial_state(citizens)
	ColonyWeather.initialize(self)
	ColonySocial.initialize(self)
	ColonyProduction.initialize(self)
	ColonyCare.initialize(self)

func _id() -> int:
	var result: int = next_id
	next_id += 1
	return result

static func inside(point: Vector2i) -> bool:
	return point.x >= 0 and point.y >= 0 and point.x < SIZE and point.y < SIZE

func is_water(point: Vector2i) -> bool:
	if structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="bridge" and s.x==point.x and s.y==point.y): return false
	if generator_version > 0 and inside(point): return terrain_state.elevation[point.y*128+point.x] == 0 and not terrain_state.bridges.has(point)
	return point.x >= 32 and point.x <= 35 and point.y not in [63, 64]

func walkable(point: Vector2i) -> bool:
	if not inside(point) or is_water(point):
		return false
	if navigation_dirty:
		care_destinations.clear()
		solid_tiles.clear()
		for resource in resources:
			if resource.remaining > 0 and definitions.resources[resource.definition].solid:
				solid_tiles[Vector2i(resource.x,resource.y)] = true
		for structure in structures:
			if structure.health<=0: continue
			if structure.definition != "supply_cart" and definitions.buildings[structure.definition].solid:
				for tile in footprint(structure):
					solid_tiles[tile] = true
		navigation_dirty = false
		reachability_dirty = true
	return not solid_tiles.has(point)

func accessible(point: Vector2i) -> bool:
	walkable(Vector2i.ZERO)
	if reachability_dirty:
		reachable_home.clear()
		var queue: Array[Vector2i] = []
		for citizen in citizens:
			var start: Vector2i = Vector2i(citizen.x,citizen.y)
			if citizen.health > 0 and not citizen.departed and walkable(start) and not reachable_home.has(start):
				reachable_home[start] = true
				queue.append(start)
		var cursor: int = 0
		while cursor < queue.size():
			var tile: Vector2i = queue[cursor]
			cursor += 1
			for delta in ColonyNavigation.NEIGHBORS:
				var neighbor: Vector2i = tile + delta
				if not reachable_home.has(neighbor) and walkable(neighbor) and can_step(tile,neighbor):
					reachable_home[neighbor] = true
					queue.append(neighbor)
		reachability_dirty = false
	return reachable_home.has(point)


func footprint(object: Dictionary) -> Array[Vector2i]:
	var definition: Dictionary = definitions.buildings.get(object.definition, {"width": 2, "height": 2})
	var width: int = definition.width if object.rotation % 2 == 0 else definition.height
	var height: int = definition.height if object.rotation % 2 == 0 else definition.width
	var result: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			result.append(Vector2i(object.x + x, object.y + y))
	return result

func _structure(kind: String, anchor: Vector2i, rotation: int) -> Dictionary:
	var result: Dictionary = {"id": _id(), "definition": kind, "x": anchor.x, "y": anchor.y, "rotation": rotation,
		"health": definitions.buildings.get(kind,{}).get("health",200), "user": 0, "fuel": 0, "cooking": true, "heat_ticks": 0}
	structures.append(result)
	if kind == "bridge" and generator_version > 0 and not terrain_state.bridges.has(anchor): terrain_state.bridges.append(anchor)
	rooms_dirty = true
	navigation_dirty = true
	return result

func find(records: Array, id: int) -> Dictionary:
	if id == 0:
		return {}
	var table: String = ""
	for name in ["citizens","structures","resources","stacks","jobs","stores","fields"]:
		if is_same(records,get(name)):
			table = name
			break
	if not table.is_empty():
		var index: Dictionary = record_indexes.get(table,{})
		if index.has(id):
			return index[id]
		for record in records:
			if record.id == id:
				index[id] = record
				record_indexes[table] = index
				return record
		return {}
	for record in records:
		if record.id == id:
			return record
	return {}

func queue_command(kind: String, args: Dictionary, command_id: int = 0, expected_session: String = "") -> int:
	var id: int = command_id if command_id > 0 else next_command_id
	next_command_id = maxi(next_command_id, id + 1)
	pending_commands.append({"id": id, "session": session_id if expected_session.is_empty() else expected_session,
		"kind": kind, "args": args.duplicate(true)})
	return id

func queue_designation(tiles: Array[Vector2i], command_id: int = 0, expected_session: String = "") -> int:
	return queue_command("stockpile", {"tiles": tiles}, command_id, expected_session)

func step() -> void:
	if care_state.ended: return
	in_tick=true;work_commits.clear()
	tick += 1
	path_requests = 0
	pending_commands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	for command in pending_commands:
		if not receipts.has(command.id):
			receipts[command.id] = _command(command) if command.session == session_id else "wrong_session"
			command_trace.append({"tick": tick, "command": command.duplicate(true)})
	pending_commands.clear()
	ColonyDefense.advance(self)
	ColonyFire.advance(self)
	ColonyCare.advance(self)
	ColonyWeather.advance(self)
	ColonyAgriculture.advance(self)
	ColonyRegion.advance(self)
	ColonyTrade.advance(self)
	ColonyPopulation.advance(self)
	ColonyDomestic.advance(self)
	ColonyWildlife.advance(self)
	ColonyNature.advance(self)
	ColonySocial.advance(self)
	ColonyLiving.advance(self)
	for citizen in citizens:
		_needs(citizen)
	ColonyDirector.advance(self)
	if tick % 10 == 0:
		_create_work()
		ColonyProduction.create_jobs(self)
		ColonyAgriculture.create_jobs(self)
		ColonyFire.create_jobs(self)
		ColonyCare.create_jobs(self)
		ColonyNature.create_jobs(self)
		ColonyDomestic.create_jobs(self)
		ColonyConstruction.create_helpers(self)
		ColonyEquipment.create_jobs(self)
		for citizen in citizens:
			_assign(citizen)
	for citizen in citizens:
		if citizen.job > 0:
			_work(citizen, find(jobs, citizen.job))
	ColonyCombat.resolve(self)
	committing_work=true
	for transaction in work_commits:
		var job: Dictionary = find(jobs,transaction.job);var worker: Dictionary = find(citizens,transaction.worker)
		if job.is_empty() or worker.is_empty() or job.worker!=worker.id or worker.job!=job.id or worker.downed or worker.death_recorded or worker.departed: continue
		if transaction.kind=="finish": _finish(worker,job)
		elif transaction.kind=="water": ColonyFire.water_ready(self,worker,job)
		elif transaction.kind=="move_phase": ColonyMaintenance.finish_dismantle(self,worker,job)
	committing_work=false;in_tick=false

func placement_error(kind: String, anchor: Vector2i, rotation: int, excluded_job: int = 0, excluded_structure: int = 0) -> String:
	if not definitions.buildings.has(kind) or rotation not in [0, 1, 2, 3]:
		return "Unknown building or rotation"
	if not definitions.buildings[kind].buildable: return "The supply cart cannot be built; move the existing cart instead"
	var unlock: String = definitions.buildings[kind].unlock
	if unlock != "initial" and not researched.has(unlock):
		return "Requires " + unlock.capitalize() + " research"
	var blueprint: Dictionary = {"definition": kind, "x": anchor.x, "y": anchor.y, "rotation": rotation}
	if kind == "fishing_pier":
		var water: int = footprint(blueprint).filter(func(p:Vector2i)->bool:return inside(p) and is_water(p)).size()
		if water != 2: return "Pier needs two land cells and two adjacent river cells"
	for point in footprint(blueprint):
		if not inside(point): return "Outside map"
		if kind == "bridge" and not is_water(point): return "Bridge needs an unbridged river tile"
		var overlay_under_structure: bool = kind in ColonyConstruction.OVERLAYS and not is_water(point) and structures.any(func(s:Dictionary)->bool:return footprint(s).has(point)) and not resources.any(func(r:Dictionary)->bool:return r.remaining>0 and definitions.resources[r.definition].solid and Vector2i(r.x,r.y)==point)
		if not walkable(point) and not overlay_under_structure and not (kind in ["bridge","fishing_pier"] and is_water(point)):
			return "Blocked terrain"
		for structure in structures:
			if structure.health<=0 or structure.id==excluded_structure: continue
			if kind in ColonyConstruction.OVERLAYS and structure.definition=="bridge" and footprint(structure).has(point): return "Bridge already provides its deck"
			if (kind in ColonyConstruction.OVERLAYS)!=(structure.definition in ColonyConstruction.OVERLAYS): continue
			if footprint(structure).has(point):
				return "Occupied by " + structure.definition
		for field in fields:
			if Vector2i(field.x, field.y) == point:
				return "Field occupies this tile: clear its order first"
		for job in jobs:
			if job.id!=excluded_job and job.kind=="move_furniture" and job.state not in ["Complete","Canceled"] and ColonyMaintenance.move_footprint(self,job).has(point): return "Reserved furniture move destination"
			if job.id != excluded_job and job.kind == "build" and job.state not in ["Complete", "Canceled"] and footprint(job).has(point) and ((kind in ColonyConstruction.OVERLAYS)==(job.definition in ColonyConstruction.OVERLAYS)):
				return "Another blueprint occupies this tile"
	if definitions.buildings[kind].solid:
		var blocked: Array[Vector2i] = footprint(blueprint)
		for citizen in citizens:
			if citizen.death_recorded or citizen.departed or citizen.carried_by>0: continue
			var start: Vector2i = Vector2i(citizen.x, citizen.y)
			if blocked.has(start) or (citizen.progress > 0 and blocked.has(Vector2i(citizen.edge_x, citizen.edge_y))):
				return "A resident occupies this tile"
			var cart: Dictionary = structures.filter(func(s:Dictionary)->bool:return s.definition == "supply_cart")[0]
			var destination: Vector2i = Vector2i(cart.x,cart.y)
			if start != destination and ColonyNavigation.path(start, destination, func(point: Vector2i) -> bool: return walkable(point) and not blocked.has(point),can_step).is_empty():
				return "Closes a resident's last exit"
	var work: Array[Vector2i] = _perimeter(footprint(blueprint))
	return "No work position" if work.is_empty() else ""

func gather_targets(definition: String, tiles: Array) -> Array[Dictionary]:
	var area: Dictionary = {}
	for tile in tiles:
		area[tile] = true
	var ordered: Dictionary = {}
	for job in jobs:
		if job.kind == "gather" and job.state not in ["Complete", "Canceled"]:
			ordered[job.target] = true
	var targets: Array[Dictionary] = []
	for resource in resources:
		if resource.definition == definition and resource.remaining > 0 and area.has(Vector2i(resource.x,resource.y)) and not ordered.has(resource.id):
			targets.append(resource)
	targets.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return a.id < b.id)
	return targets

func _command(command: Dictionary) -> String:
	var args: Dictionary = command.args
	match command.kind:
		"stockpile":
			if args.tiles.is_empty():
				return "empty_area"
			for point: Vector2i in args.tiles:
				if fields.any(func(f:Dictionary)->bool:return Vector2i(f.x,f.y)==point) or domestic_state.pens.any(func(p:Dictionary)->bool:return p.tiles.has(point)): return "Stockpile overlaps field or pen"
				if not walkable(point):
					return "invalid_tile"
				for store in stores:
					if store.tiles.has(point):
						return "store_overlap"
			var tiles: Array = []
			for point: Vector2i in args.tiles:
				if not tiles.has(point):
					tiles.append(point)
				if not designations.has(point):
					designations.append(point)
			stores.append({"id": _id(), "tiles": tiles, "capacity": tiles.size() * 50, "priority": 2, "filters": definitions.items.keys()})
		"build":
			var error: String = placement_error(args.definition, Vector2i(args.x, args.y), args.rotation)
			if not error.is_empty():
				return error
			var definition: Dictionary = definitions.buildings[args.definition]
			var job: Dictionary = _job("build", "Building", "Build", 0, Vector2i(args.x, args.y), definition.work_milli)
			job.definition = args.definition
			job.rotation = args.rotation
			job.inputs = definition.materials.duplicate()
		"gather":
			var resource: Dictionary = find(resources, args.target)
			if resource.is_empty() or resource.remaining == 0:
				return "target_empty"
			for job in jobs:
				if job.target == resource.id and job.kind == "gather" and job.state not in ["Complete", "Canceled"]:
					return "already_ordered"
			var definition: Dictionary = definitions.resources[resource.definition]
			_job("gather", "Gathering", "Field", resource.id, Vector2i(resource.x, resource.y), definition.work_milli)
		"gather_area":
			if not definitions.resources.has(args.definition) or args.tiles.is_empty():
				return "invalid_gather_area"
			for tile in args.tiles:
				if not tile is Vector2i or not inside(tile):
					return "invalid_tile"
			var targets: Array[Dictionary] = gather_targets(args.definition, args.tiles)
			if targets.is_empty():
				return "No unmarked resources in this area"
			for resource in targets:
				var job: Dictionary = _job("gather", "Gathering", "Field", resource.id, Vector2i(resource.x, resource.y), definitions.resources[args.definition].work_milli)
				# A mining designation repeats unit work until the marked deposit is empty.
				job.definition = resource.definition
		"cancel":
			var job: Dictionary = find(jobs, args.target)
			if job.is_empty():
				return "missing_target"
			if job.state == "Complete":
				return "already_completed"
			if job.kind=="expedition_pack": ColonyRegion.cancel(self,find(region_state.trips,job.target))
			else: _release(job, true)
		"preference":
			var citizen: Dictionary = find(citizens, args.citizen)
			if citizen.is_empty() or not args.category in CATEGORIES or not args.value in [0, 1, 2, 3]:
				return "invalid_preference"
			citizen.preferences[args.category] = args.value
			if citizen.job > 0:
				var job: Dictionary = find(jobs, citizen.job)
				if job.kind not in ["eat", "sleep"]:
					_release(job, false)
		"field": return ColonyAgriculture.designate(self, args)
		"draft", "undraft", "focus", "shelter", "open_passage", "stand_down", "raid_ack", "raid_offer", "enemy_treat": return ColonyDefense.command(self,command.kind,args)
		"expedition_prepare", "expedition_depart", "expedition_cancel", "expedition_recall", "expedition_choice", "expedition_collect": return ColonyRegion.command(self,command.kind,args)
		"trade", "trade_cancel": return ColonyTrade.command(self,command.kind,args)
		"newcomer": return ColonyPopulation.command(self,args)
		"cart_move": return ColonyMaintenance.cart_command(self,args)
		"move_furniture": return ColonyMaintenance.move_command(self,args)
		"repair", "demolish", "rebuild": return ColonyMaintenance.command(self,command.kind,args)
		"equip", "equipment_policy": return ColonyEquipment.command(self,command.kind,args)
		"build_area", "lodge": return ColonyConstruction.command(self,command.kind,args)
		"pen", "breeding", "slaughter": return ColonyDomestic.command(self,command.kind,args)
		"hunt": return ColonyWildlife.command(self,args)
		"forest", "forest_policy", "replant_tree", "clear_sapling": return ColonyNature.command(self,command.kind,args)
		"care_mode", "treat_now", "burial": return ColonyCare.command(self,command.kind,args)
		"station_enabled":
			var station: Dictionary = find(structures,args.target)
			if station.is_empty(): return "Missing workstation"
			station.cooking = args.enabled
			for job in jobs:
				if job.target == station.id and job.kind in ["cook","craft","research","fish"] and job.worker > 0: _release(job,false)
		"recipe_order", "order_enabled", "research_select", "research_queue": return ColonyProduction.command(self,command.kind,args)
		"request_accept", "request_decline", "mediate": return ColonySocial.command(self,command.kind,args)
		"early_harvest":
			var field: Dictionary = find(fields,args.target)
			if field.is_empty() or not field.planted: return "No planted crop on this tile"
			var definition: Dictionary = definitions.crops[field.crop]
			if field.growth * 2 < definition.growth: return "Early harvest requires at least 50% growth"
			if jobs.any(func(job:Dictionary)->bool:return job.kind == "harvest" and job.target == field.id and job.state not in ["Complete","Canceled"]): return "Already ordered"
			var job: Dictionary = _job("harvest","Growing","Field",field.id,Vector2i(field.x,field.y),definition.harvest_milli)
			job.definition = "early_harvest"
			job.priority = 3
		"clear_field":
			var field: Dictionary = find(fields, args.target)
			if field.is_empty():
				return "missing_field"
			for job in jobs:
				if job.target == field.id and job.state not in ["Complete", "Canceled"]:
					_release(job, true)
			fields.erase(field)
			record_indexes.clear()
		"stock_filter":
			var store: Dictionary = find(stores, args.target)
			if store.is_empty() or not args.filters.all(func(item: Variant) -> bool: return definitions.items.has(item)) or args.priority not in [1,2,3]:
				return "invalid_storage_filter"
			store.filters = args.filters.duplicate()
			store.priority = args.priority
			for job in jobs:
				if job.kind == "haul" and job.destination == store.id and job.worker > 0:
					var source: Dictionary = find(stacks,job.source)
					if not source.is_empty() and not store.filters.has(source.item):
						_release(job,false)
		"schedule":
			var citizen: Dictionary = find(citizens, args.citizen)
			if citizen.is_empty() or args.shift not in ["Normal", "Night shift"]:
				return "invalid_schedule"
			var job: Dictionary = find(jobs,citizen.job)
			if not job.is_empty() and job.kind in ["sleep","eat"]:
				citizen.pending_shift = args.shift
			else:
				citizen.shift = args.shift
		"pin":
			var citizen: Dictionary = find(citizens,args.citizen)
			var job: Dictionary = find(jobs,args.target)
			if citizen.is_empty() or job.is_empty() or job.state in ["Complete","Canceled"] or citizen.preferences.get(job.category,0) == 0:
				return "Pinned work is missing or its category is Off"
			if job.worker > 0 and job.worker != citizen.id:
				return "Already assigned to another resident"
			citizen.pinned_job = job.id
			if citizen.job > 0:
				var current: Dictionary = find(jobs,citizen.job)
				if current.kind not in ["eat","sleep"]:
					_release(current,false)
		"priority":
			var job: Dictionary = find(jobs, args.target)
			if job.is_empty() or args.value not in [1, 2, 3]:
				return "invalid_priority"
			job.priority = args.value
		"food_policy": use_rations = args.enabled
		_: return "unknown_command"
	return "accepted"

func _job(kind: String, category: String, skill: String, target: int, point: Vector2i, effort: int) -> Dictionary:
	var job: Dictionary = {"id": _id(), "kind": kind, "category": category, "skill": skill, "target": target,
		"x": point.x, "y": point.y, "definition": "", "rotation": 0, "required": effort, "work": 0,
		"state": "Ready", "worker": 0, "priority": 2, "created": tick, "inputs": {}, "output": {},
		"source": 0, "destination": 0, "work_x": point.x, "work_y": point.y, "reason": "", "retry": 0, "worker_days": {}, "order":0, "care_goal":[], "emergency":false, "amount":0, "memo":{},
		"rate_remainders": {}, "pending_xp": {}}
	jobs.append(job)
	return job

func _perimeter(tiles: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for tile in tiles:
		for delta in ColonyNavigation.NEIGHBORS:
			var point: Vector2i = tile + delta
			if not tiles.has(point) and walkable(point) and not result.has(point):
				result.append(point)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y * SIZE + a.x < b.y * SIZE + b.x)
	return result

func _create_work() -> void:
	for hearth in structures:
		if hearth.health<=0 or hearth.definition != "hearth":
			continue
		if hearth.fuel < 4 and ColonyLiving.temperature(self) < 8 and available("wood") >= 8 - hearth.fuel and not jobs.any(func(job: Dictionary) -> bool: return job.kind == "fuel" and job.target == hearth.id and job.state not in ["Complete", "Canceled"]):
			var fuel_job: Dictionary = _job("fuel", "Hauling", "", hearth.id, Vector2i(hearth.x,hearth.y), 0)
			fuel_job.inputs = {"wood": 8 - hearth.fuel}
		if not hearth.cooking:
			continue
		if production_state.orders.any(func(order:Dictionary)->bool:return order.station == hearth.id):
			continue
		var active: bool = false
		var output_batches: int = 0
		var in_progress: int = 0
		for stack in stacks:
			if stack.location == "output" and stack.owner == hearth.id:
				output_batches += 1
		for job in jobs:
			if job.kind in ["cook","craft"] and job.target == hearth.id and job.state not in ["Complete", "Canceled"]:
				active = true
				in_progress += 2
		if not active and output_batches < 2 and available("meal") + in_progress < citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed and not c.away).size() * 4:
			var recipe: Dictionary = definitions.recipes.cook_meals
			var inputs: Dictionary = recipe.materials.duplicate()
			var count: int = 0
			var food: Array[Dictionary] = []
			for stack in stacks:
				if recipe.alternatives.has(stack.item) and stack.location in ["ground","store","output"] and stack.count > _reserved(stack) and ColonyFire.usable(self,stack) and accessible(Vector2i(stack.x,stack.y)):
					food.append(stack)
			food.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
				var ae: int = FoodForecast.expiry_ticks(self,a)
				var be: int = FoodForecast.expiry_ticks(self,b)
				var ad: int = absi(a.x-hearth.x)+absi(a.y-hearth.y)
				var bd: int = absi(b.x-hearth.x)+absi(b.y-hearth.y)
				return ae < be or (ae == be and (ad < bd or (ad == bd and (a.item < b.item or (a.item == b.item and a.id < b.id))))))
			for stack in food:
				var item: String = stack.item
				var quantity: int = mini(4 - count, stack.count-_reserved(stack))
				if quantity > 0:
					inputs[item] = inputs.get(item,0)+quantity
					count += quantity
			if count == 4 and available("wood") >= 1:
				var job: Dictionary = _job("cook", "Cooking", "Cooking", hearth.id, Vector2i(hearth.x, hearth.y), recipe.work_milli)
				job.inputs = inputs
				job.output = recipe.outputs.duplicate()
	for stack in stacks.duplicate():
		var invalid_store: bool = false
		if stack.location == "store":
			var store: Dictionary = find(stores,stack.owner)
			invalid_store = store.is_empty() or not store.filters.has(stack.item)
		if stack.count == 0 or (stack.location not in ["ground", "output"] and not invalid_store) or _reserved(stack) > 0:
			continue
		var exists: bool = false
		for job in jobs:
			if job.kind == "haul" and job.source == stack.id and job.state not in ["Complete", "Canceled"]:
				exists = true
		if not exists:
			var job: Dictionary = _job("haul", "Hauling", "", stack.id, Vector2i(stack.x, stack.y), 0)
			job.source = stack.id

func _needs(citizen: Dictionary) -> void:
	if citizen.away:
		ColonyRegion.needs(self,citizen);return
	if citizen.death_recorded or citizen.departed: return
	citizen.hunger_rem += 1000
	citizen.fullness = maxi(0, citizen.fullness - citizen.hunger_rem / 7200)
	citizen.hunger_rem %= 7200
	var job: Dictionary = find(jobs, citizen.job)
	var sleeping: bool = citizen.downed or (not job.is_empty() and job.kind in ["sleep","recover"] and job.state == "Working")
	var rate: int = 50
	if sleeping:
		var bed: Dictionary = find(structures, citizen.bed if citizen.downed else job.target)
		if citizen.downed:
			bed = {}
			for structure in structures:
				if structure.health>0 and structure.definition in ["bed","bedroll"] and footprint(structure).has(Vector2i(citizen.x,citizen.y)):
					bed = structure
					break
		rate = 80 if bed.is_empty() else (150 if bed.definition == "bed" else 120)
	citizen.rest_rem += rate
	var change: int = citizen.rest_rem / 300
	citizen.rest_rem %= 300
	citizen.rest = clampi(citizen.rest + (change if sleeping else -change), 0, 1000)
	if citizen.fullness == 0:
		if citizen.starving_ticks == 0:
			facts.append({"tick":tick,"actor":citizen.id,"job":0,"kind":"starvation_warning","text":citizen.name+" is at zero fullness. After six continuous hours without food they lose 5 health/hour. Feed downed patients through Care; gather food and enable Cooking."})
		citizen.starving_ticks += 1
		if citizen.starving_ticks > 1800 and (citizen.starving_ticks - 1800) % 300 == 0:
			ColonyCare.hurt(self,citizen,5)
	else:
		citizen.starving_ticks = 0

func _assign(citizen: Dictionary) -> void:
	if citizen.away: return
	if citizen.death_recorded or citizen.departed:
		citizen.activity = "Died" if citizen.death_recorded else "Departed"
		return
	if citizen.downed:
		citizen.activity = "Hearthside recovery" if citizen.hearthside_until > tick else ("Downed: bleeding, needs care" if not citizen.stabilized else "Downed: recovering")
		return
	if ColonyDanger.escape(self,citizen): return
	if ColonyConstruction.step_aside(self,citizen): return
	var arrival: Dictionary = jobs.filter(func(j:Dictionary)->bool:return j.kind=="arrival" and j.target==citizen.id and j.state not in ["Complete","Canceled"]).front() if jobs.any(func(j:Dictionary)->bool:return j.kind=="arrival" and j.target==citizen.id and j.state not in ["Complete","Canceled"]) else {}
	var hour: int = ((tick % 7200) / 300 + (12 if citizen.shift == "Night shift" else 0)) % 24
	var needs_sleep: bool = citizen.rest <= 300 or ((hour >= 22 or hour < 6) and citizen.rest < 900)
	var current: Dictionary = find(jobs, citizen.job)
	var treatment_wait: bool = citizen.fullness > 0 and citizen.rest > 100 and jobs.any(func(j:Dictionary)->bool:return j.kind == "treat" and j.target == citizen.id and j.state not in ["Complete","Canceled"])
	if treatment_wait and current.get("kind") not in ["eat","sleep"]:
		_release(current,false)
		citizen.activity = "Resting for treatment"
		return
	if not current.is_empty():
		var emergency: bool = citizen.health > 20 and citizen.break_until <= tick and citizen.fullness > 0 and citizen.rest > 100 and jobs.any(func(j:Dictionary)->bool:return j.emergency and (j.kind!="extinguish" or citizen.preferences.Care>0) and j.worker == 0 and j.state not in ["Complete","Canceled"] and tick >= j.retry)
		if (current.emergency and (citizen.fullness == 0 or citizen.rest <= 100)) or (current.kind not in ["eat","sleep"] and not current.emergency and (emergency or citizen.fullness <= 350 or needs_sleep)) or (current.kind == "sleep" and citizen.fullness == 0 and not _food(citizen).is_empty()):
			_release(current, false)
		else:
			return
	if citizen.health > 20 and citizen.fullness > 0 and citizen.rest > 100 and citizen.break_until <= tick:
		var emergencies: Array = jobs.filter(func(j:Dictionary)->bool:return j.emergency and (j.kind!="extinguish" or citizen.preferences.Care>0) and j.worker == 0 and j.state not in ["Complete","Canceled"] and tick >= j.retry)
		emergencies.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _higher_score(a,b,citizen))
		for emergency in emergencies:
			if _reserve(emergency,citizen): citizen.job = emergency.id; return
	if citizen.fullness <= 350:
		var food: Dictionary = _food(citizen)
		if not food.is_empty():
			var eat_job: Dictionary = _job("eat", "", "", citizen.id, Vector2i(citizen.x, citizen.y), 2000)
			eat_job.inputs = {food.item: 1}
			eat_job.source = food.id
			if _reserve(eat_job, citizen):
				citizen.job = eat_job.id
				return
		citizen.activity = "Hungry: gather berries or mushrooms and enable Cooking"
	if needs_sleep and (citizen.fullness > 350 or citizen.rest <= 100):
		var bed: Dictionary = find(structures, citizen.bed)
		var point: Vector2i = Vector2i(citizen.x, citizen.y) if bed.is_empty() or citizen.rest <= 100 else Vector2i(bed.x, bed.y)
		if citizen.rest <= 100: bed = {}
		var sleep_job: Dictionary = _job("sleep", "", "", 0 if bed.is_empty() else bed.id, point, 0)
		sleep_job.worker = citizen.id
		sleep_job.state = "Moving"
		sleep_job.work_x = point.x
		sleep_job.work_y = point.y
		citizen.job = sleep_job.id
		return
	if citizen.health < 50:
		var destination: Dictionary = ColonyCare.destination(self,citizen)
		var recovery: Dictionary = _job("recover","","",destination.id,destination.point,0)
		recovery.worker = citizen.id; recovery.state = "Moving"
		citizen.job = recovery.id
		return
	if ColonyDefense.shelter_assign(self,citizen): return
	if ColonyDefense.assign(self,citizen): return
	if ColonyRegion.assign(self,citizen): return
	if not arrival.is_empty() and _reserve(arrival,citizen):
		citizen.job=arrival.id
		return
	if citizen.departure_until > 0 and tick >= citizen.departure_until:
		var depart_job: Dictionary = _job("depart", "", "", citizen.id, Vector2i(66,127), 0)
		depart_job.worker = citizen.id
		depart_job.state = "Moving"
		citizen.job = depart_job.id
		return
	if citizen.break_until > tick or (hour >= 18 and hour < 20 and citizen.leisure_ticks < 600):
		var urgent: bool = jobs.any(func(job: Dictionary) -> bool: return job.priority == 3 and job.state not in ["Complete", "Canceled"])
		if citizen.break_until > tick or not urgent:
			var leisure: Dictionary = _job("leisure", "", "", citizen.id, ColonySocial.leisure_seat(self,citizen), 0)
			leisure.state = "Moving"
			leisure.worker = citizen.id
			citizen.job = leisure.id
			return
	if citizen.pinned_job > 0:
		var pinned: Dictionary = find(jobs,citizen.pinned_job)
		if not pinned.is_empty() and pinned.worker == 0 and (citizen.preferences.get(pinned.category,0) > 0 or pinned.kind == "treat") and _reserve(pinned,citizen):
			citizen.job = pinned.id
			return
		citizen.pinned_job = 0
		citizen.activity = "Pinned task unavailable: check its inputs and route"
	var candidates: Array[Dictionary] = []
	for job in jobs:
		if job.worker != 0 or job.state in ["Complete", "Canceled"] or tick < job.retry or citizen.preferences.get(job.category, 0) == 0:
			continue
		candidates.append(job)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _higher_score(a,b,citizen))
	for job in candidates:
		if _reserve(job, citizen):
			citizen.job = job.id
			return
	if citizen.fullness > 350:
		citizen.activity = "Idle: designate resources or place a blueprint"

func _score(job: Dictionary, citizen: Dictionary) -> Array:
	return [mini(3, job.priority + (tick - job.created) / 7200), citizen.preferences.get(job.category, 0),
		1 if citizen.preferred == job.category else 0, citizen.skills.get(job.skill, 0),
		-absi(citizen.x - job.x) - absi(citizen.y - job.y), -job.id]

func _higher_score(a: Dictionary, b: Dictionary, citizen: Dictionary) -> bool:
	var aa: Array = _score(a,citizen)
	var bb: Array = _score(b,citizen)
	for index in range(aa.size()):
		if aa[index] != bb[index]: return aa[index] > bb[index]
	return false

func _reserve(job: Dictionary, citizen: Dictionary) -> bool:
	if job.kind=="enemy_treat" and find(defense_state.enemies,job.target).get("state")!="Downed": _release(job,true);return false
	if job.kind=="raid_pay" and find(defense_state.raids,job.target).get("state")!="Payment": return _block(job,"Payment is no longer awaiting delivery")
	if job.kind=="extinguish": return ColonyFire.reserve(self,job,citizen)
	if job.kind in ["repair","demolish","cook","craft","research","fuel","fish"] and ColonyFire.burning(self,"structure",job.target): return _block(job,"Burning station: extinguish first")
	if citizen.away: return false
	if job.kind=="expedition_pack" and not ColonyRegion.pack_ready(self,job): return false
	if job.kind=="trade" and not ColonyTrade.ready(self,job): return false
	if job.kind=="arrival" and job.target!=citizen.id: return false
	if job.kind=="cart_move" and job.memo.phase=="prepare":
		var cart: Dictionary = find(structures,job.target);job.x=cart.x;job.y=cart.y
	if job.kind in ["repair","demolish","move_furniture"] and not ColonyMaintenance.reserve(self,job): return false
	if job.kind == "equip" and not ColonyEquipment.reserve(self,job,citizen): return false
	if job.kind in ["build","build_helper"] and not ColonyConstruction.ready(self,job): return false
	if job.kind in ["stock_feed","lead_animal","collect_animal","slaughter"] and not ColonyDomestic.reserve(self,job,citizen): return false
	if job.kind in ["hunt","escort_hunt","butcher"] and not ColonyWildlife.reserve(self,job,citizen): return false
	if job.kind in ["plant_tree","clear_sapling","fish"] and not ColonyNature.reserve(self,job): return false
	if job.kind in ["rescue","treat","feed","bury"] and not ColonyCare.reserve(self,job,citizen): return false
	if job.kind in ["cook","craft"]: ColonyProduction.replace_food(self,job)
	if job.kind == "research" and job.definition != production_state.project: return _block(job,"Project inactive: choose it in Research to resume")
	if job.kind == "craft":
		var order: Dictionary = find(production_state.orders,job.order)
		if order.is_empty() or not order.enabled: return _block(job,"Production order paused")
	if job.kind in ["cook","craft","research","fish"]:
		if find(structures,job.target).get("health",0)<=0 or not find(structures,job.target).get("cooking",true): return _block(job,"Station suspended: enable it in the workstation card")
		for other in jobs:
			if other.id != job.id and other.target == job.target and other.worker > 0 and other.kind in ["cook","craft","research"]: return _block(job,"Workstation in use by another resident")
	for resident in citizens:
		if resident.pinned_job == job.id and resident.id != citizen.id and not job.emergency:
			return false
	var point: Vector2i = Vector2i(job.x, job.y)
	var positions: Array[Vector2i] = []
	if job.kind=="cart_move":
		var cart: Dictionary = find(structures,job.target);positions.append(Vector2i(cart.x,cart.y))
	elif job.kind=="move_furniture":
		positions=_perimeter(ColonyMaintenance.move_footprint(self,job)) if job.memo.phase=="rebuild" else _perimeter(footprint(find(structures,job.target)))
	elif job.kind in ["build","build_helper"]:
		positions = _perimeter(footprint(job))
	elif job.kind in ["repair","demolish", "gather", "cook", "fuel", "prepare", "sow", "harvest", "replant", "mediate", "craft", "research", "treat", "feed", "bury", "plant_tree", "clear_sapling", "fish", "hunt", "escort_hunt", "butcher", "stock_feed", "lead_animal", "collect_animal", "slaughter", "enemy_treat"]:
		positions = _perimeter(footprint(find(structures, job.target))) if job.kind in ["repair","demolish","cook","fuel","craft","research","fish"] else _perimeter([point])
	else:
		positions.append(point)
	positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var ad: int = absi(a.x - citizen.x) + absi(a.y - citizen.y)
		var bd: int = absi(b.x - citizen.x) + absi(b.y - citizen.y)
		return ad < bd or (ad == bd and a.y * SIZE + a.x < b.y * SIZE + b.x))
	var work_position: Vector2i = Vector2i(-1, -1)
	for position in positions:
		var occupied: bool = false
		for other in jobs:
			if other.worker > 0 and other.id != job.id and other.work_x == position.x and other.work_y == position.y:
				occupied = true
		if not occupied:
			work_position = position
			break
	if work_position.x < 0:
		return _block(job, "No free work position")
	if job.kind not in ["hunt","escort_hunt"] and not job.emergency and not ColonyDanger.safe(self,work_position): return _block(job,"Unsafe route: work avoids eight tiles around danger")
	var requests: Array[Dictionary] = []
	if job.kind == "haul":
		var source: Dictionary = find(stacks, job.source)
		if source.is_empty() or source.count == 0:
			job.state = "Canceled"
			return false
		var quantity: int = mini(8, source.count - _reserved(source))
		if quantity <= 0:
			return _block(job, "Inputs reserved by another job; waiting for its completion")
		var destination: Dictionary = _destination(source.item, quantity, point, source.tags)
		if destination.is_empty():
			return _block(job, "No storage space: paint a stockpile or build a rack")
		job.destination = destination.id
		job.work_x = destination.tile.x
		job.work_y = destination.tile.y
		requests.append({"stack": source.id, "count": quantity})
	else:
		job.work_x = work_position.x
		job.work_y = work_position.y
		for item in job.inputs:
			var needed: int = job.inputs[item] - _escrow_count(job.id, item)
			for held_stack in stacks:
				if held_stack.item==item: needed-=held_stack.reservations.get(job.id,0)
				if held_stack.location=="carry" and held_stack.job==job.id and held_stack.item==item: needed-=held_stack.count
			if job.kind=="move_furniture":
				for bundle in stacks:
					if bundle.location=="move_bundle" and bundle.owner==job.id and bundle.item==item: needed -= bundle.count
			var sources: Array = stacks.filter(func(s:Dictionary)->bool:return s.item == item and s.count > _reserved(s) and s.location in ["ground","store","output"] and ColonyFire.usable(self,s) and accessible(Vector2i(s.x,s.y)))
			sources.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return ColonyProduction.input_before(self,a,b,Vector2i(citizen.x,citizen.y)))
			for stack in sources:
				if stack.item != item or stack.location not in ["ground", "store", "output"] or (job.kind in ["eat","feed"] and stack.id != job.source):
					continue
				var count: int = mini(needed, stack.count - _reserved(stack))
				if count > 0:
					requests.append({"stack": stack.id, "count": count})
					needed -= count
				if needed == 0:
					break
			if needed > 0:
				return _block(job, "Missing " + item + ": gather it or free reserved supplies")
	# Validate every input before committing any reservation.
	for request in requests:
		find(stacks, request.stack).reservations[job.id] = find(stacks, request.stack).reservations.get(job.id,0)+request.count
	job.worker = citizen.id
	job.state = "Fetching" if not requests.is_empty() or stacks.any(func(s:Dictionary)->bool:return s.reservations.get(job.id,0)>0) or (job.kind=="move_furniture" and stacks.any(func(s:Dictionary)->bool:return s.location=="move_bundle" and s.owner==job.id and s.count>0)) else "Moving"
	job.reason = ""
	return true

func _block(job: Dictionary, reason: String) -> bool:
	job.state = "Blocked"
	job.reason = reason
	job.retry = tick + 50
	return false

func _work(citizen: Dictionary, job: Dictionary) -> void:
	if job.is_empty():
		citizen.job = 0
		return
	if job.kind=="defend":
		ColonyDefense.defend_work(self,citizen,job);return
	if job.kind=="extinguish":
		ColonyFire.work(self,citizen,job);return
	if job.kind=="expedition_walk":
		ColonyRegion.walk_work(self,citizen,job);return
	if job.kind=="expedition_meet":
		if _walk(citizen,Vector2i(ColonyTrade.cart(self).x,ColonyTrade.cart(self).y)): _complete(citizen,job)
		return
	if job.kind=="arrival":
		ColonyPopulation.arrival_work(self,citizen,job)
		return
	if job.kind=="cart_move":
		ColonyMaintenance.cart_work(self,citizen,job)
		return
	if job.kind=="move_furniture" and job.memo.phase=="dismantle":
		ColonyMaintenance.move_dismantle(self,citizen,job)
		return
	if job.kind == "build_helper":
		ColonyConstruction.helper_work(self,citizen,job)
		return
	if job.kind == "lead_animal":
		ColonyDomestic.lead_work(self,citizen,job)
		return
	if job.kind in ["hunt","escort_hunt"]:
		ColonyWildlife.hunt_work(self,citizen,job)
		return
	if job.kind == "rescue":
		ColonyCare.rescue_work(self,citizen,job)
		return
	if job.kind in ["treat","feed"]:
		var patient: Dictionary = find(citizens,job.target)
		if patient.death_recorded or patient.carried_by > 0 or absi(patient.x-job.x)+absi(patient.y-job.y) > 0:
			_release(job,false)
			_block(job,"Patient moved: care will follow their position")
			return
	var activity: Dictionary = {
		"Fetching":"Fetching supplies", "Delivering":"Carrying supplies", "Moving":"Walking to the task", "Working":"Working"}
	citizen.activity = activity.get(job.state,job.reason)
	if job.kind == "sleep":
		citizen.activity = "Sleeping" if job.state == "Working" else "Heading to bed"
	elif job.kind == "eat":
		citizen.activity = "Eating" if job.state == "Working" else "Getting food"
	elif job.kind == "leisure":
		citizen.activity = "Taking leisure" if job.state == "Working" else "Walking to rest"
	elif job.state == "Working":
		citizen.activity = {"build":"Building "+job.definition,"gather":"Gathering","cook":"Cooking meals","prepare":"Preparing soil","sow":"Sowing","harvest":"Harvesting","fuel":"Refueling hearth"}.get(job.kind,"Working")
	match job.state:
		"Fetching":
			if job.kind=="move_furniture" and ColonyMaintenance.fetch_bundle(self,citizen,job): return
			var source: Dictionary = {}
			for stack in stacks:
				if stack.reservations.get(job.id, 0) > 0:
					source = stack
					break
			if source.is_empty():
				job.state = "Moving"
				return
			if _walk(citizen, Vector2i(source.x, source.y)):
				var held: int = 0
				for existing in stacks:
					if existing.location == "carry" and existing.owner == citizen.id: held += existing.count
				var quantity: int = mini(8-held, source.reservations[job.id])
				var carried: Dictionary = _make_stack(source.item, quantity, "carry", citizen.id, Vector2i(citizen.x, citizen.y), false)
				carried.age = source.age
				carried.age_rem = source.age_rem
				carried.tags = source.tags.duplicate()
				carried.job = job.id
				source.count -= quantity
				source.reservations[job.id] -= quantity
				if source.reservations[job.id] == 0:
					source.reservations.erase(job.id)
				if held+quantity >= 8 or not stacks.any(func(s:Dictionary)->bool:return s.reservations.get(job.id,0)>0): job.state = "Delivering"
		"Delivering":
			if _walk(citizen, Vector2i(job.work_x, job.work_y)):
				for stack in stacks:
					if stack.location == "carry" and stack.owner == citizen.id and stack.job == job.id:
						stack.location = "store" if job.kind == "haul" else "escrow"
						stack.owner = job.destination if job.kind == "haul" else job.id
						stack.x = job.work_x
						stack.y = job.work_y
						if job.kind == "haul" and find(structures,job.destination).is_empty():
							_merge_stored(stack)
				if job.kind == "haul":
					_complete(citizen, job)
				else:
					job.state = "Fetching"
		"Moving":
			if _walk(citizen, Vector2i(job.work_x, job.work_y)):
				if job.kind in ["escape","step_aside","shelter"]:
					_complete(citizen,job)
				elif job.kind == "depart":
					citizen.departed = true
					_complete(citizen, job)
				else:
					job.state = "Working"
		"Working":
			if job.kind == "leisure":
				citizen.leisure_ticks += 1
				if citizen.leisure_ticks >= 600 and citizen.break_until <= tick:
					_complete(citizen, job)
				return
			if job.kind == "recover":
				citizen.activity = "Recovering: ordinary work resumes at 50 health"
				if citizen.health >= 50: _complete(citizen,job)
				return
			if job.kind == "sleep":
				var hour: int = ((tick % 7200) / 300 + (12 if citizen.shift == "Night shift" else 0)) % 24
				if (hour >= 6 and hour < 22 and citizen.rest >= 900) or (hour == 6 and citizen.rest >= 500):
					_complete(citizen, job)
				return
			if job.kind == "research":
				ColonyProduction.research_work(self,citizen,job)
				return
			var work: int = _rate(citizen, job)
			work = mini(work, job.required - job.work)
			job.work += work
			if job.kind == "build": job.worker_days[citizen.id] = tick / 7200
			job.pending_xp[citizen.id] = job.pending_xp.get(citizen.id, 0) + work
			if job.work >= job.required:
				_finish(citizen, job)

func _walk(citizen: Dictionary, goal: Vector2i) -> bool:
	if citizen.progress == 0 and citizen.x == goal.x and citizen.y == goal.y:
		return true
	if citizen.progress == 0:
		if citizen.route_goal != [goal.x, goal.y] or citizen.route.is_empty():
			if path_requests >= 4:
				return false
			path_requests += 1
			citizen.route = ColonyNavigation.path(Vector2i(citizen.x, citizen.y), goal, func(p:Vector2i)->bool:return ColonyDanger.allowed(self,citizen,p),func(a:Vector2i,b:Vector2i)->bool:
				var task: Dictionary = find(jobs,citizen.job)
				return ColonyMaintenance.cart_edge(self,a,b) if task.get("kind")=="cart_move" and task.memo.phase=="push" and task.state=="Working" else can_step(a,b))
			citizen.route_goal = [goal.x, goal.y]
		if citizen.route.is_empty():
			var job: Dictionary = find(jobs, citizen.job)
			_release(job, false)
			_block(job, "No route: remove a blocking wall or choose another worksite")
			return false
		var edge: Vector2i = citizen.route[0]
		if not ColonyDanger.allowed(self,citizen,edge): citizen.route.clear();citizen.route_goal.clear();return false
		citizen.route.pop_front()
		citizen.edge_x = edge.x
		citizen.edge_y = edge.y
	# Carry the fractional progress in a common denominator across terrain changes.
	citizen.move_base_rem += 1200000 / tile_move_cost(Vector2i(citizen.edge_x,citizen.edge_y))
	var speed: int = citizen.move_base_rem / 120
	citizen.move_base_rem %= 120
	if citizen.traits.has("Restless"):
		citizen.move_rem += speed * 1150
		speed = citizen.move_rem / 1000
		citizen.move_rem %= 1000
	if citizen.health < 50:
		citizen.injury_rem += speed * 750
		speed = citizen.injury_rem / 1000
		citizen.injury_rem %= 1000
	if citizen.carrying_patient > 0:
		citizen.patient_move_rem += speed * 750
		speed = citizen.patient_move_rem / 1000
		citizen.patient_move_rem %= 1000
	speed += citizen.travel_credit
	citizen.travel_credit = 0
	citizen.progress += speed
	if citizen.progress >= 10000:
		citizen.progress -= 10000
		citizen.x = citizen.edge_x
		citizen.y = citizen.edge_y
		citizen.travel_credit = citizen.progress
		citizen.progress = 0
	return citizen.x == goal.x and citizen.y == goal.y and citizen.progress == 0

func _rate(citizen: Dictionary, job: Dictionary) -> int:
	var ratios: Array[int] = [1000 + 100 * citizen.skills.get(job.skill, 0),
		(500 if citizen.equipment.toolkit.is_empty() else (1150 if citizen.equipment.toolkit == "forged_toolkit" else 1000)) if job.skill in ["Build","Craft","Field"] else 1000,
		1200 if (job.skill == "Care" and citizen.traits.has("Kind")) or (job.skill == "Study" and citizen.traits.has("Curious")) else 1000, 800 if not comfortable(citizen) and not roofed(Vector2i(citizen.x, citizen.y)) else 1000]
	var remainders: Array = job.rate_remainders.get(citizen.id, [0, 0, 0, 0])
	var work: int = 100
	for index in range(4):
		var numerator: int = work * ratios[index] + remainders[index]
		work = numerator / 1000
		remainders[index] = numerator % 1000
	job.rate_remainders[citizen.id] = remainders
	return work

func _finish(citizen: Dictionary, job: Dictionary) -> void:
	if job.kind=="enemy_treat" and find(defense_state.enemies,job.target).get("state")!="Downed": _release(job,true);return
	if job.kind=="raid_pay" and find(defense_state.raids,job.target).get("state")!="Payment": _release(job,true);return
	if in_tick and not committing_work:
		work_commits.append({"kind":"finish","worker":citizen.id,"job":job.id});return
	if job.kind=="expedition_pack" and not ColonyRegion.pack_ready(self,job):
		var reason: String = job.reason;_release(job,false);_block(job,reason);return
	if job.kind=="trade" and not ColonyTrade.ready(self,job):
		var reason: String = job.reason
		_release(job,false);_block(job,reason);return
	if job.kind=="move_furniture":
		var move_error: String = placement_error(job.definition,Vector2i(job.care_goal[0],job.care_goal[1]),job.rotation,job.id,job.target)
		if not move_error.is_empty(): _release(job,false);_block(job,move_error);return
	if job.kind in ["stock_feed","collect_animal","slaughter"] and not ColonyDomestic.ready_complete(self,job):
		_release(job,false); _block(job,"Animal buffer full or conditions changed: haul goods or restore the barn"); return
	if job.kind == "mediate":
		if not ColonySocial.complete_mediation(self,job):
			_release(job,false)
			_block(job,"Both residents must meet within 3 tiles for mediation")
			return
	# Batch inputs remain real escrow until this atomic completion transaction.
	if job.kind == "build":
		var error: String = placement_error(job.definition, Vector2i(job.x, job.y), job.rotation, job.id)
		if not error.is_empty():
			_release(job, false)
			_block(job, error)
			return
	for item in job.inputs:
		if _escrow_count(job.id, item) != job.inputs[item]:
			_release(job, false)
			_block(job, "Inputs changed: replace missing ingredients")
			return
	for stack in stacks:
		if stack.location == "escrow" and stack.owner == job.id:
			if job.kind in ["stock_feed","equip","expedition_pack"]: continue
			if job.kind in ["eat","feed"]:
				var eater: Dictionary = citizen if job.kind == "eat" else find(citizens,job.target)
				for tag in stack.tags:
					if not eater.food_tags.has(tag):
						eater.food_tags.append(tag)
			if job.kind != "fuel":
				_record("traded_out" if job.kind in ["trade","raid_pay"] else "consumed", stack.item, stack.count)
			else:
				find(structures,job.target).fuel += stack.count
			stack.count = 0
	var point: Vector2i = Vector2i(job.work_x, job.work_y)
	match job.kind:
		"raid_pay": ColonyDefense.pay_complete(self,job)
		"enemy_treat": ColonyDefense.treatment_complete(self,job)
		"extinguish": ColonyFire.complete(self,job)
		"expedition_pack": ColonyRegion.pack_complete(self,job)
		"trade": ColonyTrade.complete(self,job)
		"move_furniture": ColonyMaintenance.complete_move(self,job)
		"repair", "demolish": ColonyMaintenance.complete(self,job)
		"equip": ColonyEquipment.complete(self,citizen,job)
		"stock_feed", "collect_animal", "slaughter": ColonyDomestic.complete(self,job)
		"butcher": ColonyWildlife.butcher(self,job)
		"plant_tree", "clear_sapling", "fish": ColonyNature.complete(self,job)
		"treat", "feed", "bury": ColonyCare.complete(self,citizen,job)
		"prepare", "sow", "harvest", "replant": ColonyAgriculture.complete(self, citizen, job)
		"gather":
			var resource: Dictionary = find(resources, job.target)
			var definition: Dictionary = definitions.resources[resource.definition]
			var quantity: int = 1 if definition.per_unit else resource.remaining
			resource.remaining -= quantity
			navigation_dirty = true
			_make_stack(definition.item, quantity, "ground", 0, point, true)
			if resource.remaining == 0 and definition.regrow_ticks > 0:
				resource.regrow_at = tick + definition.regrow_ticks
			elif definition.per_unit and resource.remaining > 0 and job.definition == resource.definition:
				var continuation: Dictionary = _job("gather", "Gathering", "Field", resource.id, Vector2i(resource.x,resource.y), definition.work_milli)
				continuation.definition = resource.definition
				continuation.priority = job.priority
		"build":
			var structure: Dictionary = _structure(job.definition, Vector2i(job.x, job.y), job.rotation)
			if job.definition == "bed":
				for resident in citizens:
					if resident.death_recorded or resident.departed: continue
					var old_bed: Dictionary = find(structures, resident.bed)
					if old_bed.get("definition") == "bedroll" or old_bed.is_empty():
						if not old_bed.is_empty(): old_bed.user = 0
						resident.bed = structure.id
						structure.user = resident.id
						break
			if definitions.buildings[job.definition].storage_capacity > 0:
				stores.append({"id": structure.id, "tiles": [Vector2i(structure.x, structure.y)], "capacity": definitions.buildings[job.definition].storage_capacity, "priority": 2, "filters": definitions.items.keys()})
		"cook", "craft":
			for item in job.output:
				var stack: Dictionary = _make_stack(item, job.output[item], "output", job.target, point, true)
				for ingredient in job.inputs:
					for tag in definitions.items[ingredient].tags:
						if not stack.tags.has(tag):
							stack.tags.append(tag)
		"eat":
			var item: String = job.inputs.keys()[0]
			citizen.fullness = mini(1000, citizen.fullness + definitions.items[item].fullness)
			citizen.starving_ticks = 0
			if item not in ["meal", "travel_ration"]:
				citizen.raw_memory_until = tick + 1800
	if job.kind == "craft": ColonyProduction.completed(self,job)
	_complete(citizen, job)

func _complete(citizen: Dictionary, job: Dictionary) -> void:
	if job.kind == "build": ColonyConstruction.finish_helpers(self,citizen,job)
	for stack in stacks:
		stack.reservations.erase(job.id)
	if job.category == citizen.preferred:
		citizen.preferred_work += job.pending_xp.get(citizen.id, 0)
		if citizen.preferred_work >= 30000:
			citizen.preferred_memory_until = tick + 7200
			citizen.preferred_work = 0
	for person in citizens:
		if person.pinned_job == job.id: person.pinned_job = 0
	if job.kind in ["eat","sleep"] and not citizen.pending_shift.is_empty():
		citizen.shift = citizen.pending_shift
		citizen.pending_shift = ""
	if job.kind == "build": ColonySocial.shared_building(self,job)
	job.state = "Complete"
	job.worker = 0
	citizen.job = 0
	citizen.activity = "Completed " + job.kind
	_award_xp(job)
	facts.append({"tick": tick, "actor": citizen.id, "job": job.id, "kind": job.kind, "text": citizen.name + " completed " + job.kind})

func _award_xp(job: Dictionary) -> void:
	for worker_id in job.pending_xp:
		if not job.skill.is_empty():
			var worker: Dictionary = find(citizens, worker_id)
			worker.xp[job.skill] += job.pending_xp[worker_id]
			for level in range(6):
				if worker.xp[job.skill] >= THRESHOLDS[level] * 1000:
					worker.skills[job.skill] = level

func _release(job: Dictionary, cancel: bool) -> void:
	if job.is_empty():
		return
	if cancel and job.kind=="trade":
		var exchange: Dictionary = find(trade_state.exchanges,job.target)
		if not exchange.is_empty() and exchange.state=="Packing": exchange.state="Canceled"
	if job.kind=="move_furniture": ColonyMaintenance.release_move(self,job,cancel)
	if cancel and job.kind == "build": ColonyConstruction.cancel_helpers(self,job)
	if job.kind == "hunt": danger_cache_tick = -1
	if cancel and job.kind == "hunt":
		for escort in jobs:
			if escort.kind == "escort_hunt" and escort.order == job.id and escort.state not in ["Complete","Canceled"]: _release(escort,true)
	if job.kind == "lead_animal":
		var animal: Dictionary = find(domestic_state.animals,job.target)
		if not animal.is_empty(): animal.handler = 0
	ColonyFire.released(self,job)
	ColonyCare.released(self,job)
	for stack in stacks:
		if cancel or job.kind not in ["trade","expedition_pack","raid_pay"]: stack.reservations.erase(job.id)
		if (stack.location == "carry" and stack.job == job.id) or (cancel and stack.location == "escrow" and stack.owner == job.id):
			stack.location = "ground"
			if stack.owner > 0 and not find(citizens, stack.owner).is_empty():
				var carrier: Dictionary = find(citizens, stack.owner)
				stack.x = carrier.x
				stack.y = carrier.y
			stack.owner = 0
			stack.job = 0
			if not cancel and job.kind in ["trade","expedition_pack","raid_pay"] and stack.count>0: stack.reservations[job.id]=stack.count
	if job.worker > 0:
		var citizen: Dictionary = find(citizens, job.worker)
		citizen.job = 0
		citizen.route.clear()
		citizen.route_goal.clear()
	job.worker = 0
	job.state = "Canceled" if cancel else "Ready"
	if cancel:
		for citizen in citizens:
			if citizen.pinned_job == job.id:
				citizen.pinned_job = 0
		job.work = 0
		job.pending_xp.clear()
		job.rate_remainders.clear()

func _make_stack(item: String, count: int, location: String, owner: int, point: Vector2i, produced: bool) -> Dictionary:
	var limit: int = definitions.items[item].stack_limit
	if count > limit:
		_make_stack(item, count - limit, location, owner, point, produced)
		count = limit
	var stack: Dictionary = {"id": _id(), "item": item, "count": count, "location": location, "owner": owner,
		"x": point.x, "y": point.y, "age": 0, "age_rem": 0, "tags": definitions.items[item].tags.duplicate(), "job": 0, "reservations": {}}
	stacks.append(stack)
	if produced:
		_record("produced", item, count)
	return stack

func _record(kind: String, item: String, count: int) -> void:
	ledger[kind][item] = ledger[kind].get(item, 0) + count

func _reserved(stack: Dictionary) -> int:
	var result: int = 0
	for count in stack.reservations.values():
		result += count
	return result

func available(item: String) -> int:
	var result: int = 0
	for stack in stacks:
		if stack.item == item and stack.location in ["ground", "store", "output"] and ColonyFire.usable(self,stack) and accessible(Vector2i(stack.x,stack.y)):
			result += stack.count - _reserved(stack)
	return result

func total(item: String) -> int:
	var result: int = 0
	for stack in stacks:
		if stack.item == item:
			result += stack.count
	for structure in structures:
		if item == "wood":
			result += structure.fuel
	for citizen in citizens:
		for equipped in citizen.equipment.values():
			if equipped == item: result += 1
	return result

func _escrow_count(job_id: int, item: String) -> int:
	var result: int = 0
	for stack in stacks:
		if stack.item == item and stack.location == "escrow" and stack.owner == job_id:
			result += stack.count
	return result

func _food(citizen: Dictionary) -> Dictionary:
	var edible: Array[Dictionary] = []
	for stack in stacks:
		if stack.count - _reserved(stack) > 0 and definitions.items[stack.item].fullness > 0 and stack.location in ["ground", "store", "output"] and ColonyFire.usable(self,stack) and (stack.item != "travel_ration" or use_rations):
			edible.append(stack)
	edible.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.age != b.age:
			return a.age > b.age
		if a.tags.has(citizen.food_tag) != b.tags.has(citizen.food_tag):
			return a.tags.has(citizen.food_tag)
		return a.item < b.item or (a.item == b.item and a.id < b.id))
	return {} if edible.is_empty() else edible[0]

func _destination(item: String, quantity: int, from: Vector2i, tags: Array = []) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for store in stores:
		if ColonyFire.burning(self,"structure",store.id): continue
		if not store.filters.has(item):
			continue
		var occupied: int = 0
		for stack in stacks:
			if stack.location == "store" and stack.owner == store.id:
				occupied += stack.count
		for job in jobs:
			if job.kind == "haul" and job.destination == store.id and job.worker > 0:
				for stack in stacks:
					occupied += stack.reservations.get(job.id, 0)
					if stack.location == "carry" and stack.job == job.id:
						occupied += stack.count
		if occupied + quantity > store.capacity:
			continue
		for tile: Vector2i in store.tiles:
			var used: int = 0
			var blocked: bool = false
			if find(structures, store.id).is_empty():
				for stack in stacks:
					if stack.location == "store" and stack.owner == store.id and Vector2i(stack.x, stack.y) == tile and stack.count > 0:
						blocked = blocked or stack.item != item or stack.tags != tags
						used += stack.count
				for job in jobs:
					if job.kind == "haul" and job.worker > 0 and job.destination == store.id and Vector2i(job.work_x, job.work_y) == tile:
						blocked = true
				if used + quantity > definitions.items[item].stack_limit:
					blocked = true
			if not blocked:
				candidates.append({"id": store.id, "tile": tile, "priority": store.priority, "distance": absi(tile.x - from.x) + absi(tile.y - from.y)})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority > b.priority or (a.priority == b.priority and (a.distance < b.distance or (a.distance == b.distance and a.id < b.id))))
	return {} if candidates.is_empty() else candidates[0]

func invariant_errors() -> Array[String]:
	var errors: Array[String] = []
	var all_ids: Dictionary = {}
	for records in [citizens, structures, resources, stacks, jobs, fields, social_state.requests, production_state.orders, care_state.bodies, nature_state.forests, wildlife_state.animals, wildlife_state.carcasses, domestic_state.pens, domestic_state.animals, construction_state.groups, population_state.offers, trade_state.merchants, trade_state.exchanges, region_state.trips, fire_state.fires, defense_state.raids, defense_state.enemies, director_state.history, ([director_state.major] if not director_state.major.is_empty() else [])]:
		for record: Dictionary in records:
			if all_ids.has(record.id) or record.id < 1 or record.id >= next_id:
				errors.append("Invalid/duplicate ID")
			all_ids[record.id] = true
	for stack in stacks:
		if stack.count < 0 or _reserved(stack) > stack.count:
			errors.append("Invalid quantity or over-reservation")
		for job_id in stack.reservations:
			var job: Dictionary = find(jobs, job_id)
			if job.is_empty() or (job.worker == 0 and job.kind not in ["trade","expedition_pack","raid_pay"]) or job.state in ["Complete", "Canceled"]:
				errors.append("Orphan reservation")
		if stack.count > 0 and stack.location in ["carry", "escrow", "output", "store", "expedition_cargo"]:
			var owners: Array = region_state.trips if stack.location=="expedition_cargo" else citizens if stack.location == "carry" else (jobs if stack.location == "escrow" else (structures if stack.location == "output" else stores))
			if find(owners, stack.owner).is_empty():
				errors.append("Missing physical owner")
	var work_positions: Dictionary = {}
	for job in jobs:
		if job.worker > 0:
			var worker: Dictionary = find(citizens, job.worker)
			var point: Vector2i = Vector2i(job.work_x, job.work_y)
			var productive: bool = job.kind in ["build", "gather", "cook", "craft", "research", "fish", "plant_tree", "clear_sapling", "build_helper", "prepare", "sow", "harvest", "replant"]
			if worker.is_empty() or worker.job != job.id or (productive and work_positions.has(point)):
				errors.append("Invalid worker/work position ownership")
			if productive:
				work_positions[point] = job.id
		if job.kind in ["gather", "cook", "craft", "research"] and find(resources if job.kind == "gather" else structures, job.target).is_empty():
			errors.append("Missing job target")
	for item in definitions.items:
		if total(item) != ledger.produced.get(item,0)+ledger.recovered.get(item,0)+ledger.traded_in.get(item,0)+ledger.expedition_gain.get(item,0)-ledger.consumed.get(item,0)-ledger.spoiled.get(item,0)-ledger.lost.get(item,0)-ledger.traded_out.get(item,0)-ledger.looted.get(item,0):
			errors.append("Conservation failed: " + item)
	for citizen in citizens:
		var carried: int = 0
		for stack in stacks:
			if stack.location == "carry" and stack.owner == citizen.id:
				carried += stack.count
		if carried > 8:
			errors.append("Carry capacity exceeded")
		if citizen.carrying_patient > 0 and carried > 0: errors.append("Patient carrier must have both hands free")
		if not inside(Vector2i(citizen.x, citizen.y)) or citizen.fullness not in range(1001) or citizen.rest not in range(1001):
			errors.append("Citizen bounds")
		if citizen.job > 0 and (find(jobs, citizen.job).is_empty() or find(jobs, citizen.job).worker != citizen.id):
			errors.append("Missing citizen task owner")
		if citizen.bed > 0 and find(structures, citizen.bed).is_empty():
			errors.append("Missing assigned bed")
	return errors

func payload() -> Dictionary:
	return {"content": CONTENT_VERSION, "content_hash":definitions.content_hash, "schema_revision":schema_revision, "generator_version":generator_version, "terrain_state":terrain_state, "director_state":director_state, "defense_state":defense_state, "fire_state":fire_state, "region_state":region_state, "trade_state":trade_state, "population_state":population_state, "equipment_state":equipment_state, "construction_state":construction_state, "domestic_state":domestic_state, "wildlife_state":wildlife_state, "nature_state":nature_state, "site_id":site_id, "weather_state":weather_state, "social_state":social_state, "production_state":production_state, "care_state":care_state, "seed": seed, "tick": tick, "session_id": session_id, "next_id": next_id,
		"next_command_id": next_command_id, "citizens": citizens, "structures": structures, "resources": resources,
		"stacks": stacks, "jobs": jobs, "stores": stores, "fields": fields, "researched": researched, "weather": weather, "designations": designations, "receipts": receipts,
		"pending_commands": pending_commands, "facts": facts, "ledger": ledger, "use_rations": use_rations}

func canonical_hash() -> String:
	return JSON.stringify(ColonyState.pack(payload()), "", true).sha256_text()

func roofed(point: Vector2i) -> bool:
	if rooms_dirty:
		room_tiles = ColonyRooms.compute(self)
		rooms_dirty = false
	return room_tiles.has(point)

func comfortable(citizen: Dictionary) -> bool:
	return ColonyLiving.comfortable(self, citizen)

func _merge_stored(incoming: Dictionary) -> void:
	for other in stacks:
		if other.id != incoming.id and other.location == "store" and other.owner == incoming.owner and other.x == incoming.x and other.y == incoming.y and other.item == incoming.item and other.tags == incoming.tags and other.count > 0 and other.count + incoming.count <= definitions.items[incoming.item].stack_limit:
			other.count += incoming.count
			if incoming.age > other.age or (incoming.age == other.age and incoming.age_rem > other.age_rem):
				other.age = incoming.age
				other.age_rem = incoming.age_rem
			incoming.count = 0
			return

func elevation(tile: Vector2i) -> int:
	if generator_version > 0: return terrain_state.elevation[tile.y*128+tile.x]
	# Authored starter geography; generated maps will store their complete terrain.
	if tile.x in range(32,36): return 0
	if tile.x in range(28,32) or tile.x in range(36,40): return 1
	return 4 if tile.x >= 112 else (3 if tile.x >= 96 else 2)

func is_flooded(tile: Vector2i) -> bool:
	if not flood_cache_valid:
		flood_cache.clear()
		for point in weather_state.flooded: flood_cache[point] = true
		flood_cache_valid = true
	return flood_cache.has(tile)

func tile_move_cost(tile: Vector2i) -> int:
	if structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="bridge" and footprint(s).has(tile)): return 10
	for structure in structures:
		if structure.health>0 and structure.definition == "stone_path" and footprint(structure).has(tile): return 8
	if is_flooded(tile): return 15
	if generator_version > 0 and terrain_state.bridges.has(tile): return 10
	if weather == "snow": return 12
	if weather == "rain" and ((generator_version > 0 and not terrain_state.paths.has(tile)) or (generator_version == 0 and tile.x != 66 and tile.y not in [63,64])): return 15
	return 10

func soil_fertility(tile: Vector2i) -> int:
	return terrain_state.fertility[tile.y*128+tile.x] if generator_version > 0 else 1000

func can_step(from: Vector2i, to: Vector2i) -> bool:
	if generator_version == 0: return true
	if terrain_state.bridges.has(from) or terrain_state.bridges.has(to): return true
	return absi(elevation(from)-elevation(to)) <= 1

static func citizen_record(id: int, name: String, point: Vector2i, skills: Dictionary, xp: Dictionary, traits: Array, preferred: String, preferences: Dictionary, food: String, weapon: String) -> Dictionary:
	var result: Dictionary = {"away":false,"expedition":0,"camp_sleeping":false,"id": id, "name": name, "x": point.x, "y": point.y,
		"progress": 0, "direction": 0, "edge_x": point.x, "edge_y": point.y, "route": [], "route_goal": [], "move_base_rem": 0, "move_rem": 0, "injury_rem": 0, "travel_credit": 0,
		"skills": skills, "xp": xp, "traits": traits, "preferred": preferred, "preferences": preferences,
		"shift": "Normal", "pending_shift": "", "pinned_job": 0, "yesterday_leisure": 0, "leisure_memory_until": 0, "warm_until": 0, "leisure_ticks": 0, "leisure_day": 0, "bed_sleep_ticks": 0, "bed_memory_until": 0, "raw_memory_until": 0, "preferred_work": 0, "preferred_memory_until": 0, "mood_terms": {}, "food_tags": [], "food_tags_day": 0, "break_clock": 0, "break_until": 0, "break_cooldown": 0, "departure_clock": 0, "departure_until": 0, "departed": false,
		"food_tag": food, "fullness": 750, "rest": 900, "morale": 650,
		"health": 100, "hunger_rem": 0, "rest_rem": 0, "starving_ticks": 0, "job": 0, "bed": 0,
		"equipment": {"toolkit": "toolkit", "cloak": "cloak", "weapon": weapon, "vest":""}, "activity": "Looking around"}
	result.merge(ColonySocial.citizen_defaults());result.merge(ColonyCare.citizen_defaults());result.merge(ColonyCombat.citizen_defaults());result.merge(ColonyDefense.citizen_defaults())
	return result
