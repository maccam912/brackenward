class_name AssignmentReadTests
extends RefCounted
## Original d6b3dab assignment search retained before reducing temporary lists.
## Updated only for the v8 hunger checkpoints; the older query strategy remains independent.
class OriginalWorld extends ColonyWorld:
	func _assign_search(citizen: Dictionary, food_checkpoint: bool = false) -> void:
		work_budget.mark_dirty()
		if citizen.away: return
		if citizen.death_recorded or citizen.departed:
			citizen.activity = "Died" if citizen.death_recorded else "Departed"
			return
		if citizen.downed:
			citizen.activity = "Hearthside recovery" if citizen.hearthside_until > tick else ("Downed: bleeding, needs care" if not citizen.stabilized else "Downed: recovering")
			return
		if ColonyDanger.escape(self,citizen): return
		if AssignmentReadTests.full_step_aside(self,citizen): return
		if ColonyCharter.assign(self,citizen): return
		# Query lists preserve job order and share the live dictionaries, so releases
		# and failed reservations below remain visible to subsequent queries.
		var open_jobs: Array = unfinished_jobs().filter(func(j:Dictionary)->bool:return j.state!="Queued")
		var arrivals: Array = open_jobs.filter(func(j:Dictionary)->bool:return j.kind=="arrival" and j.target==citizen.id)
		var arrival: Dictionary = {} if arrivals.is_empty() else arrivals[0]
		var preparing: bool = ColonyRegion.preparing(self,citizen)
		var food_threshold: int = 500 if preparing else 350
		var needs_sleep: bool = ColonyRest.wants_sleep(citizen,tick,preparing)
		var hour: int = ((tick % 7200) / 300 + (12 if citizen.shift == "Night shift" else 0)) % 24
		# Release for sleep only when the same search can actually start sleeping.
		var sleep_eligible: bool = needs_sleep and (citizen.fullness > 350 or citizen.rest <= 100)
		var current: Dictionary = find(jobs, citizen.job)
		var hunger_food: Dictionary = {};var hunger_food_checked: bool = false
		var taking_break: bool = citizen.break_until > tick
		var draft_ready: bool = citizen.drafted and not taking_break and citizen.fullness > 0 and citizen.rest > 100 and (citizen.health > 40 or citizen.stand_fast)
		var treatment_wait: bool = not draft_ready and citizen.fullness > 0 and citizen.rest > 100 and open_jobs.any(func(j:Dictionary)->bool:return j.kind == "treat" and j.target == citizen.id and j.state not in ["Complete","Canceled"])
		if treatment_wait and current.get("kind") not in ["eat","sleep"]:
			_release(current,false)
			citizen.activity = "Resting for treatment"
			return
		if not current.is_empty():
			var emergency: bool = citizen.health > 20 and citizen.break_until <= tick and citizen.fullness > 0 and citizen.rest > 100 and open_jobs.any(func(j:Dictionary)->bool:return j.emergency and j.worker == 0 and j.state not in ["Complete","Canceled"] and tick >= j.retry)
			var ordinary_food: bool = not draft_ready and not current.emergency and citizen.fullness<=food_threshold and current.kind!="eat" and (current.kind!="sleep" or citizen.rest>100)
			if ordinary_food or (citizen.fullness==0 and current.kind!="eat"):
				# Query the exact food that releasing this job would expose, without
				# dropping its cargo unless a reachable meal can actually be taken.
				hunger_food=_food(citizen,current);hunger_food_checked=true
			var urgent_self_care: bool = (citizen.fullness == 0 and current.kind != "eat" and (not hunger_food.is_empty() or current.kind=="defend")) or (citizen.rest <= 100 and current.kind not in ["eat","sleep"])
			var change_to_defense: bool = draft_ready and not current.emergency and current.kind != "defend"
			# Hunger still drains during sleep. Wake for ordinary food before reaching
			# zero, while protecting life-critical rest until it exceeds 100.
			var needs_food: bool = ordinary_food and not hunger_food.is_empty()
			if needs_food and citizen.fullness>0 and not food_checkpoint and _finishing_food_iteration(citizen,current):
				if current.state=="Fetching": current.state="Delivering"
				needs_food=false
			var hungry_sleeper: bool = current.kind=="sleep" and citizen.fullness<=350 and citizen.rest>=ColonyRest.TIRED
			var ordinary_needs: bool = not draft_ready and not current.emergency and (needs_food or hungry_sleeper or (sleep_eligible and current.kind not in ["eat","sleep"]))
			var break_interrupt: bool = taking_break and current.kind not in ["eat","sleep","leisure","recover"]
			if urgent_self_care or break_interrupt or (emergency and not current.emergency) or change_to_defense or ordinary_needs:
				_release(current, false)
			else:
				return
		if citizen.health > 20 and citizen.fullness > 0 and citizen.rest > 100 and citizen.break_until <= tick:
			var emergencies: Array = open_jobs.filter(func(j:Dictionary)->bool:return j.emergency and j.worker == 0 and j.state not in ["Complete","Canceled"] and tick >= j.retry)
			_sort_jobs(emergencies,citizen)
			for emergency in emergencies:
				hunger_food_checked=false
				if _reserve(emergency,citizen): citizen.job = emergency.id; return
		if draft_ready and ColonyDefense.assign(self,citizen): return
		if citizen.fullness <= food_threshold:
			var food: Dictionary = hunger_food if hunger_food_checked else _food(citizen)
			if not food.is_empty():
				var eat_job: Dictionary = _job("eat", "", "", citizen.id, Vector2i(citizen.x, citizen.y), 2000)
				eat_job.inputs = {food.item: 1}
				eat_job.source = food.id
				if _reserve(eat_job, citizen):
					citizen.job = eat_job.id
					return
			citizen.activity = "Hungry: gather berries or mushrooms and enable Cooking"
		if sleep_eligible:
			var bed: Dictionary = find(structures, citizen.bed)
			var point: Vector2i = Vector2i(citizen.x, citizen.y) if bed.is_empty() or citizen.rest <= 100 else Vector2i(bed.x, bed.y)
			if citizen.rest <= 100: bed = {}
			var sleep_job: Dictionary = _job("sleep", "", "", 0 if bed.is_empty() else bed.id, point, 0)
			sleep_job.worker = citizen.id
			sleep_job.state = "Moving"
			sleep_job.work_x = point.x
			sleep_job.work_y = point.y
			citizen.job = sleep_job.id
			return
		if citizen.health < 50:
			var destination: Dictionary = _care_destination(citizen)
			var recovery: Dictionary = _job("recover","","",destination.id,destination.point,0)
			recovery.worker = citizen.id; recovery.state = "Moving"
			citizen.job = recovery.id
			return
		if not taking_break and ColonyDefense.shelter_assign(self,citizen): return
		if not taking_break and ColonyRegion.assign(self,citizen): return
		if not arrival.is_empty() and _reserve(arrival,citizen):
			citizen.job=arrival.id
			return
		if not taking_break and citizen.departure_until > 0 and tick >= citizen.departure_until:
			var depart_job: Dictionary = _job("depart", "", "", citizen.id, Vector2i(66,127), 0)
			depart_job.worker = citizen.id
			depart_job.state = "Moving"
			citizen.job = depart_job.id
			return
		if citizen.break_until > tick or (hour >= 18 and hour < 20 and citizen.leisure_ticks < 600):
			if not taking_break:
				var urgent: Array = open_jobs.filter(func(j:Dictionary)->bool:return j.worker==0 and j.state not in ["Complete","Canceled"] and tick>=j.retry and citizen.preferences.get(j.category,0)>0 and not _hauling_fallback(j,citizen) and _task_priority(j)==3)
				_sort_jobs(urgent,citizen)
				for job in urgent:
					if _reserve(job,citizen): citizen.job=job.id;return
			var leisure: Dictionary = _job("leisure", "", "", citizen.id, ColonySocial.leisure_seat(self,citizen), 0)
			leisure.state = "Moving"
			leisure.worker = citizen.id
			citizen.job = leisure.id
			return
		if citizen.pinned_job > 0:
			var pinned: Dictionary = find(jobs,citizen.pinned_job)
			if not pinned.is_empty() and pinned.worker == 0 and (citizen.preferences.get(pinned.category,0) > 0 or pinned.kind == "treat") and _reserve(pinned,citizen):
				citizen.job = pinned.id
				return
			citizen.pinned_job = 0
			citizen.activity = "Pinned task unavailable: check its inputs and route"
		var candidates: Array[Dictionary] = []
		for job in open_jobs:
			if job.worker != 0 or job.state in ["Complete", "Canceled"] or tick < job.retry or citizen.preferences.get(job.category, 0) == 0:
				continue
			candidates.append(job)
		var queue: ColonyJobQueue = ColonyJobQueue.new(candidates,self,citizen)
		var storage_context: Dictionary = {}
		while not queue.heap.is_empty():
			var job: Dictionary = queue.pop()
			# Failed hauling probes commit no reservation. Share this search's exact
			# occupancy snapshot until a task succeeds; every resident starts fresh.
			if job.kind!="haul": storage_context.clear()
			elif storage_context.is_empty(): storage_context=_storage_context()
			if _reserve(job, citizen, storage_context):
				citizen.job = job.id
				return
		if citizen.fullness > 350:
			citizen.activity = "Idle: designate resources or place a blueprint"

