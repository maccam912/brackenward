class_name WorkBudgetTests
extends RefCounted

class UncachedBudget extends ColonyWorkBudget:
	func reconcile_runtime(world: ColonyWorld) -> void:
		reconcile(world)
	func after_commands(world: ColonyWorld, _had_commands: bool) -> void:
		reconcile(world)
	func reconcile(world: ColonyWorld) -> void:
		var result: Dictionary = reconcile_records(world.citizens,world.unfinished_jobs(),world.tick)
		used=result.used

class CountingBudget extends ColonyWorkBudget:
	var inspections: int = 0
	func reconcile(world: ColonyWorld) -> void:
		inspections+=1;super.reconcile(world)

class FullReservationWorld extends ColonyWorld:
	func _init(catalog: Dictionary) -> void:
		super(catalog)
	func _reservation_jobs() -> Array:
		return jobs
	func _work_inventory() -> Array:
		return stacks
	func _work_jobs() -> Array:
		return jobs
	func _find_history(records: Array, id: int, _table: String) -> Dictionary:
		for record in records:
			if record.id==id: return record
		return {}

static func run(check: Callable) -> void:
	owned_history(check)
	history_lookup(check)
	historical_inventory(check)
	runtime_deadlines(check)
	scheduling_bounds(check)
	precomputed_order(check)
	stress_tick_order(check)
	public_orders(check)
	legacy_upgrade(check)
	var world: ColonyWorld = ColonyTests.world();var jobs: Array = []
	for index in range(700):
		var job: Dictionary = world._job("build","Building","Build",0,Vector2i(index%128,index/128),16000)
		job.definition="wood_wall";job.inputs={"wood":4};job.state="Ready";job["queue_state"]="";jobs.append(job)
	for person in world.citizens:
		var personal: Dictionary = world._job("sleep","","",person.bed,Vector2i(person.x,person.y),0)
		personal.worker=person.id;personal.state="Moving";personal["queue_state"]="";jobs.append(personal)
	var bank: Dictionary = world._job("supper_reserve","","",0,Vector2i(66,63),0)
	bank.state="Working";bank["queue_state"]="";jobs.append(bank)
	world.citizens[0].pinned_job=jobs[699].id
	jobs[698].emergency=true
	var before: Array = jobs.duplicate(true)
	ColonyWorkBudget.reconcile_records(world.citizens,jobs,world.tick)
	check.call("BUDGET/queue_keeps_all_orders_and_reserves_self_care_bank_slots",jobs.size()==705 and jobs.filter(func(j:Dictionary)->bool:return ColonyWorkBudget.executable(j,world.tick)).size()==512 and jobs.filter(func(j:Dictionary)->bool:return j.state=="Queued").size()==193)
	check.call("BUDGET/emergency_and_pinned_work_enter_before_ordinary_orders",jobs[698].state=="Ready" and jobs[699].state=="Ready" and jobs.slice(700).all(func(j:Dictionary)->bool:return j.state!="Queued"))
	var stripped: Array = jobs.duplicate(true)
	for index in range(stripped.size()): stripped[index].state=before[index].state;stripped[index].queue_state=before[index].queue_state
	check.call("BUDGET/deferral_changes_only_execution_state",stripped==before)
	var queued: Dictionary = jobs.filter(func(j:Dictionary)->bool:return j.state=="Queued")[0]
	jobs[0].state="Canceled"
	ColonyWorkBudget.reconcile_records(world.citizens,jobs,world.tick)
	check.call("BUDGET/freed_capacity_admits_existing_order_without_new_id",queued.state=="Ready" and queued.queue_state.is_empty() and jobs.size()==705)
	var blocked: Dictionary = jobs[1];blocked.state="Blocked";blocked.retry=world.tick+50;blocked.reason="Missing supplies"
	ColonyWorkBudget.reconcile_records(world.citizens,jobs,world.tick)
	check.call("BUDGET/future_retry_retains_reason_and_frees_executable_capacity",blocked.state=="Blocked" and blocked.reason=="Missing supplies" and jobs.filter(func(j:Dictionary)->bool:return ColonyWorkBudget.executable(j,world.tick)).size()==512)
	world.tick+=50
	ColonyWorkBudget.reconcile_records(world.citizens,jobs,world.tick)
	check.call("BUDGET/due_retry_reenters_with_original_blocked_state",blocked.state=="Blocked" and jobs.filter(func(j:Dictionary)->bool:return ColonyWorkBudget.executable(j,world.tick)).size()==512)

