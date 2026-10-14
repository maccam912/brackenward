class_name ColonyRegion
extends RefCounted
const HOME: Vector2i = Vector2i(4,4)
const SITES: Array = ["berry_hollow","old_quarry","lost_goats","wayhouse_archive","broken_causeway","raider_cache","seed_exchange","hill_observatory"]
const OFFSETS: Array = [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-2,1),Vector2i(2,-1),Vector2i(1,2),Vector2i(-1,-2)]
const SCENERY: Array = ["Pine ridge","Wet meadow","Old pasture","River bend","Stone rise","Quiet wood"]
const PRIORITY: Array = ["medicine","iron","cloth","herb","grain","stone","berry"]
const STATES: Array = ["Preparing","Ready","Walking out","Outbound","Decision","Site work","Collect","Returning","Walking in","Unloading","Done","Canceled"]

static func rotate(point: Vector2i, turns: int) -> Vector2i:
	for index in range(turns): point=Vector2i(-point.y,point.x)
	return point

static func initial_state(seed: int, version: int, site: String) -> Dictionary:
	var rng: ParkMiller = ParkMiller.new(ParkMiller.derive(seed,version,site,"region"))
	var turns: int = rng.next()%4;var assigned: Dictionary = {HOME:"home"};var nodes: Array = []
	for index in range(8): assigned[HOME+rotate(OFFSETS[index],turns)]=SITES[index]
	for index in range(3): assigned[HOME+rotate([Vector2i(-2,0),Vector2i(2,0),Vector2i(0,2)][index],turns)]=ColonyTrade.COMMUNITIES[index]
	var names: Array = SCENERY.duplicate()
	for index in range(5,0,-1):
		var other: int = rng.next()%(index+1);var name: String = names[index];names[index]=names[other];names[other]=name
	for y in range(9):
		for x in range(9):
			var definition: String = assigned.get(Vector2i(x,y),"transit")
			nodes.append({"x":x,"y":y,"definition":definition,"scenery":names[(y*9+x)%6]})
	var progress: Dictionary = {}
	for definition in SITES+ColonyTrade.COMMUNITIES: progress[definition]={"completed":false,"returned_at":0,"decision_after":0,"leftovers":{},"pickup_used":false}
	return {"rng":rng.state,"rotation":turns,"nodes":nodes,"progress":progress,"trips":[],"alert_serial":0}

static func route(world: ColonyWorld, definition: String) -> Array[Vector2i]:
	var targets: Array = world.region_state.nodes.filter(func(n:Dictionary)->bool:return n.definition==definition)
	if targets.size()!=1: return []
	var goal: Vector2i = Vector2i(targets[0].x,targets[0].y);var point: Vector2i = HOME;var result: Array[Vector2i] = [point]
	while point!=goal:
		for delta in ColonyNavigation.NEIGHBORS:
			if absi((point+delta).x-goal.x)+absi((point+delta).y-goal.y)<absi(point.x-goal.x)+absi(point.y-goal.y): point+=delta;result.append(point);break
	return result

static func home(world: ColonyWorld) -> Array:
	return world.citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed and not c.away)

static func active(world: ColonyWorld) -> Dictionary:
	for trip in world.region_state.trips:
		if trip.state not in ["Done","Canceled"]: return trip
	return {}

static func critical(world: ColonyWorld) -> bool:
	return world.region_state.trips.any(func(t:Dictionary)->bool:return t.state in ["Decision","Collect"])

static func definition_data(world: ColonyWorld, definition: String, pickup: bool) -> Dictionary:
	if pickup: return {"skill":"Field","challenge":0,"site_hours":0,"payment":{},"rewards":world.region_state.progress[definition].leftovers.duplicate(),"insight":0,"reputation":{},"cooldown_days":0,"unlock":"initial"}
	if ColonyTrade.COMMUNITIES.has(definition): return {"skill":"Field","challenge":0,"site_hours":6,"payment":world.definitions.communities[definition].delivery.duplicate(),"rewards":{},"insight":0,"reputation":{definition:10},"cooldown_days":8,"unlock":"initial"}
	return world.definitions.expeditions.get(definition,{})

