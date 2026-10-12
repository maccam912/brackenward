class_name MaintenanceTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var wall: Dictionary = world._structure("wood_wall",Vector2i(74,54),0)
	wall.health=129
	world.queue_command("repair",{"target":wall.id});world.step()
	var job: Dictionary = world.jobs[0]
	check.call("REPAIR/exact_proportional_wu_and_single_rounding",job.amount==51 and job.required==5100 and job.inputs=={"wood":2})
	for i in range(600): world.step()
	check.call("REPAIR/physical_materials_restore_full_health",wall.health==180 and job.state=="Complete" and world.ledger.consumed.get("wood",0)==2 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();wall=world._structure("wood_wall",Vector2i(74,54),0)
	world.queue_command("demolish",{"target":wall.id})
	for i in range(500): world.step()
	check.call("DEMOLISH/half_wu_and_floor_half_materials",wall.health==0 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="demolish" and j.required==3000 and j.state=="Complete") and world.ledger.recovered.get("wood",0)==1 and world.total("wood")==45 and world.walkable(Vector2i(74,54)) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/ruin_and_reclaimed_ledger_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world.queue_command("rebuild",{"target":wall.id})
	for i in range(500): world.step()
	check.call("DEMOLISH/rebuild_at_ruin_uses_full_cost",world.structures.any(func(s:Dictionary)->bool:return s.definition=="wood_wall" and s.id!=wall.id and s.health==180 and s.x==74 and s.y==54) and world.ledger.consumed.get("wood",0)==2 and not world.walkable(Vector2i(74,54)) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world()
	var bench: Dictionary = world._structure("garden_bench",Vector2i(74,54),0)
	world.queue_command("demolish",{"target":bench.id});world.step()
	check.call("DEMOLISH/odd_wu_rounds_up_once",world.jobs[0].required==8000)
	var before: int = world.total("wood")
	world.queue_command("cancel",{"target":world.jobs[0].id});world.step()
	check.call("DEMOLISH/cancel_preserves_structure_and_materials",bench.health==200 and world.total("wood")==before and world.ledger.recovered.is_empty())
	world=ColonyTests.world()
	var rack: Dictionary = world._structure("rack",Vector2i(74,54),0)
	world.stores.append({"id":rack.id,"tiles":[Vector2i(74,54)],"capacity":120,"priority":2,"filters":world.definitions.items.keys()})
	var food: Dictionary = world._make_stack("meal",5,"store",rack.id,Vector2i(74,54),true);food.age=700;food.age_rem=3
	ColonyMaintenance.destroy(world,rack)
	check.call("DEMOLISH/stored_food_drops_without_age_reset",food.location=="ground" and food.owner==0 and food.count==5 and food.age==700 and food.age_rem==3 and world.stores.all(func(s:Dictionary)->bool:return s.id!=rack.id) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world()
	var hearth: Dictionary = world.structures[5]
	ColonyMaintenance.destroy(world,hearth)
	check.call("DEMOLISH/fuel_returns_as_real_stock",hearth.fuel==0 and world.total("wood")==44 and world.stacks.any(func(s:Dictionary)->bool:return s.location=="ground" and s.item=="wood" and s.count==4) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var bed: Dictionary = world.structures[0]
	ColonyMaintenance.destroy(world,bed)
	check.call("DEMOLISH/destroyed_bed_loses_assignment_and_rescue_use",world.citizens[0].bed==0 and ColonyCare.destination(world,world.citizens[0]).id!=bed.id)
	world=DomesticTests.setup()
	var pen: Dictionary = world.domestic_state.pens[0]
	var animal: Dictionary = ColonyDomestic.acquire(world,"hen",pen.id,pen.tiles[0]).animal
	var old_barn: Dictionary = world.find(world.structures,animal.barn)
	check.call("ROOF/catalog_barn_has_its_builtin_roof",world.roofed(Vector2i(old_barn.x,old_barn.y)))
	ColonyMaintenance.destroy(world,old_barn)
	check.call("ROOF/demolition_removes_builtin_roof",not world.roofed(Vector2i(old_barn.x,old_barn.y)) and ColonyDomestic.status(world,pen).capacity==0)
	var replacement: Dictionary = world._structure("barn",Vector2i(old_barn.x,old_barn.y),0)
	ColonyDomestic.create_jobs(world)
	check.call("ANIMALS/rebuilt_barn_reassigns_real_shelter",animal.barn==replacement.id and ColonyDomestic.status(world,pen).capacity==6)
	world=ColonyTests.world()
	var bridge: Dictionary = world._structure("bridge",Vector2i(32,48),0)
	check.call("BRIDGE/new_bridge_on_legacy_map_is_passable",not world.is_water(Vector2i(32,48)) and world.walkable(Vector2i(32,48)) and world.tile_move_cost(Vector2i(32,48))==10)
	ColonyMaintenance.destroy(world,bridge)
	check.call("BRIDGE/demolition_restores_water",world.is_water(Vector2i(32,48)) and not world.walkable(Vector2i(32,48)))
	world=ColonyTests.world();ColonyGeneration.configure(world,104729,"meadow_reach")
	bridge=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="bridge")[0]
	ColonyMaintenance.destroy(world,bridge)
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/removed_generated_bridge_and_forecast_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world=ColonyTests.world()
	var cart: Dictionary = world.structures[4]
	var reject: int = world.queue_command("demolish",{"target":cart.id});world.step()
	check.call("DEMOLISH/cart_remains_indestructible",cart.health>0 and world.jobs.is_empty() and world.receipts[reject].contains("cannot"))
	world=ColonyTests.world();world._make_stack("vegetable",8,"store",world.stores[0].id,Vector2i(66,63),true)
	for stack in world.stacks:
		if stack.item=="meal": world._record("consumed","meal",stack.count);stack.count=0
	var cooked: bool = false
	for i in range(500):
		world.step()
		var carried: int = 0
		for stack in world.stacks:
			if stack.location=="carry" and stack.owner==1: carried += stack.count
		cooked=cooked or carried==5
	check.call("HAUL/recipe_collects_five_inputs_in_one_carry",cooked and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var old: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-care.brackenward"))
	check.call("SAVE/expanded_ledger_keeps_old_conservation",old.has("world") and old.world.invariant_errors().is_empty() and old.world.ledger.recovered.is_empty(),str(old.get("error","")))
	world=ColonyTests.world();bench=world._structure("garden_bench",Vector2i(74,54),0);bench.health=150
	world.queue_command("move_furniture",{"target":bench.id,"x":84,"y":64,"rotation":1})
	var saw_bundle: bool = false;var maximum: int = 0
	for i in range(900):
		world.step()
		saw_bundle=saw_bundle or world.stacks.any(func(s:Dictionary)->bool:return s.location=="move_bundle" and s.count>0)
		for person in world.citizens:
			var carried: int = 0
			for stack in world.stacks:
				if stack.location=="carry" and stack.owner==person.id: carried += stack.count
			maximum=maxi(maximum,carried)
	check.call("MOVE/full_wu_physical_bundle_and_retained_health",bench.x==84 and bench.y==64 and bench.rotation==1 and bench.health==150 and saw_bundle and maximum<=8 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="move_furniture" and j.required==15000 and j.state=="Complete"))
	check.call("MOVE/materials_recovered_and_reused_without_minting",world.ledger.recovered.get("wood",0)==6 and world.ledger.consumed.get("wood",0)==6 and world.total("wood")==44 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/completed_furniture_move_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world=ColonyTests.world();bench=world._structure("garden_bench",Vector2i(74,54),0)
	world.queue_command("move_furniture",{"target":bench.id,"x":84,"y":64,"rotation":0})
	for i in range(800):
		world.step()
		if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="move_furniture" and j.memo.phase=="rebuild"): break
	job=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="move_furniture")[0]
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/reserved_move_bundle_and_partial_xp_roundtrip",job.memo.phase=="rebuild" and decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world.queue_command("cancel",{"target":job.id});world.step()
	check.call("MOVE/cancel_after_dismantling_keeps_real_materials",bench.health==0 and world.total("wood")==50 and world.ledger.recovered.get("wood",0)==6 and world.stacks.all(func(s:Dictionary)->bool:return s.location!="move_bundle" or s.count==0) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();bed=world.structures[0]
	world.queue_command("move_furniture",{"target":bed.id,"x":74,"y":64,"rotation":1})
	for i in range(700): world.step()
	check.call("MOVE/bed_identity_and_original_assignment_retained",bed.x==74 and bed.rotation==1 and world.citizens[0].bed==bed.id and bed.user==1 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();wall=world._structure("wood_wall",Vector2i(74,54),0)
	reject=world.queue_command("move_furniture",{"target":wall.id,"x":84,"y":64,"rotation":0});world.step()
	check.call("MOVE/walls_require_demolition_rebuild",world.receipts[reject].contains("demolition") and world.jobs.is_empty())
	world=ColonyTests.world();bench=world._structure("garden_bench",Vector2i(74,54),0)
	reject=world.queue_command("move_furniture",{"target":bench.id,"x":62,"y":59,"rotation":0});world.step()
	check.call("MOVE/invalid_destination_preserves_original",bench.health==200 and world.jobs.is_empty() and world.receipts[reject]!="accepted")
	world=ColonyTests.world();world.researched.append("woodcraft")
	var station: Dictionary = world._structure("workbench",Vector2i(74,54),0)
	world.queue_command("recipe_order",{"target":station.id,"definition":"make_toolkit","mode":"Repeat","value":1,"priority":2,"filters":[]});world.step()
	world.queue_command("move_furniture",{"target":station.id,"x":84,"y":64,"rotation":0})
	for i in range(1600): world.step()
	check.call("MOVE/station_policy_and_id_continue_after_move",station.x==84 and station.health>0 and world.production_state.orders[0].station==station.id and world.production_state.orders[0].enabled and world.ledger.produced.get("toolkit",0)==5 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();cart=world.structures[4]
	var stored_food: Dictionary = world.stacks.filter(func(s:Dictionary)->bool:return s.item=="meal")[0];stored_food.age=700
	var initial_hash: Dictionary = world.ledger.duplicate(true)
	world.queue_command("cart_move",{"target":cart.id,"x":74,"y":68})
	var saw_push: bool = false
	for i in range(1100):
		world.step()
		if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="cart_move" and j.memo.phase=="push" and j.state!="Complete"):
			if not saw_push:
				decoded=ColonyCodec.decode(ColonyCodec.encode(world))
				check.call("SAVE/cart_push_and_inventory_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
				saw_push=true
	check.call("CART/twenty_wu_push_keeps_real_goods_and_age",saw_push and cart.x==74 and cart.y==68 and stored_food.location=="store" and stored_food.owner==cart.id and stored_food.x==74 and stored_food.y==68 and stored_food.age>=700 and world.find(world.stores,cart.id).tiles==[Vector2i(74,68)] and world.ledger==initial_hash and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();cart=world.structures[4]
	reject=world.queue_command("cart_move",{"target":cart.id,"x":33,"y":48});world.step()
	check.call("CART/water_destination_is_rejected_before_work",world.jobs.is_empty() and cart.x==66 and world.receipts[reject].contains("two-by-two"))
	world=ColonyTests.world();cart=world.structures[4]
	world.queue_command("cart_move",{"target":cart.id,"x":78,"y":70})
	for i in range(600):
		world.step()
		if cart.x>=68: break
	job=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="cart_move")[0]
	var paused_position: Vector2i = Vector2i(cart.x,cart.y)
	var old_worker: Dictionary = world.find(world.citizens,job.worker)
	world._release(job,false);old_worker.preferences.Building=0
	for i in range(400): world.step()
	check.call("CART/worker_handoff_meets_cart_without_teleport",cart.x==78 and cart.y==70 and paused_position.x>=68 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
