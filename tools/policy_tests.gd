class_name PolicyTests
extends RefCounted
## Scenario planner fixtures; these are not ordinary-play campaign certificates.

static func run(check: Callable) -> void:
	finished_defense(check)
	beds_and_doors(check)
	entrance_trees(check)
	var world: ColonyWorld = ColonyTests.world()
	var accepted: String = ColonyRegion.prepare(world,RegionTests.args())
	var trip: Dictionary = ColonyRegion.active(world)
	world.tick=24*7200
	var policy: ColonyPolicy = ColonyPolicy.new("vegetarian_charter")
	var ledger: Dictionary = world.ledger.duplicate(true)
	policy._expedition(world)
	check.call("POLICY/cancels_packing_after_site_season_closes",accepted=="accepted" and world.pending_commands.size()==1 and world.pending_commands[0].kind=="expedition_cancel" and world.pending_commands[0].args.target==trip.id and world.ledger==ledger)
	ColonyRegion.command(world,"expedition_cancel",{"target":trip.id})
	check.call("POLICY/season_cancel_preserves_real_cargo_and_residents",world.total("travel_ration")==8 and world.citizens.all(func(c:Dictionary)->bool:return c.expedition==0 and not c.away))
	world=CharterTests.supper_world()
	world.tick=24*7200;world.researched.append("trailcraft")
	var cart: Dictionary = ColonyTrade.cart(world)
	world._make_stack("meal",48,"store",cart.id,Vector2i(cart.x,cart.y),true)
	world._make_stack("travel_ration",24,"store",cart.id,Vector2i(cart.x,cart.y),true)
	policy=ColonyPolicy.new("vegetarian_charter");ledger=world.ledger.duplicate(true)
	var next_id: int = world.next_id
	policy._expedition(world)
	check.call("POLICY/chooses_available_causeway_during_winter",world.pending_commands.size()==1 and world.pending_commands[0].kind=="expedition_prepare" and world.pending_commands[0].args.definition=="broken_causeway",str(world.pending_commands))
	check.call("POLICY/planning_only_queues_public_commands",world.ledger==ledger and world.next_id==next_id and world.tick==24*7200)
	world=ColonyTests.world();policy=ColonyPolicy.new("vegetarian_charter")
	accepted=ColonyRegion.prepare(world,RegionTests.args());trip=ColonyRegion.active(world)
	policy._expedition(world)
	check.call("POLICY/unfinished_packing_is_allowed_to_progress",accepted=="accepted" and world.pending_commands.is_empty())
	for index in range(1800):
		world.step()
		if trip.state=="Ready": break
	check.call("POLICY/spoilage_fixture_physically_packs_cargo_first",trip.state=="Ready" and world.find(world.jobs,trip.pack_job).state=="Complete" and ColonyRegion.cargo(world,trip).get("travel_ration",0)==8)
	for stack in world.stacks:
		if stack.location=="expedition_cargo" and stack.owner==trip.id and stack.item=="travel_ration": stack.age=world.definitions.items.travel_ration.shelf_ticks-1
	ColonyLiving.advance(world)
	policy._expedition(world)
	check.call("POLICY/spoiled_completed_packing_uses_public_cancel",world.pending_commands.size()==1 and world.pending_commands[0].kind=="expedition_cancel" and ColonyRegion.cargo(world,trip).get("travel_ration",0)==0 and world.ledger.spoiled.get("travel_ration",0)==8 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=CharterTests.supper_world();world.tick=24*7200;world.researched.append("trailcraft")
	cart=ColonyTrade.cart(world)
	world._make_stack("meal",48,"store",cart.id,Vector2i(cart.x,cart.y),true)
	world._make_stack("travel_ration",24,"store",cart.id,Vector2i(cart.x,cart.y),true)
	for person in world.citizens:
		if person.id>4: person.fullness=384
	policy=ColonyPolicy.new("vegetarian_charter");policy._expedition(world)
	check.call("POLICY/cook_is_eligible_when_four_needed_and_home_forecast_is_safe",world.pending_commands.size()==1 and world.pending_commands[0].kind=="expedition_prepare" and world.pending_commands[0].args.definition=="broken_causeway" and world.pending_commands[0].args.party.size()==4 and world.pending_commands[0].args.party.has(1),str(world.pending_commands))
	storage(check)

static func storage(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var policy: ColonyPolicy = ColonyPolicy.new("vegetarian_charter")
	check.call("POLICY/storage_expands_only_for_a_real_blocked_reason",not policy._unblock_storage(world) and world.pending_commands.is_empty())
	var stack: Dictionary = world.stacks[0]
	var blocked: Dictionary = world._job("haul","Hauling","",stack.id,Vector2i(stack.x,stack.y),0)
	blocked.source=stack.id;blocked.state="Blocked";blocked.reason="No storage space: paint a stockpile or build a rack"
	var ledger: Dictionary = world.ledger.duplicate(true)
	var planned: bool = policy._unblock_storage(world)
	check.call("POLICY/storage_queues_sixteen_safe_clear_tiles_without_grants",planned and world.pending_commands.size()==1 and world.pending_commands[0].kind=="stockpile" and world.pending_commands[0].args.tiles.size()==16 and world.ledger==ledger)
	var command: int = world.pending_commands[0].id if planned else 0
	world.step()
	check.call("POLICY/storage_designation_accepts_through_normal_command_path",planned and world.receipts.get(command)=="accepted" and world.ledger==ledger and world.stores[-1].tiles.size()==16)
	policy._unblock_storage(world);world.step()
	check.call("POLICY/storage_expansion_stops_after_two_designations",not policy._unblock_storage(world) and world.stores.filter(func(s:Dictionary)->bool:return world.find(world.structures,s.id).is_empty()).size()==2)

static func finished_defense(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var policy: ColonyPolicy = ColonyPolicy.new("vegetarian_charter")
	policy._defense(world,world.citizens)
	check.call("POLICY/quiet_colony_does_not_issue_defense_commands",world.pending_commands.is_empty())
	var raid: Dictionary = ColonyDefense.announce(world,2);raid.state="Resolved"
	world.citizens[0].drafted=true
	var ledger: Dictionary = world.ledger.duplicate(true);var next_id: int = world.next_id
	policy._defense(world,world.citizens)
	check.call("POLICY/missed_retreat_window_queues_public_stand_down",world.pending_commands.size()==1 and world.pending_commands[0].kind=="stand_down" and world.citizens[0].drafted and world.ledger==ledger and world.next_id==next_id)
	policy._defense(world,world.citizens)
	check.call("POLICY/stand_down_is_not_duplicated_while_pending",world.pending_commands.size()==1)
	var command: int = world.pending_commands[0].id
	world.step()
	check.call("POLICY/completed_raid_stand_down_applies_through_normal_command",world.receipts.get(command)=="accepted" and world.citizens.all(func(c:Dictionary)->bool:return not c.drafted) and world.ledger==ledger)

static func beds_and_doors(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var policy: ColonyPolicy = ColonyPolicy.new("vegetarian_charter")
	var ledger: Dictionary = world.ledger.duplicate(true)
	var bed: Dictionary = world._structure("bed",Vector2i(74,64),0)
	var roll: Dictionary = world.find(world.structures,world.citizens[0].bed)
	check.call("POLICY/bed_upgrade_queues_public_assignment_without_grants",policy._assign_beds(world) and world.pending_commands.size()==1 and world.pending_commands[0].kind=="assign_bed" and world.pending_commands[0].args=={"citizen":1,"target":bed.id} and world.ledger==ledger)
	check.call("POLICY/bed_upgrade_never_double_reserves_pending_bed",not policy._assign_beds(world) and world.pending_commands.size()==1)
	world.step()
	check.call("POLICY/bed_upgrade_applies_reciprocal_real_ownership",world.citizens[0].bed==bed.id and bed.user==1 and roll.user==0 and not policy._assign_beds(world) and world.ledger==ledger)
	world=ColonyTests.world();policy=ColonyPolicy.new("vegetarian_charter")
	var origin: Vector2i = policy._empty_room(world)
	var door: Dictionary = world._structure("door",origin+Vector2i(-1,2),1)
	var protected: Vector2i = Vector2i(door.x+1,door.y)
	var next: Vector2i = policy._empty_room(world)
	check.call("POLICY/new_room_preserves_built_door_approach",origin.x>=0 and next.x>=0 and next!=origin and not Rect2i(next,Vector2i(8,6)).has_point(protected))
	world=ColonyTests.world();policy=ColonyPolicy.new("vegetarian_charter");origin=policy._empty_room(world)
	var job: Dictionary = world._job("build","Building","Build",0,origin+Vector2i(-1,2),6000)
	job.definition="door";job.rotation=1
	next=policy._empty_room(world)
	check.call("POLICY/new_room_preserves_blueprint_door_approach",next.x>=0 and next!=origin and not Rect2i(next,Vector2i(8,6)).has_point(origin+Vector2i(0,2)))
	world=ColonyTests.world();policy=ColonyPolicy.new("vegetarian_charter")
	policy.lodge_origins.assign([Vector2i(56,65),Vector2i(56,71)])
	var blocked_wall: Dictionary = {}
	for lodge in policy.lodge_origins:
		for y in range(6):
			for x in range(8):
				if x not in [0,7] and y not in [0,5]: continue
				var structure: Dictionary = world._structure("door" if Vector2i(x,y)==Vector2i(4,5) else "wood_wall",lodge+Vector2i(x,y),0)
				if lodge+Vector2i(x,y)==Vector2i(60,71): blocked_wall=structure
	ledger=world.ledger.duplicate(true)
	check.call("POLICY/adjacent_old_lodge_repair_queues_real_demolition_only",not blocked_wall.is_empty() and not world.accessible(Vector2i(60,70)) and policy._repair_lodge_access(world) and world.pending_commands.size()==1 and world.pending_commands[0].kind=="demolish" and world.pending_commands[0].args.target==blocked_wall.id and blocked_wall.health>0 and world.ledger==ledger)
	check.call("POLICY/adjacent_lodge_repair_is_not_duplicated_while_pending",not policy._repair_lodge_access(world) and world.pending_commands.size()==1)
	var command: int = world.pending_commands[0].id
	world.step()
	check.call("POLICY/adjacent_lodge_repair_accepts_without_instant_removal",world.receipts.get(command)=="accepted" and world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="demolish" and j.target==blocked_wall.id) and blocked_wall.health>0)
	for tick in range(1600):
		world.step()
		if blocked_wall.health==0: break
	check.call("POLICY/adjacent_lodge_repair_physically_reopens_both_rooms",blocked_wall.health==0 and world.accessible(Vector2i(60,70)) and world.roofed(Vector2i(60,69)) and world.roofed(Vector2i(60,72)) and world.ledger.recovered.get("wood")==1 and world.invariant_errors().is_empty(),str({"wall_health":blocked_wall.health,"access":world.accessible(Vector2i(60,70)),"roof_first":world.roofed(Vector2i(60,69)),"roof_second":world.roofed(Vector2i(60,72)),"recovered":world.ledger.recovered,"jobs":world.unfinished_jobs(),"errors":world.invariant_errors()}))

static func tree_at(world: ColonyWorld, point: Vector2i, planted: bool = false, mature: bool = false) -> Dictionary:
	var resource: Dictionary={"id":world._id(),"definition":"tree","x":point.x,"y":point.y,"remaining":8 if mature else 0,"regrow_at":0}
	world.resources.append(resource)
	if planted: world.nature_state.trees[resource.id]={"planted":true,"age":100,"cleared":false}
	world.navigation_dirty=true;world.reachability_dirty=true
	return resource

static func enclosed_tree_world() -> ColonyWorld:
	var world: ColonyWorld=ColonyTests.world()
	for y in range(60,66):
		for x in range(68,76):
			if x in [68,75] or y in [60,65]: world._structure("door" if Vector2i(x,y)==Vector2i(72,65) else "wood_wall",Vector2i(x,y),0)
	tree_at(world,Vector2i(72,66),false,true)
	world.citizens[0].x=69;world.citizens[0].y=61;world.citizens[0].fullness=300
	world.citizens[0].edge_x=69;world.citizens[0].edge_y=61
	return world

static func entrance_trees(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	var policy: ColonyPolicy=ColonyPolicy.new("first_winter")
	var door: Dictionary=world._structure("door",Vector2i(90,80),0)
	var stump: Dictionary=tree_at(world,Vector2i(90,81))
	var canonical: String=world.canonical_hash()
	check.call("POLICY/door_approach_query_is_oriented_and_pure",ColonyNature.door_approach(world,Vector2i(90,81)) and ColonyNature.door_approach(world,Vector2i(90,79)) and not ColonyNature.door_approach(world,Vector2i(91,80)) and canonical==world.canonical_hash())
	policy._replant_trees(world)
	check.call("POLICY/never_replants_a_completed_door_approach",world.pending_commands.is_empty() and world.canonical_hash()==canonical)
	door.rotation=1
	check.call("POLICY/horizontal_door_protects_left_and_right_approaches",ColonyNature.door_approach(world,Vector2i(91,80)) and ColonyNature.door_approach(world,Vector2i(89,80)) and not ColonyNature.door_approach(world,Vector2i(90,81)))
	var job: Dictionary=world._job("build","Building","Build",0,Vector2i(90,82),6000);job.definition="door";job.rotation=0
	job.state="Queued"
	canonical=world.canonical_hash();policy._replant_trees(world)
	check.call("POLICY/queued_door_approach_is_protected_before_completion",ColonyNature.door_approach(world,Vector2i(90,81)) and world.pending_commands.is_empty() and world.canonical_hash()==canonical)
	job.state="Canceled";policy.lodge_origins.assign([Vector2i(86,75)])
	canonical=world.canonical_hash();policy._replant_trees(world)
	check.call("POLICY/planned_lodge_approach_is_protected_before_blueprints",world.pending_commands.is_empty() and world.canonical_hash()==canonical)
	policy.lodge_origins.clear();policy.grow_origin=Vector2i(87,75)
	policy._replant_trees(world)
	check.call("POLICY/planned_grow_room_approach_is_protected",world.pending_commands.is_empty())
	policy.grow_origin=Vector2i(-1,-1)
	var ledger: Dictionary=world.ledger.duplicate(true);var next_id: int=world.next_id
	policy._replant_trees(world)
	check.call("POLICY/ordinary_stump_still_uses_public_replant_without_grants",world.pending_commands.size()==1 and world.pending_commands[0].kind=="replant_tree" and world.pending_commands[0].args.target==stump.id and world.next_id==next_id and world.ledger==ledger)
	world=ColonyTests.world();policy=ColonyPolicy.new("first_winter")
	var origin: Vector2i=policy._empty_room(world)
	var sapling: Dictionary=tree_at(world,origin+Vector2i(4,6),true)
	canonical=world.canonical_hash();var alternative: Vector2i=policy._empty_room(world)
	check.call("POLICY/new_lodge_avoids_future_solid_sapling_at_exit",origin.x>=0 and alternative.x>=0 and alternative!=origin and world.canonical_hash()==canonical)
	world=ColonyTests.world();policy=ColonyPolicy.new("first_winter")
	origin=policy._empty_room(world,3);tree_at(world,origin+Vector2i(3,6),true)
	check.call("POLICY/grow_room_checks_its_actual_offset_entrance",policy._empty_room(world,3)!=origin)
	world=ColonyTests.world();policy=ColonyPolicy.new("first_winter")
	world._structure("door",Vector2i(90,80),0);sapling=tree_at(world,Vector2i(90,81),true)
	ledger=world.ledger.duplicate(true);next_id=world.next_id
	check.call("POLICY/old_entrance_sapling_queues_real_clear_work",policy._repair_entrance_trees(world) and world.pending_commands.size()==1 and world.pending_commands[0].kind=="clear_sapling" and world.pending_commands[0].args.target==sapling.id and world.next_id==next_id and world.ledger==ledger and ColonyNature.tree(world,sapling.id).planted)
	check.call("POLICY/entrance_clear_is_not_duplicated_while_pending",not policy._repair_entrance_trees(world) and world.pending_commands.size()==1)
	world=enclosed_tree_world();policy=ColonyPolicy.new("first_winter")
	var person: Dictionary=world.citizens[0];var tree: Dictionary=world.resources[-1]
	check.call("POLICY/seed73_geometry_traps_hungry_resident_despite_stocks",world._food(person).is_empty() and FoodForecast.calculate(world).portions>0 and tree.remaining==8 and world.invariant_errors().is_empty())
	ledger=world.ledger.duplicate(true)
	check.call("POLICY/mature_entrance_repair_queues_cut_without_instant_removal",policy._repair_entrance_trees(world) and world.pending_commands.size()==1 and world.pending_commands[0].kind=="gather" and tree.remaining==8 and world.ledger==ledger)
	world.step()
	var copy: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("POLICY/blocked_room_repair_roundtrips_with_real_queued_work",copy.has("world") and copy.world.canonical_hash()==world.canonical_hash())
	if not copy.has("world"): return
	var resumed: ColonyWorld=copy.world
	for tick in range(1600):
		world.step();resumed.step()
		if tree.remaining==0 and person.fullness>500: break
	check.call("POLICY/real_gathering_opens_exit_and_resident_physically_eats",tree.remaining==0 and person.fullness>500 and person.health==100 and world.ledger.produced.get("wood",0)==ledger.produced.get("wood",0)+8 and world.invariant_errors().is_empty(),str([person.fullness,person.health,tree.remaining,world.invariant_errors()]))
	check.call("POLICY/entrance_repair_save_continuation_remains_exact",resumed.canonical_hash()==world.canonical_hash())
