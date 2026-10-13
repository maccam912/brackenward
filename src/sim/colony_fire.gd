class_name ColonyFire
extends RefCounted
const INDUSTRIAL: Array = ["charcoal_kiln","brick_kiln","smelter"]
const ITEMS: Array = ["wood","fiber","cloth"]

static func initial_state() -> Dictionary:
	return {"fires":[],"destroyed":[],"alert_serial":0}

static func active(world: ColonyWorld) -> Array:
	return world.fire_state.fires.filter(func(f:Dictionary)->bool:return not f.done)

static func burning(world: ColonyWorld, kind: String, id: int) -> bool:
	return world.fire_state.fires.any(func(f:Dictionary)->bool:return not f.done and f.kind==kind and f.target==id)

static func usable(world: ColonyWorld, stack: Dictionary) -> bool:
	return not burning(world,"stack",stack.id) and not (stack.location in ["store","output","animal_feed"] and burning(world,"structure",stack.owner))

static func footprint(world: ColonyWorld, fire: Dictionary) -> Array:
	if fire.kind=="structure": return world.footprint(world.find(world.structures,fire.target))
	var stack: Dictionary = world.find(world.stacks,fire.target)
	if stack.location=="store":
		var structure: Dictionary = world.find(world.structures,stack.owner)
		if not structure.is_empty(): return world.footprint(structure)
	return [Vector2i(stack.x,stack.y)]

static func operating(world: ColonyWorld, station: Dictionary) -> bool:
	return station.health>0 and station.cooking and station.definition in INDUSTRIAL and world.jobs.any(func(j:Dictionary)->bool:return j.target==station.id and j.kind=="craft" and j.state=="Working")

static func unsafe(world: ColonyWorld, station: Dictionary) -> Array:
	var hazards: Array = []
	if not operating(world,station): return hazards
	var cells: Array = world.footprint(station)
	for structure in world.structures:
		if structure.id==station.id or structure.health<=0 or not world.definitions.buildings[structure.definition].flammable: continue
		if world.footprint(structure).any(func(p:Vector2i)->bool:return cells.any(func(q:Vector2i)->bool:return maxi(absi(p.x-q.x),absi(p.y-q.y))<=1)): hazards.append({"kind":"structure","target":structure.id})
	for stack in world.stacks:
		if stack.count<=0 or stack.item not in ITEMS or stack.location not in ["ground","store","output","escrow","move_bundle"]: continue
		var fuel: Array = footprint(world,{"kind":"stack","target":stack.id})
		if fuel.any(func(p:Vector2i)->bool:return cells.any(func(q:Vector2i)->bool:return maxi(absi(p.x-q.x),absi(p.y-q.y))<=1)): hazards.append({"kind":"stack","target":stack.id})
	return hazards

static func ignite(world: ColonyWorld, kind: String, target: int, root: int = 0) -> Dictionary:
	if burning(world,kind,target): return {}
	var object: Dictionary = world.find(world.structures if kind=="structure" else world.stacks,target)
	if object.is_empty(): return {}
	if kind=="structure":
		if object.health<=0 or object.definition=="supply_cart" or (not world.definitions.buildings[object.definition].flammable and object.definition not in INDUSTRIAL): return {}
	elif object.count<=0 or object.item not in ITEMS: return {}
	var fire: Dictionary = {"id":world._id(),"kind":kind,"target":target,"root":root,"created":world.tick,"spread_ticks":0,"damage_rem":0,"work":0,"pending_xp":{},"done":false}
	if root==0: fire.root=fire.id;world.fire_state.alert_serial+=1
	world.fire_state.fires.append(fire);world.danger_cache_tick=-1
	for job in world.jobs:
		if job.target==target and job.kind!="extinguish" and job.state not in ["Complete","Canceled"]: world._release(job,false);world._block(job,"Burning target: extinguish before work resumes")
	ColonyTrade.fact(world,"fire_started","Fire started at "+(object.definition if kind=="structure" else object.item)+". Care workers fetch water (2 WU), carry it, then extinguish (8 WU). Rain halves damage and doubles spread time.")
	return fire

static func end(world: ColonyWorld, fire: Dictionary, reason: String) -> void:
	fire.done=true;world.danger_cache_tick=-1
	for job in world.jobs:
		if job.kind=="extinguish" and job.target==fire.id and job.state not in ["Complete","Canceled"]: world._release(job,true)
	ColonyTrade.fact(world,"fire_ended",reason)

