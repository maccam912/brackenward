class_name LargeColonyPolicy
extends ColonyPolicy
## Ordinary player commands only; grow naturally across the four-day offer cadence.
var extra_grow_origins: Array[Vector2i]=[]

func _init() -> void:
	super("twenty_colony")
	resident_target=20;lodge_target=5

func plan(world: ColonyWorld) -> void:
	if last_policy==world.tick: return
	var population: int=ColonyPopulation.living(world)
	# Reserve/build the housing before expanding the outdoor fields into it.
	turnip_target=48 if population>8 else 24
	barley_target=128 if population>8 else 64
	cavecap_target=72 if population>=8 else 24
	super.plan(world)
	if population>=8: _extra_grow_room(world)
	_unblock_storage(world)

func _reserved_plan(point: Vector2i) -> bool:
	if super(point): return true
	return extra_grow_origins.any(func(origin:Vector2i)->bool:return Rect2i(origin,Vector2i(8,6)).has_point(point))

func _planned_approach(point: Vector2i) -> bool:
	if super(point): return true
	return extra_grow_origins.any(func(origin:Vector2i)->bool:return point==origin+Vector2i(3,6))

func _extra_grow_room(world: ColonyWorld) -> void:
	if grow_origin.x<0 or extra_grow_origins.size()>=2 or not world.researched.has("storecraft") or not world.roofed(grow_origin+Vector2i(1,1)): return
	var origin: Vector2i=_empty_room(world,3)
	if origin.x<0: return
	issue(world,"build",{"definition":"door","x":origin.x+3,"y":origin.y+5,"rotation":0})
	var walls: Array[Vector2i]=[]
	for y in range(6):
		for x in range(8):
			if (x in [0,7] or y in [0,5]) and Vector2i(x,y)!=Vector2i(3,5): walls.append(origin+Vector2i(x,y))
	issue(world,"build_area",{"definition":"wood_wall","tiles":walls})
	extra_grow_origins.append(origin)

func _fields(world: ColonyWorld, crop: String, desired: int, roof: bool) -> void:
	if not roof: super(world,crop,desired,roof);return
	var first: Vector2i=grow_origin
	var origins: Array[Vector2i]=[first];origins.append_array(extra_grow_origins)
	for origin in origins:
		if origin.x<0 or not world.roofed(origin+Vector2i(1,1)): continue
		grow_origin=origin;super(world,crop,desired,true)
	grow_origin=first

func _orders(world: ColonyWorld, residents: int) -> void:
	super(world,residents)
	var desired: int=mini(80,maxi(16,((residents+3)/4)*16))
	for station in world.structures:
		if station.health<=0 or station.definition!="hearth": continue
		var current: Array=world.production_state.orders.filter(func(o:Dictionary)->bool:return o.enabled and o.station==station.id and o.recipe=="cook_meals")
		if current.is_empty() or current.any(func(o:Dictionary)->bool:return o.mode=="Maintain" and o.quantity>=desired): continue
		if world.pending_commands.any(func(c:Dictionary)->bool:return c.kind=="recipe_order" and c.args.target==station.id and c.args.definition=="cook_meals"): continue
		for order in current:
			# A paused batch still occupies its station. Cancel through ordinary
			# work controls before replacing this small-household recipe policy.
			for job in world.unfinished_jobs():
				if job.kind=="craft" and job.order==order.id: issue(world,"cancel",{"target":job.id})
			issue(world,"order_enabled",{"target":order.id,"enabled":false})
		issue(world,"recipe_order",{"target":station.id,"definition":"cook_meals","mode":"Maintain","value":desired,"priority":2,"filters":["grain","vegetable","berry","mushroom"]})

func resume(world: ColonyWorld, previous_decisions: Array) -> void:
	super(world,previous_decisions)
	var origins: Array[Vector2i]=[]
	for entry in world.command_trace:
		var command: Dictionary=entry.command
		if world.receipts.get(command.id)=="accepted" and command.kind=="build" and command.args.definition=="door":
			var origin: Vector2i=Vector2i(command.args.x-3,command.args.y-5)
			if not origins.has(origin): origins.append(origin)
	if not origins.is_empty():
		grow_origin=origins[0];extra_grow_origins.assign(origins.slice(1))
