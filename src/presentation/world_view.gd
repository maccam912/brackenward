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
	refresh_terrain()
	for index in range(4): _add_actor(index)
	resized.connect(_update_transform)
	_update_transform()

func _process(delta: float) -> void:
	var started: int = Time.get_ticks_usec()
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
			if stack.location=="carried": cargo[stack.owner]=true
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
		# Godot resolves equal-y ties by tree order. Restore stable global IDs
		# after pooling rather than depending on which actor appeared first.
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
	if diagnostics!=null: diagnostics.record("map_draw_commands",Time.get_ticks_usec()-started)

func _draw_frame() -> void:
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
	for tile in rejected_build_tiles:
		draw_rect(Rect2(tile_to_screen(Vector2(tile)),Vector2.ONE*tile_size),Color(0.7,0.3,0.3,0.35))
		draw_rect(Rect2(tile_to_screen(Vector2(tile)),Vector2.ONE*tile_size),Color("B44F4A"),false,2)
	for tile in world.designations:
		draw_rect(Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size), Color(0.91, 0.73, 0.4, 0.35))
		draw_rect(Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size), Color("F3E8CC"), false, 2)
	if preview_visible:
		for tile in preview_tiles():
			var water: bool = world.is_water(tile) if world is ColonyWorld else PrototypeWorld.is_water(tile)
			var color: Color = Color("B44F4A") if rejected_build_tiles.has(tile) or (preview_resource.is_empty() and not preview_line and water) else Color("E9BA67")
			color.a = 0.3
			var rectangle: Rect2 = Rect2(tile_to_screen(Vector2(tile)), Vector2.ONE * tile_size)
			draw_rect(rectangle, color)
			draw_rect(rectangle, Color("263C3B"), false, 2)
			if high_contrast:
				draw_rect(rectangle.grow(-2),Color.WHITE,false,2)
				if rejected_build_tiles.has(tile):
					draw_line(rectangle.position,rectangle.end,Color.BLACK,4);draw_line(rectangle.position+Vector2(rectangle.size.x,0),rectangle.position+Vector2(0,rectangle.size.y),Color.BLACK,4)
	if preview_visible and preview_lodge and world is ColonyWorld:
		for blueprint in ColonyConstruction.lodge(preview_start):
			for tile in world.footprint(blueprint): draw_rect(Rect2(tile_to_screen(Vector2(tile))+Vector2.ONE*2,Vector2.ONE*(tile_size-4)),Color("F3E8CC"),false,2)
	if preview_visible and not preview_resource.is_empty() and world is ColonyWorld:
		for resource in world.gather_targets(preview_resource,preview_tiles()):
			_draw_gather_mark(Vector2i(resource.x,resource.y),Color("F3E8CC"))
	for citizen in world.citizens:
		if citizen.id == selected_id:
			var point: Vector2 = tile_to_screen(citizen_point(citizen))
			if high_contrast: draw_arc(point,maxf(12.0,tile_size*0.55),0,TAU,24,Color.BLACK,7.0)
			draw_arc(point, maxf(12.0, tile_size * 0.55), 0, TAU, 24, Color("F3E8CC"), 2.0)
	if tutorial_highlight_visible and tutorial_target.size()==2:
		var center: Vector2 = tile_to_screen(Vector2(tutorial_target[0]+0.5,tutorial_target[1]+0.5))
		var phase: float = tutorial_animation/1.4
		draw_arc(center,tile_size*(0.58+phase*0.28),0,TAU,32,Color(0.91,0.73,0.4,1.0-phase*0.7),3)
		var hand: Vector2 = center+Vector2(0,-tile_size*(0.9+0.12*sin(phase*TAU)))
		draw_circle(hand,5,Color("F3E8CC"))
		draw_line(hand,hand+Vector2(0,10),Color("263C3B"),3)
		if tutorial_gesture.begins_with("Drag"):
			draw_line(center-Vector2(tile_size*0.4,0),center+Vector2(tile_size*(phase-0.4),0),Color("F3E8CC"),3)
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

