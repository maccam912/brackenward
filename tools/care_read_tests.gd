class_name CareReadTests
extends RefCounted
## Original 5cf3cca bed selection: one independent A* route per bed.

static func full_destination(world: ColonyWorld, patient: Dictionary) -> Dictionary:
	if world.navigation_dirty:
		world.care_destinations.clear()
		world.walkable(Vector2i.ZERO)
	var candidates: Array = []
	var origin: Vector2i = Vector2i(patient.x,patient.y)
	var occupied_beds: Array = []
	for bed in world.structures:
		if bed.health<=0: continue
		if bed.definition in ["bed","bedroll"] and world.citizens.any(func(c:Dictionary)->bool:return c.id != patient.id and c.health > 0 and not c.departed and c.x == bed.x and c.y == bed.y): occupied_beds.append(bed.id)
	var cached: Dictionary = world.care_destinations.get(patient.id,{})
	if cached.get("origin") == origin and cached.get("occupied") == occupied_beds: return cached.result
	for bed in world.structures:
		if bed.health<=0: continue
		if bed.definition not in ["bed","bedroll"]: continue
		if origin == Vector2i(bed.x,bed.y): return {"id":bed.id,"point":origin,"distance":0}
		if occupied_beds.has(bed.id): continue
		var point: Vector2i = Vector2i(bed.x,bed.y)
		var route: Array = [] if point == origin else ColonyNavigation.path(origin,point,world.walkable,world.can_step)
		if point != origin and route.is_empty(): continue
		candidates.append({"id":bed.id,"point":point,"distance":route.size()})
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.distance < b.distance or (a.distance == b.distance and a.id < b.id))
	if not candidates.is_empty():
		world.care_destinations[patient.id] = {"origin":origin,"occupied":occupied_beds,"result":candidates[0]}
		return candidates[0]
	var cart: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition == "supply_cart")[0]
	for point in world._perimeter(world.footprint(cart)):
		var route: Array = [] if point == origin else ColonyNavigation.path(origin,point,world.walkable,world.can_step)
		if point == origin or not route.is_empty(): return {"id":0,"point":point,"distance":route.size()}
	return {"id":0,"point":origin,"distance":0}


class OriginalWorld extends ColonyWorld:
	func _care_destination(citizen: Dictionary) -> Dictionary:
		return CareReadTests.full_destination(self,citizen)

static func compare(world: ColonyWorld, patient: Dictionary) -> bool:
	var before: String=world.canonical_hash()
	var actual: Dictionary=ColonyCare.destination(world,patient)
	world.care_destinations.clear()
	var original: Dictionary=full_destination(world,patient)
	return actual==original and world.canonical_hash()==before

static func run(check: Callable) -> void:
	for site in ["legacy","meadow_reach","pine_shelf","reed_bend"]:
		var world: ColonyWorld=ColonyTests.world()
		if site!="legacy":
			var error: String=ColonyGeneration.configure(world,104729,site)
			if not error.is_empty(): check.call("CARE_SEARCH/site_"+site,false,error);continue
		for point in [Vector2i(60,60),Vector2i(80,70),Vector2i(40,63),Vector2i(66,85)]:
			world._structure("bed",point,0)
		var patient: Dictionary=world.citizens[0]
		var exact: bool=true
		for point in [Vector2i(68,63),Vector2i(72,70),Vector2i(31,63),Vector2i(0,0),Vector2i(127,127),Vector2i(80,70)]:
			patient.x=point.x;patient.y=point.y
			exact=compare(world,patient) and exact
		check.call("CARE_SEARCH/shortest_distance_and_id_match_independent_astar_"+site,exact)
	var world: ColonyWorld=ColonyTests.world();var patient: Dictionary=world.citizens[0]
	for bed in world.structures:
		if bed.definition in ["bed","bedroll"]: bed.health=0
	patient.x=90;patient.y=80
	var first: Dictionary=world._structure("bed",Vector2i(89,80),0)
	var second: Dictionary=world._structure("bedroll",Vector2i(91,80),0)
	world.structures.reverse()
	check.call("CARE_SEARCH/equal_distance_uses_id_rather_than_record_or_bed_kind",compare(world,patient) and ColonyCare.destination(world,patient).id==first.id)
	world.citizens[1].x=89;world.citizens[1].y=80
	check.call("CARE_SEARCH/moving_occupant_invalidates_cached_destination",compare(world,patient) and ColonyCare.destination(world,patient).id==second.id)
	world.citizens[1].departed=true
	check.call("CARE_SEARCH/departed_occupant_does_not_reserve_a_bed",compare(world,patient) and ColonyCare.destination(world,patient).id==first.id)
	world._structure("wood_wall",Vector2i(89,80),0)
	check.call("CARE_SEARCH/new_solid_tile_invalidates_navigation_and_bed_cache",compare(world,patient) and ColonyCare.destination(world,patient).id==second.id)
	var same: Dictionary=world._structure("bed",Vector2i(91,80),0)
	patient.x=91;patient.y=80
	world.structures.erase(same);world.structures.push_front(same)
	check.call("CARE_SEARCH/already_at_bed_keeps_original_first_record_rule",compare(world,patient) and ColonyCare.destination(world,patient).id==same.id)
	for bed in world.structures:
		if bed.definition in ["bed","bedroll"]: bed.health=0
	world.navigation_dirty=true
	check.call("CARE_SEARCH/no_beds_keeps_original_cart_perimeter_order",compare(world,patient) and ColonyCare.destination(world,patient).id==0)
	world._structure("bed",Vector2i(20,20),0)
	for point in [Vector2i(20,19),Vector2i(21,20),Vector2i(20,21),Vector2i(19,20)]: world._structure("wood_wall",point,0)
	check.call("CARE_SEARCH/unreachable_bed_falls_back_to_same_cart_tile_and_distance",compare(world,patient) and ColonyCare.destination(world,patient).id==0)
	complete_ticks(check)

static func clone(source: ColonyWorld, original: bool) -> ColonyWorld:
	var result: ColonyWorld=OriginalWorld.new(source.definitions) if original else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	return result

static func complete_ticks(check: Callable) -> void:
	var source: ColonyWorld=ColonyTests.world()
	for person in source.citizens: person.health=40;person.rest=800;person.fullness=900
	for point in [Vector2i(72,66),Vector2i(60,68),Vector2i(74,64),Vector2i(64,70)]: source._structure("bed",point,0)
	var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
	var exact: bool=true
	for index in range(420):
		fast.step();original.step()
		if index%60==0: exact=fast.canonical_hash()==original.canonical_hash() and exact
	check.call("CARE_SEARCH/simultaneous_injuries_preserve_complete_tick_state",exact and fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(fast))
	check.call("CARE_SEARCH/recovery_save_is_valid_and_retains_authoritative_state",decoded.has("world") and decoded.world.canonical_hash()==fast.canonical_hash(),str(decoded.get("error","")))
	if not decoded.has("world"): return
	fast=decoded.world
	for index in range(120): fast.step();original.step()
	check.call("CARE_SEARCH/derived_search_cache_rebuilds_after_reload",fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty())
