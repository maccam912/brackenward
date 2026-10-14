class_name AgingReadTests
extends RefCounted
## Full advance path retained from cf34471; all shared helper definitions unchanged.
class CountingWorld extends ColonyWorld:
	var structure_reads: int = 0
	func _init(catalog: Dictionary) -> void: super(catalog)
	func find(records: Array, id: int) -> Dictionary:
		if is_same(records,structures): structure_reads+=1
		return super(records,id)

static func full_advance(world: ColonyWorld) -> void:
	for stack in world.perishable_stacks():
		if stack.count == 0:
			continue
		var shelf: int = world.definitions.items[stack.item].shelf_ticks
		if shelf == 0:
			continue
		var denominator: int = 1
		if stack.location == "store":
			var store: Dictionary = world.find(world.structures,stack.owner)
			if not store.is_empty() and store.definition in ["granary","cellar"]:
				denominator = world.definitions.buildings[store.definition].age_denominator
		stack.age_rem += 4 / denominator
		stack.age += stack.age_rem / 4
		stack.age_rem %= 4
		if stack.age >= shelf:
			world._record("spoiled", stack.item, stack.count)
			stack.count = 0
			for job_id in stack.reservations.keys():
				var job: Dictionary = world.find(world.jobs, job_id)
				world._release(job, false)
				world._block(job, "Ingredients spoiled: gather fresh food and check storage")
			if stack.location in ["carry", "escrow"]:
				var job: Dictionary = world.find(world.jobs, stack.job if stack.location == "carry" else stack.owner)
				world._release(job, false)
				world._block(job, "Held inputs spoiled: gather fresh food")
			stack.reservations.clear()
	if ColonyLiving.temperature(world)<8:
		for hearth in world.structures:
			if hearth.health<=0 or hearth.definition!="hearth" or hearth.fuel<=0: continue
			var occupied: bool = false
			for citizen in world.citizens:
				if citizen.death_recorded or citizen.departed: continue
				var point: Vector2i = Vector2i(citizen.x,citizen.y)
				if absi(point.x-hearth.x)+absi(point.y-hearth.y)<=3 or (world.roofed(point) and world.room_tiles.get(point)==world.room_tiles.get(Vector2i(hearth.x,hearth.y),-1)):
					occupied=true;break
			if occupied:
				hearth.heat_ticks+=1
				if hearth.heat_ticks>=1800:
					hearth.heat_ticks-=1800;hearth.fuel-=1
					world._record("consumed","wood",1)
	for citizen in world.citizens:
		if citizen.death_recorded or citizen.departed: continue
		var day: int = world.tick / 7200
		if citizen.leisure_day != day:
			citizen.leisure_day = day
			citizen.yesterday_leisure = citizen.leisure_ticks
			citizen.leisure_ticks = 0
		if citizen.food_tags_day != day:
			citizen.food_tags_day = day
			citizen.food_tags.clear()
		var job: Dictionary = world.find(world.jobs, citizen.job)
		if not job.is_empty() and job.kind == "sleep" and job.state == "Working":
			var bed: Dictionary = world.find(world.structures, citizen.bed)
			if not bed.is_empty() and bed.health>0 and bed.definition == "bed" and job.target==bed.id and world.footprint(bed).has(Vector2i(citizen.x,citizen.y)):
				citizen.bed_sleep_ticks += 1
				if citizen.bed_sleep_ticks >= 1200:
					citizen.bed_memory_until = world.tick + 7200
					if citizen.bed_sleep_ticks == 1200:
						var rested: int = world.emit_fact({"tick":world.tick,"actor":citizen.id,"job":job.id,"kind":"rested_in_bed","text":citizen.name+" completed four hours of sleep in an assigned bed."},{"participants":[citizen.id,bed.id],"location":[citizen.x,citizen.y]})
						ColonyChronicle.remember(world,"sleep:"+str(citizen.id),rested)
			else:
				citizen.bed_sleep_ticks = 0
		else:
			citizen.bed_sleep_ticks = 0
		if citizen.leisure_ticks >= (450 if citizen.traits.has("Sociable") else 300):
			citizen.leisure_memory_until = world.tick + 7200
			var prior: Array = ColonyChronicle.causes(world,"leisure:"+str(citizen.id))
			if prior.is_empty() or ColonyChronicle.fact(world.chronicle_state,prior[0]).tick / 7200 != day:
				var relaxed: int = world.emit_fact({"tick":world.tick,"actor":citizen.id,"job":citizen.job,"kind":"leisure_completed","text":citizen.name+" completed the day's leisure time."})
				ColonyChronicle.remember(world,"leisure:"+str(citizen.id),relaxed)
		if ColonyLiving.comfortable(world,citizen):
			citizen.warm_until = world.tick + 600
		if citizen.morale < (200 if citizen.traits.has("Steady") else 250):
			citizen.break_clock += 1
		else:
			citizen.break_clock = 0
		if citizen.break_clock >= 1800 and world.tick >= citizen.break_cooldown and citizen.break_until == 0:
			citizen.break_until = world.tick + 1800
			citizen.break_clock = 0
			if not job.is_empty() and job.kind not in ["eat", "sleep"]:
				world._release(job, false)
			world.emit_fact({"tick": world.tick, "actor": citizen.id, "job": 0, "kind": "break", "text": citizen.name + " takes a break: " + str(citizen.mood_terms)})
		if citizen.break_until > 0 and world.tick >= citizen.break_until:
			citizen.break_until = 0
			citizen.break_cooldown = world.tick + 14400
			citizen.morale = mini(1000, citizen.morale + 120)
		if citizen.morale < 200:
			citizen.departure_clock += 1
		elif citizen.morale >= 300:
			citizen.departure_clock = 0
			citizen.departure_until = 0
		if citizen.departure_clock >= 7200 and citizen.departure_until == 0 and not citizen.departed:
			citizen.departure_until = world.tick + 7200
			world.emit_fact({"tick": world.tick, "actor": citizen.id, "job": 0, "kind": "departure_notice", "text": citizen.name + " may leave in one day: improve bed, food, warmth or workload"})
		if world.tick % 300 == 0:
			ColonyLiving._morale(world, citizen, job)

