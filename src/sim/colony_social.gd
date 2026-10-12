class_name ColonySocial
extends RefCounted
const REQUESTS: Array[String] = ["quiet_bed","garden_seat","supper","learn","tool","valley"]
const TITLES: Dictionary = {"quiet_bed":"A quiet bed","garden_seat":"A garden seat","supper":"Supper together","learn":"Time to learn","tool":"A better tool","valley":"Walk the valley"}

static func citizen_defaults() -> Dictionary:
	return {"friend_leisure_until":0,"fulfilled_request_until":0,"broken_promise_until":0,"last_request_offer":0,"request_cycle":0,"private_leisure_ticks":0,"private_leisure_day":-1,"supper_ticks":0,"successful_trips":0}

static func initial_state(citizens: Array, tick: int) -> Dictionary:
	var pairs: Dictionary = {}
	for i in range(citizens.size()):
		for j in range(i+1,citizens.size()):
			var a: int = citizens[i].id
			var b: int = citizens[j].id
			pairs[key(a,b)] = {"a":a,"b":b,"score":20 if [a,b] in [[1,2],[3,4]] else 0,"last_interaction":tick,"last_decay":tick,"conversation_ticks":0,"conversation_day":-1,"work_day":-1,"conflict_clock":0,"conflict_until":0,"conflict_cooldown":0,"rescued":[]}
	return {"pairs":pairs,"requests":[],"supper_history":{},"deaths":[]}

static func initialize(world: ColonyWorld) -> void:
	for citizen in world.citizens:
		for field in citizen_defaults(): citizen[field] = citizen_defaults()[field]
	world.social_state = initial_state(world.citizens,world.tick)

static func key(a: int,b: int) -> String:
	return "%d:%d" % [mini(a,b),maxi(a,b)]

static func change(world: ColonyWorld, pair: Dictionary, amount: int) -> void:
	pair.score = clampi(pair.score+amount,-100,100)
	pair.last_interaction = world.tick
	pair.last_decay = world.tick

static func leisure_seat(world: ColonyWorld, citizen: Dictionary) -> Vector2i:
	var start: Vector2i = Vector2i(citizen.x,citizen.y)
	var distance: Dictionary = {start:0}
	var queue: Array[Vector2i] = [start]
	var cursor: int = 0
	while cursor < queue.size():
		var point: Vector2i = queue[cursor]
		cursor += 1
		if distance[point] >= 32: continue
		for delta in ColonyNavigation.NEIGHBORS:
			var next: Vector2i = point+delta
			if not distance.has(next) and world.walkable(next):
				distance[next] = distance[point]+1
				queue.append(next)
	var candidates: Array[Dictionary] = []
	var occupied: Dictionary = {}
	for job in world.jobs:
		if job.worker > 0: occupied[Vector2i(job.work_x,job.work_y)] = true
	var cart: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition == "supply_cart")[0]
	var seats: Dictionary = {}
	var cart_tiles: Array[Vector2i] = world.footprint(cart)
	for y in range(cart.y-3,cart.y+4):
		for x in range(cart.x-3,cart.x+4):
			var point: Vector2i = Vector2i(x,y)
			if absi(x-cart.x)+absi(y-cart.y) <= 3 and not cart_tiles.has(point): seats[point] = {"tier":3,"object":point.y*128+point.x}
	for structure in world.structures:
		if structure.definition not in ["garden_bench","table"]: continue
		for point in seats_for(world,structure):
			seats[point] = {"tier":1 if structure.definition == "garden_bench" else 2,"object":structure.id}
	for point in seats:
		if not distance.has(point) or occupied.has(point): continue
		var tier: int = seats[point].tier
		var object: int = seats[point].object
		var private_tier: int = 0
		var near_friend: bool = false
		for other in world.citizens:
			if other.id == citizen.id or other.departed or other.health == 0: continue
			var near: bool = absi(point.x-other.x)+absi(point.y-other.y) <= 2
			if near and citizen.traits.has("Private"): private_tier = 1
			var job: Dictionary = world.find(world.jobs,other.job)
			var pair: Dictionary = world.social_state.pairs[key(citizen.id,other.id)]
			if near and pair.score >= 40 and job.get("kind") == "leisure": near_friend = true
		if near_friend: tier = 0
		var warm: bool = false
		for hearth in world.structures:
			if hearth.definition == "hearth" and hearth.fuel > 0 and (absi(point.x-hearth.x)+absi(point.y-hearth.y) <= 3 or (world.roofed(point) and world.room_tiles.get(point) == world.room_tiles.get(Vector2i(hearth.x,hearth.y),-1))): warm = true
		candidates.append({"point":point,"rank":[private_tier,0 if world.comfortable(citizen) or warm else 1,tier,distance[point],object,point.y*128+point.x]})
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		for i in range(a.rank.size()):
			if a.rank[i] != b.rank[i]: return a.rank[i] < b.rank[i]
		return false)
	return start if candidates.is_empty() else candidates[0].point

