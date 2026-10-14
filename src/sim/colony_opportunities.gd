class_name ColonyOpportunities
extends RefCounted
## Optional, physical visitor transactions. Every deadline and cooldown is game time.
const KINDS: Array = ["traveling_storyteller","stranded_carrier","surplus_harvest","shared_observation"]
const ACTIVE: Array = ["Offered","Accepted","Hosted"]
const ENDED: Array = ["Complete","Declined","Expired","Failed"]
const OFFER_TICKS: int = 14400
const REPEAT_TICKS: int = 57600
const HOST_TICKS: int = 1800

static func initial_state(seed: int, version: int, site: String) -> Dictionary:
	return {"rng":ParkMiller.derive(seed,version,site,"minor_incidents"),"offers":[],"visitors":[],"after":{"traveling_storyteller":0,"stranded_carrier":0,"surplus_harvest":0,"shared_observation":0}}

static func friend_pair(world: ColonyWorld) -> Array:
	var home: Array = ColonyRegion.home(world).map(func(c:Dictionary)->int:return c.id)
	var pairs: Array = world.social_state.pairs.values().filter(func(p:Dictionary)->bool:return p.score>=40 and home.has(p.a) and home.has(p.b))
	pairs.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.a<b.a if a.a!=b.a else a.b<b.b)
	return [] if pairs.is_empty() else [pairs[0].a,pairs[0].b]

static func visitor_count(world: ColonyWorld) -> int:
	# Reserve capacity for hostile actors becoming stable neutral visitors when downed.
	var count: int = world.trade_state.merchants.filter(func(m:Dictionary)->bool:return m.state not in ["Waiting","Gone"]).size()
	count+=world.defense_state.enemies.filter(func(e:Dictionary)->bool:return e.state!="Gone").size()
	return count+world.opportunity_state.visitors.filter(func(v:Dictionary)->bool:return v.state not in ["Waiting","Gone"]).size()

static func critical(world: ColonyWorld) -> bool:
	if ColonyRegion.critical(world): return true
	if world.defense_state.raids.any(func(r:Dictionary)->bool:return not r.acknowledged and r.arrival>0): return true
	return world.citizens.any(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed and c.departure_until>0)

static func eligible(world: ColonyWorld, kind: String) -> bool:
	match kind:
		"traveling_storyteller": return world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="table")
		"stranded_carrier": return world.trade_state.reputation.road_fellowship>=0
		"surplus_harvest": return world.trade_state.reputation.orchard_kin>=20 and not world.trade_state.merchants.any(func(m:Dictionary)->bool:return m.state not in ["Waiting","Gone"])
		"shared_observation": return not friend_pair(world).is_empty() and world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="research_desk")
	return false

static func offer(world: ColonyWorld, kind: String) -> Dictionary:
	var state: Dictionary = world.opportunity_state
	if not KINDS.has(kind) or not eligible(world,kind) or critical(world) or world.tick<state.after[kind]: return {}
	if state.offers.any(func(e:Dictionary)->bool:return e.state in ACTIVE or e.created/7200==world.tick/7200): return {}
	var visitor: Dictionary = {"id":world._id(),"offer":0,"state":"Waiting","x":0,"y":0,"entry":Vector2i.ZERO,"route":[],"goal":[],"progress":0,"move_rem":0,"note":"Waiting for a safe boundary and visitor capacity"}
	var record: Dictionary = {"id":world._id(),"definition":kind,"state":"Offered","created":world.tick,"deadline":world.tick+OFFER_TICKS,"visitor":visitor.id,"station":0,"jobs":[],"people":friend_pair(world) if kind=="shared_observation" else [],"completed":[],"host_until":0,"attendance":{},"receipt":0,"reason":"Declining or expiry has no reputation penalty; only genuinely consumed supplies are lost"}
	visitor.offer=record.id;state.visitors.append(visitor);state.offers.append(record);state.after[kind]=world.tick+REPEAT_TICKS
	_enter(world,visitor)
	ColonyTrade.fact(world,"minor_offer",kind.capitalize()+" offer waits two days. "+record.reason+".")
	return record

