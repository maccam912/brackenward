extends SceneTree
## Stream raw accepted map data; an independent external program checks geometry.
const GOLDEN_SEEDS: Array[int]=[0,1,42,104729,2147483647,4294967295]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=3 or not ColonyGeneration.SITES.has(args[0]) or not args[1].is_valid_int() or not args[2].is_valid_int():printerr("Usage: -- SITE START_INDEX COUNT");quit(2);return
	var first: int=int(args[1]);var count: int=int(args[2])
	if first<0 or count<1 or first+count>10000:printerr("Case range must fit 0..9999");quit(2);return
	for index in range(first,first+count):
		var entered: int
		if index<GOLDEN_SEEDS.size():entered=GOLDEN_SEEDS[index]
		else:
			var digest: PackedByteArray=("brackenward-map-sweep-v1|%d" % index).sha256_buffer()
			entered=(int(digest[0])<<24)|(int(digest[1])<<16)|(int(digest[2])<<8)|int(digest[3])
		var started: int=Time.get_ticks_usec()
		var world: ColonyWorld=ColonyTests.world()
		var error: String=ColonyGeneration.configure(world,entered,args[0])
		if not error.is_empty():printerr("Generation rejected %s/%d: %s" % [args[0],entered,error]);quit(1);return
		var map: Dictionary={"format":"brackenward-raw-map","version":1,"index":index,"seed":entered,"site":args[0],"generator":world.generator_version,"content_hash":world.definitions.content_hash,"transform":world.terrain_state.transform,"attempt":world.terrain_state.attempt,"fallback":world.terrain_state.fallback,"diagnostics":world.terrain_state.diagnostics,"elevation":world.terrain_state.elevation,"fertility":world.terrain_state.fertility,"paths":points(world.terrain_state.paths),"bridges":points(world.terrain_state.bridges),"starter_field":points(world.terrain_state.starter_field),"habitats":{},"resources":[],"structures":[],"citizens":[],"animals":[],"regions":world.region_state.nodes}
		for species in world.terrain_state.habitats:map.habitats[species]=points(world.terrain_state.habitats[species])
		map["weather"]=world.weather
		for resource in world.resources:map.resources.append({"id":resource.id,"definition":resource.definition,"x":resource.x,"y":resource.y,"remaining":resource.remaining})
		for structure in world.structures:map.structures.append({"id":structure.id,"definition":structure.definition,"x":structure.x,"y":structure.y,"rotation":structure.rotation,"health":structure.health,"user":structure.get("user",0)})
		for person in world.citizens:map.citizens.append({"id":person.id,"x":person.x,"y":person.y,"bed":person.bed})
		for animal in world.wildlife_state.animals:map.animals.append({"id":animal.id,"definition":animal.definition,"x":animal.x,"y":animal.y})
		var payload: String=JSON.stringify(map,"",true)
		print("GENMAP "+JSON.stringify({"payload":payload,"sha256":payload.sha256_text(),"canonical_hash":world.canonical_hash() if index<6 else "","generation_us":Time.get_ticks_usec()-started},"",true))
	quit(0)

func points(value: Array) -> Array:
	return value.map(func(p:Vector2i)->Array:return [p.x,p.y])
