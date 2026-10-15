extends SceneTree
## Ordinary-play scenario runner. Policy only observes state and queues commands.
## --resume uses a prior report plus its verified final snapshot; --days is additional time.
var options: Dictionary = {"scenario":"", "seed":"104729", "site":"meadow_reach", "mode":"Standard", "days":"8", "report":"reports/simulation.json", "resume":""}
var failure: String = ""

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()%2!=0: _usage();return
	var seen: Array = []
	for index in range(0,args.size(),2):
		var flag: String = args[index].trim_prefix("--")
		if not args[index].begins_with("--") or not options.has(flag) or seen.has(flag): _usage();return
		seen.append(flag);options[flag]=args[index+1]
	if options.scenario not in ["first_week","first_winter","vegetarian_charter","twenty_colony"] or not options.seed.is_valid_int() or int(options.seed)<0 or int(options.seed)>4294967295 or not options.days.is_valid_int() or int(options.days)<1 or int(options.days)>128 or not ColonyGeneration.SITES.has(options.site) or options.mode not in ["Standard","Hearthside"] or options.report.is_empty() or options.report==options.resume: _usage();return
	call_deferred("run")

func _usage() -> void:
	printerr("Usage: -- --scenario first_week|first_winter|vegetarian_charter|twenty_colony --seed UINT32 --site meadow_reach|pine_shelf|reed_bend --mode Standard|Hearthside --days 1..128 --report PATH [--resume PREVIOUS_REPORT]")
	quit(2)

