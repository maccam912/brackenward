class_name CaptureTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var cache: ColonyCapture = ColonyCapture.new()
	var retired: Array = []
	var first: Dictionary = cache.capture(world,retired)
	check.call("SAVE/capture_owns_every_mutable_branch",first==world.payload() and frozen(first) and not world.jobs.is_read_only() and not world.citizens[0].is_read_only() and not is_same(first.citizens[0],world.citizens[0]))
	var unchanged: Dictionary = cache.capture(world,retired)
	check.call("SAVE/capture_reuses_unchanged_owned_records",is_same(first.citizens[0],unchanged.citizens[0]) and is_same(first.terrain_state,unchanged.terrain_state) and not is_same(first.citizens,unchanged.citizens))
	var original: int = world.citizens[0].fullness
	world.citizens[0].fullness-=1;world.citizens[0].skills.Cooking+=1
	var changed: Dictionary = cache.capture(world,retired)
	check.call("SAVE/capture_live_changes_never_rewrite_an_older_capture",first.citizens[0].fullness==original and changed.citizens[0].fullness==original-1 and first.citizens[0].skills.Cooking+1==changed.citizens[0].skills.Cooking and is_same(first.citizens[1],changed.citizens[1]) and frozen(changed))
	world.structures.reverse();world.structures.remove_at(0)
	world.structures.append(world._structure("bed",Vector2i(80,80),0))
	var reordered: Dictionary = cache.capture(world,retired)
	check.call("SAVE/capture_follows_current_order_removal_and_new_ids",reordered==world.payload() and reordered.structures.size()==world.structures.size() and reordered.structures[-1].id==world.structures[-1].id and first.structures[0].id!=reordered.structures[0].id)
	world.emit_fact({"tick":world.tick,"actor":1,"job":0,"kind":"capture_fixture","text":"An ordinary Chronicle fact."})
	var chronicle: Dictionary = cache.capture(world,retired)
	world.emit_fact({"tick":world.tick,"actor":2,"job":0,"kind":"capture_fixture","text":"Another ordinary Chronicle fact."})
	var later: Dictionary = cache.capture(world,retired)
	check.call("SAVE/capture_chronicle_grows_without_copying_unchanged_facts",later.chronicle_state.facts.size()==chronicle.chronicle_state.facts.size()+1 and is_same(later.chronicle_state.facts[0],chronicle.chronicle_state.facts[0]) and first.chronicle_state.facts.is_empty() and frozen(later))
	var restored: Dictionary = ColonyDelta.restore(chronicle,ColonyDelta.make(chronicle,later))
	check.call("SAVE/capture_readonly_delta_recovery_returns_mutable_owned_state",restored.get("state")==later and not restored.state.is_read_only() and not restored.state.citizens[0].is_read_only())
	var other: ColonyWorld = ColonyTests.world()
	other.session_id=world.session_id
	var replaced: Dictionary = cache.capture(other,retired)
	check.call("SAVE/capture_world_replacement_cannot_reuse_stale_same_campaign_data",replaced==other.payload() and not is_same(first.citizens[0],replaced.citizens[0]) and first.citizens[0].fullness==original)
	check.call("SAVE/capture_retirement_holds_old_trees_until_worker_cleanup",retired.any(func(value:Variant)->bool:return is_same(value,first)))
	block_boundaries(check)

static func block_boundaries(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	for index in range(513): world._job("sleep","","",0,Vector2i(70,70),0)
	var cache: ColonyCapture = ColonyCapture.new()
	var retired: Array = []
	var first: Dictionary = cache.capture(world,retired)
	world.jobs[256].reason="Changed at a block boundary"
	var changed: Dictionary = cache.capture(world,retired)
	check.call("SAVE/capture_changed_middle_block_keeps_neighbors_owned_and_exact",changed==world.payload() and first.jobs[256].reason!=changed.jobs[256].reason and is_same(first.jobs[0],changed.jobs[0]) and is_same(first.jobs[512],changed.jobs[512]) and frozen(changed))
	world.jobs.reverse();world.jobs.remove_at(255)
	world._job("sleep","","",0,Vector2i(71,70),0)
	world.jobs.insert(0,world.jobs.pop_back())
	var reordered: Dictionary = cache.capture(world,retired)
	check.call("SAVE/capture_reorder_and_replace_across_blocks_preserves_every_record",reordered==world.payload() and first.jobs.size()==513 and is_same(first.jobs[512],reordered.jobs[1]) and frozen(reordered))
	var unchanged: Dictionary = cache.capture(world,retired)
	check.call("SAVE/capture_unchanged_full_blocks_reuse_all_owned_records",unchanged==reordered and is_same(unchanged.jobs[0],reordered.jobs[0]) and is_same(unchanged.jobs[256],reordered.jobs[256]) and is_same(unchanged.jobs[512],reordered.jobs[512]))

static func frozen(value: Variant) -> bool:
	if value is Dictionary:
		if not value.is_read_only(): return false
		for key in value:
			if not frozen(value[key]): return false
	elif value is Array:
		if not value.is_read_only(): return false
		for entry in value:
			if not frozen(entry): return false
	return true