static func _enter(world: ColonyWorld, visitor: Dictionary) -> void:
	if visitor_count(world)>=8: visitor.note="Eight visiting humans: waiting for someone to leave";return
	var entries: Array = ColonyPopulation.boundary(world)
	if entries.is_empty(): visitor.note="Route blocked: clear a safe boundary route";return
	var rng: ParkMiller = ParkMiller.new(world.opportunity_state.rng)
	visitor.entry=entries[rng.next()%entries.size()];world.opportunity_state.rng=rng.state
	visitor.x=visitor.entry.x;visitor.y=visitor.entry.y;visitor.state="Entering";visitor.note="Walking to the supply cart"

static func _leave(visitor: Dictionary) -> void:
	if visitor.is_empty() or visitor.state in ["Leaving","Gone"]: return
	if visitor.state=="Waiting": visitor.state="Gone";return
	visitor.state="Leaving";visitor.note="Returning to the boundary"
	# Preserve an in-progress movement edge. Repath only at its next tile.
	visitor.goal.clear()
	if visitor.progress==0: visitor.route.clear()

static func advance(world: ColonyWorld) -> void:
	var state: Dictionary = world.opportunity_state
	for event in state.offers:
		if event.state in ["Offered","Accepted"] or (event.state=="Hosted" and event.host_until==0):
			if world.tick>=event.deadline: cancel(world,event,"Expired" if event.state=="Offered" else "Failed")
	for visitor in state.visitors:
		if visitor.state=="Gone": continue
		var event: Dictionary = world.find(state.offers,visitor.offer)
		if event.state in ENDED: _leave(visitor)
		if visitor.state=="Waiting": _enter(world,visitor)
		if visitor.state=="Entering" or (visitor.state=="At cart" and event.state!="Hosted"):
			var wagon: Dictionary = ColonyTrade.cart(world)
			if ColonyTrade.move(world,visitor,Vector2i(wagon.x,wagon.y)): visitor.state="At cart";visitor.note="Ready for the accepted task"
		elif visitor.state=="Leaving" and ColonyTrade.move(world,visitor,visitor.entry): visitor.state="Gone"
	for event in state.offers:
		if event.state=="Hosted": _host(world,event)
	var day: int = world.tick/7200+1
	if world.tick%7200!=2400 or day<4 or day%2!=0 or critical(world): return
	if state.offers.any(func(e:Dictionary)->bool:return e.state in ACTIVE or e.created/7200==world.tick/7200): return
	var options: Array = KINDS.filter(func(kind:String)->bool:return world.tick>=state.after[kind] and eligible(world,kind))
	if options.is_empty(): return
	var rng: ParkMiller = ParkMiller.new(state.rng);var kind: String = options[rng.next()%options.size()];state.rng=rng.state
	offer(world,kind)

static func _positions(world: ColonyWorld, station: Dictionary, origin: Vector2i) -> Array:
	var points: Array = world._perimeter(world.footprint(station)).filter(func(p:Vector2i)->bool:return world.walkable(p) and world.accessible(p) and ColonyDanger.safe(world,p))
	points.sort_custom(func(a:Vector2i,b:Vector2i)->bool:
		var ad: int = absi(a.x-origin.x)+absi(a.y-origin.y);var bd: int = absi(b.x-origin.x)+absi(b.y-origin.y)
		return ad<bd if ad!=bd else a.y*128+a.x<b.y*128+b.x)
	return points

static func _station(world: ColonyWorld, definition: String) -> Dictionary:
	var wagon: Dictionary = ColonyTrade.cart(world)
	var candidates: Array = world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition==definition)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ad: int = absi(a.x-wagon.x)+absi(a.y-wagon.y);var bd: int = absi(b.x-wagon.x)+absi(b.y-wagon.y)
		return ad<bd if ad!=bd else a.id<b.id)
	for station in candidates:
		if not _positions(world,station,Vector2i(wagon.x,wagon.y)).is_empty(): return station
	return {}

