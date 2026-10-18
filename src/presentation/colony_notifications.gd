class_name ColonyNotifications
extends RefCounted
## Presentation only. Existing discoveries stay in the Chronicle after reload.
var world_id: int = 0
var seen_research: Array = []
var entries: Array[Dictionary] = []

func reset(world: RefCounted) -> void:
	world_id=world.get_instance_id()
	seen_research=world.researched.duplicate() if world is ColonyWorld else []
	entries.clear()

func observe(world: RefCounted) -> void:
	if world_id!=world.get_instance_id(): reset(world);return
	if not world is ColonyWorld: return
	for project in world.researched:
		if seen_research.has(project): continue
		seen_research.append(project)
		entries.append({"project":project,"read":false})

func pending() -> Array[Dictionary]:
	return entries.filter(func(entry:Dictionary)->bool:return not entry.read)

func dismiss() -> void:
	var unread: Array[Dictionary]=pending()
	if not unread.is_empty(): unread[0].read=true

static func benches(world: ColonyWorld, target: int = 0) -> Array[Dictionary]:
	var assigned: Dictionary={}
	for person in world.citizens:
		if person.job==0 or person.downed or person.death_recorded or person.departed or person.away: continue
		var job: Dictionary=world.find(world.jobs,person.job)
		if job.get("kind","") not in ["research","minor_study"] or job.get("worker",0)!=person.id or job.state in ["Complete","Canceled","Blocked"]: continue
		if job.kind=="research" and job.definition!=world.production_state.project: continue
		var station: int=job.target if job.kind=="research" else job.memo.get("station",0)
		assigned[station]={"state":"working" if job.state=="Working" else "traveling","shared":job.kind=="minor_study"}
	var result: Array[Dictionary]=[]
	for station in world.structures:
		if station.definition!="research_desk" or station.health<=0 or (target>0 and station.id!=target): continue
		var state: String="waiting"
		if not station.cooking: state="suspended"
		elif ColonyFire.burning(world,"structure",station.id): state="unavailable"
		elif assigned.has(station.id): state=assigned[station.id].state
		elif world.researched.size()==world.definitions.research.size(): state="finished"
		elif world.production_state.project.is_empty(): state="choose"
		result.append({"id":station.id,"state":state,"shared":assigned.get(station.id,{}).get("shared",false)})
	return result