static func spread(world: ColonyWorld, fire: Dictionary) -> void:
	var from: Array = footprint(world,fire);var candidates: Array = []
	for index in range(4):
		var delta: Vector2i = ColonyNavigation.NEIGHBORS[index]
		for structure in world.structures:
			if structure.health<=0 or structure.definition=="supply_cart" or not world.definitions.buildings[structure.definition].flammable or burning(world,"structure",structure.id): continue
			if world.footprint(structure).any(func(p:Vector2i)->bool:return from.any(func(q:Vector2i)->bool:return p==q+delta)): candidates.append({"direction":index,"kind":"structure","target":structure.id})
		for stack in world.stacks:
			if stack.count<=0 or stack.item not in ITEMS or stack.location not in ["ground","store","output","escrow","move_bundle"] or burning(world,"stack",stack.id): continue
			var cells: Array = footprint(world,{"kind":"stack","target":stack.id})
			if cells.any(func(p:Vector2i)->bool:return from.any(func(q:Vector2i)->bool:return p==q+delta)): candidates.append({"direction":index,"kind":"stack","target":stack.id})
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.direction<b.direction if a.direction!=b.direction else a.target<b.target)
	if not candidates.is_empty(): ignite(world,candidates[0].kind,candidates[0].target,fire.root)

static func advance(world: ColonyWorld) -> void:
	var people_hit: Dictionary = {}
	for fire in active(world):
		var object: Dictionary = world.find(world.structures if fire.kind=="structure" else world.stacks,fire.target)
		if object.is_empty() or (fire.kind=="structure" and object.health<=0) or (fire.kind=="stack" and object.count<=0): end(world,fire,"Burning object no longer exists");continue
		fire.spread_ticks+=1
		if world.tick%10==0:
			fire.damage_rem+=500 if world.weather=="rain" else 1000
			var units: int = fire.damage_rem/1000;fire.damage_rem%=1000
			var health_damage: int = 1 if world.weather=="rain" else 2
			if fire.kind=="structure":
				object.health=maxi(0,object.health-health_damage)
				if object.health==0: ColonyMaintenance.destroy(world,object);end(world,fire,"Fire destroyed "+object.definition+"; surviving goods fell with their ages retained");continue
			else:
				var loss: int = mini(units,object.count);object.count-=loss;object.reservations.clear();world._record("lost",object.item,loss)
				if object.count==0: end(world,fire,"Fire consumed the exposed "+object.item+" stack");continue
			for person in world.citizens:
				if person.away or person.death_recorded or person.departed: continue
				if footprint(world,fire).has(Vector2i(person.x,person.y)): people_hit[person.id]=maxi(people_hit.get(person.id,0),health_damage)
		if fire.spread_ticks>=(600 if world.weather=="rain" else 300): fire.spread_ticks=0;spread(world,fire)
	for id in people_hit: ColonyCare.hurt(world,world.find(world.citizens,id),people_hit[id])

static func water(world: ColonyWorld, from: Vector2i) -> Dictionary:
	var candidates: Array[Vector2i] = []
	for station in world.structures:
		if station.definition=="well" and station.health>0 and not burning(world,"structure",station.id): candidates.append_array(world._perimeter(world.footprint(station)))
	var river: Array = world.terrain_state.river if world.generator_version>0 else []
	if world.generator_version==0:
		for y in range(128): river.append(Vector2i(32,y));river.append(Vector2i(35,y))
	for tile in river:
		for delta in ColonyNavigation.NEIGHBORS:
			var point: Vector2i = tile+delta
			if world.walkable(point) and not world.is_water(point) and world.accessible(point) and ColonyDanger.safe(world,point) and not candidates.has(point): candidates.append(point)

	var targets: Dictionary = {}
	for point in candidates:
		if world.walkable(point) and ColonyDanger.safe(world,point): targets[point]=true
	var queue: Array[Vector2i] = [from]
	var seen: Dictionary = {from:true};var cursor: int = 0
	while cursor<queue.size():
		var point: Vector2i = queue[cursor];cursor+=1
		if targets.has(point): return {"point":point}
		for delta in ColonyNavigation.NEIGHBORS:
			var next: Vector2i = point+delta
			if not seen.has(next) and world.walkable(next) and world.can_step(point,next): seen[next]=true;queue.append(next)
	return {}

static func create_jobs(world: ColonyWorld) -> void:
	for fire in active(world):
		if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="extinguish" and j.target==fire.id and j.state not in ["Complete","Canceled"]): continue
		var p: Vector2i = footprint(world,fire)[0]
		var job: Dictionary = world._job("extinguish","Care","Care",fire.id,p,8000);job.emergency=true;job.priority=3;job.work=fire.work
		job.memo={"phase":"water","water_work":0,"water_x":0,"water_y":0}