static func owned_history(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var first: Dictionary = world._job("leisure","","",0,Vector2i(50,60),0)
	var second: Dictionary = world._job("leisure","","",0,Vector2i(51,60),0)
	first.worker=world.citizens[0].id;world.citizens[0].job=first.id;first.state="Complete"
	second.worker=world.citizens[1].id;world.citizens[1].job=second.id
	world.jobs.reverse();world.record_indexes.clear();world.reset_job_queries()
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("READ/terminal_owned_history_is_an_accepted_save",decoded.has("world") and world.invariant_errors().is_empty(),str(decoded.get("error",world.invariant_errors())))
	if not decoded.has("world"): return
	world=decoded.world;first=world.find(world.jobs,first.id);second=world.find(world.jobs,second.id)
	world.in_tick=true;world.assigning_work=true;world.reservation_query_ready=false
	var owned: Array = world._reservation_jobs()
	check.call("READ/owned_lookup_keeps_terminal_records_and_imported_array_order",owned.map(func(j:Dictionary)->int:return j.id)==[second.id,first.id] and is_same(owned[1],first))
	world._release(second,false)
	check.call("READ/same_search_release_updates_borrowed_owned_reference",owned[0].worker==0 and is_same(world._reservation_jobs()[0],second))
	world.reservation_query_ready=false
	check.call("READ/next_search_rebuilds_current_ownership",world._reservation_jobs().map(func(j:Dictionary)->int:return j.id)==[first.id])
	world.in_tick=false;world.reservation_query_ready=false
	second.worker=world.citizens[1].id;world.citizens[1].job=0
	check.call("READ/direct_search_keeps_full_history_for_incomplete_fixtures",world._reservation_jobs().map(func(j:Dictionary)->int:return j.id)==[second.id,first.id])

static func history_lookup(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	world.in_tick=true
	var exact: bool = true
	for table in ["citizens","structures","resources","stacks","jobs"]:
		var records: Array = world.get(table)
		for record in records:
			exact=exact and is_same(world.find(records,record.id),record)
		exact=exact and world.find(records,world.next_id+100).is_empty()
	check.call("READ/history_index_returns_original_records_and_absent_ids",exact)
	var missing: int = world.next_id
	check.call("READ/missing_history_id_is_not_a_future_tombstone",world.find(world.stacks,missing).is_empty())
	var added: Dictionary = world._make_stack("wood",1,"ground",0,Vector2i(50,60),true)
	check.call("READ/same_tick_append_is_visible_after_negative_lookup",added.id==missing and is_same(world.find(world.stacks,missing),added))
	added.count=0
	check.call("READ/index_keeps_mutable_historical_record_reference",is_same(world.find(world.stacks,missing),added) and world.find(world.stacks,missing).count==0)
	var replacement: Dictionary = added.duplicate(true);replacement.count=7
	world.stacks=[replacement]
	check.call("READ/history_array_replacement_rebuilds_index",is_same(world.find(world.stacks,missing),replacement))
	world.stacks.clear()
	check.call("READ/history_shrink_discards_removed_ids",world.find(world.stacks,missing).is_empty())
	var outside: Dictionary = world._make_stack("wood",1,"ground",0,Vector2i(50,60),false)
	world.in_tick=false
	world.find(world.stacks,outside.id)
	world.record_indexes.clear()
	world.stacks.assign([replacement])
	check.call("READ/reset_clears_complete_and_direct_lookup_indexes",world.find(world.stacks,outside.id).is_empty() and is_same(world.find(world.stacks,missing),replacement))
	world.in_tick=true
	check.call("READ/reset_view_rebuilds_with_reused_container",is_same(world.find(world.stacks,missing),replacement))
	var untracked: Array = [{"id":5,"value":"first"},{"id":5,"value":"second"}]
	check.call("READ/non_world_arrays_keep_first_record_scan",is_same(world.find(untracked,5),untracked[0]))

static func historical_inventory(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var person: Dictionary = world.citizens[0]
	var station: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	var job: Dictionary = world._job("cook","Cooking","Cooking",station.id,Vector2i(station.x,station.y),world.definitions.recipes.cook_meals.work_milli)
	job.output={"meal":2}
	var historical: Array = []
	for index in range(8000):
		var old: Dictionary = world._make_stack("wood",0,"carry",person.id,Vector2i(50,60),false)
		old.job=job.id;historical.append(old)
	world._make_stack("grain",8,"ground",0,Vector2i(50,60),true)
	check.call("READ/history_fixture_reserves_real_inputs",world._reserve(job,person))
	person.job=job.id
	var full: FullReservationWorld = FullReservationWorld.new(world.definitions)
	for field in world.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant = world.get(field)
		if value is Array: full.get(field).assign(value.duplicate(true))
		elif value is Dictionary: full.set(field,value.duplicate(true))
		else: full.set(field,value)
	full.record_indexes.clear();full.reset_job_queries();full.reset_stack_queries()
	full.navigation_dirty=true;full.reachability_dirty=true;full.rooms_dirty=true
	var exact: bool = true
	for index in range(1200):
		world.step();full.step()
		if index in [99,299,599,1199]: exact=exact and world.canonical_hash()==full.canonical_hash()
	check.call("READ/live_inventory_reads_match_full_history_continuation",exact and job.state=="Complete" and world.invariant_errors().is_empty(),str([job.state,world.invariant_errors()]))
	check.call("READ/zero_count_delivery_metadata_is_still_updated",historical.size()==8000 and historical.all(func(s:Dictionary)->bool:return s.count==0 and s.location=="escrow" and s.owner==job.id and s.x==job.work_x and s.y==job.work_y))
	check.call("READ/direct_queries_keep_full_history_fallback",not world.in_tick and is_same(world._work_inventory(),world.stacks))

static func scheduling_bounds(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var resource: Dictionary = world.resources[0]
	var job: Dictionary = world._job("gather","Gathering","Field",resource.id,Vector2i(resource.x,resource.y),16000)
	job.definition=resource.definition
	for change in [{"priority":0},{"priority":-1},{"priority":4},{"created":-1},{"created":world.tick+1},{"retry":-1}]:
		var payload: Dictionary = world.payload().duplicate(true);payload.jobs[0].merge(change,true)
		check.call("SAVE/admission_metadata_bounds_%s" % str(change),ColonyCodec.restore(payload).get("error","")=="Invalid job scheduling metadata")

static func runtime_deadlines(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var reference: ColonyWorld = ColonyTests.world()
	var budget: CountingBudget = CountingBudget.new();world.work_budget=budget;reference.work_budget=UncachedBudget.new()
	var exact: bool = true
	for index in range(200):
		world.step();reference.step();exact=exact and world.canonical_hash()==reference.canonical_hash()
	check.call("BUDGET/unchanged_ticks_skip_order_inspection_without_changing_state",exact and budget.inspections<80 and world.invariant_errors().is_empty(),str(budget.inspections))
	world=ColonyTests.world();budget=CountingBudget.new();world.work_budget=budget
	for index in range(600):
		var job: Dictionary = world._job("build","Building","Build",0,Vector2i(80+index%20,80+index/20),16000)
		job.definition="wood_wall";job.priority=2 if index==0 else 3
	budget.reconcile_runtime(world)
	var waiting: Dictionary = world.jobs[0];var before: int = budget.inspections;var next_id: int = world.next_id
	world.tick=8999;budget.reconcile_runtime(world)
	check.call("BUDGET/aging_deadline_is_not_polled_before_due",waiting.state=="Queued" and budget.inspections==before and budget.next_review_tick==9000)
	world.tick=9000;budget.reconcile_runtime(world)
	check.call("BUDGET/aging_deadline_admits_existing_low_id_order_exactly",waiting.state=="Ready" and budget.inspections==before+1 and world.next_id==next_id)
	var retry: Dictionary = world.jobs[1];world._block(retry,"Waiting for supplies");budget.reconcile_runtime(world);before=budget.inspections
	world.tick=9049;budget.reconcile_runtime(world)
	check.call("BUDGET/future_retry_keeps_cached_admission",budget.inspections==before and budget.next_review_tick==9050)
	world.tick=9050;budget.reconcile_runtime(world)
	var expected: Array = world.jobs.duplicate(true);ColonyWorkBudget.reconcile_records(world.citizens,expected,world.tick)
	check.call("BUDGET/retry_deadline_reconciles_on_exact_logical_tick",budget.inspections==before+1 and world.jobs==expected)
	before=budget.inspections
	for person in world.citizens: person.preferences.Building=0
	budget.reconcile_runtime(world)
	check.call("BUDGET/enabled_category_signature_detects_live_worker_changes",budget.inspections==before+1)
	world.jobs=world.jobs.duplicate(true);before=budget.inspections;budget.reconcile_runtime(world)
	check.call("BUDGET/runtime_cache_detects_same_length_array_replacement",budget.inspections==before+1)
	world.jobs[0].priority=1;before=budget.inspections;budget.reconcile(world)
	expected=world.jobs.duplicate(true);ColonyWorkBudget.reconcile_records(world.citizens,expected,world.tick)
	check.call("BUDGET/explicit_reconciliation_observes_direct_dictionary_edits",budget.inspections==before+1 and world.jobs==expected)
	for person in world.citizens: person.preferences.Cooking=0
	world.citizens[0].preferences.Cooking=2;budget.reconcile_runtime(world)
	var cook: Dictionary = world._job("cook","Cooking","Cooking",0,Vector2i(70,62),24000);budget.reconcile_runtime(world)
	check.call("BUDGET/one_enabled_home_cook_admits_usable_work",cook.state=="Ready")
	before=budget.inspections;world.citizens[0].away=true;budget.reconcile_runtime(world)
	check.call("BUDGET/last_home_worker_departure_invalidates_category_availability",budget.inspections==before+1 and cook.state=="Queued")
	before=budget.inspections;world.citizens[0].away=false;world.citizens[0].downed=true;budget.reconcile_runtime(world)
	check.call("BUDGET/equivalent_unavailable_worker_state_keeps_admission",budget.inspections==before and cook.state=="Queued")
	world.citizens[0].downed=false;budget.reconcile_runtime(world)
	check.call("BUDGET/recovered_home_worker_restores_usable_admission",budget.inspections==before+1 and cook.state=="Ready")
	before=budget.inspections;world.citizens[1].pinned_job=world.jobs[599].id;budget.reconcile_runtime(world)
	check.call("BUDGET/live_pin_membership_invalidates_without_a_command_hook",budget.inspections==before+1 and world.jobs[599].state=="Ready")
	before=budget.inspections;world.citizens[0].departed=true;budget.reconcile_runtime(world)
	expected=world.jobs.duplicate(true);ColonyWorkBudget.reconcile_records(world.citizens,expected,world.tick)
	check.call("BUDGET/living_count_changes_reserved_capacity_exactly",budget.inspections==before+1 and ColonyWorkBudget.ordinary_limit(world.citizens)==508 and world.jobs==expected)
	world.tick+=3;world._block(world.jobs[0],"Waiting for supplies");var due: int = world.jobs[0].retry;budget.reconcile_runtime(world)
	world.tick=due-1;world._release(world.jobs[0],false);budget.reconcile_runtime(world);before=budget.inspections
	check.call("BUDGET/released_ready_order_keeps_deadline_after_deferral",world.jobs[0].state=="Queued" and budget.next_review_tick==due)
	world.tick=due;budget.reconcile_runtime(world)
	expected=world.jobs.duplicate(true);ColonyWorkBudget.reconcile_records(world.citizens,expected,world.tick)
	check.call("BUDGET/released_order_retry_is_reviewed_between_assignment_ticks",due%10!=0 and budget.inspections==before+1 and world.jobs==expected)

static func precomputed_order(check: Callable) -> void:
	for variant in range(8):
		var world: ColonyWorld = ColonyTests.world();world.tick+=40000
		for index in range(1200):
			var job: Dictionary = world._job("build",ColonyWorld.CATEGORIES[index%10],"Build",0,Vector2i(index%128,index/128),16000)
			job.id=1000000000-1200+index;job.created=world.tick-index*71;job.priority=index%4
			job.emergency=(index+variant)%17==0;job.state="Blocked" if index%23==0 else "Ready";job.queue_state=""
			job.retry=world.tick+50 if index%23==0 else 0
			if index%97==0: world.citizens[index%4].pinned_job=job.id
		for person in world.citizens:
			person.away=variant%3==1;person.downed=variant%3==2
			person.preferences.Building=variant%4;person.preferences.Cooking=0
		var reference: Array = world.jobs.duplicate(true);var actual: Array = world.jobs.duplicate(true)
		if variant>=4:
			for index in range(7): reference[index].worker=world.citizens[index%4].id;actual[index].worker=reference[index].worker
		var expected: Dictionary = ColonyWorkBudget.reconcile_records(world.citizens,reference,world.tick)
		var result: Dictionary = ColonyWorkBudget.reconcile_records(world.citizens,actual,world.tick,true)
		check.call("BUDGET/precomputed_admission_matches_tuple_order_%d" % variant,result==expected and actual==reference)

static func stress_tick_order(check: Callable) -> void:
	var fixture: Dictionary = StressFixture.make()
	if not fixture.has("world"): check.call("BUDGET/stress_reference_fixture_constructs",false,str(fixture));return
	var first: Dictionary = ColonyCodec.decode(ColonyCodec.encode(fixture.world))
	var second: Dictionary = ColonyCodec.decode(ColonyCodec.encode(fixture.world))
	if not first.has("world") or not second.has("world"): check.call("BUDGET/stress_reference_fixture_restores",false);return
	var full_scan: FullReservationWorld = FullReservationWorld.new(second.world.definitions)
	for field in second.world.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant = second.world.get(field)
		if value is Array: full_scan.get(field).assign(value.duplicate(true))
		elif value is Dictionary: full_scan.set(field,value.duplicate(true))
		else: full_scan.set(field,value)
	second.world=full_scan
	second.world.work_budget=UncachedBudget.new()
	var exact: bool = true;var mismatch: int = 0
	for index in range(120):
		first.world.step();second.world.step()
		if first.world.canonical_hash()!=second.world.canonical_hash(): exact=false;mismatch=first.world.tick;break
	check.call("BUDGET/stress_matches_original_three_pass_order_each_tick",exact and first.world.invariant_errors().is_empty(),str([mismatch,first.world.invariant_errors()]))

static func public_orders(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var tiles: Array[Vector2i] = []
	for y in range(82,102):
		for x in range(42,74): tiles.append(Vector2i(x,y))
	var command: int = world.queue_command("build_area",{"definition":"wood_floor","tiles":tiles})
	world.step()
	var builds: Array = world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build")
	var queued: Array = builds.filter(func(j:Dictionary)->bool:return j.state=="Queued")
	check.call("BUDGET/public_paint_retains_every_tile_under_execution_limit",world.receipts.get(command)=="accepted" and builds.size()==640 and not queued.is_empty() and world.invariant_errors().is_empty(),str([world.receipts.get(command),builds.size(),queued.size(),world.invariant_errors()]))
	var saved: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/queued_orders_roundtrip_with_exact_intent",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	if not saved.has("world"): return
	var invalid: Dictionary = world.payload().duplicate(true)
	for job in invalid.jobs:
		if job.state=="Queued": job.worker=world.citizens[0].id;break
	check.call("SAVE/queued_order_cannot_own_a_worker",ColonyCodec.restore(invalid).get("error","")=="Invalid queued work contract")
	invalid=world.payload().duplicate(true)
	for job in invalid.jobs:
		if job.state=="Queued": job.state=job.queue_state;job.queue_state=""
	check.call("SAVE/current_content_rejects_unbounded_executable_work",ColonyCodec.restore(invalid).get("error","").contains("Executable job limit exceeded"))
	var target: int = queued[-1].id
	world.queue_command("pin",{"citizen":world.citizens[1].id,"target":target})
	saved.world.queue_command("pin",{"citizen":world.citizens[1].id,"target":target})
	for index in range(9): world.step();saved.world.step()
	check.call("BUDGET/pinned_queued_order_is_admitted_and_reserved",world.citizens[1].job==target and world.find(world.jobs,target).state!="Queued" and world.canonical_hash()==saved.world.canonical_hash() and world.invariant_errors().is_empty(),str([world.citizens[1].job,target,world.find(world.jobs,target).state,world.invariant_errors()]))
	var root: String = "user://work-budget-journal-%d" % Time.get_ticks_usec()
	var store: ColonyStore = ColonyStore.new();store.root_directory=root;store.select_slot(1)
	var error: String = store.save(world)
	world.queue_command("cancel",{"target":queued[0].id});world.step()
	if error.is_empty(): error=store.checkpoint(world)
	var recovered: Dictionary = store.load_latest()
	check.call("SAVE/queued_order_cancellation_and_admission_recover_from_journal",error.is_empty() and recovered.has("world") and recovered.world.canonical_hash()==world.canonical_hash(),error+str(recovered.get("error","")))
	CampaignTests.remove_tree(root)
	ColonyCare.hurt(world,world.citizens[2],90,true)
	world.citizens[1].fullness=0
	for index in range(9): world.step()
	check.call("BUDGET/full_order_queue_admits_emergency_care_and_critical_food",world.jobs.any(func(j:Dictionary)->bool:return j.emergency and j.worker>0) and world.find(world.jobs,world.citizens[1].job).get("kind")=="eat" and world.invariant_errors().is_empty(),str([world.find(world.jobs,world.citizens[1].job).get("kind"),world.invariant_errors()]))
	var first: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world));var second: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	if not first.has("world") or not second.has("world"): check.call("BUDGET/cached_admission_fixture_restores",false);return
	second.world.work_budget=UncachedBudget.new()
	var exact: bool = true
	for index in range(120):
		if index in [20,40,60]:
			var kind: String = "pin" if index==20 else ("priority" if index==40 else "cancel")
			var args: Dictionary = {"target":builds[620].id,"citizen":world.citizens[3].id} if index==20 else ({"target":builds[610].id,"value":3} if index==40 else {"target":builds[600].id})
			first.world.queue_command(kind,args);second.world.queue_command(kind,args)
		if index==80:
			for person in first.world.citizens: person.preferences.Building=0
			for person in second.world.citizens: person.preferences.Building=0
		first.world.step();second.world.step()
		exact=exact and first.world.canonical_hash()==second.world.canonical_hash()
	check.call("BUDGET/cached_admission_matches_full_reconciliation_through_retries_and_commands",exact and first.world.invariant_errors().is_empty(),str(first.world.invariant_errors()))
	# Unusable old orders cannot occupy all admission capacity while useful food
	# work waits behind them. Under the limit, ordinary existing states stay put.
	var off_world: ColonyWorld = ColonyTests.world()
	for person in off_world.citizens: person.preferences.Building=0
	off_world.queue_command("build_area",{"definition":"wood_floor","tiles":tiles});off_world.step()
	off_world._make_stack("berry",8,"ground",0,Vector2i(66,63),true)
	for stack in off_world.stacks:
		if stack.item=="meal": off_world._record("consumed","meal",stack.count);stack.count=0
	off_world._create_work();off_world.work_budget.reconcile(off_world)
	check.call("BUDGET/disabled_categories_cannot_starve_usable_cooking_slots",off_world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="cook" and j.state!="Queued") and off_world.invariant_errors().is_empty(),str(off_world.invariant_errors()))

static func legacy_upgrade(check: Callable) -> void:
	var path: String = "res://tests/fixtures/schema22-budget-upgrade.brackenward"
	var before: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var envelope: Dictionary = JSON.parse_string(before.get_string_from_utf8())
	var original: Dictionary = ColonyState.unpack(JSON.parse_string(envelope.payload))
	var loaded: Dictionary = ColonyCodec.decode(before)
	var normalized: Dictionary = SchemaCompatibility.normalize(loaded.world,original) if loaded.has("world") else {}
	check.call("SAVE/schema22_working_colony_preserves_every_acknowledged_gameplay_field",loaded.has("world") and loaded.world.schema_revision==24 and loaded.world.CONTENT_VERSION=="colony-v11" and JSON.stringify(ColonyState.pack(normalized),"",true).sha256_text()=="437b533de5a1e1a4d5b9348d0ee9b9171bc4f60d2a16c1da628c3e3a721e7d33" and FileAccess.get_sha256(path)=="eac9462f2633de6d5f9c805ce755876876dbf262e7032cb57a688830b6414b36",str(loaded.get("error","")))
	original.stores[0].filters.reverse()
	envelope.payload=JSON.stringify(ColonyState.pack(original),"",true);envelope.sha256=envelope.payload.sha256_text()
	loaded=ColonyCodec.decode(JSON.stringify(envelope,"",true).to_utf8_buffer())
	check.call("SAVE/v2_upgrade_keeps_player_storage_filter_order_exactly",loaded.has("world") and SchemaCompatibility.normalize(loaded.world,original)==original,str(loaded.get("error","")))
