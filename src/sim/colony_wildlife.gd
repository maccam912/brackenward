class_name ColonyWildlife
extends RefCounted
const MOVE_DENOM: int = 151200
const REPLACEMENT_ORDER: Array = ["hare","deer","marsh_goose","boar"]

static func initial_state() -> Dictionary:
	return {"animals":[],"carcasses":[],"replacement":0,"injuries":{}}

static func animal_template() -> Dictionary:
	return {"id":0,"definition":"hare","x":0,"y":0,"health":24,"home":Vector2i.ZERO,"origin":Vector2i.ZERO,"rng":1,"route":[],"progress":0,"move_rem":0,"cooldown":0,"attacker":0,"crop_day":-1}

static func spawn(world: ColonyWorld, kind: String, point: Vector2i) -> Dictionary:
	var animal: Dictionary = animal_template()
	animal.id = world._id(); animal.definition = kind; animal.x = point.x; animal.y = point.y
	animal.health = world.definitions.animals[kind].health; animal.home = point; animal.origin = point
	animal.rng = ParkMiller.derive(world.seed,world.generator_version,world.site_id,"wildlife:%d" % animal.id)
	world.wildlife_state.animals.append(animal)
	return animal

static func initialize(world: ColonyWorld) -> void:
	world.wildlife_state = initial_state()
	for kind in world.terrain_state.habitats:
		for point in world.terrain_state.habitats[kind]: spawn(world,kind,point)

static func animal_walkable(world: ColonyWorld, point: Vector2i) -> bool:
	if not world.walkable(point): return false
	# Wildlife does not open doors or pen gates, or enter occupied buildings.
	for structure in world.structures:
		if structure.health<=0: continue
		if structure.definition not in ["wood_floor","stone_path","bridge"] and world.footprint(structure).has(point): return false
	return true

static func distance(a: Dictionary, b: Dictionary) -> int:
	return absi(a.x-b.x)+absi(a.y-b.y)

static func advance(world: ColonyWorld) -> void:
	for carcass in world.wildlife_state.carcasses:
		if not carcass.done and not carcass.spoiled and world.tick >= carcass.expires:
			carcass.spoiled = true
			for job in world.jobs:
				if job.kind == "butcher" and job.target == carcass.id and job.state not in ["Complete","Canceled"]: world._release(job,true)
			world.facts.append({"tick":world.tick,"actor":0,"job":0,"kind":"carcass_spoiled","text":"An unbutchered %s carcass spoiled after two days. No food was produced." % carcass.definition})
	if world.tick%7200 == 1800 and ((world.tick/7200+1)%4 == 0): replenish(world)
	for animal in world.wildlife_state.animals:
		if animal.health <= 0: continue
		var definition: Dictionary = world.definitions.animals[animal.definition]
		var near: Array = world.citizens.filter(func(c:Dictionary)->bool:return not c.downed and not c.death_recorded and not c.departed and distance(animal,c) <= definition.flee_range)
		near.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return distance(animal,a)<distance(animal,b) if distance(animal,a)!=distance(animal,b) else a.id<b.id)
		var aggressor: Dictionary = world.find(world.citizens,animal.attacker)
		if animal.attacker > 0 and (aggressor.is_empty() or aggressor.downed or aggressor.death_recorded or aggressor.departed or distance(animal,aggressor)>6 or absi(animal.x-animal.origin.x)+absi(animal.y-animal.origin.y)>=12): animal.attacker = 0
		if animal.definition == "boar" and animal.health < definition.health and animal.attacker == 0:
			var intruders: Array = near.filter(func(c:Dictionary)->bool:return distance(animal,c)<=2)
			if not intruders.is_empty() and absi(animal.x-animal.origin.x)+absi(animal.y-animal.origin.y)<12: animal.attacker = intruders[0].id; aggressor = intruders[0]
		if animal.progress == 0 and world.tick%10 == 0:
			if animal.attacker > 0:
				# A wounded boar also defends itself against people within two tiles.
				var nearby: Array = near.filter(func(c:Dictionary)->bool:return distance(animal,c)<=2)
				if not nearby.is_empty(): aggressor = nearby[0]
				if distance(animal,aggressor)>1: _route(world,animal,Vector2i(aggressor.x,aggressor.y))
				else: animal.route.clear()
			elif not near.is_empty():
				var options: Array = []
				for delta in ColonyNavigation.NEIGHBORS:
					var p: Vector2i = Vector2i(animal.x,animal.y)+delta
					if animal_walkable(world,p) and world.can_step(Vector2i(animal.x,animal.y),p): options.append(p)
				options.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return absi(a.x-near[0].x)+absi(a.y-near[0].y)>absi(b.x-near[0].x)+absi(b.y-near[0].y))
				animal.route = [options[0]] if not options.is_empty() else []
		if world.tick%300 == 0 and animal.attacker == 0 and near.is_empty():
			var choices: Array[Vector2i] = []
			var origin: Vector2i = Vector2i(animal.x,animal.y)
			var queue: Array[Vector2i] = [origin]
			var seen: Dictionary = {origin:true}
			var cursor: int = 0
			while cursor < queue.size():
				var tile: Vector2i = queue[cursor]; cursor += 1
				if tile != origin: choices.append(tile)
				for delta in ColonyNavigation.NEIGHBORS:
					var p: Vector2i = tile+delta
					if absi(p.x-origin.x)+absi(p.y-origin.y)>6 or seen.has(p) or not animal_walkable(world,p) or not world.can_step(tile,p): continue
					seen[p] = true; queue.append(p)
			if not choices.is_empty():
				var rng: ParkMiller = ParkMiller.new(animal.rng)
				_route(world,animal,choices[rng.next()%choices.size()]); animal.rng = rng.state
		_move(world,animal)
		if animal.crop_day != world.tick/7200:
			for field in world.fields:
				if field.x == animal.x and field.y == animal.y and field.planted and field.yield_count > 0:
					field.yield_count -= 1; animal.crop_day = world.tick/7200
					field.reason = "Wildlife ate one future crop unit: fence this field or mark a hunt"
					world.facts.append({"tick":world.tick,"actor":animal.id,"job":0,"kind":"wildlife_crop","text":"A %s ate one future crop unit. Fence this field or designate a hunt." % animal.definition})
					break

