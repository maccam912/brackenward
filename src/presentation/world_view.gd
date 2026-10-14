class_name WorldView
extends Control

signal intent(action: Dictionary)
var tutorial_target: Array = []
var tutorial_gesture: String = ""
var tutorial_highlight_visible: bool = true
var tutorial_animation: float = 0.0
var world: RefCounted
var gestures: GestureState = GestureState.new()
var camera_tile: Vector2 = Vector2(68, 63)
var tile_size: float = 32.0
var focus_offset: Vector2 = Vector2.ZERO:
	set(value):
		if value==focus_offset: return
		var center: Vector2 = camera_center()
		focus_offset=value
		if follow_id==0: camera_tile=center+focus_offset/tile_size
		_update_transform()
var preview_start: Vector2i = Vector2i(74, 54)
var preview_end: Vector2i = Vector2i(77, 55)
var forecast_mask: Array[Vector2i] = []
var preview_visible: bool = false
var preview_definition: String = ""
var preview_resource: String = ""
var preview_line: bool = false
var preview_lodge: bool = false
var rejected_build_tiles: Dictionary = {}
var preview_rotation: int = 0
var selected_id: int = 0
var follow_id: int = 0
var magnifier: Vector2 = Vector2(-100, -100)
var ground: Node2D
var actor_layer: Node2D
var carried_overlay: Node2D
var terrain: TileMapLayer
var actors: Array[Sprite2D] = []
var extra_actors: Dictionary = {}
var extra_tick: int = -1
var extra_world: RefCounted
var extra_wanted: Dictionary = {}
var extra_order_changed: bool = false
var simulation_speed: int = 0
var reduced_motion: bool = false
var high_contrast: bool = false
var diagnostics: FrameDiagnostics
var environment: ColonyEnvironment
var quality: String = "Balanced"
var rooms_overlay: bool = false
var inspected_tiles: Array[Vector2i] = []
var inspected_object: int = 0
var draw_command_us: int = 0
var draw_command_tick: int = 0
var draw_command_speed: int = 0

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
	if world is ColonyWorld: environment=ColonyEnvironment.new(self)
	refresh_terrain()
	for index in range(4): _add_actor(index)
	resized.connect(_update_transform)
	_update_transform()

func _process(delta: float) -> void:
	var started: int = Time.get_ticks_usec()
	if draw_command_us>0:
		if diagnostics!=null: diagnostics.record("map_draw_commands",draw_command_us,draw_command_tick,draw_command_speed)
		draw_command_us=0
	_update_frame(delta)
	if diagnostics!=null and is_visible_in_tree(): diagnostics.record("map_update",Time.get_ticks_usec()-started)

func _update_frame(delta: float) -> void:
	tutorial_animation=0.0 if reduced_motion else fmod(tutorial_animation+delta,1.4)
	var action: Dictionary = gestures.elapse(delta)
	if not action.is_empty():
		_apply_intent(action)
	if world == null:
		return
	while actors.size()<world.citizens.size():
		_add_actor(actors.size())
	var cargo: Dictionary = {}
	if world is ColonyWorld:
		for stack in world.nonempty_stacks():
			if stack.location=="carry": cargo[stack.owner]=true
	for i in range(actors.size()):
		if i>=world.citizens.size(): actors[i].visible=false;continue
		var citizen: Dictionary = world.citizens[i]
		actors[i].set_meta("world_id",citizen.id)
		var point: Vector2 = Vector2(citizen.x + 0.5, citizen.y + 0.5)
		if world is ColonyWorld:
			point += Vector2(citizen.edge_x - citizen.x, citizen.edge_y - citizen.y) * float(citizen.progress) / 10000.0
		else:
			point.x += float(citizen.progress) / 10000.0 * citizen.direction
		actors[i].position = point * 16.0
		if world is ColonyWorld:
			actors[i].visible = not citizen.death_recorded and not citizen.departed and citizen.carried_by == 0 and ColonyRegion.visible(world,citizen)
			if actors[i].visible: actors[i].animate(world,citizen,delta,simulation_speed,cargo.has(citizen.id),reduced_motion)
		if citizen.id == follow_id:
			if world is ColonyWorld and not ColonyRegion.visible(world,citizen): follow_id=0
			else: camera_tile = point
	if world is ColonyWorld:
		_refresh_extra_actors()
		for actor in extra_actors.values():
			if actor is AnimalSprite: actor.animate(world,delta,simulation_speed,reduced_motion)
			else: actor.animate_guest(world,delta,simulation_speed,reduced_motion)
			actor.visible=Rect2(Vector2.ZERO,size).grow(tile_size*2).has_point(tile_to_screen(actor.position/16.0))
		if environment!=null: environment.update(delta)
		if extra_order_changed: _sort_world_nodes()
	_update_transform()
	queue_redraw()
	carried_overlay.queue_redraw()