static func command(world: ColonyWorld, args: Dictionary) -> String:
	if not args.get("target") is int or not args.get("accept") is bool: return "Choose a valid offer and acceptance"
	var event: Dictionary = world.find(world.opportunity_state.offers,args.target)
	if event.is_empty() or event.state!="Offered": return "Offer is no longer waiting"
	if world.tick>=event.deadline: cancel(world,event,"Expired");return "Offer deadline passed"
	if not args.accept: cancel(world,event,"Declined");return "accepted"
	if not eligible(world,event.definition): return "Prerequisite changed: check table, friend pair, desk or reputation"
	var wagon: Dictionary = ColonyTrade.cart(world);var point: Vector2i = Vector2i(wagon.x,wagon.y)
	var station: Dictionary = {}
	if event.definition in ["shared_observation","traveling_storyteller"]:
		station=_station(world,"research_desk" if event.definition=="shared_observation" else "table")
		if station.is_empty(): return "Route blocked: provide a reachable safe desk or table"
	var data: Dictionary = world.definitions.events[event.definition]
	var payment: Dictionary = ColonyTrade.reservation_plan(world,data.payment,point)
	if not payment.error.is_empty(): return "Payment not accessible or already reserved: "+payment.error
	var count: int = 2 if event.definition=="shared_observation" else 1
	if world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.state not in ["Complete","Canceled"]).size()+count>512: return "Job limit: finish or cancel existing work first"
	event.station=station.get("id",0)
	if event.definition=="shared_observation":
		event.people=friend_pair(world)
		for id in event.people:
			var job: Dictionary = world._job("minor_study","Research","Study",event.id,point,20000)
			job.order=id;job.definition=event.definition;job.memo={"station":event.station};event.jobs.append(job.id)
	else:
		var job: Dictionary = world._job("minor_work","Building" if event.definition=="stranded_carrier" else "Hauling","Build" if event.definition=="stranded_carrier" else "",event.id,point,data.work_milli)
		job.definition=event.definition;job.inputs=data.payment.duplicate()
		for request in payment.requests: world.find(world.stacks,request.stack).reservations[job.id]=request.count
		event.jobs.append(job.id)
	event.state="Accepted";event.reason="Payment reserved; work waits for the visitor. Deadline unchanged; failure has no reputation penalty"
	ColonyTrade.fact(world,"minor_accepted",event.definition.capitalize()+" accepted. "+event.reason+".")
	return "accepted"

static func cancel(world: ColonyWorld, event: Dictionary, outcome: String) -> void:
	if event.is_empty() or event.state not in ACTIVE or outcome not in ["Declined","Expired","Failed"]: return
	event.state=outcome
	for id in event.jobs:
		var job: Dictionary = world.find(world.jobs,id)
		if not job.is_empty() and job.state not in ["Complete","Canceled"]: world._release(job,true)
	event.reason="Opportunity ended; unconsumed supplies returned. No reputation penalty"
	_leave(world.find(world.opportunity_state.visitors,event.visitor))
	ColonyTrade.fact(world,"minor_ended",event.definition.capitalize()+": "+outcome.to_lower()+". "+event.reason+".")

static func released(world: ColonyWorld, job: Dictionary, canceled: bool) -> void:
	if canceled and job.kind in ["minor_work","minor_study"]:
		cancel(world,world.find(world.opportunity_state.offers,job.target),"Failed")

static func ready_complete(world: ColonyWorld, job: Dictionary) -> bool:
	var event: Dictionary = world.find(world.opportunity_state.offers,job.target)
	if event.is_empty() or event.state!="Accepted" or not event.jobs.has(job.id): return world._block(job,"Opportunity is no longer accepted")
	if world.tick>=event.deadline: return world._block(job,"Offer deadline passed")
	var visitor: Dictionary = world.find(world.opportunity_state.visitors,event.visitor)
	var wagon: Dictionary = ColonyTrade.cart(world);var point: Vector2i = Vector2i(wagon.x,wagon.y)
	if visitor.state!="At cart" or visitor.progress!=0 or Vector2i(visitor.x,visitor.y)!=point: return world._block(job,"Visitor is still walking to the cart")
	if event.definition in ["traveling_storyteller","shared_observation"]:
		var station: Dictionary = world.find(world.structures,event.station)
		if station.is_empty() or station.health<=0: return world._block(job,"Required table or research desk was removed: restore it before the deadline")
		if _positions(world,station,point).is_empty(): return world._block(job,"Route blocked: clear the table or desk approach")
	if job.kind=="minor_study":
		var person: Dictionary = world.find(world.citizens,job.order)
		if not ColonyRegion.home(world).has(person) or person.downed: return world._block(job,"The named friend must be home and able to study")
		if job.worker>0 and job.worker!=job.order: return world._block(job,"This observation requires the named friend")
		if job.worker>0 and not world._perimeter(world.footprint(world.find(world.structures,event.station))).has(Vector2i(job.work_x,job.work_y)): return world._block(job,"Research desk moved: walk to its new position")
	else:
		for stack in world.stacks:
			if stack.location=="escrow" and stack.owner==job.id and Vector2i(stack.x,stack.y)!=point:
				stack.location="ground";stack.owner=0;stack.job=0;stack.reservations[job.id]=stack.count
		job.x=point.x;job.y=point.y
		if job.worker>0 and Vector2i(job.work_x,job.work_y)!=point: return world._block(job,"Cart moved: carry payment to its new position")
	return true

