class_name GameSession
extends Control

var world: RefCounted = ColonyWorld.new(ColonyCatalog.load_data(), Crypto.new().generate_random_bytes(16).hex_encode())
var runner: SimRunner = SimRunner.new(world)
var store: PrototypeStore = ColonyStore.new()
var view: WorldView
var content: Control
var status: PanelContainer
var clock_label: Label
var notice_label: Label
var nav: GridContainer
var speeds: HBoxContainer
var map_tools: VBoxContainer
var placement: VBoxContainer
var preview_label: Label
var confirm_button: Button
var placement_nudges: HBoxContainer
var placement_actions: HBoxContainer
var placement_wide_row: HBoxContainer
var sheet: PanelContainer
var sheet_body: VBoxContainer
var sheet_feedback: Label
var inspector: PanelContainer
var selected: int = 0
var sheet_name: String = ""
var text_scale: float = 1.0
var left_handed: bool = false
var logical_scale: float = 1.0
var notice: String = "Four travelers. A ruined wayhouse. Make a place to stay."
var submitted_command: int = 0
var backgrounded: bool = false
var last_saved_tick: int = 1800
var autosave_elapsed: float = 0.0
var journal_elapsed: float = 0.0
var file_dialog: FileDialog
var catalog_strings: Dictionary = {}
var seen_care_alert: int = -1
var epilogue_session: String = ""
var awaiting_first_colony: bool = false
var creation_thread: Thread
var native_storage: Object
var document_request: int = 0
var exporting: bool = false
var export_bytes: PackedByteArray = PackedByteArray()
var document_pending: bool = false
var test_insets: Vector4 = Vector4.ZERO
var controls: Array[Button] = []
var nav_labels: Array[Label] = []
var inspector_details: Label
var rotation_button: Button
var placement_kind: String = "stockpile"
var paint_build_definition: String = ""
var placement_cache_key: String = ""
var placement_cache: Dictionary = {}
var forecast_elapsed: float = 0.0
var food_warning_level: int = 0
var saving_disabled: bool = false
var storage_error: String = ""
var recovery_failed: bool = false
var settings: DeviceSettings = DeviceSettings.new()
var pending_import_world: ColonyWorld
var forecast: Dictionary = {"portions":24,"ticks":21600,"label":"24 portions | 3 days stored runway"}

func _ready() -> void:
	Engine.max_fps = 30
	settings.load_local()
	text_scale = float(settings.values.text_scale)
	left_handed = settings.values.left_handed
	if store is ColonyStore and store.root_directory == ColonyStore.CAMPAIGN_ROOT and store.directory == ColonyStore.CAMPAIGN_ROOT.path_join("slot-1"):
		store.select_slot(settings.values.last_slot)
	if store is ColonyStore and (not store._generations().is_empty() or (store.directory == ColonyStore.CAMPAIGN_ROOT.path_join("slot-1") and ColonyStore.occupied(1))):
		var restored: Dictionary = store.load_latest()
		if restored.has("world"):
			world = restored.world
			runner = SimRunner.new(world)
			last_saved_tick = world.tick
			notice = restored.get("recovery","Recovered colony. Time stays paused.")
		else:
			recovery_failed = true
			storage_error = restored.error
	if Engine.has_singleton("BrackenwardSave"):
		native_storage = Engine.get_singleton("BrackenwardSave")
		logical_scale = maxf(1.0, float(native_storage.getDensity()))
		native_storage.document_result.connect(_native_result)
	_build_theme()
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	view = WorldView.new()
	content.add_child(view)
	view.setup(world)
	_restore_camera()
	view.intent.connect(_map_intent)
	_build_status()
	_build_navigation()
	_build_speed_controls()
	_build_map_tools()
	_build_placement()
	resized.connect(_resize)
	_layout()
	show_sheet("Welcome")
	if recovery_failed:
		show_recovery_problem()
	elif store is ColonyStore and store.root_directory == ColonyStore.CAMPAIGN_ROOT and not ColonyStore.occupied(store.slot):
		awaiting_first_colony = true
		show_new_colony(store.slot)

func _build_theme() -> void:
	var ui_theme: Theme = Theme.new()
	ui_theme.default_font = load("res://assets/exported/fonts/kenney_mini.ttf")
	ui_theme.default_font_size = int(16 * text_scale)
	ui_theme.set_color("font_color", "Label", Color("F8F3E7"))
	ui_theme.set_color("font_color", "Button", Color("F8F3E7"))
	ui_theme.set_color("font_disabled_color", "Button", Color("B8BCAD"))
	for type_name in ["PanelContainer", "Button"]:
		var box: StyleBoxFlat = _box(Color("263C3B"))
		ui_theme.set_stylebox("panel" if type_name == "PanelContainer" else "normal", type_name, box)
	ui_theme.set_stylebox("hover", "Button", _box(Color("375749")))
	ui_theme.set_stylebox("pressed", "Button", _box(Color("716D88")))
	ui_theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), Color("E9BA67")))
	ui_theme.set_stylebox("disabled", "Button", _box(Color("334741")))
	ui_theme.set_constant("separation", "VBoxContainer", 8)
	ui_theme.set_constant("separation", "HBoxContainer", 8)
	theme = ui_theme

func _box(color: Color, border: Color = Color("77915A")) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box

func button(label: String, callback: Callable, parent: Node, width: float = 48.0) -> Button:
	var result: Button = Button.new()
	result.text = label
	result.clip_text = true
	result.tooltip_text = label
	result.name = label.validate_node_name() if not label.is_empty() else "Action"
	result.custom_minimum_size = Vector2(width, 48)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ancestor: Node = parent
	while ancestor != null:
		if ancestor is ScrollContainer:
			# Raw touch events must reach the scroll container even when a drag
			# starts over an actionable row. Emulated clicks still activate it.
			result.mouse_filter = Control.MOUSE_FILTER_PASS
			break
		ancestor = ancestor.get_parent()
	if callback.is_valid(): result.pressed.connect(callback)
	parent.add_child(result)
	controls.append(result)
	return result

func direction_button(title: String, direction: Vector2, callback: Callable, parent: Node) -> Button:
	var result: Button = button("",callback,parent)
	result.name = title
	result.tooltip_text = title
	result.draw.connect(func() -> void:
		var center: Vector2 = result.size * 0.5
		var tip: Vector2 = center + direction * 9
		var side: Vector2 = direction.orthogonal() * 7
		result.draw_line(center-direction*9,tip,Color("F8F3E7"),3)
		result.draw_line(tip,center+side,Color("F8F3E7"),3)
		result.draw_line(tip,center-side,Color("F8F3E7"),3))
	return result

func label(text: String, parent: Node) -> Label:
	var result: Label = Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(result)
	return result

func _build_status() -> void:
	status = PanelContainer.new()
	content.add_child(status)
	var rows: VBoxContainer = VBoxContainer.new()
	status.add_child(rows)
	var row: HBoxContainer = HBoxContainer.new()
	rows.add_child(row)
	clock_label = label("", row)
	var menu_button: Button = button("Menu", func() -> void: show_sheet("Menu"), row, 64)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	notice_label = label(notice, rows)
	notice_label.max_lines_visible = 2
	notice_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _build_navigation() -> void:
	nav = GridContainer.new()
	nav.add_theme_constant_override("h_separation", 0)
	nav.add_theme_constant_override("v_separation", 0)
	content.add_child(nav)
	for title in ["Build", "Work", "People", "Valley", "Journal"]:
		var entry: Button = button(title, func() -> void: show_sheet(title), nav)
		entry.text = ""
		entry.tooltip_text = title
		entry.custom_minimum_size.y = 64
		var art: VBoxContainer = VBoxContainer.new()
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.offset_top = 4
		art.offset_bottom = -4
		art.add_theme_constant_override("separation", 2)
		var icon: TextureRect = TextureRect.new()
		icon.texture = load("res://assets/exported/ui/%s.svg" % title.to_lower())
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(24, 24)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(icon)
		var caption: Label = Label.new()
		caption.text = title
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.add_theme_font_size_override("font_size", int(16 * text_scale))
		art.add_child(caption)
		nav_labels.append(caption)
		entry.add_theme_font_size_override("font_size", int(16 * text_scale))
		for state in ["normal", "hover", "pressed", "focus"]:
			var box: StyleBoxFlat = entry.get_theme_stylebox(state).duplicate()
			box.content_margin_left = 2
			box.content_margin_right = 2
			entry.add_theme_stylebox_override(state, box)

func _build_speed_controls() -> void:
	speeds = HBoxContainer.new()
	content.add_child(speeds)
	button("Pause", func() -> void: set_speed(0), speeds, 72)
	for speed in [1, 2, 4]:
		button("%dx" % speed, func() -> void: set_speed(speed), speeds)

func _build_map_tools() -> void:
	map_tools = VBoxContainer.new()
	map_tools.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(map_tools)
	var zoom: HBoxContainer = HBoxContainer.new()
	zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_tools.add_child(zoom)
	button("-", func() -> void: view.zoom_at(0.8, view.size * 0.5), zoom)
	button("+", func() -> void: view.zoom_at(1.25, view.size * 0.5), zoom)
	var nudge: GridContainer = GridContainer.new()
	nudge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nudge.columns = 2
	map_tools.add_child(nudge)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var title: String = {Vector2.UP: "Up", Vector2.DOWN: "Down", Vector2.LEFT: "Left", Vector2.RIGHT: "Right"}[direction]
		direction_button(title, direction, func() -> void:
			view.follow_id = 0
			view.camera_tile += direction * 3
			view._update_transform(), nudge)

func _build_placement() -> void:
	placement = VBoxContainer.new()
	# Layout containers can temporarily retain an old minimum height. Their
	# empty area must never intercept the map; only actual buttons handle input.
	placement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(placement)
	placement.visible = false
	preview_label = label("", placement)
	preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_label.add_theme_stylebox_override("normal", _box(Color("263C3B")))
	placement_nudges = HBoxContainer.new()
	placement_nudges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placement.add_child(placement_nudges)
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var title: String = {Vector2i.LEFT: "Left", Vector2i.RIGHT: "Right", Vector2i.UP: "Up", Vector2i.DOWN: "Down"}[direction]
		direction_button(title, Vector2(direction), func() -> void:
			if not view.preview_definition.is_empty() or view.preview_lodge:
				view.preview_start += direction
			view.preview_end += direction
			view.preview_end.x = clampi(view.preview_end.x, 0, 127)
			view.preview_end.y = clampi(view.preview_end.y, 0, 127)
			if view.preview_lodge: view.fit_build_preview(), placement_nudges)
	placement_actions = HBoxContainer.new()
	placement_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placement.add_child(placement_actions)
	button("Cancel", cancel_placement, placement_actions, 64)
	button("Pan", func() -> void:
		view.cancel_gesture()
		view.gestures.mode = "paint" if view.gestures.mode == "pan" else "pan", placement_actions, 64)
	confirm_button = button("Confirm", confirm_placement, placement_actions, 96)
	rotation_button = button("Rotate", func() -> void:
		view.preview_rotation = (view.preview_rotation + 1) % 4
		view.fit_build_preview(), placement)
	rotation_button.visible = false
	placement_wide_row = HBoxContainer.new()
	placement_wide_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placement.add_child(placement_wide_row)

