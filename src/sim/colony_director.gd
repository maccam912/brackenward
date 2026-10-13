class_name ColonyDirector
extends RefCounted

static func initial_state(seed: int, version: int, site: String) -> Dictionary:
	return {"rng":ParkMiller.derive(seed,version,site,"major_incidents"),"last_start":0,"recovery_until":0,"major":{},"history":[]}

static func pressure(world: ColonyWorld) -> Dictionary:
	var people: Array = ColonyRegion.home(world);var terms: Dictionary = {};var score: int = 0
	if people.is_empty(): return {"score":100,"terms":{"No home residents":100}}
	var food: int = FoodForecast.calculate(world).ticks
	if food<7200: terms["Food below one day"]=50
	elif food<14400: terms["Food below two days"]=30
	if world.citizens.any(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed and c.downed): terms["A resident is downed"]=40
	if people.filter(func(c:Dictionary)->bool:return c.health<60).size()*10>=people.size()*3: terms["At least thirty percent below sixty health"]=20
	if world.fire_state.destroyed.any(func(d:Dictionary)->bool:return world.tick-d.tick<14400): terms["A completed building destroyed in two days"]=20
	var morale: int = people.reduce(func(n:int,c:Dictionary)->int:return n+c.morale,0)/people.size()
	if morale<400: terms["Average home morale below four hundred"]=20
	for amount in terms.values(): score+=amount
	return {"score":mini(100,score),"terms":terms}

static func start_allowed(world: ColonyWorld, tick: int) -> bool:
	var state: Dictionary = world.director_state
	if state.last_start>0 and tick-state.last_start<21600: return false
	if tick<state.recovery_until: return false
	for entry in world.weather_state.days:
		if entry.kind in ["flood","cold_snap"]:
			var extreme_start: int = entry.day*7200+(1800 if entry.kind=="flood" else 0)
			if absi(extreme_start-tick)<21600: return false
	return true

static func gates(world: ColonyWorld) -> String:
	var state: Dictionary = world.director_state
	if not state.major.is_empty() or not ColonyDefense.active(world).is_empty() or not ColonyFire.active(world).is_empty(): return "An incident remains active"
	if ColonyRegion.critical(world): return "An expedition choice needs acknowledgement"
	if world.citizens.any(func(c:Dictionary)->bool:return c.downed and not c.death_recorded and not c.departed): return "A resident is downed"
	if pressure(world).score>=50: return "Pressure is fifty or more"
	if world.tick<state.recovery_until: return "No new major incident while recovering"
	if state.last_start>0 and world.tick+3600-state.last_start<21600: return "Major starts remain seventy-two hours apart"
	return ""

static func budget(world: ColonyWorld) -> int:
	var charter: Variant = world.get("charter_state")
	var stages: int = charter.get("completed",[]).size() if charter is Dictionary else 0
	return mini(10,2+maxi(0,ColonyPopulation.living(world)-4)/3+stages/2)

static func finish(world: ColonyWorld, reason: String) -> void:
	var state: Dictionary = world.director_state;var major: Dictionary = state.major
	if major.is_empty(): return
	major.state="Resolved";major.ended=world.tick;major.reason=reason
	state.history.append(major.duplicate(true));state.major={};state.recovery_until=world.tick+14400
	ColonyTrade.fact(world,"major_resolved",reason+" No new major for forty-eight hours, with seventy-two-hour start spacing retained.")

