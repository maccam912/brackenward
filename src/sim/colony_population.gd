class_name ColonyPopulation
extends RefCounted
const NAMES: Array = ["Ada","Bram","Cora","Dax","Edda","Fenn","Greta","Hale","Ivo","Jori","Kest","Lina","Moss","Neri","Otis","Pella","Quin","Rill","Soren","Una","Venn","Wren","Yara","Zed"]
const SURNAMES: Array = ["Ash","Brook","Clay","Fern","Reed","Stone"]
const PREFERRED: Array = ["Growing","Gathering","Building","Crafting","Cooking","Care","Research","Animals"]
const PRIMARY: Dictionary = {"Growing":"Field","Gathering":"Field","Building":"Build","Crafting":"Craft","Cooking":"Cooking","Care":"Care","Research":"Study","Animals":"Field"}
const TRAITS: Array = ["Kind","Homebody","Steady","Sociable","Outdoorsy","Restless","Curious","Private"]
const FOODS: Array = ["Vegetable","Grain","Berry","Mushroom","Meat","Fish","Milk","Egg"]

static func initial_state(seed: int, version: int, site: String) -> Dictionary:
	var rng: ParkMiller = ParkMiller.new(ParkMiller.derive(seed,version,site,"newcomers"))
	var names: Array = NAMES.duplicate()
	for index in range(23,0,-1):
		var other: int = rng.next()%(index+1);var name: String = names[index];names[index]=names[other];names[other]=name
	return {"rng":rng.state,"names":names,"name_cursor":0,"offers":[]}

static func boundary(world: ColonyWorld) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(128):
		for x in (range(128) if y in [0,127] else [0,127]):
			var p: Vector2i = Vector2i(x,y)
			if world.walkable(p) and world.accessible(p) and ColonyDanger.safe(world,p): result.append(p)
	return result

static func living(world: ColonyWorld) -> int:
	return world.citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed).size()

static func generate(world: ColonyWorld) -> Dictionary:
	var state: Dictionary = world.population_state
	var rng: ParkMiller = ParkMiller.new(state.rng)
	var preferred: String = PREFERRED[rng.next()%8]
	var skills: Dictionary = {}
	for skill in ColonyWorld.SKILLS: skills[skill]=0
	skills[PRIMARY[preferred]]=2
	var other_skills: Array = ColonyWorld.SKILLS.filter(func(skill:String)->bool:return skill!=PRIMARY[preferred])
	skills[other_skills[rng.next()%other_skills.size()]]=1
	var traits: Array = []
	while traits.size()!=2:
		traits=[TRAITS[rng.next()%8],TRAITS[rng.next()%8]]
		if traits[0]==traits[1] or (traits.has("Sociable") and traits.has("Private")): traits.clear()
	var food: String = FOODS[rng.next()%8]
	var name: String = ""
	while name.is_empty():
		var base: String = state.names[state.name_cursor%24];state.name_cursor += 1
		var used: Array = world.citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed).map(func(c:Dictionary)->String:return c.name)
		if not used.has(base): name=base
		else:
			var offset: int = rng.next()%6
			for index in range(6):
				var full: String = base+" "+SURNAMES[(offset+index)%6]
				if not used.has(full): name=full;break
	state.rng=rng.state
	return {"name":name,"preferred":preferred,"skills":skills,"traits":traits,"food":food}

static func offer(world: ColonyWorld) -> Dictionary:
	var candidate: Dictionary = generate(world)
	var entries: Array[Vector2i] = boundary(world)
	var rng: ParkMiller = ParkMiller.new(world.population_state.rng)
	var entry: Vector2i = entries[rng.next()%entries.size()] if not entries.is_empty() else Vector2i.ZERO
	world.population_state.rng=rng.state
	var result: Dictionary = {"id":world._id(),"state":"Offered","created":world.tick,"deadline":world.tick+14400,"candidate":candidate,"entry":entry,"actor":0}
	world.population_state.offers.append(result)
	world.emit_fact({"tick":world.tick,"actor":0,"job":0,"kind":"newcomer_offer","text":candidate.name+" can join if there is a reachable free bed and two days of food for the enlarged household. Declining has no penalty; the offer waits two days."})
	return result

static func advance(world: ColonyWorld) -> void:
	for request in world.population_state.offers:
		if request.state=="Offered" and world.tick>=request.deadline: request.state="Expired"
	if world.tick%7200==2400 and (world.tick/7200+1)%4==0 and living(world)<20 and not world.population_state.offers.any(func(o:Dictionary)->bool:return o.state in ["Offered","Accepted"]): offer(world)

static func acceptance(world: ColonyWorld, request: Dictionary) -> Dictionary:
	if request.state!="Offered": return {"error":"Offer is no longer waiting"}
	if living(world)>=20: return {"error":"Twenty residents is the colony limit"}
	var entry: Vector2i = request.entry
	if not ColonyWorld.inside(entry) or not world.walkable(entry) or not world.accessible(entry) or not ColonyDanger.safe(world,entry): return {"error":"Boundary route blocked: clear a safe arrival route"}
	var beds: Array = world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition in ["bed","bedroll"] and s.user==0 and not ColonyFire.burning(world,"structure",s.id) and world.accessible(Vector2i(s.x,s.y)) and ColonyDanger.safe(world,Vector2i(s.x,s.y)))
	beds.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if a.definition!=b.definition: return a.definition=="bed"
		var roof_a: bool = world.roofed(Vector2i(a.x,a.y));var roof_b: bool = world.roofed(Vector2i(b.x,b.y))
		return roof_a if roof_a!=roof_b else a.id<b.id)
	if beds.is_empty(): return {"error":"Build one reachable free bed or bedroll first"}
	var home_count: int = ColonyRegion.home(world).size()+1
	var forecast: Dictionary = FoodForecast.calculate(world,home_count)
	if forecast.ticks<14400: return {"error":"Need two stored-food days for %d residents after joining; currently %s" % [home_count,forecast.label]}
	return {"error":"","bed":beds[0].id}

