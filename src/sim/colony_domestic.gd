class_name ColonyDomestic
extends RefCounted
const BOUNDARIES: Array = ["fence","pen_gate","wood_wall","stone_wall","palisade"]

static func initial_state() -> Dictionary:
	return {"pens":[],"animals":[],"feed_day":-1}

static func animal_template() -> Dictionary:
	return {"id":0,"definition":"hen","name":"Hen","x":0,"y":0,"pen":0,"barn":0,"health":25,"juvenile_until":0,"born":1800,"unfed":0,"last_fed":-1,"pending":0,"away":false,"handler":0}

static func geometry(world: ColonyWorld, tiles: Array) -> Dictionary:
	var boundaries: Dictionary = {}
	for structure in world.structures:
		if structure.definition in BOUNDARIES:
			for p in world.footprint(structure): boundaries[p]=true
	var interior: Array[Vector2i] = []
	for p in tiles:
		if not ColonyWorld.inside(p) or world.is_water(p): return {"error":"Pen needs land"}
		if not boundaries.has(p) and not interior.has(p): interior.append(p)
	if interior.is_empty(): return {"error":"Paint at least four interior tiles"}
	var area: Dictionary = {}
	for p in interior: area[p]=true
	for p in interior:
		for delta in ColonyNavigation.NEIGHBORS:
			if not area.has(p+delta) and not boundaries.has(p+delta): return {"error":"Pen perimeter is open: complete fences, gates or solid walls"}
	var reached: Dictionary = {interior[0]:true}
	var queue: Array[Vector2i] = [interior[0]]
	var cursor: int = 0
	while cursor<queue.size():
		var p: Vector2i = queue[cursor];cursor += 1
		for delta in ColonyNavigation.NEIGHBORS:
			if area.has(p+delta) and not reached.has(p+delta): reached[p+delta]=true;queue.append(p+delta)
	if queue.size()!=interior.size(): return {"error":"Choose one connected enclosed pen"}
	var barns: Array = []
	for structure in world.structures:
		if structure.definition!="barn": continue
		if world.footprint(structure).any(func(p:Vector2i)->bool:return area.has(p) or ColonyNavigation.NEIGHBORS.any(func(d:Vector2i)->bool:return area.has(p+d))): barns.append(structure.id)
	return {"error":"","interior":interior,"barns":barns,"tiles_capacity":interior.filter(func(p:Vector2i)->bool:return world.walkable(p)).size()/4,"shelter_capacity":barns.size()*6}

static func occupants(world: ColonyWorld, pen_id: int) -> Array:
	return world.domestic_state.animals.filter(func(a:Dictionary)->bool:return a.pen==pen_id and a.health>0)

static func status(world: ColonyWorld, pen: Dictionary) -> Dictionary:
	var result: Dictionary = geometry(world,pen.tiles)
	if not result.has("barns"):
		result["barns"] = []
		for structure in world.structures:
			if structure.definition=="barn" and world.footprint(structure).any(func(p:Vector2i)->bool:return pen.tiles.has(p) or ColonyNavigation.NEIGHBORS.any(func(d:Vector2i)->bool:return pen.tiles.has(p+d))): result.barns.append(structure.id)
	result["count"] = occupants(world,pen.id).size()
	var slots: int = 0
	for barn in result.barns:
		slots += maxi(0,6-world.domestic_state.animals.filter(func(a:Dictionary)->bool:return a.health>0 and a.barn==barn and a.pen!=pen.id).size())
	result["capacity"] = 0 if not result.error.is_empty() else mini(result.tiles_capacity,slots)
	return result

static func demand(world: ColonyWorld, animal: Dictionary, day: int) -> int:
	var adult: int = world.definitions.animals[animal.definition].feed
	if world.tick>=animal.juvenile_until: return adult
	return adult/2+(adult%2 if (day-animal.born/7200)%2==1 else 0)

static func feed_item(world: ColonyWorld, item: String) -> bool:
	var tags: Array = world.definitions.items.get(item,{}).get("tags",[])
	return tags.has("Grain") or tags.has("Vegetable")

static func feed_count(world: ColonyWorld, barn: int) -> int:
	var count: int = 0
	for stack in world.stacks:
		if stack.location=="animal_feed" and stack.owner==barn: count += stack.count
	return count

