class_name ColonyCharter
extends RefCounted
## Ordered, permanent charter snapshots and physical communal supper attendance.
const STAGES: Array[String] = ["shelter", "provision", "connection", "refuge", "charter"]
const TITLES: Dictionary = {"shelter":"A place to stay", "provision":"A place that lasts", "connection":"A place on the road", "refuge":"A place for others", "charter":"Brackenward restored"}
const REWARDS: Dictionary = {"shelter":100, "provision":100, "connection":200, "refuge":200, "charter":0}
const ACTIVE: Array[String] = ["Scheduled", "Active"]

static func initial_state(tick: int = 1800) -> Dictionary:
	return {"completed":[], "snapshots":{}, "winter_day":tick/7200, "winter_observed":0, "winter_failed":false, "winter_completed_at":0, "supper":{}, "last_supper":0, "supper_memories":{}, "ceremony":{}, "ending":false, "continued":false, "appearances":[]}

static func living(world: ColonyWorld, home: bool = false) -> Array:
	return world.citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed and (not home or not c.away))

static func _healthy(citizen: Dictionary) -> bool:
	return citizen.health>=60 and not citizen.downed

static func _fact(world: ColonyWorld, kind: String, text: String, job: int = 0) -> int:
	var cart: Dictionary = ColonyTrade.cart(world)
	var details: Dictionary = {"location":[cart.x,cart.y]}
	var link: String = ""
	if kind.begins_with("supper_"):
		link="supper:"+str(job)
		details.causes=ColonyChronicle.causes(world,link)
		if kind=="supper_complete":
			details.participants=world.charter_state.supper.attended.duplicate()
			details.changes={"meal":-world.charter_state.supper.eaten.size()}
			details.salience=60
	elif kind in ["charter_ceremony","charter_interrupted"]:
		link="ceremony:"+str(world.charter_state.ceremony.start)
		details.causes=ColonyChronicle.causes(world,link)
	elif kind=="charter_stage":
		var stage: String = world.charter_state.completed[-1]
		link="charter:"+stage
		if stage=="charter": details.causes=ColonyChronicle.causes(world,"ceremony:"+str(world.charter_state.ceremony.start))
	elif kind=="charter_complete":
		details.causes=ColonyChronicle.causes(world,"charter:charter")
	var id: int = world.emit_fact({"tick":world.tick, "actor":0, "job":job, "kind":kind, "text":text},details)
	if not link.is_empty(): ColonyChronicle.remember(world,link,id)
	if kind=="supper_complete": ColonyChronicle.remember(world,"supper",id)
	return id

static func snapshot(world: ColonyWorld) -> Dictionary:
	var residents: Array = living(world)
	var beds: int = 0
	var morale: int = 0
	for person in residents:
		morale += person.morale
		var bed: Dictionary = world.find(world.structures,person.bed)
		if not bed.is_empty() and bed.definition=="bed" and bed.health>0 and bed.user==person.id and world.footprint(bed).all(func(p:Vector2i)->bool:return world.roofed(p)): beds += 1
	var returned: int = 0
	for definition in ColonyRegion.SITES:
		if world.region_state.progress[definition].returned_at>0: returned += 1
	var restored: bool = world.region_state.trips.any(func(t:Dictionary)->bool:return t.args.definition=="broken_causeway" and not t.args.pickup and t.reward_committed and t.quote.shortfall<=2)
	return {"tick":world.tick, "residents":residents.size(), "beds":beds,
		"tables":world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition=="table").size(),
		"hearths":world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition=="hearth" and s.cooking and not ColonyFire.burning(world,"structure",s.id)).size(),
		"runway":FoodForecast.calculate(world).ticks,
		"planted":world.fields.filter(func(f:Dictionary)->bool:return f.planted).size(),
		"granaries":world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition in ["granary","cellar"]).size(),
		"winter":world.charter_state.winter_completed_at>0, "storecraft":world.researched.has("storecraft"), "farming":world.researched.has("farming"),
		"returned":returned, "causeway":restored, "friendly":world.trade_state.reputation.values().filter(func(n:int)->bool:return n>=40).size(),
		"commonlife":world.researched.has("commonlife"), "supper":world.charter_state.last_supper>0, "valley_charter":world.researched.has("valley_charter"),
		"beacons":world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition=="beacon").size(), "day":world.tick/7200+1, "morale":0 if residents.is_empty() else morale/residents.size()}

