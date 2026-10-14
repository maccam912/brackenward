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
