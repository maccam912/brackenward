class_name ColonyProduction
extends RefCounted

static func initial_state() -> Dictionary:
	return {"orders":[],"project":"","progress":{},"insight":0,"queue":[],"discoveries":{}}

static func initialize(world: ColonyWorld) -> void:
	world.production_state = initial_state()

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	if kind in ["research_select","research_queue"]:
		if not world.definitions.research.has(args.definition): return "Unknown research"
		if world.researched.has(args.definition): return "Already researched"
		if kind == "research_queue":
			if world.production_state.queue.size() >= 3: return "Research queue is limited to three projects"
			if world.production_state.queue.has(args.definition) or world.production_state.project == args.definition: return "Already selected or queued"
			world.production_state.queue.append(args.definition)
			return "accepted"
		for prerequisite in world.definitions.research[args.definition].prerequisites:
			if not world.researched.has(prerequisite): return "Requires "+prerequisite.capitalize()
		for job in world.jobs:
			if job.kind == "research" and job.worker > 0: world._release(job,false)
		world.production_state.project = args.definition
		world.production_state.queue.erase(args.definition)
		apply_insight(world)
		return "accepted"
	if kind == "order_enabled":
		var order: Dictionary = world.find(world.production_state.orders,args.target)
		if order.is_empty(): return "Missing production order"
		order.enabled = args.enabled
		for job in world.jobs:
			if job.kind == "craft" and job.order == order.id and not order.enabled and job.worker > 0: world._release(job,false)
		return "accepted"
	var station: Dictionary = world.find(world.structures,args.target)
	var recipe: Dictionary = world.definitions.recipes.get(args.definition,{})
	if station.is_empty() or recipe.is_empty() or recipe.station != station.definition: return "Recipe needs its matching workstation"
	if recipe.unlock != "initial" and not world.researched.has(recipe.unlock): return "Requires "+recipe.unlock.capitalize()+" research"
	if args.mode not in ["Repeat","Maintain"] or args.value < 1 or args.value > 1000 or args.priority not in [1,2,3]: return "Invalid production policy"
	if not args.filters.all(func(item:Variant)->bool:return recipe.alternatives.has(item)): return "Invalid ingredient filter"
	world.production_state.orders.append({"id":world._id(),"station":station.id,"recipe":recipe.id,"mode":args.mode,"quantity":args.value,"priority":args.priority,"filters":args.filters.duplicate(),"enabled":true})
	return "accepted"

static func create_jobs(world: ColonyWorld) -> void:
	var project: String = world.production_state.project
	if not project.is_empty() and not world.researched.has(project):
		var contributing: int = 0
		for desk in world.structures:
			if desk.definition != "research_desk" or not desk.cooking: continue
			var exists: bool = world.jobs.any(func(j:Dictionary)->bool:return j.kind == "research" and j.target == desk.id and j.definition == project and j.state not in ["Complete","Canceled"])
			if contributing >= 2: break
			contributing += 1
			if not exists:
				var job: Dictionary = world._job("research","Research","Study",desk.id,Vector2i(desk.x,desk.y),world.definitions.research[project].points*1000)
				job.definition = project
	var orders: Array = world.production_state.orders.duplicate()
	orders.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.priority > b.priority or (a.priority == b.priority and a.id < b.id))
	for order in orders:
		if not order.enabled or order.quantity <= 0: continue
		var station: Dictionary = world.find(world.structures,order.station)
		if station.is_empty() or not station.cooking: continue
		if world.jobs.any(func(j:Dictionary)->bool:return j.target == station.id and j.kind in ["cook","craft"] and j.state not in ["Complete","Canceled"]): continue
		var outputs: int = world.stacks.filter(func(s:Dictionary)->bool:return s.count > 0 and s.location == "output" and s.owner == station.id).size()
		if outputs >= 2: continue
		var recipe: Dictionary = world.definitions.recipes[order.recipe]
		if not recipe.materials.keys().all(func(item:Variant)->bool:return world.available(item) >= recipe.materials[item]): continue
		if order.mode == "Maintain":
			var sufficient: bool = true
			for item in recipe.outputs:
				var count: int = policy_stock(world,item)
				for other in world.jobs:
					if other.kind in ["cook","craft"] and other.state not in ["Complete","Canceled"]: count += other.output.get(item,0)
				if count < order.quantity: sufficient = false
			if sufficient: continue
		var inputs: Dictionary = recipe.materials.duplicate()
		var needed: int = recipe.food_count
		if needed > 0:
			var choices: Array = world.stacks.filter(func(s:Dictionary)->bool:return order.filters.has(s.item) and s.count-world._reserved(s) > 0 and s.location in ["ground","store","output"] and world.accessible(Vector2i(s.x,s.y)))
			choices.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
				var ae: int = FoodForecast.expiry_ticks(world,a)
				var be: int = FoodForecast.expiry_ticks(world,b)
				var ad: int = absi(a.x-station.x)+absi(a.y-station.y)
				var bd: int = absi(b.x-station.x)+absi(b.y-station.y)
				return ae < be or (ae == be and (ad < bd or (ad == bd and (a.item < b.item or (a.item == b.item and a.id < b.id))))))
			for stack in choices:
				var count: int = mini(needed,stack.count-world._reserved(stack))
				inputs[stack.item] = inputs.get(stack.item,0)+count
				needed -= count
				if needed == 0: break
			if needed > 0: continue
		var job: Dictionary = world._job("craft","Cooking" if recipe.skill == "Cooking" else "Crafting",recipe.skill,station.id,Vector2i(station.x,station.y),recipe.work_milli)
		job.definition = recipe.id
		job.order = order.id
		job.inputs = inputs
		job.output = recipe.outputs.duplicate()
		job.priority = order.priority

