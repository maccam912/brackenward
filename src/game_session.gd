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
var sheet_camera_center: Vector2 = Vector2.ZERO
var text_scale: float = 1.0
var left_handed: bool = false
var logical_scale: float = 1.0
var notice: String = "Four travelers. A ruined wayhouse. Make a place to stay."
var submitted_command: int = 0
var backgrounded: bool = false
var last_saved_tick: int = 1800
var autosave_elapsed: float = 0.0
var journal_elapsed: float = 0.0
var save_queue: ColonySaveQueue = ColonySaveQueue.new()
var save_clock: float = 0.0
var durable_at: float = 0.0
var save_requested_at: float = 0.0
var file_dialog: FileDialog
var catalog_strings: Dictionary = {}
var seen_care_alert: int = -1
var seen_region_alert: int = -1
var seen_fire_alert: int = -1
var seen_defense_alert: int = -1
var seen_opportunity_id: int = 0
var defend_citizens: Array = []
var defend_stand_fast: bool = false
var epilogue_session: String = ""
var charter_epilogue_session: String = ""
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
var moving_target: int = 0
var placement_cache_key: String = ""
var placement_cache: Dictionary = {}
var forecast_elapsed: float = 0.0
var food_warning_level: int = 0
var saving_disabled: bool = false
var storage_error: String = ""
var recovery_failed: bool = false
var settings: DeviceSettings = DeviceSettings.new()
var pending_import_world: ColonyWorld
var guidance_panel: PanelContainer
var guidance_text: Label
var guidance_forecast: Label
var guidance_actions: HBoxContainer
var guidance_forecast_button: Button
var guidance_card: Dictionary = {}
var guidance_elapsed: float = 1.0
var guidance_signature: String = ""
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
	_build_guidance()
	resized.connect(_resize)
	_layout()
	show_sheet("Welcome")
	if recovery_failed:
		show_recovery_problem()
	elif store is ColonyStore and store.root_directory == ColonyStore.CAMPAIGN_ROOT and not ColonyStore.occupied(store.slot):
		awaiting_first_colony = true
		show_new_colony(store.slot)
	if world is ColonyWorld and not awaiting_first_colony: save_queue.prime(world)

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
	var help: Button = button("?",show_tutorials,speeds)
	help.tooltip_text="Lessons and food forecast"

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
	save_clock+=delta
	_finish_background_save()
	if store is ColonyStore and world.tick==store.journal_tick: durable_at=save_clock
	if _storage_wait_required() and runner.speed>0:
		runner.pause()
		notice="Saving is slow; paused to protect recent progress. Resume after saving finishes."
	runner.advance_frame(delta)
	guidance_elapsed += delta
	if world is ColonyWorld:
		var signature: String = world.session_id+JSON.stringify(_tutorial_state())
		if guidance_elapsed>=1.0 or signature!=guidance_signature:
			_refresh_guidance()
		if is_instance_valid(guidance_panel): _layout_guidance()
	if world is ColonyWorld:
		if world.charter_state.ending and not world.charter_state.continued and charter_epilogue_session!=world.session_id:
			charter_epilogue_session=world.session_id
			show_charter_ending()
		if world.care_state.ended:
			seen_care_alert = world.care_state.alert_serial
			if epilogue_session != world.session_id:
				epilogue_session = world.session_id
				show_epilogue()
		elif world.care_state.alert_serial > seen_care_alert:
			seen_care_alert = world.care_state.alert_serial
			if world.citizens.any(func(c:Dictionary)->bool:return c.downed or c.death_recorded): show_care()
	if world is ColonyWorld and world.region_state.alert_serial>seen_region_alert:
		seen_region_alert=world.region_state.alert_serial
		if ColonyRegion.critical(world): show_expeditions()
	if world is ColonyWorld and world.fire_state.alert_serial>seen_fire_alert:
		seen_fire_alert=world.fire_state.alert_serial
		if not ColonyFire.active(world).is_empty(): show_fires()
	if world is ColonyWorld and world.defense_state.alert_serial>seen_defense_alert:
		seen_defense_alert=world.defense_state.alert_serial
		if not ColonyDefense.active(world).is_empty(): show_defense()
	if world is ColonyWorld:
		for event in world.opportunity_state.offers:
			if event.id<=seen_opportunity_id: continue
			seen_opportunity_id=event.id
			if event.state=="Offered": notice=event.definition.replace("_"," ").capitalize()+" offer: open Valley > Visitor opportunities. Two game days; declining has no penalty."
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
	if store is ColonyStore and journal_elapsed >= 1.0 and not save_queue.busy() and not saving_disabled and not recovery_failed and not awaiting_first_colony:
		if world.tick!=store.journal_tick: _start_background_save(false)
		journal_elapsed = 0.0
	autosave_elapsed += delta
	if autosave_elapsed >= 30.0 and world.tick != last_saved_tick and not saving_disabled and not recovery_failed and not awaiting_first_colony:
		if store is ColonyStore:
			if not save_queue.busy():
				_start_background_save(true)
				autosave_elapsed = 0.0
		else:
			save_local()
			autosave_elapsed = 0.0

func _start_background_save(full_snapshot: bool) -> void:
	save_requested_at=save_clock
	var error: String = save_queue.start(store,world,full_snapshot)
	if not error.is_empty(): _storage_failed(error)

func _finish_background_save(wait: bool = false, report_error: bool = true) -> String:
	var result: Dictionary = save_queue.poll(wait)
	if result.is_empty(): return ""
	if result.world!=world or result.store!=store: return result.error
	if not result.error.is_empty():
		if report_error: _storage_failed(result.error)
		return result.error
	durable_at=save_requested_at
	if result.snapshot:
		last_saved_tick=result.tick
		_save_settings()
	return ""

func _storage_wait_required() -> bool:
	return store is ColonyStore and not saving_disabled and not recovery_failed and not awaiting_first_colony and world.tick!=store.journal_tick and save_clock-durable_at>=1.75

func set_speed(value: int) -> void:
	if value>0 and _storage_wait_required():
		notice="Saving is still in progress. Resume after saving finishes."
		return
	if value > 0 and creation_thread != null and creation_thread.is_started():
		notice = "Map generation is still running. Time stays paused."
		return
	if value > 0 and awaiting_first_colony:
		show_new_colony(store.slot)
		return
	if value>0 and world is ColonyWorld and world.charter_state.ending and not world.charter_state.continued and not world.pending_commands.any(func(c:Dictionary)->bool:return c.kind=="continue_settlement"):
		show_charter_ending();return
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
	var center: Vector2 = sheet_camera_center if sheet!=null and view.follow_id>0 else view.camera_center()
	view.follow_id=0
	close_sheet()
	runner.pause()
	confirm_button.disabled = submitted_command>0
	view.cancel_gesture()
	view.follow_id = 0
	view.preview_visible = true
	view.preview_definition = ""
	view.preview_line=false;view.preview_lodge=false;view.rejected_build_tiles.clear()
	moving_target=0;paint_build_definition="";placement_cache_key="";placement_cache.clear()
	view.preview_resource = ""
	placement_kind = "stockpile"
	rotation_button.visible = false
	view.gestures.mode = "paint"
	placement.visible = true
	notice = "Tap for one tile or drag an area, then Confirm. Dragging never submits an order."
	_layout()
	view.center_camera(center)
	view.preview_start = view.screen_to_tile(view.size * 0.5)
	view.preview_end = view.preview_start

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
		var error: String = ColonyMaintenance.cart_position_error(world,world.find(world.structures,moving_target),view.preview_start) if placement_kind=="cart_move" else world.placement_error(view.preview_definition,view.preview_start,view.preview_rotation,0,moving_target)
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
	if world is ColonyWorld and placement_kind=="rally":
		submitted_command=world.queue_command("draft",{"citizens":defend_citizens.duplicate(),"rally":Vector2i((view.preview_start.x+view.preview_end.x)/2,(view.preview_start.y+view.preview_end.y)/2),"stand_fast":defend_stand_fast})
	elif world is ColonyWorld and placement_kind == "cart_move":
		submitted_command=world.queue_command("cart_move",{"target":moving_target,"x":view.preview_start.x,"y":view.preview_start.y})
	elif world is ColonyWorld and placement_kind == "move_furniture":
		submitted_command=world.queue_command("move_furniture",{"target":moving_target,"x":view.preview_start.x,"y":view.preview_start.y,"rotation":view.preview_rotation})
	elif world is ColonyWorld and placement_kind == "lodge":
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
		if world is ColonyWorld and (citizen.death_recorded or citizen.departed or citizen.carried_by>0 or not ColonyRegion.visible(world,citizen)): continue
		var separation: float = view.tile_to_screen(view.citizen_point(citizen)).distance_to(action.point)
		if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"citizen","object":citizen,"rank":0,"distance":separation})
	if world is ColonyWorld:
		for enemy in world.defense_state.enemies:
			if enemy.state=="Gone": continue
			var separation: float = view.tile_to_screen(Vector2(enemy.x+0.5,enemy.y+0.5)).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"enemy","object":enemy,"rank":1,"distance":separation})
		for visitor in world.opportunity_state.visitors:
			if visitor.state in ["Waiting","Gone"]: continue
			var separation: float = view.tile_to_screen(Vector2(visitor.x+0.5,visitor.y+0.5)).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"visitor","object":visitor,"rank":1,"distance":separation})
		for merchant in world.trade_state.merchants:
			if merchant.state not in ["Entering","Trading","Leaving"]: continue
			var separation: float = view.tile_to_screen(Vector2(merchant.x+0.5,merchant.y+0.5)).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"merchant","object":merchant,"rank":1,"distance":separation})
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
			var title: String = candidate.object.get("name",("Ruins: " if candidate.kind=="station" and candidate.object.health<=0 else candidate.kind+": ")+candidate.object.get("definition",candidate.object.get("crop","")))
			if candidate.kind=="merchant": title=candidate.object.community.capitalize()+" merchant"
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
		"visitor": show_opportunities()
		"enemy": show_enemy(object)
		"merchant":
			if object.state=="Trading": show_trade(object)
			else: show_valley()
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
	var citizen: Dictionary = world.find(world.citizens,id) if world is ColonyWorld else world.citizens[id-1]
	inspector_details = label("", rows)
	_update_inspector()
	if world is ColonyWorld: button("Assign bed",func()->void:show_beds(id),rows)
	var actions: HBoxContainer = HBoxContainer.new()
	inspector_rows.add_child(actions)
	button("Follow", func() -> void:
		view.follow_id = id;_tutorial_action("follow",{"citizen":id});_refresh_guidance(), actions, 80)
	button("Close", close_inspector, actions, 64)
	_layout()

