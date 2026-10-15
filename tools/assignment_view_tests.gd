class_name AssignmentViewTests
extends RefCounted

static func expected(world: ColonyWorld) -> Array:
	# Complete original f887763 expression, independent of the direct loop.
	return (world._work_jobs() if world.in_tick else world.unfinished_jobs()).filter(func(j:Dictionary)->bool:return j.state not in ["Complete","Canceled","Queued"])

static func same(world: ColonyWorld) -> bool:
	var before: String=world.canonical_hash();var actual: Array=world._assignment_jobs();var original: Array=expected(world)
	if actual.size()!=original.size() or world.canonical_hash()!=before:return false
	for index in range(original.size()):
		if not is_same(actual[index],original[index]):return false
	return true

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();var target: int=world.resources[0].id
	for state in ["Ready","Blocked","Fetching","Delivering","Moving","Working","Queued","Complete","Canceled"]:
		for index in range(64):
			var job: Dictionary=world._job("gather","Gathering","Field",target,Vector2i(80,80),1000);job.state=state
	world.in_tick=true
	var rows: Array=world._assignment_jobs();var exact: bool=same(world)
	var ids: Array=rows.map(func(j:Dictionary)->int:return j.id)
	rows.reverse();rows.clear()
	check.call("ASSIGN/direct_loop_preserves_all_states_order_live_records_and_owned_container",exact and ids.size()==384 and world._assignment_jobs().map(func(j:Dictionary)->int:return j.id)==ids and same(world))
	world=ColonyTests.world();world.in_tick=true
	var first: Dictionary=world._job("gather","Gathering","Field",world.resources[0].id,Vector2i(80,80),1000)
	var second: Dictionary=world._job("gather","Gathering","Field",world.resources[0].id,Vector2i(81,80),1000)
	exact=same(world);first.state="Complete";exact=exact and same(world)
	var appended: Dictionary=world._job("gather","Gathering","Field",world.resources[0].id,Vector2i(82,80),1000)
	exact=exact and same(world) and world._assignment_jobs().map(func(j:Dictionary)->int:return j.id)==[second.id,appended.id]
	world._release(second,true);exact=exact and same(world) and world._assignment_jobs().size()==1
	world.jobs=world.jobs.duplicate(true);exact=exact and same(world)
	world.jobs.resize(1);exact=exact and same(world) and world._assignment_jobs().is_empty()
	check.call("ASSIGN/same_tick_append_end_release_and_table_replacement_keep_original_membership",exact)
	world=ColonyTests.world();target=world.resources[0].id
	for state in ["Ready","Queued","Complete","Canceled","Blocked"]:
		var job: Dictionary=world._job("gather","Gathering","Field",target,Vector2i(80,80),1000);job.state=state
	var before: String=world.canonical_hash();rows=world._assignment_jobs();rows.clear()
	check.call("ASSIGN/direct_outside_tick_calls_keep_exact_original_query_and_no_canonical_changes",not world.in_tick and same(world) and world._assignment_jobs().size()==2 and world.canonical_hash()==before)