static func _route(world: ColonyWorld, animal: Dictionary, goal: Vector2i) -> void:
	if world.path_requests >= 4: return
	world.path_requests += 1
	animal.route = ColonyNavigation.path(Vector2i(animal.x,animal.y),goal,func(p:Vector2i)->bool:return animal_walkable(world,p),world.can_step)

static func _move(world: ColonyWorld, animal: Dictionary) -> void:
	if animal.route.is_empty(): animal.progress = 0; return
	var edge: Vector2i = animal.route[0]
	if not animal_walkable(world,edge) or not world.can_step(Vector2i(animal.x,animal.y),edge): animal.route.clear(); animal.progress = 0; return
	var normal: int = world.definitions.animals[animal.definition].move_ticks
	# One common integer denominator preserves exact wet/snow terrain ratios.
	animal.move_rem += 100000*MOVE_DENOM/(normal*world.tile_move_cost(edge))
	animal.progress += animal.move_rem/MOVE_DENOM; animal.move_rem %= MOVE_DENOM
	if animal.progress >= 10000:
		animal.progress -= 10000; animal.x = edge.x; animal.y = edge.y; animal.route.pop_front()

static func replenish(world: ColonyWorld) -> void:
	# Incident module sets an active hostiles list; empty until its implementation.
	if world.wildlife_state.get("hostile_active",false): return
	var replaced: int = 0
	var start: int = world.wildlife_state.replacement
	for offset in range(4):
		var kind: String = REPLACEMENT_ORDER[(start+offset)%4]
		if kind == "boar" and world.tick/7200+1 < 9: continue
		var living: Array = world.wildlife_state.animals.filter(func(a:Dictionary)->bool:return a.health>0)
		if living.size()>=32 or living.filter(func(a:Dictionary)->bool:return a.definition==kind).size() >= world.definitions.animals[kind].initial_count: continue
		var homes: Array = world.terrain_state.habitats.get(kind,[]).duplicate()
		if homes.is_empty():
			for previous in world.wildlife_state.animals:
				if previous.definition == kind and not homes.has(previous.home): homes.append(previous.home)
		for p in homes:
			if not animal_walkable(world,p) or living.any(func(a:Dictionary)->bool:return Vector2i(a.x,a.y)==p) or not world.accessible(p): continue
			spawn(world,kind,p); replaced += 1; break
		if replaced == 2: break
	world.wildlife_state.replacement = (start+1)%4

static func command(world: ColonyWorld, args: Dictionary) -> String:
	var animal: Dictionary = world.find(world.wildlife_state.animals,args.target)
	if animal.is_empty() or animal.health<=0: return "Choose a living wild animal"
	if world.jobs.any(func(j:Dictionary)->bool:return j.kind == "hunt" and j.target == animal.id and j.state not in ["Complete","Canceled"]): return "Animal already marked for hunting"
	var designated: Dictionary = world.find(world.citizens,args.citizen)
	if args.citizen>0 and (designated.is_empty() or designated.downed or designated.death_recorded or designated.departed or designated.equipment.weapon.is_empty() or designated.preferences.Gathering==0): return "Chosen hunter needs a weapon and Gathering enabled"
	var job: Dictionary = world._job("hunt","Gathering","Guard",animal.id,Vector2i(animal.x,animal.y),0)
	job.definition = animal.definition
	world.danger_cache_tick = -1
	if not designated.is_empty(): designated.pinned_job = job.id
	if animal.definition == "boar" and not args.solo:
		var escort: Dictionary = world._job("escort_hunt","Guard","Guard",animal.id,Vector2i(animal.x,animal.y),0)
		escort.order = job.id; escort.definition = animal.definition
	return "accepted"

