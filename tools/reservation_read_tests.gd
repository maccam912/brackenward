class_name ReservationReadTests
extends RefCounted
## Independent 2e4d4c1 reservation and food replacement paths.
class OriginalWorld extends ColonyWorld:
	func _init(catalog: Dictionary) -> void: super(catalog)
	func _reserve(job: Dictionary, citizen: Dictionary, storage_context: Dictionary = {}) -> bool:
		if job.state=="Queued": return false
		work_budget.mark_dirty()
		if job.kind in ["minor_work","minor_study"] and not ColonyOpportunities.reserve(self,job,citizen): return false
		if job.kind=="enemy_treat" and find(defense_state.enemies,job.target).get("state")!="Downed": _release(job,true);return false
		if job.kind=="raid_pay" and find(defense_state.raids,job.target).get("state")!="Payment": return _block(job,"Payment is no longer awaiting delivery")
		if job.kind=="extinguish": return ColonyFire.reserve(self,job,citizen)
		if job.kind in ["repair","demolish","cook","craft","research","fuel","fish"] and ColonyFire.burning(self,"structure",job.target): return _block(job,"Burning station: extinguish first")
		if citizen.away: return false
		if job.kind=="expedition_pack" and not ColonyRegion.pack_ready(self,job): return false
		if job.kind=="trade" and not ColonyTrade.ready(self,job): return false
		if job.kind=="arrival" and job.target!=citizen.id: return false
		if job.kind=="cart_move" and job.memo.phase=="prepare":
			var cart: Dictionary = find(structures,job.target);job.x=cart.x;job.y=cart.y
		if job.kind in ["repair","demolish","move_furniture"] and not ColonyMaintenance.reserve(self,job): return false
		if job.kind == "equip" and not ColonyEquipment.reserve(self,job,citizen): return false
		if job.kind in ["build","build_helper"] and not ColonyConstruction.ready(self,job): return false
		if job.kind in ["stock_feed","lead_animal","collect_animal","slaughter"] and not ColonyDomestic.reserve(self,job,citizen): return false
		if job.kind in ["hunt","escort_hunt","butcher"] and not ColonyWildlife.reserve(self,job,citizen): return false
		if job.kind in ["plant_tree","clear_sapling","fish"] and not ColonyNature.reserve(self,job): return false
		if job.kind in ["rescue","treat","feed","bury"] and not ColonyCare.reserve(self,job,citizen): return false
		if job.kind in ["cook","craft"]: ReservationReadTests.full_replace_food(self,job)
		if job.kind == "research" and job.definition != production_state.project: return _block(job,"Project inactive: choose it in Research to resume")
		if job.kind == "craft":
			var order: Dictionary = find(production_state.orders,job.order)
			if order.is_empty() or not order.enabled: return _block(job,"Production order paused")
		if job.kind in ["cook","craft","research","fish"]:
			if find(structures,job.target).get("health",0)<=0 or not find(structures,job.target).get("cooking",true): return _block(job,"Station suspended: enable it in the workstation card")
			for other in _reservation_jobs():
				if other.id != job.id and other.worker>0 and other.kind=="minor_study" and other.memo.get("station")==job.target: return _block(job,"Research desk in use by a shared observation")
				if other.id != job.id and other.target == job.target and other.worker > 0 and other.kind in ["cook","craft","research"]: return _block(job,"Workstation in use by another resident")
		for resident in citizens:
			if resident.pinned_job == job.id and resident.id != citizen.id and not job.emergency:
				return false
		var point: Vector2i = Vector2i(job.x, job.y)
		var positions: Array[Vector2i] = []
		if job.kind=="cart_move":
			var cart: Dictionary = find(structures,job.target);positions.append(Vector2i(cart.x,cart.y))
		elif job.kind=="move_furniture":
			positions=_perimeter(ColonyMaintenance.move_footprint(self,job)) if job.memo.phase=="rebuild" else _perimeter(footprint(find(structures,job.target)))
		elif job.kind in ["build","build_helper"]:
			positions = _perimeter(footprint(job))
		elif job.kind=="eat":
			var food: Dictionary = find(stacks,job.source)
			if food.is_empty(): return _block(job,"Food moved or spoiled: choose another portion")
			positions.append(ColonySocial.meal_seat(self,citizen,Vector2i(food.x,food.y)))
		elif job.kind in ["repair","demolish", "gather", "cook", "fuel", "prepare", "sow", "harvest", "replant", "mediate", "craft", "research", "treat", "feed", "bury", "plant_tree", "clear_sapling", "fish", "hunt", "escort_hunt", "butcher", "stock_feed", "lead_animal", "collect_animal", "slaughter", "enemy_treat"]:
			positions = _perimeter(footprint(find(structures, job.target))) if job.kind in ["repair","demolish","cook","fuel","craft","research","fish"] else _perimeter([point])
		else:
			positions.append(point)
		positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var ad: int = absi(a.x - citizen.x) + absi(a.y - citizen.y)
			var bd: int = absi(b.x - citizen.x) + absi(b.y - citizen.y)
			return ad < bd or (ad == bd and a.y * SIZE + a.x < b.y * SIZE + b.x))
		var work_position: Vector2i = Vector2i(-1, -1)
		var unsafe_position: bool = false
		var unreachable_position: bool = false
		var maintenance_from_home: bool = job.kind in ["repair","demolish"] and accessible(Vector2i(citizen.edge_x,citizen.edge_y) if citizen.progress>0 else Vector2i(citizen.x,citizen.y))
		for position in positions:
			if maintenance_from_home and not accessible(position):
				unreachable_position=true
				continue
			if job.kind not in ["hunt","escort_hunt"] and not job.emergency and not ColonyDanger.safe(self,position):
				unsafe_position = true
				continue
			var occupied: bool = false
			if job.kind=="haul" and job.worker==0 and storage_context.has("work_positions"):
				# Consecutive failed unowned haul probes cannot change another task's
				# ownership. Their existing search-local context is valid until success.
				occupied=storage_context.work_positions.has(position)
			else:
				for other in _reservation_jobs():
					# Personal eating owns food rather than a productive work position.
					if job.kind!="eat" and other.kind!="eat" and other.worker > 0 and other.id != job.id and other.work_x == position.x and other.work_y == position.y:
						occupied = true
			if not occupied:
				work_position = position
				break
		if work_position.x < 0:
			return _block(job,"Unsafe route: work avoids eight tiles around danger" if unsafe_position else ("No reachable free work position: clear access or finish nearby work" if unreachable_position else "No free work position"))
		if job.kind not in ["hunt","escort_hunt"] and not job.emergency and not ColonyDanger.safe(self,work_position): return _block(job,"Unsafe route: work avoids eight tiles around danger")
		var requests: Array[Dictionary] = []
		if job.kind == "haul":
			var source: Dictionary = find(stacks, job.source)
			if source.is_empty() or source.count == 0:
				job.state = "Canceled"
				return false
			var quantity: int = mini(8, source.count - _reserved(source))
			if quantity <= 0:
				return _block(job, "Inputs reserved by another job; waiting for its completion")
			var destination: Dictionary = _destination(source.item, quantity, point, source.tags, storage_context)
			if destination.is_empty():
				return _block(job, "No storage space: paint a stockpile or build a rack")
			job.destination = destination.id
			job.work_x = destination.tile.x
			job.work_y = destination.tile.y
			requests.append({"stack": source.id, "count": quantity})
		else:
			job.work_x = work_position.x
			job.work_y = work_position.y
			for item in job.inputs:
				var needed: int = job.inputs[item] - _escrow_count(job.id, item)
				for held_stack in _work_inventory():
					if held_stack.item==item: needed-=held_stack.reservations.get(job.id,0)
					if held_stack.location=="carry" and held_stack.job==job.id and held_stack.item==item: needed-=held_stack.count
				if job.kind=="move_furniture":
					for bundle in _work_inventory():
						if bundle.location=="move_bundle" and bundle.owner==job.id and bundle.item==item: needed -= bundle.count
				if needed<=0: continue
				var sources: Array = (_work_inventory() if in_tick else nonempty_stacks()).filter(func(s:Dictionary)->bool:return s.item == item and s.count > _reserved(s) and s.location in ["ground","store","output"] and (job.kind not in ["eat","feed"] or s.id==job.source) and ColonyFire.usable(self,s) and accessible(Vector2i(s.x,s.y)))
				for stack in ColonyProduction.first_inputs(self,sources,Vector2i(citizen.x,citizen.y),needed):
					var count: int = mini(needed, stack.count - _reserved(stack))
					if count > 0:
						requests.append({"stack": stack.id, "count": count})
						needed -= count
					if needed == 0:
						break
				if needed > 0:
					return _block(job, "Missing " + item + ": gather it or free reserved supplies")
		# Validate every input before committing any reservation.
		for request in requests:
			find(stacks, request.stack).reservations[job.id] = find(stacks, request.stack).reservations.get(job.id,0)+request.count
		job.worker = citizen.id
		job.state = "Fetching" if not requests.is_empty() or _work_inventory().any(func(s:Dictionary)->bool:return s.reservations.get(job.id,0)>0) or (job.kind=="move_furniture" and _work_inventory().any(func(s:Dictionary)->bool:return s.location=="move_bundle" and s.owner==job.id and s.count>0)) else "Moving"
		job.reason = ""
		return true

