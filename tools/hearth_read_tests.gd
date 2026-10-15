class_name HearthReadTests
extends RefCounted
## Complete unmodified creation body from 7059064, independent of optimized reads.
class OriginalWorld extends ColonyWorld:
	func _create_work() -> void:
		if not personal_jobs_reconciled:
			# Older snapshots can contain abandoned personal work. Retain its history
			# and release any real supplies through the ordinary cancellation path.
			for job in unfinished_jobs():
				if job.kind in PERSONAL_JOBS and job.worker==0 and job.state not in ["Complete","Canceled"]:
					_release(job,true)
			personal_jobs_reconciled=true
		for hearth in structures:
			if hearth.health<=0 or hearth.definition != "hearth":
				continue
			if hearth.fuel < 4 and ColonyLiving.temperature(self) < 8 and available("wood") >= 8 - hearth.fuel and not unfinished_jobs().any(func(job: Dictionary) -> bool: return job.kind == "fuel" and job.target == hearth.id and job.state not in ["Complete", "Canceled"]):
				var fuel_job: Dictionary = _job("fuel", "Hauling", "", hearth.id, Vector2i(hearth.x,hearth.y), 0)
				fuel_job.inputs = {"wood": 8 - hearth.fuel}
			if not hearth.cooking:
				continue
			if production_state.orders.any(func(order:Dictionary)->bool:return order.station == hearth.id):
				continue
			var active: bool = false
			var output_batches: int = 0
			var in_progress: int = 0
			for stack in nonempty_stacks():
				if stack.location == "output" and stack.owner == hearth.id and stack.count > 0:
					output_batches += 1
			for job in unfinished_jobs():
				if job.kind in ["cook","craft"] and job.target == hearth.id and job.state not in ["Complete", "Canceled"]:
					active = true
					in_progress += 2
			if not active and output_batches < 2 and available("meal") + in_progress < citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed and not c.away).size() * 4:
				var recipe: Dictionary = definitions.recipes.cook_meals
				var inputs: Dictionary = recipe.materials.duplicate()
				var count: int = 0
				var food: Array[Dictionary] = []
				for stack in nonempty_stacks():
					if recipe.alternatives.has(stack.item) and stack.location in ["ground","store","output"] and stack.count > _reserved(stack) and ColonyFire.usable(self,stack) and accessible(Vector2i(stack.x,stack.y)):
						food.append(stack)
				for stack in ColonyProduction.first_inputs(self,food,Vector2i(hearth.x,hearth.y),4):
					var item: String = stack.item
					var quantity: int = mini(4 - count, stack.count-_reserved(stack))
					if quantity > 0:
						inputs[item] = inputs.get(item,0)+quantity
						count += quantity
				if count == 4 and available("wood") >= 1:
					var job: Dictionary = _job("cook", "Cooking", "Cooking", hearth.id, Vector2i(hearth.x, hearth.y), recipe.work_milli)
					job.inputs = inputs
					job.output = recipe.outputs.duplicate()
		# Completed work remains in history; index only live hauling reservations
		# once instead of rescanning that history for every loose stack.
		var haul_sources: Dictionary = {}
		for existing in unfinished_jobs():
			if existing.kind == "haul" and existing.state not in ["Complete", "Canceled"]:
				haul_sources[existing.source] = true
		for stack in nonempty_stacks():
			var invalid_store: bool = false
			if stack.location == "store":
				var store: Dictionary = find(stores,stack.owner)
				invalid_store = store.is_empty() or not store.filters.has(stack.item)
			if stack.count == 0 or (stack.location not in ["ground", "output"] and not invalid_store) or _reserved(stack) > 0:
				continue
			if not haul_sources.has(stack.id):
				var job: Dictionary = _job("haul", "Hauling", "", stack.id, Vector2i(stack.x, stack.y), 0)
				job.source = stack.id
				haul_sources[stack.id] = true

static func clone(source: ColonyWorld, original: bool) -> ColonyWorld:
	var result: ColonyWorld=OriginalWorld.new(source.definitions) if original else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	return result