func close_inspector() -> void:
	if inspector != null:
		inspector.queue_free()
		inspector = null
	selected = 0
	view.selected_id = 0

func show_sheet(title: String) -> void:
	if sheet==null: sheet_camera_center=view.camera_center()
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
				_tutorial_begin();close_sheet();_refresh_guidance()
				if not guidance_card.get("target",[]).is_empty():
					view.camera_tile=Vector2(guidance_card.target[0],guidance_card.target[1]);view._update_transform()
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
			if world is ColonyWorld: button("Defense and shelter",show_defense,sheet_body)
			if world is ColonyWorld and not ColonyFire.active(world).is_empty(): button("Fires and water",show_fires,sheet_body)
			if world is ColonyWorld: button("Newcomer offers",show_newcomers,sheet_body)
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
			if world is ColonyWorld: show_valley()
		"Journal":
			if world is ColonyWorld:
				button("Chronicle",show_chronicle,sheet_body)
				button("Charter",show_charter,sheet_body)
				button("Pin a moment",show_pin_moment,sheet_body)
				_tutorial_sheet()
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
	for control in controls:
		if is_instance_valid(control) and control.text in ["Pause","Close","Menu","Follow","Begin","Hide","Skip","Show me","Cancel","Confirm","Pan","Rotate"]:
			var text_width: float = control.get_theme_font("font").get_string_size(control.text,HORIZONTAL_ALIGNMENT_LEFT,-1,control.get_theme_font_size("font_size")).x
			control.custom_minimum_size.x=maxf(48,ceilf(text_width)+control.get_theme_stylebox("normal").get_minimum_size().x+4)
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
	var speed_width: float = speeds.get_theme_constant("separation")*4
	for control in speeds.get_children(): speed_width+=control.custom_minimum_size.x
	speeds.position = Vector2(8 if left_handed else maxf(8,width-speed_width-8),height-navigation_height-56)
	speeds.size = Vector2(speed_width,48)
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
	_layout_guidance()
	speeds.move_to_front()

func _resize() -> void:
	if view != null:
		view.cancel_gesture()
	_layout()

func save_local() -> String:
	if awaiting_first_colony: return ""
	_finish_background_save(true,false)
	if recovery_failed:
		return "Recovery failed; original campaign will not be overwritten"
	var error: String = store.save(world)
	if error.is_empty():
		durable_at=save_clock
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
	if not _finish_background_save(true).is_empty(): return
	var result: Dictionary = store.load_latest()
	if result.has("error"):
		notice = result.error
		return
	_replace_world(result.world)
	notice = "Colony restored. Time stays paused."

func _replace_world(state: RefCounted) -> void:
	_finish_background_save(true,false)
	durable_at=save_clock
	journal_elapsed=0.0
	world = state
	# Every caller supplies a loaded, imported or newly adopted campaign. The
	# first-launch placeholder must no longer block play or persistence.
	awaiting_first_colony = false
	seen_care_alert = -1
	seen_region_alert = -1
	seen_fire_alert = -1
	seen_defense_alert = -1
	seen_opportunity_id = 0
	food_warning_level = 0
	forecast_elapsed = 2.0
	epilogue_session = ""
	charter_epilogue_session = ""
	defend_citizens.clear()
	defend_stand_fast = false
	recovery_failed = false
	storage_error = ""
	saving_disabled = false
	runner = SimRunner.new(world)
	view.world = world
	view.refresh_terrain()
	view.forecast_mask.clear()
	view.cancel_gesture()
	view.follow_id = 0
	close_inspector()
	cancel_placement()
	submitted_command = 0
	confirm_button.disabled = false
	last_saved_tick = world.tick
	if world is ColonyWorld: save_queue.prime(world)

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
		rotation_button.visible=false
		notice="Tap for one %s or drag to paint, then Confirm. The preview shows valid cells, total cost and omitted obstructions." % _catalog_name(kind)
		_layout();return
	begin_placement()
	view.preview_definition = kind
	view.preview_rotation = 0
	view.fit_build_preview()
	rotation_button.visible = true
	notice = "Place %s. Tap a tile or use the arrows; Confirm spends nothing until built." % kind.capitalize()
	_layout()

func begin_gather(kind: String) -> void:
	begin_placement()
	placement_kind = "gather"
	view.preview_resource = kind
	notice = "Drag a rectangle around the resources, then Confirm. Gathering workers finish every marked job."
	_layout()

func _preview_text() -> String:
	if placement_kind=="rally": return "Defend rally · hold within two tiles · %d selected\n%s" % [defend_citizens.size(),"Stand fast: automatic retreat disabled until this incident ends" if defend_stand_fast else "Automatic retreat at forty health; downed residents stop fighting"]
	if placement_kind=="cart_move":
		var error: String = ColonyMaintenance.cart_position_error(world,world.find(world.structures,moving_target),view.preview_start)
		return "Move cart · 20 WU · stored goods stay aboard\n"+("Needs a clear two-by-two route" if error.is_empty() else error)
	if placement_kind=="move_furniture":
		var error: String = world.placement_error(view.preview_definition,view.preview_start,view.preview_rotation,0,moving_target)
		return "Move %s · %d WU · materials retained\n%s" % [_catalog_name(view.preview_definition),world.definitions.buildings[view.preview_definition].work_milli/1000,"Valid destination" if error.is_empty() else error]
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
		var error: String = world.placement_error(view.preview_definition,view.preview_start,view.preview_rotation,0,moving_target)
		var definition: Dictionary = world.definitions.buildings[view.preview_definition]
		return "%s | %s | %d WU\n%s" % [view.preview_definition.capitalize(), _cost_text(definition.materials), definition.work_milli / 1000, "Valid placement" if error.is_empty() else error]
	return "%d x %d tiles | %s" % [absi(view.preview_end.x - view.preview_start.x) + 1, absi(view.preview_end.y - view.preview_start.y) + 1, "Pan mode" if view.gestures.mode == "pan" else ("Turnip field" if placement_kind == "field" else "Stockpile preview")]

func _update_inspector() -> void:
	if selected <= 0 or not is_instance_valid(inspector_details):
		return
	var citizen: Dictionary = world.find(world.citizens,selected) if world is ColonyWorld else world.citizens[selected-1]
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
	var state: Dictionary = _tutorial_state()
	label("Lessons use real work and supplies. Skipping leaves a lesson available to replay; it does not complete it.",sheet_body)
	button("Resume first steps",func()->void:_tutorial_begin();close_sheet(),sheet_body)
	for lesson in ColonyTutorial.OPENING+state.triggered:
		var status_text: String = "Completed" if state.completed.has(lesson) else ("Skipped" if state.skipped.has(lesson) else "Available")
		button("%s - %s" % [ColonyTutorial.TITLES[lesson],status_text],func()->void:
			ColonyTutorial.replay(state,lesson);_save_settings();close_sheet();_tutorial_show_me(),sheet_body)
	button("Food forecast",show_food_forecast,sheet_body)

func _tutorial_state() -> Dictionary:
	return ColonyTutorial.campaign(settings,world.session_id)

func tutorial_tick() -> Dictionary:
	if not world is ColonyWorld or awaiting_first_colony: return {}
	var state: Dictionary = _tutorial_state()
	var previous: String = JSON.stringify(state)
	var added: Array = ColonyTutorial.evaluate(world,state)
	if JSON.stringify(state)!=previous: _save_settings()
	if not added.is_empty(): notice="New lesson: "+ColonyTutorial.TITLES[added[0]]+". Open ? to see the action."
	return ColonyTutorial.card(world,state)

func _tutorial_action(kind: String, args: Dictionary = {}) -> void:
	if not world is ColonyWorld: return
	var state: Dictionary = _tutorial_state()
	var previous: String = JSON.stringify(state)
	ColonyTutorial.action(world,state,kind,args)
	if JSON.stringify(state)!=previous: _save_settings()

func _tutorial_begin() -> void:
	if not world is ColonyWorld: return
	ColonyTutorial.begin(_tutorial_state());_save_settings();runner.pause()

func _tutorial_skip() -> void:
	ColonyTutorial.skip(_tutorial_state());_save_settings()

func _tutorial_dismiss() -> void:
	ColonyTutorial.dismiss(_tutorial_state());_save_settings()

func show_tutorials() -> void:
	show_sheet("Lessons")
	_tutorial_sheet()

func _tutorial_show_me() -> void:
	runner.pause()
	var card: Dictionary = ColonyTutorial.card(world,_tutorial_state())
	if card.is_empty(): show_tutorials();return
	if not card.prerequisite.is_empty():
		show_sheet(card.title);label(card.prerequisite,sheet_body)
		button("Skip this lesson",func()->void:_tutorial_skip();close_sheet(),sheet_body)
		return
	match card.action:
		"follow":
			close_sheet();select_citizen(card.entity)
		"forage":
			begin_gather("berry_bush")
			view.preview_start=Vector2i(card.target[0],card.target[1]);view.preview_end=view.preview_start
		"lodge":
			begin_lodge();view.preview_start=Vector2i(card.target[0],card.target[1]);placement_cache_key=""
		"cook":
			_tutorial_action("hearth");show_station(world.find(world.structures,card.entity))
		"field":
			begin_field();view.preview_start=Vector2i(card.target[0],card.target[1]);view.preview_end=view.preview_start+Vector2i(3,1)
		"cooking_priority":
			_tutorial_action("work_preferences",{"citizen":card.entity});show_work_preferences(card.entity)
		"forecast": show_food_forecast()
		"winter": _tutorial_action("weather");show_weather()
		"injury": _tutorial_action("care");show_care()
		"research": _tutorial_action("research");show_research()
		"expedition": _tutorial_action("expedition");show_expeditions()
	if not card.target.is_empty():
		view.camera_tile=Vector2(card.target[0],card.target[1]);view._update_transform()

