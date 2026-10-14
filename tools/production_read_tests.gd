class_name ProductionReadTests
extends RefCounted
## Original cc84275 production creation and complete step retained as exact oracles.
class OriginalWorld extends ColonyWorld:
	func _init(catalog: Dictionary) -> void: super(catalog)
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
		work_budget.after_commands(self,had_commands)
		ColonyDefense.advance(self)
		ColonyCare.advance(self)
		ColonyWeather.advance(self)
		ColonyAgriculture.advance(self)
		ColonyRegion.advance(self)
		ColonyTrade.advance(self)
		ColonyPopulation.advance(self)
		ColonyDomestic.advance(self)
		ColonyWildlife.advance(self)
		ColonyNature.advance(self)
		ColonySocial.advance(self)
		ColonyLiving.advance(self)
		for citizen in citizens:
			_needs(citizen)
		ColonyCharter.begin_tick(self)
		ColonyDirector.advance(self)
		if tick % 10 == 0:
			_create_work()
			ProductionReadTests.full_create_jobs(self)
			ColonyAgriculture.create_jobs(self)
			ColonyFire.create_jobs(self)
			ColonyCare.create_jobs(self)
			ColonyNature.create_jobs(self)
			ColonyDomestic.create_jobs(self)
			ColonyConstruction.create_helpers(self)
			ColonyEquipment.create_jobs(self)
			work_budget.mark_dirty();work_budget.reconcile_runtime(self)
			for citizen in citizens:
				_assign(citizen)
		for citizen in citizens:
			if citizen.job > 0:
				_work(citizen, find(jobs, citizen.job))
		ColonyCombat.resolve(self)
		committing_work=true
		for transaction in work_commits:
			var job: Dictionary = find(jobs,transaction.job);var worker: Dictionary = find(citizens,transaction.worker)
			if job.is_empty() or worker.is_empty() or job.worker!=worker.id or worker.job!=job.id or worker.downed or worker.death_recorded or worker.departed: continue
			if transaction.kind=="finish": _finish(worker,job)
			elif transaction.kind=="water": ColonyFire.water_ready(self,worker,job)
			elif transaction.kind=="move_phase": ColonyMaintenance.finish_dismantle(self,worker,job)
		ColonyOpportunities.advance(self)
		ColonyCharter.advance(self)
		ColonyChronicle.advance(self)
		work_budget.reconcile_runtime(self)
		committing_work=false;in_tick=false

static func full_create_jobs(world: ColonyWorld) -> void:
	# This pass only queues work; it does not reserve or move stock. Index the
	# current work once, then include each newly queued batch in the same maps.
	var occupied_stations: Dictionary = {}
	var research_desks: Dictionary = {}
	var pending_outputs: Dictionary = {}
	for job in world.unfinished_jobs():
		if job.state in ["Complete","Canceled"]: continue
		if job.kind in ["cook","craft"]:
			occupied_stations[job.target]=true
			for item in job.output: pending_outputs[item]=pending_outputs.get(item,0)+job.output[item]
		elif job.kind=="research" and job.definition==world.production_state.project: research_desks[job.target]=true
	var output_batches: Dictionary = {}
	var material_stock: Dictionary = {}
	for stack in world.nonempty_stacks():
		if stack.count<=0: continue
		if stack.location=="output": output_batches[stack.owner]=output_batches.get(stack.owner,0)+1
		if stack.location in ["ground","store","output"] and ColonyFire.usable(world,stack) and world.accessible(Vector2i(stack.x,stack.y)):
			material_stock[stack.item]=material_stock.get(stack.item,0)+stack.count-world._reserved(stack)
	var maintained_stock: Dictionary = {}
	for station in world.structures:
		if station.health<=0: continue
		if station.definition == "herbal_bench" and world.researched.has("herbalism") and not world.production_state.orders.any(func(o:Dictionary)->bool:return o.station == station.id):
			ColonyProduction.command(world,"recipe_order",{"target":station.id,"definition":"prepare_medicine","mode":"Maintain","value":4,"priority":2,"filters":[]})
	var project: String = world.production_state.project
	if not project.is_empty() and not world.researched.has(project):
		var contributing: int = 0
		for desk in world.structures:
			if desk.health<=0: continue
			if desk.definition != "research_desk" or not desk.cooking: continue
			var exists: bool = research_desks.has(desk.id)
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
		if station.is_empty() or station.health<=0 or not station.cooking: continue
		if occupied_stations.has(station.id): continue
		var outputs: int = output_batches.get(station.id,0)
		if outputs >= 2: continue
		var recipe: Dictionary = world.definitions.recipes[order.recipe]
		if not recipe.materials.keys().all(func(item:Variant)->bool:return material_stock.get(item,0) >= recipe.materials[item]): continue
		if order.mode == "Maintain":
			var sufficient: bool = true
			for item in recipe.outputs:
				if not maintained_stock.has(item): maintained_stock[item]=full_policy_stock(world,item)
				var count: int = maintained_stock[item]+pending_outputs.get(item,0)
				if count < order.quantity: sufficient = false
			if sufficient: continue
		var inputs: Dictionary = recipe.materials.duplicate()
		var needed: int = recipe.food_count
		if needed > 0:
			var choices: Array = world.nonempty_stacks().filter(func(s:Dictionary)->bool:return order.filters.has(s.item) and s.count-world._reserved(s) > 0 and s.location in ["ground","store","output"] and world.accessible(Vector2i(s.x,s.y)))
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
		occupied_stations[station.id]=true
		for item in job.output: pending_outputs[item]=pending_outputs.get(item,0)+job.output[item]

