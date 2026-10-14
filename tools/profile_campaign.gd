extends SceneTree
## Read-only snapshot profiling; instrumented ticks must match the normal simulator.
class ProfileWorld extends ColonyWorld:
	var timings: Dictionary = {}
	var counts: Dictionary = {}
	func _init(catalog: Dictionary) -> void:
		super(catalog)
	func _profile(label: String, action: Callable) -> void:
		var start: int = Time.get_ticks_usec()
		action.call()
		timings[label]=timings.get(label,0)+Time.get_ticks_usec()-start
		counts[label]=counts.get(label,0)+1
	func step() -> void:
		if care_state.ended: return
		in_tick=true;work_commits.clear()
		citizens.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.id<b.id)
		tick += 1
		path_requests = 0
		var had_commands: bool = not pending_commands.is_empty()
		pending_commands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
		for command in pending_commands:
			if not receipts.has(command.id):
				receipts[command.id] = _command(command) if command.session == session_id else "wrong_session"
				command_trace.append({"tick": tick, "command": command.duplicate(true)})
		pending_commands.clear()
		_profile("work_budget",func()->void:work_budget.after_commands(self,had_commands))
		_profile("ColonyDefense.advance",func()->void:ColonyDefense.advance(self))
		_profile("ColonyCare.advance",func()->void:ColonyCare.advance(self))
		_profile("ColonyWeather.advance",func()->void:ColonyWeather.advance(self))
		_profile("ColonyAgriculture.advance",func()->void:ColonyAgriculture.advance(self))
		_profile("ColonyRegion.advance",func()->void:ColonyRegion.advance(self))
		_profile("ColonyTrade.advance",func()->void:ColonyTrade.advance(self))
		_profile("ColonyPopulation.advance",func()->void:ColonyPopulation.advance(self))
		_profile("ColonyDomestic.advance",func()->void:ColonyDomestic.advance(self))
		_profile("ColonyWildlife.advance",func()->void:ColonyWildlife.advance(self))
		_profile("ColonyNature.advance",func()->void:ColonyNature.advance(self))
		_profile("ColonySocial.advance",func()->void:ColonySocial.advance(self))
		_profile("ColonyLiving.advance",func()->void:ColonyLiving.advance(self))
		for citizen in citizens:
			_profile("_needs",func()->void:_needs(citizen))
		_profile("ColonyCharter.begin_tick",func()->void:ColonyCharter.begin_tick(self))
		_profile("ColonyDirector.advance",func()->void:ColonyDirector.advance(self))
		if tick % 10 == 0:
			_profile("_create_work",func()->void:_create_work())
			_profile("ColonyProduction.create_jobs",func()->void:ColonyProduction.create_jobs(self))
			_profile("ColonyAgriculture.create_jobs",func()->void:ColonyAgriculture.create_jobs(self))
			_profile("ColonyFire.create_jobs",func()->void:ColonyFire.create_jobs(self))
			_profile("ColonyCare.create_jobs",func()->void:ColonyCare.create_jobs(self))
			_profile("ColonyNature.create_jobs",func()->void:ColonyNature.create_jobs(self))
			_profile("ColonyDomestic.create_jobs",func()->void:ColonyDomestic.create_jobs(self))
			_profile("ColonyConstruction.create_helpers",func()->void:ColonyConstruction.create_helpers(self))
			_profile("ColonyEquipment.create_jobs",func()->void:ColonyEquipment.create_jobs(self))
			_profile("work_budget",func()->void:work_budget.reconcile(self))
			for citizen in citizens:
				_profile("_assign",func()->void:_assign(citizen))
		for citizen in citizens:
			if citizen.job > 0:
				_profile("_work",func()->void:_work(citizen, find(jobs, citizen.job)))
		_profile("ColonyCombat.resolve",func()->void:ColonyCombat.resolve(self))
		committing_work=true
		for transaction in work_commits:
			var job: Dictionary = find(jobs,transaction.job);var worker: Dictionary = find(citizens,transaction.worker)
			if job.is_empty() or worker.is_empty() or job.worker!=worker.id or worker.job!=job.id or worker.downed or worker.death_recorded or worker.departed: continue
			if transaction.kind=="finish": _finish(worker,job)
			elif transaction.kind=="water": ColonyFire.water_ready(self,worker,job)
			elif transaction.kind=="move_phase": ColonyMaintenance.finish_dismantle(self,worker,job)
		_profile("ColonyOpportunities.advance",func()->void:ColonyOpportunities.advance(self))
		_profile("ColonyCharter.advance",func()->void:ColonyCharter.advance(self))
		_profile("ColonyChronicle.advance",func()->void:ColonyChronicle.advance(self))
		_profile("work_budget",func()->void:work_budget.reconcile(self))
		committing_work=false;in_tick=false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()!=2 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>7200:
		printerr("Usage: -- SNAPSHOT TICKS (1..7200)");quit(2);return
	var decoded: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"): printerr(decoded);quit(2);return
	var baseline: ColonyWorld = decoded.world
	var instrumented: ProfileWorld = ProfileWorld.new(baseline.definitions)
	for field in baseline.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant = baseline.get(field)
		if value is Array: instrumented.get(field).assign(value.duplicate(true))
		elif value is Dictionary: instrumented.set(field,value.duplicate(true))
		else: instrumented.set(field,value)
	var before: Dictionary = inventory(baseline)
	var start_hash: String = baseline.canonical_hash()
	var start: int = Time.get_ticks_usec()
	for index in range(int(args[1])): baseline.step()
	var baseline_us: int = Time.get_ticks_usec()-start
	start=Time.get_ticks_usec()
	for index in range(int(args[1])): instrumented.step()
	var profiled_us: int = Time.get_ticks_usec()-start
	var matching: bool = baseline.canonical_hash()==instrumented.canonical_hash()
	var ranked: Array = instrumented.timings.keys()
	ranked.sort_custom(func(a:String,b:String)->bool:return instrumented.timings[a]>instrumented.timings[b])
	var phases: Array = []
	for phase in ranked: phases.append({"phase":phase,"microseconds":instrumented.timings[phase],"calls":instrumented.counts[phase]})
	print(JSON.stringify({"snapshot":args[0],"ticks":int(args[1]),"baseline_us":baseline_us,"profiled_us":profiled_us,"canonical_match":matching,"start_hash":start_hash,"canonical_hash":baseline.canonical_hash(),"before":before,"after":inventory(baseline),"phases":phases},"\t",true))
	quit(0 if matching else 1)

func inventory(world: ColonyWorld) -> Dictionary:
	return {"tick":world.tick,"jobs":world.jobs.size(),"active_jobs":world.jobs.filter(func(j:Dictionary)->bool:return j.state not in ["Complete","Canceled"]).size(),"stacks":world.stacks.size(),"nonempty_stacks":world.stacks.filter(func(s:Dictionary)->bool:return s.count>0).size(),"facts":world.facts.size(),"chronicle_facts":world.chronicle_state.facts.size(),"fields":world.fields.size(),"structures":world.structures.size(),"citizens":world.citizens.size()}
