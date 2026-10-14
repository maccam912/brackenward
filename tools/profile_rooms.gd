extends SceneTree
## Uncached room flood-fill timing, with ordered geometry and state preservation.
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()!=2 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>100: printerr("Usage: -- SNAPSHOT ITERATIONS (1..100)");quit(2);return
	var decoded: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"): printerr(decoded);quit(2);return
	var world: ColonyWorld = decoded.world
	var original: String = world.canonical_hash()
	var timings: Array[int] = []
	var hashes: Array[String] = []
	for index in range(int(args[1])):
		var started: int = Time.get_ticks_usec()
		var rooms: Dictionary = ColonyRooms.compute(world)
		timings.append(Time.get_ticks_usec()-started)
		hashes.append(RoomGeometryTests.fingerprint(rooms).sha256)
	timings.sort()
	var result: Dictionary = {"snapshot":args[0],"iterations":int(args[1]),"host":OS.get_name(),"p50_us":timings[timings.size()/2],"p95_us":timings[mini(timings.size()-1,timings.size()*95/100)],"min_us":timings[0],"max_us":timings[-1],"ordered_room_sha256":hashes[0],"stable":hashes.all(func(value:String)->bool:return value==hashes[0]),"canonical_preserved":world.canonical_hash()==original,"scope":"Uncached native CPU room computation; no physical device/GPU claim"}
	print(JSON.stringify(result))
	quit(0 if result.stable and result.canonical_preserved else 1)
