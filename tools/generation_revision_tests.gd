class_name GenerationRevisionTests
extends RefCounted
## Keep generator-1 campaign acknowledgments while strengthening fresh maps.

static func closest_work_path(world: ColonyWorld, resource: Dictionary) -> int:
	world._refresh_navigation()
	var cart: Dictionary=ColonyTrade.cart(world);var best: int=100000
	for start in world.footprint(cart):
		for direction in ColonyNavigation.NEIGHBORS:
			var goal: Vector2i=Vector2i(resource.x,resource.y)+direction
			if not world.walkable(goal):continue
			if start==goal:return 0
			var path: Array[Vector2i]=ColonyNavigation.path(start,goal,world.walkable,world.can_step)
			if not path.is_empty():best=mini(best,path.size())
	return best

static func quantity(world: ColonyWorld, definition: String, limit: int) -> int:
	var result: int=0
	for resource in world.resources:
		if resource.definition==definition and closest_work_path(world,resource)<=limit:result+=resource.remaining
	return result

static func run(check: Callable) -> void:
	for site in ColonyGeneration.SITES:
		for entered in [0,1,42,104729,2147483647,4294967295]:
			var reference: ColonyWorld=ColonyTests.world();var current: ColonyWorld=ColonyTests.world()
			var before: String=GenerationV1Reference.configure(reference,entered,site)
			var after: String=ColonyGeneration.configure(current,entered,site,1)
			check.call("GEN/legacy_v1_complete_reference_%s_%d" % [site,entered],before.is_empty() and after.is_empty() and reference.payload()==current.payload() and reference.canonical_hash()==current.canonical_hash())
		var fixture: ColonyWorld=ColonyTests.world()
		var old: Dictionary=GenerationV1Reference._generate(fixture,1,site,true)
		var retained: Dictionary=ColonyGeneration._generate(fixture,1,site,true,1)
		check.call("GEN/legacy_fallback_complete_reference_%s" % site,old.keys().all(func(key:Variant)->bool:return old[key]==retained[key]) and ColonyGeneration.validate_map(retained,1).is_empty())
		var fallback: Dictionary=ColonyGeneration._generate(fixture,1,site,true,2)
		var errors: Array=ColonyGeneration.validate_map(fallback,2)
		check.call("GEN/v2_fallback_keeps_actual_travel_guarantees_%s" % site,errors.is_empty() and fallback.state.fallback,str(errors))
	var old_world: ColonyWorld=ColonyTests.world()
	GenerationV1Reference.configure(old_world,1,"pine_shelf")
	var seam: Dictionary=old_world.resources.filter(func(r:Dictionary)->bool:return r.definition=="stone_node" and r.x==56 and r.y==33)[0]
	check.call("GEN/pine1_reference_extra_requires_forty_one_real_path_steps",closest_work_path(old_world,seam)==41 and quantity(old_world,"stone_node",40)==1400)
	var map: Dictionary=GenerationV1Reference._generate(ColonyTests.world(),1,"pine_shelf",false);map.site="pine_shelf"
	var old_state: Dictionary=map.state.duplicate(true);var old_resources: Array=map.resources.duplicate(true)
	var errors: Array=ColonyGeneration.validate_map(map,2)
	check.call("GEN/v2_rejects_outlying_legacy_extra_without_mutating_geometry",errors.has("site-extra access: stone_node") and map.state==old_state and map.resources==old_resources,str(errors))
	var old_bytes: PackedByteArray=ColonyCodec.encode(old_world);var old_hash: String=old_world.canonical_hash()
	var imported: Dictionary=ColonyCodec.decode(old_bytes)
	check.call("GEN/old_saved_map_loads_unchanged_without_regeneration",imported.has("world") and imported.world.generator_version==1 and imported.world.canonical_hash()==old_hash and imported.world.terrain_state==old_world.terrain_state)
	var current: ColonyWorld=ColonyTests.world();var error: String=ColonyGeneration.configure(current,1,"pine_shelf")
	check.call("GEN/new_campaign_uses_v2_and_has_eight_stone_nodes_within_forty",error.is_empty() and current.generator_version==2 and quantity(current,"stone_node",24)>=800 and quantity(current,"stone_node",40)>=1600 and current.invariant_errors().is_empty(),error)
	var saved: PackedByteArray=ColonyCodec.encode(current);var decoded: Dictionary=ColonyCodec.decode(saved)
	check.call("GEN/v2_snapshot_roundtrip_keeps_complete_state",decoded.has("world") and decoded.world.canonical_hash()==current.canonical_hash() and decoded.world.generator_version==2,str(decoded.get("error","")))
	bounded_routes(current,check)
	var future: Dictionary=JSON.parse_string(saved.get_string_from_utf8());future.generator_version=3
	check.call("GEN/future_generator_snapshot_is_rejected",ColonyCodec.decode(JSON.stringify(future,"",true).to_utf8_buffer()).has("error"))
	current=ColonyTests.world();var unchanged: String=current.canonical_hash()
	check.call("GEN/unknown_requested_revision_leaves_current_world_unchanged",not ColonyGeneration.configure(current,1,"meadow_reach",3).is_empty() and current.canonical_hash()==unchanged)

