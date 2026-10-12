class_name WorldView
extends Control

signal intent(action: Dictionary)
var world: PrototypeWorld
var gestures: GestureState = GestureState.new()
var camera_tile: Vector2 = Vector2(68, 63)
var tile_size: float = 32.0
var preview_start: Vector2i = Vector2i(74, 54)
var preview_end: Vector2i = Vector2i(77, 55)
var preview_visible: bool = false
var selected_id: int = 0
var follow_id: int = 0
var magnifier: Vector2 = Vector2(-100, -100)
var ground: Node2D
var terrain: TileMapLayer
var actors: Array[Sprite2D] = []

func setup(state: PrototypeWorld) -> void:
	world = state
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	ground = Node2D.new()
	ground.y_sort_enabled = true
	add_child(ground)
	terrain = TileMapLayer.new()
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas.texture = load("res://assets/exported/terrain/m0_atlas.svg")
	atlas.texture_region_size = Vector2i(16, 16)
	for x in range(6):
		atlas.create_tile(Vector2i(x, 0))
	tile_set.add_source(atlas, 0)
	terrain.tile_set = tile_set
	ground.add_child(terrain)
	for y in range(128):
		for x in range(128):
			var cell: int = (x * 17 + y * 13) % 2
			if x < 32 or x > 95:
				cell = 2
			if PrototypeWorld.is_water(Vector2i(x, y)):
				cell = 3
			elif x == 66 or y == 63 or y == 64:
				cell = 4
			if x in range(74, 82) and y in range(54, 62):
				cell = 0
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(cell, 0))
	for name in ["mira", "oren", "tavi", "sela"]:
		var actor: Sprite2D = Sprite2D.new()
		actor.texture = load("res://assets/exported/citizens/%s.svg" % name)
		actor.offset = Vector2(0, -8)
		ground.add_child(actor)
		actors.append(actor)
	resized.connect(_update_transform)
	_update_transform()

func _process(delta: float) -> void:
	var action: Dictionary = gestures.elapse(delta)
	if not action.is_empty():
		_apply_intent(action)
	if world == null:
		return
	for i in range(4):
		var citizen: Dictionary = world.citizens[i]
		var point: Vector2 = Vector2(citizen.x + 0.5, citizen.y + 0.5)
		point.x += float(citizen.progress) / 10000.0 * citizen.direction
		actors[i].position = point * 16.0
		if citizen.id == follow_id:
			camera_tile = point
	_update_transform()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			gestures.begin(event.index, event.position)
		else:
			_apply_intent(gestures.end(event.index, event.position))
		accept_event()
	elif event is InputEventScreenDrag:
		_apply_intent(gestures.move(event.index, event.position))
		accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_at(1.25, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_at(0.8, event.position)
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				if event.button_index == MOUSE_BUTTON_MIDDLE:
					gestures.mode = "pan"
				gestures.begin(-1, event.position)
			else:
				_apply_intent(gestures.end(-1, event.position))
				gestures.mode = "paint" if preview_visible else "select"
		accept_event()
	elif event is InputEventMouseMotion and gestures.fingers.has(-1):
		_apply_intent(gestures.move(-1, event.position))
		accept_event()

func _apply_intent(action: Dictionary) -> void:
	if action.is_empty():
		return
	match action.kind:
		"pan":
			follow_id = 0
			camera_tile -= action.delta / tile_size
		"pinch":
			follow_id = 0
			camera_tile -= action.delta / tile_size
			zoom_at(action.ratio, action.point)
		"paint":
			preview_start = screen_to_tile(action.start)
			preview_end = screen_to_tile(action.point)
		"paint_tap":
			preview_end = screen_to_tile(action.point)
		"select", "chooser":
			action["tile"] = screen_to_tile(action.point)
			intent.emit(action)
		"magnifier":
			magnifier = action.point
			intent.emit({"kind": "notice", "text": "Drag to adjust. Confirm stays separate."})
	_update_transform()
	queue_redraw()

func screen_to_tile(point: Vector2) -> Vector2i:
	var tile: Vector2 = (point - size * 0.5) / tile_size + camera_tile
	return Vector2i(clampi(int(floor(tile.x)), 0, 127), clampi(int(floor(tile.y)), 0, 127))

func tile_to_screen(tile: Vector2) -> Vector2:
	return (tile - camera_tile) * tile_size + size * 0.5

func zoom_at(ratio: float, point: Vector2) -> void:
	var anchor: Vector2 = (point - size * 0.5) / tile_size + camera_tile
	tile_size = clampf(tile_size * ratio, 16.0, 64.0)
	camera_tile = anchor - (point - size * 0.5) / tile_size
	_update_transform()

func cancel_gesture() -> void:
	gestures.cancel()
	magnifier = Vector2(-100, -100)

func preview_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(mini(preview_start.y, preview_end.y), maxi(preview_start.y, preview_end.y) + 1):
		for x in range(mini(preview_start.x, preview_end.x), maxi(preview_start.x, preview_end.x) + 1):
			result.append(Vector2i(x, y))
	return result

func _update_transform() -> void:
	if ground == null:
		return
	camera_tile.x = clampf(camera_tile.x, 0.0, 128.0)
	camera_tile.y = clampf(camera_tile.y, 0.0, 128.0)
	ground.scale = Vector2.ONE * tile_size / 16.0
	ground.position = size * 0.5 - camera_tile * tile_size

func _draw() -> void:
	if world == null:
		return
	# Fixture landmarks, no constructed structures/economy implied.
	for point in [Vector2(62, 59), Vector2(64, 59), Vector2(62, 61), Vector2(64, 61)]:
		draw_style_box(_bed_style(), Rect2(tile_to_screen(point), Vector2(tile_size, tile_size * 1.6)))
	var hearth: Vector2 = tile_to_screen(Vector2(70.5, 62.5))
	draw_circle(hearth, tile_size * 0.45, Color("716D88"))
	draw_colored_polygon(PackedVector2Array([hearth + Vector2(-8, 5), hearth + Vector2(0, -13), hearth + Vector2(8, 5)]), Color("E9BA67"))
	draw_rect(Rect2(tile_to_screen(Vector2(66, 63)), Vector2(tile_size * 2, tile_size)), Color("B96C50"))
	for tile in world.designations:
		draw_rect(Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size), Color(0.91, 0.73, 0.4, 0.35))
		draw_rect(Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size), Color("F3E8CC"), false, 2)
	if preview_visible:
		for tile in preview_tiles():
			var color: Color = Color("B44F4A") if PrototypeWorld.is_water(tile) else Color("E9BA67")
			color.a = 0.3
			var rectangle: Rect2 = Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size)
			draw_rect(rectangle, color)
			draw_rect(rectangle, Color("263C3B"), false, 2)
	for citizen in world.citizens:
		if citizen.id == selected_id:
			var point: Vector2 = tile_to_screen(Vector2(citizen.x + 0.5 + float(citizen.progress) / 10000.0 * citizen.direction, citizen.y + 0.5))
			draw_arc(point, maxf(12.0, tile_size * 0.55), 0, TAU, 24, Color("F3E8CC"), 2.0)
	if magnifier.x >= 0:
		var position_above: Vector2 = magnifier - Vector2(0, 72)
		draw_circle(position_above, 28, Color("263C3B"))
		draw_rect(Rect2(position_above - Vector2(16, 16), Vector2(32, 32)), Color("E9BA67"), false, 2)

func _bed_style() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("716D88")
	box.border_color = Color("F3E8CC")
	box.set_border_width_all(2)
	return box
