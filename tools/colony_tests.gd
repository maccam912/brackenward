class_name ColonyTests
extends RefCounted

static func world() -> ColonyWorld:
	return ColonyWorld.new(ColonyCatalog.load_data())

static func run(check: Callable) -> void:
	area_gathering(check)
	var initial: ColonyWorld = world()
	check.call("M1/starting_supply_and_equipment", initial.total("wood") == 44 and initial.available("meal") == 24 and initial.stores[0].capacity == 300 and initial.invariant_errors().is_empty())
	var route: Array[Vector2i] = ColonyNavigation.path(Vector2i(0, 0), Vector2i(2, 2), func(p: Vector2i) -> bool: return ColonyWorld.inside(p))
	check.call("M1/navigation_tie_break", route == [Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)])
	for level in [0, 3]:
		var w: ColonyWorld = world()
		var worker: Dictionary = w.citizens[0]
		worker.skills.Build = level
		var job: Dictionary = w._job("build", "Building", "Build", 0, Vector2i(74, 62), 100000)
		var effort: int = 0
		for i in range(100):
			effort += w._rate(worker, job)
		check.call("SIM03/skill_%d_exact_rate" % level, effort == (10000 if level == 0 else 13000))
	var w: ColonyWorld = world()
	w.citizens[0].fullness = 1000
	for i in range(7200):
		w._needs(w.citizens[0])
	check.call("SIM04/day_fullness_exact", w.citizens[0].fullness == 0 and w.citizens[0].hunger_rem == 0)
	w.citizens[0].starving_ticks = 0
	w.citizens[0].health = 100
	for i in range(1800):
		w._needs(w.citizens[0])
	check.call("SIM05/starvation_grace", w.citizens[0].health == 100)
	for i in range(300):
		w._needs(w.citizens[0])
	check.call("SIM05/starvation_damage", w.citizens[0].health == 95)
	for kind in ["bed", "bedroll", "ground"]:
		w = world()
		var resident: Dictionary = w.citizens[0]
		resident.rest = 100
		var bed: Dictionary = w.find(w.structures, resident.bed)
		if kind != "ground": resident.x=bed.x;resident.y=bed.y
		if kind != "ground":
			bed.definition = kind
		var sleep_job: Dictionary = w._job("sleep", "", "", bed.id if kind != "ground" else 0, Vector2i(resident.x, resident.y), 0)
		sleep_job.state = "Working"
		resident.job = sleep_job.id
		for i in range(1200):
			w._needs(resident)
		check.call("SIM06/four_hour_%s" % kind, resident.rest == {"bed": 700, "bedroll": 580, "ground": 420}[kind])
	for phase in ["Fetching", "Delivering", "Working"]:
		w = world()
		w.queue_command("build", {"definition": "bed", "x": 74, "y": 63, "rotation": 0})
		var found: bool = false
		var job: Dictionary
		for i in range(3000):
			w.step()
			for candidate in w.jobs:
				if candidate.kind == "build" and candidate.state == phase:
					job = candidate
					found = true
			if found:
				break
		var before: Dictionary = {"wood": w.total("wood"), "fiber": w.total("fiber")}
		if found:
			w.queue_command("cancel", {"target": job.id})
			w.step()
		check.call("SIM08/cancel_build_" + phase, found and w.total("wood") == before.wood and w.total("fiber") == before.fiber and w.invariant_errors().is_empty() and job.state == "Canceled", str(w.invariant_errors()))
	# Exclusive reservations and cancellation across actual recipe and haul phases.
	for kind in ["cook", "haul"]:
		for phase in ["Fetching", "Delivering", "Working"]:
			if kind == "haul" and phase == "Working":
				continue
			w = world()
			for resident in w.citizens:
				resident.preferences["Hauling" if kind == "cook" else "Cooking"] = 0
			for stack in w.stacks:
				if stack.item == "meal":
					w._record("consumed", "meal", stack.count)
					stack.count = 0
			w._make_stack("berry", 4, "ground", 0, Vector2i(68, 68), true)
			var target_job: Dictionary = {}
			for i in range(1500):
				w.step()
				for candidate in w.jobs:
					if candidate.kind == kind and candidate.state == phase:
						target_job = candidate
				if not target_job.is_empty():
					break
			var before_berry: int = w.total("berry")
			var before_wood: int = w.total("wood")
			if not target_job.is_empty():
				w.queue_command("cancel", {"target": target_job.id})
				w.step()
			check.call("SIM08/cancel_%s_%s" % [kind, phase], not target_job.is_empty() and target_job.state == "Canceled" and w.total("berry") == before_berry and w.total("wood") == before_wood and w.invariant_errors().is_empty(), str(w.invariant_errors()))
	w = world()
	w.queue_command("build", {"definition":"bed", "x":74, "y":63, "rotation":0}, 1)
	w.queue_command("build", {"definition":"bed", "x":76, "y":63, "rotation":0}, 1)
	w.step()
	check.call("M1/command_receipt_no_duplicate_blueprint", w.jobs.size() == 1 and w.receipts.size() == 1)
	for i in range(60): w.step()
	var held_world: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("M1/save_held_inputs_mid_edge", held_world.has("world") and held_world.world.canonical_hash() == w.canonical_hash())
	if held_world.has("world"):
		for i in range(500):
			w.step()
			held_world.world.step()
		check.call("M1/held_inputs_replay", w.canonical_hash() == held_world.world.canonical_hash())
	# A valid-checksum malicious payload must still fail structural validation.
	var bad: Dictionary = ColonyState.pack(w.payload())
	bad.citizens[0].preferences.Cooking = 9
	var bad_text: String = JSON.stringify(bad)
	var bad_envelope: Dictionary = JSON.parse_string(ColonyCodec.encode(w).get_string_from_utf8())
	bad_envelope.payload = bad_text
	bad_envelope.sha256 = bad_text.sha256_text()
	check.call("M1/import_rejects_valid_checksum_invalid_state", ColonyCodec.decode(JSON.stringify(bad_envelope).to_utf8_buffer()).has("error"))
	# Durable commands plus tick markers reconstruct exact acknowledged state.
	w = world()
	var store: ColonyStore = ColonyStore.new()
	store.directory = "user://journal-test-%d" % Time.get_ticks_usec()
	check.call("M2/journal_base_snapshot", store.save(w).is_empty())
	w.queue_command("build", {"definition":"bed", "x":74, "y":63, "rotation":0})
	for i in range(71): w.step()
	check.call("M2/journal_verified_write", store.checkpoint(w).is_empty())
	var recovery: Dictionary = store.load_latest()
	check.call("M2/journal_exact_command_tick_recovery", recovery.has("world") and recovery.world.canonical_hash() == w.canonical_hash(), str(recovery.get("error", "hash differs")))
	var journal_path: String = store.directory.path_join("journal-%010d.frames" % store.sequence)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(journal_path)
	var torn: PackedByteArray = bytes.duplicate()
	torn.append_array(ColonyJournal.frame({"sequence":"3", "kind":"tick", "tick":w.tick + 1}).slice(0, 8))
	var parsed: Dictionary = ColonyJournal.read(torn)
	check.call("M2/torn_tail_retains_complete_marker", not parsed.has("error") and parsed.torn_tail and parsed.records.size() == 2)
	bytes[10] ^= 1
	check.call("M2/journal_checksum_failure_rejected", ColonyJournal.read(bytes).has("error"))
	# Corrupt newest journal must recover older generation and preserve evidence.
	for i in range(10): w.step()
	store.save(w)
	for i in range(10): w.step()
	store.checkpoint(w)
	var newest: String = store.directory.path_join("journal-%010d.frames" % store.sequence)
	var bad_bytes: PackedByteArray = FileAccess.get_file_as_bytes(newest)
	bad_bytes[10] ^= 1
	var bad_file: FileAccess = FileAccess.open(newest, FileAccess.WRITE)
	bad_file.store_buffer(bad_bytes)
	bad_file.close()
	recovery = store.load_latest()
	check.call("M2/bad_newest_journal_falls_back_without_overwrite", recovery.has("world") and recovery.world.tick == 1871 and FileAccess.get_file_as_bytes(newest) == bad_bytes)
	for name in DirAccess.get_files_at(store.directory):
		DirAccess.remove_absolute(store.directory.path_join(name))
	DirAccess.remove_absolute(store.directory)
	# A real loop; setup removes only the initial meal reserve to require new cooking.
	w = world()
	for stack in w.stacks:
		if stack.item == "meal":
			w._record("consumed", "meal", stack.count)
			stack.count = 0
	w.queue_command("gather", {"target": w.resources[0].id})
	for index in range(30, 34):
		w.queue_command("gather", {"target": w.resources[index].id})
	w.queue_command("build", {"definition": "bed", "x": 74, "y": 63, "rotation": 0})
	w.queue_designation([Vector2i(58, 64), Vector2i(58, 65)])
	var errors: Array[String] = []
	var saw_sleep: bool = false
	for i in range(7200):
		w.step()
		if i % 10 == 0:
			errors.append_array(w.invariant_errors())
			saw_sleep = saw_sleep or w.jobs.any(func(job: Dictionary) -> bool: return job.kind == "sleep" and job.state == "Working")
	var kinds: Array = w.facts.map(func(f: Dictionary) -> String: return f.kind)
	check.call("M1/visible_gather_haul_cook_build_eat_sleep", ["gather", "haul", "cook", "build", "eat"].all(func(kind: String) -> bool: return kinds.has(kind)) and w.ledger.produced.get("meal", 0) > 24 and w.structures.any(func(s: Dictionary) -> bool: return s.definition == "bed") and saw_sleep and w.citizens.any(func(c: Dictionary) -> bool: return c.rest > 700), str(kinds))
	check.call("M1/end_to_end_conservation", errors.is_empty(), str(errors.slice(0, 8)))
	# Mid-edge plus held input and completed work all survive exact continuation.
	var restored: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("M1/save_roundtrip", restored.has("world") and restored.world.canonical_hash() == w.canonical_hash(), str(restored.get("error", "hash mismatch")))
	if restored.has("world"):
		for i in range(1000):
			w.step()
			restored.world.step()
		check.call("M1/save_continuation", w.canonical_hash() == restored.world.canonical_hash())
	var hashes: Array[String] = []
	for speed in [1, 2, 4]:
		w = world()
		w.queue_command("gather", {"target": w.resources[0].id})
		w.queue_command("build", {"definition": "bed", "x": 74, "y": 63, "rotation": 0})
		var runner: SimRunner = SimRunner.new(w)
		runner.set_speed(speed)
		for frame in range(72000 / speed):
			runner.advance_frame(0.1)
		hashes.append(w.canonical_hash())
	check.call("SIM01/colony_72000_ticks_speeds", hashes[0] == hashes[1] and hashes[1] == hashes[2], str(hashes))