static func clone(source: ColonyWorld, original: bool, target: ColonyWorld = null) -> ColonyWorld:
	var result: ColonyWorld=target if target!=null else (OriginalWorld.new(source.definitions) if original else ColonyWorld.new(source.definitions))
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	return result

static func paired(source: ColonyWorld, ticks: int, name: String, check: Callable) -> void:
	var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
	var exact: bool=true
	for index in range(ticks):
		fast.step();original.step()
		if index%10==0: exact=fast.canonical_hash()==original.canonical_hash() and exact
	check.call("ASSIGN/"+name+"_matches_original_complete_ticks",exact and fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(fast))
	check.call("ASSIGN/"+name+"_retains_valid_saved_state",decoded.has("world") and decoded.world.canonical_hash()==fast.canonical_hash(),str(decoded.get("error","")))
	if not decoded.has("world"): return
	fast=decoded.world
	for index in range(60): fast.step();original.step()
	check.call("ASSIGN/"+name+"_continues_identically_after_reload",fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty())

static func run(check: Callable) -> void:
	var source: ColonyWorld=ColonyTests.world()
	for index in range(2000):
		var old: Dictionary=source._job("leisure","","",0,Vector2i(60,60),0);old.state="Complete"
	for person in source.citizens: person.fullness=300;person.rest=800
	paired(source,120,"owned_and_new_personal_work_with_history",check)
	source=ColonyTests.world();source._structure("bedroll",Vector2i(74,64),0)
	var offer: Dictionary=ColonyPopulation.offer(source)
	source.queue_command("newcomer",{"target":offer.id,"accept":true});source.step()
	paired(source,120,"newcomer_arrival_and_ordinary_assignment",check)
	var stress: Dictionary=StressFixture.make()
	check.call("ASSIGN/crowded_fixture_is_a_valid_start",stress.has("world"),str(stress.get("error","")))
	if stress.has("world"): paired(stress.world,30,"crowded_danger_and_reservations",check)
	direct_membership(check)
	step_aside_membership(check)
	urgent_haul_contexts(check)

