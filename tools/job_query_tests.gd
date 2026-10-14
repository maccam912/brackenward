class_name JobQueryTests
extends RefCounted

class ReservationProbe extends ColonyWorld:
	var target: int = 0
	func _init(catalog: Dictionary) -> void:
		super(catalog)
	func _assign_search(citizen: Dictionary) -> void:
		var job: Dictionary = find(jobs,target)
		if _reserve(job,citizen): citizen.job=job.id

static func run(check: Callable) -> void:
	reservation_search(check)
	var world: ColonyWorld = ColonyTests.world()
	var point: Vector2i = Vector2i(80,80)
	for index in range(5000):
		var old: Dictionary = world._job("leisure","","",1,point,0)
		old.state="Complete" if index%2==0 else "Canceled"
	var first: Dictionary = world._job("leisure","","",1,point,0)
	var second: Dictionary = world._job("leisure","","",2,point,0)
	second.state="Blocked"
	var original: String = world.canonical_hash()
	var query: Array = world.unfinished_jobs()
	check.call("JOBS/history_is_retained_but_not_a_scheduling_candidate",world.jobs.size()==5002 and query.size()==2 and query[0].id==first.id and query[1].id==second.id)
	query.reverse();query.clear()
	check.call("JOBS/caller_sort_or_clear_cannot_change_query_order",world.unfinished_jobs().map(func(j:Dictionary)->int:return j.id)==[first.id,second.id])
	check.call("JOBS/query_cache_has_no_authoritative_payload",world.canonical_hash()==original)
	var resource: Dictionary = world.resources[0]
	var third: Dictionary = world._job("gather","Gathering","Field",resource.id,Vector2i(resource.x,resource.y),16000)
	third.definition=resource.definition
	check.call("JOBS/new_same_tick_work_is_visible",world.unfinished_jobs().back().id==third.id)
	world._release(first,true)
	second.state="Complete"
	check.call("JOBS/same_tick_cancel_and_completion_disappear",world.unfinished_jobs().size()==1 and world.unfinished_jobs()[0].id==third.id)
	world._release(third,false)
	check.call("JOBS/nonterminal_release_stays_schedulable",world.unfinished_jobs().size()==1 and world.unfinished_jobs()[0].state=="Ready")
	world.tick+=1
	check.call("JOBS/next_tick_prunes_finished_references",world.unfinished_jobs().size()==1 and world.job_query_live.size()==1 and world.job_query_count==5003)
	var saved: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/job_query_cache_rebuilds_after_full_history_import",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash() and saved.world.jobs.size()==5003 and saved.world.unfinished_jobs().size()==1,str(saved.get("error","")))
	world.jobs=world.jobs.duplicate(true)
	check.call("JOBS/replaced_array_rebuilds_same_size_query",world.unfinished_jobs().size()==1 and is_same(world.unfinished_jobs()[0],world.jobs[-1]))
	world.jobs.clear()
	check.call("JOBS/cleared_array_does_not_keep_phantom_work",world.unfinished_jobs().is_empty())
	field_jobs(check)

static func reservation_search(check: Callable) -> void:
	var world: ReservationProbe = ReservationProbe.new(ColonyTests.world().definitions)
	var station: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	var point: Vector2i = Vector2i(station.x,station.y)
	for index in range(2000):
		var old: Dictionary = world._job("leisure","","",0,point,0);old.state="Complete"
	var ordinary: Dictionary = world._job("cook","Cooking","Cook",station.id,point,4000)
	ordinary.worker=world.citizens[1].id
	var shared: Dictionary = world._job("minor_study","Research","Study",0,point,4000)
	shared.worker=world.citizens[2].id;shared.memo={"station":station.id}
	var candidate: Dictionary = world._job("cook","Cooking","Cook",station.id,point,4000)
	candidate.state="Ready";world.target=candidate.id
	# Deliberately use a history order different from immutable ID order.
	world.jobs.reverse()
	world._assign(world.citizens[0])
	check.call("JOBS/reservation_conflict_keeps_original_history_reason",candidate.reason=="Research desk in use by a shared observation")
	check.call("JOBS/reservation_scope_clears_after_early_assignment_return",not world.assigning_work and not world.reservation_query_ready and world.reservation_query_jobs.is_empty())
	world._release(shared,false);candidate.state="Ready"
	world._assign(world.citizens[0])
	check.call("JOBS/next_resident_search_refreshes_released_ownership",candidate.reason=="Workstation in use by another resident")
	# Direct reservation calls must also observe records without citizen links.
	ordinary.worker=0;shared.worker=world.citizens[2].id;candidate.state="Ready"
	world._reserve(candidate,world.citizens[0])
	check.call("JOBS/direct_reservation_retains_full_history_fallback",candidate.reason=="Research desk in use by a shared observation" and is_same(world._reservation_jobs(),world.jobs))

static func field_jobs(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	world.queue_command("field",{"crop":"turnip","tiles":[Vector2i(80,80),Vector2i(81,80),Vector2i(82,80)]})
	world.step()
	ColonyAgriculture.create_jobs(world)
	var count: int = world.jobs.size()
	ColonyAgriculture.create_jobs(world)
	check.call("JOBS/field_index_prevents_same_tick_duplicate_operations",world.jobs.size()==count and world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.kind=="prepare").size()==3)
	var first: Dictionary = world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.kind=="prepare")[0]
	world._release(first,true)
	ColonyAgriculture.create_jobs(world)
	check.call("JOBS/canceled_field_operation_can_be_replanned",world.jobs.size()==count+1 and world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.kind=="prepare" and j.target==first.target).size()==1)