static func advance(world: ColonyWorld) -> void:
	var day: int = world.tick / 7200
	var leisure: Array[Dictionary] = []
	for citizen in world.citizens:
		var job: Dictionary = world.find(world.jobs,citizen.job)
		if citizen.health > 0 and not citizen.departed and job.get("kind") == "leisure" and job.state == "Working": leisure.append(citizen)
	var chosen: Dictionary = {}
	var paired: Dictionary = {}
	for citizen in leisure:
		if paired.has(citizen.id): continue
		var partners: Array = leisure.filter(func(c:Dictionary)->bool:return c.id != citizen.id and not paired.has(c.id) and absi(c.x-citizen.x)+absi(c.y-citizen.y) <= 2)
		partners.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			var ad: int = absi(a.x-citizen.x)+absi(a.y-citizen.y)
			var bd: int = absi(b.x-citizen.x)+absi(b.y-citizen.y)
			return ad < bd or (ad == bd and a.id < b.id))
		if partners.is_empty(): continue
		paired[citizen.id] = true
		paired[partners[0].id] = true
		chosen[key(citizen.id,partners[0].id)] = true
	for pair in world.social_state.pairs.values():
		if chosen.has(key(pair.a,pair.b)) and pair.conversation_day != day:
			pair.conversation_ticks += 1
			if pair.conversation_ticks >= 150:
				var a: Dictionary = world.find(world.citizens,pair.a)
				var b: Dictionary = world.find(world.citizens,pair.b)
				var gain: int = (1 if a.traits.has("Private") or b.traits.has("Private") else 2)+(1 if a.traits.has("Sociable") else 0)+(1 if b.traits.has("Sociable") else 0)
				change(world,pair,gain)
				pair.conversation_day = day
				pair.conversation_ticks = 0
				if pair.score >= 40:
					a.friend_leisure_until = world.tick+7200
					b.friend_leisure_until = world.tick+7200
		elif not chosen.has(key(pair.a,pair.b)): pair.conversation_ticks = 0
		if world.tick-pair.last_interaction >= 57600 and world.tick-pair.last_decay >= 57600:
			pair.score -= signi(pair.score)
			pair.last_decay = world.tick
		_disagreement(world,pair)
	for citizen in world.citizens:
		if leisure.has(citizen):
			var alone: bool = not leisure.any(func(c:Dictionary)->bool:return c.id != citizen.id and absi(c.x-citizen.x)+absi(c.y-citizen.y) <= 2)
			if alone and citizen.traits.has("Private"):
				citizen.private_leisure_ticks += 1
				if citizen.private_leisure_ticks >= 150 and citizen.private_leisure_day != day:
					citizen.friend_leisure_until = world.tick+7200
					citizen.private_leisure_day = day
			else: citizen.private_leisure_ticks = 0
			var table: int = table_at(world,Vector2i(citizen.x,citizen.y))
			if table > 0 and leisure.filter(func(c:Dictionary)->bool:return table_at(world,Vector2i(c.x,c.y)) == table).size() >= 3:
				citizen.supper_ticks += 1
				if citizen.supper_ticks == 150: world.social_state.supper_history[citizen.id] = world.tick
			else: citizen.supper_ticks = 0
		else:
			citizen.private_leisure_ticks = 0
			citizen.supper_ticks = 0
	for request in world.social_state.requests:
		if request.state == "Accepted":
			if fulfilled(world,request): _resolve(world,request,true)
			elif world.tick >= request.deadline: _resolve(world,request,false)
	if world.tick % 7200 == 2400 and (day+1)%4 == 0:
		for request in world.social_state.requests:
			if request.state == "Offered": request.state = "Declined"
		if not world.social_state.requests.any(func(r:Dictionary)->bool:return r.state == "Accepted"): _offer(world)

