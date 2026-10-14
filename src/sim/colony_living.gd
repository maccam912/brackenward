class_name ColonyLiving
extends RefCounted

static func advance(world: ColonyWorld) -> void:
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
	if temperature(world)<8:
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
		if comfortable(world,citizen):
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
			_morale(world, citizen, job)

static func temperature(world: ColonyWorld) -> int:
	return [12, 24, 10, -5][ColonyAgriculture.season(world.tick)] - (10 if world.weather == "cold_snap" else 0)

static func comfortable(world: ColonyWorld, citizen: Dictionary) -> bool:
	if citizen.away: return true
	if temperature(world) + (12 if citizen.equipment.cloak == "cloak" else 0) >= 5:
		return true
	var point: Vector2i = Vector2i(citizen.x, citizen.y)
	for hearth in world.structures:
		if hearth.health<=0: continue
		if hearth.definition == "hearth" and hearth.fuel > 0:
			if absi(point.x - hearth.x) + absi(point.y - hearth.y) <= 3:
				return true
			if world.roofed(point) and world.room_tiles.get(point) == world.room_tiles.get(Vector2i(hearth.x, hearth.y), -1):
				return true
	return false

static func _morale(world: ColonyWorld, citizen: Dictionary, job: Dictionary) -> void:
	var terms: Dictionary = ColonySocial.mood_terms(world,citizen)
	terms.merge(ColonyCare.mood_terms(world,citizen))
	terms.merge(ColonyCharter.mood_terms(world,citizen))
	if citizen.story_memory_until>world.tick: terms["Shared a traveling story"]=40
	if citizen.away and citizen.traits.has("Homebody"): terms["Homebody away"]=-40
	if world.production_state.discoveries.get(citizen.id,0) > world.tick:
		terms["Discovery"] = 60
	if citizen.bed_memory_until > world.tick:
		terms["Assigned bed"] = 40 if citizen.traits.has("Restless") else 80
	if citizen.food_tags.size() >= 3:
		terms["Food variety"] = 60
	if citizen.warm_until > world.tick:
		terms["Warmth"] = 60
	if not comfortable(world,citizen):
		terms["Cold"] = -150
	if citizen.leisure_memory_until > world.tick:
		terms["Leisure"] = 60
	elif world.tick / 7200 > 0 and citizen.yesterday_leisure < (450 if citizen.traits.has("Sociable") else 300):
		terms["Missed leisure"] = -60
	if citizen.preferred_memory_until > world.tick:
		terms["Preferred work"] = 40
	if citizen.fullness < 200:
		terms["Hungry"] = -250
	if citizen.rest < 200:
		terms["Tired"] = -200
	if citizen.health < 60:
		terms["Injured"] = -150
	if citizen.raw_memory_until > world.tick and not citizen.traits.has("Outdoorsy"):
		terms["Raw produce"] = -50
	if not job.is_empty() and job.kind not in ["sleep", "eat", "leisure", "supper", "supper_reserve"]:
		var inside: bool = world.roofed(Vector2i(citizen.x, citizen.y))
		if citizen.traits.has("Homebody") and inside and not citizen.away:
			terms["Homebody indoors"] = 40
		if citizen.traits.has("Outdoorsy") and not inside:
			terms["Outdoorsy at work"] = 40
	var target: int = 600
	for amount in terms.values():
		target += amount
	target = clampi(target, 100, 900)
	citizen.morale += clampi(target - citizen.morale, -60, 60)
	citizen.mood_terms = terms