static func preview(world: ColonyWorld, args: Dictionary, departing: bool = false) -> Dictionary:
	if args.definition not in SITES+ColonyTrade.COMMUNITIES: return {"error":"Choose a regional destination"}
	if not departing and not active(world).is_empty(): return {"error":"One expedition at a time; finish or cancel the current trip"}
	var path: Array[Vector2i] = route(world,args.definition);var edges: int = path.size()-1
	if edges>4 or edges<1: return {"error":"Destination must be one to four edges from home"}
	if edges>1 and not world.researched.has("trailcraft"): return {"error":"Research Trailcraft for routes beyond adjacent tiles"}
	var data: Dictionary = definition_data(world,args.definition,args.pickup)
	if data.is_empty(): return {"error":"Unknown site"}
	var progress: Dictionary = world.region_state.progress[args.definition]
	if args.pickup:
		if progress.leftovers.is_empty() or progress.pickup_used: return {"error":"No unclaimed one-time pickup remains"}
	else:
		if data.unlock!="initial" and not world.researched.has(data.unlock): return {"error":"Requires "+data.unlock.capitalize()}
		if data.get("seasons",[0,1,2,3]).has((world.tick/57600)%4)==false: return {"error":"This site is unavailable in Winter"}
		if progress.completed and data.cooldown_days==0: return {"error":"This completed site is a landmark; only leftover pickup remains"}
		if progress.returned_at>0 and world.tick<progress.returned_at+data.cooldown_days*7200: return {"error":"Site cooldown: %.1f days remain" % ((progress.returned_at+data.cooldown_days*7200-world.tick)/7200.0)}
		if ColonyTrade.COMMUNITIES.has(args.definition) and (world.tick<world.trade_state.delivery_after[args.definition] or world.trade_state.exchanges.any(func(e:Dictionary)->bool:return e.community==args.definition and e.delivery and e.state=="Packing")): return {"error":"Community delivery already accepted or cooling down"}
	if not args.party is Array or args.party.size()<2 or args.party.size()>4 or not distinct(args.party): return {"error":"Select two to four distinct residents"}
	if home(world).size()-args.party.size()<2: return {"error":"Leave at least two living residents at home"}
	var party: Array = []
	for id in args.party:
		var person: Dictionary = world.find(world.citizens,id)
		if person.is_empty() or person.death_recorded or person.departed or person.away or person.downed or person.health<70 or person.fullness<500 or person.rest<500: return {"error":"Every traveler needs health 70, fullness 500 and rest 500"}
		party.append(person)
	if not args.goats is Array or args.goats.size()>2: return {"error":"Choose at most two adult pack goats"}
	var seen: Dictionary = {}
	for id in args.goats:
		var goat: Dictionary = world.find(world.domestic_state.animals,id)
		if seen.has(id) or goat.is_empty() or goat.definition!="pack_goat" or goat.away or goat.health<40 or goat.juvenile_until>world.tick: return {"error":"Choose distinct adult pack goats at home with at least 40 health"}
		seen[id]=true
	if args.feed not in ["grain","vegetable"] or not ColonyTrade.quantities(args.cargo,world.definitions.items.keys()): return {"error":"Choose grain/vegetable feed and positive cargo quantities"}
	if args.variant not in [0,1] or (args.variant==1 and (args.definition!="old_quarry" or args.pickup)): return {"error":"Unknown reward option"}
	var hours: int = edges*12+data.site_hours
	var rations: int = 2*party.size()*((hours+23)/24+1)
	var animal_reward: bool = data.get("animal_reward","")=="pack_goat"
	var feed: int = args.goats.size()*2*((hours+23)/24)+(2*((edges*6+23)/24) if animal_reward else 0)
	var inputs: Dictionary = args.cargo.duplicate()
	inputs.travel_ration=inputs.get("travel_ration",0)+rations
	if feed>0: inputs[args.feed]=inputs.get(args.feed,0)+feed
	for item in data.payment: inputs[item]=inputs.get(item,0)+data.payment[item]
	var capacity: int = 12*(party.size()+args.goats.size());var units: int = 0
	for count in inputs.values(): units+=count
	if units>capacity: return {"error":"Departure cargo %d exceeds %d units" % [units,capacity]}
	if animal_reward:
		var error: String = ColonyDomestic.acquire_error(world,"pack_goat",args.pen)
		if not error.is_empty(): return {"error":error}
	var skills: Array = party.map(func(c:Dictionary)->int:return c.skills[data.skill]);skills.sort();skills.reverse()
	var readiness: int = skills[0]+skills[1]+party.filter(func(c:Dictionary)->bool:return c.equipment.weapon in ["bow","spear"]).size()+(2 if inputs.get("medicine",0)>0 else 0)
	readiness=mini(15,readiness)
	var entries: Array = ColonyPopulation.boundary(world)
	if entries.is_empty(): return {"error":"Boundary route blocked: clear a safe departure and return route"}
	if not departing:
		var available: Dictionary = ColonyTrade.accessible_goods(world)
		for item in inputs:
			if inputs[item]>available.get(item,0): return {"error":"Need %d more accessible unreserved %s" % [inputs[item]-available.get(item,0),item]}
	var removal: Dictionary = {}
	if not departing:
		var wagon: Dictionary = ColonyTrade.cart(world)
		var planned: Dictionary = ColonyTrade.reservation_plan(world,inputs,Vector2i(wagon.x,wagon.y))
		for request in planned.get("requests",[]): removal[request.stack]=request.count
	var home_forecast: Dictionary = FoodForecast.calculate(world,home(world).size()-party.size(),removal)
	var rewards: Dictionary = data.get("reward_choices",[data.rewards])[args.variant].duplicate()
	var shortfall: int = maxi(0,data.challenge-readiness)
	for item in rewards: rewards[item]=0 if shortfall>2 else (rewards[item]*3/4 if shortfall>0 else rewards[item])
	for item in rewards.keys():
		if rewards[item]==0: rewards.erase(item)
	return {"error":"","route":path,"edges":edges,"hours":hours,"rations":rations,"feed":feed,"inputs":inputs,"capacity":capacity,"return_capacity":capacity+(12 if animal_reward and shortfall<=2 else 0),"readiness":readiness,"challenge":data.challenge,"shortfall":shortfall,"rewards":rewards,"insight":data.insight/2 if shortfall>2 else data.insight,"payment":data.payment.duplicate(),"reputation":{} if shortfall>2 else data.reputation.duplicate(),"home_forecast":home_forecast,"decision":-1 if args.pickup or ColonyTrade.COMMUNITIES.has(args.definition) else SITES.find(args.definition)%3}