func _process(delta: float) -> void:
	if not is_node_ready() or backgrounded:
		return
	runner.advance_frame(delta)
	if world is ColonyWorld:
		if world.care_state.ended:
			seen_care_alert = world.care_state.alert_serial
			if epilogue_session != world.session_id:
				epilogue_session = world.session_id
				show_epilogue()
		elif world.care_state.alert_serial > seen_care_alert:
			seen_care_alert = world.care_state.alert_serial
			if world.citizens.any(func(c:Dictionary)->bool:return c.downed or c.death_recorded): show_care()
	if runner.speed_reduced:
		notice = "Speed reduced to keep the colony responsive."
		runner.speed_reduced = false
	if submitted_command > 0 and world.receipts.has(submitted_command):
		var receipt: String = world.receipts[submitted_command]
		notice = "Order accepted. Resume to watch the work." if receipt == "accepted" else "Order rejected: " + receipt
		submitted_command = 0
		confirm_button.disabled = false
	var day: int = (world.tick / 7200) % 8 + 1
	var season_name: String = ["Spring","Summer","Autumn","Winter"][ColonyAgriculture.season(world.tick)]
	var hour: int = (world.tick % 7200) / 300
	var minute: int = (world.tick % 300) / 5
	clock_label.text = "%s %d Y%d  %02d:%02d\n%s | %s" % [season_name,day,world.tick/230400+1,hour,minute,("Meals %d  Wood %d" % [world.available("meal"),world.available("wood")]) if world is ColonyWorld else "4 travelers","Paused" if runner.speed == 0 else "%dx" % runner.speed]
	_update_inspector()
	if world is ColonyWorld:
		forecast_elapsed += delta
		if forecast_elapsed >= 1.0:
			forecast = FoodForecast.calculate(world)
			forecast_elapsed = 0.0
			var warning: int = 3 if forecast.ticks < 3600 else (2 if forecast.ticks < 7200 else (1 if forecast.ticks < 14400 else 0))
			if warning > food_warning_level:
				notice = forecast.label + ". Gather food, plant turnips, and keep Cooking enabled. Ration policy is in Menu."
			food_warning_level = warning
	notice_label.text = ("Unsaved progress | " if saving_disabled else "") + notice
	if is_instance_valid(sheet_feedback):
		sheet_feedback.text = notice
	preview_label.text = _preview_text()
	journal_elapsed += delta
	if store is ColonyStore and journal_elapsed >= 2.0 and not saving_disabled and not recovery_failed and not awaiting_first_colony:
		var error: String = store.checkpoint(world)
		if not error.is_empty():
			_storage_failed(error)
		journal_elapsed = 0.0
	autosave_elapsed += delta
	if autosave_elapsed >= 30.0 and world.tick != last_saved_tick and not saving_disabled and not recovery_failed and not awaiting_first_colony:
		save_local()
		autosave_elapsed = 0.0

func set_speed(value: int) -> void:
	if value > 0 and creation_thread != null and creation_thread.is_started():
		notice = "Map generation is still running. Time stays paused."
		return
	if value > 0 and awaiting_first_colony:
		show_new_colony(store.slot)
		return
	if value > 0 and world is ColonyWorld and world.care_state.ended:
		show_epilogue()
		return
	if recovery_failed:
		notice = "Recovery stopped. Choose another campaign or import a verified snapshot."
		return
	if value > 0 and not storage_error.is_empty() and not saving_disabled:
		_storage_failed(storage_error)
		return
	if not sheet_name.is_empty() or backgrounded or (placement.visible and value != 0):
		notice = "Close the panel or confirm/cancel the area before resuming."
		return
	runner.set_speed(value)

func begin_placement() -> void:
	if awaiting_first_colony:
		show_new_colony(store.slot)
		return
	close_sheet()
	runner.pause()
	confirm_button.disabled = submitted_command>0
	view.cancel_gesture()
	view.follow_id = 0
	view.preview_visible = true
	view.preview_definition = ""
	view.preview_line=false;view.preview_lodge=false;view.rejected_build_tiles.clear()
	paint_build_definition="";placement_cache_key="";placement_cache.clear()
	view.preview_resource = ""
	if world is ColonyWorld:
		view.preview_start = _home_tile(Vector2i(74,54))
		view.preview_end = _home_tile(Vector2i(77,55))
	placement_kind = "stockpile"
	rotation_button.visible = false
	view.gestures.mode = "paint"
	placement.visible = true
	view.camera_tile = Vector2(_home_tile(Vector2i(77,55)))
	notice = "Paint an area, then Confirm. Dragging never submits an order."
	_layout()

func cancel_placement() -> void:
	view.cancel_gesture()
	view.preview_visible = false
	view.gestures.mode = "select"
	placement.visible = false
	notice = "Unconfirmed area canceled. Time stays paused."
	_layout()

func confirm_placement() -> void:
	if awaiting_first_colony:
		show_new_colony(store.slot)
		return
	if confirm_button.disabled or not placement.visible:
		return
	for tile in view.preview_tiles():
		if placement_kind not in ["gather","build_area"] and view.preview_definition not in ["bridge","fishing_pier"] and (world.is_water(tile) if world is ColonyWorld else PrototypeWorld.is_water(tile)):
			notice = "Deep river cannot be designated. Move the preview onto land."
			return
	if world is ColonyWorld and not view.preview_definition.is_empty():
		var error: String = world.placement_error(view.preview_definition, view.preview_start, view.preview_rotation)
		if not error.is_empty():
			notice = error
			return
	if placement_kind == "lodge":
		var error: String = ColonyConstruction.lodge_error(world,view.preview_start)
		if not error.is_empty(): notice=error;return
	if placement_kind == "build_area":
		var preview: Dictionary = ColonyConstruction.paint_preview(world,paint_build_definition,view.preview_tiles())
		view.rejected_build_tiles=preview.rejected
		if preview.valid.is_empty(): notice="No valid tiles. Inspect the red cells or clear obstructions.";return
	confirm_button.disabled = true
	if world is ColonyWorld and placement_kind == "lodge":
		submitted_command=world.queue_command("lodge",{"x":view.preview_start.x,"y":view.preview_start.y})
	elif world is ColonyWorld and placement_kind == "build_area":
		submitted_command=world.queue_command("build_area",{"definition":paint_build_definition,"tiles":view.preview_tiles()})
	elif world is ColonyWorld and not view.preview_definition.is_empty():
		submitted_command = world.queue_command("build", {"definition": view.preview_definition, "x": view.preview_start.x, "y": view.preview_start.y, "rotation": view.preview_rotation})
	elif world is ColonyWorld and placement_kind == "gather":
		if world.gather_targets(view.preview_resource,view.preview_tiles()).is_empty():
			confirm_button.disabled = false
			notice = "No unmarked resources here. Drag over the resources you want."
			return
		submitted_command = world.queue_command("gather_area", {"definition":view.preview_resource,"tiles":view.preview_tiles()})
	elif world is ColonyWorld and placement_kind == "pen":
		submitted_command = world.queue_command("pen",{"tiles":view.preview_tiles()})
	elif world is ColonyWorld and placement_kind == "forest":
		submitted_command = world.queue_command("forest",{"tiles":view.preview_tiles(),"value":75})
	elif world is ColonyWorld and placement_kind == "field":
		submitted_command = world.queue_command("field", {"crop":"turnip", "tiles":view.preview_tiles()})
	else:
		submitted_command = world.queue_designation(view.preview_tiles())
	view.cancel_gesture()
	view.preview_visible = false
	placement.visible = false
	view.gestures.mode = "select"
	notice = "Area pending. Resume to validate it on the next tick."
	_layout()

func _map_intent(action: Dictionary) -> void:
	if action.kind == "notice": notice=action.text;return
	var candidates: Array[Dictionary] = []
	for citizen in world.citizens:
		if world is ColonyWorld and (citizen.death_recorded or citizen.departed or citizen.carried_by>0): continue
		var separation: float = view.tile_to_screen(view.citizen_point(citizen)).distance_to(action.point)
		if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"citizen","object":citizen,"rank":0,"distance":separation})
	if world is ColonyWorld:
		for animal in world.domestic_state.animals:
			if animal.health<=0 or animal.away: continue
			var separation: float = view.tile_to_screen(Vector2(animal.x+0.5,animal.y+0.5)).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"domestic","object":animal,"rank":2,"distance":separation})
		for animal in world.wildlife_state.animals:
			if animal.health<=0: continue
			var separation: float = view.tile_to_screen(Vector2(animal.x+0.5,animal.y+0.5)).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"wildlife","object":animal,"rank":2,"distance":separation})
		for structure in world.structures:
			if world.footprint(structure).has(action.tile): candidates.append({"kind":"station","object":structure,"rank":3,"distance":0.0})
		for job in world.jobs:
			if job.kind=="build" and job.state not in ["Complete","Canceled"] and world.footprint(job).has(action.tile): candidates.append({"kind":"job","object":job,"rank":4,"distance":0.0})
		for resource in world.resources:
			if Vector2i(resource.x,resource.y)==action.tile: candidates.append({"kind":"resource","object":resource,"rank":5,"distance":0.0})
		for field in world.fields:
			if Vector2i(field.x,field.y)==action.tile: candidates.append({"kind":"field","object":field,"rank":5,"distance":0.0})
		for carcass in world.wildlife_state.carcasses:
			if not carcass.done and not carcass.spoiled and Vector2i(carcass.x,carcass.y)==action.tile: candidates.append({"kind":"carcass","object":carcass,"rank":3,"distance":0.0})
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if a.rank!=b.rank: return a.rank<b.rank
		if a.distance!=b.distance: return a.distance<b.distance
		return a.object.id<b.object.id)
	if action.kind=="chooser" or candidates.size()>1:
		show_sheet("Select object")
		for candidate in candidates:
			var title: String = candidate.object.get("name",candidate.kind+": "+candidate.object.get("definition",candidate.object.get("crop","")))
			button(title,func()->void:close_sheet();_select_map_object(candidate),sheet_body)
		label("Terrain (%d, %d)" % [action.tile.x,action.tile.y],sheet_body)
	elif candidates.size()==1: _select_map_object(candidates[0])
	else:
		if world is ColonyWorld:
			for pen in world.domestic_state.pens:
				if pen.tiles.has(action.tile): show_pen(pen);return
		if view.rejected_build_tiles.has(action.tile):
			show_sheet("Unsubmitted building cell");label(view.rejected_build_tiles[action.tile],sheet_body);return
		notice="Terrain (%d, %d). Use Build to place a blueprint." % [action.tile.x,action.tile.y]

func _select_map_object(candidate: Dictionary) -> void:
	var object: Dictionary = candidate.object
	match candidate.kind:
		"citizen": select_citizen(object.id)
		"domestic": show_domestic_animal(object)
		"wildlife": _wildlife_sheet(object)
		"station": show_station(object)
		"job": _job_sheet(object)
		"resource": _resource_sheet(object)
		"field": _field_sheet(object)
		"carcass":
			show_sheet("Carcass")
			label("%s: %.1f game hours until spoilage. Gathering workers butcher it; outputs need hauling." % [_catalog_name(object.definition),(object.expires-world.tick)/300.0],sheet_body)

