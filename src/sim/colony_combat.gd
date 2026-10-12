class_name ColonyCombat
extends RefCounted

static func citizen_defaults() -> Dictionary:
	return {"attack_ready":0}

static func line_of_sight(world: ColonyWorld, from: Vector2i, to: Vector2i) -> bool:
	var p: Vector2i = from
	var dx: int = absi(to.x-from.x); var dy: int = absi(to.y-from.y)
	var sx: int = 1 if from.x<to.x else -1; var sy: int = 1 if from.y<to.y else -1
	var error: int = dx-dy
	while p != to:
		var twice: int = error*2
		if twice > -dy: error -= dy; p.x += sx
		if twice < dx: error += dx; p.y += sy
		if p == to: return true
		for structure in world.structures:
			if structure.definition in ["wood_wall","stone_wall","door","palisade","reinforced_gate"] and world.footprint(structure).has(p): return false
	return true

static func weapon(citizen: Dictionary, distance: int) -> Dictionary:
	var name: String = citizen.equipment.weapon
	var bow: bool = name == "bow" and distance>=2
	return {"damage":(8 if bow else (9 if name == "spear" else 3))+citizen.skills.Guard,"cooldown":30 if bow else 20,"range":6 if bow else 1}

static func resolve(world: ColonyWorld) -> void:
	var hits: Array = []
	for citizen in world.citizens:
		if citizen.downed or citizen.death_recorded or citizen.departed or citizen.health<=40 or world.tick<citizen.attack_ready: continue
		var job: Dictionary = world.find(world.jobs,citizen.job)
		if job.get("kind") not in ["hunt","escort_hunt"] or job.state != "Working": continue
		if job.kind == "escort_hunt":
			var hunt: Dictionary = world.find(world.jobs,job.order)
			var hunter: Dictionary = world.find(world.citizens,hunt.get("worker",0))
			if hunter.is_empty() or hunt.state in ["Complete","Canceled"] or ColonyWildlife.distance(hunter,world.find(world.wildlife_state.animals,job.target))>6: continue
		var target: Dictionary = world.find(world.wildlife_state.animals,job.target)
		if target.is_empty() or target.health<=0: continue
		var separation: int = ColonyWildlife.distance(citizen,target)
		var attack: Dictionary = weapon(citizen,separation)
		if separation>attack.range or not line_of_sight(world,Vector2i(citizen.x,citizen.y),Vector2i(target.x,target.y)): continue
		citizen.attack_ready = world.tick+attack.cooldown
		hits.append({"animal":target.id,"citizen":citizen.id,"damage":attack.damage,"job":job.id})
	for animal in world.wildlife_state.animals:
		if animal.health<=0 or animal.definition != "boar" or animal.attacker == 0 or world.tick<animal.cooldown: continue
		var target: Dictionary = world.find(world.citizens,animal.attacker)
		var candidates: Array = world.citizens.filter(func(c:Dictionary)->bool:return not c.downed and not c.death_recorded and not c.departed and ColonyWildlife.distance(c,animal)<=1)
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.id<b.id)
		if not candidates.is_empty() and (target.is_empty() or ColonyWildlife.distance(target,animal)>1): target = candidates[0]
		if target.is_empty() or target.downed or target.death_recorded or target.departed or ColonyWildlife.distance(animal,target)>1: continue
		animal.cooldown = world.tick+25
		hits.append({"animal":animal.id,"citizen":target.id,"damage":maxi(1,12-(2 if target.equipment.vest == "vest" else 0)),"job":0})
	# Every attack is chosen before any damage resolves, preserving simultaneous hits.
	var animal_damage: Dictionary = {}; var people_damage: Dictionary = {}
	for hit in hits:
		if hit.job>0:
			animal_damage[hit.animal] = animal_damage.get(hit.animal,0)+hit.damage
			var animal: Dictionary = world.find(world.wildlife_state.animals,hit.animal)
			if animal.definition == "boar" and animal.attacker == 0:
				animal.attacker = hit.citizen; animal.origin = Vector2i(animal.x,animal.y)
		else:
			people_damage[hit.citizen] = people_damage.get(hit.citizen,0)+hit.damage
			world.facts.append({"tick":world.tick,"actor":hit.citizen,"job":0,"kind":"boar_injury","text":"%s took %d damage from a wounded boar; retreat begins at health 40." % [world.find(world.citizens,hit.citizen).name,hit.damage]})
	for id in people_damage:
		var person: Dictionary = world.find(world.citizens,id)
		ColonyCare.hurt(world,person,people_damage[id],true)
		if person.downed:
			var cause: Dictionary = hits.filter(func(h:Dictionary)->bool:return h.job == 0 and h.citizen == id)[0]
			world.wildlife_state.injuries[person.injury_id] = {"animal":cause.animal,"tick":world.tick}
	for id in animal_damage:
		var animal: Dictionary = world.find(world.wildlife_state.animals,id)
		animal.health = maxi(0,animal.health-animal_damage[id])
		if animal.health == 0: ColonyWildlife.kill(world,animal)
	world.danger_cache_tick = -1