static func cargo(world: ColonyWorld, trip: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for stack in world.stacks:
		if stack.location=="expedition_cargo" and stack.owner==trip.id and stack.count>0: result[stack.item]=result.get(stack.item,0)+stack.count
	return result

static func consume(world: ColonyWorld, trip: Dictionary, item: String, count: int, ledger: String = "consumed") -> void:
	for stack in world.stacks:
		if stack.location!="expedition_cargo" or stack.owner!=trip.id or stack.item!=item: continue
		var take: int = mini(count,stack.count);stack.count-=take;count-=take;world._record(ledger,item,take)
		if count==0: break

static func prepare(world: ColonyWorld, args: Dictionary) -> String:
	var quote: Dictionary = preview(world,args)
	if not quote.error.is_empty(): return quote.error
	var trip: Dictionary = {"id":world._id(),"args":args.duplicate(true),"state":"Preparing","quote":quote,"entry":Vector2i.ZERO,"remaining":0,"elapsed":0,"away_ticks":0,"fed_days":0,"eaten":0,"readiness":0,"decision":quote.decision,"decision_done":false,"decision_bonus":false,"reward_committed":false,"reward_animal":false,"reward_goat_fed":0,"pack_job":0,"note":"Packing real cargo and gathering the party at the cart"}
	world.region_state.trips.append(trip)
	var wagon: Dictionary = ColonyTrade.cart(world)
	var job: Dictionary = world._job("expedition_pack","Hauling","",trip.id,Vector2i(wagon.x,wagon.y),0)
	job.inputs=quote.inputs.duplicate();trip.pack_job=job.id
	if not ColonyTrade.reserve_payment(world,job): world._release(job,true);trip.state="Canceled";return "Cargo changed; refresh preview"
	for id in args.party:
		var person: Dictionary = world.find(world.citizens,id);world._release(world.find(world.jobs,person.job),false);person.expedition=trip.id
	for id in args.goats:
		var goat: Dictionary = world.find(world.domestic_state.animals,id)
		for old in world.jobs:
			if old.kind in ["lead_animal","collect_animal","slaughter"] and old.target==id and old.state not in ["Complete","Canceled"]: world._release(old,true)
		var lead: Dictionary = world._job("lead_animal","Animals","Field",id,Vector2i(goat.x,goat.y),0);lead.care_goal=[wagon.x,wagon.y];lead.order=trip.id
	var prepared: int = ColonyTrade.fact(world,"expedition_prepare",args.definition.capitalize()+": party and cargo are gathering at the cart; Depart is a separate action.",job.id,{"participants":args.party,"location":[wagon.x,wagon.y]})
	ColonyChronicle.remember(world,"trip:"+str(trip.id),prepared)
	return "accepted"

static func assign(world: ColonyWorld, person: Dictionary) -> bool:
	if person.expedition==0: return false
	var trip: Dictionary = world.find(world.region_state.trips,person.expedition)
	if trip.is_empty() or trip.state not in ["Preparing","Ready"]: return false
	var wagon: Dictionary = ColonyTrade.cart(world)
	if Vector2i(person.x,person.y)==Vector2i(wagon.x,wagon.y):
		person.activity="Preparing: needs food to reach fullness 500" if person.fullness<500 else "At the cart: waiting for Depart or Cancel"
		return true
	var job: Dictionary = world._job("expedition_meet","","",person.id,Vector2i(wagon.x,wagon.y),0)
	job.order=trip.id;job.worker=person.id;job.state="Moving";person.job=job.id
	return true

static func preparing(world: ColonyWorld, person: Dictionary) -> bool:
	return person.expedition>0 and world.find(world.region_state.trips,person.expedition).get("state") in ["Preparing","Ready"]

static func pack_complete(world: ColonyWorld, job: Dictionary) -> void:
	for stack in world.stacks:
		if stack.location=="escrow" and stack.owner==job.id: stack.location="expedition_cargo";stack.owner=job.target;stack.job=0

static func ready(world: ColonyWorld, trip: Dictionary) -> String:
	var quote: Dictionary = preview(world,trip.args,true)
	if not quote.error.is_empty(): return quote.error
	var wagon: Dictionary = ColonyTrade.cart(world);var point: Vector2i = Vector2i(wagon.x,wagon.y)
	var goods: Dictionary = cargo(world,trip)
	for item in trip.quote.inputs:
		if goods.get(item,0)<trip.quote.inputs[item]: return "Cargo not packed or spoiled: missing "+item
	for id in trip.args.party:
		var person: Dictionary = world.find(world.citizens,id)
		if Vector2i(person.x,person.y)!=point or person.progress>0 or person.job!=0: return "Party is still walking or meeting essential needs"
	for id in trip.args.goats:
		var goat: Dictionary = world.find(world.domestic_state.animals,id)
		if Vector2i(goat.x,goat.y)!=point or goat.handler>0: return "Pack goats are still being led to the cart"
	return ""

static func start_walk(world: ColonyWorld, trip: Dictionary, incoming: bool, from_boundary: bool = true) -> void:
	trip.state="Walking in" if incoming else "Walking out"
	for id in trip.args.party:
		var person: Dictionary = world.find(world.citizens,id);world._release(world.find(world.jobs,person.job),false)
		var goal: Vector2i = Vector2i(ColonyTrade.cart(world).x,ColonyTrade.cart(world).y) if incoming else trip.entry
		if incoming and from_boundary: person.x=trip.entry.x;person.y=trip.entry.y
		person.progress=0;person.route.clear();person.route_goal.clear()
		var job: Dictionary = world._job("expedition_walk","","",person.id,goal,0)
		job.order=trip.id;job.worker=person.id;job.state="Moving";person.job=job.id
	if incoming:
		var carriers: Array = trip.args.party.filter(func(id:int)->bool:return world.find(world.citizens,id).health>20)
		carriers.sort()
		for id in trip.args.party:
			var patient: Dictionary = world.find(world.citizens,id)
			if patient.health>20 or carriers.is_empty(): continue
			var carrier: Dictionary = world.find(world.citizens,carriers.pop_front())
			world._release(world.find(world.jobs,patient.job),true);patient.carried_by=carrier.id;carrier.carrying_patient=patient.id

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	if kind=="expedition_prepare": return prepare(world,args)
	var trip: Dictionary = world.find(world.region_state.trips,args.target)
	if trip.is_empty() or trip.state in ["Done","Canceled"]: return "Trip already ended"
	if kind=="expedition_cancel":
		if trip.state not in ["Preparing","Ready"]: return "Recall an expedition that has departed"
		cancel(world,trip);return "accepted"
	if kind=="expedition_depart":
		if trip.state not in ["Preparing","Ready"]: return "Trip already departed"
		var error: String = ready(world,trip)
		if not error.is_empty(): return error
		trip.quote=preview(world,trip.args,true);trip.readiness=trip.quote.readiness
		if trip.quote.shortfall>2 and not args.unprepared: return "Attempt unprepared needs explicit confirmation: no item reward, half insight, twenty health damage to two travelers"
		var entries: Array = ColonyPopulation.boundary(world);var rng: ParkMiller = ParkMiller.new(world.region_state.rng)
		trip.entry=entries[rng.next()%entries.size()];world.region_state.rng=rng.state
		for id in trip.args.party: world.find(world.citizens,id).away=true
		for id in trip.args.goats: world.find(world.domestic_state.animals,id).away=true
		start_walk(world,trip,false)
		var departed: int = ColonyTrade.fact(world,"expedition_depart",trip.args.definition.capitalize()+": departure readiness %d fixed against challenge %d; planned regional trip %d hours." % [trip.readiness,trip.quote.challenge,trip.quote.hours],0,{"participants":trip.args.party,"causes":ColonyChronicle.causes(world,"trip:"+str(trip.id))})
		ColonyChronicle.remember(world,"trip:"+str(trip.id),departed)
		return "accepted"
	if kind=="expedition_recall":
		if trip.state in ["Preparing","Ready"]: cancel(world,trip);return "accepted"
		if trip.state=="Walking out": start_walk(world,trip,true,false);return "accepted"
		if trip.state in ["Returning","Walking in","Unloading"]: return "Already returning"
		trip.remaining=trip.elapsed if trip.state in ["Outbound","Decision"] else trip.quote.edges*1800
		trip.state="Returning";trip.note="Recalled with unconsumed cargo; uncommitted site rewards remain unclaimed"
		if trip.remaining==0: start_walk(world,trip,true)
		return "accepted"
	if kind=="expedition_choice": return choice(world,trip,args.definition)
	if kind=="expedition_collect": return collect(world,trip,args.keep)
	return "Unknown expedition action"

static func cancel(world: ColonyWorld, trip: Dictionary) -> void:
	world._release(world.find(world.jobs,trip.pack_job),true)
	for job in world.jobs:
		if job.order==trip.id and job.kind in ["expedition_meet","lead_animal"] and job.state not in ["Complete","Canceled"]: world._release(job,true)
	for stack in world.stacks:
		if stack.location=="expedition_cargo" and stack.owner==trip.id: stack.location="ground";stack.owner=0;stack.job=0
	for id in trip.args.party: world.find(world.citizens,id).expedition=0
	trip.state="Canceled"

static func walk_work(world: ColonyWorld, person: Dictionary, job: Dictionary) -> void:
	var trip: Dictionary = world.find(world.region_state.trips,job.order)
	var goal: Vector2i = trip.entry if trip.state=="Walking out" else Vector2i(ColonyTrade.cart(world).x,ColonyTrade.cart(world).y)
	person.activity=trip.state+" for "+trip.args.definition.capitalize()
	var reached: bool = world._walk(person,goal)
	if person.carrying_patient>0:
		var patient: Dictionary = world.find(world.citizens,person.carrying_patient)
		patient.x=person.x;patient.y=person.y;patient.edge_x=person.edge_x;patient.edge_y=person.edge_y;patient.progress=person.progress
	if reached: world._complete(person,job)

static func walking_arrived(world: ColonyWorld, trip: Dictionary, incoming: bool) -> bool:
	var point: Vector2i = Vector2i(ColonyTrade.cart(world).x,ColonyTrade.cart(world).y) if incoming else trip.entry
	var all_arrived: bool = true
	for id in trip.args.party:
		var person: Dictionary = world.find(world.citizens,id)
		if Vector2i(person.x,person.y)==point and person.progress==0 and person.job==0: continue
		all_arrived=false
		if person.job==0 and person.carried_by==0 and world.tick%10==0:
			var job: Dictionary = world._job("expedition_walk","","",id,point,0)
			job.order=trip.id;job.worker=id;job.state="Moving";person.job=job.id
	for id in trip.args.goats:
		var goat: Dictionary = world.find(world.domestic_state.animals,id);var leader: Dictionary = world.find(world.citizens,trip.args.party[0]);goat.x=leader.x;goat.y=leader.y
	return all_arrived

static func waiting_for_raid(world: ColonyWorld, trip: Dictionary) -> bool:
	if trip.state!="Returning" or trip.remaining!=0: return false
	var raid: Dictionary = ColonyDefense.active(world)
	return not raid.is_empty() and raid.arrival>0 and world.tick<raid.arrival+1800

static func advance(world: ColonyWorld) -> void:
	var trip: Dictionary = active(world)
	if trip.is_empty(): return
	if trip.state in ["Preparing","Ready"]:
		if world.tick%10!=0: return
		var wagon: Dictionary = ColonyTrade.cart(world)
		for stack in world.stacks:
			if stack.location=="expedition_cargo" and stack.owner==trip.id: stack.x=wagon.x;stack.y=wagon.y
		trip.note=ready(world,trip);trip.state="Ready" if trip.note.is_empty() else "Preparing"
	elif trip.state=="Walking out" and walking_arrived(world,trip,false):
		trip.state="Outbound";trip.remaining=trip.quote.edges*1800;trip.elapsed=0
	elif trip.state=="Outbound":
		trip.remaining-=1;trip.elapsed+=1;trip.away_ticks+=1
		if not trip.decision_done and trip.decision>=0 and trip.elapsed>=trip.quote.edges*900:
			trip.state="Decision";world.region_state.alert_serial+=1;trip.note="Choose a route response; no real-time expiry and a free Continue option"
		elif trip.remaining==0: trip.state="Site work";trip.remaining=definition_data(world,trip.args.definition,trip.args.pickup).site_hours*300
	elif trip.state=="Site work":
		trip.remaining=maxi(0,trip.remaining-1);trip.away_ticks+=1
		if trip.remaining==0: trip.state="Collect";world.region_state.alert_serial+=1;trip.note="Review exact outcome and choose which rewards fit; Recall before collection gives no new reward"
	elif trip.state=="Returning":
		if trip.remaining>0: trip.remaining-=1;trip.away_ticks+=1
		elif not waiting_for_raid(world,trip): trip.away_ticks+=1
		if trip.remaining==0:
			if waiting_for_raid(world,trip): trip.note="Raid at home: waiting safely at the boundary without extra food until the raid ends or its six-hour limit"
			elif world.walkable(trip.entry) and world.accessible(trip.entry) and ColonyDanger.safe(world,trip.entry): start_walk(world,trip,true)
			else: trip.note="Return boundary blocked or dangerous: clear a safe route; party waits with its cargo"
	elif trip.state=="Walking in" and walking_arrived(world,trip,true):
		var wagon: Dictionary = ColonyTrade.cart(world)
		if trip.reward_animal:
			var acquired: Dictionary = ColonyDomestic.acquire(world,"pack_goat",trip.args.pen,Vector2i(wagon.x,wagon.y))
			if acquired.has("error"): trip.note=acquired.error+": returning goat waits at the cart";return
			trip.reward_animal=false
		for id in trip.args.party:
			var person: Dictionary = world.find(world.citizens,id);person.away=false;person.expedition=0;person.camp_sleeping=false;person.carried_by=0;person.carrying_patient=0
		for id in trip.args.goats:
			var goat: Dictionary = world.find(world.domestic_state.animals,id);goat.away=false;goat.x=wagon.x;goat.y=wagon.y
			var lead: Dictionary = world._job("lead_animal","Animals","Field",goat.id,Vector2i(goat.x,goat.y),0);lead.care_goal=[world.find(world.domestic_state.pens,goat.pen).tiles[0].x,world.find(world.domestic_state.pens,goat.pen).tiles[0].y]
		for stack in world.stacks:
			if stack.location=="expedition_cargo" and stack.owner==trip.id: stack.x=wagon.x;stack.y=wagon.y
		trip.state="Unloading"
	elif trip.state=="Unloading":
		trip.note="Unloading physically in eight-unit loads; returning residents are available for home work"
		for stack in world.stacks:
			if stack.location!="expedition_cargo" or stack.owner!=trip.id or stack.count<=0: continue
			if not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="haul" and j.source==stack.id and j.state not in ["Complete","Canceled"]):
				var job: Dictionary = world._job("haul","Hauling","",stack.id,Vector2i(stack.x,stack.y),0);job.source=stack.id;job.order=trip.id
		var blocked: Array = world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.kind=="haul" and j.order==trip.id and j.state=="Blocked")
		if not blocked.is_empty(): trip.note="Unloading waits: "+blocked[0].reason
		if cargo(world,trip).is_empty() and not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="haul" and j.order==trip.id and j.state not in ["Complete","Canceled"]):
			trip.state="Done";var progress: Dictionary = world.region_state.progress[trip.args.definition]
			if trip.reward_committed:
				progress.returned_at=world.tick
				if trip.quote.shortfall<=2:
					for id in trip.args.party: world.find(world.citizens,id).successful_trips+=1
			var wagon: Dictionary = ColonyTrade.cart(world)
			ColonyTrade.fact(world,"expedition_return",trip.args.definition.capitalize()+" party returned and finished physical unloading. "+("Declared site outcome committed once." if trip.reward_committed else "Recalled without new site rewards."),0,{"participants":trip.args.party,"location":[wagon.x,wagon.y],"causes":ColonyChronicle.causes(world,"trip:"+str(trip.id))})
			world.chronicle_state.links.erase("trip:"+str(trip.id))
	feed_goats(world,trip)