static func conditions(stage: String, s: Dictionary) -> Array[Dictionary]:
	match stage:
		"shelter": return [_condition("Four living residents",s.residents>=4), _condition("Four assigned beds in roofed rooms",s.beds>=4), _condition("One table",s.tables>=1), _condition("One active hearth",s.hearths>=1), _condition("Two days of edible food runway",s.runway>=14400)]
		"provision": return [_condition("A granary or cellar",s.granaries>=1), _condition("Twenty-four planted field tiles",s.planted>=24), _condition("One entire Winter day without zero fullness",s.winter), _condition("Storecraft and Farming researched",s.storecraft and s.farming)]
		"connection": return [_condition("Returned from two different expedition sites",s.returned>=2), _condition("Restored Broken causeway or Friendly with two communities",s.causeway or s.friendly>=2)]
		"refuge": return [_condition("Eight living residents",s.residents>=8), _condition("Eight roofed assigned beds",s.beds>=8), _condition("Commonlife researched",s.commonlife), _condition("Completed a communal supper",s.supper)]
		"charter": return [_condition("Valley charter researched",s.valley_charter), _condition("A completed beacon",s.beacons>=1), _condition("Eight living residents",s.residents>=8), _condition("Day thirty-three or later",s.day>=33), _condition("Three days of edible food runway",s.runway>=21600), _condition("Average morale at least 550",s.morale>=550)]
	return []

static func _condition(text: String, met: bool) -> Dictionary:
	return {"text":text, "met":met}

static func checklist(world: ColonyWorld) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var current: Dictionary = snapshot(world)
	for stage in STAGES:
		var complete: bool = world.charter_state.completed.has(stage)
		result.append({"id":stage, "title":TITLES[stage], "complete":complete, "conditions":conditions(stage,world.charter_state.snapshots.get(stage,current)), "reward":REWARDS[stage]})
	return result

static func seats(world: ColonyWorld) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var used: Dictionary = {}
	var tables: Array = world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition=="table" and not ColonyFire.burning(world,"structure",s.id))
	tables.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.id<b.id)
	for table in tables:
		for point in ColonySocial.seats_for(world,table):
			if used.has(point) or not world.walkable(point) or not world.accessible(point) or not ColonyDanger.safe(world,point): continue
			used[point]=true
			result.append({"table":table.id, "x":point.x, "y":point.y, "actor":0, "job":0})
	return result