static func create_equal(fast: ColonyWorld, original: ColonyWorld, inside: bool = true) -> bool:
	fast.in_tick=inside;original.in_tick=inside
	fast._create_work();original._create_work()
	fast.in_tick=false;original.in_tick=false
	return fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty()

static func fixture() -> ColonyWorld:
	var world: ColonyWorld=ColonyTests.world()
	world.tick=24*7200+1800;ColonyWeather.initialize(world)
	for stack in world.stacks:
		if stack.item=="meal": world._record("consumed","meal",stack.count);stack.count=0
	for point in [Vector2i(78,62),Vector2i(86,62),Vector2i(94,62)]: world._structure("hearth",point,0)
	var aged: Dictionary=world._make_stack("vegetable",24,"ground",0,Vector2i(76,64),true);aged.age=20000
	world._make_stack("mushroom",16,"ground",0,Vector2i(84,64),true)
	for index in range(2000):
		var old: Dictionary=world._job("leisure","","",world.citizens[0].id,Vector2i(50,60),0)
		old.state="Complete" if index%2==0 else "Canceled"
		var depleted: Dictionary=world._make_stack("vegetable",1,"ground",0,Vector2i(80,70),true)
		world._record("consumed","vegetable",1);depleted.count=0;depleted.age=123;depleted.job=old.id
	world.work_budget.reset();world.reset_job_queries();world.reset_stack_queries()
	return world

static func run(check: Callable) -> void:
	orphan_inputs(check)
	var source: ColonyWorld=fixture()
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(source))
	check.call("HEARTH/full_history_fixture_has_valid_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==source.canonical_hash() and source.invariant_errors().is_empty())
	if not decoded.has("world"): return
	var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
	var ledger: Dictionary=fast.ledger.duplicate(true)
	check.call("HEARTH/multi_hearth_fuel_food_haul_proposals_match_full_body",create_equal(fast,original) and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="cook").size()==4 and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="fuel").size()==3 and fast.ledger==ledger)
	check.call("HEARTH/proposals_keep_independent_unreserved_inputs",fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="cook").all(func(j:Dictionary)->bool:return j.inputs=={"wood":1,"vegetable":4}) and fast.stacks.all(func(s:Dictionary)->bool:return s.reservations.is_empty()))
	var next_id: int=fast.next_id
	check.call("HEARTH/repeated_call_does_not_duplicate_any_creation_kind",create_equal(fast,original) and fast.next_id==next_id)
	var cook: Dictionary=fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="cook")[0]
	cook.state="Canceled";original.find(original.jobs,cook.id).state="Canceled"
	var fuel: Dictionary=fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="fuel")[0]
	fuel.state="Canceled";original.find(original.jobs,fuel.id).state="Canceled"
	check.call("HEARTH/same_tick_terminal_rows_allow_fresh_proposals",create_equal(fast,original) and fast.next_id==next_id+2)
	for world in [fast,original]:
		for job in world.jobs:
			if job.kind in ["fuel","cook","haul"] and job.state not in ["Complete","Canceled"]: job.state="Queued";job.queue_state="Ready"
		world.work_budget.reset()
	next_id=fast.next_id
	check.call("HEARTH/queued_proposals_count_for_all_duplicate_guards",create_equal(fast,original) and fast.next_id==next_id)
	fast=clone(source,false);original=clone(source,true)
	for world in [fast,original]:
		var hearth: Dictionary=world.structures.filter(func(b:Dictionary)->bool:return b.definition=="hearth")[1]
		world._make_stack("meal",1,"output",hearth.id,Vector2i(hearth.x,hearth.y),true)
		world._make_stack("meal",1,"output",hearth.id,Vector2i(hearth.x,hearth.y),true)
		var empty: Dictionary=world._make_stack("meal",1,"output",hearth.id,Vector2i(hearth.x,hearth.y),true)
		world._record("consumed","meal",1);empty.count=0;empty.age=321
	check.call("HEARTH/output_limit_counts_nonempty_records_without_changing_metadata",create_equal(fast,original) and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="cook").size()==3)
	fast=clone(source,false);original=clone(source,true)
	for world in [fast,original]:
		var hearth: Dictionary=world.structures.filter(func(b:Dictionary)->bool:return b.definition=="hearth")[1]
		ColonyProduction.command(world,"recipe_order",{"target":hearth.id,"definition":"cook_meals","mode":"Maintain","value":4,"priority":2,"filters":[]})
		var abandoned: Dictionary=world._job("sleep","","",0,Vector2i(60,60),0)
		abandoned.state="Moving";world.personal_jobs_reconciled=false
	check.call("HEARTH/custom_orders_and_legacy_personal_reconciliation_match",create_equal(fast,original) and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="cook").size()==3 and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="sleep").all(func(j:Dictionary)->bool:return j.state=="Canceled"))
	fast=clone(source,false);original=clone(source,true)
	for world in [fast,original]:
		for person in world.citizens: person.away=true
	check.call("HEARTH/no_home_demand_creates_no_automatic_cooking",create_equal(fast,original) and not fast.jobs.any(func(j:Dictionary)->bool:return j.kind=="cook"))
	fast=clone(source,false);original=clone(source,true)
	check.call("HEARTH/direct_outside_tick_calls_keep_full_reference_state",create_equal(fast,original,false))
	for world in [fast,original]:
		for job in world.jobs:
			if job.kind=="cook": job.state="Canceled"
		for stack in world.stacks:
			if stack.item=="vegetable" and stack.count>0: world._record("consumed","vegetable",stack.count);stack.count=0
	check.call("HEARTH/next_call_observes_consumed_candidates_without_stale_reads",create_equal(fast,original,false) and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="cook" and j.state!="Canceled").all(func(j:Dictionary)->bool:return j.inputs=={"wood":1,"mushroom":4}))
	fast=clone(source,false);original=clone(source,true)
	for tick in range(600): fast.step();original.step()
	check.call("HEARTH/actual_fuel_cooking_and_hauling_ticks_remain_exact",fast.canonical_hash()==original.canonical_hash() and fast.ledger.consumed.get("wood",0)>0 and fast.ledger.produced.get("meal",0)>24 and fast.invariant_errors().is_empty())
	var saved: Dictionary=ColonyCodec.decode(ColonyCodec.encode(fast))
	check.call("HEARTH/full_history_after_real_work_roundtrips_exactly",saved.has("world") and saved.world.canonical_hash()==fast.canonical_hash())
	if not saved.has("world"): return
	var resumed: ColonyWorld=saved.world
	for tick in range(120): fast.step();original.step();resumed.step()
	check.call("HEARTH/reloaded_real_work_continuation_matches_both_paths",fast.canonical_hash()==original.canonical_hash() and fast.canonical_hash()==resumed.canonical_hash() and fast.invariant_errors().is_empty())