static func reserve(world: ColonyWorld, job: Dictionary, person: Dictionary) -> bool:
	if person.away or person.downed or person.death_recorded or person.departed or person.preferences.Care==0 or person.carrying_patient>0: return false
	var fire: Dictionary = world.find(world.fire_state.fires,job.target)
	if fire.is_empty() or fire.done: job.state="Canceled";return false
	var positions: Array = world._perimeter(footprint(world,fire)).filter(func(p:Vector2i)->bool:return not active(world).any(func(f:Dictionary)->bool:return footprint(world,f).has(p)))
	positions.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return absi(a.x-person.x)+absi(a.y-person.y)<absi(b.x-person.x)+absi(b.y-person.y) if absi(a.x-person.x)+absi(a.y-person.y)!=absi(b.x-person.x)+absi(b.y-person.y) else a.y*128+a.x<b.y*128+b.x)
	if positions.is_empty(): return world._block(job,"No safe adjacent firefighting position")
	var source: Dictionary = water(world,Vector2i(person.x,person.y))
	if source.is_empty(): return world._block(job,"No safe water route: build a well or clear river-bank access")
	job.work_x=positions[0].x;job.work_y=positions[0].y;job.memo.water_x=source.point.x;job.memo.water_y=source.point.y
	job.work=fire.work;job.worker=person.id;job.state="Moving";job.reason=""
	return true

static func work(world: ColonyWorld, person: Dictionary, job: Dictionary) -> void:
	var fire: Dictionary = world.find(world.fire_state.fires,job.target)
	if fire.is_empty() or fire.done: world._release(job,true);return
	if job.memo.phase=="water":
		person.activity="Fetching water for fire (2 WU)"
		if not world._walk(person,Vector2i(job.memo.water_x,job.memo.water_y)): return
		job.memo.water_work=mini(2000,job.memo.water_work+world._rate(person,job))
		if job.memo.water_work==2000:
			if world.in_tick and not world.committing_work: world.work_commits.append({"kind":"water","worker":person.id,"job":job.id})
			else: water_ready(world,person,job)
	elif job.memo.phase=="carry":
		person.activity="Carrying a water load in both hands"
		if world._walk(person,Vector2i(job.work_x,job.work_y)): job.memo.phase="apply"
	else:
		person.activity="Extinguishing fire (8 WU)"
		var amount: int = mini(8000-fire.work,world._rate(person,job));fire.work+=amount;fire.pending_xp[person.id]=fire.pending_xp.get(person.id,0)+amount;job.work=fire.work
		if fire.work==8000: world._finish(person,job)

static func complete(world: ColonyWorld, job: Dictionary) -> void:
	var fire: Dictionary = world.find(world.fire_state.fires,job.target)
	fire.done=true;job.pending_xp=fire.pending_xp.duplicate();world.danger_cache_tick=-1
	ColonyTrade.fact(world,"fire_extinguished","Care extinguished this target completely after water delivery and eight WU; partial effort and completed WU were retained.",job.id)

static func released(world: ColonyWorld, job: Dictionary) -> void:
	if job.kind!="extinguish": return
	job.memo.phase="water";job.memo.water_work=0
	var fire: Dictionary = world.find(world.fire_state.fires,job.target)
	if not fire.is_empty(): job.work=fire.work

static func validate(data: Variant, structures: Array, stacks: Array, citizens: Array, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["fires","destroyed","alert_serial"]) or not data.fires is Array or not data.destroyed is Array or not data.alert_serial is int or data.alert_serial<0: return false
	for entry in data.destroyed:
		if not entry is Dictionary or not ColonyCodec._keys(entry,["target","tick"]) or not entry.target is int or not structures.any(func(s:Dictionary)->bool:return s.id==entry.target) or not entry.tick is int or entry.tick<1800 or entry.tick>tick: return false
	for fire in data.fires:
		if not fire is Dictionary or not ColonyCodec._keys(fire,["id","kind","target","root","created","spread_ticks","damage_rem","work","pending_xp","done"]) or not fire.id is int or fire.id<=0 or fire.kind not in ["structure","stack"] or not fire.target is int or not (structures if fire.kind=="structure" else stacks).any(func(o:Dictionary)->bool:return o.id==fire.target) or not fire.root is int or not data.fires.any(func(f:Dictionary)->bool:return f.id==fire.root) or not fire.created is int or fire.created<1800 or fire.created>tick or not fire.spread_ticks is int or fire.spread_ticks<0 or fire.spread_ticks>=600 or not fire.damage_rem is int or fire.damage_rem<0 or fire.damage_rem>=1000 or not fire.work is int or fire.work<0 or fire.work>8000 or not fire.pending_xp is Dictionary or not fire.done is bool: return false
		for id in fire.pending_xp:
			if not citizens.any(func(c:Dictionary)->bool:return c.id==id) or not fire.pending_xp[id] is int or fire.pending_xp[id]<=0: return false
	return true

static func water_ready(world: ColonyWorld, person: Dictionary, job: Dictionary) -> void:
	if job.memo.phase!="water" or job.memo.water_work!=2000: return
	world._award_xp({"skill":"Care","pending_xp":{person.id:2000}});job.memo.phase="carry";person.route.clear();person.route_goal.clear()