func select_citizen(id: int) -> void:
	selected = id
	view.selected_id = id
	if inspector != null:
		inspector.queue_free()
	inspector = PanelContainer.new()
	content.add_child(inspector)
	var inspector_rows: VBoxContainer = VBoxContainer.new()
	inspector.add_child(inspector_rows)
	var scroll: ScrollContainer = TouchScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_rows.add_child(scroll)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var citizen: Dictionary = world.citizens[id - 1]
	inspector_details = label("", rows)
	_update_inspector()
	var actions: HBoxContainer = HBoxContainer.new()
	inspector_rows.add_child(actions)
	button("Follow", func() -> void: view.follow_id = id, actions, 80)
	button("Close", close_inspector, actions, 64)
	_layout()

func close_inspector() -> void:
	if inspector != null:
		inspector.queue_free()
		inspector = null
	selected = 0
	view.selected_id = 0

func show_sheet(title: String) -> void:
	runner.pause()
	view.cancel_gesture()
	if sheet != null:
		sheet.queue_free()
	close_inspector()
	sheet_name = title
	sheet = PanelContainer.new()
	content.add_child(sheet)
	var rows: VBoxContainer = VBoxContainer.new()
	sheet.add_child(rows)
	var top: HBoxContainer = HBoxContainer.new()
	rows.add_child(top)
	var heading: Label = label(title, top)
	heading.add_theme_font_override("font", load("res://assets/exported/fonts/kenney_bold.ttf"))
	heading.add_theme_font_size_override("font_size", int(20 * text_scale))
	var close_button: Button = button("Close", close_sheet, top, 64)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var pause_button: Button = button("Pause", func() -> void: runner.pause(), top, 72)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var scroll: ScrollContainer = TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(scroll)
	sheet_body = VBoxContainer.new()
	sheet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sheet_body)
	sheet_feedback = label(notice, sheet_body)
	sheet_feedback.visible = title != "Welcome"
	match title:
		"Welcome":
			label("Four travelers. A ruined wayhouse. Make a place to stay.", sheet_body)
			label("Start paused. Gather berries and wood, place a bed, then resume and watch your residents fetch, carry, work, eat, and sleep.", sheet_body)
			label("Meals: 3 days of starting food. Cooking needs four raw food units and one wood for two meals. Choose resource orders in Work or tap a plant on the map.", sheet_body)
			button("Begin", func() -> void:
				close_sheet()
				notice = "Tap Mira and Follow. Time starts paused.", sheet_body)
			button("Look around", close_sheet, sheet_body)
		"Build":
			label("Blueprints require real supplies and worker time. Pause to plan; materials are spent only when construction finishes.", sheet_body)
			button("Paint stockpile", begin_placement, sheet_body)
			button("Plant turnips", begin_field, sheet_body)
			if world is ColonyWorld:
				button("Four-bed lodge | W73 F8",begin_lodge,sheet_body)
				for kind in world.definitions.buildings:
					var definition: Dictionary = world.definitions.buildings[kind]
					if not definition.buildable: continue
					button(kind.capitalize() + " | " + _cost_text(definition.materials), func() -> void: begin_build(kind), sheet_body)
		"People":
			if world is ColonyWorld: button("Injuries and care",show_care,sheet_body)
			for citizen in world.citizens:
				button(citizen.name, func() -> void:
					if world is ColonyWorld: show_person(citizen.id)
					else:
						close_sheet()
						select_citizen(citizen.id), sheet_body)
		"Work":
			_work_sheet()
		"Valley":
			label("The regional map and expeditions arrive in M4. This checkpoint tests the local map and mobile storage.", sheet_body)
		"Journal":
			if world is ColonyWorld:
				_tutorial_sheet()
				for fact in world.facts.slice(maxi(0, world.facts.size() - 30)):
					label("%02d:%02d - %s" % [(fact.tick % 7200) / 300, (fact.tick % 300) / 5, fact.text], sheet_body)
		"Menu":
			label("Brackenward %s\nCampaigns preserve inventory, work and needs. Time stays paused after recovery." % ProjectSettings.get_setting("application/config/version"), sheet_body)
			if world is ColonyWorld: button("Mode: "+world.care_state.mode,show_mode,sheet_body)
			if world is ColonyWorld: button("Map and seed",show_map_details,sheet_body)
			button("Save colony", save_local, sheet_body)
			button("Load colony", load_local, sheet_body)
			button("Export save", func() -> void: choose_document(true), sheet_body)
			button("Import save", func() -> void: choose_document(false), sheet_body)
			button("Text size: %d%%" % int(text_scale * 100), func() -> void:
				text_scale = 1.25 if text_scale == 1.0 else (1.5 if text_scale == 1.25 else 1.0)
				_save_settings()
				_build_theme()
				show_sheet("Menu"), sheet_body)
			button("Handedness: " + ("Left" if left_handed else "Right"), func() -> void:
				left_handed = not left_handed
				_save_settings()
				show_sheet("Menu"), sheet_body)
			if world is ColonyWorld:
				button("Campaign slots",show_campaigns,sheet_body)
				button("Named snapshots",show_named_snapshots,sheet_body)
				button("Weather forecast",show_weather,sheet_body)
				label("Travel rations are expedition reserves. Home use is " + ("on" if world.use_rations else "off") + ".",sheet_body)
				button("Keep rations for expeditions" if world.use_rations else "Use rations at home",func() -> void: _submit("food_policy", {"enabled":not world.use_rations}),sheet_body)
			button("Introduction", func() -> void: show_sheet("Welcome"), sheet_body)
	_layout()
	get_viewport().gui_release_focus()
	call_deferred("_layout")

func close_sheet() -> void:
	if sheet != null:
		sheet.queue_free()
		sheet = null
	sheet_name = ""
	notice = "Paused. Choose 1x, 2x, or 4x to resume."
	_layout()

func _layout() -> void:
	if content == null:
		return
	var available: Vector2 = size / logical_scale
	var insets: Vector4 = test_insets
	if OS.has_feature("android") and test_insets == Vector4.ZERO:
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		if safe.size.x > 0 and safe.size.y > 0:
			insets = Vector4(safe.position.x, safe.position.y, maxi(0, int(size.x) - safe.end.x), maxi(0, int(size.y) - safe.end.y)) / logical_scale
	content.scale = Vector2.ONE * logical_scale
	content.position = Vector2(insets.x, insets.y) * logical_scale
	content.size = available - Vector2(insets.x + insets.z, insets.y + insets.w)
	var width: float = content.size.x
	var height: float = content.size.y
	var wrap_navigation: bool = width < 600 and text_scale > 1.0
	var navigation_height: float = 128 if wrap_navigation else 64
	var header_height: float = (104.0 if width < 600 else 88.0) * text_scale
	status.position = Vector2.ZERO
	status.size = Vector2(width, header_height)
	nav.columns = 3 if wrap_navigation else 5
	nav.position = Vector2(0, height - navigation_height)
	for child: Button in nav.get_children():
		child.custom_minimum_size.x = width / nav.columns
		child.add_theme_font_size_override("font_size", int(16 * text_scale))
	for caption in nav_labels:
		caption.add_theme_font_size_override("font_size", int(16 * text_scale))
	nav.reset_size()
	nav.size = Vector2(width, navigation_height)
	speeds.position = Vector2(8 if left_handed else maxf(8, width - 248), height - navigation_height - 56)
	speeds.size = Vector2(240, 48)
	view.position = Vector2(0, header_height)
	view.size = Vector2(width, maxf(48, height - header_height - navigation_height))
	map_tools.position = Vector2(8, header_height + 8)
	map_tools.size = Vector2(112, 160)
	map_tools.visible = sheet == null and not placement.visible
	placement.position = Vector2(8, header_height + 8)
	if (width >= 600 and height < 500) or (text_scale > 1.0 and height < 700):
		placement.position.y = 8
	status.visible = not (placement.visible and placement.position.y < header_height)
	var placement_parent: Node = placement_wide_row if width >= 600 else placement
	if placement_nudges.get_parent() != placement_parent:
		placement_nudges.reparent(placement_parent)
		placement_actions.reparent(placement_parent)
		if width < 600:
			placement.move_child(placement_nudges, 1)
			placement.move_child(placement_actions, 2)
	placement_wide_row.visible = width >= 600
	placement.reset_size()
	placement.size = Vector2(width - 16, 160)
	if sheet != null:
		sheet.position = Vector2(8, 8)
		sheet.reset_size()
		sheet.size = Vector2(width - 16, maxf(120, height - navigation_height - 72))
		sheet.move_to_front()
	if inspector != null:
		var wide: bool = width >= 600
		inspector.position = Vector2(width - 328, header_height + 8) if wide else Vector2(8, maxf(header_height, height - navigation_height - 248))
		inspector.size = Vector2(320 if wide else width - 16, 184)
		inspector.move_to_front()
		view.focus_offset = Vector2(-164, 0) if wide else Vector2(0, -120)
	else:
		view.focus_offset = Vector2.ZERO
	speeds.move_to_front()

func _resize() -> void:
	if view != null:
		view.cancel_gesture()
	_layout()

func save_local() -> String:
	if awaiting_first_colony: return ""
	if recovery_failed:
		return "Recovery failed; original campaign will not be overwritten"
	var error: String = store.save(world)
	if error.is_empty():
		last_saved_tick = world.tick
		_save_settings()
		saving_disabled = false
		storage_error = ""
		notice = "Saved and verified at tick %d." % world.tick
		if sheet_name == "Save problem":
			close_sheet()
	else:
		_storage_failed(error)
	return error

func load_local() -> void:
	runner.pause()
	var result: Dictionary = store.load_latest()
	if result.has("error"):
		notice = result.error
		return
	_replace_world(result.world)
	notice = "Colony restored. Time stays paused."

func _replace_world(state: RefCounted) -> void:
	world = state
	seen_care_alert = -1
	epilogue_session = ""
	recovery_failed = false
	storage_error = ""
	saving_disabled = false
	runner = SimRunner.new(world)
	view.world = world
	view.refresh_terrain()
	view.forecast_mask.clear()
	view.cancel_gesture()
	view.follow_id = 0
	cancel_placement()
	submitted_command = 0
	confirm_button.disabled = false
	last_saved_tick = world.tick

func choose_document(export: bool) -> void:
	if document_pending:
		notice = "A document operation is already open. Finish or cancel it first."
		return
	runner.pause()
	view.cancel_gesture()
	exporting = export
	document_request += 1
	if export:
		export_bytes = store.encode(world)
		if store.decode(export_bytes).has("error"):
			notice = "Snapshot validation failed. Nothing exported."
			return
	if native_storage != null:
		document_pending = true
		if export:
			native_storage.chooseExportDestination(document_request, "brackenward-colony.brackenward")
		else:
			native_storage.chooseImportDocument(document_request)
		return
	file_dialog = FileDialog.new()
	document_pending = true
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = true
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if export else FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.brackenward ; Brackenward colony"])
	file_dialog.current_file = "brackenward-colony.brackenward" if export else ""
	add_child(file_dialog)
	file_dialog.file_selected.connect(_desktop_selected)
	file_dialog.canceled.connect(func() -> void:
		document_pending = false
		notice = "Picker canceled. Saves unchanged.")
	file_dialog.popup_centered(Vector2i(720, 480))

