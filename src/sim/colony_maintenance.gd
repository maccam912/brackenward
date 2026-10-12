class_name ColonyMaintenance
extends RefCounted
const LEDGER_BUCKETS: Array = ["produced","recovered","traded_in","expedition_gain","consumed","spoiled","lost","traded_out","looted"]

static func dominant(definition: Dictionary) -> String:
	var items: Array = definition.materials.keys()
	items.sort_custom(func(a:String,b:String)->bool:return definition.materials[a]>definition.materials[b] if definition.materials[a]!=definition.materials[b] else a<b)
	return "" if items.is_empty() else items[0]

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	var structure: Dictionary = world.find(world.structures,args.target)
	if structure.is_empty() or structure.definition=="supply_cart": return "Choose a structure; the supply cart cannot be demolished"
	var definition: Dictionary = world.definitions.buildings[structure.definition]
	if kind=="rebuild":
		if structure.health>0: return "Structure still exists: repair it instead"
		return world._command({"kind":"build","args":{"definition":structure.definition,"x":structure.x,"y":structure.y,"rotation":structure.rotation}})
	if structure.health<=0: return "Structure is gone: rebuild it"
	if world.jobs.any(func(j:Dictionary)->bool:return j.target==structure.id and j.kind in ["repair","demolish","move_furniture"] and j.state not in ["Complete","Canceled"]): return "Maintenance already marked"
	var missing: int = definition.health-structure.health
	if kind=="repair" and missing<=0: return "Already at full health"
	var job: Dictionary = world._job(kind,"Building","Build",structure.id,Vector2i(structure.x,structure.y),missing*100 if kind=="repair" else ((definition.work_milli+1999)/2000)*1000)
	job.definition=structure.definition;job.rotation=structure.rotation
	if kind=="repair": job.amount=missing;job.inputs={dominant(definition):(missing+49)/50}
	return "accepted"

static func reserve(world: ColonyWorld, job: Dictionary) -> bool:
	var structure: Dictionary = world.find(world.structures,job.target)
	if job.kind=="move_furniture":
		var error: String = world.placement_error(job.definition,Vector2i(job.care_goal[0],job.care_goal[1]),job.rotation,job.id,job.target)
		if not error.is_empty(): return world._block(job,error)
		if job.memo.phase=="rebuild": return true
	if structure.is_empty() or structure.health<=0: return world._block(job,"Structure no longer exists")
	return true

static func complete(world: ColonyWorld, job: Dictionary) -> void:
	var structure: Dictionary = world.find(world.structures,job.target)
	if job.kind=="repair":
		structure.health=mini(world.definitions.buildings[structure.definition].health,structure.health+job.amount)
		return
	var definition: Dictionary = world.definitions.buildings[structure.definition]
	for item in definition.materials:
		var count: int = definition.materials[item]/2
		if count>0:
			world._make_stack(item,count,"ground",0,Vector2i(structure.x,structure.y),false);world._record("recovered",item,count)
	destroy(world,structure,job.id)

static func destroy(world: ColonyWorld, structure: Dictionary, caller: int = 0, temporary: bool = false) -> void:
	if structure.definition=="supply_cart": return
	structure.health=0
	if not temporary: structure.cooking=false
	for job in world.jobs:
		if job.id!=caller and job.target==structure.id and job.state not in ["Complete","Canceled"]:
			world._release(job,not temporary)
			if temporary:
				for held in world.stacks:
					if held.location=="escrow" and held.owner==job.id: held.location="ground";held.owner=0;held.job=0
				world._block(job,"Station being moved: retained work resumes after rebuilding")
	for order in world.production_state.orders:
		if order.station==structure.id and not temporary: order.enabled=false
	for citizen in world.citizens:
		if citizen.bed==structure.id: citizen.bed=0
	for stack in world.stacks:
		if stack.owner==structure.id and stack.location in ["store","output","animal_feed"]: stack.location="ground";stack.owner=0
	if structure.fuel>0:
		world._make_stack("wood",structure.fuel,"ground",0,Vector2i(structure.x,structure.y),false);structure.fuel=0
	for store in world.stores.duplicate():
		if store.id==structure.id: world.stores.erase(store)
	if structure.definition=="bridge" and world.generator_version>0: world.terrain_state.bridges.erase(Vector2i(structure.x,structure.y))
	world.record_indexes.clear();world.navigation_dirty=true;world.rooms_dirty=true;world.reachability_dirty=true;world.danger_cache_tick=-1

const MOVABLE: Array = ["bedroll","bed","table","hearth","rack","workbench","loom","herbal_bench","research_desk","bell","garden_bench","memorial"]

