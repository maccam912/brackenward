class_name ColonyCare
extends RefCounted

static func citizen_defaults() -> Dictionary:
	return {"downed":false,"stabilized":true,"bleed_ticks":0,"healing_ticks":0,"recovery_rate":2,"recovery_until":0,"recovery_windows":{},"hearthside_until":0,"carried_by":0,"carrying_patient":0,"patient_move_rem":0,"injury_id":0,"death_recorded":false}

static func initial_state() -> Dictionary:
	return {"mode":"Standard","bodies":[],"alert_serial":0,"ended":false}

static func initialize(world: ColonyWorld) -> void:
	world.care_state = initial_state()
	for person in world.citizens:
		person.merge(citizen_defaults())

static func hurt(world: ColonyWorld, person: Dictionary, damage: int, attack: bool = false, causes: Array = []) -> void:
	if person.death_recorded or person.departed or person.hearthside_until > world.tick or (attack and person.downed): return
	var before: int = person.health
	person.health = maxi(0,person.health-maxi(0,damage))
	if attack and person.health <= 20: person.health = maxi(10,person.health)
	if before>person.health and causes.is_empty():
		causes=[world.emit_fact({"tick":world.tick,"actor":person.id,"job":0,"kind":"health_loss","text":"%s lost %d health." % [person.name,before-person.health]})]
	if person.health < 50:
		var current: Dictionary = world.find(world.jobs,person.job)
		if current.get("kind") not in ["eat","sleep","recover","rescue"]: world._release(current,false)
	if person.health <= 20 and not person.downed:
		person.downed = true
		person.stabilized = false
		person.bleed_ticks = 0
		person.injury_id = world._id()
		person.progress = 0; person.travel_credit = 0
		person.activity = "Downed: bleeding, needs care"
		world._release(world.find(world.jobs,person.job),false)
		world.care_state.alert_serial += 1
		var downed_fact: int = world.emit_fact({"tick":world.tick,"actor":person.id,"job":0,"kind":"downed","text":person.name+" is downed. Bleeding costs 2 health/hour until treatment. Care workers rescue and treat automatically; Treat now overrides Care Off."},{"causes":causes})
		ColonyChronicle.remember(world,"downed:"+str(person.id),downed_fact)
	if person.health == 0: _zero_health(world,person,causes)

static func advance(world: ColonyWorld) -> void:
	for person in world.citizens:
		if person.death_recorded or person.departed or person.away: continue
		if person.health == 0 and person.hearthside_until == 0: _zero_health(world,person)
		if person.hearthside_until > 0:
			if world.tick >= person.hearthside_until:
				person.hearthside_until = 0
				person.health = 40; person.stabilized = true; person.downed = false
				person.recovery_rate = 2; person.recovery_until = 0
				person.recovery_windows.clear()
				person.healing_ticks = 0
				world.emit_fact({"tick":world.tick,"actor":person.id,"job":0,"kind":"recovered","text":person.name+" wakes at 40 health after Hearthside recovery; rest until 50 before working."})
			else: continue
		if person.health <= 20 and not person.downed: hurt(world,person,0)
		if person.downed and not person.stabilized:
			person.bleed_ticks += 1
			if person.bleed_ticks >= 300:
				person.bleed_ticks -= 300
				var bleeding: int = world.emit_fact({"tick":world.tick,"actor":person.id,"job":0,"kind":"bleeding","text":person.name+" lost %d health from untreated bleeding." % mini(2,person.health)},{"causes":ColonyChronicle.causes(world,"downed:"+str(person.id))})
				hurt(world,person,2,false,[bleeding])
		if person.death_recorded: continue
		var healing_rate: int = recovery(world,person,true).rate
		refresh_recovery(world,person)
		var job: Dictionary = world.find(world.jobs,person.job)
		var resting: bool = person.carried_by == 0 and (person.downed or (job.get("kind") in ["sleep","recover"] and job.get("state") == "Working"))
		if person.stabilized and resting and person.health < 100:
			person.healing_ticks += healing_rate
			person.health = mini(100,person.health+person.healing_ticks/300)
			person.healing_ticks %= 300
			if person.health == 100: person.healing_ticks = 0
			if person.health > 20: person.downed = false
	world.care_state.ended = not world.citizens.any(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed)