static func supper_error(world: ColonyWorld) -> String:
	if not world.researched.has("commonlife"): return "Research Commonlife before holding a communal supper"
	if world.charter_state.supper.get("state","") in ACTIVE: return "A communal supper is already scheduled or underway"
	if world.charter_state.last_supper>0 and world.tick<world.charter_state.last_supper+57600: return "The next communal supper is available eight days after the last completed supper"
	var home: Array = living(world,true)
	if home.filter(_healthy).size()<8: return "Supper needs eight home residents with at least 60 health and none downed; expedition residents do not count"
	if seats(world).size()<4: return "Build a table with four safe, reachable seats"
	if world.available("meal")<home.size()*2: return "Supper reserves two meals per home resident: %d meals needed" % (home.size()*2)
	return ""

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	match kind:
		"start_supper":
			var error: String = supper_error(world)
			if not error.is_empty(): return error
			var point: Dictionary = ColonyTrade.cart(world)
			var bank: Dictionary = world._job("supper_reserve","","",point.id,Vector2i(point.x,point.y),0)
			var needed: int = living(world,true).size()*2
			var sources: Array = world.stacks.filter(func(s:Dictionary)->bool:return s.item=="meal" and s.location in ["ground","store","output"] and s.count>world._reserved(s) and ColonyFire.usable(world,s) and world.accessible(Vector2i(s.x,s.y)))
			sources.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return ColonyProduction.input_before(world,a,b,Vector2i(point.x,point.y)))
			for stack in sources:
				var count: int = mini(needed,stack.count-world._reserved(stack))
				if count>0: stack.reservations[bank.id]=count; needed-=count
				if needed==0: break
			if needed>0:
				world._release(bank,true)
				return "Supper reservation changed: restore accessible meals and try again"
			var start: int = (world.tick/7200)*7200+5400
			if world.tick%7200>=5400: start+=7200
			var eligible: Array = living(world,true).map(func(c:Dictionary)->int:return c.id)
			eligible.sort()
			world.charter_state.supper={"job":bank.id,"state":"Scheduled","start":start,"end":start+600,"eligible":eligible,"attended":[],"eaten":[],"slots":seats(world).slice(0,eligible.size()),"reason":"Meals remain physically reserved until each attendee collects one", "completed_at":0}
			_fact(world,"supper_scheduled","Communal supper scheduled for 18:00–20:00. %d meals reserved; eight residents must eat and sit for half an hour." % (eligible.size()*2),bank.id)
		"cancel_supper":
			if world.charter_state.supper.get("state","") not in ACTIVE: return "No active communal supper to cancel"
			_end_supper(world,"Canceled","Canceled by the player")
		"start_ceremony":
			var error: String = ceremony_error(world)
			if not error.is_empty(): return error
			world.charter_state.ceremony={"state":"Active","start":world.tick,"end":world.tick+600,"snapshot":snapshot(world),"reason":"Two-hour charter ceremony; an arriving hostile party cancels it without cost"}
			_fact(world,"charter_ceremony","The two-hour charter ceremony began with its food, population and morale conditions recorded.")
		"cancel_ceremony":
			if world.charter_state.ceremony.get("state","")!="Active": return "No charter ceremony is underway"
			world.charter_state.ceremony.state="Canceled";world.charter_state.ceremony.reason="Canceled by the player; no consumables used"
		"continue_settlement":
			if not world.charter_state.ending: return "The charter is not yet complete"
			world.charter_state.continued=true
		"charter_appearance":
			if args.definition not in STAGES.slice(0,4) or not world.charter_state.completed.has(args.definition): return "This charter appearance has not been earned"
			world.charter_state.appearances.erase(args.definition)
			if args.enabled: world.charter_state.appearances.append(args.definition)
		_: return "Unknown charter command"
	return "accepted"

static func ceremony_error(world: ColonyWorld) -> String:
	if world.charter_state.ending: return "The charter is already complete; continue the settlement"
	if world.charter_state.ceremony.get("state","")=="Active": return "The charter ceremony is already underway"
	if world.charter_state.completed.size()<4: return "Complete Shelter, Provision, Connection and Refuge first"
	for condition in conditions("charter",snapshot(world)):
		if not condition.met: return condition.text
	if world.defense_state.raids.any(func(r:Dictionary)->bool:return r.arrival>0 and r.state in ["Active","Grace","Payment","Retreating"]): return "Wait for the hostile party to leave before starting the ceremony"
	return ""

static func _can_attend(world: ColonyWorld, citizen: Dictionary) -> bool:
	if citizen.away or citizen.death_recorded or citizen.departed or citizen.downed or citizen.fullness==0 or citizen.rest<=100 or citizen.break_until>world.tick or citizen.get("drafted",false): return false
	if not ColonyDanger.safe(world,Vector2i(citizen.x,citizen.y)): return false
	if world.jobs.any(func(j:Dictionary)->bool:return j.state not in ["Complete","Canceled"] and ((j.emergency and j.worker in [0,citizen.id]) or (j.kind=="treat" and j.target==citizen.id))): return false
	return true

