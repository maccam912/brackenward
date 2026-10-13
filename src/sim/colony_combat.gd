class_name ColonyCombat
extends RefCounted

static func citizen_defaults() -> Dictionary:
	return {"attack_ready":0,"guard_xp_day":0,"guard_xp_today":0,"defense_incident":0}

static func award_guard_xp(world: ColonyWorld, citizen: Dictionary, amount: int) -> void:
	var day: int = world.tick/7200
	if citizen.guard_xp_day!=day: citizen.guard_xp_day=day;citizen.guard_xp_today=0
	var earned: int = mini(amount,50-citizen.guard_xp_today)
	if earned<=0: return
	citizen.guard_xp_today+=earned
	world._award_xp({"skill":"Guard","pending_xp":{citizen.id:earned*1000}})

static func validate(citizens: Array, tick: int, raids: Array) -> bool:
	for person in citizens:
		if not person.guard_xp_day is int or person.guard_xp_day<0 or person.guard_xp_day>tick/7200 or not person.guard_xp_today is int or person.guard_xp_today<0 or person.guard_xp_today>50 or not person.defense_incident is int or person.defense_incident<0: return false
		if person.defense_incident>0 and not raids.any(func(r:Dictionary)->bool:return r.id==person.defense_incident): return false
	return true

static func ordered_actors(records: Array) -> Array:
	var ordered: Array = records.duplicate()
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.id<b.id)
	return ordered

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
			if structure.health>0 and structure.definition in ["wood_wall","stone_wall","door","palisade","reinforced_gate"] and world.footprint(structure).has(p): return false
	return true

static func weapon(citizen: Dictionary, distance: int, weather: String = "clear") -> Dictionary:
	var name: String = citizen.equipment.weapon
	var bow: bool = name == "bow" and distance>=2
	return {"damage":(8 if bow else (9 if name == "spear" else 3))+citizen.skills.Guard,"cooldown":30 if bow else 20,"range":(4 if weather=="fog" else 6) if bow else 1}

static func resolve(world: ColonyWorld) -> void:
	var hits: Array = []
	for citizen in ordered_actors(world.citizens):
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
		var attack: Dictionary = weapon(citizen,separation,world.weather)
		if separation>attack.range or not line_of_sight(world,Vector2i(citizen.x,citizen.y),Vector2i(target.x,target.y)): continue
		citizen.attack_ready = world.tick+attack.cooldown
		hits.append({"animal":target.id,"citizen":citizen.id,"damage":attack.damage,"job":job.id})
	for animal in ordered_actors(world.wildlife_state.animals):
		if animal.health<=0 or animal.definition != "boar" or animal.attacker == 0 or world.tick<animal.cooldown: continue
		var target: Dictionary = world.find(world.citizens,animal.attacker)
		var candidates: Array = world.citizens.filter(func(c:Dictionary)->bool:return not c.downed and not c.death_recorded and not c.departed and not c.away and ColonyWildlife.distance(c,animal)<=1)
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.id<b.id)
		if not candidates.is_empty() and (target.is_empty() or ColonyWildlife.distance(target,animal)>1): target = candidates[0]
		if target.is_empty() or target.downed or target.death_recorded or target.departed or ColonyWildlife.distance(animal,target)>1: continue
		animal.cooldown = world.tick+25
		hits.append({"animal":animal.id,"citizen":target.id,"damage":maxi(1,12-(2 if target.equipment.vest == "vest" else 0)),"job":0})
	var human_hits: Array = ColonyDefense.attacks(world)
	# Every attack is chosen before any damage resolves, preserving simultaneous hits.
	var animal_damage: Dictionary = {}; var people_damage: Dictionary = {}
	for hit in hits:
		if hit.job>0:
			animal_damage[hit.animal] = animal_damage.get(hit.animal,0)+hit.damage
			award_guard_xp(world,world.find(world.citizens,hit.citizen),2)
			var animal: Dictionary = world.find(world.wildlife_state.animals,hit.animal)
			if animal.definition == "boar" and animal.attacker == 0:
				animal.attacker = hit.citizen; animal.origin = Vector2i(animal.x,animal.y)
		else:
			people_damage[hit.citizen] = people_damage.get(hit.citizen,0)+hit.damage
			world.facts.append({"tick":world.tick,"actor":hit.citizen,"job":0,"kind":"boar_injury","text":"%s took %d damage from a wounded boar; retreat begins at health 40." % [world.find(world.citizens,hit.citizen).name,hit.damage]})
	var enemy_damage: Dictionary = {};var wall_damage: Dictionary = {};var attackers: Dictionary = {}
	for hit in human_hits:
		if hit.kind=="citizen": people_damage[hit.target]=people_damage.get(hit.target,0)+hit.damage
		elif hit.kind=="enemy":
			enemy_damage[hit.target]=enemy_damage.get(hit.target,0)+hit.damage;attackers[hit.target]=mini(attackers.get(hit.target,hit.source),hit.source)
			var person: Dictionary = world.find(world.citizens,hit.source)
			person.defense_incident=world.find(world.defense_state.enemies,hit.target).raid
			award_guard_xp(world,person,2)
		else: wall_damage[hit.target]=wall_damage.get(hit.target,0)+hit.damage
	var fire_damage: Dictionary = ColonyFire.collect_damage(world)
	for id in fire_damage.people:
		if not people_damage.has(id): people_damage[id]=0
	for id in fire_damage.structures: wall_damage[id]=wall_damage.get(id,0)+fire_damage.structures[id]
	for id in people_damage:
		var person: Dictionary = world.find(world.citizens,id)
		# Attack damage keeps the promised downing floor, then fire contributes
		# uncapped damage in the same resolution, including to downed people.
		var attack_damage: int = 0 if person.downed else mini(people_damage[id],maxi(0,person.health-10))
		var flame_damage: int = fire_damage.people.get(id,0)
		ColonyCare.hurt(world,person,attack_damage+flame_damage)
		if flame_damage>0: world.facts.append({"tick":world.tick,"actor":person.id,"job":0,"kind":"fire_injury","text":"%s took %d fire damage from a burning tile; rescue and water remain available." % [person.name,flame_damage]})
		if person.downed:
			var causes: Array = hits.filter(func(h:Dictionary)->bool:return h.job==0 and h.citizen==id)
			if not causes.is_empty(): world.wildlife_state.injuries[person.injury_id]={"animal":causes[0].animal,"tick":world.tick}
	for id in animal_damage:
		var animal: Dictionary = world.find(world.wildlife_state.animals,id)
		animal.health = maxi(0,animal.health-animal_damage[id])
		if animal.health == 0: ColonyWildlife.kill(world,animal)
	for id in enemy_damage: ColonyDefense.hurt(world,world.find(world.defense_state.enemies,id),enemy_damage[id],attackers[id])
	for id in wall_damage:
		var wall: Dictionary = world.find(world.structures,id);wall.health=maxi(0,wall.health-wall_damage[id])
		if wall.health==0: ColonyMaintenance.destroy(world,wall)
	ColonyFire.finish_tick(world,fire_damage)
	world.danger_cache_tick = -1