func _desktop_selected(path: String) -> void:
	document_pending = false
	if exporting:
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			notice = "Could not open selected export destination."
			return
		file.store_buffer(export_bytes)
		file.flush()
		var error: Error = file.get_error()
		file.close()
		notice = "Export written and verified." if error == OK and not store.decode(FileAccess.get_file_as_bytes(path)).has("error") else "Export write/verification failed."
	else:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null or file.get_length() > ColonyCodec.MAX_BYTES:
			notice = "Could not read save, or file exceeds the colony's 64 MiB limit."
			return
		_accept_import(file.get_buffer(file.get_length()))

func _native_result(request: int, result: String, bytes: PackedByteArray) -> void:
	if request != document_request:
		return
	if result not in ["export_selected", "import_selected"]:
		document_pending = false
	match result:
		"export_selected": native_storage.writeSelectedDocument(request, export_bytes)
		"import_selected": native_storage.readSelectedDocument(request, ColonyCodec.MAX_BYTES)
		"read": _accept_import(bytes)
		"written": notice = "Export written and verified."
		"canceled": notice = "Picker canceled. Saves unchanged."
		_: notice = "Document operation failed: " + result

func _accept_import(bytes: PackedByteArray) -> void:
	var result: Dictionary = store.decode(bytes)
	if result.has("error"):
		notice = result.error
		return
	if world is ColonyWorld:
		pending_import_world = result.world
		pending_import_world.session_id = Crypto.new().generate_random_bytes(16).hex_encode()
		for command in pending_import_world.pending_commands:
			command.session = pending_import_world.session_id
		show_import_slots()
	else:
		_replace_world(result.world)
		notice = "Imported verified fixture. Time stays paused."

func suspend() -> void:
	if backgrounded:
		return
	backgrounded = true
	runner.pause()
	view.cancel_gesture()
	if not saving_disabled and not recovery_failed:
		save_local()

func resume_from_background() -> void:
	backgrounded = false
	runner.pause()
	view.cancel_gesture()
	notice = "While you were away, nothing advanced."
	if recovery_failed:
		show_recovery_problem()
		return
	if not storage_error.is_empty() and not saving_disabled:
		_storage_failed(storage_error)
		return
	show_sheet("Welcome back")
	label(notice, sheet_body)

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		suspend()
	elif what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN] and backgrounded:
		resume_from_background()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		suspend()
		get_tree().quit()

func back() -> void:
	view.cancel_gesture()
	if sheet != null:
		close_sheet()
	elif placement.visible:
		cancel_placement()
	elif inspector != null:
		close_inspector()
	else:
		show_sheet("Menu")

func _unhandled_key_input(event: InputEvent) -> void:
	if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE: back()
		KEY_SPACE: set_speed(runner.previous_speed if runner.speed == 0 else 0)
		KEY_1: set_speed(1)
		KEY_2: set_speed(2)
		KEY_3: set_speed(4)
		KEY_B: show_sheet("Build")
		KEY_J: show_sheet("Work")
		KEY_P: show_sheet("People")
		KEY_V: show_sheet("Valley")
		KEY_L: show_sheet("Journal")
		KEY_W, KEY_UP: view.camera_tile += Vector2.UP * 3
		KEY_S, KEY_DOWN: view.camera_tile += Vector2.DOWN * 3
		KEY_A, KEY_LEFT: view.camera_tile += Vector2.LEFT * 3
		KEY_D, KEY_RIGHT: view.camera_tile += Vector2.RIGHT * 3
		_: return
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:
		return
	# Space is the global pause shortcut even when a Button owns GUI focus.
	# Enter remains available to activate the focused button.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		set_speed(runner.previous_speed if runner.speed == 0 else 0)
		get_viewport().set_input_as_handled()

func _cost_text(materials: Dictionary) -> String:
	var parts: Array[String] = []
	for item in materials:
		parts.append("%d %s" % [materials[item], item])
	return ", ".join(parts)

func begin_build(kind: String) -> void:
	if kind in ColonyConstruction.PAINTABLE:
		begin_placement();placement_kind="build_area";paint_build_definition=kind
		view.preview_line=kind not in ColonyConstruction.OVERLAYS
		view.preview_start=_home_tile(Vector2i(74,63));view.preview_end=view.preview_start+Vector2i(3,0)
		view.camera_tile=Vector2(view.preview_start);rotation_button.visible=false
		notice="Paint %s, then Confirm. The preview shows valid cells, total cost and omitted obstructions." % _catalog_name(kind)
		_layout();return
	begin_placement()
	view.preview_definition = kind
	view.preview_rotation = 0
	view.preview_start = _home_tile(Vector2i(74,63))
	view.fit_build_preview()
	view.camera_tile = Vector2(view.preview_start)
	rotation_button.visible = true
	notice = "Place %s. Tap a tile or use the arrows; Confirm spends nothing until built." % kind.capitalize()
	_layout()

func begin_gather(kind: String) -> void:
	begin_placement()
	placement_kind = "gather"
	view.preview_resource = kind
	for resource in world.resources:
		if resource.definition == kind and resource.remaining > 0:
			view.preview_start = Vector2i(resource.x,resource.y)
			view.preview_end = view.preview_start
			view.camera_tile = Vector2(resource.x,resource.y)
			break
	notice = "Drag a rectangle around the resources, then Confirm. Gathering workers finish every marked job."
	_layout()

func _preview_text() -> String:
	if placement_kind=="lodge":
		var key: String = "lodge|%s|%d" % [view.preview_start,world.tick]
		if key!=placement_cache_key:
			placement_cache_key=key;placement_cache={"error":ColonyConstruction.lodge_error(world,view.preview_start)}
		return "Four-bed lodge · 8×6 · W73 F8 · 206 WU\n"+("Valid; beds and door finish before enclosure" if placement_cache.error.is_empty() else placement_cache.error)
	if placement_kind=="build_area":
		var key: String = "%s|%s|%s|%d" % [paint_build_definition,view.preview_start,view.preview_end,world.tick]
		if key!=placement_cache_key:
			placement_cache_key=key;placement_cache=ColonyConstruction.paint_preview(world,paint_build_definition,view.preview_tiles())
		view.rejected_build_tiles=placement_cache.rejected
		var cost: Dictionary = {}
		for item in world.definitions.buildings[paint_build_definition].materials: cost[item]=world.definitions.buildings[paint_build_definition].materials[item]*placement_cache.valid.size()
		var tiles: Array = view.preview_tiles()
		var dimensions: Vector2i = (tiles[-1]-tiles[0]).abs()+Vector2i.ONE
		return "%s · %d×%d · Confirm %d valid · %s\n%d blocked cells stay unsubmitted%s" % [_catalog_name(paint_build_definition),dimensions.x,dimensions.y,placement_cache.valid.size(),_cost_text(cost),placement_cache.rejected.size(),"" if placement_cache.rejected.is_empty() else ": "+placement_cache.rejected.values()[0]]
	if placement_kind == "pen": return "Livestock pen | Enclose with fences/gates/solid walls\nFour interior tiles and one barn shelter slot per animal"
	if placement_kind == "forest": return "Forest zone | Keep 75% of its tree sites mature\nAutomatically cut excess and replant stumps"
	if placement_kind == "gather":
		var count: int = world.gather_targets(view.preview_resource,view.preview_tiles()).size()
		return "Gather %s | %d unmarked %s\nDrag a rectangle, then Confirm" % [world.definitions.resources[view.preview_resource].item,count,"trees" if view.preview_resource == "tree" else "resources"]
	if world is ColonyWorld and not view.preview_definition.is_empty():
		var error: String = world.placement_error(view.preview_definition, view.preview_start, view.preview_rotation)
		var definition: Dictionary = world.definitions.buildings[view.preview_definition]
		return "%s | %s | %d WU\n%s" % [view.preview_definition.capitalize(), _cost_text(definition.materials), definition.work_milli / 1000, "Valid placement" if error.is_empty() else error]
	return "%d x %d tiles | %s" % [absi(view.preview_end.x - view.preview_start.x) + 1, absi(view.preview_end.y - view.preview_start.y) + 1, "Pan mode" if view.gestures.mode == "pan" else ("Turnip field" if placement_kind == "field" else "Stockpile preview")]

func _update_inspector() -> void:
	if selected <= 0 or not is_instance_valid(inspector_details):
		return
	var citizen: Dictionary = world.citizens[selected - 1]
	if world is ColonyWorld:
		var job: Dictionary = world.find(world.jobs, citizen.job)
		inspector_details.text = "%s - %s\nFood %d/1000 | Rest %d/1000\nHealth %d | %s first\n%s" % [citizen.name, citizen.activity, citizen.fullness, citizen.rest, citizen.health, citizen.preferred,
			("Work %d/%d WU" % [job.work / 1000, job.required / 1000]) if not job.is_empty() and job.required > 0 else ("Needs take priority over ordinary work." if not job.is_empty() else "Choose orders in Work or Build.")]
	else:
		inspector_details.text = "%s - looking around\nM0 touch fixture movement." % citizen.name

func _submit(kind: String, args: Dictionary) -> void:
	if awaiting_first_colony:
		notice = "Choose a site and create this colony first."
		return
	if submitted_command > 0 and kind not in ["preference","schedule","priority","stock_filter","food_policy"]:
		notice = "An order is pending. Resume to apply it before another action."
		return
	submitted_command = world.queue_command(kind, args)
	confirm_button.disabled = true
	notice = "Order pending. Close the panel and resume to apply it."

func _resource_sheet(resource: Dictionary) -> void:
	show_sheet(resource.definition.capitalize())
	var definition: Dictionary = world.definitions.resources[resource.definition]
	label("%d %s remaining | %d WU %s" % [resource.remaining, definition.item, definition.work_milli / 1000, "per unit" if definition.per_unit else "per harvest"], sheet_body)
	label("A gatherer works beside the resource. The output appears there and must be hauled into storage.", sheet_body)
	if resource.definition == "tree" and resource.remaining == 0:
		var state: Dictionary = ColonyNature.tree(world,resource.id)
		label("Growing: %.1f of eight non-winter days. Winter pauses growth." % (float(state.age)/7200.0) if state.planted else "Stump. Replant for 4 WU; no material cost. Eight non-winter days to maturity.",sheet_body)
		button("Clear sapling (2 WU)" if state.planted else "Replant tree (4 WU)",func()->void:
			_submit("clear_sapling" if state.planted else "replant_tree",{"target":resource.id})
			close_sheet(),sheet_body)

	if resource.remaining > 0:
		button("Gather", func() -> void:
			_submit("gather", {"target": resource.id})
			close_sheet()
			view.camera_tile = Vector2(resource.x, resource.y), sheet_body)

