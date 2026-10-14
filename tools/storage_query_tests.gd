class_name StorageQueryTests
extends RefCounted

static func run(check: Callable) -> void:
	input_prefix(check)
	haul_work_positions(check)
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

static func haul_work_positions(check: Callable) -> void:
	for occupied in ["none","sleep","eat","haul","full_store"]:
		var original: ColonyWorld = ColonyTests.world()
		var owner: Dictionary = original.citizens[1]
		var point: Vector2i = Vector2i(74,70)
		if occupied in ["sleep","eat"]:
			if occupied=="sleep": owner.rest=50
			else: owner.fullness=100
			original._assign(owner)
			var owned: Dictionary = original.find(original.jobs,owner.job)
			check.call("STORE/position_fixture_has_real_"+occupied,owned.get("kind")==occupied,str(owned))
			point=Vector2i(owned.work_x,owned.work_y)
		elif occupied=="haul":
			var existing: Dictionary = original._make_stack("wood",8,"ground",0,point,true)
			var owned: Dictionary = original._job("haul","Hauling","",existing.id,point,0);owned.source=existing.id
			check.call("STORE/position_fixture_reserves_real_haul",original._reserve(owned,owner))
			owner.job=owned.id;point=Vector2i(owned.work_x,owned.work_y)
		elif occupied=="full_store":
			original.stores[0].capacity=original._storage_context().occupied[original.stores[0].id]
		var source: Dictionary = original._make_stack("wood",8,"ground",0,point,true)
		var job: Dictionary = original._job("haul","Hauling","",source.id,point,0);job.source=source.id
		var decoded: Dictionary = ColonyCodec.restore(original.payload().duplicate(true))
		check.call("STORE/position_fixture_roundtrips_"+occupied,decoded.has("world"),str(decoded.get("error","")))
		if not decoded.has("world"): continue
		var cached: ColonyWorld = decoded.world
		var context: Dictionary = cached._storage_context()
		var expected: bool = original._reserve(job,original.citizens[0])
		var actual: bool = cached._reserve(cached.find(cached.jobs,job.id),cached.citizens[0],context)
		check.call("STORE/search_local_position_matches_full_history_"+occupied,expected==actual and original.canonical_hash()==cached.canonical_hash(),str([expected,actual,job.reason]))
		if actual:
			original.citizens[0].job=job.id;cached.citizens[0].job=job.id
			original._release(job,true);cached._release(cached.find(cached.jobs,job.id),true)
			check.call("STORE/search_local_position_cancel_is_exact_"+occupied,original.canonical_hash()==cached.canonical_hash() and original.invariant_errors().is_empty(),str(original.invariant_errors()))

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
	# Compare complete return contracts as well as their consumed prefixes,
	# including food in slow-aging stores, reservations and equal-time ties.
	var granary: Dictionary = world._structure("granary",Vector2i(80,80),0)
	var cellar: Dictionary = world._structure("cellar",Vector2i(84,80),0)
	choices.clear()
	for index in range(120):
		var item: String = ["grain","berry","meal","wood","vegetable","stone"][index%6]
		var store: Dictionary = granary if index%3==0 else cellar
		var stack: Dictionary = world._make_stack(item,2+index%7,"store" if index%4==0 else "ground",store.id if index%4==0 else 0,Vector2i(40+index%30,50+index%8),true)
		stack.age=index%9*100;stack.age_rem=index%4
		if index%5==0: stack.reservations[99]=1
		choices.append(stack)
	choices.reverse();before=world.canonical_hash()
	for point in [Vector2i(0,0),Vector2i(66,63),Vector2i(127,127)]:
		sorted=choices.duplicate();sorted.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return ColonyProduction.input_before(world,a,b,point))
		for needed in [1,4,16,17,9999]:
			var expected: Array = sorted.duplicate()
			if needed<=16:
				expected.clear();var remaining: int = needed
				for stack in sorted:
					if remaining<=0: break
					expected.append(stack);remaining-=maxi(0,stack.count-world._reserved(stack))
			var input: Array = choices.duplicate()
			var actual: Array = ColonyProduction.first_inputs(world,input,point,needed)
			check.call("INPUT/packed_keys_keep_full_contract_%s_%d" % [str(point),needed],actual==expected and input==(choices if needed<=16 else sorted) and world.canonical_hash()==before)