static func feed_goats(world: ColonyWorld, trip: Dictionary) -> void:
	if trip.state not in ["Outbound","Site work","Returning"]: return
	var days: int = trip.away_ticks/7200+1
	if days>trip.fed_days:
		var quantity: int = trip.args.goats.size()*2
		if cargo(world,trip).get(trip.args.feed,0)>=quantity:
			consume(world,trip,trip.args.feed,quantity);trip.fed_days=days
			for id in trip.args.goats:
				var goat: Dictionary = world.find(world.domestic_state.animals,id);goat.last_fed=world.tick/7200;goat.unfed=0;goat.health=mini(60,goat.health+10)
	if trip.reward_animal and trip.reward_goat_fed==0 and cargo(world,trip).get(trip.args.feed,0)>=2:
		consume(world,trip,trip.args.feed,2);trip.reward_goat_fed=1

static func needs(world: ColonyWorld, person: Dictionary) -> void:
	var trip: Dictionary = world.find(world.region_state.trips,person.expedition)
	if trip.is_empty(): return
	var protected_wait: bool = waiting_for_raid(world,trip)
	if not protected_wait:
		person.hunger_rem+=1000;person.fullness=maxi(0,person.fullness-person.hunger_rem/7200);person.hunger_rem%=7200
	if not protected_wait and person.fullness<=350 and cargo(world,trip).get("travel_ration",0)>0:
		consume(world,trip,"travel_ration",1);trip.eaten+=1;person.fullness=mini(1000,person.fullness+500);person.starving_ticks=0
	var hour: int = ((world.tick%7200)/300+(12 if person.shift=="Night shift" else 0))%24
	if not person.camp_sleeping and (person.rest<=300 or ((hour>=22 or hour<6) and person.rest<900)): person.camp_sleeping=true
	elif person.camp_sleeping and (((hour>=6 and hour<22) and person.rest>=900) or (hour==6 and person.rest>=500)): person.camp_sleeping=false
	person.rest_rem+=120 if person.camp_sleeping else 50
	var change: int = person.rest_rem/300;person.rest_rem%=300;person.rest=clampi(person.rest+(change if person.camp_sleeping else -change),0,1000)
	if not protected_wait and person.fullness==0:
		person.starving_ticks+=1
		if person.starving_ticks>1800 and (person.starving_ticks-1800)%300==0: ColonyCare.hurt(world,person,5)
	if trip.state not in ["Walking out","Walking in"]: person.activity="Expedition: "+trip.state+(" · resting at camp" if person.camp_sleeping else "")

