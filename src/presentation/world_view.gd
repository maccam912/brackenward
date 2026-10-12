class_name WorldView
extends Control

signal intent(action: Dictionary)
var world: RefCounted
var gestures: GestureState = GestureState.new()
var camera_tile: Vector2 = Vector2(68, 63)
var tile_size: float = 32.0
var focus_offset: Vector2 = Vector2.ZERO
var preview_start: Vector2i = Vector2i(74, 54)
var preview_end: Vector2i = Vector2i(77, 55)
var forecast_mask: Array[Vector2i] = []
var preview_visible: bool = false
var preview_definition: String = ""
var preview_resource: String = ""
var preview_rotation: int = 0
var selected_id: int = 0
var follow_id: int = 0
var magnifier: Vector2 = Vector2(-100, -100)
var ground: Node2D
var actor_layer: Node2D
var carried_overlay: Node2D
var terrain: TileMapLayer
var actors: Array[Sprite2D] = []

func setup(state: RefCounted) -> void:
	world = state
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	ground = Node2D.new()
	ground.y_sort_enabled = true
	ground.show_behind_parent = true
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
	actor_layer = Node2D.new()
	actor_layer.y_sort_enabled = true
	add_child(actor_layer)
	carried_overlay = Node2D.new()
	add_child(carried_overlay)
	carried_overlay.draw.connect(_draw_carried_items)
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
		actor_layer.add_child(actor)
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
		if world is ColonyWorld:
			point += Vector2(citizen.edge_x - citizen.x, citizen.edge_y - citizen.y) * float(citizen.progress) / 10000.0
		else:
			point.x += float(citizen.progress) / 10000.0 * citizen.direction
		actors[i].position = point * 16.0
		if world is ColonyWorld:
			actors[i].visible = not citizen.death_recorded and not citizen.departed and citizen.carried_by == 0
			actors[i].rotation = PI*0.5 if citizen.downed else 0.0
			actors[i].modulate = Color("E9BA67") if citizen.health < 50 else Color.WHITE
		if citizen.id == follow_id:
			camera_tile = point
	_update_transform()
	queue_redraw()
	carried_overlay.queue_redraw()

func _gui_input(event: InputEvent) -> void:
	# Godot also emits a device -1 mouse event for a touch. Track the real
	# touchscreen pointer once; ordinary Controls still use mouse emulation.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == -1:
		return
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
			if not preview_definition.is_empty():
				preview_start = preview_end
				fit_build_preview()
		"paint_tap":
			preview_end = screen_to_tile(action.point)
			if not preview_definition.is_empty():
				preview_start = preview_end
				fit_build_preview()
		"select", "chooser":
			action["tile"] = screen_to_tile(action.point)
			intent.emit(action)
		"magnifier":
			magnifier = action.point
			intent.emit({"kind": "notice", "text": "Drag to adjust. Confirm stays separate."})
	_update_transform()
	queue_redraw()

func screen_to_tile(point: Vector2) -> Vector2i:
	var tile: Vector2 = (point - size * 0.5 - focus_offset) / tile_size + camera_tile
	return Vector2i(clampi(int(floor(tile.x)), 0, 127), clampi(int(floor(tile.y)), 0, 127))

func tile_to_screen(tile: Vector2) -> Vector2:
	return (tile - camera_tile) * tile_size + size * 0.5 + focus_offset

func zoom_at(ratio: float, point: Vector2) -> void:
	var anchor: Vector2 = (point - size * 0.5 - focus_offset) / tile_size + camera_tile
	tile_size = clampf(tile_size * ratio, 16.0, 64.0)
	camera_tile = anchor - (point - size * 0.5 - focus_offset) / tile_size
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
	ground.position = size * 0.5 + focus_offset - camera_tile * tile_size
	actor_layer.scale = ground.scale
	actor_layer.position = ground.position

func _draw() -> void:
	if world == null:
		return
	# Fixture landmarks are retained only for the M0 regression scene.
	if world is ColonyWorld:
		_draw_colony()
	else:
		_draw_fixture()
	var flooded: Array = world.weather_state.flooded if world is ColonyWorld else []
	for tile in flooded + forecast_mask:
		var point: Vector2 = tile_to_screen(Vector2(tile))
		if not Rect2(Vector2.ZERO,size).grow(tile_size).has_point(point): continue
		draw_rect(Rect2(point,Vector2.ONE*tile_size),Color(0.25,0.52,0.65,0.35))
		draw_line(point+Vector2(0,tile_size),point+Vector2(tile_size,0),Color("D8E8DC"),2)
	for tile in world.designations:
		draw_rect(Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size), Color(0.91, 0.73, 0.4, 0.35))
		draw_rect(Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size), Color("F3E8CC"), false, 2)
	if preview_visible:
		for tile in preview_tiles():
			var color: Color = Color("B44F4A") if preview_resource.is_empty() and PrototypeWorld.is_water(tile) else Color("E9BA67")
			color.a = 0.3
			var rectangle: Rect2 = Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size)
			draw_rect(rectangle, color)
			draw_rect(rectangle, Color("263C3B"), false, 2)
	if preview_visible and not preview_resource.is_empty() and world is ColonyWorld:
		for resource in world.gather_targets(preview_resource,preview_tiles()):
			_draw_gather_mark(Vector2i(resource.x,resource.y),Color("F3E8CC"))
	for citizen in world.citizens:
		if citizen.id == selected_id:
			var point: Vector2 = tile_to_screen(citizen_point(citizen))
			draw_arc(point, maxf(12.0, tile_size * 0.55), 0, TAU, 24, Color("F3E8CC"), 2.0)
	if magnifier.x >= 0:
		var position_above: Vector2 = magnifier - Vector2(0, 72)
		draw_circle(position_above, 28, Color("263C3B"))
		draw_rect(Rect2(position_above - Vector2(16, 16), Vector2(32, 32)), Color("E9BA67"), false, 2)