func _add_actor(index: int) -> void:
	var actor: Sprite2D = CitizenSprite.new() if world is ColonyWorld else Sprite2D.new()
	if not world is ColonyWorld:
		actor.texture=load("res://assets/exported/citizens/%s.svg" % ["mira","oren","tavi","sela"][index%4]);actor.offset=Vector2(0,-8)
	actor_layer.add_child(actor);actors.append(actor)
	extra_order_changed=true

func _refresh_extra_actors() -> void:
	if extra_world!=world:
		for actor in extra_actors.values(): actor.queue_free()
		extra_actors.clear();extra_world=world;extra_tick=-1;extra_order_changed=true
	if extra_tick==world.tick and not extra_order_changed: return
	extra_tick=world.tick;extra_wanted.clear()
	for animal in world.wildlife_state.animals:
		if animal.health>0: _want_extra("wild:%d" % animal.id,animal.definition,animal,"wildlife")
	for animal in world.domestic_state.animals:
		if animal.health>0 and not animal.away: _want_extra("domestic:%d" % animal.id,animal.definition,animal,"domestic")
	for carcass in world.wildlife_state.carcasses:
		if not carcass.done and not carcass.spoiled: _want_extra("carcass:%d" % carcass.id,carcass.definition,carcass,"carcass")
	for visitor in world.opportunity_state.visitors:
		if visitor.state not in ["Waiting","Gone"]: _want_extra("visitor:%d" % visitor.id,"",visitor,"visitor")
	for merchant in world.trade_state.merchants:
		if merchant.state in ["Entering","Trading","Leaving"]:
			_want_extra("merchant:%d" % merchant.id,"",merchant,"merchant")
			_want_extra("pack:%d" % merchant.id,"merchant_pack",merchant,"pack")
	for enemy in world.defense_state.enemies:
		if enemy.state!="Gone": _want_extra("enemy:%d" % enemy.id,"",enemy,"enemy")
	for key in extra_actors.keys():
		if not extra_wanted.has(key): extra_actors[key].queue_free();extra_actors.erase(key);extra_order_changed=true
	if extra_order_changed:
		_sort_world_nodes()

func _sort_world_nodes() -> void:
	# Equal-y ties follow global IDs across actors, interactive props and
	# resource batches partitioned around those IDs.
	var ordered: Array = actor_layer.get_children().filter(func(child:Node)->bool:return not child.is_queued_for_deletion())
	ordered.sort_custom(func(a:Node,b:Node)->bool:return a.get_meta("world_id",0)<b.get_meta("world_id",0) if a.get_meta("world_id",0)!=b.get_meta("world_id",0) else str(a.get_meta("role","resident"))<str(b.get_meta("role","resident")))
	for index in range(ordered.size()): actor_layer.move_child(ordered[index],index)
	extra_order_changed=false

func _want_extra(key: String, kind: String, record: Dictionary, role: String) -> void:
	extra_wanted[key]=true
	if not extra_actors.has(key):
		var actor: Sprite2D = AnimalSprite.new() if not kind.is_empty() else GuestSprite.new()
		actor.name=key.replace(":","_");actor.set_meta("world_id",record.id);actor.set_meta("role",role)
		actor_layer.add_child(actor);extra_actors[key]=actor;extra_order_changed=true
	var actor: Sprite2D = extra_actors[key]
	actor.record=record;actor.role=role
	if actor is AnimalSprite: actor.kind=kind

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
			if not preview_definition.is_empty() or preview_lodge:
				preview_start = preview_end
				fit_build_preview()
		"paint_tap":
			# A new tap starts a new brush stroke, including a one-cell line.
			preview_start = screen_to_tile(action.point)
			preview_end = preview_start
			if not preview_definition.is_empty() or preview_lodge:
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

func camera_center() -> Vector2:
	return camera_tile-focus_offset/tile_size

func center_camera(point: Vector2) -> void:
	camera_tile=point+focus_offset/tile_size
	_update_transform()

func zoom_at(ratio: float, point: Vector2) -> void:
	var anchor: Vector2 = (point - size * 0.5 - focus_offset) / tile_size + camera_tile
	tile_size = clampf(tile_size * ratio, 16.0, 64.0)
	camera_tile = anchor - (point - size * 0.5 - focus_offset) / tile_size
	_update_transform()

func cancel_gesture() -> void:
	gestures.cancel()
	magnifier = Vector2(-100, -100)

