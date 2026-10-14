class_name PolicyTests
extends RefCounted
## Scenario planner fixtures; these are not ordinary-play campaign certificates.

static func run(check: Callable) -> void:
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