static func assign(world: ColonyWorld, citizen: Dictionary) -> bool:
	var supper: Dictionary = world.charter_state.supper
	if supper.get("state","") in ACTIVE and citizen.fullness==0:
		var held_job: Dictionary = world.find(world.jobs,citizen.job)
		if held_job.get("kind")=="supper": world._release(held_job,false)
		if held_job.get("kind")!="eat" and world._food(citizen).is_empty():
			for stack in world.stacks:
				if stack.reservations.get(supper.job,0)>0 and ColonyFire.usable(world,stack):
					stack.reservations[supper.job]-=1
					if stack.reservations[supper.job]==0: stack.reservations.erase(supper.job)
					supper.reason="Life-critical hunger takes a meal from the supper buffer; attendance still requires eight meals and seats before 20:00"
					break
	if supper.get("state","")!="Active" or world.tick>=supper.end or not supper.eligible.has(citizen.id) or supper.attended.has(citizen.id): return false
	var current: Dictionary = world.find(world.jobs,citizen.job)
	if not _can_attend(world,citizen):
		if current.get("kind")=="supper": world._release(current,false)
		return false
	if current.get("kind")=="supper": return true
	var prior: Dictionary = {}
	for slot in supper.slots:
		if slot.actor==citizen.id: prior=world.find(world.jobs,slot.job)
	if not prior.is_empty() and prior.state not in ["Complete","Canceled"]:
		if world.tick<prior.retry: return false
		world._release(current,false)
		prior.worker=citizen.id;citizen.job=prior.id
		prior.state="Moving" if prior.amount==1 else "Fetching"
		return true
	world._release(current,false)
	var vacant: Dictionary = {}
	for slot in supper.slots:
		if slot.actor!=0 or not _seat_valid(world,slot): continue
		var point: Vector2i = Vector2i(slot.x,slot.y)
		if world.jobs.any(func(j:Dictionary)->bool:return j.worker>0 and j.work_x==point.x and j.work_y==point.y and j.worker!=citizen.id): continue
		vacant=slot;break
	if vacant.is_empty():
		citizen.activity="Waiting for a communal supper seat"
		return true
	var job: Dictionary = world._job("supper","","",citizen.id,Vector2i(vacant.x,vacant.y),2000)
	job.order=supper.job;job.worker=citizen.id;job.state="Fetching";job.memo={"table":vacant.table};job.inputs={"meal":1}
	if supper.eaten.has(citizen.id): job.amount=1;job.required=15000;job.inputs={};job.state="Moving"
	citizen.job=job.id;vacant.actor=citizen.id;vacant.job=job.id
	return true

static func _seat_valid(world: ColonyWorld, slot: Dictionary) -> bool:
	var table: Dictionary = world.find(world.structures,slot.table)
	var point: Vector2i = Vector2i(slot.x,slot.y)
	return not table.is_empty() and table.health>0 and table.definition=="table" and ColonySocial.seats_for(world,table).has(point) and world.walkable(point) and ColonyDanger.safe(world,point)

static func work(world: ColonyWorld, citizen: Dictionary, job: Dictionary) -> void:
	var supper: Dictionary = world.charter_state.supper
	if supper.get("state","")!="Active" or job.order!=supper.job or world.tick>=supper.end:
		world._release(job,true);return
	var slot: Dictionary = {"table":job.memo.table,"x":job.work_x,"y":job.work_y}
	if not _seat_valid(world,slot):
		world._release(job,false);world._block(job,"Supper seat lost or unsafe: restore the table and route before 20:00");return
	var carried: Dictionary = {}
	for stack in world.stacks:
		if stack.count>0 and ((stack.location=="carry" and stack.job==job.id) or (stack.location=="escrow" and stack.owner==job.id)): carried=stack;break
	match job.state:
		"Fetching":
			citizen.activity="Collecting a reserved supper meal"
			if not carried.is_empty(): job.state="Delivering";return
			var source: Dictionary = {}
			for stack in world.stacks:
				if stack.count>0 and stack.reservations.get(job.id,0)>0: source=stack;break
			if source.is_empty():
				for stack in world.stacks:
					if stack.count>0 and stack.reservations.get(supper.job,0)>0 and ColonyFire.usable(world,stack): source=stack;break
				if not source.is_empty():
					source.reservations[supper.job]-=1
					if source.reservations[supper.job]==0: source.reservations.erase(supper.job)
					source.reservations[job.id]=1
			if source.is_empty():
				world._release(job,false);world._block(job,"Reserved supper meals were lost or spoiled; remaining attendees cannot eat");return
			if world._walk(citizen,Vector2i(source.x,source.y)):
				var meal: Dictionary = world._make_stack("meal",1,"carry",citizen.id,Vector2i(citizen.x,citizen.y),false)
				meal.age=source.age;meal.age_rem=source.age_rem;meal.tags=source.tags.duplicate();meal.job=job.id
				source.count-=1;source.reservations.erase(job.id);job.state="Delivering"
		"Delivering":
			citizen.activity="Carrying supper to the table"
			if carried.is_empty(): job.state="Fetching";return
			if world._walk(citizen,Vector2i(job.work_x,job.work_y)):
				carried.location="escrow";carried.owner=job.id;carried.x=job.work_x;carried.y=job.work_y;job.state="Working"
		"Moving":
			citizen.activity="Returning to the communal supper"
			if world._walk(citizen,Vector2i(job.work_x,job.work_y)): job.state="Working"
		"Working":
			citizen.activity="Eating communal supper" if job.amount==0 else "Sitting at communal supper"
			if job.amount==0 and carried.is_empty(): job.state="Fetching";job.work=0;return
			job.work=mini(job.required,job.work+100)
			if job.amount==1: citizen.leisure_ticks+=1