func _job_sheet(job: Dictionary) -> void:
	show_sheet("Work order")
	label("%s: %s\nWork %d/%d WU\n%s" % [job.kind.capitalize(), job.state, job.work / 1000, job.required / 1000, job.reason], sheet_body)
	if not job.inputs.is_empty():
		label("Required: " + _cost_text(job.inputs) + "\nDelivered materials remain refundable until completion.", sheet_body)
	if job.category in ColonyWorld.CATEGORIES:
		button("Priority: " + ["", "Low", "Normal", "Urgent"][job.priority],func() -> void: _submit("priority",{"target":job.id,"value":job.priority%3+1}),sheet_body)
		for citizen in world.citizens:
			button("Do next: " + citizen.name,func() -> void:
				_submit("pin",{"target":job.id,"citizen":citizen.id})
				close_sheet(),sheet_body)
	button("Cancel order", func() -> void:
		_submit("cancel", {"target": job.id})
		close_sheet(), sheet_body)

func _work_sheet() -> void:
	if not world is ColonyWorld:
		label("M0 fixture: real worker loop is in the colony scene.", sheet_body)
		return
	label("Choose a resource, drag a rectangle, then Confirm. Workers with Gathering enabled keep taking marked jobs until they are finished.", sheet_body)
	for kind in ["tree", "berry_bush", "mushroom_patch", "herb_patch", "stone_node", "clay_bank", "iron_seam"]:
		button("Gather " + world.definitions.resources[kind].item, func() -> void: begin_gather(kind), sheet_body)
	button("Paint forest zone",begin_forest,sheet_body)
	button("Research",show_research,sheet_body)
	button("Wildlife",show_wildlife,sheet_body)
	button("Livestock pens",show_pens,sheet_body)
	label("Worker assignments",sheet_body)
	for citizen in world.citizens:
		button("%s | Gathering %s" % [citizen.name,["Off","Last","Normal","First"][citizen.preferences.Gathering]],func() -> void: show_work_preferences(citizen.id),sheet_body)
	for zone in world.nature_state.forests:
		button("Forest | Keep %d%% mature" % zone.reserve,func()->void:show_forest(zone),sheet_body)
	label("Storage",sheet_body)
	for store in world.stores:
		button("Storage " + str(store.id),func() -> void: _storage_sheet(store),sheet_body)
	label("Current orders", sheet_body)
	for job in world.jobs:
		if job.state not in ["Complete", "Canceled"]:
			button("%s - %s" % [job.kind.capitalize(), job.state], func() -> void: _job_sheet(job), sheet_body)
			if not job.reason.is_empty():
				label(job.reason, sheet_body)

func _tutorial_sheet() -> void:
	label("First steps", sheet_body)
	label(forecast.label, sheet_body)
	label("Stored runway excludes future harvests, reserved goods and expedition rations. Fresh food, cooking and storage can change it.", sheet_body)
	var completed: Array = world.facts.map(func(fact: Dictionary) -> String: return fact.kind)
	for kind in ["gather", "haul", "build", "cook", "eat", "sleep"]:
		label(("Done: " if completed.has(kind) else "Next: ") + kind.capitalize(), sheet_body)
	label("Gather berries and wood in Work. Place a bed in Build. Resume to see materials carried and used. Cooking starts when stored meals fall below 16; hunger and nightfall trigger eating and sleep.", sheet_body)

func begin_field() -> void:
	begin_placement()
	placement_kind = "field"
	view.preview_start = _home_tile(Vector2i(74,54))
	view.preview_end = _home_tile(Vector2i(77,57))
	view.camera_tile = Vector2(view.preview_start+view.preview_end)*0.5
	view._update_transform()
	notice = "Turnips: prepare 4 WU, sow 1 WU, harvest 2 WU per tile. Two days of growth gives four vegetables."

func _field_sheet(field: Dictionary) -> void:
	show_sheet(field.crop.capitalize())
	var definition: Dictionary = world.definitions.crops[field.crop]
	label("%s\nGrowth %d/%d | Yield %d\nSoil %d%% | %s" % [field.reason,field.growth,definition.growth,field.yield_count,field.fertility/10,"Automatic replanting" if field.replant else "Replant off"],sheet_body)
	if field.planted:
		if field.growth * 2 >= definition.growth:
			label("Early harvest now: about %d units. Workers still need to reach and harvest this crop." % mini(field.yield_count,maxi(1,definition.yield_count * field.growth / definition.growth)),sheet_body)
			button("Harvest early",func() -> void:
				_submit("early_harvest",{"target":field.id})
				close_sheet(),sheet_body)
		else:
			label("Early harvest requires 50% growth. Clearing now returns no produce.",sheet_body)
	label("Clearing removes this field and its unharvested crop. Unconsumed materials and carried goods are retained.",sheet_body)
	button("Clear field",func() -> void:
		_submit("clear_field",{"target":field.id})
		close_sheet(),sheet_body)

func _storage_sheet(storage: Dictionary) -> void:
	show_sheet("Storage")
	var count: int = 0
	for stack in world.stacks:
		if stack.location == "store" and stack.owner == storage.id:
			count += stack.count
	label("%d/%d units. Each zone tile holds one stack. Goods remain here while their filter is valid; new loose goods prefer higher-priority destinations." % [count,storage.capacity],sheet_body)
	button("Priority: " + ["","Low","Normal","High"][storage.priority],func() -> void:
		_submit("stock_filter",{"target":storage.id,"filters":storage.filters,"priority":storage.priority%3+1}),sheet_body)
	for item in world.definitions.items:
		var stored: int = 0
		var reserved: int = 0
		for stack in world.stacks:
			if stack.location == "store" and stack.owner == storage.id and stack.item == item:
				stored += stack.count
				reserved += world._reserved(stack)
		label("%s: %d stored, %d reserved" % [item.capitalize(),stored,reserved],sheet_body)
		button(item.capitalize()+": "+("On" if storage.filters.has(item) else "Off"),func() -> void:
			var filters: Array = storage.filters.duplicate()
			if filters.has(item): filters.erase(item)
			else: filters.append(item)
			_submit("stock_filter",{"target":storage.id,"filters":filters,"priority":storage.priority}),sheet_body)

func _storage_failed(error: String) -> void:
	storage_error = error
	runner.pause()
	view.cancel_gesture()
	notice = error
	show_sheet("Save problem")
	label(error + "\nCurrent progress remains in memory. No earlier valid save was replaced.",sheet_body)
	button("Retry save",save_local,sheet_body)
	button("Export current colony",func() -> void: choose_document(true),sheet_body)
	label("Continue without saving can lose progress when the app closes. A persistent Unsaved progress notice remains until a verified save succeeds.",sheet_body)
	button("Continue without saving",func() -> void:
		saving_disabled = true
		close_sheet()
		notice = "Saving is disabled. Retry Save in Menu to restore it.",sheet_body)

func show_recovery_problem() -> void:
	runner.pause()
	show_sheet("Recovery stopped")
	label(storage_error + "\nOriginal campaign files are retained. Choose another campaign or import a verified snapshot. This preview will not overwrite the failed campaign.",sheet_body)
	button("Campaign slots",show_campaigns,sheet_body)
	button("Import verified save",func() -> void: choose_document(false),sheet_body)

func show_campaigns() -> void:
	if not store is ColonyStore:
		return
	if not recovery_failed and not saving_disabled and not save_local().is_empty():
		return
	show_sheet("Campaigns")
	label("Five independent campaign slots. Switching first saves the current colony. Imported campaigns use an empty slot or a confirmed replacement.",sheet_body)
	for number in range(1,6):
		var exists: bool = ColonyStore.occupied(number,store.root_directory)
		button(("Load" if exists else "New") + " campaign %d" % number,func() -> void: _switch_campaign(number,exists),sheet_body)

func _switch_campaign(number: int, exists: bool) -> void:
	if not exists:
		show_new_colony(number)
		return
	if not recovery_failed and not saving_disabled and not save_local().is_empty():
		return
	var candidate: ColonyStore = ColonyStore.new()
	candidate.root_directory = store.root_directory
	candidate.select_slot(number)
	var result: Dictionary
	if exists:
		result = candidate.load_latest()
	else:
		var fresh: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data(),Crypto.new().generate_random_bytes(16).hex_encode())
		var error: String = candidate.adopt(fresh,number)
		result = {"world":fresh} if error.is_empty() else {"error":error}
	if result.has("error"):
		notice = result.error
		return
	store = candidate
	_restore_camera()
	_replace_world(result.world)
	_save_settings()
	close_sheet()
	notice = "Campaign %d is ready. Time stays paused." % number

func show_import_slots() -> void:
	if pending_import_world == null:
		return
	show_sheet("Import campaign")
	label("The complete snapshot is verified. Select an empty campaign slot, or confirm replacement of a specific existing campaign. Your device settings are preserved.",sheet_body)
	for number in range(1,6):
		var exists: bool = ColonyStore.occupied(number,store.root_directory)
		button(("Replace" if exists else "Import into")+" campaign %d" % number,func() -> void:
			if exists:
				show_sheet("Confirm replacement")
				label("Replace campaign %d with the verified import? The previous campaign is archived before adoption. Every other campaign stays intact." % number,sheet_body)
				button("Replace campaign %d" % number,func() -> void: _adopt_import(number,true),sheet_body)
				button("Choose another slot",show_import_slots,sheet_body)
			else:
				_adopt_import(number,false),sheet_body)
	button("Cancel import",func() -> void:
		pending_import_world = null
		close_sheet()
		notice = "Import canceled. Campaigns unchanged.",sheet_body)

func _adopt_import(number: int, replace: bool) -> void:
	if pending_import_world == null:
		return
	if not recovery_failed and not saving_disabled and not save_local().is_empty():
		return
	var candidate: ColonyStore = ColonyStore.new()
	candidate.root_directory = store.root_directory
	var error: String = candidate.adopt(pending_import_world,number,replace)
	if not error.is_empty():
		notice = error
		return
	store = candidate
	_restore_camera()
	_replace_world(pending_import_world)
	_save_settings()
	pending_import_world = null
	close_sheet()
	notice = "Imported verified campaign %d. Time stays paused." % number

func show_named_snapshots() -> void:
	if not store is ColonyStore or recovery_failed:
		return
	show_sheet("Named snapshots")
	label("Ten named snapshots per campaign. Autosaves use their own three rotating generations. A full list requires choosing exactly which snapshot to replace.",sheet_body)
	for row in store.named_snapshots():
		label("%d: %s" % [row.index,row.name],sheet_body)
		if row.valid:
			button("Load snapshot %d" % row.index,func() -> void: _load_named(row.index),sheet_body)
		button(("Replace" if row.exists else "Save")+" snapshot %d" % row.index,func() -> void: _name_snapshot(row.index,row.exists,row.name),sheet_body)

