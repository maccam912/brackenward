class_name AssignmentViewReference
extends ColonyWorld
## Complete f887763 assignment-search oracle, retaining its callback filter.
## Updated for v10 needs rules; the older query strategy remains independent.
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
	if ColonyConstruction.step_aside(self,citizen): return
	if ColonyCharter.assign(self,citizen): return
	# Query lists preserve job order and share the live dictionaries, so releases
	# and failed reservations below remain visible to subsequent queries.
	var open_jobs: Array = (_work_jobs() if in_tick else unfinished_jobs()).filter(func(j:Dictionary)->bool:return j.state not in ["Complete","Canceled","Queued"])
	var preparing: bool = ColonyRegion.preparing(self,citizen)
	var food_threshold: int = 500 if preparing else 350
	var needs_sleep: bool = ColonyRest.wants_sleep(citizen,tick,preparing)
	var hour: int = ((tick % 7200) / 300 + (12 if citizen.shift == "Night shift" else 0)) % 24
	# Release for sleep only when the same search can actually start sleeping.
	var sleep_eligible: bool = needs_sleep
	var current: Dictionary = find(jobs, citizen.job)
	# Recover an old collapse sleep in place as soon as an assigned bed exists.
	# An explicitly unreachable bed keeps its explained safe-ground fallback.
	if current.get("kind")=="sleep" and current.target==0 and (current.reason.is_empty() or current.reason.begins_with("Exhausted:")):
		var assigned_bed: Dictionary=find(structures,citizen.bed)
		if not assigned_bed.is_empty() and assigned_bed.health>0 and ColonyDanger.safe(self,Vector2i(assigned_bed.x,assigned_bed.y)):
			current.target=assigned_bed.id;current.x=assigned_bed.x;current.y=assigned_bed.y
			current.work_x=assigned_bed.x;current.work_y=assigned_bed.y;current.state="Moving"
			citizen.route.clear();citizen.route_goal.clear()
	var hunger_food: Dictionary = {};var hunger_food_checked: bool = false
	var food_work_only: bool = citizen.fullness<=food_threshold
	# A hungry cook/forager may finish making food while above critical rest.
	# Unrelated work never postpones sleep just because the food stores are empty.
	var food_work_available: bool = food_work_only and open_jobs.any(func(j:Dictionary)->bool:return (j.worker==0 or j.worker==citizen.id) and tick>=j.retry and citizen.preferences.get(j.category,0)>0 and _food_supply_work(j))
	if food_work_available and citizen.rest>100: sleep_eligible=false
	var taking_break: bool = citizen.break_until > tick
	var draft_ready: bool = citizen.drafted and not taking_break and citizen.fullness > 0 and citizen.rest > 100 and (citizen.health > 40 or citizen.stand_fast)
	var treatment_wait: bool = not draft_ready and citizen.fullness > 0 and citizen.rest > 100 and open_jobs.any(func(j:Dictionary)->bool:return j.kind == "treat" and j.target == citizen.id and j.state not in ["Complete","Canceled"])
	if treatment_wait and current.get("kind") not in ["eat","sleep"]:
		_release(current,false)
		citizen.activity = "Resting for treatment"
		return
	if not current.is_empty():
		var emergency: bool = citizen.health > 20 and citizen.break_until <= tick and citizen.fullness > 0 and citizen.rest > 100 and open_jobs.any(func(j:Dictionary)->bool:return j.emergency and j.worker == 0 and j.state not in ["Complete","Canceled"] and tick >= j.retry)
		var ordinary_food: bool = not draft_ready and not current.emergency and citizen.fullness<=food_threshold and current.kind!="eat" and (current.kind!="sleep" or citizen.rest>=ColonyRest.TIRED)
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
		var seek_food_work: bool = food_work_only and hunger_food.is_empty() and current.kind not in PERSONAL_JOBS and not _food_supply_work(current)
		var hungry_sleeper: bool = current.kind=="sleep" and food_work_available and citizen.rest>=ColonyRest.TIRED
		var ordinary_needs: bool = not draft_ready and not current.emergency and (needs_food or seek_food_work or hungry_sleeper or (sleep_eligible and current.kind not in ["eat","sleep"]))
		var break_interrupt: bool = taking_break and current.kind not in ["eat","sleep","leisure","recover"]
		if urgent_self_care or break_interrupt or (emergency and not current.emergency) or change_to_defense or ordinary_needs:
			_release(current, false)
		else:
			return
	if citizen.health > 20 and citizen.fullness > 0 and citizen.rest > 100 and citizen.break_until <= tick:
		var emergencies: Array = open_jobs.filter(func(j:Dictionary)->bool:return j.emergency and j.worker == 0 and j.state not in ["Complete","Canceled"] and tick >= j.retry)
		_sort_jobs(emergencies,citizen)
		var emergency_storage: Dictionary={}
		for emergency in emergencies:
			hunger_food_checked=false
			if emergency.kind!="haul": emergency_storage.clear()
			elif emergency_storage.is_empty(): emergency_storage=_storage_context()
			if _reserve(emergency,citizen,emergency_storage): citizen.job = emergency.id; return
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
		if not bed.is_empty() and (bed.health<=0 or not ColonyDanger.safe(self,Vector2i(bed.x,bed.y))): bed={}
		var point: Vector2i = Vector2i(citizen.x, citizen.y) if bed.is_empty() else Vector2i(bed.x, bed.y)
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
	var arrival: Dictionary = {}
	for job in open_jobs:
		if job.kind=="arrival" and job.target==citizen.id: arrival=job;break
	if not arrival.is_empty() and _reserve(arrival,citizen):
		citizen.job=arrival.id
		return
	if not taking_break and citizen.departure_until > 0 and tick >= citizen.departure_until:
		var depart_job: Dictionary = _job("depart", "", "", citizen.id, Vector2i(66,127), 0)
		depart_job.worker = citizen.id
		depart_job.state = "Moving"
		citizen.job = depart_job.id
		return
	if citizen.break_until > tick or (not food_work_only and hour >= 18 and hour < 20 and citizen.leisure_ticks < 600):
		if not taking_break:
			var urgent: Array = open_jobs.filter(func(j:Dictionary)->bool:return j.worker==0 and j.state not in ["Complete","Canceled"] and tick>=j.retry and citizen.preferences.get(j.category,0)>0 and not _hauling_fallback(j,citizen) and _task_priority(j)==3)
			_sort_jobs(urgent,citizen)
			var urgent_storage: Dictionary={}
			for job in urgent:
				if job.kind!="haul": urgent_storage.clear()
				elif urgent_storage.is_empty(): urgent_storage=_storage_context()
				if _reserve(job,citizen,urgent_storage): citizen.job=job.id;return
		var leisure: Dictionary = _job("leisure", "", "", citizen.id, ColonySocial.leisure_seat(self,citizen), 0)
		leisure.state = "Moving"
		leisure.worker = citizen.id
		citizen.job = leisure.id
		return
	if citizen.pinned_job > 0 and not food_work_only:
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
		if food_work_only and not _food_supply_work(job): continue
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
	else:
		citizen.activity = "Hungry: gather berries or mushrooms and enable Cooking"

func _food_supply_work(job: Dictionary) -> bool:
	if job.kind in ["cook","harvest","fish","butcher","collect_animal","slaughter"]: return true
	if job.kind=="gather":
		var resource: Dictionary=find(resources,job.target)
		return not resource.is_empty() and definitions.items[definitions.resources[resource.definition].item].fullness>0
	if job.kind=="craft": return job.output.keys().any(func(item:String)->bool:return definitions.items[item].fullness>0)
	if job.kind=="haul":
		var source: Dictionary=find(stacks,job.source)
		return not source.is_empty() and definitions.items[source.item].fullness>0
	return false