static func reserve(world: ColonyWorld, job: Dictionary, person: Dictionary) -> bool:
	if job.kind=="minor_study" and job.order!=person.id: return false
	if not ready_complete(world,job): return false
	if job.kind=="minor_study":
		var event: Dictionary = world.find(world.opportunity_state.offers,job.target)
		for other in world.jobs:
			if other.id!=job.id and other.worker>0 and ((other.kind=="minor_study" and other.memo.get("station")==event.station) or (other.kind=="research" and other.target==event.station)): return world._block(job,"Research desk in use: waiting for the other scholar")
		var positions: Array = _positions(world,world.find(world.structures,event.station),Vector2i(person.x,person.y))
		positions=positions.filter(func(p:Vector2i)->bool:return not world.jobs.any(func(j:Dictionary)->bool:return j.id!=job.id and j.worker>0 and j.work_x==p.x and j.work_y==p.y))
		if positions.is_empty(): return world._block(job,"No free work position at the research desk")
		job.x=positions[0].x;job.y=positions[0].y
	return true

static func finished_work(world: ColonyWorld, job: Dictionary) -> void:
	var event: Dictionary = world.find(world.opportunity_state.offers,job.target)
	if event.is_empty() or event.state!="Accepted" or not event.jobs.has(job.id) or job.work<job.required: return
	if job.kind=="minor_study":
		if job.worker!=job.order or event.completed.has(job.order): return
		event.completed.append(job.order)
		if event.completed.size()==2: complete(world,event)
	else:
		if event.completed.has(job.id): return
		event.completed.append(job.id)
		if event.definition=="traveling_storyteller":
			event.state="Hosted";event.reason="Two delivered meals consumed; visitor walks to the table for six hours of stories"
		else: complete(world,event)

static func _host(world: ColonyWorld, event: Dictionary) -> void:
	var visitor: Dictionary = world.find(world.opportunity_state.visitors,event.visitor)
	var table: Dictionary = world.find(world.structures,event.station)
	if table.is_empty() or table.health<=0: cancel(world,event,"Failed");return
	var positions: Array = _positions(world,table,Vector2i(visitor.x,visitor.y))
	if positions.is_empty():
		event.attendance.clear()
		if event.host_until>0 and world.tick>=event.host_until: complete(world,event)
		return
	var arrived: bool = ColonyTrade.move(world,visitor,positions[0])
	if arrived:
		visitor.state="Hosting";visitor.note="Telling stories at the table"
		if event.host_until==0: event.host_until=world.tick+HOST_TICKS
	var home: Array = ColonyRegion.home(world)
	for id in event.attendance:
		if event.attendance[id]<150 and not home.any(func(c:Dictionary)->bool:return c.id==id): event.attendance[id]=0
	for person in home:
		var task: Dictionary = world.find(world.jobs,person.job)
		var sharing: bool = arrived and task.get("kind")=="leisure" and task.get("state")=="Working" and ColonySocial.table_at(world,Vector2i(person.x,person.y))==table.id and absi(person.x-visitor.x)+absi(person.y-visitor.y)<=2
		var attendance: int = event.attendance.get(person.id,0)
		if attendance==150: continue
		event.attendance[person.id]=attendance+1 if sharing else 0
		if event.attendance[person.id]==150:
			person.story_memory_until=world.tick+7200
			var memory: int = world.emit_fact({"tick":world.tick,"actor":person.id,"job":0,"kind":"story_leisure","text":person.name+" shared half an hour of stories at the table; morale target +40 for one day."})
			ColonyChronicle.remember(world,"story:"+str(person.id),memory)
	if event.host_until>0 and world.tick>=event.host_until: complete(world,event)