static func _end_supper(world: ColonyWorld, state: String, reason: String) -> void:
	var supper: Dictionary = world.charter_state.supper
	supper.state=state
	supper.reason="%s: %d of eight required residents ate and sat for half an hour; %d meals eaten stay consumed. Unused reservations are released." % [reason,supper.attended.size(),supper.eaten.size()]
	for job in world.jobs:
		if (job.id==supper.job or (job.kind=="supper" and job.order==supper.job)) and job.state not in ["Complete","Canceled"]: world._release(job,true)
	for slot in supper.slots: slot.actor=0;slot.job=0
	if state=="Complete":
		supper.completed_at=world.tick;world.charter_state.last_supper=world.tick
		for id in supper.attended: world.charter_state.supper_memories[id]=world.tick+14400
		_fact(world,"supper_complete","The residents shared a communal supper: %d ate and stayed together for half an hour. The shared memory lasts two days." % supper.attended.size(),supper.job)
	else: _fact(world,"supper_shortfall",supper.reason,supper.job)

static func begin_tick(world: ColonyWorld) -> void:
	var supper: Dictionary = world.charter_state.supper
	if supper.get("state","")=="Scheduled" and world.tick>=supper.start:
		supper.state="Active"
		for id in supper.eligible:
			var person: Dictionary = world.find(world.citizens,id)
			if not person.is_empty() and _can_attend(world,person): world._release(world.find(world.jobs,person.job),false)

