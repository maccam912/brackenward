class_name ColonyPolicy
extends RefCounted
## Deterministic planning through public commands only. No state/material grants.
var scenario: String
var initialized: bool = false
var lodge_origins: Array[Vector2i] = []
var grow_origin: Vector2i = Vector2i(-1,-1)
var decisions: Array[Dictionary] = []
var last_policy: int = -1
const RESEARCH: Array[String] = ["storecraft","farming","woodcraft","weaving","masonry","herbalism","trailcraft","commonlife","metalwork","signalcraft","valley_charter"]

func _init(selected: String) -> void:
	scenario=selected

func resume(world: ColonyWorld, previous_decisions: Array) -> void:
	initialized=true
	last_policy=world.tick
	decisions.assign(previous_decisions)
	# Recover the planner's designated rooms from the accepted command evidence.
	for entry in world.command_trace:
		var command: Dictionary = entry.command
		if world.receipts.get(command.id)!="accepted": continue
		if command.kind=="lodge": lodge_origins.append(Vector2i(command.args.x,command.args.y))
		elif command.kind=="build" and command.args.definition=="door": grow_origin=Vector2i(command.args.x-3,command.args.y-5)

func issue(world: ColonyWorld, kind: String, args: Dictionary = {}) -> void:
	var id: int = world.queue_command(kind,args)
	decisions.append({"tick":world.tick,"id":id,"kind":kind,"args":args.duplicate(true)})

func plan(world: ColonyWorld) -> void:
	if last_policy==world.tick: return
	last_policy=world.tick
	if not initialized:
		initialized=true
		issue(world,"preference",{"citizen":1,"category":"Cooking","value":3})
		issue(world,"preference",{"citizen":3,"category":"Growing","value":3})
		issue(world,"preference",{"citizen":3,"category":"Gathering","value":2})
		issue(world,"preference",{"citizen":4,"category":"Research","value":3})
		_fields(world,"turnip",12,false)
		issue(world,"research_select",{"definition":"storecraft"})
		return
	var residents: Array = world.citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed)
	if residents.is_empty(): return
	_defense(world,residents)
	var forecast: Dictionary = FoodForecast.calculate(world)
	_gather(world,"tree",120,2)
	if forecast.ticks<21600:
		_gather(world,"berry_bush",32,2,24)
		_gather(world,"mushroom_patch",24,2,24)
	var long_campaign: bool = scenario!="first_week"
	if long_campaign: _gather(world,"stone_node",100,2)
	if not _present(world,"table"):
		_build(world,"table");return
	if lodge_origins.is_empty():
		var origin: Vector2i = _empty_room(world)
		if origin.x>=0:
			issue(world,"lodge",{"x":origin.x,"y":origin.y});lodge_origins.append(origin)
		return
	if not _present(world,"research_desk"):
		_build(world,"research_desk");return
	_orders(world,residents.size())
	if long_campaign: _finished_research_staffing(world)
	if world.production_state.project.is_empty():
		for research in RESEARCH:
			if world.researched.has(research) or not world.definitions.research[research].prerequisites.all(func(id:String)->bool:return world.researched.has(id)): continue
			issue(world,"research_select",{"definition":research});break
	if world.researched.has("storecraft") and not _present(world,"granary"):
		_build(world,"granary");return
	if not long_campaign: return
	if world.researched.has("farming"):
		if ColonyAgriculture.season(world.tick) in [0,1]: _fields(world,"barley",64,false)
		_fields(world,"flax",12,false)
		_fields(world,"turnip",24,false)
	if world.researched.has("storecraft") and grow_origin.x<0:
		grow_origin=_empty_room(world)
		if grow_origin.x>=0:
			issue(world,"build",{"definition":"door","x":grow_origin.x+3,"y":grow_origin.y+5,"rotation":0})
			var walls: Array[Vector2i] = []
			for y in range(6):
				for x in range(8):
					if (x in [0,7] or y in [0,5]) and Vector2i(x,y)!=Vector2i(3,5): walls.append(grow_origin+Vector2i(x,y))
			issue(world,"build_area",{"definition":"wood_wall","tiles":walls})
		return
	if grow_origin.x>=0 and world.roofed(grow_origin+Vector2i(1,1)):
		_fields(world,"cavecap",24,true)
	if world.researched.has("weaving") and not _present(world,"loom"):
		_build(world,"loom");return
	if lodge_origins.size()<2 and world.researched.has("farming"):
		var origin: Vector2i = _empty_room(world)
		if origin.x>=0:
			issue(world,"lodge",{"x":origin.x,"y":origin.y});lodge_origins.append(origin)
		return
	for origin in lodge_origins:
		var point: Vector2i = origin+Vector2i(1,3)
		if world.roofed(point) and not world.structures.any(func(s:Dictionary)->bool:return s.definition=="hearth" and s.x==point.x and s.y==point.y) and not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="build" and j.definition=="hearth" and j.x==point.x and j.y==point.y and j.state not in ["Complete","Canceled"]):
			if world.placement_error("hearth",point,0).is_empty(): issue(world,"build",{"definition":"hearth","x":point.x,"y":point.y,"rotation":0})
	if world.researched.has("masonry") and not _present(world,"cellar"):
		_build(world,"cellar");return
	if residents.size()<8:
		for offer in world.population_state.offers:
			if offer.state=="Offered" and ColonyPopulation.acceptance(world,offer).error.is_empty(): issue(world,"newcomer",{"target":offer.id,"accept":true});break
	for person in residents:
		if person.equipment.cloak.is_empty() and world.available("cloak")>0: issue(world,"equip",{"target":person.id,"slot":"cloak","item":"cloak"})
	for resource in world.resources:
		if resource.definition=="tree" and resource.remaining==0 and not ColonyNature.tree(world,resource.id).planted and ColonyNature.plantable(world,Vector2i(resource.x,resource.y)) and not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.target==resource.id and j.kind=="plant_tree" and j.state not in ["Complete","Canceled"]):
			issue(world,"replant_tree",{"target":resource.id});break
	if scenario=="vegetarian_charter": _charter(world)

