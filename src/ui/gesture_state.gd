class_name GestureState
extends RefCounted
## Gestures only return intents. Confirm remains a separate UI action.

var mode: String = "select"
var fingers: Dictionary = {}
var start: Vector2 = Vector2.ZERO
var last: Vector2 = Vector2.ZERO
var elapsed_ms: float = 0.0
var dragging: bool = false
var multiple: bool = false
var long_pressed: bool = false
var pinch_distance: float = 0.0

func begin(index: int, point: Vector2) -> void:
	fingers[index] = point
	if fingers.size() == 1:
		start = point
		last = point
		elapsed_ms = 0.0
		dragging = false
		multiple = false
		long_pressed = false
	else:
		multiple = true
		pinch_distance = _distance()

func move(index: int, point: Vector2) -> Dictionary:
	if not fingers.has(index):
		return {}
	var previous: Vector2 = fingers[index]
	fingers[index] = point
	if multiple:
		var distance: float = _distance()
		var ratio: float = distance / pinch_distance if pinch_distance > 0.0 and distance > 0.0 else 1.0
		pinch_distance = distance
		return {"kind": "pinch", "ratio": ratio, "delta": (point - previous) * 0.5, "point": _midpoint()}
	if point.distance_to(start) > 8.0:
		dragging = true
	var delta: Vector2 = point - last
	last = point
	if dragging:
		return {"kind": "paint" if mode == "paint" else "pan", "point": point, "start": start, "delta": delta}
	return {}

func end(index: int, point: Vector2) -> Dictionary:
	if not fingers.has(index):
		return {}
	fingers.erase(index)
	var result: Dictionary = {}
	if not multiple and not dragging and not long_pressed and elapsed_ms < 350.0 and point.distance_to(start) <= 8.0:
		result = {"kind": "paint_tap" if mode == "paint" else "select", "point": point}
	if fingers.is_empty():
		cancel()
	return result

func elapse(delta: float) -> Dictionary:
	if fingers.is_empty():
		return {}
	elapsed_ms += delta * 1000.0
	if not multiple and not dragging and not long_pressed and elapsed_ms >= 450.0:
		long_pressed = true
		return {"kind": "magnifier" if mode == "paint" else "chooser", "point": last}
	return {}

func cancel() -> void:
	fingers.clear()
	dragging = false
	multiple = false
	long_pressed = false
	pinch_distance = 0.0

func _distance() -> float:
	var values: Array = fingers.values()
	return values[0].distance_to(values[1]) if values.size() >= 2 else 0.0

func _midpoint() -> Vector2:
	var values: Array = fingers.values()
	return (values[0] + values[1]) * 0.5 if values.size() >= 2 else last