func run() -> void:
	var started: int = Time.get_ticks_msec()
	var world: ColonyWorld = ColonyTests.world()
	var error: String = ColonyGeneration.configure(world,int(options.seed),options.site)
	if not error.is_empty(): printerr(error);quit(2);return
	var previous: Dictionary = {}
	var policy: ColonyPolicy = LargeColonyPolicy.new() if options.scenario=="twenty_colony" else ColonyPolicy.new(options.scenario)
	var initial: PackedByteArray
	if not options.resume.is_empty():
		var parsed: Variant = ColonyState.unpack(JSON.parse_string(FileAccess.get_file_as_string(options.resume)))
		if not parsed is Dictionary or not parsed.get("ordinary_play_only",false): printerr("Resume needs an ordinary-play report");quit(2);return
		previous=parsed
		var saved_bytes: PackedByteArray = FileAccess.get_file_as_bytes(options.resume.get_basename()+"-final.brackenward")
		var decoded: Dictionary = ColonyCodec.decode(saved_bytes)
		if not decoded.has("world"): printerr(decoded);quit(2);return
		world=decoded.world
		var original_envelope: Dictionary = JSON.parse_string(saved_bytes.get_string_from_utf8())
		if original_envelope.get("sha256")!=previous.get("canonical_hash") or world.seed!=int(options.seed) or world.site_id!=options.site or previous.get("mode")!=options.mode or world.tick!=previous.get("end_tick"):
			printerr("Resume snapshot/report hash, site, seed, mode or tick mismatch");quit(2);return
		initial=FileAccess.get_file_as_bytes(options.resume.get_basename()+"-initial.brackenward")
		if initial.is_empty(): printerr("Resume original starting snapshot missing");quit(2);return
		world.command_trace.assign(previous.commands)
		policy.resume(world,previous.policy_decisions)
		print("Resuming verified ordinary-play snapshot at tick %d; source canonical %s; migrated canonical %s" % [world.tick,previous.canonical_hash,world.canonical_hash()])
	else:
		if options.mode=="Hearthside": world.queue_command("care_mode",{"mode":"Hearthside"})
		initial=ColonyCodec.encode(world)
	var large_metrics: Dictionary=LargeColonyScenario.initial(previous.get("large_colony",{}))
	var run_beginning: int = world.tick
	var end: int = run_beginning+int(options.days)*7200
	var metrics: Dictionary = {"start_tick":previous.get("start_tick",world.tick),"initial_structure_ids":previous.get("initial_structure_ids",world.structures.map(func(s:Dictionary)->int:return s.id)),"prior_improvements":previous.get("prior_improvements",0),"elapsed_ms":previous.get("elapsed_ms",0),"samples":previous.get("samples",[]),"minimum_health":previous.get("minimum_health",100),"zero_fullness_ticks":previous.get("zero_fullness_ticks",0),"starvation_grace_exceeded_ticks":previous.get("starvation_grace_exceeded_ticks",0),"first_week":previous.get("first_week",{}),"invariant_checks":previous.get("invariant_checks",0),"source_reports":previous.get("source_reports",[])}
	if not previous.is_empty():
		metrics.source_reports.append({"path":options.resume,"canonical_hash":previous.canonical_hash,"end_tick":previous.end_tick})
		if not previous.has("initial_structure_ids"): metrics.prior_improvements=previous.completed_improvements
	if options.scenario=="twenty_colony": metrics.large_colony=large_metrics
	policy.plan(world)
	while world.tick<end:
		world.step()
		if options.scenario=="twenty_colony": LargeColonyScenario.observe(world,large_metrics)
		for person in world.citizens:
			if person.death_recorded or person.departed: continue
			metrics.minimum_health=mini(metrics.minimum_health,person.health)
			if person.fullness==0: metrics.zero_fullness_ticks+=1
			if person.starving_ticks>1800: metrics.starvation_grace_exceeded_ticks+=1
		if world.tick%300==0:
			metrics.invariant_checks+=1
			var invariants: Array[String] = world.invariant_errors()
			if not invariants.is_empty(): failure="Invariant failure: "+str(invariants);break
			policy.plan(world)
		if world.tick%7200==0:
			var daily: Dictionary = sample(world)
			metrics.samples.append(daily)
			print("Day %d: %d residents, %s, %d research, %d charter stages; pressure %d" % [daily.day,daily.living,daily.food.label,world.researched.size(),world.charter_state.completed.size(),daily.pressure])
			if world.tick==8*7200: metrics.first_week=daily.duplicate(true)
			var checkpoint: Dictionary = report(world,policy,metrics,started)
			checkpoint.checkpoint=true;checkpoint.scenario_pass=false
			if not save_report(options.report.get_basename()+"-latest.json",checkpoint,initial,world): quit(2);return
		if world.care_state.ended:
			failure="Settlement ended through ordinary simulation; inspect recorded warnings, causes and policy decisions";break
	var result: Dictionary = report(world,policy,metrics,started)
	var scenario_pass: bool = failure.is_empty()
	if options.scenario=="first_week": scenario_pass=scenario_pass and world.tick-metrics.start_tick>=57600 and metrics.starvation_grace_exceeded_ticks==0 and result.completed_improvements>=3 and FoodForecast.calculate(world).ticks>=7200 and world.citizens.all(func(c:Dictionary)->bool:return not c.departed and not c.death_recorded)
	elif options.scenario=="first_winter": scenario_pass=scenario_pass and world.tick>=32*7200 and metrics.starvation_grace_exceeded_ticks==0 and world.citizens.filter(func(c:Dictionary)->bool:return not c.departed and not c.death_recorded).size()>=8 and not world.citizens.any(func(c:Dictionary)->bool:return c.departed)
	elif options.scenario=="twenty_colony": scenario_pass=scenario_pass and LargeColonyScenario.passes(world,large_metrics,metrics.starvation_grace_exceeded_ticks)
	else: scenario_pass=scenario_pass and world.charter_state.ending and not world.researched.has("husbandry") and world.ledger.consumed.get("meat",0)==0 and world.ledger.consumed.get("leather",0)==0
	result.scenario_pass=scenario_pass
	if not scenario_pass and failure.is_empty(): result.invariant_failure="Policy did not meet the stated scenario goals; this is not automatically a simulation defect"
	if not save_report(options.report,result,initial,world): quit(2);return
	print("Scenario %s: %s; %d ticks in %d ms; report %s" % [options.scenario,"PASS" if scenario_pass else "FAILED POLICY OR INVARIANT",world.tick-metrics.start_tick,result.elapsed_ms,options.report])
	quit(0 if scenario_pass else 1)