func _draw_colony() -> void:
	for person in world.citizens:
		var task: Dictionary = world.find(world.jobs,person.job)
		if task.get("kind")=="extinguish" and task.memo.phase in ["carry","apply"]:
			var point: Vector2 = tile_to_screen(citizen_point(person))
			draw_rect(Rect2(point+Vector2(0.2,0.1)*tile_size,Vector2(0.2,0.25)*tile_size),Color("7096B4"))
	for pen in world.domestic_state.pens:
		for tile in pen.tiles:
			var point: Vector2 = tile_to_screen(Vector2(tile))
			if Rect2(Vector2.ZERO,size).grow(tile_size).has_point(point): draw_rect(Rect2(point,Vector2.ONE*tile_size),Color(0.7,0.7,0.45,0.12))
	for source in ColonyDanger.sources(world):
		var center: Vector2 = tile_to_screen(Vector2(source)+Vector2(0.5,0.5))
		var radius: float = tile_size*8
		draw_polyline(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0),center+Vector2(0,-radius)]),Color("E9BA67"),2)
	for task in world.unfinished_jobs():
		if task.kind=="hunt":
			var animal: Dictionary = world.find(world.wildlife_state.animals,task.target)
			if not animal.is_empty() and animal.health>0: _draw_gather_mark(Vector2i(animal.x,animal.y),Color("E9BA67"))
	for field in world.fields:
		var rectangle: Rect2 = Rect2(tile_to_screen(Vector2(field.x,field.y)),Vector2.ONE*tile_size)
		draw_rect(rectangle.grow(-1),Color("B96C50") if field.prepared else Color(0.72,0.42,0.31,0.25))
		if field.planted:
			var radius: float = tile_size * (0.08+0.22*float(field.growth)/world.definitions.crops[field.crop].growth)
			for offset in [Vector2(0.25,0.25),Vector2(0.75,0.25),Vector2(0.25,0.75),Vector2(0.75,0.75)]:
				draw_circle(rectangle.position+offset*tile_size,radius,Color("E9BA67") if field.ripe_tick>0 else Color("375749"))
	for resource in world.resources:
		var point: Vector2 = tile_to_screen(Vector2(resource.x+0.5,resource.y+0.5))
		if not Rect2(Vector2.ZERO,size).grow(tile_size).has_point(point): continue
		if resource.remaining == 0:
			if resource.definition == "tree":
				var state: Dictionary = ColonyNature.tree(world,resource.id)
				draw_circle(point,tile_size*0.12,Color("B96C50"))
				if state.planted:
					draw_line(point,point-Vector2(0,tile_size*0.4),Color("375749"),3)
					draw_circle(point-Vector2(0,tile_size*0.35),tile_size*0.15,Color("77915A"))
			continue
		if resource.definition == "tree":
			draw_rect(Rect2(point + Vector2(-tile_size * 0.1, 0), Vector2(tile_size * 0.2, tile_size * 0.4)), Color("B96C50"))
			draw_colored_polygon(PackedVector2Array([point + Vector2(-tile_size * 0.4, tile_size * 0.1), point + Vector2(0, -tile_size * 0.7), point + Vector2(tile_size * 0.4, tile_size * 0.1)]), Color("263C3B"))
		elif resource.definition in ["stone_node","clay_bank","iron_seam"]:
			draw_circle(point, tile_size * 0.4, Color("B96C50") if resource.definition == "clay_bank" else (Color("263C3B") if resource.definition == "iron_seam" else Color("716D88")))
			draw_line(point - Vector2(8, 2), point + Vector2(4, -8), Color("F3E8CC"), 2)
		else:
			draw_circle(point, tile_size * 0.32, Color("375749"))
			var color: Color = Color("B96C50") if resource.definition == "berry_bush" else Color("F3E8CC")
			for offset in [Vector2(-6, -2), Vector2(4, -4), Vector2(0, 5)]:
				draw_circle(point + offset * tile_size / 32, tile_size * 0.07, color)
	for structure in world.structures:
		if structure.health<=0:
			var ruin: Vector2 = tile_to_screen(Vector2(structure.x+0.5,structure.y+0.5))
			draw_rect(Rect2(ruin-Vector2(tile_size*0.3,tile_size*0.1),Vector2(tile_size*0.6,tile_size*0.2)),Color("716D88"));continue
		var tiles: Array[Vector2i] = world.footprint(structure)
		var rectangle: Rect2 = Rect2(tile_to_screen(Vector2(tiles[0])), Vector2(tiles[-1] - tiles[0] + Vector2i.ONE) * tile_size)
		if structure.definition=="supply_cart":
			for task in world.jobs:
				if task.kind=="cart_move" and task.target==structure.id and task.worker>0 and task.memo.phase=="push" and task.state=="Working":
					var worker: Dictionary = world.find(world.citizens,task.worker)
					rectangle.position += Vector2(worker.edge_x-worker.x,worker.edge_y-worker.y)*tile_size*float(worker.progress)/10000.0
		if not rectangle.intersects(Rect2(Vector2.ZERO, size)):
			continue
		var color: Color = Color("B96C50")
		if structure.definition in ["bed", "bedroll"]:
			draw_style_box(_bed_style(), rectangle.grow(-tile_size * 0.12))
			draw_rect(Rect2(rectangle.position + Vector2.ONE * tile_size * 0.15, Vector2.ONE * tile_size * 0.45), Color("F3E8CC"))
		elif structure.definition == "supply_cart":
			_draw_cart(rectangle)
		elif structure.definition == "hearth":
			var center: Vector2 = rectangle.get_center()
			draw_circle(center, tile_size * 0.6, Color("716D88"))
			draw_colored_polygon(PackedVector2Array([center + Vector2(-10, 8), center + Vector2(0, -16), center + Vector2(10, 8)]), Color("E9BA67"))
		else:
			draw_rect(rectangle.grow(-tile_size * 0.1), color)
			draw_rect(rectangle.grow(-tile_size * 0.1), Color("263C3B"), false, 3)
	for job in world.unfinished_jobs():
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
	for job in world.unfinished_jobs():
		if job.kind=="move_furniture" and job.state not in ["Complete","Canceled"]:
			for tile in ColonyMaintenance.move_footprint(world,job): draw_rect(Rect2(tile_to_screen(Vector2(tile)),Vector2.ONE*tile_size).grow(-1),Color("E9BA67"),false,2)
	for stack in world.nonempty_stacks():
		if stack.count <= 0:
			continue
		if stack.location == "expedition_cargo" and world.find(world.region_state.trips,stack.owner).get("state") not in ["Preparing","Ready","Unloading"]: continue
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

	for fire in ColonyFire.active(world):
		for tile in ColonyFire.footprint(world,fire):
			var center: Vector2 = tile_to_screen(Vector2(tile)+Vector2(0.5,0.5))
			draw_colored_polygon(PackedVector2Array([center+Vector2(-0.3,0.3)*tile_size,center+Vector2(0,-0.45)*tile_size,center+Vector2(0.3,0.3)*tile_size]),Color("E9BA67"))


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
	for stack in world.nonempty_stacks():
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