static func advance(world: ColonyWorld) -> void:
	var state: Dictionary = world.charter_state
	var day: int = world.tick/7200
	if state.winter_day!=day:
		if state.winter_day%32>=24 and state.winter_observed==7200 and not state.winter_failed and state.winter_completed_at==0: state.winter_completed_at=world.tick
		state.winter_day=day;state.winter_observed=0;state.winter_failed=false
	state.winter_observed=mini(7200,state.winter_observed+1)
	var residents: Array = living(world)
	if residents.is_empty() or residents.any(func(c:Dictionary)->bool:return c.fullness==0): state.winter_failed=true
	var supper: Dictionary = state.supper
	if supper.get("state","") in ACTIVE and world.find(world.jobs,supper.job).get("state")=="Canceled": _end_supper(world,"Canceled","Supper reservation canceled")
	begin_tick(world)
	if supper.get("state","")=="Active":
		for slot in supper.slots:
			if slot.actor==0: continue
			var person: Dictionary = world.find(world.citizens,slot.actor)
			var job: Dictionary = world.find(world.jobs,slot.job)
			if person.is_empty() or person.away or person.death_recorded or person.departed or job.is_empty() or job.state=="Canceled":
				if not job.is_empty() and job.state not in ["Complete","Canceled"]: world._release(job,true)
				slot.actor=0;slot.job=0;continue
			if world.tick>=supper.end or job.worker==0 or person.job!=job.id or person.downed or job.state!="Working" or job.work<job.required: continue
			if job.amount==0:
				var meal: Dictionary = {}
				for stack in world.stacks:
					if stack.location=="escrow" and stack.owner==job.id and stack.item=="meal" and stack.count==1: meal=stack;break
				if meal.is_empty(): job.state="Fetching";job.work=0;continue
				world._record("consumed","meal",1);meal.count=0;person.fullness=mini(1000,person.fullness+500);person.starving_ticks=0
				for tag in meal.tags:
					if not person.food_tags.has(tag): person.food_tags.append(tag)
				if not supper.eaten.has(person.id): supper.eaten.append(person.id)
				job.amount=1;job.work=0;job.required=15000;job.inputs={}
			else:
				if not supper.attended.has(person.id): supper.attended.append(person.id)
				world._complete(person,job);slot.actor=0;slot.job=0
		if supper.attended.size()>=8: _end_supper(world,"Complete","Supper completed")
		elif world.tick>=supper.end: _end_supper(world,"Failed","Evening window ended")
	if world.tick%10==0 and state.completed.size()<4:
		var current: Dictionary = snapshot(world)
		while state.completed.size()<4:
			var stage: String = STAGES[state.completed.size()]
			if not conditions(stage,current).all(func(c:Dictionary)->bool:return c.met): break
			_complete_stage(world,stage,current)
	var ceremony: Dictionary = state.ceremony
	if ceremony.get("state","")=="Active":
		if world.defense_state.raids.any(func(r:Dictionary)->bool:return r.arrival>0 and r.arrival>=ceremony.start):
			ceremony.state="Canceled";ceremony.reason="Hostile arrival interrupted the ceremony; restart when the party has left, with no consumables lost"
			_fact(world,"charter_interrupted",ceremony.reason)
		elif world.tick>=ceremony.end:
			ceremony.state="Complete";_complete_stage(world,"charter",ceremony.snapshot);state.ending=true
			_fact(world,"charter_complete","Brackenward is restored. Four travelers made a place to stay; the shelter weathered Winter, opened its roads, and welcomed others to its table. The beacon now watches over a living settlement. Its story can continue.")

static func _complete_stage(world: ColonyWorld, stage: String, evidence: Dictionary) -> void:
	if world.charter_state.completed.has(stage): return
	world.charter_state.completed.append(stage);world.charter_state.snapshots[stage]=evidence.duplicate(true)
	ColonyProduction.add_insight(world,REWARDS[stage])
	_fact(world,"charter_stage",TITLES[stage]+" recorded permanently. "+("%d insight earned." % REWARDS[stage] if REWARDS[stage]>0 else "The charter is complete."))

static func mood_terms(world: ColonyWorld, citizen: Dictionary) -> Dictionary:
	return {"Communal supper":60} if world.charter_state.supper_memories.get(citizen.id,0)>world.tick else {}

static func supper_status(world: ColonyWorld) -> Dictionary:
	var supper: Dictionary = world.charter_state.supper
	if supper.is_empty(): return {"state":"None","reason":supper_error(world),"attended":0,"traveling":[],"waiting":[]}
	var traveling: Array = []
	var waiting: Array = []
	for id in supper.eligible:
		if supper.attended.has(id): continue
		var person: Dictionary = world.find(world.citizens,id)
		if person.is_empty(): continue
		var job: Dictionary = world.find(world.jobs,person.job)
		if job.get("kind")=="supper" and job.state!="Working": traveling.append(person.name)
		else: waiting.append(person.name)
	return {"state":supper.state,"reason":supper.reason,"attended":supper.attended.size(),"traveling":traveling,"waiting":waiting}

static func _integer(value: Variant, low: int = 0, high: int = 9007199254740991) -> bool:
	return value is int and value>=low and value<=high

static func _unique_ids(value: Variant, citizens: Array) -> bool:
	if not value is Array or value.size()>20: return false
	var seen: Array = []
	for id in value:
		if not id is int or seen.has(id) or not citizens.any(func(c:Dictionary)->bool:return c.id==id): return false
		seen.append(id)
	return true

