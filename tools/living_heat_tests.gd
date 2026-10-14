class_name LivingHeatTests
extends RefCounted

class RoomProbe extends ColonyWorld:
	var roof_queries: int = 0
	func roofed(point: Vector2i) -> bool:
		roof_queries+=1;return super.roofed(point)

static func reference_heat(world: ColonyWorld) -> void:
	# Original loop: occupancy was searched even in warmth or with no fuel.
	for hearth in world.structures:
		if hearth.health<=0 or hearth.definition!="hearth": continue
		var occupied: bool = false
		for citizen in world.citizens:
			if citizen.death_recorded or citizen.departed: continue
			var point: Vector2i = Vector2i(citizen.x,citizen.y)
			occupied=occupied or absi(point.x-hearth.x)+absi(point.y-hearth.y)<=3 or (world.roofed(point) and world.room_tiles.get(point)==world.room_tiles.get(Vector2i(hearth.x,hearth.y),-1))
		if ColonyLiving.temperature(world)<8 and occupied and hearth.fuel>0:
			hearth.heat_ticks+=1
			if hearth.heat_ticks>=1800:
				hearth.heat_ticks-=1800;hearth.fuel-=1;world._record("consumed","wood",1)

static func run(check: Callable) -> void:
	for scenario in ["warm","summer","winter","cold_snap","unoccupied","unlit","same_room"]:
		var world: RoomProbe = RoomProbe.new(ColonyCatalog.load_data())
		world.tick=(8 if scenario=="summer" else (24 if scenario in ["winter","unoccupied","unlit","same_room"] else 0))*7200+1801
		world.weather="cold_snap" if scenario=="cold_snap" else "clear";ColonyWeather.initialize(world)
		var hearth: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
		hearth.heat_ticks=1799
		if scenario=="same_room":
			for x in range(74,84): world._structure("wood_wall",Vector2i(x,68),0);world._structure("wood_wall",Vector2i(x,74),0)
			for y in range(69,74): world._structure("door" if y==70 else "wood_wall",Vector2i(74,y),0);world._structure("wood_wall",Vector2i(83,y),0)
			hearth.x=75;hearth.y=69
		if scenario=="unlit": world._record("consumed","wood",hearth.fuel);hearth.fuel=0
		for person in world.citizens: person.x=90;person.y=90
		if scenario!="unoccupied": world.citizens[0].x=hearth.x-1;world.citizens[0].y=hearth.y
		if scenario=="same_room": world.citizens[0].x=80;world.citizens[0].y=71
		for person in world.citizens: person.edge_x=person.x;person.edge_y=person.y
		var decoded: Dictionary = ColonyCodec.restore(world.payload().duplicate(true))
		if not decoded.has("world"): check.call("LIVING/heat_fixture_"+scenario,false,str(decoded));continue
		var expected: ColonyWorld = decoded.world
		reference_heat(expected);ColonyLiving.advance(world)
		check.call("LIVING/heating_matches_original_"+scenario,world.structures==expected.structures and world.ledger.consumed.get("wood",0)==expected.ledger.consumed.get("wood",0) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
		if scenario in ["warm","summer","unlit"]:
			check.call("LIVING/no_room_search_for_inactive_heating_"+scenario,world.roof_queries==0,str(world.roof_queries))
