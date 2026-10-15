class_name FoodCandidatesTests
extends RefCounted
const Reference = preload("res://tools/food_candidates_reference.gd")

class ReplacedInventoryWorld extends ColonyWorld:
	var inventory_view: Array=[]
	func _work_inventory() -> Array:
		return inventory_view

static func clone_world(source: ColonyWorld, original: bool=false) -> ColonyWorld:
	var result: ColonyWorld=Reference.new(source.definitions) if original else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]:continue
		var value: Variant=source.get(field)
		if value is Array:result.get(field).assign(value.duplicate(true))
		elif value is Dictionary:result.set(field,value.duplicate(true))
		else:result.set(field,value)
	result.reset_job_queries();result.reset_stack_queries();result.reset_resource_queries();result.record_indexes.clear()
	result.navigation_dirty=true;result.rooms_dirty=true;result.reachability_dirty=true
	return result

static func same_candidates(world: ColonyWorld) -> bool:
	var expected: Array=world._work_inventory().filter(func(s:Dictionary)->bool:return world.definitions.items[s.item].fullness>0)
	var actual: Array=world._work_food()
	if expected.size()!=actual.size():return false
	for index in range(expected.size()):
		if not is_same(expected[index],actual[index]):return false
	return true

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();world.in_tick=true;world.use_rations=false
	for location in ["ground","store","carry","escrow","move_bundle","expedition_cargo"]:
		world._make_stack("meal",2,location,1,Vector2i(80,80),true)
		world._make_stack("wood",2,location,1,Vector2i(80,80),true)
	var ration: Dictionary=world._make_stack("travel_ration",2,"ground",0,Vector2i(81,80),true)
	var before: String=world.canonical_hash();var rows: Array=world._work_food()
	check.call("FOOD/candidate_view_keeps_all_locations_live_records_and_rations_independent_of_policy",same_candidates(world) and rows.has(ration) and rows.filter(func(s:Dictionary)->bool:return s.item=="meal" and s.x==80 and s.y==80).size()==6 and world.canonical_hash()==before)
	var old_size: int=rows.size();var fresh: Dictionary=world._make_stack("berry",1,"ground",0,Vector2i(82,80),true)
	world._work_inventory();world._record("consumed",fresh.item,fresh.count);fresh.count=0
	var exact: bool=same_candidates(world) and world._work_food().size()==old_size+1 and world._work_food().has(fresh)
	world.tick+=1;exact=exact and same_candidates(world) and not world._work_food().has(fresh)
	world.stacks=world.stacks.duplicate(true);exact=exact and same_candidates(world)
	world.stacks.resize(1);exact=exact and same_candidates(world)
	world.in_tick=false;before=world.canonical_hash();rows=world._work_food();rows.clear()
	check.call("FOOD/same_tick_zero_tail_next_tick_and_replaced_tables_match_inventory_membership",exact and world.food_query_tick==-1 and world._work_food()==world.nonempty_stacks() and world.canonical_hash()==before)
	var changed_view: ReplacedInventoryWorld=ReplacedInventoryWorld.new(ColonyCatalog.load_data())
	var first_view_row: Dictionary=changed_view._make_stack("meal",1,"ground",0,Vector2i(80,80),true)
	var second_view_row: Dictionary=changed_view._make_stack("berry",1,"ground",0,Vector2i(81,80),true)
	changed_view.in_tick=true;changed_view.inventory_view=[first_view_row]
	var first_ids: Array=changed_view._work_food().map(func(s:Dictionary)->int:return s.id)
	changed_view.inventory_view=[second_view_row]
	check.call("FOOD/same_size_replaced_borrowed_inventory_uses_new_live_rows",first_ids==[first_view_row.id] and changed_view._work_food().map(func(s:Dictionary)->int:return s.id)==[second_view_row.id] and same_candidates(changed_view))

	world=ColonyTests.world();var person: Dictionary=world.citizens[0];person.x=80;person.y=80
	for stack in world.stacks:
		if world.definitions.items[stack.item].fullness>0:world._record("consumed",stack.item,stack.count);stack.count=0
	var target: int=world.resources[0].id
	var current_job: Dictionary=world._job("gather","Gathering","Field",target,Vector2i(80,80),1000);current_job.worker=1;person.job=current_job.id
	var foreign: Dictionary=world._job("gather","Gathering","Field",target,Vector2i(81,80),1000);foreign.worker=2;world.citizens[1].job=foreign.id
	var meal: Dictionary=world._make_stack("meal",3,"ground",0,Vector2i(80,81),true);meal.age=500
	var berries: Dictionary=world._make_stack("berry",3,"ground",0,Vector2i(81,80),true);berries.age=500
	ration=world._make_stack("travel_ration",3,"ground",0,Vector2i(82,80),true);ration.age=700
	var cargo: Dictionary=world._make_stack("meal",1,"carry",1,Vector2i(10,10),true);cargo.job=current_job.id;cargo.age=900
	var prior: ColonyWorld=clone_world(world,true);world.in_tick=true;prior.in_tick=true;exact=true;var cases: int=0
	for policy in [false,true]:
		for tag in ["Vegetable","Berry","Meat"]:
			for release in [false,true]:
				world.use_rations=policy;prior.use_rations=policy;person.food_tag=tag;prior.citizens[0].food_tag=tag
				var current_before: String=world.canonical_hash();var old_before: String=prior.canonical_hash()
				var actual: Dictionary=world._food(person,current_job if release else {})
				var expected: Dictionary=prior._food(prior.citizens[0],prior.find(prior.jobs,current_job.id) if release else {})
				exact=exact and actual.get("id")==expected.get("id") and world.canonical_hash()==current_before and prior.canonical_hash()==old_before;cases+=1
	meal.reservations[foreign.id]=3;prior.find(prior.stacks,meal.id).reservations[foreign.id]=3
	world._make_stack("berry",1,"ground",0,Vector2i(80,80),true).age=1000
	prior._make_stack("berry",1,"ground",0,Vector2i(80,80),true).age=1000
	exact=exact and world._food(person).get("id")==prior._food(prior.citizens[0]).get("id") and same_candidates(world)
	check.call("FOOD/full_original_selector_matches_policy_tags_live_reservations_release_predictions_and_new_rows",exact and cases==12)

	world=ColonyTests.world();world.citizens[0].fullness=0;world.in_tick=true;world._food(world.citizens[0]);world.in_tick=false
	var payload: Dictionary=world.payload();var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world));prior=clone_world(world,true)
	exact=decoded.has("world") and not payload.has("food_query_live") and not payload.has("food_query_tick") and not payload.has("food_query_count") and not payload.has("food_query_source") and decoded.world.food_query_tick==-1 and decoded.world.food_query_live.is_empty() and decoded.world.food_query_source.is_empty()
	if decoded.has("world"):
		for tick in range(240):world.step();prior.step();decoded.world.step()
		exact=exact and world.canonical_hash()==prior.canonical_hash() and world.canonical_hash()==decoded.world.canonical_hash() and world.invariant_errors().is_empty()
	check.call("FOOD/derived_candidates_never_enter_saves_and_hungry_future_matches_original_after_reload",exact)
