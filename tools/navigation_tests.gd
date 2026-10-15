class_name NavigationTests
extends RefCounted

static func run(check: Callable) -> void:
	# Frozen from the original sorted-frontier A*: obstacles and directed edges
	# exercise equal scores, improved routes, blocked targets and no-path cases.
	var routes: Array = []
	for seed in range(1,41):
		var blocked: Dictionary = {}
		var rng: ParkMiller = ParkMiller.new(seed*104729)
		for index in range(90): blocked[Vector2i(rng.next()%20,rng.next()%20)]=true
		var passable: Callable = func(p:Vector2i)->bool:return p.x>=0 and p.y>=0 and p.x<20 and p.y<20 and not blocked.has(p)
		var edge: Callable = func(a:Vector2i,b:Vector2i)->bool:return not (a.x==10 and b.x==11 and a.y<12)
		routes.append(ColonyNavigation.path(Vector2i.ZERO,Vector2i(19,19),passable,edge))
	check.call("NAV/frozen_paths_across_forty_obstacle_and_edge_maps",JSON.stringify(ColonyState.pack(routes)).sha256_text()=="c553bf6c68d0023c2bd33cd12d17764050b3bdb9a845f6a2f08241e3ec9d7f05")

static func reachability(check: Callable) -> void:
	var goldens: Dictionary = {
		"authored":"fa752c8b7025500bb86c91eac4a70a33bd5446c46089e70e189d3c2884b9b1be",
		"meadow_reach":"e5739682e79b2299740dd35f974fbb2e0a624e0cd4e98f4500469af252b30112",
		"pine_shelf":"d92da93e60619340b90163fdba20b9bb965ad87fa0af1d3d5d203cbb9e5dce32",
		"reed_bend":"e316b2bcc25c8953cf6867cb28693ecf35486285a18db3d9f3258c3eee40f88f"
	}
	for site in goldens:
		var world: ColonyWorld = ColonyTests.world()
		if site!="authored": ColonyGeneration.configure(world,104729,site,1)
		world.accessible(Vector2i(66,63))
		check.call("NAV/frozen_reachable_cells_%s" % site,ColonyJournal._hash(world.reachable_cells).hex_encode()==goldens[site])
	var world: ColonyWorld = ColonyTests.world()
	var outside: Dictionary = world.citizens[1]
	world.citizens.resize(1)
	world.citizens[0].x=70;world.citizens[0].y=70
	var walls: Array[Dictionary] = []
	for delta in ColonyNavigation.NEIGHBORS: walls.append(world._structure("wood_wall",Vector2i(75,75)+delta,0))
	check.call("NAV/enclosed_room_excluded_without_a_resident",not world.accessible(Vector2i(75,75)) and world.accessible(Vector2i(70,70)))
	world.citizens[0].x=75;world.citizens[0].y=75;world.reachability_dirty=true
	check.call("NAV/trapped_resident_seeds_own_component",world.accessible(Vector2i(75,75)) and not world.accessible(Vector2i(70,70)))
	world.citizens.append(outside);world.reachability_dirty=true
	check.call("NAV/multiple_resident_components_are_retained",world.accessible(Vector2i(75,75)) and world.accessible(Vector2i(70,70)))
	world.citizens[0].health=0;world.reachability_dirty=true
	check.call("NAV/dead_resident_does_not_seed_a_component",not world.accessible(Vector2i(75,75)))
	walls[0].health=0;world.navigation_dirty=true
	check.call("NAV/removed_wall_reconnects_cached_component",world.accessible(Vector2i(75,75)))
	var bridge: Dictionary = world._structure("bridge",Vector2i(32,60),0)
	check.call("NAV/built_bridge_updates_water_and_reachability",not world.is_water(Vector2i(32,60)) and world.accessible(Vector2i(32,60)))
	bridge.health=0;world.navigation_dirty=true
	check.call("NAV/destroyed_bridge_invalidates_water_and_reachability",world.is_water(Vector2i(32,60)) and not world.accessible(Vector2i(32,60)))