static func reserve(world: ColonyWorld, job: Dictionary, citizen: Dictionary) -> bool:
	if job.kind == "butcher":
		var carcass: Dictionary = world.find(world.wildlife_state.carcasses,job.target)
		if carcass.is_empty() or carcass.done or carcass.spoiled: return world._block(job,"Carcass spoiled or already butchered")
		return true
	var animal: Dictionary = world.find(world.wildlife_state.animals,job.target)
	if animal.is_empty() or animal.health<=0: return world._block(job,"Animal no longer alive")
	job.x = animal.x; job.y = animal.y
	if citizen.equipment.weapon.is_empty() or citizen.health<=40: return world._block(job,"Hunting needs an armed, healthy worker")
	if job.kind == "escort_hunt":
		var hunt: Dictionary = world.find(world.jobs,job.order)
		if hunt.is_empty() or hunt.state in ["Complete","Canceled"]: return world._block(job,"Hunt ended")
	else:
		var escorts: Array = world.jobs.filter(func(j:Dictionary)->bool:return j.kind == "escort_hunt" and j.order == job.id and j.state not in ["Complete","Canceled"])
		if not escorts.is_empty() and escorts[0].worker == 0: return world._block(job,"Boar hunt needs a second armed Guard worker; enable Guard or choose Solo hunt explicitly")
	return true

static func hunt_work(world: ColonyWorld, citizen: Dictionary, job: Dictionary) -> void:
	var animal: Dictionary = world.find(world.wildlife_state.animals,job.target)
	if animal.is_empty() or animal.health<=0:
		world._complete(citizen,job); return
	if citizen.health<=40:
		world._release(job,false); world._block(job,"Hunter retreated at health 40 or less; needs care"); return
	if job.kind == "hunt":
		var escorts: Array = world.jobs.filter(func(j:Dictionary)->bool:return j.kind == "escort_hunt" and j.order == job.id and j.state not in ["Complete","Canceled"])
		if not escorts.is_empty() and (escorts[0].worker == 0 or distance(world.find(world.citizens,escorts[0].worker),animal)>6):
			citizen.activity = "Waiting for armed escort"; return
	if job.kind == "escort_hunt":
		var hunt: Dictionary = world.find(world.jobs,job.order)
		if hunt.is_empty() or hunt.state in ["Complete","Canceled"]:
			world._release(job,true); return
		if hunt.worker==0:
			citizen.activity = "Waiting for the armed hunter"
			if not ColonyDanger.safe(world,Vector2i(citizen.x,citizen.y)):
				world._release(job,false); world._block(job,"Waiting for the hunter; return to safety"); ColonyDanger.escape(world,citizen)
			return
	var range_limit: int = 6 if citizen.equipment.weapon == "bow" else 1
	if distance(citizen,animal)<=range_limit and ColonyCombat.line_of_sight(world,Vector2i(citizen.x,citizen.y),Vector2i(animal.x,animal.y)):
		citizen.activity = "Escorting boar hunt" if job.kind == "escort_hunt" else "Hunting "+animal.definition; job.state = "Working"; return
	var positions: Array[Vector2i] = []
	for delta in ColonyNavigation.NEIGHBORS:
		var p: Vector2i = Vector2i(animal.x,animal.y)+delta
		if world.walkable(p): positions.append(p)
	positions.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return absi(a.x-citizen.x)+absi(a.y-citizen.y)<absi(b.x-citizen.x)+absi(b.y-citizen.y))
	if positions.is_empty(): world._release(job,false); world._block(job,"Animal has no reachable approach"); return
	job.state = "Moving"; citizen.activity = "Approaching "+animal.definition
	world._walk(citizen,positions[0])

static func kill(world: ColonyWorld, animal: Dictionary) -> void:
	var carcass: Dictionary = {"id":world._id(),"animal":animal.id,"definition":animal.definition,"x":animal.x,"y":animal.y,"expires":world.tick+14400,"done":false,"spoiled":false}
	world.wildlife_state.carcasses.append(carcass)
	for job in world.jobs:
		if job.target == animal.id and job.kind in ["hunt","escort_hunt"] and job.state not in ["Complete","Canceled"]:
			var worker: Dictionary = world.find(world.citizens,job.worker)
			if worker.is_empty(): job.state = "Complete"
			else: world._complete(worker,job)
	var butcher: Dictionary = world._job("butcher","Gathering","Field",carcass.id,Vector2i(animal.x,animal.y),world.definitions.animals[animal.definition].work_milli)
	butcher.definition = animal.definition
	world.facts.append({"tick":world.tick,"actor":animal.id,"job":butcher.id,"kind":"hunt_kill","text":"A %s hunt left a carcass. Butchering and hauling are still required; it spoils after two days." % animal.definition})