static func move_command(world: ColonyWorld, args: Dictionary) -> String:
	var structure: Dictionary = world.find(world.structures,args.target)
	if structure.is_empty() or structure.health<=0 or structure.definition not in MOVABLE: return "This structure requires demolition and rebuilding; only listed furniture can move"
	if structure.x==args.x and structure.y==args.y and structure.rotation==args.rotation: return "Choose another position or rotation"
	if world.jobs.any(func(j:Dictionary)->bool:return j.target==structure.id and j.kind in ["repair","demolish","move_furniture"] and j.state not in ["Complete","Canceled"]): return "Maintenance already marked"
	var error: String = world.placement_error(structure.definition,Vector2i(args.x,args.y),args.rotation,0,structure.id)
	if not error.is_empty(): return error
	var store: Dictionary = world.find(world.stores,structure.id)
	var job: Dictionary = world._job("move_furniture","Building","Build",structure.id,Vector2i(structure.x,structure.y),world.definitions.buildings[structure.definition].work_milli)
	job.definition=structure.definition;job.rotation=args.rotation;job.care_goal=[args.x,args.y]
	job.memo={"phase":"dismantle","cooking":structure.cooking,"health":structure.health,"user":structure.user,"store":store.duplicate(true)}
	return "accepted"

static func move_footprint(world: ColonyWorld, job: Dictionary) -> Array[Vector2i]:
	return world.footprint({"definition":job.definition,"rotation":job.rotation,"x":job.care_goal[0],"y":job.care_goal[1]})

static func move_dismantle(world: ColonyWorld, citizen: Dictionary, job: Dictionary) -> void:
	citizen.activity="Dismantling "+job.definition+" for a physical move"
	if job.state=="Moving":
		if world._walk(citizen,Vector2i(job.work_x,job.work_y)): job.state="Working"
		return
	if job.state!="Working": return
	var limit: int = job.required/2
	var work: int = mini(world._rate(citizen,job),limit-job.work)
	job.work += work;job.pending_xp[citizen.id]=job.pending_xp.get(citizen.id,0)+work
	if job.work<limit: return
	var error: String = world.placement_error(job.definition,Vector2i(job.care_goal[0],job.care_goal[1]),job.rotation,job.id,job.target)
	if not error.is_empty(): world._release(job,false);world._block(job,"Move destination changed: "+error);return
	var structure: Dictionary = world.find(world.structures,job.target)
	job.memo.health=structure.health
	var point: Vector2i = Vector2i(structure.x,structure.y)
	destroy(world,structure,job.id,true)
	job.memo.phase="rebuild";job.inputs=world.definitions.buildings[job.definition].materials.duplicate()
	for item in job.inputs:
		world._make_stack(item,job.inputs[item],"move_bundle",job.id,point,false);world._record("recovered",item,job.inputs[item])
	var positions: Array[Vector2i] = []
	for p in world._perimeter(move_footprint(world,job)):
		if not world.jobs.any(func(other:Dictionary)->bool:return other.id!=job.id and other.worker>0 and Vector2i(other.work_x,other.work_y)==p): positions.append(p)
	positions.sort_custom(func(a:Vector2i,b:Vector2i)->bool:
		var da: int = absi(a.x-citizen.x)+absi(a.y-citizen.y);var db: int = absi(b.x-citizen.x)+absi(b.y-citizen.y)
		return da<db if da!=db else a.y*128+a.x<b.y*128+b.x)
	if positions.is_empty(): world._release(job,false);world._block(job,"Move needs a reachable rebuilding position");return
	job.work_x=positions[0].x;job.work_y=positions[0].y;job.state="Fetching"

static func fetch_bundle(world: ColonyWorld, citizen: Dictionary, job: Dictionary) -> bool:
	var bundles: Array = world.stacks.filter(func(s:Dictionary)->bool:return s.location=="move_bundle" and s.owner==job.id and s.count>0)
	if bundles.is_empty(): return false
	var source: Dictionary = bundles[0]
	citizen.activity="Carrying retained furniture materials"
	if world._walk(citizen,Vector2i(source.x,source.y)):
		var held: int = 0
		for stack in world.stacks:
			if stack.location=="carry" and stack.owner==citizen.id: held += stack.count
		var quantity: int = mini(8-held,source.count)
		var carried: Dictionary = world._make_stack(source.item,quantity,"carry",citizen.id,Vector2i(citizen.x,citizen.y),false)
		carried.age=source.age;carried.age_rem=source.age_rem;carried.tags=source.tags.duplicate();carried.job=job.id
		source.count -= quantity
		if held+quantity>=8 or not world.stacks.any(func(s:Dictionary)->bool:return s.location=="move_bundle" and s.owner==job.id and s.count>0): job.state="Delivering"
	return true

