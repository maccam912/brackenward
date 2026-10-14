class_name MovementCostTests
extends RefCounted

static func reference_cost(world: ColonyWorld, tile: Vector2i) -> int:
	if world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="bridge" and world.footprint(s).has(tile)): return 10
	for structure in world.structures:
		if structure.health>0 and structure.definition=="stone_path" and world.footprint(structure).has(tile): return 8
	if world.is_flooded(tile): return 15
	if world.generator_version>0 and world.terrain_state.bridges.has(tile): return 10
	if world.weather=="snow": return 12
	if world.weather=="rain" and ((world.generator_version>0 and not world.terrain_state.paths.has(tile)) or (world.generator_version==0 and tile.x!=66 and tile.y not in [63,64])): return 15
	return 10

static func run(check: Callable) -> void:
	for site in ["legacy","meadow_reach","pine_shelf","reed_bend"]:
		var world: ColonyWorld = ColonyTests.world()
		if site!="legacy":
			var error: String = ColonyGeneration.configure(world,104729,site)
			if not error.is_empty(): check.call("MOVE/cost_site_"+site,false,error);continue
		var path: Dictionary = world._structure("stone_path",Vector2i(76,70),0)
		var bridge: Dictionary = world._structure("bridge",Vector2i(33,70),0)
		world.weather_state.flooded=[Vector2i(76,70),Vector2i(77,70),Vector2i(33,70)];world.flood_cache_valid=false
		for weather in ["clear","rain","snow","flood"]:
			world.weather=weather;var matches: bool = true
			for y in range(0,128,7):
				for x in range(0,128,7):
					var tile: Vector2i = Vector2i(x,y);matches=matches and world.tile_move_cost(tile)==reference_cost(world,tile)
			for tile in [Vector2i(76,70),Vector2i(77,70),Vector2i(33,70),Vector2i(66,63)]: matches=matches and world.tile_move_cost(tile)==reference_cost(world,tile)
			check.call("MOVE/cached_tile_cost_matches_reference_%s_%s" % [site,weather],matches)
		path.health=0;bridge.health=0;world.navigation_dirty=true
		check.call("MOVE/destroyed_path_bridge_costs_rebuild_%s" % site,world.tile_move_cost(Vector2i(76,70))==reference_cost(world,Vector2i(76,70)) and world.tile_move_cost(Vector2i(33,70))==reference_cost(world,Vector2i(33,70)))