func _name_snapshot(index: int, exists: bool, previous_name: String) -> void:
	show_sheet("Name snapshot")
	label("Replacing %s requires confirmation." % previous_name if exists else "Name this paused snapshot.",sheet_body)
	var entry: LineEdit = LineEdit.new()
	entry.placeholder_text = "Snapshot name"
	entry.max_length = 64
	entry.custom_minimum_size = Vector2(48,48)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet_body.add_child(entry)
	button("Continue" if exists else "Save snapshot",func() -> void:
		var snapshot_name: String = entry.text.strip_edges()
		if snapshot_name.is_empty():
			notice = "Enter a snapshot name."
			return
		if exists:
			show_sheet("Confirm snapshot replacement")
			label("Replace %s with %s? Only snapshot slot %d changes." % [previous_name,snapshot_name,index],sheet_body)
			button("Replace snapshot",func() -> void: _save_named(index,snapshot_name,true),sheet_body)
		else:
			_save_named(index,snapshot_name,false),sheet_body)
	entry.grab_focus()

func _save_named(index: int, name: String, replace: bool) -> void:
	var error: String = store.save_named(world,index,name,replace)
	if not error.is_empty():
		_storage_failed(error)
		return
	last_saved_tick = world.tick
	saving_disabled = false
	storage_error = ""
	show_named_snapshots()
	notice = "Named snapshot saved and verified."

func _load_named(index: int) -> void:
	if not saving_disabled and not save_local().is_empty():
		return
	var result: Dictionary = store.load_named(index)
	if result.has("error"):
		notice = result.error
		return
	store.recovered = true
	_replace_world(result.world)
	close_sheet()
	notice = "Named snapshot restored. Time stays paused."

func _restore_camera() -> void:
	if view == null or not store is ColonyStore:
		return
	var camera: Array = settings.values.cameras[store.slot-1]
	view.camera_tile = Vector2(camera[0],camera[1])
	view.tile_size = camera[2]
	view._update_transform()

func _save_settings() -> void:
	settings.values.text_scale = text_scale
	settings.values.left_handed = left_handed
	if store is ColonyStore:
		settings.values.last_slot = store.slot
		settings.values.cameras[store.slot-1] = [view.camera_tile.x,view.camera_tile.y,view.tile_size]
	var error: String = settings.save_local()
	if not error.is_empty():
		notice = error

func show_weather() -> void:
	show_sheet("Weather forecast")
	label("Today: %s, %d C\n%s" % [world.weather.replace("_"," "),ColonyLiving.temperature(world),ColonyWeather.describe(world.weather)],sheet_body)
	for entry in world.weather_state.days:
		if entry.day <= world.tick / 7200: continue
		label("%s %d Y%d: %s\n%s" % [["Spring","Summer","Autumn","Winter"][(entry.day/8)%4],entry.day%8+1,entry.day/32+1,entry.kind.replace("_"," "),ColonyWeather.describe(entry.kind)],sheet_body)
		if entry.kind == "flood":
			var food: int = 0
			var crop: int = 0
			for stack in world.stacks:
				if ColonyWeather.vulnerable(world,stack,entry.mask): food += stack.count / 2
			for field in world.fields:
				if field.ripe_tick > 0 and entry.mask.has(Vector2i(field.x,field.y)): crop += field.yield_count / 2
			label("Currently exposed: %d food units and %d ripe crop units. Move food or harvest before 06:00. This count assumes current positions and ripeness." % [food,crop],sheet_body)
			button("View flood area",func() -> void:
				view.forecast_mask.assign(entry.mask)
				view.camera_tile = Vector2(38,64)
				view.tile_size = 16
				close_sheet()
				notice = "Striped low ground floods from 06:00 to 18:00 on the forecast date. High ground is safe.",sheet_body)
	if not view.forecast_mask.is_empty():
		button("Hide flood preview",func() -> void:
			view.forecast_mask.clear()
			close_sheet(),sheet_body)

func show_work_preferences(id: int) -> void:
	var citizen: Dictionary = world.find(world.citizens,id)
	show_sheet(citizen.name+" - Work")
	label(citizen.activity+"\nCategories set to Off retain their queued jobs for other eligible workers. Hunger, sleep and taking a break come first.",sheet_body)
	button(citizen.shift,func() -> void:
		_submit("schedule",{"citizen":id,"shift":"Night shift" if citizen.shift == "Normal" else "Normal"}),sheet_body)
	for category in ColonyWorld.CATEGORIES:
		var entry: Button = button(category+": "+["Off","Last","Normal","First"][_queued_preference(id,category)],Callable(),sheet_body)
		entry.pressed.connect(func() -> void:
			var value: int = (_queued_preference(id,category)+1)%4
			_submit("preference",{"citizen":id,"category":category,"value":value})
			entry.text = category+": "+["Off","Last","Normal","First"][value]+" (pending)")
	button("All work orders",func() -> void:show_sheet("Work"),sheet_body)

func _queued_preference(id: int,category: String) -> int:
	var value: int = world.find(world.citizens,id).preferences[category]
	for command in world.pending_commands:
		if command.kind == "preference" and command.args.citizen == id and command.args.category == category: value = command.args.value
	return value

func show_person(id: int) -> void:
	var citizen: Dictionary = world.find(world.citizens,id)
	show_sheet(citizen.name)
	label("%s\nFood %d/1000 | Rest %d/1000 | Health %d\nMorale %d/1000\n%s | %s\n%s work, %s food" % [citizen.activity,citizen.fullness,citizen.rest,citizen.health,citizen.morale,citizen.traits[0],citizen.traits[1],citizen.preferred,citizen.food_tag],sheet_body)
	if citizen.health < 100: button("Care and recovery",show_care,sheet_body)
	label("Active morale causes",sheet_body)
	for term in citizen.mood_terms: label("%s: %+d" % [term,citizen.mood_terms[term]],sheet_body)
	button("Work preferences",func() -> void:show_work_preferences(id),sheet_body)
	button("View on map",func() -> void:
		close_sheet()
		select_citizen(id)
		view.camera_tile = Vector2(citizen.x,citizen.y),sheet_body)
	label("Relationships",sheet_body)
	for other in world.citizens:
		if other.id == id: continue
		var pair: Dictionary = world.social_state.pairs[ColonySocial.key(id,other.id)]
		label("%s: %s (%d)" % [other.name,"Friends" if pair.score >= 40 else ("Strained" if pair.score <= -40 else "Getting acquainted"),pair.score],sheet_body)
		if pair.conflict_until > world.tick:
			button("Mediate with "+other.name,func() -> void:
				_submit("mediate",{"definition":ColonySocial.key(id,other.id)})
				close_sheet(),sheet_body)
	for request in world.social_state.requests:
		if request.actor != id or request.state not in ["Offered","Accepted"]: continue
		label(ColonySocial.TITLES[request.kind]+" | "+request.state,sheet_body)
		label({"quiet_bed":"Assign a bed in a roofed room with at most two beds.","garden_seat":"Build a garden bench within 3 tiles of four planted field tiles.","supper":"Finish half an hour of leisure at one table with two other residents.","learn":"Complete 60 WU of research after this offer.","tool":"Equip a forged toolkit.","valley":"Return from a successful expedition after this offer."}[request.kind],sheet_body)
		if request.state == "Offered":
			label("Optional. Accepting gives four days; decline without a penalty. Success gives +100 morale target for two days; an accepted promise that expires gives -60 for two days.",sheet_body)
			button("Accept - four days",func() -> void:
				_submit("request_accept",{"target":request.id})
				close_sheet(),sheet_body)
			button("Decline without penalty",func() -> void:
				_submit("request_decline",{"target":request.id})
				close_sheet(),sheet_body)
		else:
			label("Deadline: %s %d at %02d:00 | about %.1f days left" % [["Spring","Summer","Autumn","Winter"][(request.deadline/57600)%4],(request.deadline/7200)%8+1,(request.deadline%7200)/300,maxf(0,float(request.deadline-world.tick)/7200.0)],sheet_body)

func show_research() -> void:
	show_sheet("Research")
	label("One active project, up to two desks. Each productive WU adds one point; switching keeps progress. Build a research desk and enable Research work to begin.",sheet_body)
	label("Active: "+("None" if world.production_state.project.is_empty() else _catalog_name(world.production_state.project))+"\nQueue: "+", ".join(world.production_state.queue.map(_catalog_name))+"\nBanked insight: %d" % world.production_state.insight,sheet_body)
	for id in world.definitions.research:
		var definition: Dictionary = world.definitions.research[id]
		var missing: Array = definition.prerequisites.filter(func(p:Variant)->bool:return not world.researched.has(p))
		label("%s | %d/%d points\n%s" % [id.capitalize(),world.production_state.progress.get(id,0)/1000,definition.points,"Complete" if world.researched.has(id) else ("Available" if missing.is_empty() else "Requires "+", ".join(missing))],sheet_body)
		label("Unlocks: "+", ".join(definition.unlocks.map(_catalog_name)),sheet_body)
		if not world.researched.has(id):
			if missing.is_empty():
				button("Study "+id.capitalize(),func() -> void:
					_submit("research_select",{"definition":id})
					close_sheet(),sheet_body)
			button("Queue "+id.capitalize(),func() -> void:
				_submit("research_queue",{"definition":id})
				close_sheet(),sheet_body)

func show_station(station: Dictionary) -> void:
	show_sheet(station.definition.replace("_"," ").capitalize())
	var definition: Dictionary = world.definitions.buildings[station.definition]
	label("Health %d/%d | %s\n%s" % [station.health,definition.health,"Flammable" if definition.flammable else "Does not spread fire",("Store capacity %d" % definition.storage_capacity) if definition.storage_capacity > 0 else "Work needs inputs and an eligible resident"],sheet_body)
	if station.definition == "hearth":
		label("Without production orders, cooking keeps four meals per living resident. Adding a policy replaces that default; Repeat stops after its batch count. Choose Maintain for a steady meal reserve.",sheet_body)
	if station.definition == "fishing_pier":
		var fish: Dictionary = world.nature_state.fishing
		label("Fishing: 12 WU for two fish. Pier %d/8, entire river %d/16 caught this day. Limits recover at 06:00; output must be hauled and cooked." % [fish.piers.get(station.id,0),fish.river],sheet_body)
	if station.definition == "research_desk":
		button("Research projects",show_research,sheet_body)
	for recipe in world.definitions.recipes.values():
		if recipe.station != station.definition: continue
		label("%s\n%s -> %s | %d WU" % [recipe.id.replace("_"," ").capitalize(),_cost_text(recipe.materials)+(" + %d allowed food units" % recipe.food_count if recipe.food_count > 0 else ""),_cost_text(recipe.outputs),recipe.work_milli/1000],sheet_body)
		if recipe.unlock != "initial" and not world.researched.has(recipe.unlock):
			label("Requires "+recipe.unlock.capitalize()+" research.",sheet_body)
			button("Show research",show_research,sheet_body)
		else:
			button("Make one batch",func() -> void:
				_submit("recipe_order",{"target":station.id,"definition":recipe.id,"mode":"Repeat","value":1,"priority":2,"filters":recipe.alternatives.duplicate()})
				close_sheet(),sheet_body)
			button("Set production policy",func() -> void: show_recipe_policy(station,recipe),sheet_body)
	for order in world.production_state.orders:
		if order.station != station.id: continue
		label("%s | %s %d | %s" % [order.recipe.replace("_"," "),order.mode,order.quantity,"Enabled" if order.enabled else "Paused"],sheet_body)
		button("Pause order" if order.enabled else "Resume order",func() -> void:
			_submit("order_enabled",{"target":order.id,"enabled":not order.enabled})
			close_sheet(),sheet_body)
	button("Suspend station" if station.cooking else "Enable station",func() -> void:
		_submit("station_enabled",{"target":station.id,"enabled":not station.cooking})
		close_sheet(),sheet_body)
	if definition.storage_capacity > 0:
		button("Storage filters and priority",func() -> void: _storage_sheet(world.find(world.stores,station.id)),sheet_body)