func refresh_terrain() -> void:
	if terrain == null: return
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

func _draw_cart(rectangle: Rect2) -> void:
	var body: Rect2 = rectangle.grow(-tile_size*0.12)
	var rewards: Array = world.charter_state.appearances
	if rewards.has("provision"):
		draw_rect(rectangle.grow(tile_size*0.18),Color("716D88"),false,maxf(1,tile_size*0.09))
		for offset in [Vector2(-0.25,-0.25),Vector2(1.05,-0.25),Vector2(-0.25,1.05),Vector2(1.05,1.05)]:
			draw_circle(rectangle.position+rectangle.size*offset,tile_size*0.12,Color("E9BA67"))
	draw_rect(body,Color("B96C50"))
	draw_rect(body,Color("263C3B"),false,maxf(1,tile_size*0.08))
	for x in [body.position.x,body.end.x]:
		draw_circle(Vector2(x,body.end.y-tile_size*0.12),tile_size*0.17,Color("263C3B"))
	if rewards.has("shelter"):
		var pole: Vector2 = body.position+Vector2(tile_size*0.15,0)
		draw_line(pole,pole-Vector2(0,tile_size*0.9),Color("263C3B"),maxf(1,tile_size*0.06))
		var banner: Rect2 = Rect2(pole-Vector2(0,tile_size*0.85),Vector2(tile_size*1.6,tile_size*0.48))
		draw_rect(banner,Color("F3E8CC"))
		draw_string(ThemeDB.fallback_font,banner.position+Vector2(3,banner.size.y*0.76),ColonyChronicle.display_name(world,0),HORIZONTAL_ALIGNMENT_LEFT,banner.size.x-6,maxi(8,int(tile_size*0.25)),Color("263C3B"))
	if rewards.has("connection"):
		var plaque: Rect2 = Rect2(body.get_center()-Vector2(tile_size*0.35,tile_size*0.22),Vector2(tile_size*0.7,tile_size*0.44))
		draw_rect(plaque,Color("F3E8CC"))
		draw_line(plaque.position+plaque.size*Vector2(0.15,0.75),plaque.position+plaque.size*Vector2(0.85,0.25),Color("5F98AC"),maxf(1,tile_size*0.07))
		for end in [Vector2(0.15,0.75),Vector2(0.85,0.25)]: draw_circle(plaque.position+plaque.size*end,tile_size*0.06,Color("375749"))
	if rewards.has("refuge"):
		var sign: Rect2 = Rect2(body.end-Vector2(tile_size*0.4,tile_size*0.4),Vector2(tile_size*0.55,tile_size*0.5))
		draw_rect(sign,Color("77915A"))
		var center: Vector2 = sign.get_center()
		draw_colored_polygon(PackedVector2Array([center+Vector2(-0.2,0)*tile_size,center+Vector2(0,-0.18)*tile_size,center+Vector2(0.2,0)*tile_size]),Color("F3E8CC"))
		draw_rect(Rect2(center,Vector2(tile_size*0.13,tile_size*0.16)).grow(-0.5),Color("F3E8CC"))
