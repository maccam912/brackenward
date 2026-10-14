class_name RoomGeometryTests
extends RefCounted
const PATTERNS: Array[String] = ["empty","small","limit64","limit65","partition","hole","edge","water","bridged","builtins"]

static func fixtures() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for site in ["authored","meadow_reach","pine_shelf","reed_bend"]:
		var base: ColonyWorld = ColonyTests.world()
		if site!="authored":
			var error: String = ColonyGeneration.configure(base,104729,site)
			if not error.is_empty(): printerr(error);return []
		for pattern in PATTERNS:
			var restored: Dictionary = ColonyCodec.restore(base.payload().duplicate(true))
			if not restored.has("world"): printerr(restored);return []
			var world: ColonyWorld = restored.world
			match pattern:
				"small": shell(world,Vector2i(74,74),Vector2i(6,6))
				"limit64": shell(world,Vector2i(74,74),Vector2i(10,10))
				"limit65": shell(world,Vector2i(74,74),Vector2i(15,7))
				"partition":
					shell(world,Vector2i(74,74),Vector2i(14,6))
					for y in range(75,79): world._structure("door" if y==77 else "wood_wall",Vector2i(81,y),0)
				"hole":
					shell(world,Vector2i(74,74),Vector2i(6,6))
					world.structures[-1].health=0
				"edge": shell(world,Vector2i(0,80),Vector2i(6,6))
				"water","bridged":
					shell(world,Vector2i(29,58),Vector2i(9,8))
					if pattern=="bridged":
						for y in range(59,65):
							for x in range(30,37):
								if world.is_water(Vector2i(x,y)): world._structure("bridge",Vector2i(x,y),0)
				"builtins":
					shell(world,Vector2i(88,88),Vector2i(8,7))
					world._structure("barn",Vector2i(90,90),0)
					world._structure("barn",Vector2i(93,92),1)
					world._structure("barn",Vector2i(103,102),2)
			result.append({"id":site+"/"+pattern,"world":world})
	return result

static func shell(world: ColonyWorld, origin: Vector2i, extent: Vector2i) -> void:
	for y in range(extent.y):
		for x in range(extent.x):
			if x not in [0,extent.x-1] and y not in [0,extent.y-1]: continue
			world._structure("door" if Vector2i(x,y)==Vector2i(extent.x/2,extent.y-1) else "wood_wall",origin+Vector2i(x,y),0)

static func fingerprint(rooms: Dictionary) -> Dictionary:
	var ordered: Array = []
	for point in rooms: ordered.append([point.y*128+point.x,rooms[point]])
	return {"tiles":rooms.size(),"sha256":JSON.stringify(ordered).sha256_text()}

static func run(check: Callable) -> void:
	var frozen: Dictionary = ColonyState.unpack(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/room-connectivity-golden.json")))
	var inputs: Array[Dictionary] = fixtures()
	check.call("ROOM/all_geometry_fixtures_are_present",inputs.size()==40 and frozen.cases.size()==40)
	for fixture in inputs:
		var actual: Dictionary = fingerprint(ColonyRooms.compute(fixture.world))
		check.call("ROOM/frozen_membership_labels_and_order_"+fixture.id,actual==frozen.cases.get(fixture.id),str(actual)+" expected "+str(frozen.cases.get(fixture.id)))