static func table_at(world: ColonyWorld, point: Vector2i) -> int:
	for structure in world.structures:
		if structure.definition == "table" and seats_for(world,structure).has(point): return structure.id
	return 0

static func seats_for(world: ColonyWorld, structure: Dictionary) -> Array[Vector2i]:
	var points: Array[Vector2i] = [Vector2i(0,-1),Vector2i(0,1)]
	if structure.definition == "table": points.append_array([Vector2i(1,-1),Vector2i(1,1)])
	var definition: Dictionary = world.definitions.buildings[structure.definition]
	var result: Array[Vector2i] = []
	for point in points:
		match structure.rotation:
			1: point = Vector2i(-point.y,point.x)+Vector2i(definition.height-1,0)
			2: point = -point+Vector2i(definition.width-1,definition.height-1)
			3: point = Vector2i(point.y,-point.x)+Vector2i(0,definition.width-1)
		result.append(point+Vector2i(structure.x,structure.y))
	return result

static func _disagreement(world: ColonyWorld, pair: Dictionary) -> void:
	if pair.score > -40:
		pair.conflict_clock = 0
		return
	var a: Dictionary = world.find(world.citizens,pair.a)
	var b: Dictionary = world.find(world.citizens,pair.b)
	var aj: Dictionary = world.find(world.jobs,a.job)
	var bj: Dictionary = world.find(world.jobs,b.job)
	var at: Vector2i = Vector2i(a.x,a.y)
	var bt: Vector2i = Vector2i(b.x,b.y)
	if pair.score <= -40 and a.health > 0 and b.health > 0 and aj.get("state") == "Working" and bj.get("state") == "Working" and aj.kind not in ["leisure","eat","sleep"] and bj.kind not in ["leisure","eat","sleep"] and world.roofed(at) and world.roofed(bt) and world.room_tiles[at] == world.room_tiles[bt]:
		pair.conflict_clock += 1
		if pair.conflict_clock >= 1200 and world.tick >= pair.conflict_cooldown:
			change(world,pair,-3)
			pair.conflict_clock = 0
			pair.conflict_until = world.tick+14400
			pair.conflict_cooldown = world.tick+14400
			world.facts.append({"tick":world.tick,"actor":pair.a,"job":0,"kind":"disagreement","text":a.name+" and "+b.name+" disagree after sharing work in a room. Separate their work or mediate."})
	else: pair.conflict_clock = 0

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	if kind == "mediate":
		var pair: Dictionary = world.social_state.pairs.get(args.definition,{})
		if pair.is_empty() or pair.conflict_until <= world.tick: return "No active disagreement"
		if world.jobs.any(func(j:Dictionary)->bool:return j.kind == "mediate" and j.definition == args.definition and j.state not in ["Complete","Canceled"]): return "Already ordered"
		var person: Dictionary = world.find(world.citizens,pair.a)
		var job: Dictionary = world._job("mediate","Care","Care",person.id,Vector2i(person.x,person.y),12000)
		job.definition = args.definition
	else:
		var request: Dictionary = world.find(world.social_state.requests,args.target)
		if request.is_empty() or request.state != "Offered": return "This request is no longer offered"
		if kind == "request_decline": request.state = "Declined"
		else:
			request.state = "Accepted"
			request.accepted_at = world.tick
			request.deadline = world.tick+28800
			if fulfilled(world,request): _resolve(world,request,true)
	return "accepted"

static func complete_mediation(world: ColonyWorld, job: Dictionary) -> bool:
	var pair: Dictionary = world.social_state.pairs[job.definition]
	var a: Dictionary = world.find(world.citizens,pair.a)
	var b: Dictionary = world.find(world.citizens,pair.b)
	if absi(a.x-b.x)+absi(a.y-b.y) > 3: return false
	change(world,pair,8)
	pair.conflict_until = 0
	return true