func _finished_research_staffing(world: ColonyWorld) -> void:
	if not RESEARCH.all(func(id:String)->bool:return world.researched.has(id)): return
	var researcher: Dictionary = world.find(world.citizens,4)
	if researcher.is_empty() or researcher.death_recorded or researcher.departed: return
	if researcher.preferences.Gathering!=3: issue(world,"preference",{"citizen":researcher.id,"category":"Gathering","value":3})
	if researcher.preferences.Research!=2: issue(world,"preference",{"citizen":researcher.id,"category":"Research","value":2})

func _present(world: ColonyWorld, definition: String) -> bool:
	return world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition==definition) or world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="build" and j.definition==definition and j.state not in ["Complete","Canceled"])

func _cart(world: ColonyWorld) -> Vector2i:
	var cart: Dictionary = ColonyTrade.cart(world)
	return Vector2i(cart.x,cart.y)

func _reserved_plan(point: Vector2i) -> bool:
	for origin in lodge_origins+([grow_origin] if grow_origin.x>=0 else []):
		if Rect2i(origin,Vector2i(8,6)).has_point(point): return true
	return false

func _build(world: ColonyWorld, definition: String) -> bool:
	var data: Dictionary = world.definitions.buildings[definition]
	if data.unlock!="initial" and not world.researched.has(data.unlock): return false
	var cart: Vector2i = _cart(world)
	var protected_seats: Array[Vector2i] = []
	for table in world.structures:
		if table.definition=="table" and table.health>0: protected_seats.append_array(ColonySocial.seats_for(world,table))
	for radius in range(3,25):
		for y in range(maxi(1,cart.y-radius),mini(125,cart.y+radius+1)):
			for x in range(maxi(1,cart.x-radius),mini(125,cart.x+radius+1)):
				if absi(x-cart.x)+absi(y-cart.y)!=radius: continue
				var point: Vector2i = Vector2i(x,y)
				var area: Array[Vector2i] = world.footprint({"definition":definition,"x":x,"y":y,"rotation":0})
				if area.any(_reserved_plan) or area.any(func(p:Vector2i)->bool:return world.terrain_state.starter_field.has(p) or protected_seats.has(p)) or not world.placement_error(definition,point,0).is_empty(): continue
				if definition=="table":
					var seats: Array[Vector2i] = ColonySocial.seats_for(world,{"definition":definition,"x":x,"y":y,"rotation":0})
					if seats.any(func(p:Vector2i)->bool:return not world.walkable(p) or not world.accessible(p) or _reserved_plan(p) or world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="build" and j.state not in ["Complete","Canceled"] and world.footprint(j).has(p))): continue
				issue(world,"build",{"definition":definition,"x":x,"y":y,"rotation":0});return true
	return false