func preview_tiles() -> Array[Vector2i]:
	var end: Vector2i = preview_end
	if preview_line:
		if absi(end.x-preview_start.x)>=absi(end.y-preview_start.y): end.y=preview_start.y
		else: end.x=preview_start.x
	var result: Array[Vector2i] = []
	for y in range(mini(preview_start.y, end.y), maxi(preview_start.y, end.y) + 1):
		for x in range(mini(preview_start.x, end.x), maxi(preview_start.x, end.x) + 1):
			result.append(Vector2i(x, y))
	return result

func _update_transform() -> void:
	if ground == null:
		return
	var center: Vector2 = camera_center().clamp(Vector2.ZERO,Vector2.ONE*128)
	camera_tile=center+focus_offset/tile_size
	ground.scale = Vector2.ONE * tile_size / 16.0
	ground.position = size * 0.5 + focus_offset - camera_tile * tile_size
	actor_layer.scale = ground.scale
	actor_layer.position = ground.position

func _draw() -> void:
	var started: int = Time.get_ticks_usec()
	_draw_frame()
	account_draw(Time.get_ticks_usec()-started)

func account_draw(microseconds: int) -> void:
	if draw_command_us==0:
		draw_command_tick=world.tick if world!=null else 0;draw_command_speed=simulation_speed
	draw_command_us+=microseconds

func _draw_frame() -> void:
	if world==null: return
	if not world is ColonyWorld:
		_draw_fixture();_draw_feedback(self)

func _draw_feedback(painter: CanvasItem) -> void:
	if world==null: return
	var flooded: Array = world.weather_state.flooded if world is ColonyWorld else []
	for tile in flooded + forecast_mask:
		var point: Vector2 = tile_to_screen(Vector2(tile))
		if not Rect2(Vector2.ZERO,size).grow(tile_size).has_point(point): continue
		painter.draw_rect(Rect2(point,Vector2.ONE*tile_size),Color(0.25,0.52,0.65,0.35))
		painter.draw_line(point+Vector2(0,tile_size),point+Vector2(tile_size,0),Color("D8E8DC"),2)
	for tile in rejected_build_tiles:
		painter.draw_rect(Rect2(tile_to_screen(Vector2(tile)),Vector2.ONE*tile_size),Color(0.7,0.3,0.3,0.35))
		painter.draw_rect(Rect2(tile_to_screen(Vector2(tile)),Vector2.ONE*tile_size),Color("B44F4A"),false,2)
	for tile in world.designations:
		painter.draw_rect(Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size), Color(0.91, 0.73, 0.4, 0.35))
		painter.draw_rect(Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size), Color("F3E8CC"), false, 2)
	if preview_visible:
		for tile in preview_tiles():
			var water: bool = world.is_water(tile) if world is ColonyWorld else PrototypeWorld.is_water(tile)
			var color: Color = Color("B44F4A") if rejected_build_tiles.has(tile) or (preview_resource.is_empty() and not preview_line and water) else Color("E9BA67")
			color.a = 0.3
			var rectangle: Rect2 = Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size)
			painter.draw_rect(rectangle, color)
			painter.draw_rect(rectangle, Color("263C3B"), false, 2)
			if high_contrast:
				painter.draw_rect(rectangle.grow(-2),Color.WHITE,false,2)
				if rejected_build_tiles.has(tile):
					painter.draw_line(rectangle.position,rectangle.end,Color.BLACK,4);painter.draw_line(rectangle.position+Vector2(rectangle.size.x,0),rectangle.position+Vector2(0,rectangle.size.y),Color.BLACK,4)
	if preview_visible and preview_lodge and world is ColonyWorld:
		for blueprint in ColonyConstruction.lodge(preview_start):
			for tile in world.footprint(blueprint): painter.draw_rect(Rect2(tile_to_screen(Vector2(tile))+Vector2.ONE*2,Vector2.ONE*(tile_size-4)),Color("F3E8CC"),false,2)
	if preview_visible and not preview_resource.is_empty() and world is ColonyWorld:
		for resource in world.gather_targets(preview_resource,preview_tiles()):
			_draw_gather_mark(Vector2(resource.x,resource.y),Color("F3E8CC"),painter)
	for citizen in world.citizens:
		if citizen.id == selected_id:
			var point: Vector2 = tile_to_screen(citizen_point(citizen))
			if high_contrast: painter.draw_arc(point,maxf(12.0,tile_size*0.55),0,TAU,24,Color.BLACK,7.0)
			painter.draw_arc(point, maxf(12.0, tile_size * 0.55), 0, TAU, 24, Color("F3E8CC"), 2.0)
	if tutorial_highlight_visible and tutorial_target.size()==2:
		var center: Vector2 = tile_to_screen(Vector2(tutorial_target[0]+0.5,tutorial_target[1]+0.5))
		var phase: float = tutorial_animation/1.4
		painter.draw_arc(center,tile_size*(0.58+phase*0.28),0,TAU,32,Color(0.91,0.73,0.4,1.0-phase*0.7),3)
		var hand: Vector2 = center+Vector2(0,-tile_size*(0.9+0.12*sin(phase*TAU)))
		painter.draw_circle(hand,5,Color("F3E8CC"))
		painter.draw_line(hand,hand+Vector2(0,10),Color("263C3B"),3)
		if tutorial_gesture.begins_with("Drag"):
			painter.draw_line(center-Vector2(tile_size*0.4,0),center+Vector2(tile_size*(phase-0.4),0),Color("F3E8CC"),3)
	if magnifier.x >= 0:
		var position_above: Vector2 = magnifier - Vector2(0, 72)
		painter.draw_circle(position_above, 28, Color("263C3B"))
		painter.draw_rect(Rect2(position_above - Vector2(16, 16), Vector2(32, 32)), Color("E9BA67"), false, 2)

