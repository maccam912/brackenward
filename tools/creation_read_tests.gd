class_name CreationReadTests
extends RefCounted
## Independent full-history creation reads retained from 04500fb.

static func full_equipment(world: ColonyWorld) -> void:
	# These views live for this call only; job creation does not reserve stock.
	var pending: Dictionary = {}
	for job in world.jobs:
		if job.kind!="equip" or job.state in ["Complete","Canceled"]: continue
		if not pending.has(job.target): pending[job.target]={}
		pending[job.target][job.definition]=true
	var stocked: Dictionary = {}
	for stack in world.stacks:
		if stack.count>0 and stack.location in ["ground","store","output"] and stack.count>world._reserved(stack): stocked[stack.item]=true
	for person in world.citizens:
		if person.death_recorded or person.departed or person.downed or person.away: continue
		for slot in ColonyEquipment.SLOTS:
			var worn: String = person.equipment[slot]
			var policy: Dictionary = world.equipment_state[person.id][slot]
			if not ((worn.is_empty() and policy.replacements) or (not worn.is_empty() and policy.upgrades)): continue
			if pending.get(person.id,{}).has(slot): continue
			var choices: Array = ColonyEquipment.SLOTS[slot].duplicate()
			choices.sort_custom(func(a:String,b:String)->bool:
				if ColonyEquipment.rank(a)!=ColonyEquipment.rank(b): return ColonyEquipment.rank(a)>ColonyEquipment.rank(b)
				if (a==policy.preferred)!=(b==policy.preferred): return a==policy.preferred
				return ColonyEquipment.SLOTS[slot].find(a)<ColonyEquipment.SLOTS[slot].find(b))
			for item in choices:
				if ColonyEquipment.rank(item)<=ColonyEquipment.rank(worn) or not stocked.has(item): continue
				var stack: Dictionary = ColonyEquipment.source(world,person,item)
				if not stack.is_empty(): ColonyEquipment._create(world,person,slot,item,stack);break

static func full_helpers(world: ColonyWorld) -> void:
	var parents: Array = world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build" and j.state=="Working")
	for parent in parents:
		if world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="build_helper" and j.order==parent.id and j.state not in ["Complete","Canceled"]): continue
		var helper: Dictionary = world._job("build_helper","Building","Build",parent.id,Vector2i(parent.x,parent.y),0)
		helper.definition=parent.definition;helper.rotation=parent.rotation;helper.order=parent.id;helper.priority=parent.priority

static func create(world: ColonyWorld, full: bool) -> void:
	if full: full_helpers(world);full_equipment(world)
	else: ColonyConstruction.create_helpers(world);ColonyEquipment.create_jobs(world)

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	world.queue_command("build",{"definition":"table","x":74,"y":63,"rotation":0})
	var parent: Dictionary = {}
	for index in range(400):
		world.step()
		var working: Array = world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build" and j.state=="Working")
		if not working.is_empty(): parent=working[0];break
	check.call("CREATE/reference_fixture_reaches_real_shared_material_work",not parent.is_empty() and world._escrow_count(parent.get("id",0),"wood")==8)
	if parent.is_empty(): return
	for index in range(8000):
		var kind: String = ["leisure","equip","build_helper"][index%3]
		var old: Dictionary = world._job(kind,"Hauling" if kind=="equip" else "", "",world.citizens[0].id if kind=="equip" else (parent.id if kind=="build_helper" else 0),Vector2i(50,60),2000 if kind=="equip" else 0)
		old.state="Complete";old.work=old.required
		if kind=="equip": old.definition="vest"
		elif kind=="build_helper": old.order=parent.id;old.definition=parent.definition
		world._make_stack("wood",0,"ground",0,Vector2i(50,60),false)
	world._make_stack("forged_toolkit",4,"ground",0,Vector2i(50,60),true)
	world._make_stack("vest",4,"ground",0,Vector2i(50,60),true)
	world.equipment_state[world.citizens[0].id].toolkit.upgrades=true
	ColonyEquipment._create(world,world.citizens[0],"vest","vest",world.stacks[-1])
	world.jobs[-1].state="Queued";world.jobs[-1].queue_state="Ready"
	var first: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	var second: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("CREATE/history_fixture_is_an_accepted_conserved_save",first.has("world") and second.has("world"),str([first.get("error",""),second.get("error","")]))
	if not first.has("world") or not second.has("world"): return
	var fast: ColonyWorld=first.world;var full: ColonyWorld=second.world
	fast.in_tick=true;full.in_tick=true
	create(fast,false);create(full,true)
	check.call("CREATE/live_views_match_full_history_and_keep_queued_equipment",fast.canonical_hash()==full.canonical_hash() and fast.invariant_errors().is_empty() and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="equip" and j.target==fast.citizens[0].id and j.definition=="vest" and j.state not in ["Complete","Canceled"]).size()==1,str(fast.invariant_errors()))
	var next: int=fast.next_id
	create(fast,false);create(full,true)
	check.call("CREATE/repeated_same_tick_creation_does_not_duplicate_proposals",fast.next_id==next and full.canonical_hash()==fast.canonical_hash())
	for current in [fast,full]:
		for job in current.jobs:
			if job.kind=="equip" and job.definition=="toolkit" and job.state not in ["Complete","Canceled"]: current._release(job,true)
		for stack in current.stacks:
			if stack.item=="forged_toolkit" and stack.count>0: current._record("consumed",stack.item,stack.count);stack.count=0
	create(fast,false);create(full,true)
	check.call("CREATE/same_tick_depleted_stock_is_not_proposed",fast.next_id==next and full.canonical_hash()==fast.canonical_hash() and fast.invariant_errors().is_empty())
	for current in [fast,full]: current._make_stack("forged_toolkit",1,"ground",0,Vector2i(50,60),true)
	var appended: int=fast.next_id
	create(fast,false);create(full,true)
	check.call("CREATE/same_tick_new_stock_is_visible",fast.next_id==appended+1 and full.canonical_hash()==fast.canonical_hash() and fast.invariant_errors().is_empty())
	direct_reopen(check)

static func direct_reopen(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	world._make_stack("vest",4,"ground",0,Vector2i(50,60),true)
	ColonyEquipment._create(world,world.citizens[0],"vest","vest",world.stacks[-1])
	world.jobs[-1].state="Complete"
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	if not decoded.has("world"): check.call("CREATE/direct_fixture_loads",false,str(decoded));return
	var other: ColonyWorld=decoded.world
	for current in [world,other]: current.unfinished_jobs();current.jobs[-1].state="Ready"
	create(world,false);create(other,true)
	check.call("CREATE/direct_calls_keep_reopened_fixture_history",world.canonical_hash()==other.canonical_hash() and world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="equip" and j.target==world.citizens[0].id and j.definition=="vest" and j.state not in ["Complete","Canceled"]).size()==1)
