extends SceneTree
## Report actual fallback approach lengths with/without its extra woodland.
func _initialize() -> void:
	for site in ColonyGeneration.SITES:
		var map: Dictionary=ColonyGeneration._generate(ColonyTests.world(),1,site,true,2)
		var clear: Dictionary=map.duplicate();clear.solid={}
		clear.resources=map.resources.filter(func(r:Dictionary)->bool:return r.guaranteed)
		for resource in clear.resources:
			if resource.definition in ["tree","stone_node","clay_bank","iron_seam"]:clear.solid[resource.point]=true
		var full: Dictionary=ColonyGeneration._reachable(map);var cleared: Dictionary=ColonyGeneration._reachable(clear)
		var rows: Array=[]
		for resource in map.resources:
			if resource.definition!="clay_bank":continue
			var a: int=100000;var b: int=100000
			for direction in ColonyNavigation.NEIGHBORS:
				a=mini(a,full.get(resource.point+direction,100000));b=mini(b,cleared.get(resource.point+direction,100000))
			rows.append({"x":resource.point.x,"y":resource.point.y,"with_woodland":a,"without_woodland":b})
		print(JSON.stringify({"site":site,"clay_approaches":rows}))
	quit(0)