static func shared_building(world: ColonyWorld, job: Dictionary) -> void:
	var workers: Array = job.worker_days.keys().filter(func(id:int)->bool:return job.worker_days[id] == world.tick / 7200)
	workers.sort()
	for i in range(workers.size()):
		for j in range(i+1,workers.size()):
			var pair: Dictionary = world.social_state.pairs[key(workers[i],workers[j])]
			if pair.work_day != world.tick / 7200:
				change(world,pair,1)
				pair.work_day = world.tick / 7200

static func rescue(world: ColonyWorld, rescuer: int, patient: int, incident: int) -> void:
	var pair: Dictionary = world.social_state.pairs[key(rescuer,patient)]
	if pair.rescued.has(str(incident)): return
	pair.rescued.append(str(incident))
	change(world,pair,25 if world.find(world.citizens,rescuer).traits.has("Kind") else 20)

static func _eligible(citizen: Dictionary, kind: String) -> bool:
	return {"quiet_bed":citizen.traits.has("Private") or citizen.traits.has("Homebody"),"garden_seat":citizen.traits.has("Outdoorsy") or citizen.preferred in ["Growing","Gathering","Animals"],"supper":citizen.traits.has("Sociable") or citizen.traits.has("Kind"),"learn":citizen.traits.has("Curious") or citizen.preferred == "Research","tool":citizen.preferred in ["Crafting","Building"],"valley":citizen.traits.has("Restless") or citizen.preferred == "Gathering"}[kind]

static func _offer(world: ColonyWorld) -> void:
	var people: Array = world.citizens.filter(func(c:Dictionary)->bool:return c.health > 0 and not c.departed and REQUESTS.any(func(kind:String)->bool:return _eligible(c,kind)))
	people.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.last_request_offer < b.last_request_offer or (a.last_request_offer == b.last_request_offer and a.id < b.id))
	if people.is_empty(): return
	var person: Dictionary = people[0]
	var choices: Array[Dictionary] = []
	for offset in range(REQUESTS.size()):
		var index: int = (person.request_cycle+offset)%REQUESTS.size()
		var kind: String = REQUESTS[index]
		if not _eligible(person,kind): continue
		var request: Dictionary = {"id":0,"actor":person.id,"kind":kind,"state":"Offered","offered_at":world.tick,"accepted_at":0,"deadline":0,"study_xp":person.xp.Study,"trip_count":person.successful_trips,"supper_before":world.social_state.supper_history.get(person.id,0)}
		choices.append(request)
	var choice: Dictionary = choices[0]
	for candidate in choices:
		if not fulfilled(world,candidate):
			choice = candidate
			break
	choice.id = world._id()
	person.last_request_offer = world.tick
	person.request_cycle = (REQUESTS.find(choice.kind)+1)%REQUESTS.size()
	world.social_state.requests.append(choice)
	world.facts.append({"tick":world.tick,"actor":person.id,"job":0,"kind":"request_offered","text":person.name+" requests "+TITLES[choice.kind]+". Optional; accepting gives four days."})

static func fulfilled(world: ColonyWorld, request: Dictionary) -> bool:
	var person: Dictionary = world.find(world.citizens,request.actor)
	match request.kind:
		"quiet_bed":
			var bed: Dictionary = world.find(world.structures,person.bed)
			if bed.get("definition") != "bed" or not world.roofed(Vector2i(bed.x,bed.y)): return false
			var room: int = world.room_tiles[Vector2i(bed.x,bed.y)]
			return world.structures.filter(func(s:Dictionary)->bool:return s.definition in ["bed","bedroll"] and world.room_tiles.get(Vector2i(s.x,s.y),-1) == room).size() <= 2
		"garden_seat":
			for bench in world.structures:
				if bench.definition == "garden_bench" and world.fields.filter(func(f:Dictionary)->bool:return f.planted and absi(f.x-bench.x)+absi(f.y-bench.y) <= 3).size() >= 4: return true
		"supper": return world.social_state.supper_history.get(person.id,0) > request.supper_before or person.supper_ticks >= 150
		"learn": return person.xp.Study-request.study_xp >= 60000
		"tool": return person.equipment.toolkit == "forged_toolkit"
		"valley": return person.successful_trips > request.trip_count
	return false

