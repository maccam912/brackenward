class_name ColonyEquipment
extends RefCounted
const SLOTS: Dictionary = {"toolkit":["toolkit","forged_toolkit"],"weapon":["spear","bow"],"cloak":["cloak"],"vest":["vest"]}

static func initial_state(citizens: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not citizens is Array: return result
	for citizen in citizens:
		if not citizen is Dictionary or not citizen.get("id") is int or not citizen.get("equipment") is Dictionary: return {}
		result[citizen.id] = {}
		for slot in SLOTS: result[citizen.id][slot]={"replacements":true,"upgrades":false,"preferred":citizen.equipment.get(slot,"")}
	return result

static func rank(item: String) -> int:
	return 2 if item=="forged_toolkit" else (0 if item.is_empty() else 1)

static func source(world: ColonyWorld, person: Dictionary, item: String) -> Dictionary:
	var sources: Array = world.nonempty_stacks().filter(func(s:Dictionary)->bool:return s.item==item and s.count>world._reserved(s) and s.location in ["ground","store","output"] and world.accessible(Vector2i(s.x,s.y)))
	sources.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return ColonyProduction.input_before(world,a,b,Vector2i(person.x,person.y)))
	return {} if sources.is_empty() else sources[0]

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	var person: Dictionary = world.find(world.citizens,args.target)
	if person.is_empty() or person.death_recorded or person.departed or not SLOTS.has(args.slot): return "Choose a resident and a valid equipment slot"
	var policy: Dictionary = world.equipment_state[person.id][args.slot]
	if kind=="equipment_policy":
		policy.replacements=args.replacements;policy.upgrades=args.upgrades
		return "accepted"
	if not args.item is String or (not args.item.is_empty() and not SLOTS[args.slot].has(args.item)): return "Item does not fit this equipment slot"
	if person.equipment[args.slot]==args.item: return "Already equipped"
	var available: Dictionary = {} if args.item.is_empty() else source(world,person,args.item)
	if not args.item.is_empty() and available.is_empty(): return "No accessible unreserved "+args.item+": craft it or free the stock"
	for job in world.jobs:
		if job.kind=="equip" and job.target==person.id and job.definition==args.slot and job.state not in ["Complete","Canceled"]: world._release(job,true)
	policy.preferred=args.item
	if args.item.is_empty(): policy.replacements=false
	_create(world,person,args.slot,args.item,available)
	return "accepted"

static func _create(world: ColonyWorld, person: Dictionary, slot: String, item: String, stack: Dictionary) -> void:
	var point: Vector2i = Vector2i(person.x,person.y) if stack.is_empty() else Vector2i(stack.x,stack.y)
	var job: Dictionary = world._job("equip","Hauling","",person.id,point,2000)
	job.definition=slot;job.inputs={} if item.is_empty() else {item:1}

static func create_jobs(world: ColonyWorld) -> void:
	# These views live for this call only; job creation does not reserve stock.
	var pending: Dictionary = {}
	for job in world._work_jobs():
		if job.kind!="equip" or job.state in ["Complete","Canceled"]: continue
		if not pending.has(job.target): pending[job.target]={}
		pending[job.target][job.definition]=true
	var stocked: Dictionary = {}
	for stack in world._work_inventory():
		if stack.count>0 and stack.location in ["ground","store","output"] and stack.count>world._reserved(stack): stocked[stack.item]=true
	for person in world.citizens:
		if person.death_recorded or person.departed or person.downed or person.away: continue
		for slot in SLOTS:
			var worn: String = person.equipment[slot]
			var policy: Dictionary = world.equipment_state[person.id][slot]
			if not ((worn.is_empty() and policy.replacements) or (not worn.is_empty() and policy.upgrades)): continue
			if pending.get(person.id,{}).has(slot): continue
			var choices: Array = SLOTS[slot].duplicate()
			choices.sort_custom(func(a:String,b:String)->bool:
				if rank(a)!=rank(b): return rank(a)>rank(b)
				if (a==policy.preferred)!=(b==policy.preferred): return a==policy.preferred
				return SLOTS[slot].find(a)<SLOTS[slot].find(b))
			for item in choices:
				if rank(item)<=rank(worn) or not stocked.has(item): continue
				var stack: Dictionary = source(world,person,item)
				if not stack.is_empty(): _create(world,person,slot,item,stack);break

static func reserve(world: ColonyWorld, job: Dictionary, citizen: Dictionary) -> bool:
	if citizen.id!=job.target: return false
	if citizen.death_recorded or citizen.departed or citizen.downed: return world._block(job,"Wearer unavailable: equipment waits for recovery")
	return true

static func complete(world: ColonyWorld, person: Dictionary, job: Dictionary) -> void:
	var item: String = "" if job.inputs.is_empty() else job.inputs.keys()[0]
	for stack in world.stacks:
		if stack.location=="escrow" and stack.owner==job.id: stack.count=0
	var previous: String = person.equipment[job.definition]
	if not previous.is_empty(): world._make_stack(previous,1,"ground",0,Vector2i(person.x,person.y),false)
	person.equipment[job.definition]=item
	world.emit_fact({"tick":world.tick,"actor":person.id,"job":job.id,"kind":"equipment","text":person.name+(" removed "+previous if item.is_empty() else " equipped "+item)+" after fetching it and two work units. Existing gear stays available."})

static func validate(data: Variant, citizens: Array) -> bool:
	if not data is Dictionary or data.size()!=citizens.size(): return false
	for person in citizens:
		if not data.has(person.id) or not data[person.id] is Dictionary or not ColonyCodec._keys(data[person.id],SLOTS.keys()): return false
		for slot in SLOTS:
			var policy: Variant = data[person.id][slot]
			if not policy is Dictionary or not ColonyCodec._keys(policy,["replacements","upgrades","preferred"]) or not policy.replacements is bool or not policy.upgrades is bool or not policy.preferred is String or (not policy.preferred.is_empty() and not SLOTS[slot].has(policy.preferred)): return false
	return true