static func full_policy_stock(world: ColonyWorld, item: String) -> int:
	var count: int = 0
	for stack in world.nonempty_stacks():
		if stack.count<=0 or stack.item != item or stack.location not in ["ground","store","output","carry"]: continue
		if stack.location == "carry":
			var delivery: Dictionary = world.find(world.jobs,stack.job)
			if delivery.get("kind") != "haul": continue
		elif not world.accessible(Vector2i(stack.x,stack.y)): continue
		var reserved: int = 0
		for job_id in stack.reservations:
			if world.find(world.jobs,job_id).get("kind") != "haul": reserved += stack.reservations[job_id]
		count += stack.count-reserved
	return count

static func clone(source: ColonyWorld, original: bool = false) -> ColonyWorld:
	var result: ColonyWorld=OriginalWorld.new(source.definitions) if original else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	return result

static func create(world: ColonyWorld, original: bool) -> void:
	if original: full_create_jobs(world)
	else: ColonyProduction.create_jobs(world)

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	var hearth: Dictionary=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	ColonyProduction.command(world,"recipe_order",{"target":hearth.id,"definition":"cook_meals","mode":"Maintain","value":30,"priority":3,"filters":["berry","vegetable","grain"]})
	var bench: Dictionary=world._structure("workbench",Vector2i(74,63),0)
	ColonyProduction.command(world,"recipe_order",{"target":bench.id,"definition":"make_toolkit","mode":"Repeat","value":2,"priority":2,"filters":[]})
	var desk: Dictionary=world._structure("research_desk",Vector2i(78,63),0)
	ColonyProduction.command(world,"research_select",{"definition":"storecraft"})
	for index in range(120):
		var stack: Dictionary=world._make_stack(["grain","berry","vegetable"][index%3],1+index%3,"ground",0,Vector2i(50+index%12,65+index/12),true)
		stack.age=index%11*250;stack.age_rem=index%4
	for index in range(8000):
		world._make_stack("meal",0,"ground",0,Vector2i(66,63),false)
		var job: Dictionary=world._job("leisure","","",0,Vector2i(66,63),0);job.state="Complete"
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("PRODUCTION/read_fixture_is_accepted_and_conserved",decoded.has("world") and world.invariant_errors().is_empty(),str(decoded.get("error","")))
	if not decoded.has("world"): return
	var fast: ColonyWorld=clone(decoded.world);var full: ColonyWorld=clone(decoded.world,true)
	fast.in_tick=true;full.in_tick=true
	create(fast,false);create(full,true)
	check.call("PRODUCTION/live_creation_matches_original_food_recipe_research_and_ordering",fast.canonical_hash()==full.canonical_hash() and fast.jobs.filter(func(j:Dictionary)->bool:return j.state not in ["Complete","Canceled"] and j.kind=="craft").size()==2 and fast.jobs[-1].kind=="craft",str(fast.invariant_errors()))
	var next: int=fast.next_id
	create(fast,false);create(full,true)
	check.call("PRODUCTION/same_tick_proposals_are_not_duplicated",fast.next_id==next and fast.canonical_hash()==full.canonical_hash())
	for current in [fast,full]:
		for job in current.jobs:
			if job.kind=="craft" and job.state not in ["Complete","Canceled"]: current._release(job,true)
		for stack in current.stacks:
			if stack.count>0 and stack.item in ["grain","berry","vegetable","wood"]: current._record("consumed",stack.item,stack.count);stack.count=0
	create(fast,false);create(full,true)
	check.call("PRODUCTION/same_tick_depletion_and_released_work_match_original",fast.canonical_hash()==full.canonical_hash() and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="craft" and j.state not in ["Complete","Canceled"]).is_empty())
	for current in [fast,full]:
		current._make_stack("berry",4,"ground",0,Vector2i(66,63),true)
		current._make_stack("wood",4,"ground",0,Vector2i(66,63),true)
	create(fast,false);create(full,true)
	check.call("PRODUCTION/same_tick_new_food_and_materials_match_original",fast.canonical_hash()==full.canonical_hash() and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="craft" and j.state not in ["Complete","Canceled"]).size()==2 and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
	fast.in_tick=false;full.in_tick=false
	for index in range(600):
		fast.step();full.step()
		if index%100==99: check.call("PRODUCTION/complete_tick_oracle_%d" % (index+1),fast.canonical_hash()==full.canonical_hash() and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
	direct_reopen(check)

static func direct_reopen(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	var hearth: Dictionary=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	ColonyProduction.command(world,"recipe_order",{"target":hearth.id,"definition":"cook_meals","mode":"Maintain","value":30,"priority":2,"filters":["berry"]})
	var berry: Dictionary=world._make_stack("berry",4,"ground",0,Vector2i(66,63),true)
	var full: ColonyWorld=clone(world,true)
	for current in [world,full]:
		current.nonempty_stacks();current.find(current.stacks,berry.id).count=0
	create(world,false);create(full,true)
	for current in [world,full]: current.find(current.stacks,berry.id).count=4
	create(world,false);create(full,true)
	check.call("PRODUCTION/direct_creation_observes_reopened_fixture_stock",world.canonical_hash()==full.canonical_hash() and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="craft"))