static func orphan_inputs(check: Callable) -> void:
	var source: ColonyWorld=ColonyTests.world()
	var orphan: Dictionary=source._job("eat","","",1,Vector2i(61,63),2000)
	orphan.inputs={"vegetable":1};orphan.state="Moving"
	var held: Dictionary=source._make_stack("vegetable",1,"escrow",orphan.id,Vector2i(61,63),true)
	var zero: Dictionary=source._make_stack("vegetable",1,"escrow",orphan.id,Vector2i(61,63),true)
	source._record("consumed","vegetable",1);zero.count=0;zero.age=700
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(source))
	check.call("HEARTH/legacy_personal_escrow_fixture_is_a_valid_save",decoded.has("world") and decoded.world.canonical_hash()==source.canonical_hash())
	var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
	var ledger: Dictionary=fast.ledger.duplicate(true)
	check.call("HEARTH/reconciliation_reads_newly_dropped_food_before_haul_proposals",create_equal(fast,original) and fast.find(fast.stacks,held.id).location=="ground" and fast.jobs.any(func(j:Dictionary)->bool:return j.kind=="haul" and j.source==held.id) and fast.ledger==ledger)
	var ended: Dictionary=fast.find(fast.stacks,zero.id)
	check.call("HEARTH/reconciliation_preserves_zero_record_metadata_writes",ended.count==0 and ended.location=="ground" and ended.owner==0 and ended.job==0 and ended.age==700 and not fast.jobs.any(func(j:Dictionary)->bool:return j.kind=="haul" and j.source==zero.id))