func tutorial_forecast_text() -> String:
	if not world is ColonyWorld: return ""
	var residents: int = ColonyCharter.living(world,true).size()
	return "%s | %d meal portions/day\n%s" % [FoodForecast.calculate(world).label,residents*2,_tutorial_harvest_text()]

func _tutorial_harvest_text() -> String:
	var soonest: int = 2147483647
	var quantity: int = 0
	var reason: String = "No planted crops: plant seasonal food and keep Growing enabled."
	for field in world.fields:
		if not field.planted: continue
		var definition: Dictionary = world.definitions.crops[field.crop]
		if world.definitions.items[definition.item].fullness<=0 and definition.item not in world.definitions.recipes.cook_meals.alternatives: continue
		if field.ripe_tick>0: return "Ripe crops are ready now; workers still need to harvest and haul them."
		if ColonyAgriculture.season(world.tick) not in definition.seasons or world.roofed(Vector2i(field.x,field.y))!=definition.roof or world.is_flooded(Vector2i(field.x,field.y)):
			reason="Planted crops are paused: "+field.reason;continue
		var watered: bool = world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="well" and absi(s.x-field.x)+absi(s.y-field.y)<=8)
		var rate: int = field.fertility*(500 if world.weather=="drought" and not watered else 1000)/1000
		if rate<=0: continue
		var remaining: int = maxi(0,((definition.growth-field.growth)*7200-field.growth_rem+rate-1)/rate)
		if remaining<soonest: soonest=remaining;quantity=field.yield_count
		elif remaining==soonest: quantity+=field.yield_count
	if soonest==2147483647: return reason
	var hours: int = (soonest+299)/300
	return "Next crop maturity: about %d days %d hours, %d raw food units, if current growing conditions continue." % [hours/24,hours%24,quantity]

func begin_field() -> void:
	begin_placement()
	placement_kind = "field"
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
	if not _finish_background_save(true).is_empty(): return
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
	view.tile_size = camera[2]
	view.center_camera(Vector2(camera[0],camera[1]))

func _save_settings() -> void:
	settings.values.text_scale = text_scale
	settings.values.left_handed = left_handed
	if store is ColonyStore:
		settings.values.last_slot = store.slot
		var center: Vector2 = view.camera_center().clamp(Vector2.ZERO,Vector2.ONE*128)
		settings.values.cameras[store.slot-1] = [center.x,center.y,view.tile_size]
	var error: String = settings.save_local()
	if not error.is_empty():
		notice = error

func show_weather() -> void:
	_tutorial_action("weather")
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
	_tutorial_action("work_preferences",{"citizen":id})
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

func show_beds(id: int) -> void:
	var person: Dictionary = world.find(world.citizens,id)
	if person.is_empty(): return
	show_sheet("Bed: "+person.name)
	label(ColonyBeds.description(world,person),sheet_body)
	label("Choose a free bed or bedroll. Assignment is immediate when time resumes; sleep still needs a safe walk. Occupied beds must be unassigned first.",sheet_body)
	if person.bed>0: button("Unassign current bed",func()->void:show_bed_choice(id,0),sheet_body)
	for bed in world.structures:
		if bed.health<=0 or bed.definition not in ["bed","bedroll"]: continue
		var owner: String = "Assigned to "+ColonyChronicle.display_name(world,bed.user) if bed.user>0 else "Free"
		label("%s at %d,%d | %s | %s" % [ColonyChronicle.display_name(world,bed.id),bed.x,bed.y,owner,"Roofed" if world.roofed(Vector2i(bed.x,bed.y)) else "Outdoors"],sheet_body)
		if bed.user==0: button("Choose %d,%d" % [bed.x,bed.y],func()->void:show_bed_choice(id,bed.id),sheet_body)
	button("Back to "+person.name,func()->void:show_person(id),sheet_body)

func show_bed_choice(id: int, target: int) -> void:
	var person: Dictionary = world.find(world.citizens,id)
	if person.is_empty(): return
	show_sheet(person.name+" bed")
	var error: String = ColonyBeds.quote(world,id,target)
	if not error.is_empty(): label(error,sheet_body)
	else:
		var bed: Dictionary = world.find(world.structures,target)
		label("Ground sleep: 80 rest/hour." if target==0 else "%s at %d,%d" % [ColonyChronicle.display_name(world,target),bed.x,bed.y],sheet_body)
		button("Unassign" if target==0 else "Assign this bed",func()->void:_submit("assign_bed",{"citizen":id,"target":target});close_sheet(),sheet_body)
		label(person.name+" will sleep on safe ground without an assigned bed." if target==0 else person.name+" walks here when tired. Assignment does not move them or add rest.",sheet_body)
	button("Back to beds",func()->void:show_beds(id),sheet_body)

func show_person(id: int) -> void:
	var citizen: Dictionary = world.find(world.citizens,id)
	show_sheet(citizen.name)
	button("Rename",func()->void:show_rename(id),sheet_body)
	button("Remembered moments",func()->void:show_person_history(id),sheet_body)
	label("%s\nFood %d/1000 | Rest %d/1000 | Health %d\nMorale %d/1000\n%s | %s\n%s work, %s food" % [citizen.activity,citizen.fullness,citizen.rest,citizen.health,citizen.morale,citizen.traits[0],citizen.traits[1],citizen.preferred,citizen.food_tag],sheet_body)
	label(ColonyBeds.description(world,citizen),sheet_body)
	if not citizen.death_recorded and not citizen.departed: button("Assign bed",func()->void:show_beds(id),sheet_body)
	if citizen.health < 100: button("Care and recovery",show_care,sheet_body)
	label("Active morale causes",sheet_body)
	for term in citizen.mood_terms: label("%s: %+d" % [term,citizen.mood_terms[term]],sheet_body)
	if not citizen.away and not citizen.downed and not citizen.death_recorded and not citizen.departed: button("Defend",func()->void:show_squad([id]),sheet_body)
	button("Equipment",func()->void:show_equipment(id),sheet_body)
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
	_tutorial_action("research")
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
	if station.definition=="hearth" and station.health>0: _tutorial_action("hearth")
	if station.health<=0:
		var moves: Array = world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="move_furniture" and j.target==station.id and j.state not in ["Complete","Canceled"])
		if not moves.is_empty(): _job_sheet(moves[0]);return
		show_sheet("Ruins: "+_catalog_name(station.definition))
		var definition: Dictionary = world.definitions.buildings[station.definition]
		label("This structure is gone. Surviving stored goods and fuel remain as physical ground stacks with their ages retained. Rebuilding uses the full original cost: %s; %d WU." % [_cost_text(definition.materials),definition.work_milli/1000],sheet_body)
		button("Rebuild",func()->void:_submit("rebuild",{"target":station.id});close_sheet(),sheet_body)
		return
	show_sheet(ColonyChronicle.display_name(world,station.id))
	button("Rename",func()->void:show_rename(station.id),sheet_body)
	var definition: Dictionary = world.definitions.buildings[station.definition]
	label("Health %d/%d | %s\n%s" % [station.health,definition.health,"Flammable" if definition.flammable else "Does not spread fire",("Store capacity %d" % definition.storage_capacity) if definition.storage_capacity > 0 else "Work needs inputs and an eligible resident"],sheet_body)
	if station.definition == "supply_cart":
		button("Charter",show_charter,sheet_body)
		button("Communal supper",show_supper,sheet_body)
		button("Move supply cart",func()->void:begin_cart_move(station),sheet_body)
		button("Neighbors and trade",show_valley,sheet_body)
	if station.definition != "supply_cart":
		button("Repair or demolish",func()->void:show_maintenance(station),sheet_body)
	if station.definition in ["bed","bedroll"]:
		label("Assigned to "+ColonyChronicle.display_name(world,station.user) if station.user>0 else "Unassigned sleeping place",sheet_body)
		label("Rest %d/hour. Assignment reserves the bed; residents walk here to sleep. A roofed bed earns its morale memory after four hours of actual sleep." % (150 if station.definition=="bed" else 120),sheet_body)
		if station.user>0: button("Unassign bed",func()->void:show_bed_choice(station.user,0),sheet_body)
		else:
			for person in world.citizens:
				if person.death_recorded or person.departed: continue
				button("Assign "+person.name,func()->void:show_bed_choice(person.id,station.id),sheet_body)
		return
	if station.definition in ColonyFire.INDUSTRIAL:
		var hazards: Array = ColonyFire.unsafe(world,station)
		label("Unsafe operating perimeter: suspend the station or move wood/fiber/cloth and flammable structures at least two tiles away, including diagonals." if not hazards.is_empty() else "Perimeter safe or station idle. An operating kiln/smelter near flammable objects can receive a twelve-hour overheating warning; suspending or clearing the fixed target prevents ignition.",sheet_body)
	if ColonyFire.burning(world,"structure",station.id): button("Fire and water tasks",show_fires,sheet_body)
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
	_tutorial_action("care")
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
	_finish_background_save(true,false)
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
	view.fit_build_preview();rotation_button.visible=false
	notice="Four beds, 23 walls and a south door. W73 F8; 206 WU. Clear an 8×6 footprint; the preset uses normal blueprints and can be edited individually."

func show_equipment(id: int) -> void:
	var person: Dictionary = world.find(world.citizens,id)
	show_sheet(person.name+" · Equipment")
	button("Work preferences",func()->void:show_work_preferences(id),sheet_body)
	label("The wearer fetches each item and equips it for 2 WU. Hauling must be enabled; health needs and higher-priority work can delay this task. Old equipment returns as a real ground stack. Tools do not wear out.",sheet_body)
	label("Missing toolkit: half Build/Craft/Field speed. Forged toolkit: +15% to those skills. Cloak: +8°C comfort. Vest: 2 armor. Bows reach six tiles; spears reach one. Weapons have different uses rather than an automatic upgrade ranking.",sheet_body)
	for slot in ColonyEquipment.SLOTS:
		var policy: Dictionary = world.equipment_state[id][slot]
		label(slot.capitalize()+": "+("Empty" if person.equipment[slot].is_empty() else _catalog_name(person.equipment[slot])),sheet_body)
		button(slot.capitalize()+" replacements: "+("On" if policy.replacements else "Off"),func()->void:
			_submit("equipment_policy",{"target":id,"slot":slot,"replacements":not policy.replacements,"upgrades":policy.upgrades});close_sheet(),sheet_body)
		if slot=="toolkit":
			button("Toolkit upgrades: "+("On" if policy.upgrades else "Off"),func()->void:
				_submit("equipment_policy",{"target":id,"slot":slot,"replacements":policy.replacements,"upgrades":not policy.upgrades});close_sheet(),sheet_body)
		for item in ColonyEquipment.SLOTS[slot]:
			if person.equipment[slot]==item: continue
			var stock: Dictionary = ColonyEquipment.source(world,person,item)
			if stock.is_empty(): label(_catalog_name(item)+": no accessible unreserved stock; craft it or free reserved goods.",sheet_body)
			else: button("Equip "+_catalog_name(item),func()->void:_submit("equip",{"target":id,"slot":slot,"item":item});close_sheet(),sheet_body)
		if not person.equipment[slot].is_empty(): button("Remove "+slot+"; stop replacements",func()->void:_submit("equip",{"target":id,"slot":slot,"item":""});close_sheet(),sheet_body)

