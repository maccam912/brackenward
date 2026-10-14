class_name SimRunner
extends RefCounted

var world: RefCounted
var speed: int = 0
var previous_speed: int = 1
var accumulator: float = 0.0
var behind_seconds: float = 0.0
var speed_reduced: bool = false
var auto_pauses: Dictionary = default_auto_pauses()
var notice: String = ""
var seen_decisions: Dictionary = {}
var seen_departures: Dictionary = {}

static func default_auto_pauses() -> Dictionary:
	return {"downed":true,"hostile":true,"fire":true,"expedition":true,"departure":true,"low_food":true}

func _init(state: RefCounted) -> void:
	world = state

func set_speed(value: int) -> void:
	assert(value in [0, 1, 2, 4])
	if value > 0:
		previous_speed = value
	speed = value
	if speed == 0:
		accumulator = 0.0
		behind_seconds = 0.0

func pause() -> void:
	set_speed(0)

func advance_frame(delta: float) -> int:
	if speed == 0:
		return 0
	if world is ColonyWorld and _pending_pause(): return 0
	accumulator += delta * float(speed)
	var count: int = 0
	while accumulator + 0.000000001 >= 0.1 and count < 8:
		var charter_finished: bool = world.charter_state.ending if world is ColonyWorld else false
		var alerts: Array = _alerts() if world is ColonyWorld else []
		world.step()
		accumulator -= 0.1
		count += 1
		if world is ColonyWorld:
			if world.care_state.ended or (world.charter_state.ending and not charter_finished): pause();return count
			var current: Array = _alerts()
			for index in range(alerts.size()):
				if current[index]>alerts[index]:
					notice=["A resident needs urgent care.","An expedition needs a decision.","A new building fire needs attention.","A hostile party has arrived."][index]
					if auto_pauses[["downed","expedition","fire","hostile"][index]]:
						_mark_decisions();pause();return count
			if _pending_pause(): return count
	if accumulator > 1.0:
		behind_seconds += delta
		if behind_seconds >= 3.0 and speed > 1:
			speed /= 2
			previous_speed = speed
			behind_seconds = 0.0
			speed_reduced = true
	else:
		behind_seconds = 0.0
	return count

func _alerts() -> Array:
	return [world.care_state.alert_serial,world.region_state.alert_serial,world.fire_state.alert_serial,world.defense_state.alert_serial]

func _mark_decisions() -> void:
	for trip in world.region_state.trips:
		if trip.state in ["Decision","Collect"]: seen_decisions[str(trip.id)+":"+trip.state]=true

func _pending_pause() -> bool:
	if auto_pauses.expedition:
		for trip in world.region_state.trips:
			if trip.state not in ["Decision","Collect"]: continue
			var key: String = str(trip.id)+":"+trip.state
			if seen_decisions.has(key): continue
			seen_decisions[key]=true
			if world.pending_commands.any(func(c:Dictionary)->bool:return c.kind in ["expedition_choice","expedition_collect","expedition_recall"] and c.args.get("target")==trip.id): continue
			notice="An expedition needs a decision. Open Valley > Expedition status."
			pause();return true
	for person in world.citizens:
		if person.departure_until<=0 or person.departed or person.death_recorded or seen_departures.get(person.id)==person.departure_until: continue
		seen_departures[person.id]=person.departure_until
		notice=person.name+" may leave in one day. Open People to improve bed, food, warmth or workload."
		if auto_pauses.departure: pause();return true
	return false