func report(world: ColonyWorld, policy: ColonyPolicy, metrics: Dictionary, started: int) -> Dictionary:
	var result: Dictionary = metrics.duplicate(true)
	result.merge({"scenario":options.scenario,"seed":world.seed,"site":world.site_id,"mode":options.mode,"requested_days":int(options.days),"end_tick":world.tick,"ticks_run":world.tick-metrics.start_tick,"elapsed_ms":metrics.elapsed_ms+Time.get_ticks_msec()-started,"engine":Engine.get_version_info().string,"content_hash":world.definitions.content_hash,"generator_version":world.generator_version,"canonical_hash":world.canonical_hash(),"invariant_failure":failure,"completed_improvements":metrics.prior_improvements+world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and not metrics.initial_structure_ids.has(s.id)).size(),"final":sample(world),"ledger":world.ledger,"researched":world.researched,"charter":world.charter_state,"director_history":world.director_state.history,"facts":world.facts,"commands":world.command_trace,"policy_decisions":policy.decisions,"ordinary_play_only":true,"certification":"Scenario evidence only; physical devices and human comprehension remain separate"},true)
	return result

func save_report(path: String, data: Dictionary, initial: PackedByteArray, world: ColonyWorld) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var snapshot: PackedByteArray = ColonyCodec.encode(world)
	var decoded: Dictionary = ColonyCodec.decode(snapshot)
	var verified: bool = decoded.has("world") and decoded.world.canonical_hash()==data.canonical_hash
	data.roundtrip_verified=verified
	if not verified:
		data.roundtrip_error=str(decoded.get("error","canonical hash mismatch"))
		printerr("Scenario snapshot failed verified round trip: "+data.roundtrip_error)
	for output in [path.get_basename()+"-initial.brackenward",path.get_basename()+"-final.brackenward",path]:
		var file: FileAccess = FileAccess.open(output,FileAccess.WRITE)
		if file==null: printerr("Unable to write scenario report/snapshot: "+output);return false
		if output.ends_with("-initial.brackenward"): file.store_buffer(initial)
		elif output.ends_with("-final.brackenward"): file.store_buffer(snapshot)
		else: file.store_string(JSON.stringify(ColonyState.pack(data),"\t",true))
		file.close()
	return verified

func sample(world: ColonyWorld) -> Dictionary:
	return {"tick":world.tick,"day":world.tick/7200+1,"living":world.citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed).size(),"food":FoodForecast.calculate(world),"pressure":ColonyDirector.pressure(world).score,"citizens":world.citizens.map(func(c:Dictionary)->Dictionary:return {"id":c.id,"health":c.health,"fullness":c.fullness,"rest":c.rest,"morale":c.morale,"departed":c.departed,"activity":c.activity}),"stock":{"meal":world.available("meal"),"vegetable":world.available("vegetable"),"grain":world.available("grain"),"mushroom":world.available("mushroom"),"wood":world.available("wood")},"fields":world.fields.size(),"researched":world.researched.duplicate(),"charter_stages":world.charter_state.completed.duplicate(),"major_incidents":world.director_state.history.size(),"jobs":world.jobs.size(),"active_jobs":world.jobs.filter(func(j:Dictionary)->bool:return j.state not in ["Complete","Canceled"]).size(),"stacks":world.stacks.size(),"nonempty_stacks":world.stacks.filter(func(s:Dictionary)->bool:return s.count>0).size(),"chronicle_facts":world.chronicle_state.facts.size(),"canonical_hash":world.canonical_hash()}