static func _resolve(world: ColonyWorld, request: Dictionary, success: bool) -> void:
	request.state = "Fulfilled" if success else "Failed"
	var person: Dictionary = world.find(world.citizens,request.actor)
	if success: person.fulfilled_request_until = world.tick+14400
	else: person.broken_promise_until = world.tick+14400
	world.facts.append({"tick":world.tick,"actor":person.id,"job":0,"kind":"request_fulfilled" if success else "request_failed","text":person.name+": "+TITLES[request.kind]+(" fulfilled." if success else " promise expired. Improve conditions; the mood penalty lasts two days.")})

static func mood_terms(world: ColonyWorld, citizen: Dictionary) -> Dictionary:
	var terms: Dictionary = {}
	if citizen.friend_leisure_until > world.tick: terms["Quiet leisure" if citizen.traits.has("Private") else "Shared leisure with friend"] = 40
	if citizen.fulfilled_request_until > world.tick: terms["Fulfilled personal request"] = 100
	if citizen.broken_promise_until > world.tick or world.social_state.pairs.values().any(func(p:Dictionary)->bool:return citizen.id in [p.a,p.b] and p.conflict_until > world.tick): terms["Conflict or broken promise"] = -60
	return terms

static func validate(data: Variant, citizens: Array, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["pairs","requests","supper_history","deaths"]) or not data.pairs is Dictionary or not data.requests is Array or data.requests.size() > 10000 or not data.supper_history is Dictionary or not data.deaths is Array: return false
	var expected: Dictionary = initial_state(citizens,tick).pairs
	if not ColonyCodec._keys(data.pairs,expected.keys()): return false
	for name in data.pairs:
		var pair: Variant = data.pairs[name]
		if not ColonyCodec._record(pair,expected[name]) or pair.a != expected[name].a or pair.b != expected[name].b or pair.score < -100 or pair.score > 100 or pair.conversation_ticks < 0 or pair.conversation_ticks >= 150 or pair.conflict_clock < 0 or not pair.rescued.all(func(id:Variant)->bool:return id is String and id.is_valid_int()): return false
		if pair.last_interaction < 0 or pair.last_interaction > tick or pair.last_decay < 0 or pair.last_decay > tick or pair.conflict_until < 0 or pair.conflict_until > tick+14400 or pair.conflict_cooldown < 0 or pair.conflict_cooldown > tick+14400: return false
	for actor in data.supper_history:
		if not actor is int or not citizens.any(func(c:Dictionary)->bool:return c.id == actor) or not data.supper_history[actor] is int or data.supper_history[actor] < 0 or data.supper_history[actor] > tick: return false
	var active: int = 0
	for request in data.requests:
		var fields: Array = ["id","actor","kind","state","offered_at","accepted_at","deadline","study_xp","trip_count","supper_before"]
		if not request is Dictionary or not ColonyCodec._keys(request,fields) or request.kind not in REQUESTS or request.state not in ["Offered","Accepted","Declined","Fulfilled","Failed"]: return false
		for field in fields:
			if field not in ["kind","state"] and (not request[field] is int or request[field] < 0): return false
		if not citizens.any(func(c:Dictionary)->bool:return c.id == request.actor) or request.offered_at > tick or request.accepted_at > tick or request.deadline > tick+28800: return false
		if request.state in ["Offered","Declined"] and (request.accepted_at != 0 or request.deadline != 0): return false
		if request.state in ["Accepted","Fulfilled","Failed"] and (request.accepted_at < request.offered_at or request.deadline != request.accepted_at+28800): return false
		if request.state in ["Offered","Accepted"]: active += 1
	var seen: Dictionary = {}
	for death in data.deaths:
		if not death is Dictionary or not ColonyCodec._keys(death,["actor","tick","name","citizen","relationships"]) or not death.actor is int or not death.tick is int or death.tick < 1800 or death.tick > tick or not death.name is String or death.name.length() > 64 or not death.citizen is Dictionary or not death.relationships is Dictionary or seen.has(death.actor): return false
		var person: Dictionary = {}
		for c in citizens:
			if c.id == death.actor: person = c; break
		if person.is_empty() or not person.death_recorded or not ColonyCodec._record(death.citizen,person): return false
		for id in death.relationships:
			if not id is int or id == death.actor or not citizens.any(func(c:Dictionary)->bool:return c.id == id) or not death.relationships[id] is int or death.relationships[id] < -100 or death.relationships[id] > 100: return false
		seen[death.actor] = true
	return active <= 1