func _catalog_name(id: String) -> String:
	var key: String = id.get_slice(":",1) if id.contains(":") else id
	if catalog_strings.is_empty(): catalog_strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalogs/en_colony_v2.json"))
	return catalog_strings.get(key+".name",key.replace("_"," ").capitalize())

func show_recipe_policy(station: Dictionary, recipe: Dictionary) -> void:
	show_sheet("Production policy")
	label(_catalog_name(recipe.id)+" at "+_catalog_name(station.definition),sheet_body)
	label("Repeat counts completed batches. Maintain counts available home stock and unfinished outputs. One station works on one batch at a time; existing inputs keep their age.",sheet_body)
	var mode: CycleChoiceButton = CycleChoiceButton.new()
	mode.add_item("Repeat batches"); mode.add_item("Maintain quantity")
	mode.custom_minimum_size = Vector2(48,48)
	sheet_body.add_child(mode)
	var quantity: SpinBox = SpinBox.new()
	quantity.min_value = 1; quantity.max_value = 1000; quantity.value = 4
	quantity.custom_minimum_size = Vector2(96,48)
	sheet_body.add_child(quantity)
	var priority: CycleChoiceButton = CycleChoiceButton.new()
	for name in ["Low priority","Normal priority","Urgent priority"]: priority.add_item(name)
	priority.select(1); priority.custom_minimum_size = Vector2(48,48)
	sheet_body.add_child(priority)
	var choices: Dictionary = {}
	for item in recipe.alternatives:
		var choice: CheckButton = CheckButton.new()
		choice.text = "Allow "+_catalog_name(item)
		choice.button_pressed = true
		choice.custom_minimum_size = Vector2(48,48)
		sheet_body.add_child(choice)
		choices[item] = choice
	button("Add order",func() -> void:
		var filters: Array = choices.keys().filter(func(id:Variant)->bool:return choices[id].button_pressed)
		if recipe.food_count > 0 and filters.is_empty():
			notice = "Allow at least one food ingredient."
			return
		_submit("recipe_order",{"target":station.id,"definition":recipe.id,"mode":"Repeat" if mode.selected == 0 else "Maintain","value":int(quantity.value),"priority":priority.selected+1,"filters":filters})
		close_sheet(),sheet_body)

func show_mode() -> void:
	show_sheet("Colony mode")
	label("Standard allows sustained hunger and untreated injuries to cause death. Hearthside disables scheduled raids; at zero health a resident recovers for two days and wakes at 40 health. Weather, shortages and conflicts still apply. Changes affect future rules and do not resurrect anyone.",sheet_body)
	for mode in ["Standard","Hearthside"]:
		button("Choose "+mode,func()->void:
			_submit("care_mode",{"mode":mode})
			close_sheet(),sheet_body)

func show_care() -> void:
	show_sheet("Injuries and care")
	label("Rescue carries a downed person to the nearest reachable bed or cart rally and slows the carrier by 25%. Emergency rescue and urgent stabilization in place override Care Off. Ordinary treatment needs Care enabled; Treat now pins one visible override. Patients receive food automatically and rest until 50 health before working.",sheet_body)
	for patient in world.citizens:
		if patient.death_recorded or patient.departed or patient.health >= 100: continue
		var activity: String = ("Downed: bleeding, needs care" if not patient.stabilized else "Downed: recovering") if patient.downed else patient.activity
		label("%s | Health %d/100 | Food %d/1000 | Rest %d/1000\n%s" % [patient.name,patient.health,patient.fullness,patient.rest,activity],sheet_body)
		if patient.hearthside_until > world.tick:
			label("Hearthside recovery: %.1f days until waking at 40 health." % [float(patient.hearthside_until-world.tick)/7200],sheet_body)
		elif not patient.stabilized:
			label("Bleeding: 2 health/hour. About %.1f hours until zero health without care." % [float(((patient.health+1)/2)*300-patient.bleed_ticks)/300],sheet_body)
		else:
			var rate: int = patient.recovery_rate if patient.recovery_until > world.tick else 2
			label("Stabilized. Resting restores %d health/hour; about %.1f hours to work at 50 health. Treatment recovery lasts 12 hours, then resting gives 2/hour." % [rate,float(maxi(0,50-patient.health))/rate],sheet_body)
		label("Stabilize: no input, 24 WU, 2 health/hour. Herb: one herb, 16 WU, +10 health and 4/hour. Medicine: one medicine, 10 WU, +20 health and 8/hour. Strongest available treatment is selected; rates do not stack.",sheet_body)
		if patient.hearthside_until == 0:
			for worker in world.citizens:
				if worker.id == patient.id or worker.health < 50 or worker.departed: continue
				button("Treat with "+worker.name,func()->void:
					_submit("treat_now",{"target":patient.id,"citizen":worker.id})
					close_sheet(),sheet_body)
	for body in world.care_state.bodies:
		if body.buried: continue
		var person: Dictionary = world.find(world.citizens,body.patient)
		label(person.name+" died. Nearby unburied remains give -40 morale. Grief declines over two days, or three for friends.",sheet_body)
		button("Mark burial here",func()->void:
			_submit("burial",{"target":body.id,"x":body.x,"y":body.y})
			close_sheet(),sheet_body)
	if world.citizens.all(func(c:Dictionary)->bool:return c.downed or c.death_recorded or c.departed):
		label("Everyone at home is downed. Available recovery is shown above. In Standard an unstabilized patient continues bleeding; Hearthside recovery continues with time.",sheet_body)
	button("Work preferences",func()->void:show_sheet("Work"),sheet_body)

func show_epilogue() -> void:
	runner.pause()
	show_sheet("Colony epilogue")
	label("No living residents remain in this colony. The journal and saves retain their history. Load an earlier save or begin a new campaign.",sheet_body)
	button("Load save",show_named_snapshots,sheet_body)
	button("New colony with this seed",show_seed_restart,sheet_body)
	button("Return to menu",func()->void: show_sheet("Menu"),sheet_body)

func show_seed_restart() -> void:
	show_sheet("New colony with this seed")
	label("Seed %d. Choose a campaign slot; an occupied slot is archived only after confirmation. Other campaigns stay intact." % world.seed,sheet_body)
	for number in range(1,6):
		var exists: bool = ColonyStore.occupied(number,store.root_directory)
		button(("Replace" if exists else "New")+" campaign %d" % number,func()->void:
			if exists:
				show_sheet("Confirm new colony")
				label("Archive campaign %d and start again with seed %d?" % [number,world.seed],sheet_body)
				button("Archive and restart",func()->void:_restart_seed(number,true),sheet_body)
			else: _restart_seed(number,false),sheet_body)

func _restart_seed(number: int, replace: bool) -> void:
	_create_new_colony(number,world.seed,world.site_id,world.care_state.mode,replace)

func show_new_colony(number: int) -> void:
	show_sheet("New colony")
	label("Campaign %d | Mira, Oren, Tavi, Sela\nSafe home, 8 x 8 field, nearby food/deposits.\nFirst days: Clear, Rain, Clear." % number,sheet_body)
	var site: CycleChoiceButton = CycleChoiceButton.new()
	for name in ["Meadow Reach","Pine Shelf","Reed Bend"]: site.add_item(name)
	site.custom_minimum_size = Vector2(48,48)
	sheet_body.add_child(site)
	var description: Label = label("",sheet_body)
	var descriptions: Array[String] = ["Balanced ground. Poor/normal/rich soil 15/65/20%; trees 22%; floodplain width 4.","More forest and four extra stone deposits. Soil 30/60/10%; trees 36%; floodplain width 3.","Fertile ground and three extra clay deposits. Soil 10/45/45%; trees 18%; floodplain width 6."]
	description.text = descriptions[0]
	site.item_selected.connect(func(index:int)->void:description.text = descriptions[index])
	var seed_entry: LineEdit = LineEdit.new()
	seed_entry.placeholder_text = "Unsigned 32-bit seed"
	seed_entry.max_length = 10; seed_entry.custom_minimum_size = Vector2(48,48)
	var random_bytes: PackedByteArray = Crypto.new().generate_random_bytes(4)
	var seed_value: int = (int(random_bytes[0])<<24)|(int(random_bytes[1])<<16)|(int(random_bytes[2])<<8)|int(random_bytes[3])
	seed_entry.text = str(seed_value)
	sheet_body.add_child(seed_entry)
	label("Seed 0 to 4294967295. Same seed and site give the same map; saves keep their geography.",sheet_body)
	var mode: CycleChoiceButton = CycleChoiceButton.new()
	mode.add_item("Standard"); mode.add_item("Hearthside")
	mode.custom_minimum_size = Vector2(48,48); sheet_body.add_child(mode)
	label("Standard: raids; untreated injuries can kill.\nHearthside: no raids; at zero health, rest two days and wake at 40. Both retain weather and shortages.",sheet_body)
	var create: Button = button("Create colony",func()->void:
		var entered: String = seed_entry.text.strip_edges()
		if entered.is_empty():
			var bytes: PackedByteArray = Crypto.new().generate_random_bytes(4)
			entered = str((int(bytes[0])<<24)|(int(bytes[1])<<16)|(int(bytes[2])<<8)|int(bytes[3]))
			seed_entry.text = entered
		if not entered.is_valid_int() or entered.begins_with("-") or entered.begins_with("+") or int(entered) > 4294967295:
			notice = "Enter a decimal seed from 0 to 4294967295."
			return
		var selected_site: String = ["meadow_reach","pine_shelf","reed_bend"][site.selected]
		_create_new_colony(number,int(entered),selected_site,"Standard" if mode.selected == 0 else "Hearthside",false),sheet_body)
	create.name = "CreateColony"

