class_name ColonyTutorial
extends RefCounted
## Device-local learning evidence. This module never issues simulation commands.
const OPENING: Array[String] = ["follow","forage","lodge","cook","field","cooking_priority","forecast"]
const TRIGGERS: Array[String] = ["winter","injury","research","expedition"]
const TITLES: Dictionary = {"follow":"Meet Mira", "forage":"Bring food home", "lodge":"Plan a sleeping lodge", "cook":"Watch a meal batch", "field":"Grow eight turnips", "cooking_priority":"Choose Mira's work", "forecast":"Keep the food forecast visible", "winter":"Prepare for Winter", "injury":"Help an injured resident", "research":"Choose a research project", "expedition":"Prepare an expedition"}

static func initial_state() -> Dictionary:
	return {"version":1,"enabled":false,"active":"","completed":[],"skipped":[],"triggered":[],"visited":[],"forecast_pinned":false,"replaying":false}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or not ColonyCodec._keys(value,initial_state().keys()) or value.version!=1 or not value.enabled is bool or not value.forecast_pinned is bool or not value.replaying is bool or not value.active is String or (not value.active.is_empty() and not TITLES.has(value.active)): return false
	for key in ["completed","skipped","triggered","visited"]:
		if not value[key] is Array or value[key].size()>11: return false
		var unique: Array = []
		for id in value[key]:
			if not id is String or unique.has(id): return false
			if key=="triggered" and id not in TRIGGERS: return false
			if key=="visited" and id not in ["hearth","forecast","weather","care","research","expedition","work_preferences"]: return false
			if key in ["completed","skipped"] and not TITLES.has(id): return false
			unique.append(id)
	return true

static func campaign(settings: DeviceSettings, id: String) -> Dictionary:
	if not settings.values.tutorials.has(id): settings.values.tutorials[id]=initial_state()
	return settings.values.tutorials[id]

static func begin(state: Dictionary) -> void:
	state.enabled=true
	if state.active.is_empty(): state.active=_next(state)

static func dismiss(state: Dictionary) -> void:
	state.enabled=false

static func skip(state: Dictionary) -> void:
	if not state.active.is_empty() and not state.skipped.has(state.active): state.skipped.append(state.active)
	state.replaying=false;state.active=_next(state)

static func replay(state: Dictionary, lesson: String) -> void:
	if not TITLES.has(lesson): return
	state.active=lesson;state.enabled=true;state.replaying=state.completed.has(lesson)

static func _next(state: Dictionary) -> String:
	for lesson in OPENING+state.triggered:
		if not state.completed.has(lesson) and not state.skipped.has(lesson): return lesson
	return ""

static func _complete(state: Dictionary, lesson: String) -> void:
	if not state.completed.has(lesson): state.completed.append(lesson)
	if state.active==lesson and not state.replaying: state.active=_next(state)

static func action(world: ColonyWorld, state: Dictionary, kind: String, args: Dictionary = {}) -> void:
	if kind=="follow":
		var person: Dictionary = world.find(world.citizens,args.get("citizen",0))
		if not person.is_empty() and not person.death_recorded and not person.departed: _complete(state,"follow")
	elif kind=="pin_forecast":
		state.forecast_pinned=true;_complete(state,"forecast")
	elif kind in ["hearth","forecast","weather","care","research","expedition","work_preferences"]:
		if kind=="work_preferences" and args.get("citizen",0)!=1: return
		if not state.visited.has(kind): state.visited.append(kind)
		if kind=="weather" and state.triggered.has("winter"): _complete(state,"winter")
		if kind=="care" and state.triggered.has("injury"): _complete(state,"injury")

static func evaluate(world: ColonyWorld, state: Dictionary) -> Array[String]:
	var added: Array[String] = []
	var upcoming_winter: bool = ColonyAgriculture.season(world.tick)==3 or world.weather_state.days.any(func(d:Dictionary)->bool:return d.day>=world.tick/7200 and d.day%32>=24)
	var triggers: Dictionary = {"winter":upcoming_winter, "injury":world.citizens.any(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed and (c.downed or c.health<100)), "research":world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="research_desk"), "expedition":world.researched.has("trailcraft")}
	for lesson in TRIGGERS:
		if triggers[lesson] and not state.triggered.has(lesson): state.triggered.append(lesson);added.append(lesson)
	# Completed haul work proves an actual delivery, even if its source record is empty.
	if not state.completed.has("forage"):
		for job in world.jobs:
			if job.kind=="haul" and job.state=="Complete" and world.find(world.stacks,job.source).get("item")=="berry": _complete(state,"forage");break
	if not state.completed.has("lodge") and world.construction_state.groups.any(func(g:Dictionary)->bool:return g.kind=="lodge" and g.members.all(func(id:int)->bool:return world.find(world.jobs,id).get("state")!="Canceled")): _complete(state,"lodge")
	if state.visited.has("hearth") and world.jobs.any(func(j:Dictionary)->bool:return j.state=="Complete" and (j.kind=="cook" or (j.kind=="craft" and j.definition=="cook_meals"))): _complete(state,"cook")
	if world.fields.filter(func(f:Dictionary)->bool:return f.crop=="turnip" and f.planted).size()>=8: _complete(state,"field")
	var mira: Dictionary = world.find(world.citizens,1)
	if not mira.is_empty() and mira.preferences.Cooking==3 and state.visited.has("work_preferences"):
		var job: Dictionary = world.find(world.jobs,mira.job)
		if job.get("category")=="Cooking" and job.worker==mira.id: _complete(state,"cooking_priority")
	if state.triggered.has("research") and not world.production_state.project.is_empty(): _complete(state,"research")
	if state.triggered.has("expedition") and not world.region_state.trips.is_empty(): _complete(state,"expedition")
	if state.enabled and state.active.is_empty(): state.active=_next(state)
	return added