static func direct_membership(check: Callable) -> void:
	var source: ColonyWorld=ColonyTests.world();var resource: Dictionary=source.resources[0]
	var queued: Dictionary=source._job("gather","Gathering","Field",resource.id,Vector2i(resource.x,resource.y),16000)
	queued.definition=resource.definition;queued.state="Queued";queued.queue_state="Ready";queued.priority=3
	var ended: Dictionary=source._job("gather","Gathering","Field",resource.id,Vector2i(resource.x,resource.y),16000)
	ended.definition=resource.definition;ended.state="Complete";ended.work=ended.required;ended.priority=3
	var live: Dictionary=source._job("gather","Gathering","Field",resource.id,Vector2i(resource.x,resource.y),16000)
	live.definition=resource.definition;live.priority=1
	var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
	for world in [fast,original]:
		world.unfinished_jobs();world.find(world.jobs,ended.id).state="Ready"
		for category in world.citizens[0].preferences: world.citizens[0].preferences[category]=3 if category=="Gathering" else 0
		world._assign(world.citizens[0])
	check.call("ASSIGN/direct_search_preserves_original_cached_membership_and_skips_queued",fast.canonical_hash()==original.canonical_hash() and fast.citizens[0].job==live.id and fast.find(fast.jobs,queued.id).worker==0)

