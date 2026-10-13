class_name NatureTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var resource: Dictionary = world.resources[0]
	world.queue_command("gather",{"target":resource.id})
	for i in range(600): world.step()
	check.call("FOREST/cut_tree_leaves_real_stump",resource.remaining == 0 and world.total("wood") == 52)
	world.queue_command("replant_tree",{"target":resource.id})
	for i in range(500): world.step()
	check.call("FOREST/replant_costs_four_wu_without_material",ColonyNature.tree(world,resource.id).planted and world.jobs.any(func(j:Dictionary)->bool:return j.kind == "plant_tree" and j.required == 4000 and j.state == "Complete") and world.ledger.consumed.get("wood",0) == 0)
	var state: Dictionary = world.nature_state.trees[resource.id]
	state.age = ColonyNature.MATURITY-1
	world.tick = 172800
	ColonyWeather.initialize(world)
	ColonyNature.advance(world)
	check.call("FOREST/winter_pauses_tree_maturity",state.age == ColonyNature.MATURITY-1 and resource.remaining == 0)
	world.tick = 230400; ColonyWeather.initialize(world); ColonyNature.advance(world)
	check.call("FOREST/eight_nonwinter_days_restores_eight_wood_tree",resource.remaining == 8 and not state.planted and state.age == ColonyNature.MATURITY)
	world = ColonyTests.world(); resource = world.resources[0]; resource.remaining = 0
	world.nature_state.trees[resource.id] = {"planted":true,"age":500}
	world.queue_command("clear_sapling",{"target":resource.id})
	for i in range(300): world.step()
	check.call("FOREST/clearing_young_tree_yields_no_wood",not ColonyNature.tree(world,resource.id).planted and world.total("wood") == 44 and world.jobs.any(func(j:Dictionary)->bool:return j.kind == "clear_sapling" and j.required == 2000 and j.state == "Complete"))
	world = ColonyTests.world()
	var tiles: Array[Vector2i] = []
	for i in range(8): tiles.append(Vector2i(world.resources[i].x,world.resources[i].y))
	world.queue_command("forest",{"tiles":tiles,"value":75})
	for i in range(1800): world.step()
	var mature: int = world.resources.slice(0,8).filter(func(r:Dictionary)->bool:return r.remaining > 0).size()
	check.call("FOREST/automatic_cutting_keeps_ceiling_reserve",mature == 6 and world.total("wood") == 60 and world.nature_state.forests.size() == 1 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	check.call("FOREST/automatic_replanting_uses_real_jobs",world.jobs.filter(func(j:Dictionary)->bool:return j.kind == "plant_tree" and j.state == "Complete").size() == 2)
	world.queue_command("gather",{"target":world.resources[0].id if world.resources[0].remaining > 0 else world.resources[2].id})
	for i in range(600): world.step()
	check.call("FOREST/explicit_cut_can_go_below_reserve",world.resources.slice(0,8).filter(func(r:Dictionary)->bool:return r.remaining > 0).size() == 5)
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("FOREST/zone_saplings_and_jobs_roundtrip",decoded.has("world") and decoded.world.canonical_hash() == world.canonical_hash(),str(decoded.get("error","")))
	var zone: Dictionary = world.nature_state.forests[0]
	world.queue_command("forest_policy",{"target":zone.id,"value":50,"enabled":false}); world.step()
	check.call("FOREST/pause_releases_future_zone_work",not zone.enabled and world.jobs.all(func(j:Dictionary)->bool:return j.order != zone.id or j.state in ["Complete","Canceled"]))
	world = ColonyTests.world()
	check.call("FISH/pier_requires_half_land_half_river",world.placement_error("fishing_pier",Vector2i(31,48),0).is_empty() and world.placement_error("fishing_pier",Vector2i(70,50),0).contains("two land"))
	world.queue_command("build",{"definition":"fishing_pier","x":31,"y":48,"rotation":0})
	for i in range(2200): world.step()
	check.call("FISH/real_pier_build_and_physical_catch",world.structures.any(func(s:Dictionary)->bool:return s.definition == "fishing_pier") and world.ledger.produced.get("fish",0) > 0 and world.nature_state.fishing.river <= 8 and world.jobs.any(func(j:Dictionary)->bool:return j.kind == "fish" and j.required == 12000 and j.state == "Complete") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world._structure("fishing_pier",Vector2i(31,52),0); world._structure("fishing_pier",Vector2i(31,56),0)
	# Staff the capacity test and shorten output hauling. The limit must be reached
	# by actual work, independently of changes to ordinary meal/sleep timing.
	world.queue_command("preference",{"citizen":2,"category":"Gathering","value":3})
	world.queue_command("preference",{"citizen":3,"category":"Gathering","value":3})
	world.queue_command("preference",{"citizen":4,"category":"Hauling","value":3})
	world.queue_command("stockpile",{"tiles":[Vector2i(29,50),Vector2i(30,50),Vector2i(29,51),Vector2i(30,51)]})
	var maximum: int = 0
	var legal: bool = true
	for i in range(12000):
		world.step()
		maximum = maxi(maximum,world.nature_state.fishing.river)
		legal = legal and world.nature_state.fishing.river <= 16 and world.nature_state.fishing.piers.values().all(func(n:Variant)->bool:return n <= 8)
		if maximum == 16: break
	check.call("FISH/multiple_piers_respect_river_sixteen_limit",maximum == 16 and legal,"maximum=%d, legal=%s; residents=%s" % [maximum,legal,world.citizens.map(func(c:Dictionary)->Dictionary:return {"name":c.name,"activity":c.activity,"fullness":c.fullness,"rest":c.rest})])
	decoded = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("FISH/daily_limits_and_physical_outputs_roundtrip",decoded.has("world") and decoded.world.canonical_hash() == world.canonical_hash(),str(decoded.get("error","")))
	var following_day: int = world.nature_state.fishing.day+1
	world.tick = following_day*7200+1799; ColonyWeather.initialize(world); world.step()
	check.call("FISH/river_and_pier_limits_reset_at_dawn",world.nature_state.fishing.day == following_day and world.nature_state.fishing.river == 0 and world.nature_state.fishing.piers.is_empty())
	var old: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-care.brackenward"))
	check.call("NATURE/legacy_care_and_map_remain_intact",old.has("world") and old.world.citizens[2].health == 27 and old.world.generator_version == 0 and old.world.nature_state.trees.is_empty())
	var damaged: Dictionary = world.payload().duplicate(true)
	damaged.nature_state.fishing = {"day":(world.tick-1800)/7200,"river":2,"piers":{999999:2}}
	check.call("SAVE/rejects_missing_fishing_pier",ColonyCodec.restore(damaged).has("error"))
	damaged = world.payload().duplicate(true)
	damaged.nature_state.forests = [{"id":world.next_id,"tiles":[Vector2i(-1,20)],"reserve":75,"enabled":true}]
	check.call("SAVE/rejects_outside_forest_tiles",ColonyCodec.restore(damaged).has("error"))