static func _zero_health(world: ColonyWorld, person: Dictionary, causes: Array = []) -> void:
	if person.death_recorded or person.hearthside_until > 0: return
	world._release(world.find(world.jobs,person.job),true)
	for job in world.jobs:
		if job.target == person.id and job.kind in ["treat","feed","rescue"] and job.state not in ["Complete","Canceled"]: world._release(job,true)
	if world.care_state.mode == "Hearthside":
		person.downed = true; person.stabilized = true
		person.hearthside_until = world.tick+14400
		world.care_state.alert_serial += 1
		world.emit_fact({"tick":world.tick,"actor":person.id,"job":0,"kind":"hearthside","text":person.name+" is recovering for two days and will wake at 40 health. Needs and shortages continue."},{"causes":causes})
		return
	var relationships: Dictionary = {}
	for other in world.citizens:
		if other.id != person.id: relationships[other.id] = world.social_state.pairs[ColonySocial.key(person.id,other.id)].score
	world.social_state.deaths.append({"actor":person.id,"tick":world.tick,"name":person.name,"citizen":person.duplicate(true),"relationships":relationships})
	person.death_recorded = true; person.downed = false; person.stabilized = false
	person.activity = "Died"
	for slot in person.equipment:
		var item: String = person.equipment[slot]
		if not item.is_empty(): world._make_stack(item,1,"ground",0,Vector2i(person.x,person.y),false)
		person.equipment[slot] = ""
	var bed: Dictionary = world.find(world.structures,person.bed)
	if not bed.is_empty() and bed.user == person.id: bed.user = 0
	person.bed = 0
	world.care_state.bodies.append({"id":world._id(),"patient":person.id,"x":person.x,"y":person.y,"created":world.tick,"buried":false})
	for request in world.social_state.requests:
		if request.actor == person.id and request.state in ["Offered","Accepted"]:
			request.state = "Declined" if request.state == "Offered" else "Failed"
	world.care_state.alert_serial += 1
	var death: int = world.emit_fact({"tick":world.tick,"actor":person.id,"job":0,"kind":"death","text":person.name+" died. Carried goods and worn equipment were dropped. Mark the body tile for burial; relationships and memories remain in the journal."},{"causes":causes})
	ColonyChronicle.remember(world,"death:"+str(person.id),death)
	world.care_state.ended = not world.citizens.any(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed)

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	if kind == "care_mode":
		if args.mode not in ["Standard","Hearthside"]: return "Unknown mode"
		world.care_state.mode = args.mode
		return "accepted"
	if kind == "burial":
		var body: Dictionary = world.find(world.care_state.bodies,args.target)
		if body.is_empty() or body.buried: return "Body already buried or missing"
		if not world.walkable(Vector2i(args.x,args.y)): return "Choose a reachable burial tile"
		if _exists(world,"bury",body.id): return "Burial already marked"
		var job: Dictionary = world._job("bury","Care","Care",body.id,Vector2i(args.x,args.y),12000)
		job.source = body.patient
		return "accepted"
	var patient: Dictionary = world.find(world.citizens,args.target)
	var worker: Dictionary = world.find(world.citizens,args.citizen)
	if patient.is_empty() or patient.death_recorded or patient.health >= 100: return "No living injured patient"
	if worker.is_empty() or worker.id == patient.id or worker.health < 50 or worker.departed or worker.break_until > world.tick or worker.rest <= 100 or worker.fullness == 0: return "Choose a healthy available resident"
	var job: Dictionary = _treatment(world,patient)
	world._release(world.find(world.jobs,patient.job),false)
	job.priority = 3
	worker.pinned_job = job.id
	world._release(world.find(world.jobs,worker.job),false)
	return "accepted"

static func _exists(world: ColonyWorld, kind: String, patient: int) -> bool:
	return world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind == kind and j.target == patient and j.state not in ["Complete","Canceled"])

static func _treatment(world: ColonyWorld, patient: Dictionary) -> Dictionary:
	for existing in world.jobs:
		if existing.kind == "treat" and existing.target == patient.id and existing.state not in ["Complete","Canceled"]: return existing
	var treatment: String = "medicine" if world.available("medicine") > 0 else ("herb" if world.available("herb") > 0 else "stabilize")
	var required: int = {"medicine":10000,"herb":16000,"stabilize":24000}[treatment]
	var job: Dictionary = world._job("treat","Care","Care",patient.id,Vector2i(patient.x,patient.y),required)
	job.definition = treatment
	if treatment != "stabilize": job.inputs = {treatment:1}
	return job