static func clone(source: ColonyWorld) -> CountingWorld:
	var result: CountingWorld=CountingWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	result.structure_reads=0
	return result

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	var stores: Array=[world.stores[0]]
	for pair in [["granary",Vector2i(74,63)],["cellar",Vector2i(80,63)]]:
		var building: Dictionary=world._structure(pair[0],pair[1],0)
		var store: Dictionary={"id":building.id,"tiles":[pair[1]],"capacity":world.definitions.buildings[pair[0]].storage_capacity,"priority":2,"filters":world.definitions.items.keys()}
		world.stores.append(store);stores.append(store)
	var painted: Dictionary={"id":world._id(),"tiles":[Vector2i(50,60)],"capacity":100,"priority":2,"filters":world.definitions.items.keys()}
	world.stores.append(painted);stores.append(painted)
	var first_ids: Array=[]
	for store in stores:
		for index in range(50):
			var stack: Dictionary=world._make_stack("meal",1,"store",store.id,store.tiles[0],true)
			stack.age=index*3;stack.age_rem=index%4
			if index==0: first_ids.append(stack.id)
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("AGE/mixed_storage_fixture_is_accepted_and_conserved",decoded.has("world") and world.invariant_errors().is_empty(),str(decoded.get("error",world.invariant_errors())))
	if not decoded.has("world"): return
	var fast: CountingWorld=clone(decoded.world);var full: CountingWorld=clone(decoded.world)
	for index in range(4):
		fast.tick+=1;full.tick+=1
		ColonyLiving.advance(fast);full_advance(full)
	check.call("AGE/one_lookup_per_owner_matches_full_advance",fast.canonical_hash()==full.canonical_hash() and fast.structure_reads==16 and full.structure_reads>=800,str([fast.structure_reads,full.structure_reads]))
	check.call("AGE/quarter_remainders_keep_cart_granary_cellar_and_painted_rates",first_ids.map(func(id:int)->int:return fast.find(fast.stacks,id).age)==[4,2,1,4] and first_ids.all(func(id:int)->bool:return fast.find(fast.stacks,id).age_rem==0))
	for current in [fast,full]:
		var moved: Dictionary=current.find(current.stacks,first_ids[0]);moved.owner=stores[2].id;moved.x=80;moved.y=63
	ColonyLiving.advance(fast);full_advance(full)
	check.call("AGE/new_call_uses_current_owner_without_refreshing_age",fast.canonical_hash()==full.canonical_hash() and fast.find(fast.stacks,first_ids[0]).age==4 and fast.find(fast.stacks,first_ids[0]).age_rem==1)
	for current in [fast,full]: ColonyMaintenance.destroy(current,current.find(current.structures,stores[2].id))
	ColonyLiving.advance(fast);full_advance(full)
	check.call("AGE/destroyed_store_drops_preservation_immediately",fast.canonical_hash()==full.canonical_hash() and fast.find(fast.stacks,first_ids[0]).location=="ground" and fast.find(fast.stacks,first_ids[0]).age==5 and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
	world=ColonyTests.world();world.citizens[0].fullness=300;world._assign(world.citizens[0])
	var eating: Dictionary=world.find(world.jobs,world.citizens[0].job)
	check.call("AGE/reserved_food_fixture_uses_real_eating_order",eating.get("kind")=="eat" and eating.source>0)
	if eating.get("kind")!="eat": return
	var meal: Dictionary=world.find(world.stacks,eating.source);meal.age=world.definitions.items[meal.item].shelf_ticks-1;meal.age_rem=3
	fast=clone(world);full=clone(world)
	ColonyLiving.advance(fast);full_advance(full)
	check.call("AGE/spoilage_release_and_ledger_match_with_shared_owner_cache",fast.canonical_hash()==full.canonical_hash() and fast.find(fast.jobs,eating.id).state=="Canceled" and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