static func choice_error(world: ColonyWorld, trip: Dictionary, option: String) -> String:
	if trip.state!="Decision": return "No route decision is waiting"
	var allowed: Array = [["wait","repair","continue"],["give","continue"],["survey","continue"]][trip.decision]
	if option not in allowed: return "Choice does not belong to this decision"
	var goods: Dictionary = cargo(world,trip)
	var delay: int = 6 if option in ["wait","survey"] else 0
	var required: int = 2*trip.args.party.size()*((trip.quote.hours+delay+23)/24+1)-trip.eaten
	var offer: int = 2 if option=="give" else 0
	if goods.get("travel_ration",0)-offer<required: return "Return reserve needs %d more rations" % (required-goods.get("travel_ration",0)+offer)
	var feed: int = 2*trip.args.goats.size()*((trip.quote.hours+delay+23)/24)-2*trip.args.goats.size()*trip.fed_days
	if goods.get(trip.args.feed,0)<feed: return "Delay needs %d more goat feed" % (feed-goods.get(trip.args.feed,0))
	if option=="repair" and goods.get("wood",0)<4: return "Repair needs four packed wood"
	return ""

static func choice(world: ColonyWorld, trip: Dictionary, option: String) -> String:
	if option=="continue" and trip.state=="Decision": pass
	else:
		var error: String = choice_error(world,trip,option)
		if not error.is_empty(): return error
	var progress: Dictionary = world.region_state.progress[trip.args.definition]
	var bonus: bool = world.tick>=progress.decision_after
	if option in ["wait","survey"]: trip.remaining+=1800;trip.quote.hours+=6
	if option=="repair": consume(world,trip,"wood",4)
	if option=="give":
		consume(world,trip,"travel_ration",2)
		if bonus: world.trade_state.reputation.road_fellowship=mini(100,world.trade_state.reputation.road_fellowship+3)
	if bonus and option in ["wait","repair"]:
		var units: int = 0
		for count in cargo(world,trip).values(): units+=count
		var kept: int = mini(4,maxi(0,trip.quote.capacity-units))
		if kept>0: world._make_stack("cloth",kept,"expedition_cargo",trip.id,trip.entry,false);world._record("expedition_gain","cloth",kept)
		if kept<4: progress.leftovers.cloth=progress.leftovers.get("cloth",0)+4-kept
	if bonus and option=="survey": ColonyProduction.add_insight(world,80)
	if bonus and option!="continue": progress.decision_after=world.tick+57600;trip.decision_bonus=true
	trip.decision_done=true;trip.state="Outbound";trip.note="Route choice saved; original readiness stays fixed"
	ColonyTrade.fact(world,"expedition_choice",trip.args.definition.capitalize()+": chose "+option+("; optional reward cooldown eight days" if bonus and option!="continue" else "; no optional bonus"))
	return "accepted"