static func complete(world: ColonyWorld, event: Dictionary) -> void:
	if event.is_empty() or event.receipt>0 or event.state not in ["Accepted","Hosted"]: return
	if event.definition=="traveling_storyteller":
		if event.state!="Hosted" or event.host_until==0 or world.tick<event.host_until: return
	elif event.completed.size()!=(2 if event.definition=="shared_observation" else 1): return
	var data: Dictionary = world.definitions.events[event.definition];var wagon: Dictionary = ColonyTrade.cart(world)
	for item in data.rewards:
		world._make_stack(item,data.rewards[item],"ground",0,Vector2i(wagon.x,wagon.y),false);world._record("traded_in",item,data.rewards[item])
	if data.insight>0: ColonyProduction.add_insight(world,data.insight)
	for community in data.reputation: world.trade_state.reputation[community]=mini(100,world.trade_state.reputation[community]+data.reputation[community])
	event.state="Complete";event.receipt=event.id;event.reason="Completed once; receipt "+str(event.id)
	_leave(world.find(world.opportunity_state.visitors,event.visitor))
	ColonyTrade.fact(world,"minor_complete",event.definition.capitalize()+" completed; "+str(data.rewards)+", insight "+str(data.insight)+", relations "+str(data.reputation)+".")

static func _ids(value: Variant) -> bool:
	if not value is Array: return false
	var seen: Dictionary = {}
	for id in value:
		if not id is int or id<=0 or seen.has(id): return false
		seen[id]=true
	return true

static func validate(data: Variant, citizens: Array, definitions: Dictionary, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["rng","offers","visitors","after"]) or not data.rng is int or data.rng<=0 or data.rng>=2147483647 or not data.offers is Array or not data.visitors is Array or data.offers.size()>10000 or data.visitors.size()!=data.offers.size() or not data.after is Dictionary or not ColonyCodec._keys(data.after,KINDS): return false
	for value in data.after.values():
		if not value is int or value<0 or value>tick+REPEAT_TICKS: return false
	var ids: Dictionary = {};var days: Dictionary = {};var active: int = 0;var present: int = 0
	var expected_after: Dictionary = initial_state(0,0,"").after
	for event in data.offers:
		if not event is Dictionary or not ColonyCodec._keys(event,["id","definition","state","created","deadline","visitor","station","jobs","people","completed","host_until","attendance","receipt","reason"]): return false
		if not event.id is int or event.id<=0 or ids.has(event.id) or event.definition not in KINDS or not definitions.events.has(event.definition) or event.state not in ACTIVE+ENDED: return false
		ids[event.id]=true
		if not event.created is int or event.created<1800 or event.created>tick or not event.deadline is int or event.deadline!=event.created+OFFER_TICKS or days.has(event.created/7200) or event.created<expected_after[event.definition]: return false
		days[event.created/7200]=true;expected_after[event.definition]=event.created+REPEAT_TICKS
		if not event.visitor is int or event.visitor<=0 or not event.station is int or event.station<0 or not _ids(event.jobs) or not _ids(event.people) or not _ids(event.completed) or not event.host_until is int or event.host_until<0 or not event.attendance is Dictionary or not event.receipt is int or event.receipt not in [0,event.id] or not event.reason is String or event.reason.length()>1024: return false
		if (event.state=="Complete")!=(event.receipt>0) or event.jobs.size()>(2 if event.definition=="shared_observation" else 1): return false
		if not event.people.all(func(id:int)->bool:return citizens.any(func(c:Dictionary)->bool:return c.id==id)): return false
		if event.definition=="shared_observation":
			if event.people.size()!=2 or not event.completed.all(func(id:int)->bool:return event.people.has(id)): return false
		elif not event.people.is_empty() or not event.completed.all(func(id:int)->bool:return event.jobs.has(id)): return false
		if event.state in ["Offered","Declined","Expired"] and (not event.jobs.is_empty() or not event.completed.is_empty() or event.station!=0): return false
		if event.state in ["Accepted","Hosted","Complete"] and event.jobs.size()!=(2 if event.definition=="shared_observation" else 1): return false
		if event.state in ["Accepted","Hosted","Complete"] and event.definition in ["shared_observation","traveling_storyteller"] and event.station==0: return false
		if event.state=="Complete" and event.completed.size()!=(2 if event.definition=="shared_observation" else 1): return false
		if event.state=="Hosted" and event.completed.size()!=1: return false
		if event.state=="Accepted" and event.completed.size()>=(2 if event.definition=="shared_observation" else 1): return false
		if event.definition not in ["traveling_storyteller","shared_observation"] and event.station!=0: return false
		if event.definition!="traveling_storyteller" and (event.host_until!=0 or not event.attendance.is_empty() or event.state=="Hosted"): return false
		if event.host_until>0 and (event.host_until<event.created+HOST_TICKS or event.host_until>event.deadline+HOST_TICKS or event.host_until>tick+HOST_TICKS or event.state not in ["Hosted","Complete","Failed"]): return false
		if event.definition=="traveling_storyteller" and event.state=="Complete" and (event.host_until==0 or event.host_until>tick): return false
		for id in event.attendance:
			if not id is int or not citizens.any(func(c:Dictionary)->bool:return c.id==id) or not event.attendance[id] is int or event.attendance[id]<0 or event.attendance[id]>150: return false
		if event.state in ACTIVE: active+=1
	if data.after!=expected_after or active>1: return false
	for visitor in data.visitors:
		if not visitor is Dictionary or not ColonyCodec._keys(visitor,["id","offer","state","x","y","entry","route","goal","progress","move_rem","note"]): return false
		if not visitor.id is int or visitor.id<=0 or ids.has(visitor.id) or not visitor.offer is int or visitor.state not in ["Waiting","Entering","At cart","Hosting","Leaving","Gone"] or not ColonyCodec._position(visitor) or not visitor.entry is Vector2i or not ColonyWorld.inside(visitor.entry) or (visitor.entry.x not in [0,127] and visitor.entry.y not in [0,127]): return false
		ids[visitor.id]=true
		var events: Array = data.offers.filter(func(e:Dictionary)->bool:return e.id==visitor.offer and e.visitor==visitor.id)
		if events.size()!=1 or (events[0].state in ENDED and visitor.state not in ["Leaving","Gone"]) or (events[0].state in ACTIVE and visitor.state in ["Leaving","Gone"]) or (visitor.state=="Hosting" and events[0].state!="Hosted"): return false
		if not visitor.route is Array or not visitor.route.all(func(p:Variant)->bool:return p is Vector2i and ColonyWorld.inside(p)) or not visitor.goal is Array or visitor.goal.size() not in [0,2] or not visitor.goal.all(func(n:Variant)->bool:return n is int and n>=0 and n<128) or not visitor.progress is int or visitor.progress<0 or visitor.progress>=10000 or not visitor.move_rem is int or visitor.move_rem<0 or visitor.move_rem>=120 or not visitor.note is String or visitor.note.length()>1024: return false
		if visitor.progress>0 and visitor.route.is_empty(): return false
		var previous: Vector2i = Vector2i(visitor.x,visitor.y)
		for point in visitor.route:
			if absi(point.x-previous.x)+absi(point.y-previous.y)!=1: return false
			previous=point
		if visitor.state not in ["Waiting","Gone"]: present+=1
	return present<=8

