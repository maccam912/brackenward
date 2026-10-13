class_name ColonyDanger
extends RefCounted

static func sources(world: ColonyWorld) -> Array[Vector2i]:
	if world.danger_cache_tick == world.tick: return world.danger_cache
	var result: Array[Vector2i] = []
	for animal in world.wildlife_state.animals:
		if animal.health<=0 or animal.definition!="boar": continue
		if animal.attacker>0 or world.jobs.any(func(j:Dictionary)->bool:return j.kind=="hunt" and j.target==animal.id and j.state not in ["Complete","Canceled"]): result.append(Vector2i(animal.x,animal.y))
	for enemy in world.defense_state.enemies:
		if ColonyDefense.enemy_active(enemy) and world.find(world.defense_state.raids,enemy.raid).get("state")=="Active": result.append(Vector2i(enemy.x,enemy.y))
	for fire in ColonyFire.active(world):
		for tile in ColonyFire.footprint(world,fire):
			if not result.has(tile): result.append(tile)
	world.danger_cache_tick = world.tick; world.danger_cache = result
	return result

static func safe(world: ColonyWorld, point: Vector2i) -> bool:
	for source in sources(world):
		if absi(point.x-source.x)+absi(point.y-source.y)<=8: return false
	return true

static func allowed(world: ColonyWorld, citizen: Dictionary, point: Vector2i) -> bool:
	if not world.walkable(point): return false
	var job: Dictionary = world.find(world.jobs,citizen.job)
	if job.get("kind")=="cart_move" and job.memo.phase=="push" and job.state=="Working" and not ColonyMaintenance.cart_position_error(world,world.find(world.structures,job.target),point).is_empty(): return false
	if job.get("kind") == "lead_animal" and world.structures.any(func(s:Dictionary)->bool:return s.definition in ["fence","door"] and world.footprint(s).has(point)): return false
	return job.get("emergency",false) or job.get("kind") in ["hunt","escort_hunt","escape","defend"] or safe(world,point)

static func escape(world: ColonyWorld, citizen: Dictionary) -> bool:
	var current: Dictionary = world.find(world.jobs,citizen.job)
	# A newly confirmed defense order has no job yet, but already permits danger.
	if citizen.drafted and citizen.break_until<=world.tick and citizen.fullness>0 and citizen.rest>100 and (citizen.health>40 or (citizen.health>20 and citizen.stand_fast)): return false
	if current.get("kind") in ["hunt","escort_hunt","escape","defend"] or current.get("emergency",false) or safe(world,Vector2i(citizen.x,citizen.y)): return false
	var start: Vector2i = Vector2i(citizen.x,citizen.y)
	var queue: Array[Vector2i] = [start]
	var seen: Dictionary = {start:0}
	var cursor: int = 0
	var candidates: Array[Vector2i] = []
	var reachable: Array[Vector2i] = []
	while cursor<queue.size():
		var point: Vector2i = queue[cursor]; cursor += 1
		reachable.append(point)
		if safe(world,point): candidates.append(point)
		if seen[point]>=16: continue
		for delta in ColonyNavigation.NEIGHBORS:
			var next: Vector2i = point+delta
			if not seen.has(next) and world.walkable(next) and world.can_step(point,next): seen[next]=seen[point]+1;queue.append(next)
	if candidates.is_empty():
		# A confined resident still moves away from the threat even when no tile
		# clears the ordinary eight-tile work exclusion radius.
		candidates=reachable
	candidates.sort_custom(func(a:Vector2i,b:Vector2i)->bool:
		var roof_a: bool = safe(world,a) and world.roofed(a);var roof_b: bool = safe(world,b) and world.roofed(b)
		if roof_a!=roof_b: return roof_a
		if not roof_a:
			var aa: int = 100000;var bb: int = 100000
			for source in sources(world): aa=mini(aa,absi(a.x-source.x)+absi(a.y-source.y));bb=mini(bb,absi(b.x-source.x)+absi(b.y-source.y))
			if aa!=bb: return aa>bb
		if seen[a]!=seen[b]: return seen[a]<seen[b]
		return a.y*128+a.x<b.y*128+b.x)
	if candidates.is_empty() or candidates[0]==start:
		citizen.activity = "Unsafe route: already at the safest reachable tile; clear an exit or extinguish the fire"
		return false
	world._release(current,false)
	var job: Dictionary = world._job("escape","","",citizen.id,candidates[0],0)
	job.worker=citizen.id;job.state="Moving";citizen.job=job.id
	citizen.activity="Escaping danger"
	return true
