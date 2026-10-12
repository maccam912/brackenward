class_name ColonyConstruction
extends RefCounted
const PAINTABLE: Array = ["wood_wall","stone_wall","door","fence","pen_gate","palisade","wood_floor","stone_path","bridge"]
const OVERLAYS: Array = ["wood_floor","stone_path"]

static func initial_state() -> Dictionary:
	return {"groups":[]}

static func lodge(origin: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"definition":"door","x":origin.x+4,"y":origin.y+5,"rotation":0}]
	for x in [1,2,4,5]: result.append({"definition":"bed","x":origin.x+x,"y":origin.y+1,"rotation":1})
	for y in range(6):
		for x in range(8):
			if (x in [0,7] or y in [0,5]) and Vector2i(x,y)!=Vector2i(4,5): result.append({"definition":"wood_wall","x":origin.x+x,"y":origin.y+y,"rotation":0})
	return result

static func lodge_error(world: ColonyWorld, origin: Vector2i) -> String:
	for y in range(origin.y,origin.y+6):
		for x in range(origin.x,origin.x+8):
			var p: Vector2i = Vector2i(x,y)
			if not world.walkable(p): return "Clear an empty 8×6 land footprint"
	for blueprint in lodge(origin):
		var error: String = world.placement_error(blueprint.definition,Vector2i(blueprint.x,blueprint.y),blueprint.rotation)
		if not error.is_empty(): return "Lodge blocked at (%d,%d): %s" % [blueprint.x,blueprint.y,error]
	return ""

static func paint_preview(world: ColonyWorld, definition: String, tiles: Array) -> Dictionary:
	var valid: Array[Vector2i] = []
	var rejected: Dictionary = {}
	for p in tiles:
		if not p is Vector2i: continue
		if valid.has(p) or rejected.has(p): continue
		var error: String = "Choose a wall, fence, floor, path or bridge" if definition not in PAINTABLE else world.placement_error(definition,p,0)
		if error.is_empty(): valid.append(p)
		else: rejected[p]=error
	valid.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return a.y*128+a.x<b.y*128+b.x)
	return {"valid":valid,"rejected":rejected}

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	var blueprints: Array[Dictionary] = []
	var group: Dictionary = {}
	var omitted: int = 0
	if kind=="lodge":
		var origin: Vector2i = Vector2i(args.x,args.y)
		var error: String = lodge_error(world,origin)
		if not error.is_empty(): return error
		blueprints=lodge(origin)
		group={"id":world._id(),"kind":"lodge","members":[],"first":[],"closing":0}
		world.construction_state.groups.append(group)
	else:
		var preview: Dictionary = paint_preview(world,args.definition,args.tiles)
		if preview.valid.is_empty(): return "No valid tiles: inspect the red cells and clear obstructions"
		omitted=preview.rejected.size()
		for p in preview.valid: blueprints.append({"definition":args.definition,"x":p.x,"y":p.y,"rotation":0})
	for blueprint in blueprints:
		var definition: Dictionary = world.definitions.buildings[blueprint.definition]
		var job: Dictionary = world._job("build","Building","Build",0,Vector2i(blueprint.x,blueprint.y),definition.work_milli)
		job.definition=blueprint.definition;job.rotation=blueprint.rotation;job.inputs=definition.materials.duplicate()
		if not group.is_empty():
			job.order=group.id;group.members.append(job.id)
			if group.members.size()<=5: group.first.append(job.id)
			if blueprint.definition=="wood_wall": group.closing=job.id
	return "accepted" if omitted==0 else "Accepted %d blueprints; %d blocked cells remain unsubmitted" % [blueprints.size(),omitted]

static func ready(world: ColonyWorld, job: Dictionary) -> bool:
	if job.kind=="build" and job.order>0:
		var group: Dictionary = world.find(world.construction_state.groups,job.order)
		if not group.is_empty() and group.closing==job.id and group.first.any(func(id:int)->bool:return world.find(world.jobs,id).get("state") not in ["Complete","Canceled"]): return world._block(job,"Lodge beds and door finish before its last enclosing wall")
	if job.kind=="build_helper":
		if job.created>=world.tick: return false
		var parent: Dictionary = world.find(world.jobs,job.order)
		if parent.is_empty() or parent.kind!="build" or parent.state in ["Complete","Canceled"]: return world._block(job,"Construction ended")
		for item in parent.inputs:
			if world._escrow_count(parent.id,item)!=parent.inputs[item]: return world._block(job,"Builder is still delivering the shared construction materials")
	return true