static func output_count(world: ColonyWorld, barn: int) -> int:
	var count: int = 0
	for stack in world.stacks:
		if stack.location=="output" and stack.owner==barn: count += stack.count
	return count

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	if kind=="pen":
		if not world.researched.has("husbandry"): return "Research Husbandry first"
		var shape: Dictionary = geometry(world,args.tiles)
		if not shape.error.is_empty(): return shape.error
		for p in shape.interior:
			if world.domestic_state.pens.any(func(z:Dictionary)->bool:return z.tiles.has(p)) or world.stores.any(func(z:Dictionary)->bool:return z.tiles.has(p)) or world.fields.any(func(f:Dictionary)->bool:return Vector2i(f.x,f.y)==p): return "Pen overlaps another zone: fields, stockpiles and pens need separate tiles"
		world.domestic_state.pens.append({"id":world._id(),"tiles":shape.interior,"breeding":false,"next_birth":0,"reason":"No livestock yet"})
		return "accepted"
	if kind=="breeding":
		var pen: Dictionary = world.find(world.domestic_state.pens,args.target)
		if pen.is_empty(): return "Missing pen"
		pen.breeding=args.enabled;pen.next_birth=world.tick+57600 if args.enabled else 0
		return "accepted"
	var animal: Dictionary = world.find(world.domestic_state.animals,args.target)
	if animal.is_empty() or animal.health<=0 or animal.away: return "Choose a living animal at home"
	if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="slaughter" and j.target==animal.id and j.state not in ["Complete","Canceled"]): return "Slaughter already marked"
	var job: Dictionary = world._job("slaughter","Animals","Field",animal.id,Vector2i(animal.x,animal.y),10000)
	job.definition=animal.definition
	return "accepted"

static func acquire_error(world: ColonyWorld, kind: String, pen_id: int) -> String:
	if not world.researched.has("husbandry"): return "Research Husbandry before acquiring animals"
	if not world.definitions.animals.get(kind,{}).get("domestic",false): return "Unknown domestic species"
	if world.domestic_state.animals.filter(func(a:Dictionary)->bool:return a.health>0).size()>=12: return "Twelve domestic animals is the colony limit"
	var pen: Dictionary = world.find(world.domestic_state.pens,pen_id)
	if pen.is_empty(): return "Paint an enclosed pen first"
	var info: Dictionary = status(world,pen)
	if not info.error.is_empty(): return info.error
	if info.count>=info.capacity: return "Need four spare pen tiles and one spare barn shelter slot"
	return ""

static func acquire(world: ColonyWorld, kind: String, pen_id: int, point: Vector2i, juvenile: bool = false) -> Dictionary:
	if not ColonyWorld.inside(point): return {"error":"Animal arrival must be on the map"}
	var error: String = acquire_error(world,kind,pen_id)
	if not error.is_empty(): return {"error":error}
	var pen: Dictionary = world.find(world.domestic_state.pens,pen_id)
	var info: Dictionary = status(world,pen)
	var animal: Dictionary = animal_template()
	animal.id=world._id();animal.definition=kind;animal.name=("Hen " if kind=="hen" else "Goat ")+str(animal.id)
	animal.x=point.x;animal.y=point.y;animal.pen=pen_id;animal.health=world.definitions.animals[kind].health;animal.born=world.tick
	if juvenile: animal.juvenile_until=world.tick+28800
	for barn in info.barns:
		if world.domestic_state.animals.filter(func(a:Dictionary)->bool:return a.barn==barn and a.health>0).size()<6: animal.barn=barn;break
	if animal.barn==0: return {"error":"All barn slots are occupied"}
	world.domestic_state.animals.append(animal)
	if not pen.tiles.has(point):
		var job: Dictionary = world._job("lead_animal","Animals","Field",animal.id,point,0)
		var goal: Vector2i = pen.tiles.filter(func(p:Vector2i)->bool:return world.walkable(p))[0]
		job.care_goal=[goal.x,goal.y]
	return {"animal":animal}

static func advance(world: ColonyWorld) -> void:
	_feed_dawn(world)
	_breed(world)