func show_maintenance(station: Dictionary) -> void:
	show_sheet(_catalog_name(station.definition)+" · Maintenance")
	var definition: Dictionary = world.definitions.buildings[station.definition]
	var missing: int = definition.health-station.health
	if missing>0:
		label("Repair restores %d health for %d %s and %.1f WU. Cost rounds up once per repair task; further damage can remain after this work." % [missing,(missing+49)/50,ColonyMaintenance.dominant(definition),missing/10.0],sheet_body)
		button("Repair",func()->void:_submit("repair",{"target":station.id});close_sheet(),sheet_body)
	else: label("Full health; no repair materials needed.",sheet_body)
	var refund: Dictionary = {}
	for item in definition.materials:
		if definition.materials[item]/2>0: refund[item]=definition.materials[item]/2
	label("Demolition: %d WU; returns %s, half materials rounded down. Stored goods/fuel fall to the ground without freshening. Beds lose assignment and production stops." % [((definition.work_milli+1999)/2000),"no materials" if refund.is_empty() else _cost_text(refund)],sheet_body)
	if station.definition in ColonyMaintenance.MOVABLE:
		label("Move: full original WU; all construction materials retained and physically carried. Stored goods/fuel stay at the source for separate hauling. Canceling after dismantling leaves the bundle available.",sheet_body)
		button("Move furniture",func()->void:begin_furniture_move(station),sheet_body)
	button("Demolish…",func()->void:
		show_sheet("Demolish "+_catalog_name(station.definition))
		label("Remove this structure for %d WU and recover %s? Rebuilding later costs the full original materials and WU." % [((definition.work_milli+1999)/2000),"no materials" if refund.is_empty() else _cost_text(refund)],sheet_body)
		button("Confirm demolition",func()->void:_submit("demolish",{"target":station.id});close_sheet(),sheet_body),sheet_body)

func begin_furniture_move(station: Dictionary) -> void:
	begin_placement();placement_kind="move_furniture";moving_target=station.id
	view.preview_definition=station.definition;view.preview_rotation=station.rotation
	view.fit_build_preview();rotation_button.visible=true
	notice="Choose the destination before dismantling. Full original WU; retained materials move in real eight-unit loads. Stored goods/fuel stay at the old location."

func begin_cart_move(cart: Dictionary) -> void:
	begin_placement();placement_kind="cart_move";moving_target=cart.id
	view.preview_definition="supply_cart";view.preview_rotation=0;view.fit_build_preview();rotation_button.visible=false
	notice="Move the supply cart for 20 WU, then push it along a clear two-by-two route. Stored goods keep their age and remain aboard. Canceling a push stops at the current position."

func show_newcomers() -> void:
	show_sheet("Newcomer offers")
	label("Adult travelers offer to join every four days from day four. No penalty for declining. Accepting needs one reachable free bed and two stored-food days after adding the resident; population limit twenty. Each arrives wearing a toolkit/cloak and brings four rations to the cart.",sheet_body)
	var waiting: Array = world.population_state.offers.filter(func(o:Dictionary)->bool:return o.state in ["Offered","Accepted"])
	if waiting.is_empty(): label("No traveler is waiting. The next offers use game time; time stays paused here.",sheet_body)
	for request in waiting:
		var person: Dictionary = request.candidate
		label("%s · %s first · %s / %s · prefers %s food" % [person.name,person.preferred,person.traits[0],person.traits[1],person.food],sheet_body)
		var skill_text: Array[String] = []
		for skill in person.skills: skill_text.append(skill+" "+str(person.skills[skill]))
		label(", ".join(skill_text),sheet_body)
		if request.state=="Accepted": label("Walking in from the boundary. The arrival and all supplies are saved exactly once.",sheet_body);continue
		label("Waits %.1f more game hours. No hidden reputation penalty if this expires." % ((request.deadline-world.tick)/300.0),sheet_body)
		var check: Dictionary = ColonyPopulation.acceptance(world,request)
		label("Ready: free sleeping place and at least two days of food for the enlarged household." if check.error.is_empty() else check.error,sheet_body)
		if check.error.is_empty(): button("Accept "+person.name,func()->void:_submit("newcomer",{"target":request.id,"accept":true});close_sheet(),sheet_body)
		else:
			button("Build sleeping place",func()->void:begin_build("bedroll"),sheet_body)
			button("Food forecast",func()->void:show_sheet("Journal"),sheet_body)
		button("Decline "+person.name,func()->void:_submit("newcomer",{"target":request.id,"accept":false});close_sheet(),sheet_body)

func show_valley() -> void:
	show_sheet("Valley and neighbors")
	button("Incident forecast and pressure",show_incidents,sheet_body)
	button("Visitor opportunities",show_opportunities,sheet_body)
	button("Regional map",show_region,sheet_body)
	button("Expedition status",show_expeditions,sheet_body)
	label("Merchants visit every four days, beginning day five. One-day notice; their 24-hour stay starts at the cart. Prices per unit are rounded up: 120% normally, 110% at Friendly (40), 100% at Trusted (70). Selling uses base value. Trade gives no reputation; listed deliveries give ten, once per eight days.",sheet_body)
	label("Next visit: %s in %.1f game hours" % [ColonyTrade.COMMUNITIES[world.trade_state.visit_index%3].capitalize(),maxf(0,(world.trade_state.next_visit-world.tick)/300.0)],sheet_body)
	for community in ColonyTrade.COMMUNITIES:
		var score: int = world.trade_state.reputation[community]
		label("%s | %d · %s\nRequested delivery: %s. Next eligible in %.1f days." % [community.capitalize(),score,"Trusted" if score>=70 else ("Friendly" if score>=40 else "Neighbor"),_cost_text(world.definitions.communities[community].delivery),maxf(0,(world.trade_state.delivery_after[community]-world.tick)/7200.0)],sheet_body)
	for merchant in world.trade_state.merchants:
		if merchant.state=="Gone": continue
		label("%s: %s · %s" % [merchant.community.capitalize(),merchant.state,merchant.note],sheet_body)
		if merchant.state=="Trading":
			button("Trade with "+merchant.community.capitalize(),func()->void:show_trade(merchant),sheet_body)
			button("Deliver community request",func()->void:_preview_trade(merchant,{},world.definitions.communities[merchant.community].delivery.duplicate(),0,true),sheet_body)
	for exchange in world.trade_state.exchanges:
		if exchange.state!="Packing": continue
		label("%s payment delivery: %s" % [exchange.community.capitalize(),_cost_text(exchange.pay)],sheet_body)
		button("Cancel unpaid exchange "+str(exchange.id),func()->void:_submit("trade_cancel",{"target":exchange.id});close_sheet(),sheet_body)
	var receipts: Array = world.trade_state.exchanges.filter(func(e:Dictionary)->bool:return e.state=="Complete")
	for exchange in receipts.slice(maxi(0,receipts.size()-10)):
		label("Receipt %d: %s paid %s; received %s; gift %d%s" % [exchange.id,exchange.community.capitalize(),_cost_text(exchange.pay),_cost_text(exchange.buy),exchange.gift,"; delivery +10 reputation" if exchange.delivery else ""],sheet_body)

func show_trade(merchant: Dictionary) -> void:
	show_sheet("Trade · "+merchant.community.capitalize())
	label("Choose quantities, then preview. Payment is reserved together and carried to the cart before bought goods are released. Cancel before payment commits; a completed exchange is final. Animals need Husbandry, four free pen tiles and a barn slot each.",sheet_body)
	if FoodForecast.calculate(world).ticks<3600 and merchant.stock.get("meal",0)>0: label("Food recovery: consider meals paid with wood or stone before offering valuable tools. The price and stock stay the same.",sheet_body)
	var buys: Dictionary = {};var pays: Dictionary = {}
	label("Merchant goods",sheet_body)
	for item in merchant.stock:
		var remaining: int = ColonyTrade.available(world,merchant,item)
		if remaining<=0: continue
		label(item.capitalize()+" | "+str(remaining)+" available",sheet_body)
		var quantity: SpinBox = SpinBox.new();quantity.min_value=0;quantity.max_value=remaining;quantity.value=0;quantity.custom_minimum_size=Vector2(96,48);sheet_body.add_child(quantity);buys[item]=quantity
	label("Your offer",sheet_body)
	var goods: Dictionary = ColonyTrade.accessible_goods(world)
	for item in goods:
		if goods[item]<=0: continue
		label(item.capitalize()+" | "+str(goods[item])+" unreserved; base value "+str(world.definitions.items[item].barter_value),sheet_body)
		var quantity: SpinBox = SpinBox.new();quantity.min_value=0;quantity.max_value=goods[item];quantity.value=0;quantity.custom_minimum_size=Vector2(96,48);sheet_body.add_child(quantity);pays[item]=quantity
	var pens: Array = world.domestic_state.pens
	var pen_choice: CycleChoiceButton = CycleChoiceButton.new();pen_choice.custom_minimum_size=Vector2(96,48)
	pen_choice.add_item("No animal destination")
	for pen in pens: pen_choice.add_item("Pen "+str(pen.id)+" · "+str(ColonyDomestic.status(world,pen).capacity)+" slots")
	sheet_body.add_child(pen_choice)
	button("Preview exchange",func()->void:
		var buy: Dictionary = {};var pay: Dictionary = {}
		for item in buys:
			if buys[item].value>0: buy[item]=int(buys[item].value)
		for item in pays:
			if pays[item].value>0: pay[item]=int(pays[item].value)
		_preview_trade(merchant,buy,pay,0 if pen_choice.selected==0 else pens[pen_choice.selected-1].id,false),sheet_body)

