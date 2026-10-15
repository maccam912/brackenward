class_name RouteContextReference
extends ColonyWorld

static func clone_world(source: ColonyWorld, original: bool=false) -> ColonyWorld:
	var result: ColonyWorld=RouteContextReference.new(source.definitions) if original else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]:continue
		var value: Variant=source.get(field)
		if value is Array:result.get(field).assign(value.duplicate(true))
		elif value is Dictionary:result.set(field,value.duplicate(true))
		else:result.set(field,value)
	result.reset_job_queries();result.reset_stack_queries();result.reset_resource_queries();result.record_indexes.clear()
	result.navigation_dirty=true;result.rooms_dirty=true;result.reachability_dirty=true
	return result

class OriginalDanger:
	static func allowed(world: ColonyWorld, citizen: Dictionary, point: Vector2i) -> bool:
		if not world.walkable(point): return false
		var job: Dictionary = world.find(world.jobs,citizen.job)
		if job.get("kind")=="cart_move" and job.memo.phase=="push" and job.state=="Working" and not ColonyMaintenance.cart_position_error(world,world.find(world.structures,job.target),point).is_empty(): return false
		if job.get("kind") == "lead_animal" and world.structures.any(func(s:Dictionary)->bool:return s.definition in ["fence","door"] and world.footprint(s).has(point)): return false
		return job.get("emergency",false) or job.get("kind") in ["hunt","escort_hunt","escape","defend"] or ColonyDanger.safe(world,point)

## Complete 4515ea6 walk oracle; original per-edge job lookup remains.
func _walk(citizen: Dictionary, goal: Vector2i) -> bool:
	if citizen.progress == 0 and citizen.x == goal.x and citizen.y == goal.y:
		return true
	if citizen.progress == 0:
		if citizen.route_goal != [goal.x, goal.y] or citizen.route.is_empty():
			if path_requests >= 4:
				return false
			path_requests += 1
			var origin: Vector2i = Vector2i(citizen.x,citizen.y)
			# Opposite sides of the known home component cannot share a route.
			# Still consume the request slot and preserve normal no-route handling.
			# An obstructed starting tile may step out, so it keeps the A* fallback.
			var disconnected: bool = walkable(origin) and walkable(goal) and accessible(origin)!=accessible(goal)
			var route: Array[Vector2i] = []
			if not disconnected:
				route=ColonyNavigation.path(origin,goal,func(p:Vector2i)->bool:return OriginalDanger.allowed(self,citizen,p),func(a:Vector2i,b:Vector2i)->bool:
					var task: Dictionary = find(jobs,citizen.job)
					return ColonyMaintenance.cart_edge(self,a,b) if task.get("kind")=="cart_move" and task.memo.phase=="push" and task.state=="Working" else can_step(a,b))
			citizen.route=route
			citizen.route_goal = [goal.x, goal.y]
		if citizen.route.is_empty():
			var job: Dictionary = find(jobs, citizen.job)
			if job.get("kind")=="sleep" and job.target>0 and walkable(Vector2i(citizen.x,citizen.y)) and ColonyDanger.safe(self,Vector2i(citizen.x,citizen.y)):
				# Keep the assigned bed, but finish this sleep on safe ground rather
				# than recreating an impossible personal route every scheduler pass.
				job.target=0;job.x=citizen.x;job.y=citizen.y
				job.work_x=citizen.x;job.work_y=citizen.y
				job.reason="Assigned bed unreachable: clear access or reassign bed"
				citizen.route_goal.clear()
				return true
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