static func default_keep(world: ColonyWorld, trip: Dictionary) -> Dictionary:
	var goods: Dictionary = cargo(world,trip);var used: int = 0
	for count in goods.values(): used+=count
	if trip.quote.shortfall<=2:
		for count in trip.quote.payment.values(): used-=count
	var free: int = trip.quote.return_capacity-used
	var result: Dictionary = {};var items: Array = trip.quote.rewards.keys()
	items.sort_custom(func(a:String,b:String)->bool:
		var aa: int = PRIORITY.find(a);var bb: int = PRIORITY.find(b)
		if aa<0: aa=100
		if bb<0: bb=100
		return aa<bb if aa!=bb else a<b)
	for item in items:
		var count: int = mini(maxi(0,free),trip.quote.rewards[item])
		if count>0: result[item]=count;free-=count
	return result

static func collect(world: ColonyWorld, trip: Dictionary, keep: Dictionary) -> String:
	if trip.state!="Collect" or trip.reward_committed: return "Outcome already committed or not waiting"
	if not ColonyTrade.quantities(keep,world.definitions.items.keys()): return "Choose positive reward quantities"
	var used: int = 0;var goods: Dictionary = cargo(world,trip)
	for count in goods.values(): used+=count
	for item in keep:
		if keep[item]>trip.quote.rewards.get(item,0): return "Cannot take more than the announced reward"
		used+=keep[item]
	if trip.quote.shortfall<=2:
		for item in trip.quote.payment:
			if goods.get(item,0)<trip.quote.payment[item]: return "Contract payment missing: recall or restore cargo"
			used-=trip.quote.payment[item]
	if used>trip.quote.return_capacity: return "Return cargo exceeds capacity; leave some rewards here"
	var progress: Dictionary = world.region_state.progress[trip.args.definition]
	var changes: Dictionary = keep.duplicate()
	var point: Vector2i = trip.entry
	for item in keep:
		world._make_stack(item,keep[item],"expedition_cargo",trip.id,point,false);world._record("expedition_gain",item,keep[item])
	var leftovers: Dictionary = {}
	for item in trip.quote.rewards:
		if trip.quote.rewards[item]>keep.get(item,0): leftovers[item]=trip.quote.rewards[item]-keep.get(item,0)
	if not trip.args.pickup:
		for item in progress.leftovers: leftovers[item]=leftovers.get(item,0)+progress.leftovers[item]
	progress.leftovers=leftovers
	if trip.args.pickup: progress.pickup_used=true
	else:
		progress.completed=true
		if trip.quote.shortfall<=2:
			for item in trip.quote.payment:
				consume(world,trip,item,trip.quote.payment[item],"traded_out" if ColonyTrade.COMMUNITIES.has(trip.args.definition) else "consumed")
				changes[item]=changes.get(item,0)-trip.quote.payment[item]
			for community in trip.quote.reputation: world.trade_state.reputation[community]=mini(100,world.trade_state.reputation[community]+trip.quote.reputation[community])
			if ColonyTrade.COMMUNITIES.has(trip.args.definition): world.trade_state.delivery_after[trip.args.definition]=world.tick+57600
			trip.reward_animal=definition_data(world,trip.args.definition,false).get("animal_reward","")=="pack_goat"
		ColonyProduction.add_insight(world,trip.quote.insight)
	var injured: Array = []
	if trip.quote.shortfall>2:
		injured=trip.args.party.duplicate();injured.sort()
		injured=injured.slice(0,2)
	elif trip.quote.shortfall>0:
		var party: Array = trip.args.party.duplicate();var skill: String = definition_data(world,trip.args.definition,trip.args.pickup).skill
		party.sort_custom(func(a:int,b:int)->bool:return world.find(world.citizens,a).skills[skill]>world.find(world.citizens,b).skills[skill] if world.find(world.citizens,a).skills[skill]!=world.find(world.citizens,b).skills[skill] else a<b)
		injured=[party[0]]
	for id in injured:
		var person: Dictionary = world.find(world.citizens,id);var damage: int = 20 if trip.quote.shortfall>2 else trip.quote.shortfall*10
		var floor_health: int = 1 if world.care_state.mode=="Hearthside" else 10
		var actual: int = mini(damage,maxi(0,person.health-floor_health))
		var injury: int = world.emit_fact({"tick":world.tick,"actor":person.id,"job":0,"kind":"expedition_injury","text":person.name+" lost %d health at %s from the previewed readiness shortfall." % [actual,trip.args.definition.capitalize()]},{"participants":[person.id],"location":[],"causes":ColonyChronicle.causes(world,"trip:"+str(trip.id))})
		ColonyCare.hurt(world,person,actual,false,[injury]);person.stabilized=true;person.bleed_ticks=0
	if not injured.is_empty() and cargo(world,trip).get("medicine",0)>0:
		injured.sort_custom(func(a:int,b:int)->bool:return world.find(world.citizens,a).health<world.find(world.citizens,b).health if world.find(world.citizens,a).health!=world.find(world.citizens,b).health else a<b)
		changes.medicine=changes.get("medicine",0)-1
		consume(world,trip,"medicine",1);world.find(world.citizens,injured[0]).health=mini(100,world.find(world.citizens,injured[0]).health+20)
		if world.find(world.citizens,injured[0]).health>20: world.find(world.citizens,injured[0]).downed=false
	trip.reward_committed=true;trip.state="Returning";trip.remaining=trip.quote.edges*1800
	var outcome: int = ColonyTrade.fact(world,"expedition_outcome",trip.args.definition.capitalize()+": kept "+str(keep)+", left "+str(leftovers)+", insight %d; shortfall %d. Injuries stabilized; anyone at <=20 is carried on the quoted return schedule." % [trip.quote.insight,trip.quote.shortfall],0,{"participants":trip.args.party,"changes":changes,"causes":ColonyChronicle.causes(world,"trip:"+str(trip.id))})
	ColonyChronicle.remember(world,"trip:"+str(trip.id),outcome)
	return "accepted"

