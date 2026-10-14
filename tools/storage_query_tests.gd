class_name StorageQueryTests
extends RefCounted

static func run(check: Callable) -> void:
	input_prefix(check)
	var world: ColonyWorld = ColonyTests.world()
	world.stores[0].filters=[]
	var point: Vector2i = Vector2i(75,70)
	var store: Dictionary = {"id":world._id(),"tiles":[point],"capacity":50,"priority":3,"filters":["wood","stone"]}
	world.stores.append(store)
	world._make_stack("wood",5,"store",store.id,point,true)
	var source: Dictionary = world._make_stack("wood",16,"ground",0,Vector2i(74,70),true)
	var original: String = world.canonical_hash()
	check.call("STORE/indexed_destination_respects_item_and_tag_piles",world._destination("wood",8,Vector2i(74,70),[]) .get("id",0)==store.id and world._destination("stone",8,Vector2i(74,70),[]).is_empty() and world._destination("wood",8,Vector2i(74,70),["Meat"]).is_empty() and original==world.canonical_hash())
	var haul: Dictionary = world._job("haul","Hauling","",source.id,Vector2i(source.x,source.y),0);haul.source=source.id
	var person: Dictionary = world.citizens[0]
	var reserved: bool = world._reserve(haul,person)
	person.job=haul.id
	check.call("STORE/real_haul_reservation_counts_incoming_and_blocks_tile",reserved and world._storage_context().occupied[store.id]==13 and world._destination("wood",8,point,[]).is_empty())
	person.x=source.x;person.y=source.y;person.edge_x=source.x;person.edge_y=source.y
	world._work(person,haul)
	check.call("STORE/fetched_cargo_keeps_same_incoming_capacity",haul.state=="Delivering" and world._storage_context().occupied[store.id]==13 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world._release(haul,true)
	check.call("STORE/cancel_rebuilds_capacity_and_reopens_destination",world._storage_context().occupied[store.id]==5 and world._destination("wood",8,point,[]).get("id",0)==store.id and world.invariant_errors().is_empty())
	# Score ordering retains its complete priority/preference/skill/distance/ID
	# contract while the hot comparison avoids allocating two Arrays each time.
	var jobs: Array = []
	for index in range(150):
		var job: Dictionary = world._job("build",ColonyWorld.CATEGORIES[index%ColonyWorld.CATEGORIES.size()],ColonyWorld.SKILLS[index%ColonyWorld.SKILLS.size()],0,Vector2i(index%128,index*7%128),16000)
		job.created=world.tick-index*97;job.priority=1+index%3;jobs.append(job)
	var expected: Array = jobs.duplicate()
	expected.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var aa: Array = world._score(a,person);var bb: Array = world._score(b,person)
		for index in range(aa.size()):
			if aa[index]!=bb[index]: return aa[index]>bb[index]
		return false)
	jobs.reverse();world._sort_jobs(jobs,person)
	check.call("SCHED/precomputed_keys_match_original_tuple_order",jobs.map(func(j:Dictionary)->int:return j.id)==expected.map(func(j:Dictionary)->int:return j.id))
	jobs.reverse()
	var queue: ColonyJobQueue = ColonyJobQueue.new(jobs,world,person)
	var popped: Array = []
	while not queue.heap.is_empty(): popped.append(queue.pop().id)
	check.call("SCHED/lazy_heap_yields_exact_original_order",popped==expected.map(func(j:Dictionary)->int:return j.id) and queue.pop().is_empty())

static func input_prefix(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var choices: Array = []
	for index in range(60):
		var stack: Dictionary = world._make_stack(["grain","meal","berry","wood"][index%4],1+index%8,"ground",0,Vector2i(50+index%12,60+index/12),true)
		stack.age=index*73;choices.append(stack)
	var origin: Vector2i = Vector2i(66,63)
	var sorted: Array = choices.duplicate()
	sorted.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return ColonyProduction.input_before(world,a,b,origin))
	var before: String = world.canonical_hash()
	for needed in [0,1,4,16,17,80,999]:
		var actual: Array = ColonyProduction.first_inputs(world,choices.duplicate(),origin,needed)
		var expected_ids: Array = [];var actual_ids: Array = [];var remaining: int = needed
		for stack in sorted:
			if remaining<=0: break
			expected_ids.append(stack.id);remaining-=stack.count-world._reserved(stack)
		remaining=needed
		for stack in actual:
			if remaining<=0: break
			actual_ids.append(stack.id);remaining-=stack.count-world._reserved(stack)
		check.call("INPUT/partial_selection_matches_full_order_%d" % needed,actual_ids==expected_ids and world.canonical_hash()==before)
