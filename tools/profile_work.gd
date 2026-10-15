extends SceneTree
## Read-only input diagnosis; complete instrumented ticks must match the normal twin.
const Campaign = preload("res://tools/profile_campaign.gd")
class WorkWorld extends Campaign.ProfileWorld:
	func note(label: String, started: int) -> void:
		var key: String="work/"+label
		timings[key]=timings.get(key,0)+Time.get_ticks_usec()-started
		counts[key]=counts.get(key,0)+1
	func _work(citizen: Dictionary, job: Dictionary) -> void:
		var key: String=str(job.get("kind","none"))+"/"+str(job.get("state","none"))
		var started: int=Time.get_ticks_usec();super(citizen,job);note(key,started)
	func _walk(citizen: Dictionary, goal: Vector2i) -> bool:
		var started: int=Time.get_ticks_usec();var result: bool=super(citizen,goal);note("walk",started);return result
	func _rate(citizen: Dictionary, job: Dictionary) -> int:
		var started: int=Time.get_ticks_usec();var result: int=super(citizen,job);note("rate",started);return result
	func _finish(citizen: Dictionary, job: Dictionary) -> void:
		var started: int=Time.get_ticks_usec();super(citizen,job);note("finish",started)
	func _release(job: Dictionary, cancel: bool) -> void:
		var started: int=Time.get_ticks_usec();super(job,cancel);note("release",started)
	func _escrow_count(job_id: int, item: String) -> int:
		var started: int=Time.get_ticks_usec();var result: int=super(job_id,item);note("escrow_count",started);return result

func _initialize() -> void: call_deferred("run")
func clone(source: ColonyWorld, measured: bool) -> ColonyWorld:
	var result: ColonyWorld=WorkWorld.new(source.definitions) if measured else ColonyWorld.new(source.definitions)
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
	print(JSON.stringify({"scope":"Headless work breakdown with ordinary complete-tick twin; nested phases overlap; not a frame/device gate","snapshot":args[0],"snapshot_sha256":snapshot_sha,"ticks":int(args[1]),"exact":exact,"baseline_us":baseline_us,"measured_us":measured_us,"canonical_hash":measured.canonical_hash(),"harness_sha256":FileAccess.get_sha256(get_script().resource_path),"phases":rows}))
	quit(0 if exact else 1)