static func visible(world: ColonyWorld, person: Dictionary) -> bool:
	if not person.away: return true
	var trip: Dictionary = world.find(world.region_state.trips,person.expedition)
	return trip.get("state","") in ["Walking out","Walking in"]

static func pack_ready(world: ColonyWorld, job: Dictionary) -> bool:
	var wagon: Dictionary = ColonyTrade.cart(world);var point: Vector2i = Vector2i(wagon.x,wagon.y)
	job.x=point.x;job.y=point.y
	for stack in world.stacks:
		if stack.location=="escrow" and stack.owner==job.id and Vector2i(stack.x,stack.y)!=point: stack.location="ground";stack.owner=0;stack.job=0
	if job.worker>0 and Vector2i(job.work_x,job.work_y)!=point: return world._block(job,"Cart moved: carry packing supplies to its new location")
	return true

static func args_valid(args: Variant, citizens: Array, definitions: Dictionary) -> bool:
	return args is Dictionary and ColonyCodec._keys(args,["definition","party","goats","cargo","feed","pen","variant","pickup"]) and args.definition in SITES+ColonyTrade.COMMUNITIES and args.party is Array and args.party.size()>=2 and args.party.size()<=4 and args.party.all(func(id:Variant)->bool:return id is int and citizens.any(func(c:Dictionary)->bool:return c.id==id)) and args.goats is Array and args.goats.size()<=2 and args.goats.all(func(id:Variant)->bool:return id is int and id>0) and ColonyTrade.quantities(args.cargo,definitions.items.keys()) and args.feed in ["grain","vegetable"] and args.pen is int and args.pen>=0 and args.variant is int and args.variant in [0,1] and args.pickup is bool

