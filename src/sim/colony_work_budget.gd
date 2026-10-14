class_name ColonyWorkBudget
extends RefCounted
## Bounded executable work; queued records retain complete persistent intent.
const LIMIT: int = 512
const PERSONAL: Array = ["eat","sleep","leisure","recover","depart","escape","step_aside","shelter","defend","expedition_meet","expedition_walk","arrival","supper"]
const TERMINAL: Array = ["Complete","Canceled"]
const NEVER: int = 1<<62
var used: int = -1
var fingerprint: PackedInt64Array = PackedInt64Array()
var admitted_ids: Dictionary = {}
var runtime_dirty: bool = true
var runtime_source: Array = []
var runtime_count: int = -1
var runtime_tick: int = -1
var runtime_residents: PackedInt64Array = PackedInt64Array()
var next_review_tick: int = 0

func reset() -> void:
	used=-1;fingerprint.clear();admitted_ids.clear()
	runtime_dirty=true;runtime_source=[];runtime_count=-1;runtime_tick=-1;runtime_residents.clear();next_review_tick=0

func mark_dirty() -> void:
	runtime_dirty=true

static func resident_signature(citizens: Array) -> PackedInt64Array:
	var living: int = 0;var enabled: int = 0;var pins: Array[int] = []
	for person: Dictionary in citizens:
		if person.death_recorded or person.departed: continue
		living+=1
		if person.pinned_job>0 and not pins.has(person.pinned_job): pins.append(person.pinned_job)
		if person.away or person.downed: continue
		for index in range(ColonyWorld.CATEGORIES.size()):
			if person.preferences.get(ColonyWorld.CATEGORIES[index],0)>0: enabled|=1<<index
	pins.sort()
	var result: PackedInt64Array = PackedInt64Array([mini(20,living),enabled])
	for id in pins: result.append(id)
	return result

func reconcile_runtime(world: ColonyWorld) -> void:
	# Only complete-tick/assignment stages use this path. Their mutation hooks
	# invalidate order changes; the small resident signature and exact deadlines
	# cover eligibility changes without polling every unchanged waiting target.
	var residents: PackedInt64Array = resident_signature(world.citizens)
	var unchanged: bool = not runtime_dirty and is_same(runtime_source,world.jobs) and runtime_count==world.jobs.size() and runtime_residents==residents and world.tick>=runtime_tick and world.tick<next_review_tick
	runtime_tick=world.tick
	if unchanged: return
	reconcile(world)
	runtime_source=world.jobs;runtime_count=world.jobs.size();runtime_residents=residents;runtime_tick=world.tick;runtime_dirty=false

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
	if had_commands: mark_dirty();reconcile_runtime(world)

func reconcile(world: ColonyWorld) -> void:
	# Explicit callers retain full live-record inspection, including fixtures
	# that deliberately edit dictionaries outside the simulation mutation API.
	mark_dirty()
	var jobs: Array = world.unfinished_jobs();var pinned: Dictionary = {}
	next_review_tick=NEVER
	var tick: int = world.tick
	var enabled: Dictionary = enabled_categories(world.citizens)
	for person in world.citizens:
		if person.pinned_job>0 and not person.death_recorded and not person.departed: pinned[person.pinned_job]=true
	# Admission depends on these bounded integer terms, not position, progress,
	# quantities or presentation. Comparing the native packed vector avoids
	# re-sorting every queued order on ticks where admission cannot change.
	var signature: PackedInt64Array = PackedInt64Array()
	signature.resize(jobs.size()+1);signature[0]=ordinary_limit(world.citizens)
	var inconsistent: bool = false
	var cursor: int = 1
	for job: Dictionary in jobs:
		var id: int = job.id;var worker: int = job.worker;var state: String = job.state;var retry: int = job.retry
		var is_pinned: bool = pinned.has(id)
		var code: int = int(worker>0)+2*int(job.kind=="supper_reserve" or (worker>0 and job.kind in PERSONAL))
		# A released Ready order can become Queued during this inspection, so
		# retain its future retry even when it is currently eligible.
		if code==0 and retry>tick: next_review_tick=mini(next_review_tick,retry)
		var eligible: bool = not (retry>tick and (state=="Blocked" or state=="Queued") and not is_pinned)
		if not eligible: code+=4
		if code==0:
			var category: String = job.category;var priority: int = job.priority;var created: int = job.created
			var waited_days: int = (tick-created)/7200
			var aged: int = mini(3,priority+waited_days)
			if aged<3: next_review_tick=mini(next_review_tick,created+(waited_days+1)*7200)
			code=8*int(job.emergency)+16*int(is_pinned)+32*aged+128*int(category=="" or enabled.has(category))
			if admitted_ids.has(id)!=(state!="Queued"): inconsistent=true
		signature[cursor]=id*256+code;cursor+=1
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
