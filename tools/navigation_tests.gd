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