static func complete_move(world: ColonyWorld, job: Dictionary) -> void:
	var structure: Dictionary = world.find(world.structures,job.target)
	structure.x=job.care_goal[0];structure.y=job.care_goal[1];structure.rotation=job.rotation
	structure.health=job.memo.health;structure.cooking=job.memo.cooking;structure.user=0
	if not job.memo.store.is_empty():
		var store: Dictionary = job.memo.store.duplicate(true)
		store.tiles=[Vector2i(structure.x,structure.y)];world.stores.append(store)
	if job.memo.user>0:
		var person: Dictionary = world.find(world.citizens,job.memo.user)
		if not person.is_empty() and not person.death_recorded and not person.departed and person.bed==0: person.bed=structure.id;structure.user=person.id
	world.record_indexes.clear();world.navigation_dirty=true;world.rooms_dirty=true;world.reachability_dirty=true

static func release_move(world: ColonyWorld, job: Dictionary, cancel: bool) -> void:
	if not cancel: return
	for stack in world.stacks:
		if stack.location=="move_bundle" and stack.owner==job.id: stack.location="ground";stack.owner=0;stack.job=0

static func cart_position_error(world: ColonyWorld, cart: Dictionary, point: Vector2i) -> String:
	var shape: Dictionary = {"definition":"supply_cart","rotation":0,"x":point.x,"y":point.y}
	for tile in world.footprint(shape):
		if not world.walkable(tile): return "Cart needs a clear two-by-two land or bridge route"
		if world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.id!=cart.id and s.definition not in ColonyConstruction.OVERLAYS and world.footprint(s).has(tile)): return "Cart route overlaps furniture or a station"
		if world.fields.any(func(f:Dictionary)->bool:return Vector2i(f.x,f.y)==tile) or world.domestic_state.pens.any(func(p:Dictionary)->bool:return p.tiles.has(tile)): return "Cart route overlaps a field or livestock pen"
	return ""

static func cart_edge(world: ColonyWorld, from: Vector2i, to: Vector2i) -> bool:
	for delta in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.ONE]:
		if not world.can_step(from+delta,to+delta): return false
	return true

static func cart_command(world: ColonyWorld, args: Dictionary) -> String:
	var cart: Dictionary = world.find(world.structures,args.target)
	if cart.is_empty() or cart.definition!="supply_cart": return "Choose the supply cart"
	if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="cart_move" and j.state not in ["Complete","Canceled"]): return "Cart move already marked"
	var goal: Vector2i = Vector2i(args.x,args.y)
	var error: String = cart_position_error(world,cart,goal)
	if not error.is_empty(): return error
	if Vector2i(cart.x,cart.y)==goal: return "Choose another cart location"
	var route: Array = ColonyNavigation.path(Vector2i(cart.x,cart.y),goal,func(p:Vector2i)->bool:return cart_position_error(world,cart,p).is_empty(),func(a:Vector2i,b:Vector2i)->bool:return cart_edge(world,a,b))
	if route.is_empty(): return "No two-by-two cart route: clear obstructions or widen the crossing"
	var job: Dictionary = world._job("cart_move","Building","Build",cart.id,Vector2i(cart.x,cart.y),20000)
	job.definition="supply_cart";job.care_goal=[goal.x,goal.y];job.memo={"phase":"prepare"}
	return "accepted"

static func cart_work(world: ColonyWorld, citizen: Dictionary, job: Dictionary) -> void:
	var cart: Dictionary = world.find(world.structures,job.target)
	if job.memo.phase=="prepare":
		citizen.activity="Preparing to move the supply cart"
		if job.state=="Moving":
			if world._walk(citizen,Vector2i(cart.x,cart.y)): job.state="Working"
			return
		if job.state!="Working": return
		var work: int = mini(world._rate(citizen,job),job.required-job.work)
		job.work += work;job.pending_xp[citizen.id]=job.pending_xp.get(citizen.id,0)+work
		if job.work>=job.required: job.memo.phase="push";citizen.route.clear();citizen.route_goal.clear()
		return
	if job.state=="Moving":
		citizen.activity="Meeting the partly moved cart"
		if world._walk(citizen,Vector2i(cart.x,cart.y)): job.state="Working"
		return
	citizen.activity="Pushing the cart with its stored goods"
	var goal: Vector2i = Vector2i(job.care_goal[0],job.care_goal[1])
	var before: Vector2i = Vector2i(citizen.x,citizen.y)
	var arrived: bool = world._walk(citizen,goal)
	var current: Vector2i = Vector2i(citizen.x,citizen.y)
	if current!=before:
		var delta: Vector2i = current-Vector2i(cart.x,cart.y)
		cart.x=current.x;cart.y=current.y
		var store: Dictionary = world.find(world.stores,cart.id);store.tiles=[current]
		for stack in world.stacks:
			if stack.location=="store" and stack.owner==cart.id: stack.x += delta.x;stack.y += delta.y
		world.care_destinations.clear()
	if arrived: world._complete(citizen,job)