static func full_replace_food(world: ColonyWorld, job: Dictionary) -> void:
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
	var choices: Array = world.nonempty_stacks().filter(func(s:Dictionary)->bool:return filters.has(s.item) and s.count-world._reserved(s) > 0 and s.location in ["ground","store","output"] and world.accessible(Vector2i(s.x,s.y)))
	for stack in ColonyProduction.first_inputs(world,choices,Vector2i(station.x,station.y),needed):
		var count: int = mini(needed,stack.count-world._reserved(stack))
		if count > 0: food[stack.item] = food.get(stack.item,0)+count; needed -= count
		if needed == 0: break
	# Keep the last complete contract while blocked; available substitutions apply atomically.
	if needed == 0: job.inputs = recipe.materials.duplicate(); job.inputs.merge(food)


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

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	var hearth: Dictionary=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	var recipe: Dictionary=world.definitions.recipes.cook_meals
	var job: Dictionary=world._job("cook","Cooking","Cooking",hearth.id,Vector2i(hearth.x,hearth.y),recipe.work_milli)
	job.inputs={"wood":1,"berry":4};job.output=recipe.outputs.duplicate()
	world._make_stack("berry",12,"ground",0,Vector2i(72,64),true)
	for index in range(8000):
		var empty: Dictionary=world._make_stack("berry",0,"carry",world.citizens[0].id,Vector2i(66,63),false);empty.job=job.id
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("RESERVE/input_fixture_is_accepted_and_conserved",decoded.has("world") and world.invariant_errors().is_empty(),str(decoded.get("error","")))
	if not decoded.has("world"): return
	var fast: ColonyWorld=clone(decoded.world);var full: ColonyWorld=clone(decoded.world,true)
	for current in [fast,full]:
		current.in_tick=true
		var current_job: Dictionary=current.find(current.jobs,job.id)
		var reserved: bool=current._reserve(current_job,current.citizens[0])
		if reserved: current.citizens[0].job=current_job.id
	check.call("RESERVE/initial_recipe_reservations_match_original",fast.canonical_hash()==full.canonical_hash() and fast.find(fast.jobs,job.id).state=="Fetching" and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
	var phases: Dictionary={}
	for index in range(600):
		fast.step();full.step()
		phases[fast.find(fast.jobs,job.id).state]=true
		if index%100==99: check.call("RESERVE/complete_tick_and_historical_metadata_%d" % (index+1),fast.canonical_hash()==full.canonical_hash() and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
	check.call("RESERVE/reference_covers_real_carry_escrow_and_completion",phases.has("Fetching") and phases.has("Delivering") and phases.has("Working") and phases.has("Complete"),str(phases))

	# Re-reserve actual partially delivered inputs after an ordinary release.
	world=ColonyTests.world();hearth=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	job=world._job("cook","Cooking","Cooking",hearth.id,Vector2i(hearth.x,hearth.y),recipe.work_milli);job.inputs={"wood":1,"berry":4};job.output=recipe.outputs.duplicate()
	world._make_stack("berry",12,"ground",0,Vector2i(72,64),true)
	var reserved: bool=world._reserve(job,world.citizens[0])
	if reserved: world.citizens[0].job=job.id
	for index in range(400):
		world.step()
		if world._escrow_count(job.id,"berry")>0: break
	check.call("RESERVE/partial_fixture_has_physically_delivered_food",world._escrow_count(job.id,"berry")>0 and world.invariant_errors().is_empty())
	world._release(job,false)
	fast=clone(world);full=clone(world,true)
	var same: bool=true
	for current in [fast,full]:
		current.in_tick=true
		var current_job: Dictionary=current.find(current.jobs,job.id)
		var current_reserved: bool=current._reserve(current_job,current.citizens[0])
		same=same and current_reserved
		if current_reserved: current.citizens[0].job=current_job.id
	check.call("RESERVE/released_partial_escrow_does_not_reserve_inputs_twice",same and fast.canonical_hash()==full.canonical_hash() and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