static func valid_job(data: Dictionary, job: Dictionary, definitions: Dictionary) -> bool:
	if job.kind not in ["minor_work","minor_study"]: return true
	var matches: Array = data.opportunity_state.offers.filter(func(e:Dictionary)->bool:return e.id==job.target and e.jobs.has(job.id))
	if matches.size()!=1: return false
	var event: Dictionary = matches[0];var definition: Dictionary = definitions.events[event.definition]
	if job.definition!=event.definition or not job.output.is_empty() or job.emergency or job.source!=0 or job.destination!=0: return false
	if job.kind=="minor_study":
		if event.definition!="shared_observation" or job.category!="Research" or job.skill!="Study" or job.required!=20000 or not event.people.has(job.order) or not job.inputs.is_empty() or job.memo!={"station":event.station} or (job.worker>0 and job.worker!=job.order): return false
		if (job.state=="Complete")!=event.completed.has(job.order): return false
	else:
		if event.definition=="shared_observation" or job.category!=("Building" if event.definition=="stranded_carrier" else "Hauling") or job.skill!=("Build" if event.definition=="stranded_carrier" else "") or job.required!=definition.work_milli or job.inputs!=definition.payment or job.order!=0 or not job.memo.is_empty(): return false
		if (job.state=="Complete")!=event.completed.has(job.id): return false
	if event.state in ENDED and job.state not in ["Complete","Canceled"]: return false
	if event.state=="Complete" and job.state!="Complete": return false
	if job.state=="Complete" and job.work!=job.required: return false
	return true