func _draw_gather_mark(tile: Vector2i,color: Color) -> void:
	var point: Vector2 = tile_to_screen(Vector2(tile)+Vector2(0.5,0.5))
	draw_rect(Rect2(point-Vector2.ONE*tile_size*0.45,Vector2.ONE*tile_size*0.9),color,false,2)
	var badge: Vector2 = point+Vector2(tile_size*0.25,-tile_size*0.35)
	draw_circle(badge,7,Color("263C3B"))
	draw_line(badge-Vector2(3,0),badge+Vector2(-1,3),color,2)
	draw_line(badge+Vector2(-1,3),badge+Vector2(4,-3),color,2)

func _bed_style() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("716D88")
	box.border_color = Color("F3E8CC")
	box.set_border_width_all(2)
	return box

func _draw_fixture() -> void:
	for point in [Vector2(62, 59), Vector2(64, 59), Vector2(62, 61), Vector2(64, 61)]:
		draw_style_box(_bed_style(), Rect2(tile_to_screen(point), Vector2(tile_size, tile_size * 1.6)))
	var hearth: Vector2 = tile_to_screen(Vector2(70.5, 62.5))
	draw_circle(hearth, tile_size * 0.45, Color("716D88"))
	draw_colored_polygon(PackedVector2Array([hearth + Vector2(-8, 5), hearth + Vector2(0, -13), hearth + Vector2(8, 5)]), Color("E9BA67"))
	draw_rect(Rect2(tile_to_screen(Vector2(66, 63)), Vector2(tile_size * 2, tile_size)), Color("B96C50"))

func fit_build_preview() -> void:
	if preview_definition.is_empty() or not world is ColonyWorld:
		return
	var definition: Dictionary = world.definitions.buildings[preview_definition]
	var footprint_size: Vector2i = Vector2i(definition.width, definition.height) if preview_rotation % 2 == 0 else Vector2i(definition.height, definition.width)
	preview_start.x = clampi(preview_start.x, 0, 128 - footprint_size.x)
	preview_start.y = clampi(preview_start.y, 0, 128 - footprint_size.y)
	preview_end = preview_start + footprint_size - Vector2i.ONE

func citizen_point(citizen: Dictionary) -> Vector2:
	var point: Vector2 = Vector2(citizen.x + 0.5, citizen.y + 0.5)
	if world is ColonyWorld:
		point += Vector2(citizen.edge_x - citizen.x, citizen.edge_y - citizen.y) * float(citizen.progress) / 10000.0
	else:
		point.x += float(citizen.progress) / 10000.0 * citizen.direction
	return point