static func create_helpers(world: ColonyWorld) -> void:
	var parents: Array = world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build" and j.state=="Working")
	for parent in parents:
		if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="build_helper" and j.order==parent.id and j.state not in ["Complete","Canceled"]): continue
		var helper: Dictionary = world._job("build_helper","Building","Build",parent.id,Vector2i(parent.x,parent.y),0)
		helper.definition=parent.definition;helper.rotation=parent.rotation;helper.order=parent.id;helper.priority=parent.priority

static func helper_work(world: ColonyWorld, citizen: Dictionary, job: Dictionary) -> void:
	var parent: Dictionary = world.find(world.jobs,job.order)
	if parent.is_empty() or parent.state in ["Complete","Canceled"]: world._release(job,true);return
	for item in parent.inputs:
		if world._escrow_count(parent.id,item)!=parent.inputs[item]: world._release(job,false);world._block(job,"Shared materials incomplete");return
	citizen.activity="Helping build "+parent.definition
	if job.state=="Moving":
		if world._walk(citizen,Vector2i(job.work_x,job.work_y)): job.state="Working"
		return
	if job.state!="Working": return
	var work: int = mini(world._rate(citizen,parent),parent.required-parent.work)
	parent.work += work;parent.pending_xp[citizen.id]=parent.pending_xp.get(citizen.id,0)+work;parent.worker_days[citizen.id]=world.tick/7200
	if parent.work>=parent.required: world._finish(citizen,parent)

static func finish_helpers(world: ColonyWorld, citizen: Dictionary, parent: Dictionary) -> void:
	var owner: Dictionary = world.find(world.citizens,parent.worker)
	if not owner.is_empty() and owner.id!=citizen.id and owner.job==parent.id: owner.job=0
	for helper in world.jobs:
		if helper.kind=="build_helper" and helper.order==parent.id and helper.state not in ["Complete","Canceled"]:
			var worker: Dictionary = world.find(world.citizens,helper.worker)
			if worker.is_empty(): helper.state="Complete"
			else: world._complete(worker,helper)

static func cancel_helpers(world: ColonyWorld, parent: Dictionary) -> void:
	for helper in world.jobs:
		if helper.kind=="build_helper" and helper.order==parent.id and helper.state not in ["Complete","Canceled"]: world._release(helper,true)

static func validate(data: Variant, jobs: Array) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["groups"]) or not data.groups is Array: return false
	for group in data.groups:
		if not group is Dictionary or not ColonyCodec._keys(group,["id","kind","members","first","closing"]) or not group.id is int or group.kind!="lodge" or not group.members is Array or group.members.size()!=28 or not group.first is Array or group.first.size()!=5 or not group.closing is int: return false
		var seen: Dictionary = {}
		for id in group.members:
			if seen.has(id): return false
			seen[id]=true
			if not id is int or not jobs.any(func(j:Dictionary)->bool:return j.id==id and j.kind=="build" and j.order==group.id): return false
		if group.first != group.members.slice(0,5): return false
		if not jobs.any(func(j:Dictionary)->bool:return j.id==group.closing and j.definition=="wood_wall"): return false
		if not group.members.has(group.closing) or not group.first.all(func(id:Variant)->bool:return id is int and group.members.has(id)): return false
	return true

static func step_aside(world: ColonyWorld, citizen: Dictionary) -> bool:
	if citizen.progress>0: return false
	var point: Vector2i = Vector2i(citizen.x,citizen.y)
	var current: Dictionary = world.find(world.jobs,citizen.job)
	if current.get("kind") in ["step_aside","eat","rescue"] or citizen.carrying_patient>0: return false
	if not current.is_empty() and current.get("kind") not in ["leisure","sleep","recover"] and current.state!="Working": return false
	var blocking: bool = world.jobs.any(func(j:Dictionary)->bool:return j.kind=="build" and j.work>0 and j.state not in ["Complete","Canceled"] and world.definitions.buildings[j.definition].solid and world.footprint(j).has(point))
	if not blocking: return false
	for delta in ColonyNavigation.NEIGHBORS:
		var next: Vector2i = point+delta
		if not world.walkable(next) or not world.can_step(point,next) or not ColonyDanger.safe(world,next): continue
		if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="build" and j.state not in ["Complete","Canceled"] and world.definitions.buildings[j.definition].solid and world.footprint(j).has(next)): continue
		world._release(current,false)
		var job: Dictionary = world._job("step_aside","","",citizen.id,next,0)
		job.worker=citizen.id;job.state="Moving";citizen.job=job.id
		citizen.activity="Stepping clear of construction"
		return true
	return false