static func bounded_routes(world: ColonyWorld, check: Callable) -> void:
	world._refresh_navigation()
	var resource: Dictionary=world.resources.filter(func(r:Dictionary)->bool:return r.definition=="clay_bank")[0]
	var target: Vector2i=Vector2i(resource.x,resource.y);var expected: int=closest_work_path(world,resource)
	var map: Dictionary={"state":world.terrain_state,"solid":world.solid_tiles,"cart_cells":world.footprint(ColonyTrade.cart(world))}
	var quote: Dictionary=ColonyGeneration._short_route(map,target,expected)
	check.call("GEN/bounded_route_matches_independent_full_astar_at_exact_limit",quote.found and quote.path.size()==expected and not ColonyGeneration._short_route(map,target,expected-1).found)
	var steps: Array=quote.get("path",[]);var legal: bool=quote.found and not steps.is_empty()
	for index in range(steps.size()):
		var point: Vector2i=steps[index]
		legal=legal and point!=target and world.walkable(point)
		if index==0:legal=legal and map.cart_cells.any(func(start:Vector2i)->bool:return absi(start.x-point.x)+absi(start.y-point.y)==1 and world.can_step(start,point))
		else:legal=legal and absi(steps[index-1].x-point.x)+absi(steps[index-1].y-point.y)==1 and world.can_step(steps[index-1],point)
	check.call("GEN/bounded_route_contains_only_actual_walkable_legal_steps",legal and steps[-1]==quote.work and absi(quote.work.x-target.x)+absi(quote.work.y-target.y)==1)
	# Algorithm-only fixture; these resource records are never a play certificate.
	var elevations: Array=[];elevations.resize(16384);elevations.fill(2)
	var fixture: Dictionary={"state":{"elevation":elevations,"bridges":[]},"resources":[],"solid":{},"cart_cells":ColonyGeneration._cart_cells(0)}
	var occupied: Dictionary={};var protected: Dictionary={};target=Vector2i(60,45)
	var placed: bool=ColonyGeneration._place(fixture,[target],"stone_node",occupied,protected,true,24)
	quote=ColonyGeneration._short_route(fixture,target,24)
	var guarded: bool=placed and quote.found and quote.path.all(func(point:Vector2i)->bool:return protected.has(point))
	for point in quote.get("path",[]):
		guarded=guarded and not ColonyGeneration._place(fixture,[point],"tree",occupied,protected)
		guarded=guarded and not ColonyGeneration._place(fixture,[point],"clay_bank",occupied,protected,true,24)
	check.call("GEN/later_deposits_and_woodland_cannot_occupy_protected_resource_routes",guarded and fixture.resources.size()==1 and fixture.solid.size()==1)
	check.call("GEN/out_of_range_resource_is_not_added",not ColonyGeneration._place(fixture,[Vector2i(90,90)],"stone_node",occupied,protected,true,24) and fixture.resources.size()==1)
	var zero: Dictionary=ColonyGeneration._short_route(fixture,Vector2i(65,63),0)
	check.call("GEN/cart_footprint_zero_step_work_position_is_a_valid_route",zero.found and zero.path.is_empty() and fixture.cart_cells.has(zero.work))