static func _home(world: ColonyWorld) -> Vector2i:
	var cart: Dictionary = ColonyTrade.cart(world)
	return Vector2i(cart.x,cart.y)

static func _nearest(world: ColonyWorld, records: Array, allowed: Callable) -> Dictionary:
	var home: Vector2i = _home(world)
	var choices: Array = records.filter(allowed)
	choices.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var da: int = absi(a.x-home.x)+absi(a.y-home.y);var db: int = absi(b.x-home.x)+absi(b.y-home.y)
		return da<db if da!=db else a.y*128+a.x<b.y*128+b.x)
	return {} if choices.is_empty() else choices[0]

static func lodge_target_valid(world: ColonyWorld, point: Vector2i) -> bool:
	if point.x<0 or point.x>120 or point.y<0 or point.y>122: return false
	if not world.accessible(point) or not ColonyDanger.safe(world,point): return false
	for y in range(point.y,point.y+6):
		for x in range(point.x,point.x+8):
			var tile: Vector2i = Vector2i(x,y)
			if world.terrain_state.get("starter_field",[]).has(tile) or world.fields.any(func(f:Dictionary)->bool:return f.x==x and f.y==y): return false
	return ColonyConstruction.lodge_error(world,point).is_empty()

static func lodge_target(world: ColonyWorld, previous: Array = []) -> Array:
	# Keep a valid suggestion stable as nearby terrain changes. Revalidate its
	# actual footprint, route and danger; this cache never bypasses placement.
	if previous.size()==2 and lodge_target_valid(world,Vector2i(previous[0],previous[1])): return previous.duplicate()
	# Scan in distance/tile order and stop at the first fully valid footprint.
	var home: Vector2i = _home(world)
	for distance in range(255):
		for y in range(maxi(0,home.y-distance),mini(122,home.y+distance)+1):
			var dx: int = distance-absi(y-home.y)
			for x in ([home.x] if dx==0 else [home.x-dx,home.x+dx]):
				if x<0 or x>120: continue
				if lodge_target_valid(world,Vector2i(x,y)): return [x,y]
	return []