func _empty_room(world: ColonyWorld) -> Vector2i:
	var cart: Vector2i = _cart(world)
	var occupied: Dictionary = {}
	for structure in world.structures:
		for point in world.footprint(structure): occupied[point]=true
		if structure.definition=="table" and structure.health>0:
			for point in ColonySocial.seats_for(world,structure): occupied[point]=true
	for job in world.jobs:
		if job.kind=="build" and job.state not in ["Complete","Canceled"]:
			for point in world.footprint(job): occupied[point]=true
	for field in world.fields: occupied[Vector2i(field.x,field.y)]=true
	for command in world.pending_commands:
		if command.kind=="field":
			for point in command.args.tiles: occupied[point]=true
	for point in world.terrain_state.starter_field: occupied[point]=true

	for radius in range(5,31):
		for y in range(maxi(1,cart.y-radius),mini(121,cart.y+radius+1)):
			for x in range(maxi(1,cart.x-radius),mini(119,cart.x+radius+1)):
				if absi(x+4-cart.x)+absi(y+3-cart.y)!=radius: continue
				var valid: bool = true
				for yy in range(y,y+6):
					for xx in range(x,x+8):
						var point: Vector2i = Vector2i(xx,yy)
						if occupied.has(point) or _reserved_plan(point) or not world.walkable(point) or world.is_flooded(point) or world.elevation(point)<2: valid=false;break
					if not valid: break
				if valid and ColonyConstruction.lodge_error(world,Vector2i(x,y)).is_empty(): return Vector2i(x,y)
	return Vector2i(-1,-1)

func _fields(world: ColonyWorld, crop: String, desired: int, roof: bool) -> void:
	var definition: Dictionary = world.definitions.crops[crop]
	if definition.unlock!="initial" and not world.researched.has(definition.unlock): return
	if not definition.seasons.has(ColonyAgriculture.season(world.tick)): return
	var count: int = world.fields.filter(func(f:Dictionary)->bool:return f.crop==crop).size()
	if count>=desired: return
	var points: Array[Vector2i] = []
	var candidates: Array[Vector2i] = []
	if roof:
		if grow_origin.x<0: return
		for y in range(grow_origin.y+1,grow_origin.y+5):
			for x in range(grow_origin.x+1,grow_origin.x+7): candidates.append(Vector2i(x,y))
	else:
		candidates.assign(world.terrain_state.starter_field)
		var cart: Vector2i = _cart(world)
		for radius in range(5,26):
			for y in range(maxi(1,cart.y-radius),mini(127,cart.y+radius+1)):
				for x in range(maxi(1,cart.x-radius),mini(127,cart.x+radius+1)):
					var point: Vector2i = Vector2i(x,y)
					if absi(x-cart.x)+absi(y-cart.y)==radius and not candidates.has(point): candidates.append(point)
	for point in candidates:
		if count+points.size()>=desired: break
		if (not roof and _reserved_plan(point)) or not world.walkable(point) or world.roofed(point)!=roof or world.elevation(point)<2 or world.fields.any(func(f:Dictionary)->bool:return f.x==point.x and f.y==point.y) or world.structures.any(func(s:Dictionary)->bool:return world.footprint(s).has(point)) or world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="build" and j.state not in ["Complete","Canceled"] and world.footprint(j).has(point)) or world.stores.any(func(s:Dictionary)->bool:return s.tiles.has(point)): continue
		# Different crop designations queued together cannot overlap.
		if world.pending_commands.any(func(c:Dictionary)->bool:return c.kind=="field" and c.args.tiles.has(point)): continue
		points.append(point)
	if not points.is_empty(): issue(world,"field",{"crop":crop,"tiles":points})

func _gather(world: ColonyWorld, definition: String, reserve: int, tasks: int, limit: int = 64) -> void:
	var item: String = world.definitions.resources[definition].item
	if world.available(item)>=reserve: return
	var active: int = world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.kind=="gather" and j.state not in ["Complete","Canceled"] and world.find(world.resources,j.target).get("definition")==definition).size()
	if active>=tasks: return
	var cart: Vector2i = _cart(world)
	var candidates: Array = world.resources.filter(func(r:Dictionary)->bool:return r.definition==definition and r.remaining>0 and not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.target==r.id and j.kind=="gather" and j.state not in ["Complete","Canceled"]))
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var aa: int = absi(a.x-cart.x)+absi(a.y-cart.y);var bb: int = absi(b.x-cart.x)+absi(b.y-cart.y)
		return aa<bb or (aa==bb and a.id<b.id))
	for resource in candidates:
		if active>=tasks: break
		var point: Vector2i = Vector2i(resource.x,resource.y)
		var goals: Array[Vector2i] = world._perimeter([point])
		var reachable: bool = false
		for goal in goals:
			if absi(goal.x-cart.x)+absi(goal.y-cart.y)>limit: continue
			var path: Array = ColonyNavigation.path(cart,goal,func(p:Vector2i)->bool:return world.walkable(p) and ColonyDanger.safe(world,p),world.can_step)
			if (goal==cart or not path.is_empty()) and path.size()<=limit: reachable=true;break
		if reachable: issue(world,"gather",{"target":resource.id});active+=1