static func destination(world: ColonyWorld, patient: Dictionary) -> Dictionary:
	if world.navigation_dirty:
		world.care_destinations.clear()
		world.walkable(Vector2i.ZERO)
	var origin: Vector2i = Vector2i(patient.x,patient.y)
	var occupied_beds: Array = []
	for bed in world.structures:
		if bed.health<=0: continue
		if bed.definition in ["bed","bedroll"] and world.citizens.any(func(c:Dictionary)->bool:return c.id != patient.id and c.health > 0 and not c.departed and c.x == bed.x and c.y == bed.y): occupied_beds.append(bed.id)
	var cached: Dictionary = world.care_destinations.get(patient.id,{})
	if cached.get("origin") == origin and cached.get("occupied") == occupied_beds: return cached.result
	var beds: Dictionary = {}
	for bed in world.structures:
		if bed.health<=0 or bed.definition not in ["bed","bedroll"]: continue
		# Keep the original first-record behavior when already on a bed, even if
		# another resident is there. Other ties use the immutable bed ID.
		if origin == Vector2i(bed.x,bed.y): return {"id":bed.id,"point":origin,"distance":0}
		if occupied_beds.has(bed.id): continue
		var cell: int=bed.y*128+bed.x
		if not beds.has(cell) or bed.id<beds[cell]: beds[cell]=bed.id
	var distance: PackedInt32Array = PackedInt32Array()
	if not beds.is_empty():
		# Only route length is used here. One breadth-first search gives the same
		# shortest lengths as every earlier A*, including bridges/elevation.
		var grid: Dictionary=world.navigation_grid()
		var cells: PackedByteArray=grid.passable;var bridges: PackedByteArray=grid.bridges
		distance.resize(16384);distance.fill(-1)
		var queue: PackedInt32Array=PackedInt32Array();queue.resize(16384)
		var start: int=origin.y*128+origin.x;distance[start]=0;queue[0]=start
		var cursor: int=0;var tail: int=1;var best: Dictionary={}
		var steps: Array[int]=[-128,1,128,-1]
		while cursor<tail:
			var index: int=queue[cursor];var column: int=index%128;cursor+=1
			var length: int=distance[index]
			if not best.is_empty() and length>best.distance: break
			if beds.has(index) and cells[index]:
				if best.is_empty() or beds[index]<best.id:
					best={"id":beds[index],"point":Vector2i(column,index/128),"distance":length}
			if not best.is_empty(): continue
			for direction in range(4):
				var next: int=index+steps[direction]
				if next<0 or next>=16384 or (direction==1 and column==127) or (direction==3 and column==0): continue
				if distance[next]>=0 or not cells[next]: continue
				if world.generator_version>0 and not bridges[index] and not bridges[next] and absi(world.terrain_state.elevation[index]-world.terrain_state.elevation[next])>1: continue
				distance[next]=length+1;queue[tail]=next;tail+=1
		if not best.is_empty():
			world.care_destinations[patient.id]={"origin":origin,"occupied":occupied_beds,"result":best}
			return best
	var cart: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition == "supply_cart")[0]
	for point in world._perimeter(world.footprint(cart)):
		if not distance.is_empty():
			var length: int=distance[point.y*128+point.x]
			if length>=0: return {"id":0,"point":point,"distance":length}
		else:
			var route: Array = [] if point == origin else ColonyNavigation.path(origin,point,world.walkable,world.can_step)
			if point == origin or not route.is_empty(): return {"id":0,"point":point,"distance":route.size()}
	return {"id":0,"point":origin,"distance":0}

static func create_jobs(world: ColonyWorld) -> void:
	for patient in world.citizens:
		if patient.death_recorded or patient.departed or patient.away or patient.carried_by > 0: continue
		if patient.downed:
			var bed: Dictionary = destination(world,patient)
			# If transport would outlast bleeding, stabilize at the current position first.
			var critical: bool = not patient.stabilized and bed.distance*20 >= ((patient.health+1)/2)*300-patient.bleed_ticks
			if bed.distance > 0 and not critical and not _exists(world,"rescue",patient.id):
				var rescue: Dictionary = world._job("rescue","Care","",patient.id,Vector2i(patient.x,patient.y),0)
				rescue.destination = bed.id; rescue.definition = "pickup"; rescue.emergency = true
				rescue.care_goal = [bed.point.x,bed.point.y]
			if patient.hearthside_until == 0 and (not patient.stabilized or (patient.health < 50 and patient.recovery_until <= world.tick)):
				var treatment: Dictionary = _treatment(world,patient)
				if critical: treatment.emergency = true; treatment.priority = 3
			if patient.fullness <= 350 and not _exists(world,"feed",patient.id):
				var food: Dictionary = world._food(patient)
				if not food.is_empty():
					var feed: Dictionary = world._job("feed","Care","",patient.id,Vector2i(patient.x,patient.y),2000)
					feed.source = food.id; feed.inputs = {food.item:1}