func _preview_trade(merchant: Dictionary, buy: Dictionary, pay: Dictionary, pen: int, delivery: bool) -> void:
	var quote: Dictionary = ColonyTrade.preview(world,merchant,buy,pay,pen,delivery)
	show_sheet("Delivery preview" if delivery else "Exchange preview")
	label("Pay: %s\nReceive: %s" % [_cost_text(pay),"Ten reputation; no deadline after acceptance" if delivery else _cost_text(buy)],sheet_body)
	if not quote.error.is_empty():
		label(quote.error,sheet_body);button("Back to trade",func()->void:show_trade(merchant),sheet_body);return
	label("Price %d · offer %d · surplus gift %d. The gift gives no extra reputation. Supplies stay reserved until physical payment or cancellation. Animals go to pen %d." % [quote.cost,quote.offered,quote.gift,pen],sheet_body)
	button("Accept delivery" if delivery else "Accept exchange",func()->void:_submit("trade",{"target":merchant.id,"buy":buy,"pay":pay,"pen":pen,"delivery":delivery});close_sheet(),sheet_body)
	button("Cancel preview",show_valley,sheet_body)

func show_region() -> void:
	show_sheet("Regional map")
	label("Known 9 x 9 valley. H is home, S is a site, N is a neighbor. Pan the map to see the edges. Each edge costs six game hours in either direction; no impassable edges. Beyond one edge requires Trailcraft. Transit scenery has no rewards.",sheet_body)
	var scroll: ScrollContainer = TouchScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.custom_minimum_size=Vector2(0,420);sheet_body.add_child(scroll)
	var grid: GridContainer = GridContainer.new();grid.columns=9;scroll.add_child(grid)
	for node in world.region_state.nodes:
		var mark: String = "H" if node.definition=="home" else ("S" if node.definition in ColonyRegion.SITES else ("N" if node.definition in ColonyTrade.COMMUNITIES else ""))
		var tile: Button = button(mark,func()->void:
			if node.definition=="home": show_station(ColonyTrade.cart(world))
			else: show_expedition_prepare(node.definition,false),grid,48)
		tile.tooltip_text=node.scenery if node.definition=="transit" else node.definition.capitalize()
		tile.disabled=node.definition=="transit"
	button("Current expedition",show_expeditions,sheet_body)
	for definition in ColonyRegion.SITES+ColonyTrade.COMMUNITIES:
		var path: Array = ColonyRegion.route(world,definition)
		var progress: Dictionary = world.region_state.progress[definition]
		button(definition.capitalize()+" · "+str(path.size()-1)+" edges"+(" · landmark" if progress.completed and definition in ColonyRegion.SITES and world.definitions.expeditions[definition].cooldown_days==0 else ""),func()->void:show_expedition_prepare(definition,false),sheet_body)
		if not progress.leftovers.is_empty() and not progress.pickup_used:
			button("Pick up leftovers: "+definition.capitalize(),func()->void:show_expedition_prepare(definition,true),sheet_body)

func show_expedition_prepare(definition: String, pickup: bool) -> void:
	show_sheet(definition.capitalize())
	var data: Dictionary = ColonyRegion.definition_data(world,definition,pickup)
	var edges: int = ColonyRegion.route(world,definition).size()-1
	label("%d edges each way · %d site hours · %d regional hours total\nSkill %s / challenge %d\nContract inputs: %s\nReward: %s; %d insight; %s" % [edges,data.site_hours,edges*12+data.site_hours,data.skill,data.challenge,_cost_text(data.payment),_cost_text(data.rewards),data.insight,str(data.reputation)],sheet_body)
	label("Packing plan: select two to four residents; leave two at home. Health 70, fullness 500, rest 500 required.",sheet_body)
	var rules: VBoxContainer = VBoxContainer.new();sheet_body.add_child(rules);rules.visible=false
	button("Travel and outcome rules",func()->void:rules.visible=not rules.visible,sheet_body)
	label("Select two to four healthy residents and leave two at home. Each needs health 70, fullness 500, rest 500. Packs hold twelve units per resident, plus twelve per adult goat. Rations must cover the quoted trip plus one reserve day. Local walking and physical packing/unloading are visible too. A shortfall of 1-2 gives 75% item rewards and injures the leader 10 per point; more than two requires explicit Attempt unprepared, gives no items and injures two travelers 20 each. Expedition injury floors are 10 health in Standard and 1 in Hearthside; injuries are stabilized and carried home.",rules)
	var people: Dictionary = {};var goats: Dictionary = {};var extras: Dictionary = {}
	for person in ColonyRegion.home(world):
		var choice: CheckButton = CheckButton.new();choice.text=person.name;choice.custom_minimum_size.y=48;choice.button_pressed=person.id in [2,3];sheet_body.add_child(choice);people[person.id]=choice
		label("%s %d · health %d · fullness %d · rest %d\n%s" % [data.skill,person.skills[data.skill],person.health,person.fullness,person.rest,"Unarmed" if person.equipment.weapon.is_empty() else person.equipment.weapon.capitalize()],sheet_body)
	for animal in world.domestic_state.animals:
		if animal.definition!="pack_goat" or animal.health<=0 or animal.away: continue
		var choice: CheckButton = CheckButton.new();choice.text=animal.name;choice.custom_minimum_size.y=48;sheet_body.add_child(choice);goats[animal.id]=choice
		label("Twelve extra cargo units; two grain/vegetable feed per trip day",sheet_body)
	var feed: CycleChoiceButton = CycleChoiceButton.new();feed.add_item("Grain feed");feed.add_item("Vegetable feed");feed.custom_minimum_size.y=48;sheet_body.add_child(feed)
	var variant: CycleChoiceButton = CycleChoiceButton.new();variant.add_item("Stone 24" if definition=="old_quarry" and not pickup else "Listed reward")
	if definition=="old_quarry" and not pickup: variant.add_item("Iron ore 12")
	variant.custom_minimum_size.y=48;sheet_body.add_child(variant)
	var pens: Array = world.domestic_state.pens
	var pen: CycleChoiceButton = CycleChoiceButton.new();pen.add_item("No animal destination")
	for enclosure in pens: pen.add_item("Returning goat to pen "+str(enclosure.id))
	pen.custom_minimum_size.y=48;sheet_body.add_child(pen)
	var extra_panel: VBoxContainer = VBoxContainer.new();sheet_body.add_child(extra_panel);extra_panel.visible=false
	button("Optional extra cargo",func()->void:extra_panel.visible=not extra_panel.visible,sheet_body)
	for item in ColonyTrade.accessible_goods(world):
		var available: int = ColonyTrade.accessible_goods(world)[item]
		if available<=0: continue
		label(item.capitalize()+" extra",extra_panel)
		var count: SpinBox = SpinBox.new();count.max_value=available;count.custom_minimum_size=Vector2(96,48);extra_panel.add_child(count);extras[item]=count
	button("Preview packing plan",func()->void:
		var plan: Dictionary = {"definition":definition,"party":[],"goats":[],"cargo":{},"feed":"grain" if feed.selected==0 else "vegetable","pen":0 if pen.selected==0 else pens[pen.selected-1].id,"variant":variant.selected,"pickup":pickup}
		for id in people:
			if people[id].button_pressed: plan.party.append(id)
		for id in goats:
			if goats[id].button_pressed: plan.goats.append(id)
		for item in extras:
			if extras[item].value>0: plan.cargo[item]=int(extras[item].value)
		show_expedition_preview(plan),sheet_body)

func show_expedition_preview(plan: Dictionary) -> void:
	var quote: Dictionary = ColonyRegion.preview(world,plan)
	show_sheet("Expedition packing preview")
	if not quote.error.is_empty(): label(quote.error,sheet_body);button("Change party or cargo",func()->void:show_expedition_prepare(plan.definition,plan.pickup),sheet_body);return
	label("%s · %d hours · readiness %d / challenge %d\nPack: %s\nDeparture capacity %d; return capacity %d\nExpected items: %s; insight %d\nHome forecast without travelers: %s" % [plan.definition.capitalize(),quote.hours,quote.readiness,quote.challenge,_cost_text(quote.inputs),quote.capacity,quote.return_capacity,_cost_text(quote.rewards),quote.insight,quote.home_forecast.label],sheet_body)
	var removed: Array[String] = []
	for id in plan.party:
		var person: Dictionary = world.find(world.citizens,id);removed.append(person.name+" · "+str(person.skills))
	label("Skills leaving home:\n"+"\n".join(removed),sheet_body)
	label("One midpoint choice with a free Continue option; optional choices cannot spend the return reserve. Reward capacity is reviewed before collection; leftovers allow one later pickup. Recall returns along elapsed outbound travel and retains unconsumed cargo. Readiness is frozen on Depart, after this packing step.",sheet_body)
	button("Start packing",func()->void:_submit("expedition_prepare",plan);close_sheet(),sheet_body)
	button("Change plan",func()->void:show_expedition_prepare(plan.definition,plan.pickup),sheet_body)