func _orders(world: ColonyWorld, residents: int) -> void:
	for station in world.structures:
		if station.health<=0: continue
		if station.definition=="hearth" and not world.production_state.orders.any(func(o:Dictionary)->bool:return o.station==station.id):
			issue(world,"recipe_order",{"target":station.id,"definition":"cook_meals","mode":"Maintain","value":maxi(8,residents*4),"priority":2,"filters":["grain","vegetable","berry","mushroom"]})
		if scenario=="vegetarian_charter" and station.definition=="hearth" and world.researched.has("trailcraft") and not world.production_state.orders.any(func(o:Dictionary)->bool:return o.recipe=="dry_rations"):
			issue(world,"recipe_order",{"target":station.id,"definition":"dry_rations","mode":"Maintain","value":48,"priority":1,"filters":["grain","vegetable","berry"]})
		if station.definition=="loom":
			for recipe in ["weave_cloth","sew_cloak"]:
				if not world.production_state.orders.any(func(o:Dictionary)->bool:return o.station==station.id and o.recipe==recipe): issue(world,"recipe_order",{"target":station.id,"definition":recipe,"mode":"Maintain","value":12 if recipe=="weave_cloth" else 4,"priority":2,"filters":[]})

func _defense(world: ColonyWorld, residents: Array) -> void:
	var raid: Dictionary = ColonyDefense.active(world)
	if raid.is_empty(): return
	if raid.state=="Announced":
		var needed: int = raid.budget*8
		var payment: Dictionary = {}
		for item in ["wood","stone","clay","fiber"]:
			var value: int = world.definitions.items[item].barter_value
			var available: int = maxi(0,world.available(item)-(20 if item=="wood" else 0))
			var count: int = mini(available,(needed+value-1)/value)
			if count>0: payment[item]=count;needed-=count*value
			if needed<=0: break
		if needed<=0: issue(world,"raid_offer",{"target":raid.id,"pay":payment})
	elif raid.state=="Active" and not residents.any(func(c:Dictionary)->bool:return c.drafted):
		var able: Array = residents.filter(func(c:Dictionary)->bool:return not c.away and not c.downed and c.health>40 and not c.equipment.weapon.is_empty()).map(func(c:Dictionary)->int:return c.id)
		if not able.is_empty(): issue(world,"draft",{"citizens":able,"rally":_cart(world),"stand_fast":false})
	elif raid.state=="Retreating": issue(world,"stand_down")

func _charter(world: ColonyWorld) -> void:
	if world.charter_state.ending and not world.charter_state.continued:
		issue(world,"continue_settlement")
	if _unblock_storage(world): return
	_expedition(world)
	if ColonyCharter.seats(world).size()<8 and not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="build" and j.definition=="table" and j.state not in ["Complete","Canceled"]):
		_build(world,"table")
	# Higher dependencies stay visible when this conservative planner cannot supply them.
	for definition in ["workbench","brick_kiln","charcoal_kiln","smelter","loom"]:
		if not _present(world,definition) and _build(world,definition): return
	_gather(world,"clay_bank",100,2);_gather(world,"iron_seam",30,2)
	for station in world.structures:
		var recipes: Dictionary = {"brick_kiln":"fire_brick","charcoal_kiln":"burn_charcoal","smelter":"smelt_iron"}
		if recipes.has(station.definition) and not world.production_state.orders.any(func(o:Dictionary)->bool:return o.station==station.id): issue(world,"recipe_order",{"target":station.id,"definition":recipes[station.definition],"mode":"Maintain","value":48,"priority":2,"filters":[]})
	if not _present(world,"beacon"): _build(world,"beacon")
	if world.charter_state.get("last_supper",0)==0 and ColonyCharter.supper_error(world).is_empty(): issue(world,"start_supper")
	if ColonyCharter.ceremony_error(world).is_empty(): issue(world,"start_ceremony")