static func reserve(world: ColonyWorld, job: Dictionary, worker: Dictionary) -> bool:
	if job.kind == "bury":
		var body: Dictionary = world.find(world.care_state.bodies,job.target)
		if body.is_empty() or body.buried: job.state = "Canceled"; return false
		# Burial in place is a marked tile; transportation to memorials is separate work.
		if body.x != job.x or body.y != job.y: return world._block(job,"Mark the body tile for burial")
		return true
	var patient: Dictionary = world.find(world.citizens,job.target)
	if patient.is_empty() or patient.death_recorded or patient.carried_by > 0: return world._block(job,"Patient unavailable or being carried")
	if job.kind == "rescue" and not patient.downed: job.state = "Canceled"; return false
	for other in world.jobs:
		if other.id != job.id and other.target == patient.id and other.worker > 0 and other.kind in ["treat","rescue","feed"]: return world._block(job,"Patient is receiving care")
	job.x = patient.x; job.y = patient.y
	if job.kind == "treat" and not job.inputs.keys().all(func(item:Variant)->bool:return world.available(item)+world._escrow_count(job.id,item) >= job.inputs[item]):
		job.definition = "medicine" if job.work <= 10000 and world.available("medicine") > 0 else ("herb" if job.work <= 16000 and world.available("herb") > 0 else "stabilize")
		job.required = {"medicine":10000,"herb":16000,"stabilize":24000}[job.definition]
		job.inputs = {} if job.definition == "stabilize" else {job.definition:1}
		job.reason = "Previous dressing unavailable; selected "+job.definition+" and retained work"
	if job.kind == "feed":
		var source: Dictionary = world.find(world.stacks,job.source)
		if source.is_empty() or source.count <= 0:
			source = world._food(patient)
			if source.is_empty(): return world._block(job,"No edible food available for the patient")
			job.source = source.id; job.inputs = {source.item:1}
	return worker.id != patient.id

static func rescue_work(world: ColonyWorld, worker: Dictionary, job: Dictionary) -> void:
	var patient: Dictionary = world.find(world.citizens,job.target)
	if job.definition == "pickup":
		if not world._walk(worker,Vector2i(patient.x,patient.y)): return
		patient.carried_by = worker.id; worker.carrying_patient = patient.id
		job.definition = "carrying"
		worker.route.clear(); worker.route_goal.clear()
		job.work_x = job.care_goal[0]; job.work_y = job.care_goal[1]
	worker.activity = "Carrying "+patient.name+" to safety"
	var arrived: bool = world._walk(worker,Vector2i(job.work_x,job.work_y))
	patient.x = worker.x; patient.y = worker.y
	if arrived:
		patient.carried_by = 0; worker.carrying_patient = 0
		var causes: Array = ColonyChronicle.causes(world,"downed:"+str(patient.id))
		var text: String = worker.name+" carried "+patient.name+" to safety"+(" after a boar injury." if ColonyChronicle.has_ancestor(world,causes,"boar_injury") else ".")
		var rescue: int = world.emit_fact({"tick":world.tick,"actor":worker.id,"job":job.id,"kind":"rescue","text":text},{"participants":[worker.id,patient.id],"location":[patient.x,patient.y],"causes":causes})
		ColonyChronicle.remember(world,"job:"+str(job.id),rescue)
		ColonySocial.rescue(world,worker.id,patient.id,patient.injury_id,rescue)
		world._complete(worker,job)

static func complete(world: ColonyWorld, worker: Dictionary, job: Dictionary) -> void:
	if job.kind == "bury": world.find(world.care_state.bodies,job.target).buried = true; return
	var patient: Dictionary = world.find(world.citizens,job.target)
	if job.kind == "treat":
		patient.stabilized = true; patient.bleed_ticks = 0
		patient.health = mini(100,patient.health+{"medicine":20,"herb":10,"stabilize":0}[job.definition])
		patient.recovery_windows[job.definition] = world.tick+3600
		refresh_recovery(world,patient)
		if patient.health > 20: patient.downed = false
		var changes: Dictionary = {}
		for item in job.inputs: changes[item]=-job.inputs[item]
		var treated: int = world.emit_fact({"tick":world.tick,"actor":worker.id,"job":job.id,"kind":"treatment","text":worker.name+" treated "+patient.name+" with "+job.definition+"; bleeding is stopped."},{"participants":[worker.id,patient.id],"location":[patient.x,patient.y],"changes":changes,"causes":ColonyChronicle.causes(world,"downed:"+str(patient.id))})
		ColonyChronicle.remember(world,"job:"+str(job.id),treated)
	elif job.kind == "feed":
		var item: String = job.inputs.keys()[0]
		patient.fullness = mini(1000,patient.fullness+world.definitions.items[item].fullness)
		patient.starving_ticks = 0
		for tag in world.definitions.items[item].tags:
			if not patient.food_tags.has(tag): patient.food_tags.append(tag)
		if item not in ["meal","travel_ration"]: patient.raw_memory_until = world.tick+1800
		var fed: int = world.emit_fact({"tick":world.tick,"actor":worker.id,"job":job.id,"kind":"patient_fed","text":worker.name+" fed one "+item+" to "+patient.name+"."},{"participants":[worker.id,patient.id],"location":[patient.x,patient.y],"changes":{item:-1},"causes":ColonyChronicle.causes(world,"downed:"+str(patient.id))})
		ColonyChronicle.remember(world,"job:"+str(job.id),fed)
		if item not in ["meal","travel_ration"]: ColonyChronicle.remember(world,"raw_food:"+str(patient.id),fed)