static func validate(data: Variant, citizens: Array, definitions: Dictionary, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["rng","rotation","nodes","progress","trips","alert_serial"]) or not data.rng is int or data.rng<=0 or data.rng>=2147483647 or not data.rotation is int or data.rotation not in [0,1,2,3] or not data.nodes is Array or data.nodes.size()!=81 or not data.progress is Dictionary or not ColonyCodec._keys(data.progress,SITES+ColonyTrade.COMMUNITIES) or not data.trips is Array or not data.alert_serial is int or data.alert_serial<0: return false
	var unique: Dictionary = {};var found: Array = []
	for node in data.nodes:
		if not node is Dictionary or not ColonyCodec._keys(node,["x","y","definition","scenery"]) or not node.x is int or not node.y is int or node.x<0 or node.x>8 or node.y<0 or node.y>8 or node.definition not in SITES+ColonyTrade.COMMUNITIES+["home","transit"] or node.scenery not in SCENERY or unique.has(Vector2i(node.x,node.y)): return false
		unique[Vector2i(node.x,node.y)]=true
		if node.definition!="transit":
			if found.has(node.definition): return false
			found.append(node.definition)
			var expected: Vector2i = HOME
			if node.definition in SITES: expected+=rotate(OFFSETS[SITES.find(node.definition)],data.rotation)
			elif node.definition in ColonyTrade.COMMUNITIES: expected+=rotate([Vector2i(-2,0),Vector2i(2,0),Vector2i(0,2)][ColonyTrade.COMMUNITIES.find(node.definition)],data.rotation)
			if Vector2i(node.x,node.y)!=expected: return false
	if found.size()!=12: return false
	for definition in data.progress:
		var state: Variant = data.progress[definition]
		if not state is Dictionary or not ColonyCodec._keys(state,["completed","returned_at","decision_after","leftovers","pickup_used"]) or not state.completed is bool or not state.pickup_used is bool or not state.returned_at is int or state.returned_at<0 or state.returned_at>tick or not state.decision_after is int or state.decision_after<0 or not ColonyTrade.quantities(state.leftovers,definitions.items.keys()): return false
	var active_count: int = 0
	for trip in data.trips:
		if not trip is Dictionary or not ColonyCodec._keys(trip,["id","args","state","quote","entry","remaining","elapsed","away_ticks","fed_days","eaten","readiness","decision","decision_done","decision_bonus","reward_committed","reward_animal","reward_goat_fed","pack_job","note"]) or not trip.id is int or trip.id<=0 or not args_valid(trip.args,citizens,definitions) or trip.state not in STATES or not trip.entry is Vector2i or not trip.note is String: return false
		for field in ["remaining","elapsed","away_ticks","fed_days","eaten","readiness","reward_goat_fed","pack_job"]:
			if not trip[field] is int or trip[field]<0 or trip[field]>1000000000: return false
		for field in ["decision_done","decision_bonus","reward_committed","reward_animal"]:
			if not trip[field] is bool: return false
		if not trip.decision is int or trip.decision not in [-1,0,1,2] or trip.readiness>15 or trip.reward_goat_fed>1: return false
		var quote: Variant = trip.quote
		if not quote is Dictionary or not ColonyCodec._keys(quote,["error","route","edges","hours","rations","feed","inputs","capacity","return_capacity","readiness","challenge","shortfall","rewards","insight","payment","reputation","home_forecast","decision"]) or quote.error!="" or not quote.route is Array or quote.route.size()<2 or quote.route.size()>5 or quote.route[0]!=HOME or not quote.route.all(func(p:Variant)->bool:return p is Vector2i and p.x<9 and p.y<9): return false
		for field in ["edges","hours","rations","feed","capacity","return_capacity","readiness","challenge","shortfall","insight"]:
			if not quote[field] is int or quote[field]<0 or quote[field]>1000: return false
		if quote.edges!=quote.route.size()-1 or quote.capacity!=12*(trip.args.party.size()+trip.args.goats.size()) or quote.return_capacity not in [quote.capacity,quote.capacity+12] or quote.hours>72 or quote.readiness>15 or quote.shortfall!=maxi(0,quote.challenge-quote.readiness) or not quote.decision is int or quote.decision!=trip.decision: return false
		for field in ["inputs","rewards","payment"]:
			if not ColonyTrade.quantities(quote[field],definitions.items.keys()): return false
		if not quote.reputation is Dictionary or not quote.reputation.keys().all(func(k:Variant)->bool:return k in ColonyTrade.COMMUNITIES and quote.reputation[k] is int and quote.reputation[k]>=0 and quote.reputation[k]<=100): return false
		if not quote.home_forecast is Dictionary or not ColonyCodec._keys(quote.home_forecast,["portions","ticks","label"]) or not quote.home_forecast.portions is int or not quote.home_forecast.ticks is int or not quote.home_forecast.label is String: return false
		if trip.state not in ["Done","Canceled"]: active_count+=1
	if active_count>1: return false
	for person in citizens:
		if not person.away is bool or not person.expedition is int or person.expedition<0 or not person.camp_sleeping is bool: return false
		if person.expedition>0 and not data.trips.any(func(t:Dictionary)->bool:return t.id==person.expedition and t.state not in ["Done","Canceled"] and t.args.party.has(person.id)): return false
		if person.away and person.expedition==0: return false
	return true

static func distinct(ids: Array) -> bool:
	var seen: Dictionary = {}
	for id in ids:
		if seen.has(id): return false
		seen[id]=true
	return true