func _expedition(world: ColonyWorld) -> void:
	var trip: Dictionary = ColonyRegion.active(world)
	if not trip.is_empty():
		var data: Dictionary = ColonyRegion.definition_data(world,trip.args.definition,trip.args.pickup)
		var packed: Dictionary = world.find(world.jobs,trip.pack_job)
		var goods: Dictionary = ColonyRegion.cargo(world,trip)
		var expired: bool = packed.get("state")=="Complete" and trip.quote.inputs.keys().any(func(item:Variant)->bool:return goods.get(item,0)<trip.quote.inputs[item])
		if trip.state in ["Preparing","Ready"] and (expired or not data.get("seasons",[0,1,2,3]).has(ColonyAgriculture.season(world.tick))):
			issue(world,"expedition_cancel",{"target":trip.id})
		elif trip.state in ["Preparing","Ready"] and ColonyRegion.ready(world,trip).is_empty(): issue(world,"expedition_depart",{"target":trip.id,"unprepared":false})
		elif trip.state=="Decision": issue(world,"expedition_choice",{"target":trip.id,"definition":"continue"})
		elif trip.state=="Collect": issue(world,"expedition_collect",{"target":trip.id,"keep":ColonyRegion.default_keep(world,trip)})
		return
	if world.citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed and not c.away).size()<8 or FoodForecast.calculate(world).ticks<21600: return
	for destination in ["berry_hollow","broken_causeway"]:
		var data: Dictionary = world.definitions.expeditions[destination]
		if world.region_state.progress[destination].returned_at>0 or not data.get("seasons",[0,1,2,3]).has(ColonyAgriculture.season(world.tick)): continue
		var skill: String = data.skill
		var travelers: Array = world.citizens.filter(func(c:Dictionary)->bool:return not c.away and not c.downed and not c.death_recorded and not c.departed and c.health>=70 and c.rest>=500 and c.fullness>=500)
		travelers.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.skills[skill]>b.skills[skill] or (a.skills[skill]==b.skills[skill] and a.id<b.id))
		for count in range(mini(4,travelers.size()),1,-1):
			var args: Dictionary = {"definition":destination,"party":travelers.slice(0,count).map(func(c:Dictionary)->int:return c.id),"goats":[],"cargo":{},"feed":"grain","pen":0,"variant":0,"pickup":false}
			var quote: Dictionary = ColonyRegion.preview(world,args)
			if quote.error.is_empty() and quote.shortfall==0 and quote.home_forecast.ticks>=21600:
				issue(world,"expedition_prepare",args)
				return

func _unblock_storage(world: ColonyWorld) -> bool:
	if not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.state=="Blocked" and j.reason.begins_with("No storage space")): return false
	var designated: int = 0
	var occupied: Dictionary = {}
	for store in world.stores:
		if world.find(world.structures,store.id).is_empty(): designated+=store.tiles.size()
		for point in store.tiles: occupied[point]=true
	if designated>=32: return false
	for structure in world.structures:
		for point in world.footprint(structure): occupied[point]=true
		if structure.definition=="table":
			for point in ColonySocial.seats_for(world,structure): occupied[point]=true
	for resource in world.resources: occupied[Vector2i(resource.x,resource.y)]=true
	for field in world.fields: occupied[Vector2i(field.x,field.y)]=true
	for pen in world.domestic_state.pens:
		for point in pen.tiles: occupied[point]=true
	for job in world.unfinished_jobs():
		if job.kind=="build":
			for point in world.footprint(job): occupied[point]=true
	for point in world.terrain_state.starter_field: occupied[point]=true
	var cart: Vector2i = _cart(world)
	for radius in range(6,31):
		for y in range(maxi(1,cart.y-radius),mini(123,cart.y+radius+1)):
			for x in range(maxi(1,cart.x-radius),mini(123,cart.x+radius+1)):
				if absi(x+2-cart.x)+absi(y+2-cart.y)!=radius: continue
				var tiles: Array[Vector2i] = []
				for yy in range(y,y+4):
					for xx in range(x,x+4):
						var point: Vector2i = Vector2i(xx,yy)
						if occupied.has(point) or _reserved_plan(point) or not world.walkable(point) or not world.accessible(point) or world.is_flooded(point) or not ColonyDanger.safe(world,point): break
						tiles.append(point)
					if tiles.size()!=(yy-y+1)*4: break
				if tiles.size()==16:
					issue(world,"stockpile",{"tiles":tiles});return true
	return false
