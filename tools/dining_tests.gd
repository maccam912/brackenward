class_name DiningTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var person: Dictionary = world.citizens[0]
	var pickup: Vector2i = Vector2i(80,80)
	check.call("MEAL/no_table_eats_at_pickup",ColonySocial.meal_seat(world,person,pickup)==pickup)
	var bottom: Dictionary = world._structure("table",Vector2i(80,82),0)
	world._structure("table",Vector2i(80,78),0)
	check.call("MEAL/equal_distance_prefers_table_id_before_tile",ColonySocial.meal_seat(world,person,pickup)==Vector2i(80,81))
	world.structures.reverse()
	check.call("MEAL/seat_choice_ignores_structure_storage_order",ColonySocial.meal_seat(world,person,pickup)==Vector2i(80,81))
	check.call("MEAL/equal_seats_use_row_major_tile",ColonySocial.meal_seat(world,person,Vector2i(bottom.x,bottom.y))==Vector2i(80,81))
	world=ColonyTests.world();person=world.citizens[0]
	world._structure("table",Vector2i(82,81),0)
	world._structure("table",Vector2i(80,85),0)
	for y in range(78,83): world._structure("wood_wall",Vector2i(81,y),0)
	check.call("MEAL/uses_path_distance_instead_of_manhattan",ColonySocial.meal_seat(world,person,pickup)==Vector2i(80,84))
	world=ColonyTests.world();person=world.citizens[0]
	var edge: Dictionary = world._structure("table",Vector2i(72,61),0)
	check.call("MEAL/twelve_tile_table_is_allowed",ColonySocial.meal_seat(world,person,Vector2i(60,60))==Vector2i(72,60))
	edge.x=73;world.navigation_dirty=true
	check.call("MEAL/thirteen_tile_table_is_ignored",ColonySocial.meal_seat(world,person,Vector2i(60,60))==Vector2i(60,60))
	world=ColonyTests.world();person=world.citizens[0]
	world._structure("table",Vector2i(80,82),0)
	var other: Dictionary = world.citizens[1]
	other.x=80;other.y=81
	var seated: Dictionary = world._job("leisure","","",other.id,Vector2i(80,81),0)
	seated.worker=other.id;seated.state="Working";other.job=seated.id
	check.call("MEAL/occupied_seat_is_not_taken",ColonySocial.meal_seat(world,person,pickup)==Vector2i(81,81))
	world._release(seated,true)
	check.call("MEAL/released_seat_becomes_available",ColonySocial.meal_seat(world,person,pickup)==Vector2i(80,81))
	world=ColonyTests.world();person=world.citizens[0]
	var burning: Dictionary = world._structure("table",Vector2i(70,61),0)
	ColonyFire.ignite(world,"structure",burning.id)
	check.call("MEAL/burning_table_is_not_a_dining_destination",ColonySocial.meal_seat(world,person,Vector2i(60,60))==Vector2i(60,60))
	world=ColonyTests.world();person=world.citizens[0]
	world.generator_version=1;world.terrain_state=ColonyGeneration.empty_state()
	world.terrain_state.elevation.resize(16384);world.terrain_state.elevation.fill(2)
	for y in range(79,83):
		for x in range(79,83): world.terrain_state.elevation[y*128+x]=4
	world._structure("table",Vector2i(80,80),0)
	check.call("MEAL/cliff_separated_table_is_not_reachable",ColonySocial.meal_seat(world,person,Vector2i(80,78))==Vector2i(80,78))
	world=CharterTests.supper_world()
	var accepted: String = ColonyCharter.command(world,"start_supper",{})
	for index in range(10): world.step()
	var wagon: Dictionary = ColonyTrade.cart(world)
	check.call("MEAL/communal_supper_keeps_its_reserved_seats",accepted=="accepted" and world.charter_state.supper.state=="Active" and ColonySocial.meal_seat(world,world.citizens[0],Vector2i(wagon.x,wagon.y))==Vector2i(wagon.x,wagon.y))
	physical_meal(check)

static func physical_meal(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	for resident in world.citizens:
		for category in resident.preferences: resident.preferences[category]=0
	var person: Dictionary = world.citizens[0]
	person.x=80;person.y=80;person.edge_x=80;person.edge_y=80;person.fullness=300
	world._structure("table",Vector2i(67,66),0)
	world._assign(person)
	var meal: Dictionary = world.find(world.jobs,person.job)
	check.call("MEAL/reserves_real_portion_and_nearby_table_destination",meal.get("kind")=="eat" and Vector2i(meal.work_x,meal.work_y)==Vector2i(67,65) and world.ledger.consumed.get("meal",0)==0)
	var carried: bool = false
	for index in range(600):
		world.step()
		carried=world.stacks.any(func(s:Dictionary)->bool:return s.location=="carry" and s.owner==person.id and s.job==meal.id and s.count==1)
		if carried: break
	check.call("MEAL/walks_to_pickup_and_carries_before_eating",carried and person.fullness<350 and world.ledger.consumed.get("meal",0)==0 and Vector2i(person.x,person.y)==Vector2i(66,63),str([carried,person.fullness,meal.state,world.ledger.consumed]))
	var restored: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/meal_table_route_and_held_portion_roundtrip",restored.has("world") and restored.world.canonical_hash()==world.canonical_hash(),str(restored.get("error","")))
	for index in range(300):
		world.step()
		if restored.has("world"): restored.world.step()
		if meal.state=="Complete": break
	check.call("MEAL/consumes_one_portion_only_after_seated_work",meal.state=="Complete" and meal.work==2000 and person.fullness>350 and Vector2i(person.x,person.y)==Vector2i(67,65) and world.ledger.consumed.get("meal",0)==1 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	check.call("SAVE/physical_dining_continuation_is_exact",restored.has("world") and restored.world.canonical_hash()==world.canonical_hash())
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://tests/fixtures/m6-before-table-dining-7200.brackenward")
	var legacy: Dictionary = ColonyCodec.decode(bytes)
	var original: Dictionary = ColonyState.unpack(JSON.parse_string(JSON.parse_string(bytes.get_string_from_utf8()).payload))
	var acknowledged: Dictionary = SchemaCompatibility.normalize(legacy.world,original) if legacy.has("world") else {}
	check.call("SAVE/pre_dining_m6_save_preserves_acknowledged_state",legacy.has("world") and legacy.world.schema_revision==ColonyWorld.SCHEMA_REVISION and JSON.stringify(ColonyState.pack(acknowledged),"",true).sha256_text()=="7503e2583def16f67d81735c214f17f22e541aec17fc47c4da53495fe787a22d",str(legacy.get("error","")))
	if not legacy.has("world"): return
	var legacy_copy: Dictionary = ColonyCodec.decode(ColonyCodec.encode(legacy.world))
	for index in range(300):
		legacy.world.step()
		if legacy_copy.has("world"): legacy_copy.world.step()
	check.call("SAVE/pre_dining_m6_continues_under_current_rules",legacy_copy.has("world") and legacy.world.canonical_hash()==legacy_copy.world.canonical_hash() and legacy.world.invariant_errors().is_empty(),str(legacy.world.invariant_errors()))
