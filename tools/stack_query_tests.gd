class_name StackQueryTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var starting_records: int = world.stacks.size()
	for stack in world.stacks:
		world._record("consumed",stack.item,stack.count);stack.count=0
	for index in range(5000):
		var old: Dictionary = world._make_stack("wood",1,"ground",0,Vector2i(80,80),true)
		old.count=0;world._record("consumed","wood",1)
	var cart: Dictionary = ColonyTrade.cart(world)
	var first: Dictionary = world._make_stack("meal",2,"store",cart.id,Vector2i(cart.x,cart.y),true)
	var second: Dictionary = world._make_stack("wood",7,"store",cart.id,Vector2i(cart.x,cart.y),true)
	var original: String = world.canonical_hash()
	var query: Array = world.nonempty_stacks()
	check.call("STACK/depleted_goods_remain_history_without_reentering_live_queries",world.stacks.size()==starting_records+5002 and query.map(func(s:Dictionary)->int:return s.id)==[first.id,second.id] and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	query.reverse();query.clear()
	check.call("STACK/caller_sort_and_clear_cannot_reorder_live_goods",world.nonempty_stacks().map(func(s:Dictionary)->int:return s.id)==[first.id,second.id])
	check.call("STACK/query_cache_is_not_authoritative_save_data",world.canonical_hash()==original)
	var third: Dictionary = world._make_stack("stone",1,"ground",0,Vector2i(81,80),true)
	check.call("STACK/new_same_tick_goods_are_visible",world.nonempty_stacks().back().id==third.id)
	first.count=0;world._record("consumed","meal",2)
	check.call("STACK/same_tick_consumption_disappears_without_pruning_history",world.nonempty_stacks().map(func(s:Dictionary)->int:return s.id)==[second.id,third.id] and world.find(world.stacks,first.id).count==0)
	var incoming: Dictionary = world._make_stack("wood",2,"store",cart.id,Vector2i(cart.x,cart.y),true)
	world._merge_stored(incoming)
	check.call("STACK/physical_merge_updates_live_record_without_reviving_tombstones",second.count==9 and incoming.count==0 and world.stacks[1].count==0 and world.nonempty_stacks().map(func(s:Dictionary)->int:return s.id)==[second.id,third.id] and world.available("wood")==9 and world.total("wood")==13)
	world.tick+=1
	world.nonempty_stacks()
	check.call("STACK/next_tick_retires_depleted_query_references",world.stack_query_live.size()==2 and world.stack_query_count==world.stacks.size())
	var restored: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/live_goods_cache_rebuilds_after_full_history_import",restored.has("world") and restored.world.canonical_hash()==world.canonical_hash() and restored.world.nonempty_stacks().map(func(s:Dictionary)->int:return s.id)==[second.id,third.id] and restored.world.stacks.size()==world.stacks.size(),str(restored.get("error","")))
	world.stacks=world.stacks.duplicate(true)
	check.call("STACK/replaced_same_length_table_uses_new_record_objects",world.nonempty_stacks().size()==2 and not is_same(world.nonempty_stacks()[0],second) and is_same(world.nonempty_stacks()[0],world.find(world.stacks,second.id)))
	world.stacks.clear()
	check.call("STACK/shrinking_table_drops_phantom_goods",world.nonempty_stacks().is_empty())
	world=ColonyTests.world()
	var meal: Dictionary = world.stacks.filter(func(s:Dictionary)->bool:return s.item=="meal")[0]
	var spoiled: int = meal.count
	world.nonempty_stacks();meal.age=world.definitions.items.meal.shelf_ticks-1
	ColonyLiving.advance(world)
	check.call("STACK/spoilage_retires_goods_with_exact_ledger_and_unchanged_history",meal.count==0 and not world.nonempty_stacks().has(meal) and world.ledger.spoiled.meal==spoiled and world.find(world.stacks,meal.id).age==world.definitions.items.meal.shelf_ticks and world.invariant_errors().is_empty(),str(world.invariant_errors()))