## Unchanged d6b3dab construction predicate, kept independent of borrowed views.
static func full_step_aside(world: ColonyWorld, citizen: Dictionary) -> bool:
	if citizen.progress>0: return false
	var point: Vector2i = Vector2i(citizen.x,citizen.y)
	var current: Dictionary = world.find(world.jobs,citizen.job)
	if current.get("kind") in ["step_aside","eat","rescue"] or citizen.carrying_patient>0: return false
	if not current.is_empty() and current.get("kind") not in ["leisure","sleep","recover"] and current.state!="Working": return false
	var blocking: bool = world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="build" and j.work>0 and j.state not in ["Complete","Canceled"] and world.definitions.buildings[j.definition].solid and world.footprint(j).has(point))
	if not blocking: return false
	for delta in ColonyNavigation.NEIGHBORS:
		var next: Vector2i = point+delta
		if not world.walkable(next) or not world.can_step(point,next) or not ColonyDanger.safe(world,next): continue
		if world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="build" and j.state not in ["Complete","Canceled"] and world.definitions.buildings[j.definition].solid and world.footprint(j).has(next)): continue
		world._release(current,false)
		var job: Dictionary = world._job("step_aside","","",citizen.id,next,0)
		job.worker=citizen.id;job.state="Moving";citizen.job=job.id
		citizen.activity="Stepping clear of construction"
		return true
	return false

static func step_aside_membership(check: Callable) -> void:
	for state in ["Ready","Queued"]:
		for terminal in ["Complete","Canceled"]:
			var source: ColonyWorld=ColonyTests.world();source.citizens[0].x=80;source.citizens[0].y=80
			var parent: Dictionary=source._job("build","Building","Build",0,Vector2i(80,80),16000)
			parent.definition="wood_wall";parent.work=1;parent.state=state;parent.queue_state="Ready" if state=="Queued" else ""
			var north: Dictionary=source._job("build","Building","Build",0,Vector2i(80,79),16000)
			north.definition="wood_wall";north.state="Queued";north.queue_state="Ready"
			var right: Dictionary=source._job("build","Building","Build",0,Vector2i(81,80),16000);right.definition="wood_wall"
			var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
			for world in [fast,original]:
				world.in_tick=true;world._work_jobs();world.find(world.jobs,right.id).state=terminal
			var actual: bool=ColonyConstruction.step_aside(fast,fast.citizens[0])
			var expected: bool=full_step_aside(original,original.citizens[0])
			var selected: Dictionary=fast.find(fast.jobs,fast.citizens[0].job)
			check.call("ASSIGN/step_aside_keeps_queued_and_same_tick_%s_%s" % [state,terminal],actual and expected and fast.canonical_hash()==original.canonical_hash() and selected.x==81 and selected.y==80)
	var source: ColonyWorld=ColonyTests.world();source.citizens[0].x=80;source.citizens[0].y=80
	for point in [Vector2i(80,80),Vector2i(80,79),Vector2i(81,80),Vector2i(80,81),Vector2i(79,80)]:
		var job: Dictionary=source._job("build","Building","Build",0,point,16000);job.definition="wood_wall";job.work=1
	var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
	fast.in_tick=true;original.in_tick=true
	check.call("ASSIGN/step_aside_keeps_all_blocked_neighbor_behavior",not ColonyConstruction.step_aside(fast,fast.citizens[0]) and not full_step_aside(original,original.citizens[0]) and fast.canonical_hash()==original.canonical_hash())
	fast.citizens[0].progress=1;original.citizens[0].progress=1
	var before: String=fast.canonical_hash()
	check.call("ASSIGN/step_aside_never_retargets_an_in_progress_movement_edge",not ColonyConstruction.step_aside(fast,fast.citizens[0]) and not full_step_aside(original,original.citizens[0]) and fast.canonical_hash()==original.canonical_hash() and fast.canonical_hash()==before)