static func _snapshot_valid(value: Variant, tick: int) -> bool:
	if not value is Dictionary or not ColonyCodec._keys(value,["tick","residents","beds","tables","hearths","runway","planted","granaries","winter","storecraft","farming","returned","causeway","friendly","commonlife","supper","valley_charter","beacons","day","morale"]): return false
	for key in ["winter","storecraft","farming","causeway","commonlife","supper","valley_charter"]:
		if not value[key] is bool: return false
	for key in ["tick","residents","beds","tables","hearths","runway","planted","granaries","returned","friendly","beacons","day","morale"]:
		if not _integer(value[key]): return false
	return value.tick<=tick and value.residents<=20 and value.beds<=20 and value.returned<=8 and value.friendly<=3 and value.day==value.tick/7200+1 and value.morale<=1000

static func valid(data: Dictionary, _definitions: Dictionary, tick: int, next_id: int) -> bool:
	var value: Variant = data.get("charter_state")
	if not value is Dictionary or not ColonyCodec._keys(value,["completed","snapshots","winter_day","winter_observed","winter_failed","winter_completed_at","supper","last_supper","supper_memories","ceremony","ending","continued","appearances"]): return false
	if not value.completed is Array or value.completed.size()>5 or value.completed!=STAGES.slice(0,value.completed.size()) or not value.snapshots is Dictionary or value.snapshots.size()!=value.completed.size(): return false
	for stage in value.completed:
		if not value.snapshots.has(stage) or not _snapshot_valid(value.snapshots[stage],tick) or not conditions(stage,value.snapshots[stage]).all(func(c:Dictionary)->bool:return c.met): return false
	if not _integer(value.winter_day,0,tick/7200) or not _integer(value.winter_observed,0,7200) or not value.winter_failed is bool or not _integer(value.winter_completed_at,0,tick) or not _integer(value.last_supper,0,tick): return false
	if not value.ending is bool or value.ending!=value.completed.has("charter") or not value.continued is bool or (value.continued and not value.ending): return false
	if not value.appearances is Array or value.appearances.size()>4 or not value.appearances.all(func(s:Variant)->bool:return s is String and s in STAGES.slice(0,4) and value.completed.has(s)): return false
	var distinct: Array = []
	for appearance in value.appearances:
		if distinct.has(appearance): return false
		distinct.append(appearance)
	if not value.supper_memories is Dictionary or value.supper_memories.size()>20: return false
	for id in value.supper_memories:
		if not id is int or not data.citizens.any(func(c:Dictionary)->bool:return c.id==id) or not _integer(value.supper_memories[id],0,tick+14400): return false
	var supper: Variant = value.supper
	if not supper is Dictionary: return false
	if not supper.is_empty():
		if not ColonyCodec._keys(supper,["job","state","start","end","eligible","attended","eaten","slots","reason","completed_at"]) or not _integer(supper.job,1,next_id-1) or not data.jobs.any(func(j:Dictionary)->bool:return j.id==supper.job and j.kind=="supper_reserve") or supper.state not in ["Scheduled","Active","Complete","Failed","Canceled"] or not supper.reason is String or supper.reason.length()>2000: return false
		if not _integer(supper.start,0,tick+7200) or supper.start%7200!=5400 or not _integer(supper.end) or supper.end!=supper.start+600 or not _integer(supper.completed_at,0,tick): return false
		for field in ["eligible","attended","eaten"]:
			if not _unique_ids(supper[field],data.citizens): return false
		if supper.eligible.size()<8 or not supper.eaten.all(func(id:int)->bool:return supper.eligible.has(id)) or not supper.attended.all(func(id:int)->bool:return supper.eaten.has(id)): return false
		if supper.state=="Complete" and (supper.attended.size()<8 or supper.completed_at==0 or value.last_supper!=supper.completed_at): return false
		if supper.state!="Complete" and supper.completed_at!=0: return false
		if supper.state=="Scheduled" and tick>=supper.start: return false
		if supper.state=="Active" and (tick<supper.start or tick>=supper.end): return false
		if not supper.slots is Array or supper.slots.size()<4 or supper.slots.size()>20: return false
		var points: Array = [];var actors: Array = []
		for slot in supper.slots:
			if not slot is Dictionary or not ColonyCodec._keys(slot,["table","x","y","actor","job"]) or not _integer(slot.table,1,next_id-1) or not _integer(slot.x,0,127) or not _integer(slot.y,0,127) or not _integer(slot.actor,0,next_id-1) or not _integer(slot.job,0,next_id-1): return false
			var point: Vector2i = Vector2i(slot.x,slot.y)
			if points.has(point): return false
			points.append(point)
			if slot.actor==0:
				if slot.job!=0: return false
			else:
				if supper.state not in ACTIVE or actors.has(slot.actor) or not supper.eligible.has(slot.actor) or supper.attended.has(slot.actor) or not data.jobs.any(func(j:Dictionary)->bool:return j.id==slot.job and j.kind=="supper" and j.target==slot.actor and j.order==supper.job and j.state not in ["Complete","Canceled"] and j.work_x==slot.x and j.work_y==slot.y): return false
				actors.append(slot.actor)
	var ceremony: Variant = value.ceremony
	if not ceremony is Dictionary: return false
	if not ceremony.is_empty():
		if not ColonyCodec._keys(ceremony,["state","start","end","snapshot","reason"]) or ceremony.state not in ["Active","Canceled","Complete"] or not _integer(ceremony.start,0,tick) or not _integer(ceremony.end) or ceremony.end!=ceremony.start+600 or not ceremony.reason is String or ceremony.reason.length()>2000 or not _snapshot_valid(ceremony.snapshot,tick) or ceremony.snapshot.tick!=ceremony.start or not conditions("charter",ceremony.snapshot).all(func(c:Dictionary)->bool:return c.met): return false
		if value.completed.size()<4 or (ceremony.state=="Active" and tick>=ceremony.end) or (ceremony.state=="Complete" and not value.ending): return false
	return true

