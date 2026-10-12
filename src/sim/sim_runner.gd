class_name SimRunner
extends RefCounted

var world: RefCounted
var speed: int = 0
var previous_speed: int = 1
var accumulator: float = 0.0
var behind_seconds: float = 0.0
var speed_reduced: bool = false

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
	accumulator += delta * float(speed)
	var count: int = 0
	while accumulator + 0.000000001 >= 0.1 and count < 8:
		var alert: int = world.care_state.alert_serial if world is ColonyWorld else 0
		world.step()
		accumulator -= 0.1
		count += 1
		if world is ColonyWorld and (world.care_state.ended or world.care_state.alert_serial > alert):
			pause()
			return count
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