class StorageProbe extends ColonyWorld:
	var context_calls: int=0
	func _storage_context() -> Dictionary:
		context_calls+=1;return super()

class OriginalStorageProbe extends OriginalWorld:
	var context_calls: int=0
	func _storage_context() -> Dictionary:
		context_calls+=1;return super()

static func urgent_haul_contexts(check: Callable) -> void:
	for emergency in [false,true]:
		var source: ColonyWorld=ColonyTests.world();source.tick=1800 if emergency else 5400
		for person in source.citizens:
			person.fullness=1000;person.rest=1000
			for category in person.preferences: person.preferences[category]=3 if category=="Hauling" else 0
			person.x=80;person.y=80;person.edge_x=80;person.edge_y=80
		for store in source.stores: store.filters=[]
		var first: Dictionary=source._make_stack("fiber",1,"ground",0,Vector2i(80,80),true)
		var second: Dictionary=source._make_stack("fiber",1,"ground",0,Vector2i(82,80),true)
		var haul_a: Dictionary=source._job("haul","Hauling","",first.id,Vector2i(80,80),0);haul_a.source=first.id;haul_a.priority=3;haul_a.emergency=emergency
		var haul_b: Dictionary=source._job("haul","Hauling","",second.id,Vector2i(82,80),0);haul_b.source=second.id;haul_b.priority=3;haul_b.emergency=emergency
		var fast: StorageProbe=clone(source,false,StorageProbe.new(source.definitions))
		var original: OriginalStorageProbe=clone(source,true,OriginalStorageProbe.new(source.definitions))
		for world in [fast,original]: world.in_tick=true;world._assign(world.citizens[0])
		var name: String="emergency" if emergency else "before_leisure"
		check.call("ASSIGN/"+name+"_failed_hauls_share_one_exact_storage_context",fast.context_calls==1 and original.context_calls==2 and fast.canonical_hash()==original.canonical_hash(),str([fast.context_calls,original.context_calls]))
		check.call("ASSIGN/"+name+"_failed_probes_keep_atomic_inputs_and_conservation",fast.stacks.all(func(s:Dictionary)->bool:return s.reservations.is_empty()) and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
		for world in [fast,original]:
			world.stores[0].filters=["fiber"]
			for job in world.jobs:
				if job.kind=="haul": job.state="Ready";job.retry=0
			world._assign(world.citizens[1])
		check.call("ASSIGN/"+name+"_next_resident_rebuilds_context_after_new_capacity",fast.context_calls==2 and original.context_calls==3 and fast.canonical_hash()==original.canonical_hash() and fast.citizens[1].job==haul_a.id and fast.find(fast.stacks,first.id).reservations.get(haul_a.id)==1 and fast.invariant_errors().is_empty(),str([fast.context_calls,original.context_calls,fast.invariant_errors()]))
