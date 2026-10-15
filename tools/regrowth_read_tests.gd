class_name RegrowthReadTests
extends RefCounted
## Complete original702b20b agriculture advance; full original resource scan retained.
class OriginalWorld extends ColonyWorld:
	func _regrowth_resources() -> Array:return resources

static func original_advance(world: ColonyWorld) -> void:
	var current_season: int = ColonyAgriculture.season(world.tick)
	# Irrigation only affects drought. Build this local view once so destroyed or
	# moved wells are observed on the next tick without a persisted cache.
	var wells: Array = world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition=="well") if world.weather=="drought" else []
	for resource in world.resources:
		if resource.remaining == 0 and resource.regrow_at > 0:
			if current_season == 3 and resource.definition in ["berry_bush", "herb_patch", "tree"]:
				resource.regrow_at += 1
			elif world.tick >= resource.regrow_at:
				resource.remaining = world.definitions.resources[resource.definition].yield_count
				resource.regrow_at = 0
				world.navigation_dirty = true
	for field in world.fields:
		if not field.planted:
			continue
		var definition: Dictionary = world.definitions.crops[field.crop]
		if world.is_flooded(Vector2i(field.x,field.y)):
			field.reason = "Flooded until 18:00: growth paused"
			continue
		if field.ripe_tick > 0:
			var elapsed: int = world.tick - field.ripe_tick
			if elapsed > 14400 and (elapsed - 14400) % 7200 == 0:
				field.yield_count = maxi(0, field.yield_count - 1)
				if field.yield_count == 0:
					field.planted = false
					field.growth = 0
					field.ripe_tick = 0
			continue
		if not definition.seasons.has(current_season):
			field.reason = "Dormant until " + ["Spring", "Summer", "Autumn", "Winter"][definition.seasons[0]]
			continue
		if world.roofed(Vector2i(field.x, field.y)) != definition.roof:
			field.reason = "Roof required" if definition.roof else "Remove roof for outdoor crops"
			continue
		var watered: bool = wells.any(func(s:Dictionary)->bool:return absi(s.x-field.x)+absi(s.y-field.y) <= 8)
		var rate: int = field.fertility * (500 if world.weather == "drought" and not watered else 1000) / 1000
		field.growth_rem += rate
		field.growth += field.growth_rem / 7200
		field.growth_rem %= 7200
		field.reason = "Growing: drought, half rate; build a well within 8 tiles" if world.weather == "drought" and not watered else ("Growing: well stabilizes drought" if world.weather == "drought" else "Growing")
		if field.growth >= definition.growth:
			field.growth = definition.growth
			field.ripe_tick = world.tick
			field.reason = "Ripe: harvest before losses after 2 days"


static func clone(source: ColonyWorld, reference: bool=false) -> ColonyWorld:
	var result: ColonyWorld=OriginalWorld.new(source.definitions) if reference else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]:continue
		var value: Variant=source.get(field)
		if value is Array:result.get(field).assign(value.duplicate(true))
		elif value is Dictionary:result.set(field,value.duplicate(true))
		else:result.set(field,value)
	result.reset_job_queries();result.reset_stack_queries();result.reset_resource_queries();result.record_indexes.clear()
	result.navigation_dirty=true;result.rooms_dirty=true;result.reachability_dirty=true
	return result

static func resource(world: ColonyWorld, kind: String) -> Dictionary:
	return world.resources.filter(func(r:Dictionary)->bool:return r.definition==kind)[0]

static func advance_pair(current: ColonyWorld, prior: ColonyWorld) -> bool:
	current.in_tick=true;ColonyAgriculture.advance(current);current.in_tick=false
	original_advance(prior)
	return current.payload()==prior.payload()