static func butcher(world: ColonyWorld, job: Dictionary) -> void:
	var carcass: Dictionary = world.find(world.wildlife_state.carcasses,job.target)
	if carcass.spoiled or carcass.done: return
	carcass.done = true
	for item in world.definitions.animals[carcass.definition].outputs:
		world._make_stack(item,world.definitions.animals[carcass.definition].outputs[item],"ground",0,Vector2i(carcass.x,carcass.y),true)

static func validate(data: Variant, world: ColonyWorld, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["animals","carcasses","replacement","injuries"]) or not data.animals is Array or not data.carcasses is Array or not data.replacement is int or data.replacement not in [0,1,2,3] or not data.injuries is Dictionary or data.animals.size()>100000 or data.carcasses.size()>100000: return false
	var living: int = 0
	for animal in data.animals:
		if not ColonyCodec._record(animal,animal_template()) or not world.definitions.animals.has(animal.definition) or world.definitions.animals[animal.definition].domestic or not ColonyCodec._position(animal) or animal.health<0 or animal.health>world.definitions.animals[animal.definition].health or not ColonyWorld.inside(animal.home) or not ColonyWorld.inside(animal.origin) or animal.rng<=0 or animal.rng>=2147483647 or animal.progress<0 or animal.progress>=10000 or animal.move_rem<0 or animal.move_rem>=MOVE_DENOM or animal.cooldown<0 or animal.cooldown>tick+35 or animal.crop_day < -1 or animal.crop_day>tick/7200 or not animal.route.all(func(p:Variant)->bool:return p is Vector2i and ColonyWorld.inside(p)): return false
		if animal.health>0: living += 1
	if living>32: return false
	for carcass in data.carcasses:
		if not carcass is Dictionary or not ColonyCodec._keys(carcass,["id","animal","definition","x","y","expires","done","spoiled"]) or not carcass.id is int or not carcass.animal is int or not carcass.definition is String or not world.definitions.animals.has(carcass.definition) or world.definitions.animals[carcass.definition].domestic or not ColonyCodec._position(carcass) or not carcass.expires is int or carcass.expires<0 or carcass.expires>tick+14400 or not carcass.done is bool or not carcass.spoiled is bool: return false
		if not data.animals.any(func(a:Dictionary)->bool:return a.id==carcass.animal and a.health==0 and a.definition==carcass.definition): return false
	var carcass_animals: Dictionary = {}
	for carcass in data.carcasses:
		if carcass_animals.has(carcass.animal): return false
		carcass_animals[carcass.animal] = true
	for id in data.injuries:
		var cause: Variant = data.injuries[id]
		if not id is int or not cause is Dictionary or not ColonyCodec._keys(cause,["animal","tick"]) or not cause.animal is int or not cause.tick is int or cause.tick<1800 or cause.tick>tick or not data.animals.any(func(a:Dictionary)->bool:return a.id==cause.animal and a.definition=="boar"): return false
	return true

static func introduce_on_saved_map(world: ColonyWorld) -> void:
	var cart: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]
	var origin: Vector2i = Vector2i(cart.x,cart.y)
	var queue: Array[Vector2i] = [origin]
	var distances: Dictionary = {origin:0}
	var cursor: int = 0
	while cursor<queue.size():
		var point: Vector2i = queue[cursor];cursor += 1
		for delta in ColonyNavigation.NEIGHBORS:
			var next: Vector2i = point+delta
			if not distances.has(next) and world.walkable(next) and world.can_step(point,next): distances[next]=distances[point]+1;queue.append(next)
	var choices: Array[Vector2i] = []
	for point in queue:
		if distances[point]>=30 and animal_walkable(world,point): choices.append(point)
	var used: Dictionary = {}
	var rng: ParkMiller = ParkMiller.new(ParkMiller.derive(world.seed,world.generator_version,world.site_id,"wildlife-introduction"))
	for kind in ["hare","deer","boar","marsh_goose"]:
		var locations: Array = world.terrain_state.habitats.get(kind,[])
		for index in range(world.definitions.animals[kind].initial_count):
			var point: Vector2i = locations[index] if index<locations.size() else Vector2i(-1,-1)
			if used.has(point) or not animal_walkable(world,point) or distances.get(point,0)<(40 if kind=="boar" else 30):
				var available: Array = choices.filter(func(p:Vector2i)->bool:return not used.has(p) and distances[p]>=(40 if kind=="boar" else 30))
				if available.is_empty(): continue
				point = available[rng.next()%available.size()]
			used[point] = true; spawn(world,kind,point)
