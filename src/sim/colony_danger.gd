class_name ColonyDanger
extends RefCounted

static func sources(world: ColonyWorld) -> Array[Vector2i]:
	if world.danger_cache_tick == world.tick: return world.danger_cache
	var result: Array[Vector2i] = []
	for animal in world.wildlife_state.animals:
		if animal.health<=0 or animal.definition!="boar": continue
		if animal.attacker>0 or world.jobs.any(func(j:Dictionary)->bool:return j.kind=="hunt" and j.target==animal.id and j.state not in ["Complete","Canceled"]): result.append(Vector2i(animal.x,animal.y))
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
	return job.get("emergency",false) or job.get("kind") in ["hunt","escort_hunt","escape"] or safe(world,point)

static func escape(world: ColonyWorld, citizen: Dictionary) -> bool:
	var current: Dictionary = world.find(world.jobs,citizen.job)
	if current.get("kind") in ["hunt","escort_hunt","escape"] or current.get("emergency",false) or safe(world,Vector2i(citizen.x,citizen.y)): return false
	var start: Vector2i = Vector2i(citizen.x,citizen.y)
	var queue: Array[Vector2i] = [start]
	var seen: Dictionary = {start:0}
	var cursor: int = 0
	var candidates: Array[Vector2i] = []
	while cursor<queue.size():
		var point: Vector2i = queue[cursor]; cursor += 1
		if safe(world,point): candidates.append(point)
		if seen[point]>=16: continue
		for delta in ColonyNavigation.NEIGHBORS:
			var next: Vector2i = point+delta
			if not seen.has(next) and world.walkable(next) and world.can_step(point,next): seen[next]=seen[point]+1;queue.append(next)
	if candidates.is_empty():
		citizen.activity = "Unsafe route: no escape within sixteen tiles"
		return false
	candidates.sort_custom(func(a:Vector2i,b:Vector2i)->bool:
		var roof_a: bool = world.roofed(a);var roof_b: bool = world.roofed(b)
		if roof_a!=roof_b: return roof_a
		if seen[a]!=seen[b]: return seen[a]<seen[b]
		return a.y*128+a.x<b.y*128+b.x)
	world._release(current,false)
	var job: Dictionary = world._job("escape","","",citizen.id,candidates[0],0)
	job.worker=citizen.id;job.state="Moving";citizen.job=job.id
	citizen.activity="Escaping a dangerous hunt"
	return true