func show_expeditions() -> void:
	_tutorial_action("expedition")
	show_sheet("Expedition")
	var trip: Dictionary = ColonyRegion.active(world)
	if trip.is_empty(): label("No expedition is active. Choose a known site on the regional map.",sheet_body);button("Regional map",show_region,sheet_body);return
	label(trip.args.definition.capitalize()+" · "+trip.state+"\n"+trip.note,sheet_body)
	label("Party: "+", ".join(trip.args.party.map(func(id:int)->String:return world.find(world.citizens,id).name))+"\nCargo: "+_cost_text(ColonyRegion.cargo(world,trip))+"\nReadiness %d / %d · remaining phase %.1f hours" % [trip.readiness,trip.quote.challenge,trip.remaining/300.0],sheet_body)
	if trip.state in ["Preparing","Ready"]:
		label("Travelers eat at fullness 500 and sleep at rest 500 while preparing, then return to the cart. Food, work and rest are real; departure requirements still apply.",sheet_body)
		var error: String = ColonyRegion.ready(world,trip)
		label("Ready for Depart" if error.is_empty() else error,sheet_body)
		if error.is_empty():
			if trip.quote.shortfall>2:
				button("Review Attempt unprepared",func()->void:
					show_sheet("Attempt unprepared?");label("No item reward, half insight, twenty health damage to each of the two lowest-ID travelers. One packed medicine is used only if an injury occurs, restoring twenty to the most injured. Readiness is fixed at departure. This is an explicit risk choice.",sheet_body)
					button("Attempt unprepared",func()->void:_submit("expedition_depart",{"target":trip.id,"unprepared":true});close_sheet(),sheet_body),sheet_body)
			else: button("Depart",func()->void:_submit("expedition_depart",{"target":trip.id,"unprepared":false});close_sheet(),sheet_body)
		button("Cancel packing",func()->void:_submit("expedition_cancel",{"target":trip.id});close_sheet(),sheet_body)
	elif trip.state=="Decision":
		var options: Array = [["wait","repair","continue"],["give","continue"],["survey","continue"]][trip.decision]
		var descriptions: Dictionary = {"wait":"Wait for carrier: +6 hours, cloth 4","repair":"Repair path: wood 4, cloth 4, no delay","give":"Give rations: 2 rations, +3 Road reputation","survey":"Survey shortcut: +6 hours, +80 insight","continue":"Continue on the original route: free"}
		if world.tick<world.region_state.progress[trip.args.definition].decision_after: label("Optional bonus is cooling down; no extra reward until eight days after the last bonus.",sheet_body)
		for option in options:
			var error: String = "" if option=="continue" else ColonyRegion.choice_error(world,trip,option)
			label(descriptions[option]+(" · "+error if not error.is_empty() else ""),sheet_body)
			if error.is_empty(): button("Choose "+option,func()->void:_submit("expedition_choice",{"target":trip.id,"definition":option});close_sheet();runner.set_speed(runner.previous_speed),sheet_body)
	elif trip.state=="Collect":
		label("Declared outcome: %s; insight %d; shortfall %d. Contract payment %s is consumed only on full/partial success. Health damage: %d%s. Kept goods remain in cargo on recall after collection; unkept goods stay here for one pickup." % [_cost_text(trip.quote.rewards),trip.quote.insight,trip.quote.shortfall,_cost_text(trip.quote.payment),20 if trip.quote.shortfall>2 else trip.quote.shortfall*10," to each of the two lowest IDs" if trip.quote.shortfall>2 else " to the highest relevant-skill leader"],sheet_body)
		var default: Dictionary = ColonyRegion.default_keep(world,trip);var quantities: Dictionary = {}
		for item in trip.quote.rewards:
			label(item.capitalize()+" · "+str(trip.quote.rewards[item])+" available",sheet_body)
			var count: SpinBox = SpinBox.new();count.max_value=trip.quote.rewards[item];count.value=default.get(item,0);count.custom_minimum_size=Vector2(96,48);sheet_body.add_child(count);quantities[item]=count
		button("Collect kept rewards and return",func()->void:
			var keep: Dictionary = {}
			for item in quantities:
				if quantities[item].value>0: keep[item]=int(quantities[item].value)
			_submit("expedition_collect",{"target":trip.id,"keep":keep});close_sheet();runner.set_speed(runner.previous_speed),sheet_body)
	if trip.state not in ["Preparing","Ready","Returning","Walking in","Unloading"]: button("Recall without committing new site rewards",func()->void:_submit("expedition_recall",{"target":trip.id});close_sheet();runner.set_speed(runner.previous_speed),sheet_body)

func show_fires() -> void:
	show_sheet("Fire and water")
	label("Emergency crews override ordinary Care Off and use one abstract water load: fetch 2 WU at the nearest reachable well or river bank, carry it in both hands, then apply 8 WU beside the target. Interruption discards the load but retains applied effort. Residents need a safe route and cannot abandon life-critical needs. Burning objects cannot provide work or storage. Rain halves damage and doubles the spread interval.",sheet_body)
	for fire in ColonyFire.active(world):
		var object: Dictionary = world.find(world.structures if fire.kind=="structure" else world.stacks,fire.target)
		label("%s at (%d, %d) · %.1f/8 WU applied\n%s" % [object.get("definition",object.get("item","")),object.x,object.y,fire.work/1000.0,"Two health/sec; touching wood can ignite every thirty seconds" if fire.kind=="structure" else "One item/sec; food and the cart itself do not propagate fire"],sheet_body)
		button("Look at fire "+str(fire.id),func()->void:view.camera_tile=Vector2(object.x,object.y);view.follow_id=0;view._update_transform();close_sheet(),sheet_body)
	button("Work preferences",func()->void:show_sheet("Work"),sheet_body)
	button("Build a well",func()->void:begin_build("well"),sheet_body)

func show_incidents() -> void:
	show_sheet("Incident forecast")
	var pressure: Dictionary = ColonyDirector.pressure(world)
	label("Pressure %d/100. No new major at fifty or more, with a downed resident, or while an incident remains unresolved." % pressure.score,sheet_body)
	for cause in pressure.terms: label(cause+": +"+str(pressure.terms[cause]),sheet_body)
	var gate: String = ColonyDirector.gates(world)
	label("No new major incident while recovering: "+gate if not gate.is_empty() else "Major consideration at 06:00 from day eight. Starts stay seventy-two hours apart; resolution gives forty-eight recovery hours. Already shown extreme weather reserves the same spacing.",sheet_body)
	var major: Dictionary = world.director_state.major
	if not major.is_empty(): label(major.kind.capitalize()+" · "+major.state+"\n"+major.reason+"\nDue in %.1f hours" % maxf(0,(major.due-world.tick)/300.0),sheet_body)
	button("Defense and supplies",show_defense,sheet_body)
	if not ColonyFire.active(world).is_empty(): button("Fire response",show_fires,sheet_body)
	if not major.is_empty() and major.kind=="overheat":
		var station: Dictionary = world.find(world.structures,major.target)
		button("Suspend overheating station",func()->void:_submit("station_enabled",{"target":station.id,"enabled":false});close_sheet(),sheet_body)
		button("Inspect fixed target",func()->void:show_station(station),sheet_body)

func show_defense() -> void:
	show_sheet("Defense")
	var raid: Dictionary = ColonyDefense.active(world)
	if raid.is_empty(): label("No road party is active. Choose a squad and rally, or inspect the incident forecast. Squad members hold within two tiles, choose targets deterministically, and retreat at forty health unless Stand fast was explicitly confirmed.",sheet_body)
	else:
		label("Party: "+", ".join(raid.party.map(func(k:String)->String:return k.capitalize()))+"\nBudget %d · theft quota %d units · supplies price %d barter value\nEntry (%d,%d) · %s\n%s" % [raid.budget,raid.party.size()*4,raid.budget*8,raid.entry.x,raid.entry.y,raid.state,raid.reason],sheet_body)
		label("Arrival in %.1f hours. Active siege remaining %.1f hours. Worn equipment and expedition cargo cannot be stolen. Downed visitors are stable, neutral and never executed." % [maxf(0,(raid.due-world.tick)/300.0),maxf(0,(raid.arrival+1800-world.tick)/300.0) if raid.arrival>0 else 6.0],sheet_body)
		if raid.state not in ["Payment","Retreating","Resolved"]: button("Offer supplies",func()->void:show_raid_offer(raid),sheet_body)
		button("Acknowledge arrival",func()->void:_submit("raid_ack",{});close_sheet(),sheet_body)
	button("Choose defending squad",func()->void:show_squad([]),sheet_body)
	button("Shelter everyone" if not world.defense_state.shelter else "End shelter order",func()->void:_submit("shelter",{"enabled":not world.defense_state.shelter});close_sheet(),sheet_body)
	button("Open passage" if not world.defense_state.open_passage else "Close hostile passage",func()->void:_submit("open_passage",{"enabled":not world.defense_state.open_passage});close_sheet(),sheet_body)
	button("Stand down: return everyone to ordinary work",func()->void:_submit("stand_down",{});close_sheet(),sheet_body)
	for enemy in world.defense_state.enemies:
		if enemy.state!="Gone": button(enemy.definition.capitalize()+" · "+enemy.state+" · "+str(enemy.health)+" health",func()->void:show_enemy(enemy),sheet_body)

func show_squad(initial: Array) -> void:
	show_sheet("Defending squad")
	var people: Dictionary = {}
	for person in ColonyRegion.home(world):
		if person.downed: continue
		var choice: CheckButton = CheckButton.new();choice.text=person.name;choice.button_pressed=initial.has(person.id);choice.custom_minimum_size.y=48;sheet_body.add_child(choice);people[person.id]=choice
		label("Health %d · Guard %d · %s" % [person.health,person.skills.Guard,"Unarmed" if person.equipment.weapon.is_empty() else person.equipment.weapon],sheet_body)
	button("Choose rally on map",func()->void:
		var selected: Array = []
		for id in people:
			if people[id].button_pressed: selected.append(id)
		if selected.is_empty(): notice="Choose at least one resident";return
		begin_defend_rally(selected,false),sheet_body)
	button("Review Stand fast",func()->void:
		var selected: Array = []
		for id in people:
			if people[id].button_pressed: selected.append(id)
		if selected.is_empty(): notice="Choose at least one resident";return
		show_sheet("Stand fast warning")
		label("Automatic retreat at forty health will be disabled for this squad during this incident. They can suffer further attacks. Downed residents still stop fighting and need rescue. This flag clears when the incident ends.",sheet_body)
		button("Confirm Stand fast and choose rally",func()->void:begin_defend_rally(selected,true),sheet_body),sheet_body)
	button("Undraft selected",func()->void:
		var selected: Array = []
		for id in people:
			if people[id].button_pressed: selected.append(id)
		_submit("undraft",{"citizens":selected});close_sheet(),sheet_body)

func begin_defend_rally(people: Array, stand_fast: bool) -> void:
	begin_placement();placement_kind="rally";defend_citizens=people.duplicate();defend_stand_fast=stand_fast
	view._update_transform()
	notice="Choose a rally point and Confirm. The squad holds within two tiles."

