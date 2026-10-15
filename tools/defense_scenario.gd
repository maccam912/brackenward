extends SceneTree
## Prepared release fixture, deliberately separate from ordinary-play campaigns.
## Only setup exception: announce one fixed two-thief party at the initial tick.
## Both branches load the exact same announcement; all later actions are commands.
var options: Dictionary={"seed":"104729","site":"meadow_reach","report":""}
var failure: String=""

func _initialize() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args();var seen: Array=[]
	if args.size()%2!=0:usage();return
	for index in range(0,args.size(),2):
		var flag: String=args[index].trim_prefix("--")
		if not args[index].begins_with("--") or not options.has(flag) or seen.has(flag):usage();return
		seen.append(flag);options[flag]=args[index+1]
	if not options.seed.is_valid_int() or int(options.seed)<0 or int(options.seed)>4294967295 or not ColonyGeneration.SITES.has(options.site) or options.report.is_empty():usage();return
	call_deferred("run")

func usage() -> void:
	printerr("Usage: -- --seed UINT32 --site meadow_reach|pine_shelf|reed_bend --report NEW.json");quit(2)

func write_bytes(path: String, bytes: PackedByteArray) -> bool:
	if FileAccess.file_exists(path):failure="Refusing to overwrite earlier evidence: "+path;return false
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null:failure="Cannot create evidence: "+path;return false
	file.store_buffer(bytes);file.close()
	if FileAccess.get_file_as_bytes(path)!=bytes:failure="Evidence readback differs: "+path;return false
	return true

func save(world: ColonyWorld, label: String) -> Dictionary:
	var bytes: PackedByteArray=ColonyCodec.encode(world);var decoded: Dictionary=ColonyCodec.decode(bytes)
	var canonical: String=world.canonical_hash();var path: String=options.report.get_basename()+"-"+label+".brackenward"
	if not decoded.has("world") or decoded.world.canonical_hash()!=canonical:
		failure="Full snapshot validation differs at "+label;return {}
	if not write_bytes(path,bytes):return {}
	return {"canonical_hash":canonical,"sha256":FileAccess.get_sha256(path),"tick":world.tick,"roundtrip_verified":true}

func run() -> void:
	DirAccess.make_dir_recursive_absolute(options.report.get_base_dir())
	var world: ColonyWorld=ColonyTests.world();var error: String=ColonyGeneration.configure(world,int(options.seed),options.site)
	if not error.is_empty():printerr(error);quit(2);return
	var normal: Dictionary=save(world,"normal")
	if normal.is_empty():printerr(failure);quit(2);return
	var raid: Dictionary=ColonyDefense.announce(world,2)
	var announced: Dictionary=save(world,"announced")
	if announced.is_empty():printerr(failure);quit(2);return
	var prepared: PackedByteArray=FileAccess.get_file_as_bytes(options.report.get_basename()+"-announced.brackenward")
	var result: Dictionary={"format":"brackenward-prepared-defense","version":1,"site":world.site_id,"seed":world.seed,"generator_version":world.generator_version,"content_hash":world.definitions.content_hash,"engine":Engine.get_version_info().string,"normal":normal,"announced":announced,"raid_id":raid.id,"due":raid.due,"entry":raid.entry,"meeting":raid.meeting,"party":raid.party.duplicate(),"setup_exception":"One ColonyDefense.announce(world,2) at tick 1800. No source of supplies, positions, weather, clocks, skills or combat results is edited. Not an ordinary director-frequency scenario.","branches":{}}
	for action in ["defend","ransom"]:
		result.branches[action]=branch(prepared,action)
		if not failure.is_empty():break
	result.passed=failure.is_empty() and result.branches.size()==2 and result.branches.values().all(func(row:Dictionary)->bool:return row.passed)
	result.failure=failure
	if not write_bytes(options.report,JSON.stringify(ColonyState.pack(result),"\t",true).to_utf8_buffer()):printerr(failure);quit(2);return
	print("Prepared defense %s seed %d: %s" % [world.site_id,world.seed,"PASS" if result.passed else "FAIL"])
	quit(0 if result.passed else 1)

func queue(world: ColonyWorld, kind: String, args: Dictionary, decisions: Array) -> void:
	var id: int=world.queue_command(kind,args)
	decisions.append({"tick_queued":world.tick,"id":id,"kind":kind,"args":args.duplicate(true)})

