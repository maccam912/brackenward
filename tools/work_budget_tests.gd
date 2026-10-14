class_name WorkBudgetTests
extends RefCounted

class UncachedBudget extends ColonyWorkBudget:
	func after_commands(world: ColonyWorld, _had_commands: bool) -> void:
		reconcile(world)
	func reconcile(world: ColonyWorld) -> void:
		var result: Dictionary = reconcile_records(world.citizens,world.unfinished_jobs(),world.tick)
		used=result.used

static func run(check: Callable) -> void:
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
	check.call("SAVE/schema22_working_colony_preserves_every_acknowledged_gameplay_field",loaded.has("world") and loaded.world.schema_revision==23 and loaded.world.CONTENT_VERSION=="colony-v3" and JSON.stringify(ColonyState.pack(normalized),"",true).sha256_text()=="437b533de5a1e1a4d5b9348d0ee9b9171bc4f60d2a16c1da628c3e3a721e7d33" and FileAccess.get_sha256(path)=="eac9462f2633de6d5f9c805ce755876876dbf262e7032cb57a688830b6414b36",str(loaded.get("error","")))
	original.stores[0].filters.reverse()
	envelope.payload=JSON.stringify(ColonyState.pack(original),"",true);envelope.sha256=envelope.payload.sha256_text()
	loaded=ColonyCodec.decode(JSON.stringify(envelope,"",true).to_utf8_buffer())
	check.call("SAVE/v2_upgrade_keeps_player_storage_filter_order_exactly",loaded.has("world") and SchemaCompatibility.normalize(loaded.world,original)==original,str(loaded.get("error","")))