static func run(check: Callable) -> void:
	var exact: bool=true
	for start in [1800,172800,230399]:
		var current: ColonyWorld=ColonyTests.world();current.tick=start
		for kind in ["berry_bush","herb_patch","mushroom_patch","tree","stone_node"]:
			var row: Dictionary=resource(current,kind);row.remaining=0;row.regrow_at=start+1
		var prior: ColonyWorld=clone(current,true)
		for offset in range(5):
			current.tick=start+offset;prior.tick=current.tick
			exact=exact and advance_pair(current,prior)
	check.call("REGROW/derived_view_matches_original_growth_and_winter_delays_for_all_resource_types",exact)
	var current: ColonyWorld=ColonyTests.world();var prior: ColonyWorld=clone(current,true)
	current.in_tick=true;var empty_before: bool=current._regrowth_resources().is_empty();current.in_tick=false
	var target: int=resource(current,"berry_bush").id
	for world: ColonyWorld in [current,prior]:
		var row: Dictionary=world.find(world.resources,target)
		var job: Dictionary=world._job("gather","Gathering","Field",target,Vector2i(row.x,row.y),8000)
		job.worker=world.citizens[0].id;world.citizens[0].job=job.id
		world._finish(world.citizens[0],job)
		world.tick=world.find(world.resources,target).regrow_at
	exact=empty_before and advance_pair(current,prior) and current.find(current.resources,target).remaining==4
	# The older replant job remains supported even though new forests use sapling ages.
	for world: ColonyWorld in [current,prior]:
		var tree: Dictionary=resource(world,"tree");tree.remaining=0
		ColonyAgriculture.complete(world,world.citizens[0],{"kind":"replant","target":tree.id})
		world.tick=tree.regrow_at
	exact=exact and advance_pair(current,prior) and resource(current,"tree").remaining==8
	check.call("REGROW/real_gather_completion_and_legacy_replant_refresh_a_warmed_empty_view",exact)
	current=ColonyTests.world();current.in_tick=true;current._regrowth_resources()
	var row: Dictionary=resource(current,"mushroom_patch").duplicate(true);row.remaining=0;row.regrow_at=current.tick
	current.resources=[row];prior=clone(current,true)
	exact=advance_pair(current,prior) and current.resources[0].remaining==3
	# Direct calls retain the full original scan and invalidate any earlier trusted view.
	resource(current,"mushroom_patch").remaining=0;current.resources[0].regrow_at=current.tick+1
	exact=exact and is_same(current._regrowth_resources(),current.resources)
	current.tick+=1;prior=clone(current,true);exact=exact and advance_pair(current,prior)
	check.call("REGROW/replacement_and_direct_call_boundaries_keep_live_records_and_original_behavior",exact)
	current=ColonyTests.world();prior=clone(current,true)
	var berry: Dictionary=resource(current,"berry_bush")
	current.queue_command("gather",{"target":berry.id});prior.queue_command("gather",{"target":berry.id})
	for tick in range(1200):current.step();prior.step()
	check.call("REGROW/complete_future_ticks_and_reload_keep_all_authoritative_state",current.payload()==prior.payload() and current.invariant_errors().is_empty() and ColonyCodec.decode(ColonyCodec.encode(current)).world.payload()==current.payload())

	# A supported legacy timer can remain dormant while its resource is positive.
	# Depleting that tree must expose the timer without a new player command.
	current=ColonyTests.world();resource(current,"tree").regrow_at=current.tick+2
	var supported: bool=ColonyCodec.restore(current.payload().duplicate(true)).has("world")
	prior=clone(current,true);exact=advance_pair(current,prior)
	for world: ColonyWorld in [current,prior]:
		var tree: Dictionary=resource(world,"tree")
		var job: Dictionary=world._job("gather","Gathering","Field",tree.id,Vector2i(tree.x,tree.y),16000)
		job.worker=world.citizens[0].id;world.citizens[0].job=job.id
		world._finish(world.citizens[0],job);world.tick+=2
	exact=exact and advance_pair(current,prior) and resource(current,"tree").remaining==8
	check.call("REGROW/dormant_positive_legacy_timer_survives_later_tree_depletion_without_new_command",supported and exact)