func show_enemy(enemy: Dictionary) -> void:
	show_sheet(enemy.definition.capitalize())
	var definition: Dictionary = world.definitions.enemies[enemy.definition]
	label("%s · health %d/%d · armor %d\n%s · %d damage every %d ticks; objective %s\nCollected goods: %s" % [enemy.state,enemy.health,definition.health,definition.armor,definition.weapon,definition.damage,definition.cooldown,definition.objective,str(enemy.loot)],sheet_body)
	if enemy.state=="Downed":
		label("Neutral and stable. Automatic recovery to twenty-five in %.1f hours; voluntary care gives three Road reputation once for this person." % maxf(0,(enemy.recovery_at-world.tick)/300.0),sheet_body)
		button("Voluntary treatment",func()->void:_submit("enemy_treat",{"target":enemy.id});close_sheet(),sheet_body)
	elif enemy.state in ["Active","Retreating"]:
		var squad: Array = world.citizens.filter(func(c:Dictionary)->bool:return c.drafted and not c.away).map(func(c:Dictionary)->int:return c.id)
		if not squad.is_empty(): button("Focus with drafted squad",func()->void:_submit("focus",{"citizens":squad,"target":enemy.id});close_sheet(),sheet_body)

func show_raid_offer(raid: Dictionary) -> void:
	show_sheet("Offer supplies")
	label("Need %d barter value at the marked meeting spot. Workers deliver it in eight-unit loads. The party waits six hours without attacks during payment; a failed delivery gives one warning hour. The absolute six-hour raid limit still prevents renewed attacks once elapsed. Payment gives no later budget increase. Retreating parties cannot be restarted." % (raid.budget*8),sheet_body)
	var choices: Dictionary = {}
	for item in ColonyTrade.accessible_goods(world):
		var available: int = ColonyTrade.accessible_goods(world)[item]
		if available<=0: continue
		label(item.capitalize()+" · value "+str(world.definitions.items[item].barter_value)+" · "+str(available)+" available",sheet_body)
		var count: SpinBox = SpinBox.new();count.max_value=available;count.custom_minimum_size=Vector2(96,48);sheet_body.add_child(count);choices[item]=count
	button("Preview supplies",func()->void:
		var pay: Dictionary = {};var value: int = 0
		for item in choices:
			if choices[item].value>0: pay[item]=int(choices[item].value);value+=pay[item]*world.definitions.items[item].barter_value
		show_sheet("Supply preview")
		label("Pay "+_cost_text(pay)+"\nOffer value %d / needed %d\nMeeting (%d,%d). Surplus %d is a gift." % [value,raid.budget*8,raid.meeting.x,raid.meeting.y,maxi(0,value-raid.budget*8)],sheet_body)
		if value<raid.budget*8: label("Add "+str(raid.budget*8-value)+" value before accepting",sheet_body)
		else: button("Accept and deliver supplies",func()->void:_submit("raid_offer",{"target":raid.id,"pay":pay});close_sheet(),sheet_body),sheet_body)

func show_opportunities() -> void:
	show_sheet("Visitor offers")
	label("Every second day from day four, one eligible visitor may offer help. Offers last two game days, with no penalty for declining or expiry. Accepting reserves the listed payment; workers must deliver it and do the promised work. No event repeats within eight days.",sheet_body)
	var active: Array = world.opportunity_state.offers.filter(func(e:Dictionary)->bool:return e.state in ["Offered","Accepted","Hosted"])
	if active.is_empty(): label("No offer is waiting. Tables, friendships and research desks create more opportunities.",sheet_body)
	for event in active:
		var visitor: Dictionary = world.find(world.opportunity_state.visitors,event.visitor)
		label(event.definition.replace("_"," ").capitalize()+" · "+event.state,sheet_body)
		label({"traveling_storyteller":"Two meals host a storyteller for six hours. Residents who share a continuous half-hour of leisure nearby gain +40 morale target for one day.","stranded_carrier":"Deliver eight wood and complete twelve Building WU at the cart within two days. Receive four cloth and +3 Road fellowship reputation.","surplus_harvest":"Deliver twenty wood to the cart within two days. Receive sixteen grain.","shared_observation":"The named friends each contribute twenty Study WU at an available research desk within two days. Receive one hundred insight."}[event.definition],sheet_body)
		label("%s · %s
%.1f hours left to accept or finish payment/work. %s" % [visitor.state,visitor.note,maxf(0,(event.deadline-world.tick)/300.0),event.reason],sheet_body)
		if not event.people.is_empty(): label("Friends: "+", ".join(event.people.map(func(id:int)->String:return world.find(world.citizens,id).name)),sheet_body)
		if event.state=="Offered":
			button("Accept "+event.definition.replace("_"," "),func()->void:_submit("minor_event",{"target":event.id,"accept":true});close_sheet(),sheet_body)
			button("Decline offer",func()->void:_submit("minor_event",{"target":event.id,"accept":false});close_sheet(),sheet_body)
		for id in event.jobs:
			var job: Dictionary = world.find(world.jobs,id)
			if not job.is_empty(): button("Task: %s · %s" % ["Study together" if job.kind=="minor_study" else ("Repair cart" if event.definition=="stranded_carrier" else "Deliver supplies"),job.state],func()->void:_job_sheet(job),sheet_body)
	for event in world.opportunity_state.offers.slice(maxi(0,world.opportunity_state.offers.size()-10)):
		if event.state not in ["Offered","Accepted","Hosted"]: label("%s · %s · %s" % [event.definition.replace("_"," ").capitalize(),event.state,event.reason],sheet_body)

func show_charter() -> void:
	show_sheet("Charter")
	label(ColonyChronicle.display_name(world,0)+" - a refuge worth staying in",sheet_body)
	label("Stages complete in order and remain recorded after later losses. There are no quest deadlines. Insight rewards apply once; the final ceremony can be paused.",sheet_body)
	button("Communal supper",show_supper,sheet_body)
	button("Cart appearance",show_charter_appearance,sheet_body)
	button("Name settlement",func()->void:show_rename(0),sheet_body)
	for stage in ColonyCharter.checklist(world):
		label(("Recorded: " if stage.complete else "Next: " if world.charter_state.completed.size()==ColonyCharter.STAGES.find(stage.id) else "Later: ")+stage.title,sheet_body)
		if stage.complete: label("Day %d snapshot is retained." % world.charter_state.snapshots[stage.id].day,sheet_body)
		for condition in stage.conditions: label(("[x] " if condition.met else "[ ] ")+condition.text,sheet_body)
		if stage.reward>0: label("Reward: %d insight and a cosmetic cart appearance." % stage.reward,sheet_body)
	if world.charter_state.ending:
		button("Read the epilogue",show_charter_ending,sheet_body)
	elif world.charter_state.ceremony.get("state","")=="Active":
		label("Ceremony: %.1f game hours remaining. A hostile arrival cancels it without using supplies." % (maxi(0,world.charter_state.ceremony.end-world.tick)/300.0),sheet_body)
		button("Cancel ceremony",func()->void:_submit("cancel_ceremony",{});close_sheet(),sheet_body)
	else:
		var reason: String = ColonyCharter.ceremony_error(world)
		if reason.is_empty(): button("Begin two-hour ceremony",func()->void:_submit("start_ceremony",{});close_sheet(),sheet_body)
		else: label("Ceremony waits: "+reason,sheet_body)
	button("Food forecast",show_food_forecast,sheet_body)
	button("Research",show_research,sheet_body)

func show_supper() -> void:
	show_sheet("Communal supper")
	label("Commonlife and eight healthy home residents (60+ health, none downed) are needed. Reserve two meals per home resident and at least four reachable table seats for the next 18:00-20:00 window. Each attendee collects one real meal and sits for half an hour. Seats fill in citizen order, in waves.",sheet_body)
	label("Eight distinct attendees complete the supper. Unused meals return; eaten food stays consumed after cancellation or failure. Attendees gain +60 morale target for two days. The next completed supper can be held after eight days. Escape, rescue and life-critical needs take precedence.",sheet_body)
	var status: Dictionary = ColonyCharter.supper_status(world)
	label("%s - %d/8 attended\n%s" % [status.state,status.attended,status.reason],sheet_body)
	if not status.traveling.is_empty(): label("Traveling: "+", ".join(status.traveling),sheet_body)
	if not status.waiting.is_empty(): label("Waiting or seated: "+", ".join(status.waiting),sheet_body)
	if status.state in ColonyCharter.ACTIVE:
		var supper: Dictionary = world.charter_state.supper
		label("Day %d, 18:00-20:00. %d meals eaten; %d meals still reserved." % [supper.start/7200+1,supper.eaten.size(),world.stacks.reduce(func(n:int,s:Dictionary)->int:return n+s.reservations.get(supper.job,0),0)],sheet_body)
		button("Cancel supper",func()->void:_submit("cancel_supper",{});close_sheet(),sheet_body)
	else:
		var reason: String = ColonyCharter.supper_error(world)
		if reason.is_empty(): button("Reserve meals and evening",func()->void:_submit("start_supper",{});close_sheet(),sheet_body)
		else: label("Before scheduling: "+reason,sheet_body)
	button("Build a table",func()->void:begin_build("table"),sheet_body)
	button("Food forecast",show_food_forecast,sheet_body)

func show_charter_appearance() -> void:
	show_sheet("Cart appearance")
	label("Charter rewards change the cart's appearance at no resource cost. They have no mechanical effect.",sheet_body)
	for stage in ColonyCharter.STAGES.slice(0,4):
		var title: String = {"shelter":"Settlement banner","provision":"Courtyard palette","connection":"Route plaque","refuge":"Refuge sign"}[stage]
		if world.charter_state.completed.has(stage):
			var enabled: bool = world.charter_state.appearances.has(stage)
			button(("Remove " if enabled else "Apply ")+title,func()->void:_submit("charter_appearance",{"definition":stage,"enabled":not enabled});close_sheet(),sheet_body)
		else: label(title+" waits for "+ColonyCharter.TITLES[stage]+".",sheet_body)

func show_charter_ending() -> void:
	runner.pause()
	show_sheet("Brackenward restored")
	label(ColonyChronicle.display_name(world,0)+" has completed its charter. The beacon watches over a living settlement. These moments come from the colony's recorded history.",sheet_body)
	for fact in ColonyChronicle.epilogue(world):
		button("Day %d: %s" % [fact.tick/7200+1,fact.text],func()->void:show_fact(fact.id),sheet_body)
	button("Continue settlement",func()->void:_submit("continue_settlement",{});close_sheet(),sheet_body)
	button("Save and leave",func()->void:
		if save_local().is_empty(): show_sheet("Menu"),sheet_body)
	button("New seed",show_campaigns,sheet_body)
	button("View settlement",func()->void:close_sheet();view.camera_tile=Vector2(ColonyTrade.cart(world).x,ColonyTrade.cart(world).y),sheet_body)

func show_chronicle() -> void:
	show_sheet("Chronicle")
	button("Pin a moment",show_pin_moment,sheet_body)
	button("Charter",show_charter,sheet_body)
	button("Full event ledger",show_ledger,sheet_body)
	var days: Array = world.chronicle_state.journal
	if days.is_empty(): label("At 22:00, up to three consequential event chains are recorded for each day. Repeated meals do not fill this journal.",sheet_body)
	for day in days.slice(maxi(0,days.size()-32)):
		if day.fact_ids.is_empty(): continue
		label("Day "+str(day.day+1),sheet_body)
		for id in day.fact_ids:
			var fact: Dictionary = ColonyChronicle.fact(world.chronicle_state,id)
			label(fact.text,sheet_body)
			button("Details of event "+str(id),func()->void:show_fact(id),sheet_body)

func show_ledger(before: int = 0) -> void:
	show_sheet("Event ledger")
	label("Exact simulation facts, including routine work. Recent events and permanent history are retained; causal links appear only when the transaction recorded one.",sheet_body)
	var records: Array = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return before==0 or f.id<before)
	var page: Array = records.slice(maxi(0,records.size()-40))
	page.reverse()
	for fact in page:
		label("Day %d %02d:%02d - %s" % [fact.tick/7200+1,(fact.tick%7200)/300,(fact.tick%300)/5,fact.text],sheet_body)
		button("Inspect event "+str(fact.id),func()->void:show_fact(fact.id),sheet_body)
	if records.size()>page.size(): button("Earlier events",func()->void:show_ledger(page[-1].id),sheet_body)