static func card(world: ColonyWorld, state: Dictionary, suggestions: Dictionary = {}) -> Dictionary:
	if not state.enabled or state.active.is_empty(): return {}
	if suggestions.get("world",0)!=world.get_instance_id():
		suggestions.clear();suggestions["world"]=world.get_instance_id()
	var id: String = state.active
	var result: Dictionary = {"id":id,"title":TITLES[id],"text":"","target":[],"entity":0,"action":id,"prerequisite":"","gesture":"Tap"}
	var target: Dictionary = {}
	var mira: Dictionary = world.find(world.citizens,1)
	match id:
		"follow":
			result.text="Tap a resident, then Follow, to watch the work from their side."
			target=_nearest(world,world.citizens,func(c:Dictionary)->bool:return not c.away and not c.death_recorded and not c.departed)
			if not mira.is_empty() and not mira.away and not mira.death_recorded and not mira.departed: target=mira
			if target.is_empty(): result.prerequisite="No resident is home to follow; wait for a traveler to return."
		"forage":
			result.text="Paint berries in Work, confirm, and resume until a worker delivers real berries home.";result.gesture="Drag, then Confirm"
			target=_nearest(world,world.resources,func(r:Dictionary)->bool:return r.definition=="berry_bush" and r.remaining>0 and world.accessible(Vector2i(r.x,r.y)) and ColonyDanger.safe(world,Vector2i(r.x,r.y)))
			if target.is_empty(): result.prerequisite="No safe ripe berry bush is available; clear a route or wait for berries to regrow outside Winter."
		"lodge":
			result.text="Place the suggested sleeping lodge: four beds and a door finish before the last wall, for W73 F8.";result.gesture="Place, then Confirm"
			result.target=lodge_target(world,suggestions.get("lodge",[]))
			suggestions["lodge"]=result.target.duplicate()
			if result.target.is_empty(): result.prerequisite="Clear a safe, empty 8 by 6 footprint outside the starter field."
		"cook":
			result.text="Inspect the hearth, then resume at 1x until a cook turns four raw food and one wood into two meals."
			target=_nearest(world,world.structures,func(s:Dictionary)->bool:return s.health>0 and s.definition=="hearth" and world.accessible(Vector2i(s.x,s.y)) and not ColonyFire.burning(world,"structure",s.id))
			if target.is_empty(): result.prerequisite="Build a hearth and provide four raw food units and one wood."
		"field":
			result.text="Paint eight turnip tiles and resume until all eight are planted; the food forecast shows their expected harvest.";result.gesture="Drag eight tiles"
			result.target=field_target(world)
			if result.target.is_empty(): result.prerequisite="Clear eight connected open soil tiles, outside structures, stockpiles and animal pens."
			if ColonyAgriculture.season(world.tick) not in world.definitions.crops.turnip.seasons: result.prerequisite="Turnips cannot be sown this season; wait for their listed growing season."
		"cooking_priority":
			result.text="Open Mira's Work preferences, confirm Cooking is First, then resume until her next eligible assignment is Cooking."
			target=mira
			if target.is_empty() or target.death_recorded or target.departed:
				result.prerequisite="Mira is no longer in this settlement; skip this lesson and use Work preferences for another resident.";target={}
			elif target.away: result.prerequisite="Mira is on expedition; wait for her to return before watching a Cooking assignment.";target={}
		"forecast": result.text="Open and pin the food forecast to keep stored portions, daily demand and the next harvest visible."
		"winter": result.text="Open the weather forecast and inspect the coming cold before preparing hearth fuel and stored food."
		"injury":
			result.text="Open Care for an injured resident to inspect the injury and the next treatment action."
			target=_nearest(world,world.citizens,func(c:Dictionary)->bool:return not c.away and not c.death_recorded and not c.departed and (c.downed or c.health<100))
			if target.is_empty(): result.prerequisite="No resident currently needs this injury lesson; Care remains available in People."
		"research":
			result.text="Choose one available research project; a staffed research desk turns real work into progress."
			target=_nearest(world,world.structures,func(s:Dictionary)->bool:return s.health>0 and s.definition=="research_desk" and world.accessible(Vector2i(s.x,s.y)) and not ColonyFire.burning(world,"structure",s.id))
			if target.is_empty(): result.prerequisite="Build a research desk and enable Research work."
		"expedition": result.text="Open Expeditions, choose a site and party, review its food and readiness, then start packing real supplies."
	if not target.is_empty(): result.entity=target.id;result.target=[target.x,target.y]
	return result

static func field_target(world: ColonyWorld) -> Array:
	var home: Vector2i = _home(world)
	var planned: Dictionary = ColonyAgriculture.planned_tiles(world)
	# A lodge will roof its interior even where there is no furniture blueprint.
	# Keep the following outdoor-crop lesson outside that future room as well.
	for group in world.construction_state.groups:
		if group.kind!="lodge": continue
		var bounds: Rect2i
		var started: bool = false
		for id in group.members:
			var job: Dictionary = world.find(world.jobs,id)
			if job.is_empty() or job.state=="Canceled": continue
			for tile in world.footprint(job):
				bounds=bounds.merge(Rect2i(tile,Vector2i.ONE)) if started else Rect2i(tile,Vector2i.ONE)
				started=true
		if started:
			for y in range(bounds.position.y,bounds.end.y):
				for x in range(bounds.position.x,bounds.end.x): planned[Vector2i(x,y)]=true
	for distance in range(255):
		for y in range(maxi(0,home.y-distance),mini(126,home.y+distance)+1):
			var dx: int = distance-absi(y-home.y)
			for x in ([home.x] if dx==0 else [home.x-dx,home.x+dx]):
				if x<0 or x>124: continue
				var clear: bool = true
				for yy in range(y,y+2):
					for xx in range(x,x+4):
						var tile: Vector2i = Vector2i(xx,yy)
						if planned.has(tile) or not world.walkable(tile) or not world.accessible(tile) or world.roofed(tile) or not ColonyDanger.safe(world,tile) or world.structures.any(func(s:Dictionary)->bool:return world.footprint(s).has(tile)) or world.stores.any(func(s:Dictionary)->bool:return s.tiles.has(tile)) or world.domestic_state.pens.any(func(p:Dictionary)->bool:return p.tiles.has(tile)) or world.fields.any(func(f:Dictionary)->bool:return f.x==xx and f.y==yy): clear=false;break
					if not clear: break
				if clear: return [x,y]
	return []