func _draw_colony() -> void:
	for field in world.fields:
		var rectangle: Rect2 = Rect2(tile_to_screen(Vector2(field.x,field.y)),Vector2.ONE*tile_size)
		draw_rect(rectangle.grow(-1),Color("B96C50") if field.prepared else Color(0.72,0.42,0.31,0.25))
		if field.planted:
			var radius: float = tile_size * (0.08+0.22*float(field.growth)/world.definitions.crops[field.crop].growth)
			for offset in [Vector2(0.25,0.25),Vector2(0.75,0.25),Vector2(0.25,0.75),Vector2(0.75,0.75)]:
				draw_circle(rectangle.position+offset*tile_size,radius,Color("E9BA67") if field.ripe_tick>0 else Color("375749"))
	for resource in world.resources:
		if resource.remaining == 0:
			continue
		var point: Vector2 = tile_to_screen(Vector2(resource.x + 0.5, resource.y + 0.5))
		if not Rect2(Vector2.ZERO, size).grow(tile_size).has_point(point):
			continue
		if resource.definition == "tree":
			draw_rect(Rect2(point + Vector2(-tile_size * 0.1, 0), Vector2(tile_size * 0.2, tile_size * 0.4)), Color("B96C50"))
			draw_colored_polygon(PackedVector2Array([point + Vector2(-tile_size * 0.4, tile_size * 0.1), point + Vector2(0, -tile_size * 0.7), point + Vector2(tile_size * 0.4, tile_size * 0.1)]), Color("263C3B"))
		elif resource.definition == "stone_node":
			draw_circle(point, tile_size * 0.4, Color("716D88"))
			draw_line(point - Vector2(8, 2), point + Vector2(4, -8), Color("F3E8CC"), 2)
		else:
			draw_circle(point, tile_size * 0.32, Color("375749"))
			var color: Color = Color("B96C50") if resource.definition == "berry_bush" else Color("F3E8CC")
			for offset in [Vector2(-6, -2), Vector2(4, -4), Vector2(0, 5)]:
				draw_circle(point + offset * tile_size / 32, tile_size * 0.07, color)
	for structure in world.structures:
		var tiles: Array[Vector2i] = world.footprint(structure)
		var rectangle: Rect2 = Rect2(tile_to_screen(Vector2(tiles[0])), Vector2(tiles[-1] - tiles[0] + Vector2i.ONE) * tile_size)
		if not rectangle.intersects(Rect2(Vector2.ZERO, size)):
			continue
		var color: Color = Color("B96C50")
		if structure.definition in ["bed", "bedroll"]:
			draw_style_box(_bed_style(), rectangle.grow(-tile_size * 0.12))
			draw_rect(Rect2(rectangle.position + Vector2.ONE * tile_size * 0.15, Vector2.ONE * tile_size * 0.45), Color("F3E8CC"))
		elif structure.definition == "hearth":
			var center: Vector2 = rectangle.get_center()
			draw_circle(center, tile_size * 0.6, Color("716D88"))
			draw_colored_polygon(PackedVector2Array([center + Vector2(-10, 8), center + Vector2(0, -16), center + Vector2(10, 8)]), Color("E9BA67"))
		else:
			draw_rect(rectangle.grow(-tile_size * 0.1), color)
			draw_rect(rectangle.grow(-tile_size * 0.1), Color("263C3B"), false, 3)
	for job in world.jobs:
		if job.state in ["Complete", "Canceled"]:
			continue
		if job.kind == "gather":
			_draw_gather_mark(Vector2i(job.x,job.y),Color("E9BA67"))
		if job.kind == "build":
			for tile in world.footprint(job):
				var rectangle: Rect2 = Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size)
				draw_rect(rectangle, Color(0.91, 0.73, 0.4, 0.25))
				draw_rect(rectangle.grow(-2), Color("E9BA67"), false, 2)
			var point: Vector2 = tile_to_screen(Vector2(job.x, job.y))
			draw_rect(Rect2(point, Vector2(tile_size * float(job.work) / job.required, 4)), Color("F3E8CC"))
	for stack in world.stacks:
		if stack.count <= 0:
			continue
		if stack.location == "carry":
			continue
		var point: Vector2 = tile_to_screen(Vector2(stack.x + 0.5, stack.y + 0.5))
		if stack.location == "store":
			continue # Totals remain inspectable; loose/carried/escrow stacks are visible.
		if not Rect2(Vector2.ZERO, size).grow(tile_size).has_point(point):
			continue
		var color: Color = Color("B96C50") if stack.item == "wood" else (Color("E9BA67") if stack.item == "meal" else Color("716D88"))
		draw_rect(Rect2(point - Vector2(8, 8), Vector2(16, 16)), color)
		draw_rect(Rect2(point - Vector2(8, 8), Vector2(16, 16)), Color("263C3B"), false, 2)
		draw_string(get_theme_default_font(), point + Vector2(9, 5), str(stack.count), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("F3E8CC"))

func _draw_carried_items() -> void:
	if not world is ColonyWorld:
		return
	for citizen in world.citizens:
		if citizen.carrying_patient > 0:
			var point: Vector2 = tile_to_screen(citizen_point(citizen))+Vector2(0,-tile_size*0.7)
			carried_overlay.draw_rect(Rect2(point-Vector2(tile_size*0.35,5),Vector2(tile_size*0.7,10)),Color("F3E8CC"))
	for body in world.care_state.bodies:
		if body.buried: continue
		var point: Vector2 = tile_to_screen(Vector2(body.x+0.5,body.y+0.5))
		carried_overlay.draw_rect(Rect2(point-Vector2(tile_size*0.4,5),Vector2(tile_size*0.8,10)),Color("716D88"))
		carried_overlay.draw_line(point-Vector2(0,10),point+Vector2(0,10),Color("F3E8CC"),2)
	for stack in world.stacks:
		if stack.count <= 0 or stack.location != "carry":
			continue
		var citizen: Dictionary = world.find(world.citizens,stack.owner)
		var point: Vector2 = tile_to_screen(citizen_point(citizen))+Vector2(tile_size*0.48,-tile_size*0.25)
		if not Rect2(Vector2.ZERO,size).grow(tile_size).has_point(point):
			continue
		var color: Color = Color("B96C50") if stack.item == "wood" else (Color("E9BA67") if stack.item == "meal" else Color("716D88"))
		carried_overlay.draw_rect(Rect2(point-Vector2(8,8),Vector2(16,16)),color)
		carried_overlay.draw_rect(Rect2(point-Vector2(8,8),Vector2(16,16)),Color("263C3B"),false,2)
		carried_overlay.draw_string(get_theme_default_font(),point+Vector2(9,5),str(stack.count),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("F3E8CC"))