func _draw_gather_mark(tile: Vector2,color: Color,painter: CanvasItem = null) -> void:
	if painter==null: painter=self
	var point: Vector2 = tile_to_screen(Vector2(tile)+Vector2(0.5,0.5))
	painter.draw_rect(Rect2(point-Vector2.ONE*tile_size*0.45,Vector2.ONE*tile_size*0.9),color,false,2)
	var badge: Vector2 = point+Vector2(tile_size*0.25,-tile_size*0.35)
	painter.draw_circle(badge,7,Color("263C3B"))
	painter.draw_line(badge-Vector2(3,0),badge+Vector2(-1,3),color,2)
	painter.draw_line(badge+Vector2(-1,3),badge+Vector2(4,-3),color,2)

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
	if preview_lodge:
		preview_start.x=clampi(preview_start.x,0,120);preview_start.y=clampi(preview_start.y,0,122)
		preview_end=preview_start+Vector2i(7,5);return
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

func _draw_carried_items() -> void:
	if not world is ColonyWorld:
		return
	var started: int = Time.get_ticks_usec()
	for citizen in world.citizens:
		if citizen.carrying_patient > 0:
			var point: Vector2 = tile_to_screen(citizen_point(citizen))+Vector2(0,-tile_size*0.7)
			carried_overlay.draw_rect(Rect2(point-Vector2(tile_size*0.35,5),Vector2(tile_size*0.7,10)),Color("F3E8CC"))
	for body in world.care_state.bodies:
		if body.buried: continue
		var point: Vector2 = tile_to_screen(Vector2(body.x+0.5,body.y+0.5))
		carried_overlay.draw_rect(Rect2(point-Vector2(tile_size*0.4,5),Vector2(tile_size*0.8,10)),Color("716D88"))
		carried_overlay.draw_line(point-Vector2(0,10),point+Vector2(0,10),Color("F3E8CC"),2)
	for stack in world.nonempty_stacks():
		if stack.count <= 0 or stack.location != "carry":
			continue
		var citizen: Dictionary = world.find(world.citizens,stack.owner)
		var point: Vector2 = tile_to_screen(citizen_point(citizen))+Vector2(tile_size*0.48,-tile_size*0.25)
		if not Rect2(Vector2.ZERO,size).grow(tile_size).has_point(point):
			continue
		var tier: int = EnvironmentArt.pile_tier(stack.count,world.definitions.items[stack.item].stack_limit)
		var scale: float = tile_size/32.0
		carried_overlay.draw_texture_rect_region(EnvironmentArt.ATLAS,Rect2(point-Vector2(8,16)*scale,Vector2(16,24)*scale),EnvironmentArt.rectangle("item/%s/%d" % [stack.item,tier]))
		if citizen.id==selected_id: carried_overlay.draw_string(get_theme_default_font(),point+Vector2(9,5),str(stack.count),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("F3E8CC"))
	account_draw(Time.get_ticks_usec()-started)

func refresh_terrain() -> void:
	if terrain == null: return
	if environment!=null:
		environment.refresh_terrain();return
	for y in range(128):
		for x in range(128):
			var point: Vector2i = Vector2i(x,y)
			var cell: int = (x*17+y*13)%2
			if world is ColonyWorld and world.generator_version > 0:
				if world.soil_fertility(point) == 750: cell = 2
				if world.is_water(point): cell = 3
				elif world.terrain_state.paths.has(point): cell = 4
			else:
				if x < 32 or x > 95: cell = 2
				if PrototypeWorld.is_water(point): cell = 3
				elif x == 66 or y in [63,64]: cell = 4
				if x in range(74,82) and y in range(54,62): cell = 0
			terrain.set_cell(point,0,Vector2i(cell,0))