func branch(prepared: PackedByteArray, action: String) -> Dictionary:
	var decoded: Dictionary=ColonyCodec.decode(prepared)
	if not decoded.has("world"):failure="Prepared snapshot failed to load";return {"passed":false}
	var world: ColonyWorld=decoded.world;var raid: Dictionary=world.defense_state.raids[0]
	var decisions: Array=[];var samples: Array=[];var transitions: Array=[];var reloads: Array=[]
	var minimum_health: int=100;var zero_fullness: int=0;var checks: int=0;var enemy_steps: int=0
	var prior_positions: Dictionary={};var prior_state: String=raid.state;var first_retreat: Dictionary={}
	var saw_shelter: bool=false;var saw_downed: bool=false;var boundary_spawn: bool=false
	var cart: Vector2i=Vector2i(ColonyTrade.cart(world).x,ColonyTrade.cart(world).y)
	var approach: Array[Vector2i]=ColonyNavigation.path(raid.entry,cart,world.walkable,world.can_step)
	if approach.size()<30:failure="Announced approach route is missing or too short";return {"passed":false}
	# Intercept a visible announced approach. Waiting at the cart can let a
	# distant party hit its six-hour limit before contact, which proves no combat.
	var rally: Vector2i=approach[approach.size()/2]
	var limit: int=raid.due+7200;var finished_at: int=0
	while world.tick<limit and failure.is_empty():
		if action=="defend" and world.tick==raid.due-300:
			queue(world,"shelter",{"enabled":true},decisions)
			queue(world,"draft",{"citizens":[2,3,4],"rally":rally,"stand_fast":false},decisions)
		if action=="ransom" and raid.arrival>0 and decisions.is_empty():
			queue(world,"raid_offer",{"target":raid.id,"pay":{"wood":16}},decisions)
		var prior_tick: int=world.tick
		world.step()
		if world.tick!=prior_tick+1:failure="Simulation stopped before the incident ended";break
		for person in world.citizens:
			minimum_health=mini(minimum_health,person.health)
			if person.fullness==0:zero_fullness+=1
			if person.id==1 and (person.activity.begins_with("Shelter") or world.find(world.jobs,person.job).get("kind")=="shelter"):saw_shelter=true
		for enemy in world.defense_state.enemies:
			var point: Vector2i=Vector2i(enemy.x,enemy.y)
			if not prior_positions.has(enemy.id):boundary_spawn=point==raid.entry and (point.x in [0,127] or point.y in [0,127])
			elif point!=prior_positions[enemy.id]:enemy_steps+=1
			prior_positions[enemy.id]=point
			saw_downed=saw_downed or enemy.state=="Downed"
		if raid.state!=prior_state:
			var transition: Dictionary={"tick":world.tick,"state":raid.state,"arrival":raid.arrival,"loot_units":raid.loot_units,"reason":raid.reason,"enemies":world.defense_state.enemies.duplicate(true)}
			transitions.append(transition);prior_state=raid.state
			if raid.state=="Retreating" and first_retreat.is_empty():first_retreat=transition.duplicate(true)
		if world.tick%60==0:
			checks+=1;var errors: Array[String]=world.invariant_errors()
			if not errors.is_empty():failure="Invariant failure: "+str(errors);break
			samples.append({"tick":world.tick,"state":raid.state,"citizens":world.citizens.map(func(p:Dictionary)->Dictionary:return {"id":p.id,"x":p.x,"y":p.y,"health":p.health,"rest":p.rest,"fullness":p.fullness,"activity":p.activity}),"enemies":world.defense_state.enemies.map(func(e:Dictionary)->Dictionary:return {"id":e.id,"x":e.x,"y":e.y,"health":e.health,"state":e.state})})
		# Reload the active incident: the defense branch is approaching, while
		# the ransom branch is under a payment ceasefire. Preserve real routes.
		if world.tick==raid.due+120:
			var receipt: Dictionary=save(world,action+"-active")
			if receipt.is_empty():break
			reloads.append(receipt)
			var restored: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(options.report.get_basename()+"-"+action+"-active.brackenward"))
			if not restored.has("world"):failure="Active-incident save did not restore";break
			var trace: Array[Dictionary]=world.command_trace.duplicate(true)
			world=restored.world;world.command_trace=trace;raid=world.defense_state.raids[0]
		if raid.state=="Resolved" and finished_at==0:
			finished_at=world.tick;queue(world,"stand_down",{},decisions)
		if finished_at>0 and world.tick>=finished_at+60:break
	var final: Dictionary=save(world,action+"-final")
	var living: bool=world.citizens.size()==4 and world.citizens.all(func(p:Dictionary)->bool:return not p.death_recorded and not p.departed and not p.downed and not p.drafted)
	var commands_accepted: bool=decisions.all(func(d:Dictionary)->bool:return world.receipts.get(d.id)=="accepted") and world.pending_commands.is_empty()
	var common: bool=failure.is_empty() and raid.state=="Resolved" and raid.arrival==raid.due and boundary_spawn and living and commands_accepted and zero_fullness==0 and not first_retreat.is_empty() and reloads.size()==1 and world.invariant_errors().is_empty()
	var objective: bool=false
	if action=="defend":objective=saw_shelter and saw_downed and enemy_steps>=30 and raid.loot_units==0 and world.ledger.traded_out.get("wood",0)==0 and first_retreat.get("tick",limit)<raid.arrival+1800 and world.defense_state.enemies.any(func(e:Dictionary)->bool:return e.health<=10)
	else:
		var payment: Dictionary=world.find(world.jobs,raid.pay_job)
		objective=minimum_health==100 and raid.loot_units==0 and world.ledger.traded_out.get("wood",0)==16 and payment.get("state")=="Complete" and payment.get("kind")=="raid_pay" and payment.get("inputs")=={"wood":16} and first_retreat.get("tick",limit)<raid.arrival+1800 and world.defense_state.enemies.all(func(e:Dictionary)->bool:return e.health==40)
	return {"passed":common and objective,"action":action,"rally":rally,"approach_route":approach,"initial_canonical_hash":JSON.parse_string(prepared.get_string_from_utf8()).sha256,"end_tick":world.tick,"minimum_health":minimum_health,"zero_fullness_ticks":zero_fullness,"invariant_checks":checks,"enemy_tile_steps":enemy_steps,"saw_shelter":saw_shelter,"saw_downed":saw_downed,"boundary_spawn":boundary_spawn,"commands_accepted":commands_accepted,"all_four_living_home_undrafted":living,"first_retreat":first_retreat,"transitions":transitions,"reloads":reloads,"samples":samples,"decisions":decisions,"commands":world.command_trace,"final":final,"raid":raid.duplicate(true),"ledger":world.ledger.duplicate(true)}