static func valid_job(data: Dictionary, job: Dictionary) -> bool:
	if job.kind=="supper_reserve":
		if job.worker!=0 or job.required!=0 or not job.inputs.is_empty() or not job.memo.is_empty(): return false
		var reserved: int = 0
		for stack in data.stacks:
			if stack.reservations.get(job.id,0)>0:
				if stack.item!="meal" or stack.location not in ["ground","store","output"]: return false
				reserved+=stack.reservations[job.id]
		if job.state in ["Complete","Canceled"]: return reserved==0
		return data.charter_state.supper.get("job",0)==job.id and reserved<=data.charter_state.supper.eligible.size()*2
	if job.kind!="supper": return true
	if not ColonyCodec._keys(job.memo,["table"]) or not _integer(job.memo.table,1,data.next_id-1) or job.amount not in [0,1] or job.required!=(2000 if job.amount==0 else 15000) or job.inputs!=({"meal":1} if job.amount==0 else {}) or not data.citizens.any(func(c:Dictionary)->bool:return c.id==job.target) or not data.jobs.any(func(j:Dictionary)->bool:return j.id==job.order and j.kind=="supper_reserve"): return false
	var held: int = 0
	for stack in data.stacks:
		var reserved: int = stack.reservations.get(job.id,0)
		var owned: int = stack.count if (stack.location=="carry" and stack.job==job.id) or (stack.location=="escrow" and stack.owner==job.id) else 0
		if reserved+owned>0 and stack.item!="meal": return false
		held+=reserved+owned
	if held>(1 if job.amount==0 and job.state not in ["Complete","Canceled"] else 0): return false
	if job.state in ["Complete","Canceled"]: return true
	var supper: Dictionary = data.charter_state.supper
	return supper.get("job",0)==job.order and supper.get("state","") in ACTIVE and supper.slots.any(func(s:Dictionary)->bool:return s.job==job.id and s.actor==job.target and s.table==job.memo.table) and (job.worker==0 or job.worker==job.target)