static func _feed_dawn(world: ColonyWorld) -> void:
	if world.tick%7200!=1800 or world.domestic_state.feed_day==world.tick/7200: return
	var day: int = world.tick/7200
	world.domestic_state.feed_day=day
	for pen in world.domestic_state.pens:
		var info: Dictionary = status(world,pen)
		pen.reason=info.error
		for animal in occupants(world,pen.id):
			if animal.away: continue
			var required: int = demand(world,animal,day)
			var barn: Dictionary = world.find(world.structures,animal.barn)
			var reachable_feed: bool = info.barns.has(animal.barn) and pen.tiles.has(Vector2i(animal.x,animal.y)) and not barn.is_empty()
			if reachable_feed and feed_count(world,animal.barn)>=required:
				var remaining: int = required
				var supplies: Array = world.stacks.filter(func(s:Dictionary)->bool:return s.location=="animal_feed" and s.owner==animal.barn and s.count>0)
				supplies.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.age>b.age if a.age!=b.age else a.id<b.id)
				for stack in supplies:
					var used: int = mini(remaining,stack.count);stack.count -= used;remaining -= used;world._record("consumed",stack.item,used)
					if remaining==0: break
				animal.unfed=0;animal.last_fed=day;animal.health=mini(world.definitions.animals[animal.definition].health,animal.health+10)
				if world.tick>=animal.juvenile_until and (ColonyAgriculture.season(world.tick)!=3 or info.barns.has(animal.barn)):
					var rate: int = world.definitions.animals[animal.definition].outputs.values()[0]
					animal.pending=mini(rate*2,animal.pending+rate)
			else:
				animal.unfed += 1;pen.reason="Feed inaccessible or empty: Animals workers stock grain/vegetables in the barn. No output while unfed."
				if animal.unfed>2:
					animal.health=maxi(0,animal.health-10)
					if animal.health==0:
						animal.pending=0
						for job in world.jobs:
							if job.target==animal.id and job.kind in ["lead_animal","collect_animal","slaughter"] and job.state not in ["Complete","Canceled"]: world._release(job,true)
					world.facts.append({"tick":world.tick,"actor":animal.id,"job":0,"kind":"animal_hungry","text":animal.name+" lost 10 health after more than two unfed days. Stock barn feed and enable Animals work."})

static func create_jobs(world: ColonyWorld) -> void:
	for pen in world.domestic_state.pens:
		var info: Dictionary = status(world,pen)
		if not info.error.is_empty(): pen.reason=info.error
		for barn_id in info.barns:
			var residents: Array = occupants(world,pen.id).filter(func(a:Dictionary)->bool:return a.barn==barn_id and not a.away)
			var daily: int = 0
			for animal in residents: daily += demand(world,animal,world.tick/7200+1)
			var shortage: int = mini(24,daily*2)-feed_count(world,barn_id)
			if shortage<=0 or world.jobs.any(func(j:Dictionary)->bool:return j.kind=="stock_feed" and j.target==barn_id and j.state not in ["Complete","Canceled"]): continue
			var candidates: Array = world.stacks.filter(func(s:Dictionary)->bool:return feed_item(world,s.item) and s.count>world._reserved(s) and s.location in ["ground","store","output"] and world.accessible(Vector2i(s.x,s.y)))
			candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.age>b.age if a.age!=b.age else a.id<b.id)
			if candidates.is_empty(): pen.reason="No grain or vegetables available for barn feed";continue
			var source: Dictionary = candidates[0]
			var barn: Dictionary = world.find(world.structures,barn_id)
			var job: Dictionary = world._job("stock_feed","Animals","Field",barn_id,Vector2i(barn.x,barn.y),0)
			job.inputs={source.item:mini(8,mini(shortage,source.count-world._reserved(source)))}
	for animal in world.domestic_state.animals:
		if animal.health<=0 or animal.away or animal.pending==0 or world.jobs.any(func(j:Dictionary)->bool:return j.kind in ["collect_animal","slaughter","lead_animal"] and j.target==animal.id and j.state not in ["Complete","Canceled"]): continue
		var job: Dictionary = world._job("collect_animal","Animals","Field",animal.id,Vector2i(animal.x,animal.y),4000)
		job.definition=animal.definition

static func reserve(world: ColonyWorld, job: Dictionary, citizen: Dictionary) -> bool:
	if job.kind=="stock_feed":
		if feed_count(world,job.target)+job.inputs.values()[0]>24: return world._block(job,"Barn feed buffer full: capacity 24")
		return true
	var animal: Dictionary = world.find(world.domestic_state.animals,job.target)
	if animal.is_empty() or animal.health<=0 or animal.away: return world._block(job,"Animal is away or no longer alive")
	job.x=animal.x;job.y=animal.y
	var pen: Dictionary = world.find(world.domestic_state.pens,animal.pen)
	var info: Dictionary = status(world,pen)
	if not info.error.is_empty(): return world._block(job,info.error)
	for other in world.jobs:
		if other.id!=job.id and other.target==animal.id and other.kind in ["lead_animal","collect_animal","slaughter"] and other.worker>0: return world._block(job,"Animal already handled by another worker")
	if job.kind=="collect_animal":
		if animal.pending==0: return world._block(job,"No products waiting")
		if not info.barns.has(animal.barn) or output_count(world,animal.barn)+animal.pending>24: return world._block(job,"Barn output buffer full or shelter missing: haul its products")
	return true