static func released(world: ColonyWorld, job: Dictionary) -> void:
	if job.kind == "rescue" and job.worker > 0:
		var worker: Dictionary = world.find(world.citizens,job.worker)
		if worker.carrying_patient > 0:
			var patient: Dictionary = world.find(world.citizens,worker.carrying_patient)
			patient.carried_by = 0; patient.x = worker.x; patient.y = worker.y
			worker.carrying_patient = 0
		job.definition = "pickup"

static func mood_terms(world: ColonyWorld, person: Dictionary) -> Dictionary:
	var terms: Dictionary = {}
	for death in world.social_state.deaths:
		if death.actor == person.id: continue
		var friend: bool = death.relationships.get(person.id,0) >= 40
		var duration: int = 21600 if friend else 14400
		var remaining: int = duration-(world.tick-death.tick)
		if remaining > 0: terms["Grief for "+death.name] = -(180 if friend else 80)*remaining/duration
	for body in world.care_state.bodies:
		if not body.buried and absi(body.x-person.x)+absi(body.y-person.y) <= 4: terms["Unburied resident nearby"] = -40; break
	return terms

static func recovery(world: ColonyWorld, person: Dictionary, completed_interval: bool = false) -> Dictionary:
	var result: Dictionary = {"rate":2,"until":0}
	for treatment in person.recovery_windows:
		var until: int = person.recovery_windows[treatment]
		if until < world.tick or (until == world.tick and not completed_interval): continue
		var rate: int = {"medicine":8,"herb":4,"stabilize":2}[treatment]
		if rate > result.rate or (rate == result.rate and until > result.until): result = {"rate":rate,"until":until}
	return result

static func refresh_recovery(world: ColonyWorld, person: Dictionary) -> void:
	var active: Dictionary = recovery(world,person)
	person.recovery_rate = active.rate; person.recovery_until = active.until

static func validate(data: Variant, citizens: Array, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["mode","bodies","alert_serial","ended"]) or data.mode not in ["Standard","Hearthside"] or not data.bodies is Array or not data.alert_serial is int or data.alert_serial < 0 or not data.ended is bool: return false
	if data.ended != not citizens.any(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed): return false
	for body in data.bodies:
		if not body is Dictionary or not ColonyCodec._keys(body,["id","patient","x","y","created","buried"]) or not ColonyCodec._position(body) or not body.id is int or not body.patient is int or not body.created is int or body.created < 1800 or body.created > tick or not body.buried is bool: return false
		if not citizens.any(func(c:Dictionary)->bool:return c.id == body.patient and c.death_recorded): return false
	for person in citizens:
		for field in citizen_defaults():
			if field not in ["downed","stabilized","death_recorded","recovery_windows"] and (not person[field] is int or person[field] < 0): return false
		for treatment in person.recovery_windows:
			if treatment not in ["medicine","herb","stabilize"] or not person.recovery_windows[treatment] is int or person.recovery_windows[treatment] < 0 or person.recovery_windows[treatment] > tick+3600: return false
		if person.bleed_ticks >= 300 or person.healing_ticks >= 300 or person.patient_move_rem >= 1000 or person.recovery_rate not in [2,4,8] or person.recovery_until > tick+3600 or person.hearthside_until > tick+14400: return false
		if person.death_recorded and (person.health != 0 or person.job != 0 or person.equipment.values().any(func(s:Variant)->bool:return not s.is_empty())): return false
		if person.carried_by > 0 and not citizens.any(func(c:Dictionary)->bool:return c.id == person.carried_by and c.carrying_patient == person.id): return false
		if person.carrying_patient > 0 and not citizens.any(func(c:Dictionary)->bool:return c.id == person.carrying_patient and c.carried_by == person.id): return false
	return true
