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
	route_context(check)

static func same_route_world(a: ColonyWorld, b: ColonyWorld) -> bool:
	return a.path_requests==b.path_requests and JSON.stringify(ColonyState.pack(a.payload()),"",false)==JSON.stringify(ColonyState.pack(b.payload()),"",false)

static func route_context(check: Callable) -> void:
	var exact: bool=true;var cases: int=0
	for policy in [["", "Moving", ""],["gather","Moving",""],["escape","Moving",""],["lead_animal","Moving",""],["cart_move","Moving","meet"],["cart_move","Moving","push"],["cart_move","Working","push"]]:
		var world: ColonyWorld=ColonyTests.world();var worker: Dictionary=world.citizens[0]
		worker.x=80;worker.y=80
		world._structure("wood_wall",Vector2i(82,81),0);world._structure("door",Vector2i(83,80),0)
		if not policy[0].is_empty():
			var job: Dictionary=world._job(policy[0],"Hauling","Hauling",world.structures[4].id,Vector2i(86,80),2000)
			job.worker=worker.id;job.state=policy[1];job.memo.phase=policy[2];worker.job=job.id
		var prior: ColonyWorld=RouteContextReference.clone_world(world,true)
		var current_result: bool=world._walk(worker,Vector2i(86,80));var original_result: bool=prior._walk(prior.citizens[0],Vector2i(86,80))
		exact=exact and current_result==original_result and same_route_world(world,prior);cases+=1
	check.call("NAV/route_context_matches_full_original_for_seven_task_cart_and_fence_policies",exact and cases==7)

	var world: ColonyWorld=ColonyTests.world();var worker: Dictionary=world.citizens[0]
	worker.x=80;worker.y=80;world._structure("wood_wall",Vector2i(82,81),0)
	var job: Dictionary=world._job("cart_move","Hauling","Hauling",world.structures[4].id,Vector2i(86,80),2000)
	job.worker=worker.id;worker.job=job.id;job.memo.phase="meet";job.state="Moving"
	var prior: ColonyWorld=RouteContextReference.clone_world(world,true);var ordinary_route: Array=[];var cart_route: Array=[];exact=true
	for policy in [["Moving","meet"],["Working","push"],["Moving","push"]]:
		for twin in [world,prior]:
			var person: Dictionary=twin.citizens[0];var task: Dictionary=twin.find(twin.jobs,person.job)
			task.state=policy[0];task.memo.phase=policy[1];person.progress=0;person.x=80;person.y=80;person.route.clear();person.route_goal.clear();twin.path_requests=0
			person.move_base_rem=0;person.move_rem=0;person.injury_rem=0
			twin._walk(person,Vector2i(86,80))
		exact=exact and same_route_world(world,prior)
		if policy[0]=="Working":cart_route=worker.route.duplicate()
		else:ordinary_route=worker.route.duplicate()
	check.call("NAV/new_search_rechecks_cart_phase_and_state_without_retaining_policy",exact and ordinary_route!=cart_route and not ordinary_route.is_empty() and not cart_route.is_empty())

	world=ColonyTests.world();worker=world.citizens[0];worker.x=80;worker.y=80
	var bed: Dictionary=world._structure("bedroll",Vector2i(85,80),0)
	for delta in ColonyNavigation.NEIGHBORS:world._structure("wood_wall",Vector2i(85,80)+delta,0)
	job=world._job("sleep","","",bed.id,Vector2i(85,80),0);job.worker=worker.id;worker.job=job.id;job.state="Moving"
	prior=RouteContextReference.clone_world(world,true);world.path_requests=4;prior.path_requests=4
	var limited: bool=not world._walk(worker,Vector2i(85,80)) and not prior._walk(prior.citizens[0],Vector2i(85,80)) and same_route_world(world,prior) and world.path_requests==4
	world.path_requests=0;prior.path_requests=0
	var slept: bool=world._walk(worker,Vector2i(85,80)) and prior._walk(prior.citizens[0],Vector2i(85,80))
	check.call("NAV/request_limit_and_unreachable_sleep_ground_fallback_match_original",limited and slept and same_route_world(world,prior) and job.target==0 and world.path_requests==1)

	world=ColonyTests.world();world.queue_command("cart_move",{"target":world.structures[4].id,"x":78,"y":70})
	prior=RouteContextReference.clone_world(world,true)
	for tick in range(1200):world.step();prior.step()
	exact=same_route_world(world,prior) and world.invariant_errors().is_empty()
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	if decoded.has("world"):
		world=decoded.world;prior=RouteContextReference.clone_world(world,true)
		for tick in range(120):world.step();prior.step()
		exact=exact and same_route_world(world,prior) and world.invariant_errors().is_empty()
	check.call("NAV/real_cart_command_and_reloaded_future_preserve_exact_complete_state",exact and decoded.has("world") and world.structures[4].x==78 and world.structures[4].y==70)

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