func show_fact(id: int, expanded: bool = false) -> void:
	var fact: Dictionary = ColonyChronicle.fact(world.chronicle_state,id)
	show_sheet("Event details")
	if fact.is_empty(): label("This routine event is outside retained history.",sheet_body);return
	label("Day %d %02d:%02d\n%s" % [fact.tick/7200+1,(fact.tick%7200)/300,(fact.tick%300)/5,fact.text],sheet_body)
	if not fact.names.is_empty(): label("Names at the time: "+", ".join(fact.names.values()),sheet_body)
	if not fact.get("location",[]).is_empty():
		button("View location",func()->void:close_sheet();view.camera_tile=Vector2(fact.location[0],fact.location[1]),sheet_body)
	if not fact.changes.is_empty(): label("Recorded inventory changes: "+str(fact.changes),sheet_body)
	if fact.causes.is_empty(): label("No immediate cause was recorded for this fact. No cause is inferred from nearby events.",sheet_body)
	var causes: Array = fact.causes if expanded else fact.causes.slice(0,4)
	for cause in causes:
		var evidence: Dictionary = ColonyChronicle.fact(world.chronicle_state,cause)
		label(evidence.text,sheet_body)
		button("Why: event "+str(cause),func()->void:show_fact(cause),sheet_body)
	if fact.causes.size()>4 and not expanded: button("Show all causes",func()->void:show_fact(id,true),sheet_body)
	button("Back to chronicle",show_chronicle,sheet_body)

func show_pin_moment() -> void:
	show_sheet("Pin a moment")
	label("Optional personal note. Up to 256 printable Basic Latin characters. Pinning has no reward or simulation effect.",sheet_body)
	var entry: LineEdit = LineEdit.new();entry.max_length=256;entry.placeholder_text="A moment to remember";entry.custom_minimum_size.y=48;sheet_body.add_child(entry)
	button("Pin this moment",func()->void:_submit("pin_moment",{"text":entry.text});close_sheet(),sheet_body)

func show_rename(id: int) -> void:
	show_sheet("Name this place" if id==0 else "Rename")
	label("Names are cosmetic. Use 1-32 printable Basic Latin characters; existing journal names stay as recorded.",sheet_body)
	var entry: LineEdit = LineEdit.new();entry.max_length=32;entry.text=ColonyChronicle.display_name(world,id);entry.custom_minimum_size.y=48;sheet_body.add_child(entry)
	button("Save name",func()->void:_submit("rename",{"target":id,"text":entry.text});close_sheet(),sheet_body)

func show_person_history(id: int) -> void:
	show_sheet("Remembered moments")
	label(ColonyChronicle.display_name(world,id),sheet_body)
	var person: Dictionary = world.find(world.citizens,id)
	var memories: Array = ColonyChronicle.active_memories(world,person)
	if memories.is_empty(): label("No timed memories are currently affecting morale.",sheet_body)
	for memory in memories:
		label("%s: %+d morale target. Expires day %d at %02d:%02d (%.1f hours remaining)." % [memory.text,memory.modifier,memory.expires/7200+1,(memory.expires%7200)/300,(memory.expires%300)/5,(memory.expires-world.tick)/300.0],sheet_body)
		if memory.fact_id>0: button("Remember this event",func()->void:show_fact(memory.fact_id),sheet_body)
		else: label("The original event was not retained in this campaign's history.",sheet_body)
	for fact in ColonyChronicle.highlights(world,id):
		label(fact.text,sheet_body)
		button("Details of event "+str(fact.id),func()->void:show_fact(fact.id),sheet_body)

func show_food_forecast() -> void:
	show_sheet("Food forecast")
	_tutorial_action("forecast")
	label(tutorial_forecast_text(),sheet_body)
	label("This uses accessible, unreserved food already at home and its actual spoilage. Future harvests and expedition rations kept by policy are excluded. Residents need 1000 fullness per day; one meal supplies 500.",sheet_body)
	var state: Dictionary = _tutorial_state()
	button("Unpin forecast" if state.forecast_pinned else "Pin forecast on map",func()->void:
		if state.forecast_pinned: state.forecast_pinned=false;_save_settings()
		else: _tutorial_action("pin_forecast")
		close_sheet(),sheet_body)
	var cooking: bool = world.citizens.any(func(c:Dictionary)->bool:return not c.away and not c.death_recorded and not c.departed and c.preferences.Cooking>0)
	var hearth: bool = world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="hearth" and s.cooking and not ColonyFire.burning(world,"structure",s.id))
	var raw: int = 0
	for item in world.definitions.recipes.cook_meals.alternatives: raw+=world.available(item)
	var bottlenecks: Array[String] = []
	if not cooking: bottlenecks.append("Enable Cooking for a home resident.")
	if not hearth: bottlenecks.append("Build or enable a usable hearth.")
	if raw<4: bottlenecks.append("Gather or harvest four raw food units for the next batch.")
	if world.available("wood")<1: bottlenecks.append("Gather one wood for cooking fuel.")
	label("Cooking: "+("Inputs and a cook are available; work priority, travel and output storage still affect timing." if bottlenecks.is_empty() else " ".join(bottlenecks)),sheet_body)
	button("Gather berries",func()->void:begin_gather("berry_bush"),sheet_body)
	button("Plant turnips",begin_field,sheet_body)
	button("Work preferences",func()->void:show_sheet("Work"),sheet_body)
	button("Weather forecast",show_weather,sheet_body)

func _build_guidance() -> void:
	guidance_panel = PanelContainer.new()
	guidance_panel.visible = false
	content.add_child(guidance_panel)
	var rows: VBoxContainer = VBoxContainer.new()
	guidance_panel.add_child(rows)
	guidance_forecast = label("",rows)
	guidance_forecast.max_lines_visible=3
	guidance_forecast.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var scroll: ScrollContainer = TouchScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y=32
	rows.add_child(scroll)
	guidance_text=label("",scroll)
	guidance_actions=HBoxContainer.new();rows.add_child(guidance_actions)
	button("Show me",func()->void:_tutorial_show_me();_refresh_guidance(),guidance_actions)
	button("Skip",func()->void:_tutorial_skip();_refresh_guidance(),guidance_actions)
	button("Hide",func()->void:_tutorial_dismiss();_refresh_guidance(),guidance_actions)
	guidance_forecast_button=button("Food forecast",show_food_forecast,rows)

func _refresh_guidance() -> void:
	if not is_instance_valid(guidance_panel) or not world is ColonyWorld: return
	guidance_elapsed=0.0
	guidance_card=tutorial_tick()
	guidance_signature=world.session_id+JSON.stringify(_tutorial_state())
	var pinned: bool = _tutorial_state().forecast_pinned
	guidance_forecast.visible=pinned
	guidance_forecast.text=tutorial_forecast_text() if pinned else ""
	guidance_forecast_button.visible=pinned and guidance_card.is_empty()
	guidance_text.get_parent().visible=not guidance_card.is_empty()
	guidance_actions.visible=not guidance_card.is_empty()
	guidance_text.text="" if guidance_card.is_empty() else guidance_card.text+("\n"+guidance_card.prerequisite if not guidance_card.prerequisite.is_empty() else "")
	view.tutorial_target.clear()
	if not guidance_card.is_empty(): view.tutorial_target.assign(guidance_card.target)
	view.tutorial_gesture=guidance_card.get("gesture","")
	_layout_guidance()

func _layout_guidance() -> void:
	if not is_instance_valid(guidance_panel): return
	guidance_panel.visible=sheet==null and inspector==null and not placement.visible and (not guidance_card.is_empty() or guidance_forecast.visible)
	view.tutorial_highlight_visible=sheet==null
	if not guidance_panel.visible:
		if inspector==null: view.focus_offset=Vector2.ZERO
		return
	var width: float = minf(480,content.size.x-16)
	var available: float = maxf(80,speeds.position.y-view.position.y-16)
	guidance_panel.reset_size()
	var desired: float = 128*text_scale if not guidance_card.is_empty() else 140*text_scale
	guidance_panel.size=Vector2(width,minf(desired,available))
	guidance_panel.position=Vector2(content.size.x-width-8,speeds.position.y-guidance_panel.size.y-8)
	view.focus_offset=Vector2(0,-guidance_panel.size.y*0.5)
	guidance_panel.move_to_front()
	speeds.move_to_front()
