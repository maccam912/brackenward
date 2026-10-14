class_name ColonyWorkBudget
extends RefCounted
## Bounded executable work; queued records retain complete persistent intent.
const LIMIT: int = 512
const PERSONAL: Array = ["eat","sleep","leisure","recover","depart","escape","step_aside","shelter","defend","expedition_meet","expedition_walk","arrival","supper"]
const TERMINAL: Array = ["Complete","Canceled"]
var used: int = -1
var fingerprint: PackedInt64Array = PackedInt64Array()
var admitted_ids: Dictionary = {}

func reset() -> void:
	used=-1;fingerprint.clear();admitted_ids.clear()

func initial_state(world: ColonyWorld, kind: String) -> String:
	# One slot per living resident and one communal-supper bank cannot be
	# exhausted by ordinary orders. Their factories assign ownership atomically.
	if kind in PERSONAL or kind=="supper_reserve": return "Ready"
	if used<0:
		var open: Array = world.unfinished_jobs()
		used=0
		for job in open:
			if not protected(job) and job.state!="Queued": used+=1
	if used<ordinary_limit(world.citizens): used+=1;return "Ready"
	return "Queued"

func after_commands(world: ColonyWorld, had_commands: bool) -> void:
	# The previous complete tick already reconciled unchanged orders. Retry/age
	# changes are reconciled before assignment and at this tick's complete state.
	if had_commands: reconcile(world)

func reconcile(world: ColonyWorld) -> void:
	var jobs: Array = world.unfinished_jobs();var pinned: Dictionary = {}
	var enabled: Dictionary = enabled_categories(world.citizens)
	for person in world.citizens:
		if person.pinned_job>0 and not person.death_recorded and not person.departed: pinned[person.pinned_job]=true
	# Admission depends on these bounded integer terms, not position, progress,
	# quantities or presentation. Comparing the native packed vector avoids
	# re-sorting every queued order on ticks where admission cannot change.
	var signature: PackedInt64Array = PackedInt64Array([ordinary_limit(world.citizens)])
	var inconsistent: bool = false
	for job in jobs:
		var code: int = int(job.worker>0)+2*int(protected(job))
		var eligible: bool = not (job.retry>world.tick and job.state in ["Blocked","Queued"] and not pinned.has(job.id))
		if not eligible: code+=4
		if code==0:
			code=8*int(job.emergency)+16*int(pinned.has(job.id))+32*mini(3,job.priority+(world.tick-job.created)/7200)+128*int(job.category=="" or enabled.has(job.category))
			if admitted_ids.has(job.id)!=(job.state!="Queued"): inconsistent=true
		signature.append(job.id*256+code)
	if not inconsistent and signature==fingerprint: return
	var result: Dictionary = reconcile_records(world.citizens,jobs,world.tick,true)
	used=result.used;admitted_ids=result.admitted;fingerprint=signature

static func ordinary_limit(citizens: Array) -> int:
	var living: int = citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed).size()
	return LIMIT-mini(20,living)-1

static func enabled_categories(citizens: Array) -> Dictionary:
	var enabled: Dictionary = {}
	for person in citizens:
		if person.death_recorded or person.departed or person.away or person.downed: continue
		for category in person.preferences:
			if person.preferences[category]>0: enabled[category]=true
	return enabled

static func protected(job: Dictionary) -> bool:
	return job.kind=="supper_reserve" or (job.worker>0 and job.kind in PERSONAL)

static func executable(job: Dictionary, tick: int) -> bool:
	return job.state not in TERMINAL and job.state!="Queued" and (job.worker>0 or job.state!="Blocked" or job.retry<=tick)

static func reconcile_records(citizens: Array, jobs: Array, tick: int, precompute_keys: bool = false) -> Dictionary:
	var candidates: Array = [];var occupied: int = 0;var pinned: Dictionary = {}
	var enabled: Dictionary = enabled_categories(citizens)
	for person in citizens:
		if person.pinned_job>0 and not person.death_recorded and not person.departed: pinned[person.pinned_job]=true
	for job in jobs:
		if job.state in TERMINAL or protected(job): continue
		if job.worker>0: occupied+=1;continue
		if job.retry>tick and job.state in ["Blocked","Queued"] and not pinned.has(job.id): continue
		candidates.append(job)
	var available: int = maxi(0,ordinary_limit(citizens)-occupied)
	if candidates.size()>available:
		if precompute_keys:
			var keys: Dictionary = {}
			for job in candidates:
				# Valid age/priority occupies two bits; ID is validated below 1e9.
				var rank: int = 16*int(job.emergency)+8*int(pinned.has(job.id))+4*int(job.category=="" or enabled.has(job.category))+mini(3,job.priority+(tick-job.created)/7200)
				keys[job.id]=Vector2i(rank,-job.id)
			candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
				var aa: Vector2i = keys[a.id];var bb: Vector2i = keys[b.id]
				return aa.x>bb.x if aa.x!=bb.x else aa.y>bb.y)
		else:
			# Retain the explicit tuple comparator as an independent reference
			# for migration and runtime-cache/order regression comparisons.
			candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
				if a.emergency!=b.emergency: return a.emergency
				if pinned.has(a.id)!=pinned.has(b.id): return pinned.has(a.id)
				var ae: bool = a.category=="" or enabled.has(a.category);var be: bool = b.category=="" or enabled.has(b.category)
				if ae!=be: return ae
				var aa: int = mini(3,a.priority+(tick-a.created)/7200);var bb: int = mini(3,b.priority+(tick-b.created)/7200)
				return aa>bb if aa!=bb else a.id<b.id)
	var selected_ids: Dictionary = {}
	for index in range(candidates.size()):
		var job: Dictionary = candidates[index]
		if index<available:
			selected_ids[job.id]=true
			if job.state=="Queued": job.state=job.queue_state;job.queue_state=""
		elif job.state!="Queued": job.queue_state=job.state;job.state="Queued"
	return {"admitted":selected_ids,"used":occupied+mini(available,candidates.size())}

static func migrate(data: Dictionary) -> void:
	# Validate the fields used by this pure repair before inspecting legacy data.
	# Full codec validation still follows; malformed records remain rejected.
	if not data.get("citizens") is Array or not data.get("jobs") is Array or not data.get("tick") is int: return
	for person in data.citizens:
		if not person is Dictionary or not person.get("death_recorded") is bool or not person.get("departed") is bool or not person.get("pinned_job") is int: return
		if not person.get("away") is bool or not person.get("downed") is bool or not person.get("preferences") is Dictionary or not person.preferences.values().all(func(value:Variant)->bool:return value is int): return
	for job in data.jobs:
		if not job is Dictionary or not job.get("state") is String or not job.get("kind") is String or not job.get("category") is String or not job.get("emergency") is bool: return
		for field in ["worker","retry","id","priority","created"]:
			if not job.get(field) is int: return
	reconcile_records(data.citizens,data.jobs,data.tick)
