class_name SimRunner
extends RefCounted
# Playback labels are relative to this baseline; authoritative ticks stay 0.1 simulated seconds.
const BASE_PLAYBACK_RATE: int = 2
const QUIET_SLEEP_SPEED: int = 12
const SLEEP_SPEED_STEPS: Array[int] = [12,8,6]
const SLEEP_BATCH_BUDGET_US: int = 8000

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
var quiet_sleep_enabled: bool = true
var quiet_sleep_allowed: bool = true
var sleep_fast_forward: bool = false
var sleep_boost_suppressed: bool = false
var sleep_boost_limited: bool = false
var sleep_speed_tier: int = 0
var frame_speed: int = 0
# Only the presentation supplies wall time; authoritative world steps stay pure.
var frame_clock: Callable
# Optional presentation timing sink: elapsed microseconds, completed tick, speed.
# No clock reads or callbacks are added to ordinary headless runners.
var tick_observer: Callable

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
		sleep_fast_forward=false
		accumulator = 0.0
		behind_seconds = 0.0

func pause() -> void:
	set_speed(0)

func playback_speed() -> int:
	return SLEEP_SPEED_STEPS[sleep_speed_tier] if sleep_fast_forward and speed>0 else speed

func _clock_usec() -> int:
	return int(frame_clock.call()) if frame_clock.is_valid() else 0

func _all_asleep() -> bool:
	if not world is ColonyWorld: return false
	var count: int=0
	for person in world.citizens:
		if person.death_recorded or person.departed: continue
		count+=1
		if person.downed or person.drafted or person.rest>=ColonyRest.RESTED or person.fullness<=350 or person.departure_until>0: return false
		if person.away:
			if not person.camp_sleeping: return false
		else:
			var job: Dictionary=world.find(world.jobs,person.job)
			if job.get("kind")!="sleep" or job.state!="Working": return false
	return count>0

func _quiet() -> bool:
	if not world.pending_commands.is_empty() or world.care_state.ended or (world.charter_state.ending and not world.charter_state.continued) or not world.weather_state.flooded.is_empty(): return false
	if not ColonyDanger.sources(world).is_empty(): return false
	var raid: Dictionary=ColonyDefense.active(world)
	if not raid.is_empty() and (raid.state!="Announced" or not raid.acknowledged): return false
	var major: Dictionary=world.director_state.major
	if not major.is_empty() and (major.state=="Active" or (major.state=="Announced" and major.kind!="raid")): return false
	if world.region_state.trips.any(func(t:Dictionary)->bool:return t.state in ["Decision","Collect"]): return false
	if world.opportunity_state.offers.any(func(o:Dictionary)->bool:return o.state in ["Offered","Accepted","Hosted"]): return false
	if world.population_state.offers.any(func(o:Dictionary)->bool:return o.state=="Offered"): return false
	if world.trade_state.merchants.any(func(m:Dictionary)->bool:return m.state not in ["Waiting","Gone"]): return false
	return true

func advance_frame(delta: float) -> int:
	frame_speed=speed
	if speed == 0:
		return 0
	if world is ColonyWorld and _pending_pause(): return 0
	var was_fast: bool=sleep_fast_forward
	var all_asleep: bool=_all_asleep() if quiet_sleep_enabled else false
	if not all_asleep: sleep_boost_suppressed=false;sleep_speed_tier=0
	sleep_fast_forward=quiet_sleep_enabled and quiet_sleep_allowed and not sleep_boost_suppressed and all_asleep and _quiet()
	if was_fast and not sleep_fast_forward: accumulator=0.0;behind_seconds=0.0
	frame_speed=playback_speed()
	accumulator += delta * float(frame_speed * BASE_PLAYBACK_RATE)
	var started: int=_clock_usec() if sleep_fast_forward else 0
	var observe_ticks: bool=tick_observer.is_valid() and frame_clock.is_valid()
	var count: int = 0
	while accumulator + 0.000000001 >= 0.1 and count < 8:
		var charter_finished: bool = world.charter_state.ending if world is ColonyWorld else false
		var alerts: Array = _alerts() if world is ColonyWorld else []
		var tick_started: int=_clock_usec() if observe_ticks else 0
		world.step()
		if observe_ticks:
			var elapsed: int=_clock_usec()-tick_started
			if elapsed>=0:tick_observer.call(elapsed,world.tick,frame_speed)
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
		if sleep_fast_forward:
			# Stop exactly at the wake/event tick; unused bonus time must not race
			# an awake resident through their first work or decision.
			if not _all_asleep() or not _quiet():
				sleep_fast_forward=false;accumulator=0.0;behind_seconds=0.0
				return count
			if _clock_usec()-started>=SLEEP_BATCH_BUDGET_US: break
	if accumulator > 1.0:
		behind_seconds += delta
		if behind_seconds >= 3.0:
			if sleep_fast_forward:
				if sleep_speed_tier+1<SLEEP_SPEED_STEPS.size():
					sleep_speed_tier+=1
				else:
					sleep_boost_suppressed=true;sleep_fast_forward=false;sleep_boost_limited=true
				accumulator=0.0;behind_seconds=0.0
			elif speed > 1:
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
