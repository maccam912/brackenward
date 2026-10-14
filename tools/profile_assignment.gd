extends SceneTree
## Assignment breakdown with an ordinary complete-tick twin. Nested timings overlap.
const Campaign = preload("res://tools/profile_campaign.gd")
class AssignmentWorld extends Campaign.ProfileWorld:
	func note(label: String, started: int) -> void:
		var key: String="assignment/"+label
		timings[key]=timings.get(key,0)+Time.get_ticks_usec()-started
		counts[key]=counts.get(key,0)+1
	func _assignment_check(label: String, action: Callable) -> bool:
		var started: int=Time.get_ticks_usec();var result: bool=action.call();note(label,started);return result
	func _food(citizen: Dictionary, releasing: Dictionary = {}) -> Dictionary:
		if not assigning_work: return super(citizen,releasing)
		var started: int=Time.get_ticks_usec();var result: Dictionary=super(citizen,releasing);note("food",started);return result
	func _reserve(job: Dictionary, citizen: Dictionary, context: Dictionary = {}) -> bool:
		if not assigning_work: return super(job,citizen,context)
		var started: int=Time.get_ticks_usec();var result: bool=super(job,citizen,context);note("reserve/"+job.kind,started);return result
	func _storage_context() -> Dictionary:
		if not assigning_work: return super()
		var started: int=Time.get_ticks_usec();var result: Dictionary=super();note("storage_context",started);return result
	func _destination(item: String, quantity: int, from: Vector2i, tags: Array = [], context: Dictionary = {}) -> Dictionary:
		if not assigning_work: return super(item,quantity,from,tags,context)
		var started: int=Time.get_ticks_usec();var result: Dictionary=super(item,quantity,from,tags,context);note("destination",started);return result
	func unfinished_jobs() -> Array:
		if not assigning_work: return super()
		var started: int=Time.get_ticks_usec();var result: Array=super();note("unfinished_jobs",started);return result
	func _assign_search(citizen: Dictionary) -> void:
		work_budget.mark_dirty()
		if citizen.away: return
		if citizen.death_recorded or citizen.departed:
			citizen.activity = "Died" if citizen.death_recorded else "Departed"
			return
		if citizen.downed:
			citizen.activity = "Hearthside recovery" if citizen.hearthside_until > tick else ("Downed: bleeding, needs care" if not citizen.stabilized else "Downed: recovering")
			return
		if _assignment_check("escape",func()->bool:return ColonyDanger.escape(self,citizen)): return
		if _assignment_check("construction_step_aside",func()->bool:return ColonyConstruction.step_aside(self,citizen)): return
		if _assignment_check("charter_assign",func()->bool:return ColonyCharter.assign(self,citizen)): return
		# Query lists preserve job order and share the live dictionaries, so releases
		# and failed reservations below remain visible to subsequent queries.
		var open_jobs: Array = unfinished_jobs().filter(func(j:Dictionary)->bool:return j.state!="Queued")
		var arrivals: Array = open_jobs.filter(func(j:Dictionary)->bool:return j.kind=="arrival" and j.target==citizen.id)
		var arrival: Dictionary = {} if arrivals.is_empty() else arrivals[0]
		var preparing: bool = ColonyRegion.preparing(self,citizen)
		var food_threshold: int = 500 if preparing else 350
		var rest_threshold: int = 500 if preparing else 300
		var hour: int = ((tick % 7200) / 300 + (12 if citizen.shift == "Night shift" else 0)) % 24
		var needs_sleep: bool = citizen.rest <= rest_threshold or ((hour >= 22 or hour < 6) and citizen.rest < 900)
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
			var ordinary_needs: bool = not draft_ready and not current.emergency and (needs_food or (needs_sleep and current.kind not in ["eat","sleep"]))
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
		if needs_sleep and (citizen.fullness > 350 or citizen.rest <= 100):
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
			var destination: Dictionary = ColonyCare.destination(self,citizen)
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
				var urgent: Array = open_jobs.filter(func(j:Dictionary)->bool:return j.worker==0 and j.state not in ["Complete","Canceled"] and tick>=j.retry and citizen.preferences.get(j.category,0)>0 and _score(j,citizen)[0]==3)
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

func _initialize() -> void: call_deferred("run")
func clone(source: ColonyWorld, measured: bool) -> ColonyWorld:
	var result: ColonyWorld=AssignmentWorld.new(source.definitions) if measured else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	return result
func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>1200:
		printerr("Usage: -- SNAPSHOT TICKS (1..1200)");quit(2);return
	var snapshot_sha: String=FileAccess.get_sha256(args[0]);var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"): printerr(decoded);quit(2);return
	var original: ColonyWorld=clone(decoded.world,false);var measured: ColonyWorld=clone(decoded.world,true)
	var started: int=Time.get_ticks_usec()
	for index in range(int(args[1])): original.step()
	var baseline_us: int=Time.get_ticks_usec()-started;started=Time.get_ticks_usec()
	for index in range(int(args[1])): measured.step()
	var measured_us: int=Time.get_ticks_usec()-started
	var rows: Array=[]
	for phase in measured.timings: rows.append({"phase":phase,"calls":measured.counts[phase],"microseconds":measured.timings[phase]})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.microseconds>b.microseconds)
	var exact: bool=original.canonical_hash()==measured.canonical_hash() and measured.invariant_errors().is_empty() and snapshot_sha==FileAccess.get_sha256(args[0])
	print(JSON.stringify({"scope":"Headless assignment breakdown with ordinary complete-tick twin; nested phases overlap; not a frame/device gate","snapshot":args[0],"snapshot_sha256":snapshot_sha,"ticks":int(args[1]),"exact":exact,"baseline_us":baseline_us,"measured_us":measured_us,"canonical_hash":measured.canonical_hash(),"harness_sha256":FileAccess.get_sha256(get_script().resource_path),"phases":rows}))
	quit(0 if exact else 1)