func _create_new_colony(number: int, seed_value: int, site: String, mode: String, replace: bool) -> void:
	if creation_thread != null and creation_thread.is_started(): return
	if not recovery_failed and not saving_disabled and not save_local().is_empty(): return
	show_sheet("Growing the valley")
	label("Preparing and checking seed %d at %s. Time stays paused." % [seed_value,_catalog_name(site)],sheet_body)
	var definitions: Dictionary = world.definitions.duplicate(true)
	var campaign_id: String = Crypto.new().generate_random_bytes(16).hex_encode()
	creation_thread = Thread.new()
	var error: Error = creation_thread.start(func()->Dictionary:
		var fresh: ColonyWorld = ColonyWorld.new(definitions,campaign_id)
		var problem: String = ColonyGeneration.configure(fresh,seed_value,site)
		fresh.care_state.mode = mode
		return {"world":fresh} if problem.is_empty() else {"error":problem})
	if error != OK:
		creation_thread = null
		notice = "Could not start generation. Try another seed."
		return
	await get_tree().process_frame
	while creation_thread.is_alive(): await get_tree().process_frame
	var result: Dictionary = creation_thread.wait_to_finish()
	creation_thread = null
	if result.has("error"):
		show_sheet("Generation problem")
		label(result.error,sheet_body)
		button("Choose another seed",func()->void:show_new_colony(number),sheet_body)
		return
	if not awaiting_first_colony and not recovery_failed and not saving_disabled and not save_local().is_empty(): return
	var candidate: ColonyStore = ColonyStore.new()
	candidate.root_directory = store.root_directory
	var problem: String = candidate.adopt(result.world,number,replace)
	if not problem.is_empty(): notice = problem; return
	store = candidate
	awaiting_first_colony = false
	_replace_world(result.world)
	var cart: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition == "supply_cart")[0]
	view.camera_tile = Vector2(cart.x+1,cart.y+1)
	_save_settings()
	show_sheet("Welcome")
	if world.terrain_state.fallback: notice = "This seed uses the verified fallback layout. See generation details in Menu."

func _exit_tree() -> void:
	if creation_thread != null and creation_thread.is_started(): creation_thread.wait_to_finish()

func _home_tile(point: Vector2i) -> Vector2i:
	return ColonyGeneration.transformed(point,world.terrain_state.transform) if world is ColonyWorld and world.generator_version > 0 else point

func show_map_details() -> void:
	show_sheet("Map and seed")
	label("%s | Seed %d" % [_catalog_name(world.site_id),world.seed],sheet_body)
	if world.generator_version == 0:
		label("This campaign keeps its original starter map. New campaigns offer all three sites and a seed choice.",sheet_body)
	elif world.terrain_state.fallback:
		label("Verified fallback layout: normal soil, standard floodplain width four, protected starter field and complete resource/habitat guarantees. The selected site's extra deposits remain. The displayed seed is preserved.",sheet_body)
	else:
		label("Generated terrain is stored with the campaign and retained across updates. All starter resources, safe home ground and habitat checks passed.",sheet_body)
		label("Generation attempt %d" % world.terrain_state.attempt,sheet_body)
	button("Show weather",show_weather,sheet_body)

func begin_forest() -> void:
	begin_placement()
	placement_kind = "forest"
	view.preview_start = _home_tile(Vector2i(48,54)); view.preview_end = _home_tile(Vector2i(55,69))
	view.camera_tile = Vector2(view.preview_start+view.preview_end)*0.5
	view._update_transform()
	notice = "Drag around trees. The forest keeps 75% mature and replants cut cells; individual cuts can go below that reserve."

func show_forest(zone: Dictionary) -> void:
	show_sheet("Forest zone")
	var trees: Array = world.resources.filter(func(r:Dictionary)->bool:return r.definition == "tree" and zone.tiles.has(Vector2i(r.x,r.y)))
	var mature: int = trees.filter(func(r:Dictionary)->bool:return r.remaining > 0).size()
	label("%d mature / %d tree sites. Automatic cutting keeps at least %d mature, rounded up. Explicit cuts may go below the reserve. Replanting costs 4 WU; maturity takes eight non-winter days." % [mature,trees.size(),(trees.size()*zone.reserve+99)/100],sheet_body)
	button("Reserve: %d%%" % zone.reserve,func()->void:
		_submit("forest_policy",{"target":zone.id,"value":100 if zone.reserve == 75 else (50 if zone.reserve == 100 else 75),"enabled":zone.enabled})
		close_sheet(),sheet_body)
	button("Pause forest" if zone.enabled else "Enable forest",func()->void:
		_submit("forest_policy",{"target":zone.id,"value":zone.reserve,"enabled":not zone.enabled})
		close_sheet(),sheet_body)

func show_wildlife() -> void:
	show_sheet("Wildlife")
	label("Wild animals forage and flee. Mark a hunt after reviewing its weapon and escort needs. Carcasses require butchering and spoil in two days.",sheet_body)
	for animal in world.wildlife_state.animals:
		if animal.health<=0: continue
		button("%s · health %d" % [_catalog_name(animal.definition),animal.health],func()->void:
			view.camera_tile = Vector2(animal.x,animal.y); _wildlife_sheet(animal),sheet_body)

func _wildlife_sheet(animal: Dictionary) -> void:
	show_sheet(_catalog_name(animal.definition))
	var definition: Dictionary = world.definitions.animals[animal.definition]
	label("Health %d/%d. %s" % [animal.health,definition.health,catalog_strings.get(animal.definition+".description","")],sheet_body)
	label("After butchering (%d WU): %s. Carcass spoils in two days; outputs need hauling. Hunters retreat at health 40." % [definition.work_milli/1000,_cost_text(definition.outputs)],sheet_body)
	if world.jobs.any(func(j:Dictionary)->bool:return j.kind == "hunt" and j.target == animal.id and j.state not in ["Complete","Canceled"]):
		label("Hunt marked. Eligible armed Gathering workers take this job; an armed Guard worker escorts a boar hunt.",sheet_body)
		for job in world.jobs:
			if job.kind == "hunt" and job.target == animal.id and job.state not in ["Complete","Canceled"]: button("Inspect hunt",func()->void:_job_sheet(job),sheet_body)
		return
	label("Bows can reach fleeing wildlife from six tiles. Spear hunters must catch it at one tile. Choose a hunter, or leave assignment automatic.",sheet_body)
	var hunter_ids: Array = [0]
	var hunter: CycleChoiceButton = CycleChoiceButton.new()
	hunter.add_item("Hunter: automatic")
	var recommended: int = 0
	for citizen in world.citizens:
		if citizen.death_recorded or citizen.departed or citizen.downed or citizen.equipment.weapon.is_empty() or citizen.preferences.Gathering==0: continue
		hunter_ids.append(citizen.id); hunter.add_item("Hunter: "+citizen.name+" ("+citizen.equipment.weapon+")")
		if citizen.equipment.weapon == "bow" and recommended == 0: recommended = hunter_ids.size()-1
	hunter.select(recommended); hunter.custom_minimum_size.y = 48; sheet_body.add_child(hunter)
	button("Hunt with armed escort" if animal.definition == "boar" else "Hunt",func()->void:
		_submit("hunt",{"target":animal.id,"solo":false,"citizen":hunter_ids[hunter.selected]}); close_sheet(),sheet_body)
	if animal.definition == "boar":
		button("Solo hunt risk…",func()->void:
			var chosen: int = hunter_ids[hunter.selected]
			show_sheet("Solo boar hunt")
			label("A wounded boar deals 12 damage every 25 ticks at one tile, and charges nearby people. A solo hunter has no escort. Retreat begins at health 40; injury may require rescue and treatment.",sheet_body)
			button("Confirm solo hunt",func()->void:_submit("hunt",{"target":animal.id,"solo":true,"citizen":chosen});close_sheet(),sheet_body),sheet_body)

func begin_pen() -> void:
	begin_placement();placement_kind="pen"
	notice="Paint inside completed fences or walls. A gate permits handlers to lead animals. Each animal needs four free tiles and one barn shelter slot."

func show_pens() -> void:
	show_sheet("Livestock pens")
	label("Husbandry unlocks pens and animal acquisition. Build fences/gates and a touching or enclosed barn, then paint the interior. Animals workers lead livestock, move real feed and collect products. Each barn holds six animals, 24 feed units and 24 output units.",sheet_body)
	button("Paint pen",begin_pen,sheet_body)
	for pen in world.domestic_state.pens:
		var info: Dictionary = ColonyDomestic.status(world,pen)
		button("Pen %d · %d/%d animals" % [pen.id,info.count,info.capacity],func()->void:show_pen(pen),sheet_body)

func show_pen(pen: Dictionary) -> void:
	show_sheet("Livestock pen")
	var info: Dictionary = ColonyDomestic.status(world,pen)
	var animals: Array = ColonyDomestic.occupants(world,pen.id)
	var daily: int = 0
	for animal in animals:
		if not animal.away: daily += ColonyDomestic.demand(world,animal,world.tick/7200+1)
	label("%d/%d animals. Four interior tiles and one shelter slot each; colony limit twelve. Feed demand: %d grain/vegetable units per day, removed at 06:00. Animals Off stops stocking and collection." % [info.count,info.capacity,daily],sheet_body)
	label(info.error if not info.error.is_empty() else pen.reason,sheet_body)
	for barn in info.barns:
		label("Barn %d: feed %d/24 · products %d/24. Fed adults accrue up to two days of products; collection costs 4 WU." % [barn,ColonyDomestic.feed_count(world,barn),ColonyDomestic.output_count(world,barn)],sheet_body)
	label("Breeding: one juvenile after eight days with two fed adults and spare space/shelter. Blocked births never accumulate. Juveniles mature in four days and eat half adult feed; hens alternate whole-unit feeding days.",sheet_body)
	button("Disable breeding" if pen.breeding else "Enable breeding",func()->void:_submit("breeding",{"target":pen.id,"enabled":not pen.breeding});close_sheet(),sheet_body)
	for animal in animals: button(animal.name+" · health "+str(animal.health),func()->void:show_domestic_animal(animal),sheet_body)

func show_domestic_animal(animal: Dictionary) -> void:
	show_sheet(animal.name)
	var definition: Dictionary = world.definitions.animals[animal.definition]
	label("%s · health %d/%d. %s" % [_catalog_name(animal.definition),animal.health,definition.health,"Juvenile: %.1f days until maturity" % ((animal.juvenile_until-world.tick)/7200.0) if animal.juvenile_until>world.tick else "Adult"],sheet_body)
	label("%d unfed days. Two days of grace; then 10 health/day. Feeding restores 10/day. %d products await collection; no milk from goats away on expedition." % [animal.unfed,animal.pending],sheet_body)
	button("Inspect pen",func()->void:show_pen(world.find(world.domestic_state.pens,animal.pen)),sheet_body)
	if animal.away: label("Away on expedition; local work unavailable.",sheet_body);return
	button("Slaughter…",func()->void:
		show_sheet("Slaughter "+animal.name)
		label("Confirm slaughter of %s? Ten WU produces %s. This kills this named animal. Slaughter and breeding are optional; the charter can be completed without them." % [animal.name,_cost_text(definition.slaughter_outputs)],sheet_body)
		button("Confirm slaughter "+animal.name,func()->void:_submit("slaughter",{"target":animal.id});close_sheet(),sheet_body),sheet_body)

func begin_lodge() -> void:
	begin_placement();placement_kind="lodge";view.preview_lodge=true
	view.preview_start=_home_tile(Vector2i(74,54));view.fit_build_preview();view.camera_tile=Vector2(view.preview_start+Vector2i(4,3));rotation_button.visible=false
	notice="Four beds, 23 walls and a south door. W73 F8; 206 WU. Clear an 8×6 footprint; the preset uses normal blueprints and can be edited individually."
