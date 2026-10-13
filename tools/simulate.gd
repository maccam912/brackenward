extends SceneTree
## Ordinary-play scenario runner. Policy only observes state and queues commands.
var options: Dictionary = {"scenario":"", "seed":"104729", "site":"meadow_reach", "mode":"Standard", "days":"8", "report":"reports/simulation.json"}
var failure: String = ""

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()%2!=0: _usage();return
	var seen: Array = []
	for index in range(0,args.size(),2):
		var flag: String = args[index].trim_prefix("--")
		if not args[index].begins_with("--") or not options.has(flag) or seen.has(flag): _usage();return
		seen.append(flag);options[flag]=args[index+1]
	if options.scenario not in ["first_week","first_winter","vegetarian_charter"] or not options.seed.is_valid_int() or int(options.seed)<0 or int(options.seed)>4294967295 or not options.days.is_valid_int() or int(options.days)<1 or int(options.days)>128 or not ColonyGeneration.SITES.has(options.site) or options.mode not in ["Standard","Hearthside"] or options.report.is_empty(): _usage();return
	call_deferred("run")

func _usage() -> void:
	printerr("Usage: -- --scenario first_week|first_winter|vegetarian_charter --seed UINT32 --site meadow_reach|pine_shelf|reed_bend --mode Standard|Hearthside --days 1..128 --report PATH")
	quit(2)

func run() -> void:
	var started: int = Time.get_ticks_msec()
	var world: ColonyWorld = ColonyTests.world()
	var error: String = ColonyGeneration.configure(world,int(options.seed),options.site)
	if not error.is_empty(): printerr(error);quit(2);return
	if options.mode=="Hearthside": world.queue_command("care_mode",{"mode":"Hearthside"})
	var policy: ColonyPolicy = ColonyPolicy.new(options.scenario)
	var initial: PackedByteArray = ColonyCodec.encode(world)
	var initial_structures: Array = world.structures.map(func(s:Dictionary)->int:return s.id)
	var beginning: int = world.tick
	var end: int = beginning+int(options.days)*7200
	var samples: Array = []
	var minimum_health: int = 100
	var zero_fullness_ticks: int = 0
	var starving_damage_risk_ticks: int = 0
	var first_week: Dictionary = {}
	var checked: int = 0
	policy.plan(world)
	while world.tick<end:
		world.step()
		for person in world.citizens:
			if person.death_recorded or person.departed: continue
			minimum_health=mini(minimum_health,person.health)
			if person.fullness==0: zero_fullness_ticks+=1
			if person.starving_ticks>1800: starving_damage_risk_ticks+=1
		if world.tick%300==0:
			checked+=1
			var invariants: Array[String] = world.invariant_errors()
			if not invariants.is_empty(): failure="Invariant failure: "+str(invariants);break
			policy.plan(world)
		if world.tick%7200==0:
			var daily: Dictionary = sample(world)
			samples.append(daily)
			print("Day %d: %d residents, %s, %d research, %d charter stages; pressure %d" % [daily.day,daily.living,daily.food.label,world.researched.size(),world.charter_state.completed.size(),daily.pressure])
			if world.tick==8*7200: first_week=daily.duplicate(true)
		if world.care_state.ended:
			failure="Settlement ended through ordinary simulation; inspect recorded warnings, causes and policy decisions";break
	var completed_improvements: int = world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and not initial_structures.has(s.id)).size()
	var report: Dictionary = {"scenario":options.scenario,"seed":world.seed,"site":world.site_id,"mode":options.mode,"requested_days":int(options.days),"start_tick":beginning,"end_tick":world.tick,"ticks_run":world.tick-beginning,"elapsed_ms":Time.get_ticks_msec()-started,"engine":Engine.get_version_info().string,"content_hash":world.definitions.content_hash,"canonical_hash":world.canonical_hash(),"invariant_checks":checked,"invariant_failure":failure,"minimum_health":minimum_health,"zero_fullness_ticks":zero_fullness_ticks,"starvation_grace_exceeded_ticks":starving_damage_risk_ticks,"completed_improvements":completed_improvements,"first_week":first_week,"samples":samples,"final":sample(world),"ledger":world.ledger,"researched":world.researched,"charter":world.charter_state,"director_history":world.director_state.history,"facts":world.facts,"commands":world.command_trace,"policy_decisions":policy.decisions,"ordinary_play_only":true,"certification":"Scenario evidence only; physical devices and human comprehension remain separate"}
	var scenario_pass: bool = failure.is_empty()
	if options.scenario=="first_week": scenario_pass=scenario_pass and int(options.days)>=8 and starving_damage_risk_ticks==0 and completed_improvements>=3 and FoodForecast.calculate(world).ticks>=7200 and world.citizens.all(func(c:Dictionary)->bool:return not c.departed and not c.death_recorded)
	elif options.scenario=="first_winter": scenario_pass=scenario_pass and world.tick>=32*7200 and starving_damage_risk_ticks==0 and world.citizens.filter(func(c:Dictionary)->bool:return not c.departed and not c.death_recorded).size()>=8 and not world.citizens.any(func(c:Dictionary)->bool:return c.departed)
	else: scenario_pass=scenario_pass and world.charter_state.ending and not world.researched.has("husbandry") and world.ledger.consumed.get("meat",0)==0 and world.ledger.consumed.get("leather",0)==0
	report.scenario_pass=scenario_pass
	if not scenario_pass and failure.is_empty(): report.invariant_failure="Policy did not meet the stated scenario goals; this is not automatically a simulation defect"
	var path: String = options.report
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file==null: printerr("Unable to write scenario report: "+path);quit(2);return
	file.store_string(JSON.stringify(ColonyState.pack(report),"\t",true));file.close()
	file=FileAccess.open(path.get_basename()+"-initial.brackenward",FileAccess.WRITE)
	if file!=null: file.store_buffer(initial);file.close()
	file=FileAccess.open(path.get_basename()+"-final.brackenward",FileAccess.WRITE)
	if file!=null: file.store_buffer(ColonyCodec.encode(world));file.close()
	print("Scenario %s: %s; %d ticks in %d ms; report %s" % [options.scenario,"PASS" if scenario_pass else "FAILED POLICY OR INVARIANT",world.tick-beginning,report.elapsed_ms,path])
	quit(0 if scenario_pass else 1)

func sample(world: ColonyWorld) -> Dictionary:
	return {"tick":world.tick,"day":world.tick/7200+1,"living":world.citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed).size(),"food":FoodForecast.calculate(world),"pressure":ColonyDirector.pressure(world).score,"citizens":world.citizens.map(func(c:Dictionary)->Dictionary:return {"id":c.id,"health":c.health,"fullness":c.fullness,"rest":c.rest,"morale":c.morale,"departed":c.departed,"activity":c.activity}),"stock":{"meal":world.available("meal"),"vegetable":world.available("vegetable"),"grain":world.available("grain"),"mushroom":world.available("mushroom"),"wood":world.available("wood")},"fields":world.fields.size(),"researched":world.researched.duplicate(),"charter_stages":world.charter_state.completed.duplicate(),"major_incidents":world.director_state.history.size(),"canonical_hash":world.canonical_hash()}
