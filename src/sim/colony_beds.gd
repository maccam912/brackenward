class_name ColonyBeds
extends RefCounted
## Assignment changes a policy; sleep and recovery remain physical activities.
static func quote(world: ColonyWorld, citizen_id: int, target: int) -> String:
	var person: Dictionary = world.find(world.citizens,citizen_id)
	if person.is_empty() or person.death_recorded or person.departed: return "Choose a living resident"
	if person.away: return "Reassign a bed after this resident returns home"
	if target==0: return ""
	var bed: Dictionary = world.find(world.structures,target)
	if bed.is_empty() or bed.definition not in ["bed","bedroll"] or bed.health<=0: return "Choose a completed bed or bedroll"
	if bed.user>0 and bed.user!=person.id: return "Assigned to %s: unassign their bed first" % ColonyChronicle.display_name(world,bed.user)
	if ColonyFire.burning(world,"structure",bed.id): return "Extinguish this bed before assigning it"
	var point: Vector2i = Vector2i(bed.x,bed.y)
	if not world.walkable(point) or not ColonyDanger.safe(world,point): return "Bed is unsafe: clear danger and access first"
	var start: Vector2i = Vector2i(person.edge_x,person.edge_y) if person.progress>0 else Vector2i(person.x,person.y)
	if start!=point and ColonyNavigation.path(start,point,func(p:Vector2i)->bool:return world.walkable(p) and ColonyDanger.safe(world,p),func(a:Vector2i,b:Vector2i)->bool:return world.can_step(a,b)).is_empty(): return "Bed unreachable: clear access or choose another bed"
	return ""

static func command(world: ColonyWorld, args: Dictionary) -> String:
	if not ColonyCodec._keys(args,["citizen","target"]) or not args.citizen is int or not args.target is int or args.target<0: return "Choose a resident and a bed, or unassign with target zero"
	var error: String = quote(world,args.citizen,args.target)
	if not error.is_empty(): return error
	var person: Dictionary = world.find(world.citizens,args.citizen)
	if person.bed==args.target: return "accepted"
	var previous: Dictionary = world.find(world.structures,person.bed)
	if not previous.is_empty() and previous.user==person.id: previous.user=0
	person.bed=args.target
	var bed: Dictionary = world.find(world.structures,args.target)
	if not bed.is_empty(): bed.user=person.id
	person.bed_sleep_ticks=0
	var job: Dictionary = world.find(world.jobs,person.job)
	if job.get("kind")=="sleep" and not person.downed:
		var point: Vector2i = Vector2i(person.edge_x,person.edge_y) if person.progress>0 else Vector2i(person.x,person.y)
		var use_bed: bool = not bed.is_empty()
		if use_bed: point=Vector2i(bed.x,bed.y)
		job.target=args.target if use_bed else 0;job.x=point.x;job.y=point.y;job.work_x=point.x;job.work_y=point.y
		job.state="Moving";job.reason="" if use_bed else "No assigned bed: sleeping on safe ground"
		person.route.clear();person.route_goal.clear()
	world.emit_fact({"tick":world.tick,"actor":person.id,"job":0,"kind":"bed_assigned","text":person.name+(" has no assigned bed and will sleep on safe ground." if bed.is_empty() else " is assigned to "+ColonyChronicle.display_name(world,bed.id)+". They walk there when they need sleep.")},{"participants":[person.id] if bed.is_empty() else [person.id,bed.id]})
	return "accepted"

static func description(world: ColonyWorld, person: Dictionary) -> String:
	var bed: Dictionary = world.find(world.structures,person.bed)
	if bed.is_empty() or bed.health<=0: return "No assigned bed | ground rest %d/hour" % ColonyRest.GROUND
	return "%s at %d,%d | %s | rest %d/hour" % [ColonyChronicle.display_name(world,bed.id),bed.x,bed.y,"Roofed" if world.roofed(Vector2i(bed.x,bed.y)) else "Outdoors",ColonyRest.recovery_rate(bed.definition)]