static func command(world: ColonyWorld, args: Dictionary) -> String:
	var request: Dictionary = world.find(world.population_state.offers,args.target)
	if request.is_empty() or request.state!="Offered": return "Offer no longer waiting"
	if not args.accept:
		request.state="Declined";return "accepted"
	var check: Dictionary = acceptance(world,request)
	if not check.error.is_empty(): return check.error
	var candidate: Dictionary = request.candidate
	var xp: Dictionary = {};var preferences: Dictionary = ColonyWorld.default_preferences(candidate.preferred)
	for skill in ColonyWorld.SKILLS: xp[skill]=ColonyWorld.THRESHOLDS[candidate.skills[skill]]*1000
	var person: Dictionary = ColonyWorld.citizen_record(world._id(),candidate.name,request.entry,candidate.skills.duplicate(),xp,candidate.traits.duplicate(),candidate.preferred,preferences,candidate.food,"")
	person.fullness=800;person.rest=800;person.morale=600
	person.bed=check.bed;world.find(world.structures,check.bed).user=person.id
	world.citizens.append(person)
	for other in world.citizens:
		if other.id==person.id: continue
		var pair: Dictionary = ColonySocial.initial_state([other,person],world.tick).pairs.values()[0]
		pair.score=0;world.social_state.pairs[ColonySocial.key(other.id,person.id)]=pair
	world.equipment_state.merge(ColonyEquipment.initial_state([person]))
	world._record("produced","toolkit",1);world._record("produced","cloak",1)
	request.state="Accepted";request.actor=person.id
	var cart: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]
	var job: Dictionary = world._job("arrival","","",person.id,Vector2i(cart.x,cart.y),0)
	job.worker=person.id;job.state="Moving";job.order=request.id;person.job=job.id
	world.record_indexes.clear();world.reachability_dirty=true
	return "accepted"

static func arrival_work(world: ColonyWorld, person: Dictionary, job: Dictionary) -> void:
	var cart: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]
	person.activity="Joining the household from the boundary"
	if world._walk(person,Vector2i(cart.x,cart.y)):
		world._make_stack("travel_ration",4,"store",cart.id,Vector2i(cart.x,cart.y),true)
		world.find(world.population_state.offers,job.order).state="Arrived"
		world._complete(person,job)
		world.emit_fact({"tick":world.tick,"actor":person.id,"job":job.id,"kind":"newcomer_arrived","text":person.name+" arrived wearing a toolkit and cloak and deposited four personal rations at the cart."})

static func validate(data: Variant, citizens: Array, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["rng","names","name_cursor","offers"]) or not data.rng is int or data.rng<=0 or data.rng>=2147483647 or not data.names is Array or data.names.size()!=24 or not data.name_cursor is int or data.name_cursor<0 or not data.offers is Array: return false
	var names: Array = data.names.duplicate();names.sort();var expected: Array = NAMES.duplicate();expected.sort()
	if names!=expected: return false
	var pending: int = 0
	for request in data.offers:
		if not request is Dictionary or not ColonyCodec._keys(request,["id","state","created","deadline","candidate","entry","actor"]) or not request.id is int or request.state not in ["Offered","Accepted","Arrived","Declined","Expired"] or not request.created is int or request.created<1800 or request.created>tick or request.deadline!=request.created+14400 or not request.entry is Vector2i or (request.entry!=Vector2i(-1,-1) and not ColonyWorld.inside(request.entry)) or not request.actor is int: return false
		var candidate: Variant = request.candidate
		if not candidate is Dictionary or not ColonyCodec._keys(candidate,["name","preferred","skills","traits","food"]) or not candidate.name is String or candidate.name.length()>64 or candidate.preferred not in PREFERRED or candidate.food not in FOODS or not candidate.skills is Dictionary or not ColonyCodec._keys(candidate.skills,ColonyWorld.SKILLS) or not candidate.skills.values().all(func(n:Variant)->bool:return n is int and n>=0 and n<=2) or not candidate.traits is Array or candidate.traits.size()!=2 or candidate.traits[0]==candidate.traits[1] or not candidate.traits.all(func(t:Variant)->bool:return t in TRAITS) or (candidate.traits.has("Sociable") and candidate.traits.has("Private")): return false
		if not request.deadline is int or request.id<=0 or candidate.name.is_empty() or candidate.skills[PRIMARY[candidate.preferred]]!=2 or candidate.skills.values().count(2)!=1 or candidate.skills.values().count(1)!=1: return false
		if request.entry!=Vector2i(-1,-1) and request.entry.x not in [0,127] and request.entry.y not in [0,127]: return false
		if request.state in ["Accepted","Arrived"]:
			if request.actor<=0 or not citizens.any(func(c:Dictionary)->bool:return c.id==request.actor): return false
		elif request.actor!=0: return false
		if request.state in ["Offered","Accepted"]: pending += 1
	return pending<=1