static func consider(world: ColonyWorld) -> void:
	if world.tick/7200+1<8 or not gates(world).is_empty(): return
	var options: Array = []
	if world.care_state.mode=="Standard" and start_allowed(world,world.tick+7200): options.append({"kind":"raid","weight":70})
	var unsafe: Array = world.structures.filter(func(s:Dictionary)->bool:return not ColonyFire.unsafe(world,s).is_empty())
	if not unsafe.is_empty() and start_allowed(world,world.tick+3600): options.append({"kind":"overheat","weight":30})
	if options.is_empty(): return
	var state: Dictionary = world.director_state;var rng: ParkMiller = ParkMiller.new(state.rng);var total: int = 0
	for option in options: total+=option.weight
	var roll: int = rng.next()%total;var kind: String = ""
	for option in options:
		if roll<option.weight: kind=option.kind;break
		roll-=option.weight
	var major: Dictionary = {"id":world._id(),"kind":kind,"state":"Announced","target":0,"fire":0,"created":world.tick,"due":world.tick+(7200 if kind=="raid" else 3600),"started":0,"ended":0,"reason":""}
	if kind=="raid":
		var raid: Dictionary = ColonyDefense.announce(world,budget(world));major.target=raid.id;major.reason="Road party due in twenty-four hours; composition, theft quota and supply price are fixed"
	else:
		major.target=unsafe[rng.next()%unsafe.size()].id
		major.reason="Overheating station due to ignite in twelve hours. Suspend this station or clear its one-tile flammable perimeter to prevent ignition; target will not change"
		ColonyTrade.fact(world,"overheat_warning",major.reason)
	state.rng=rng.state;state.major=major
	if not world.weather_state.reserved_major_days.has(major.due/7200): world.weather_state.reserved_major_days.append(major.due/7200)

static func advance(world: ColonyWorld) -> void:
	var state: Dictionary = world.director_state;var major: Dictionary = state.major
	if not major.is_empty():
		if major.kind=="raid":
			var raid: Dictionary = world.find(world.defense_state.raids,major.target)
			major.due=raid.due
			if raid.arrival>0 and major.started==0: major.started=raid.arrival;major.state="Active";state.last_start=raid.arrival
			if raid.state=="Resolved": finish(world,"The announced road party resolved through the actions actually taken")
		else:
			var station: Dictionary = world.find(world.structures,major.target)
			if major.state=="Announced":
				if station.is_empty() or ColonyFire.unsafe(world,station).is_empty(): finish(world,"The fixed overheating target stopped working or its perimeter became safe; no ignition")
				elif world.tick>=major.due:
					if not start_allowed(world,world.tick): major.due+=7200;major.reason="Major spacing reserved: overheating waits twenty-four hours"
					else:
						var fire: Dictionary = ColonyFire.ignite(world,"structure",station.id)
						major.fire=fire.id;major.started=world.tick;major.state="Active";state.last_start=world.tick
			elif ColonyFire.active(world).is_empty(): finish(world,"The overheating fire ended after extinguishing or actual destruction")
	if world.tick%7200==1800: consider(world)

static func validate(data: Variant, tick: int, raids: Array, fires: Array, structures: Array) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["rng","last_start","recovery_until","major","history"]) or not data.rng is int or data.rng<=0 or data.rng>=2147483647 or not data.last_start is int or data.last_start<0 or data.last_start>tick or not data.recovery_until is int or data.recovery_until<0 or not data.major is Dictionary or not data.history is Array: return false
	var records: Array = data.history.duplicate()
	if not data.major.is_empty(): records.append(data.major)
	for major in records:
		if not major is Dictionary or not ColonyCodec._keys(major,["id","kind","state","target","fire","created","due","started","ended","reason"]) or not major.id is int or major.id<=0 or major.kind not in ["raid","overheat"] or major.state not in ["Announced","Active","Resolved"] or not major.reason is String: return false
		for field in ["target","fire","created","due","started","ended"]:
			if not major[field] is int or major[field]<0: return false
		if major.created<1800 or major.created>tick or major.started>tick or major.ended>tick: return false
		if major.kind=="raid" and not raids.any(func(r:Dictionary)->bool:return r.id==major.target): return false
		if major.kind=="overheat" and not structures.any(func(s:Dictionary)->bool:return s.id==major.target): return false
		if major.fire>0 and not fires.any(func(f:Dictionary)->bool:return f.id==major.fire): return false
	return true