static func area_gathering(check: Callable) -> void:
	var w: ColonyWorld = world()
	var tiles: Array[Vector2i] = []
	for y in range(54,58):
		for x in range(51,56): tiles.append(Vector2i(x,y))
	for citizen in w.citizens: citizen.preferences.Gathering = 0
	w.queue_command("gather_area",{"definition":"tree","tiles":tiles})
	var pending: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("WORK/area_pending_command_roundtrip",pending.has("world") and pending.world.canonical_hash() == w.canonical_hash(),str(pending.get("error","")))
	w.step()
	var marked: Array = w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "gather")
	check.call("WORK/rectangle_marks_only_six_matching_trees",marked.size() == 6 and marked.all(func(j:Dictionary)->bool:return w.find(w.resources,j.target).definition == "tree"))
	for i in range(100): w.step()
	check.call("WORK/off_category_keeps_orders_waiting",marked.all(func(j:Dictionary)->bool:return j.worker == 0 and j.work == 0))
	w.queue_command("gather_area",{"definition":"tree","tiles":tiles})
	w.step()
	check.call("WORK/repeated_area_does_not_duplicate_jobs",w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "gather").size() == 6)
	w.queue_command("preference",{"citizen":3,"category":"Gathering","value":3})
	var restored: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	for i in range(4000):
		w.step()
		if restored.has("world"): restored.world.step()
	check.call("WORK/eligible_worker_finishes_entire_rectangle",marked.all(func(j:Dictionary)->bool:return j.state == "Complete") and w.ledger.produced.wood == 92 and w.invariant_errors().is_empty(),str(marked.map(func(j:Dictionary)->Array:return [j.state,j.reason])))
	check.call("WORK/area_save_continues_exactly",restored.has("world") and restored.world.canonical_hash() == w.canonical_hash())
	w = world()
	w.queue_command("gather_area",{"definition":"tree","tiles":[Vector2i(55,54),Vector2i(-1,0)]})
	w.step()
	check.call("WORK/invalid_area_is_atomic",w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "gather").is_empty() and w.receipts[1] == "invalid_tile")
	w = world()
	var node: Dictionary = w.resources[-1]
	node.remaining = 3
	w.queue_command("gather_area",{"definition":"stone_node","tiles":[Vector2i(node.x,node.y)]})
	for i in range(1500): w.step()
	check.call("WORK/mining_area_repeats_unit_jobs_until_empty",node.remaining == 0 and w.ledger.produced.stone == 33 and w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "gather" and j.state == "Complete").size() == 3 and w.invariant_errors().is_empty())
	w = world()
	w.queue_command("gather_area",{"definition":"tree","tiles":tiles})
	w.step()
	marked = w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "gather")
	w.queue_command("cancel",{"target":marked[0].id})
	for i in range(2500): w.step()
	check.call("WORK/canceled_tree_stays_unharvested",marked[0].state == "Canceled" and w.find(w.resources,marked[0].target).remaining == 8 and marked.slice(1).all(func(j:Dictionary)->bool:return j.state == "Complete"))
