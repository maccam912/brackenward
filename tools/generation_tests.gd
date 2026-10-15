class_name GenerationTests
extends RefCounted

static func run(check: Callable) -> void:
	NavigationTests.reachability(check)
	var golden: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/generation-v2-goldens.json"))
	var valid: bool=golden is Dictionary and golden.get("format","")=="brackenward-generation-goldens" and golden.get("version",0)==1 and golden.get("generator_version",0)==ColonyGeneration.VERSION and golden.get("maps",[]) is Array and golden.maps.size()==18 and golden.get("catalog_sha256","")==ColonyTests.world().definitions.content_hash
	check.call("GEN/inspected_golden_fixture_identity_and_coverage",valid)
	if not valid:return
	var hashes: Dictionary = {}
	for site in ColonyGeneration.SITES:
		for seed_value in [0,1,42,104729,2147483647,4294967295]:
			var world: ColonyWorld = ColonyTests.world()
			var error: String = ColonyGeneration.configure(world,seed_value,site)
			check.call("GEN/viable_%s_%d" % [site,seed_value],error.is_empty() and world.resources.size() > 70 and world.terrain_state.habitats.boar.size() == 2 and world.invariant_errors().is_empty(),error)
			if not error.is_empty(): continue
			var copy: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
			check.call("GEN/save_retains_%s_%d" % [site,seed_value],copy.has("world") and copy.world.canonical_hash() == world.canonical_hash(),str(copy.get("error","")))
			var repeat: ColonyWorld = ColonyTests.world()
			ColonyGeneration.configure(repeat,seed_value,site)
			check.call("GEN/reproducible_%s_%d" % [site,seed_value],repeat.canonical_hash() == world.canonical_hash())
			var expected: Array=golden.maps.filter(func(row:Dictionary)->bool:return row.site==site and row.seed==seed_value)
			check.call("GEN/inspected_v2_golden_%s_%d" % [site,seed_value],expected.size()==1 and expected[0].canonical_hash==world.canonical_hash() and expected[0].transform==world.terrain_state.transform and expected[0].attempt==world.terrain_state.attempt)
			hashes[site+str(seed_value)] = world.canonical_hash()
			var counts: Dictionary = {}
			for resource in world.resources: counts[resource.definition] = counts.get(resource.definition,0)+1
			check.call("GEN/catalog_resources_%s_%d" % [site,seed_value],ColonyGeneration.COUNTS.keys().all(func(id:Variant)->bool:return counts.get(id,0) >= ColonyGeneration.COUNTS[id]))
			var fields: Array[Vector2i] = []
			for i in range(16): fields.append(world.terrain_state.starter_field[i])
			ColonyAgriculture.designate(world,{"tiles":fields,"crop":"turnip"})
			check.call("GEN/protected_field_%s_%d" % [site,seed_value],world.fields.size() == 16 and world.fields.all(func(f:Dictionary)->bool:return f.fertility == 1000) and not ColonyWeather.flood_mask(world).any(func(p:Vector2i)->bool:return world.terrain_state.starter_field.has(p)))
			if seed_value == 104729:
				var transforms: int = world.terrain_state.transform
				var cart: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition == "supply_cart")[0]
				check.call("GEN/transformed_footprint_%s" % site,cart.x >= 0 and cart.y >= 0 and world.footprint(cart).all(func(p:Vector2i)->bool:return ColonyWorld.inside(p)))
				for tick in range(1200): world.step()
				check.call("GEN/real_new_map_simulation_%s" % site,world.fields.any(func(f:Dictionary)->bool:return f.planted) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	check.call("GEN/sites_have_distinct_maps",hashes["meadow_reach104729"] != hashes["pine_shelf104729"] and hashes["pine_shelf104729"] != hashes["reed_bend104729"])
	var world: ColonyWorld = ColonyTests.world()
	var fallback: Dictionary = ColonyGeneration._generate(world,1,"meadow_reach",true)
	check.call("GEN/authored_fallback_satisfies_guarantees",ColonyGeneration.validate_map(fallback).is_empty(),str(ColonyGeneration.validate_map(fallback)))
	var old: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-care.brackenward"))
	check.call("GEN/older_campaign_never_regenerates",old.has("world") and old.world.generator_version == 0 and old.world.terrain_state == ColonyGeneration.empty_state() and old.world.tick == 2860 and old.world.citizens[2].health == 27)
	world = ColonyTests.world()
	ColonyGeneration.configure(world,1,"meadow_reach")
	var broken: Dictionary = world.payload().duplicate(true)
	broken.terrain_state.elevation.pop_back()
	check.call("GEN/rejects_incomplete_saved_geometry",ColonyCodec.restore(broken).has("error"))
	var start: Vector2i = Vector2i(90,90)
	var next: Vector2i = Vector2i(91,90)
	world.terrain_state.elevation[start.y*128+start.x] = 2
	world.terrain_state.elevation[next.y*128+next.x] = 4
	check.call("GEN/height_cliff_blocks_a_step",not world.can_step(start,next))