static func completed(world: ColonyWorld, job: Dictionary) -> void:
	var order: Dictionary = world.find(world.production_state.orders,job.order)
	if not order.is_empty() and order.mode == "Repeat": order.quantity = maxi(0,order.quantity-1)

static func policy_stock(world: ColonyWorld, item: String) -> int:
	var count: int = 0
	for stack in world.stacks:
		if stack.item != item or stack.location not in ["ground","store","output","carry"]: continue
		if stack.location == "carry":
			var delivery: Dictionary = world.find(world.jobs,stack.job)
			if delivery.get("kind") != "haul": continue
		elif not world.accessible(Vector2i(stack.x,stack.y)): continue
		var reserved: int = 0
		for job_id in stack.reservations:
			if world.find(world.jobs,job_id).get("kind") != "haul": reserved += stack.reservations[job_id]
		count += stack.count-reserved
	return count

static func research_work(world: ColonyWorld, citizen: Dictionary, job: Dictionary) -> void:
	if job.definition != world.production_state.project or world.researched.has(job.definition):
		world._release(job,false)
		world._block(job,"Research project changed: progress is retained")
		return
	var progress: int = world.production_state.progress.get(job.definition,0)
	var maximum: int = world.definitions.research[job.definition].points*1000
	var work: int = mini(world._rate(citizen,job),maximum-progress)
	world.production_state.progress[job.definition] = progress+work
	job.work += work
	job.pending_xp[citizen.id] = job.pending_xp.get(citizen.id,0)+work
	citizen.activity = "Researching "+job.definition.capitalize()
	if progress+work >= maximum:
		finish_project(world,job.definition,citizen.id)
		apply_insight(world)

static func finish_project(world: ColonyWorld, project: String, actor_id: int = 0) -> void:
	world.researched.append(project)
	for contributor in world.jobs:
		if contributor.kind != "research" or contributor.definition != project or contributor.state in ["Complete","Canceled"]: continue
		var actor: Dictionary = world.find(world.citizens,contributor.worker)
		if actor.is_empty():
			world._award_xp(contributor)
			contributor.state = "Complete"
		else: world._complete(actor,contributor)
	for person in world.citizens:
		if person.traits.has("Curious"): world.production_state.discoveries[person.id] = world.tick+14400
	world.production_state.project = ""
	if not world.production_state.queue.is_empty():
		var next: String = world.production_state.queue[0]
		if world.definitions.research[next].prerequisites.all(func(id:Variant)->bool:return world.researched.has(id)):
			world.production_state.project = world.production_state.queue.pop_front()
	world.facts.append({"tick":world.tick,"actor":actor_id,"job":0,"kind":"research_complete","text":project.capitalize()+" research completed; its catalog unlocks are available."})

