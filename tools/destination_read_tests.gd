class_name DestinationReadTests
extends RefCounted
## Exact original 8c0e060 destination query; keep sorting, ties and return shape.
class OriginalWorld extends ColonyWorld:
	func _init(catalog: Dictionary) -> void: super(catalog)
	func _destination(item: String, quantity: int, from: Vector2i, tags: Array = [], context: Dictionary = {}) -> Dictionary:
		var candidates: Array[Dictionary] = []
		if context.is_empty(): context=_storage_context()
		for store in stores:
			if ColonyFire.burning(self,"structure",store.id): continue
			if not store.filters.has(item):
				continue
			var occupied: int = context.occupied.get(store.id,0)
			if occupied + quantity > store.capacity:
				continue
			for tile: Vector2i in store.tiles:
				var used: int = 0
				var blocked: bool = false
				if find(structures, store.id).is_empty():
					var key: Vector3i = Vector3i(store.id,tile.x,tile.y)
					for stack in context.tiles.get(key,[]):
						blocked=blocked or stack.item!=item or stack.tags!=tags;used+=stack.count
					blocked=blocked or context.working_tiles.has(key)
					if used + quantity > definitions.items[item].stack_limit:
						blocked = true
				if not blocked:
					candidates.append({"id": store.id, "tile": tile, "priority": store.priority, "distance": absi(tile.x - from.x) + absi(tile.y - from.y)})
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority > b.priority or (a.priority == b.priority and (a.distance < b.distance or (a.distance == b.distance and a.id < b.id))))
		return {} if candidates.is_empty() else candidates[0]

class CountedWorld extends ColonyWorld:
	var structure_reads: int=0
	func _init(catalog: Dictionary) -> void: super(catalog)
	func find(records: Array, id: int) -> Dictionary:
		if is_same(records,structures):structure_reads+=1
		return super(records,id)

class CountedOriginal extends OriginalWorld:
	var structure_reads: int=0
	func _init(catalog: Dictionary) -> void: super(catalog)
	func find(records: Array, id: int) -> Dictionary:
		if is_same(records,structures):structure_reads+=1
		return super(records,id)

static func clone(source: ColonyWorld, original: bool) -> ColonyWorld:
	var result: ColonyWorld=OriginalWorld.new(source.definitions) if original else ColonyWorld.new(source.definitions)
	copy(source,result)
	return result

static func copy(source: ColonyWorld, result: ColonyWorld) -> void:
	for field in source.payload():
		if field in ["content","content_hash"]:continue
		var value: Variant=source.get(field)
		if value is Array:result.get(field).assign(value.duplicate(true))
		elif value is Dictionary:result.set(field,value.duplicate(true))
		else:result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true

static func fixture() -> ColonyWorld:
	var source: ColonyWorld=ColonyTests.world()
	source.stores[0].filters=[]
	for index in range(3):
		var tiles: Array=[]
		for y in range(4):
			for x in range(8):tiles.append(Vector2i(72+x,70+index*4+y))
		var store: Dictionary={"id":source._id(),"tiles":tiles,"capacity":1600,"priority":2,"filters":["wood","stone","meal"]}
		source.stores.append(store)
		source._make_stack("wood",24,"store",store.id,tiles[0],true)
		source._make_stack("stone",8,"store",store.id,tiles[1],true)
	var granary: Dictionary=source._structure("granary",Vector2i(84,72),0)
	source.stores.append({"id":granary.id,"tiles":[Vector2i(84,72)],"capacity":120,"priority":2,"filters":["wood","stone","meal"]})
	return source

static func compare_queries(source: ColonyWorld, name: String, check: Callable) -> void:
	var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
	var before: String=fast.canonical_hash();var exact: bool=true
	var contexts: Array=[{},fast._storage_context()]
	var references: Array=[{},original._storage_context()]
	for index in range(2):
		for item in ["wood","stone","meal"]:
			for quantity in [1,8,32,50]:
				for from in [Vector2i(75,71),Vector2i(75,76),Vector2i(70,72),Vector2i(127,127)]:
					for tags in [[],["Meat"]]:
						var actual: Dictionary=fast._destination(item,quantity,from,tags,contexts[index])
						var expected: Dictionary=original._destination(item,quantity,from,tags,references[index])
						exact=exact and actual==expected
	check.call("DEST/"+name+"_preserves_complete_original_quotes_and_ties",exact and before==fast.canonical_hash() and before==original.canonical_hash())

static func run(check: Callable) -> void:
	var source: ColonyWorld=fixture()
	compare_queries(source,"multi_tile_stockpiles_and_building_store",check)
	source.stores[1].capacity=source._storage_context().occupied.get(source.stores[1].id,0)
	source.stores[2].priority=3;source.stores[3].filters=["meal"]
	compare_queries(source,"full_capacity_priorities_filters_and_tags",check)
	ColonyFire.ignite(source,"structure",source.stores[-1].id)
	compare_queries(source,"burning_store_and_empty_choices",check)
	var counted: CountedWorld=CountedWorld.new(source.definitions);copy(source,counted)
	var old: CountedOriginal=CountedOriginal.new(source.definitions);copy(source,old)
	var context: Dictionary=counted._storage_context();var old_context: Dictionary=old._storage_context()
	counted.structure_reads=0;old.structure_reads=0
	var actual: Dictionary=counted._destination("wood",8,Vector2i(75,76),[],context)
	var expected: Dictionary=old._destination("wood",8,Vector2i(75,76),[],old_context)
	check.call("DEST/one_structure_lookup_instead_of_thirty_two_for_eligible_stockpile",actual==expected and counted.structure_reads==1 and old.structure_reads==32,str([counted.structure_reads,old.structure_reads]))
	var stress: Dictionary=StressFixture.make()
	check.call("DEST/paired_crowded_input_is_valid",stress.has("world"),str(stress.get("error","")))
	if not stress.has("world"):return
	var fast: ColonyWorld=clone(stress.world,false);var original: ColonyWorld=clone(stress.world,true);var exact: bool=true
	for index in range(120):
		fast.step();original.step()
		if index%10==0:exact=exact and fast.canonical_hash()==original.canonical_hash()
	check.call("DEST/crowded_complete_ticks_preserve_all_state",exact and fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty())
	var saved: Dictionary=ColonyCodec.decode(ColonyCodec.encode(fast))
	check.call("DEST/crowded_saved_state_roundtrips_exactly",saved.has("world") and saved.world.canonical_hash()==fast.canonical_hash())
	if not saved.has("world"):return
	fast=saved.world
	for index in range(60):fast.step();original.step()
	check.call("DEST/crowded_continuation_after_reload_matches_original",fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty())