static func lead_work(world: ColonyWorld, citizen: Dictionary, job: Dictionary) -> void:
	var animal: Dictionary = world.find(world.domestic_state.animals,job.target)
	if animal.health<=0 or animal.away: world._release(job,true);return
	if animal.handler==0:
		citizen.activity="Meeting "+animal.name
		if ColonyWildlife.distance(citizen,animal)<=1: animal.handler=citizen.id
		else: world._walk(citizen,Vector2i(animal.x,animal.y))
		return
	citizen.activity="Leading "+animal.name+" through the pen gate"
	var previous: Vector2i = Vector2i(citizen.x,citizen.y)
	var goal: Vector2i = Vector2i(job.care_goal[0],job.care_goal[1])
	var arrived: bool = world._walk(citizen,goal)
	if previous!=Vector2i(citizen.x,citizen.y): animal.x=previous.x;animal.y=previous.y
	if arrived and absi(animal.x-goal.x)+absi(animal.y-goal.y)<=1:
		animal.x=goal.x;animal.y=goal.y;animal.handler=0;world._complete(citizen,job)

static func ready_complete(world: ColonyWorld, job: Dictionary) -> bool:
	if job.kind=="stock_feed": return feed_count(world,job.target)+job.inputs.values()[0]<=24
	if job.kind=="collect_animal":
		var animal: Dictionary = world.find(world.domestic_state.animals,job.target)
		return animal.health>0 and not animal.away and output_count(world,animal.barn)+animal.pending<=24
	return true

static func complete(world: ColonyWorld, job: Dictionary) -> void:
	if job.kind=="stock_feed":
		for stack in world.stacks:
			if stack.location=="escrow" and stack.owner==job.id: stack.location="animal_feed";stack.owner=job.target;stack.job=0
		return
	var animal: Dictionary = world.find(world.domestic_state.animals,job.target)
	if job.kind=="collect_animal":
		var product: String = world.definitions.animals[animal.definition].outputs.keys()[0]
		var barn: Dictionary = world.find(world.structures,animal.barn)
		world._make_stack(product,animal.pending,"output",animal.barn,Vector2i(barn.x,barn.y),true);animal.pending=0
	else:
		animal.health=0;animal.pending=0
		for item in world.definitions.animals[animal.definition].slaughter_outputs: world._make_stack(item,world.definitions.animals[animal.definition].slaughter_outputs[item],"ground",0,Vector2i(animal.x,animal.y),true)

static func validate(data: Variant, world: ColonyWorld, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["pens","animals","feed_day"]) or not data.pens is Array or not data.animals is Array or not data.feed_day is int or data.feed_day < -1 or data.feed_day>tick/7200: return false
	for pen in data.pens:
		if not pen is Dictionary or not ColonyCodec._keys(pen,["id","tiles","breeding","next_birth","reason"]) or not pen.id is int or not pen.tiles is Array or pen.tiles.is_empty() or pen.tiles.size()>16384 or not pen.tiles.all(func(p:Variant)->bool:return p is Vector2i and ColonyWorld.inside(p)) or not pen.breeding is bool or not pen.next_birth is int or pen.next_birth<0 or pen.next_birth>tick+57600 or not pen.reason is String: return false
	var living: int = 0
	for animal in data.animals:
		if not ColonyCodec._record(animal,animal_template()) or not world.definitions.animals.get(animal.definition,{}).get("domestic",false) or not ColonyCodec._position(animal) or animal.name.length()>64 or animal.health<0 or animal.health>world.definitions.animals[animal.definition].health or animal.juvenile_until<0 or animal.juvenile_until>tick+28800 or animal.born<1800 or animal.born>tick or animal.unfed<0 or animal.last_fed < -1 or animal.last_fed>tick/7200 or animal.pending<0 or animal.pending>2*world.definitions.animals[animal.definition].outputs.values()[0] or not data.pens.any(func(p:Dictionary)->bool:return p.id==animal.pen): return false
		if animal.health>0: living += 1
	return living<=12

static func _breed(world: ColonyWorld) -> void:
	var day: int = world.domestic_state.feed_day
	for pen in world.domestic_state.pens:
		if pen.breeding and world.tick>=pen.next_birth:
			pen.next_birth=world.tick+57600
			var born: bool = false
			for species in ["hen","pack_goat"]:
				var parents: Array = occupants(world,pen.id).filter(func(a:Dictionary)->bool:return a.definition==species and not a.away and a.juvenile_until<=world.tick and a.last_fed==day)
				if parents.size()<2: continue
				var error: String = acquire_error(world,species,pen.id)
				if not error.is_empty(): pen.reason=error;continue
				var result: Dictionary = acquire(world,species,pen.id,pen.tiles.filter(func(p:Vector2i)->bool:return world.walkable(p))[0],true)
				if result.has("animal"):
					born=true;pen.reason="Juvenile born; matures in four days and consumes half adult feed.";break
				pen.reason=result.error
			if not born and pen.reason.is_empty(): pen.reason="Breeding waits: two fed adults, one free shelter slot, four free pen tiles and room under the twelve-animal cap. Blocked births do not accumulate."