static func add_insight(world: ColonyWorld, points: int) -> void:
	# Apply to the current project and eligible queue before capping the bank.
	world.production_state.insight += maxi(0,points)
	apply_insight(world)
	world.production_state.insight = mini(1000,world.production_state.insight)

static func apply_insight(world: ColonyWorld) -> void:
	while world.production_state.insight > 0 and not world.production_state.project.is_empty():
		var project: String = world.production_state.project
		var maximum: int = world.definitions.research[project].points*1000
		var progress: int = world.production_state.progress.get(project,0)
		var points: int = mini(world.production_state.insight,(maximum-progress+999)/1000)
		world.production_state.progress[project] = mini(maximum,progress+points*1000)
		world.production_state.insight -= points
		if progress+points*1000 >= maximum: finish_project(world,project)

static func replace_food(world: ColonyWorld, job: Dictionary) -> void:
	var recipe: Dictionary = world.definitions.recipes.get(job.definition if job.kind == "craft" else "cook_meals",{})
	if recipe.get("food_count",0) == 0: return
	var filters: Array = recipe.alternatives
	if job.kind == "craft": filters = world.find(world.production_state.orders,job.order).get("filters",[])
	var food: Dictionary = {}
	var needed: int = recipe.food_count
	for item in recipe.alternatives:
		var held: int = world._escrow_count(job.id,item)
		if held > 0: food[item] = held; needed -= held
	var station: Dictionary = world.find(world.structures,job.target)
	var choices: Array = world.stacks.filter(func(s:Dictionary)->bool:return filters.has(s.item) and s.count-world._reserved(s) > 0 and s.location in ["ground","store","output"] and world.accessible(Vector2i(s.x,s.y)))
	choices.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return input_before(world,a,b,Vector2i(station.x,station.y)))
	for stack in choices:
		var count: int = mini(needed,stack.count-world._reserved(stack))
		if count > 0: food[stack.item] = food.get(stack.item,0)+count; needed -= count
		if needed == 0: break
	# Keep the last complete contract while blocked; available substitutions apply atomically.
	if needed == 0: job.inputs = recipe.materials.duplicate(); job.inputs.merge(food)

static func input_before(world: ColonyWorld, a: Dictionary, b: Dictionary, origin: Vector2i) -> bool:
	var ae: int = FoodForecast.expiry_ticks(world,a)
	var be: int = FoodForecast.expiry_ticks(world,b)
	var ad: int = absi(a.x-origin.x)+absi(a.y-origin.y)
	var bd: int = absi(b.x-origin.x)+absi(b.y-origin.y)
	return ae < be or (ae == be and (ad < bd or (ad == bd and (a.item < b.item or (a.item == b.item and a.id < b.id)))))

static func validate(data: Variant, definitions: Dictionary) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["orders","project","progress","insight","queue","discoveries"]) or not data.orders is Array or data.orders.size() > 10000 or not data.project is String or not data.progress is Dictionary or not data.insight is int or data.insight < 0 or data.insight > 1000 or not data.queue is Array or data.queue.size() > 3 or not data.discoveries is Dictionary: return false
	for id in data.discoveries:
		if not id is int or id not in [1,2,3,4] or not data.discoveries[id] is int or data.discoveries[id] < 0: return false
	var seen: Dictionary = {}
	if not data.project.is_empty() and not definitions.research.has(data.project): return false
	for project in data.queue:
		if not project is String or not definitions.research.has(project) or seen.has(project) or project == data.project: return false
		seen[project] = true
	for project in data.progress:
		if not definitions.research.has(project) or not data.progress[project] is int or data.progress[project] < 0 or data.progress[project] > definitions.research[project].points*1000: return false
	for order in data.orders:
		if not order is Dictionary or not ColonyCodec._keys(order,["id","station","recipe","mode","quantity","priority","filters","enabled"]): return false
		if not order.id is int or order.id < 1 or not order.station is int or not definitions.recipes.has(order.recipe) or order.mode not in ["Repeat","Maintain"] or not order.quantity is int or order.quantity < 0 or order.quantity > 1000 or order.priority not in [1,2,3] or not order.filters is Array or not order.enabled is bool: return false
		if not order.filters.all(func(item:Variant)->bool:return definitions.recipes[order.recipe].alternatives.has(item)): return false
	return true
