class_name GameSession
extends Control

var world: PrototypeWorld = PrototypeWorld.new()
var runner: SimRunner = SimRunner.new(world)
var store: PrototypeStore = PrototypeStore.new()
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
var file_dialog: FileDialog
var native_storage: Object
var document_request: int = 0
var exporting: bool = false
var export_bytes: PackedByteArray = PackedByteArray()
var document_pending: bool = false
var test_insets: Vector4 = Vector4.ZERO
var controls: Array[Button] = []
var nav_labels: Array[Label] = []

func _ready() -> void:
	Engine.max_fps = 30
	if Engine.has_singleton("BrackenwardSave"):
		native_storage = Engine.get_singleton("BrackenwardSave")
		logical_scale = maxf(1.0, float(native_storage.getDensity()))
		native_storage.document_result.connect(_native_result)
	_build_theme()
	content = Control.new()
	add_child(content)
	view = WorldView.new()
	content.add_child(view)
	view.setup(world)
	view.intent.connect(_map_intent)
	_build_status()
	_build_navigation()
	_build_speed_controls()
	_build_map_tools()
	_build_placement()
	resized.connect(_resize)
	_layout()
	show_sheet("Welcome")

func _build_theme() -> void:
	var ui_theme: Theme = Theme.new()
	ui_theme.default_font = load("res://assets/exported/fonts/kenney_mini.ttf")
	ui_theme.default_font_size = int(18 * text_scale)
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
	result.name = label.validate_node_name()
	result.custom_minimum_size = Vector2(width, 48)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.pressed.connect(callback)
	parent.add_child(result)
	controls.append(result)
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
	content.add_child(map_tools)
	var zoom: HBoxContainer = HBoxContainer.new()
	map_tools.add_child(zoom)
	button("-", func() -> void: view.zoom_at(0.8, view.size * 0.5), zoom)
	button("+", func() -> void: view.zoom_at(1.25, view.size * 0.5), zoom)
	var nudge: GridContainer = GridContainer.new()
	nudge.columns = 2
	map_tools.add_child(nudge)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var title: String = {Vector2.UP: "Up", Vector2.DOWN: "Down", Vector2.LEFT: "Left", Vector2.RIGHT: "Right"}[direction]
		button(title, func() -> void:
			view.follow_id = 0
			view.camera_tile += direction * 3
			view._update_transform(), nudge)

func _build_placement() -> void:
	placement = VBoxContainer.new()
	content.add_child(placement)
	placement.visible = false
	preview_label = label("", placement)
	preview_label.add_theme_stylebox_override("normal", _box(Color("263C3B")))
	placement_nudges = HBoxContainer.new()
	placement.add_child(placement_nudges)
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var title: String = {Vector2i.LEFT: "Left", Vector2i.RIGHT: "Right", Vector2i.UP: "Up", Vector2i.DOWN: "Down"}[direction]
		button(title, func() -> void:
			view.preview_end += direction
			view.preview_end.x = clampi(view.preview_end.x, 0, 127)
			view.preview_end.y = clampi(view.preview_end.y, 0, 127), placement_nudges)
	placement_actions = HBoxContainer.new()
	placement.add_child(placement_actions)
	button("Cancel", cancel_placement, placement_actions, 64)
	button("Pan", func() -> void:
		view.cancel_gesture()
		view.gestures.mode = "paint" if view.gestures.mode == "pan" else "pan", placement_actions, 64)
	confirm_button = button("Confirm", confirm_placement, placement_actions, 96)
	placement_wide_row = HBoxContainer.new()
	placement.add_child(placement_wide_row)

func _process(delta: float) -> void:
	if not is_node_ready() or backgrounded:
		return
	runner.advance_frame(delta)
	if runner.speed_reduced:
		notice = "Speed reduced to keep the colony responsive."
		runner.speed_reduced = false
	if submitted_command > 0 and world.receipts.has(submitted_command):
		var receipt: String = world.receipts[submitted_command]
		notice = "Area accepted. Work simulation follows in M1." if receipt == "accepted" else "Area rejected: " + receipt
		submitted_command = 0
		confirm_button.disabled = false
	var day: int = world.tick / 7200 + 1
	var hour: int = (world.tick % 7200) / 300
	var minute: int = (world.tick % 300) / 5
	clock_label.text = "Spring %d  %02d:%02d\n4 travelers  |  %s" % [day, hour, minute, "Paused" if runner.speed == 0 else "%dx" % runner.speed]
	notice_label.text = notice
	if is_instance_valid(sheet_feedback):
		sheet_feedback.text = notice
	preview_label.text = "%d x %d tiles | %s" % [absi(view.preview_end.x - view.preview_start.x) + 1, absi(view.preview_end.y - view.preview_start.y) + 1, "Pan mode" if view.gestures.mode == "pan" else "Paint preview"]
	autosave_elapsed += delta
	if autosave_elapsed >= 30.0 and world.tick != last_saved_tick:
		save_local()
		autosave_elapsed = 0.0

func set_speed(value: int) -> void:
	if not sheet_name.is_empty() or backgrounded or (placement.visible and value != 0):
		notice = "Close the panel or confirm/cancel the area before resuming."
		return
	runner.set_speed(value)

func begin_placement() -> void:
	close_sheet()
	runner.pause()
	view.cancel_gesture()
	view.follow_id = 0
	view.preview_visible = true
	view.gestures.mode = "paint"
	placement.visible = true
	view.camera_tile = Vector2(77, 55)
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
	if confirm_button.disabled or not placement.visible:
		return
	for tile in view.preview_tiles():
		if PrototypeWorld.is_water(tile):
			notice = "Deep river cannot be designated. Move the preview onto land."
			return
	confirm_button.disabled = true
	submitted_command = world.queue_designation(view.preview_tiles())
	view.cancel_gesture()
	view.preview_visible = false
	placement.visible = false
	view.gestures.mode = "select"
	notice = "Area pending. Resume to validate it on the next tick."
	_layout()

func _map_intent(action: Dictionary) -> void:
	if action.kind == "notice":
		notice = action.text
		return
	var candidates: Array[Dictionary] = []
	for citizen in world.citizens:
		var position_on_screen: Vector2 = view.tile_to_screen(Vector2(citizen.x + 0.5 + float(citizen.progress) / 10000.0 * citizen.direction, citizen.y + 0.5))
		if position_on_screen.distance_to(action.point) <= maxf(24, view.tile_size * 0.6):
			candidates.append(citizen)
	if action.kind == "chooser" or candidates.size() > 1:
		show_sheet("Select object")
		for citizen in candidates:
			button(citizen.name, func() -> void:
				close_sheet()
				select_citizen(citizen.id), sheet_body)
		label("Terrain (%d, %d)" % [action.tile.x, action.tile.y], sheet_body)
	elif candidates.size() == 1:
		select_citizen(candidates[0].id)
	else:
		notice = "Terrain (%d, %d). Use Build to preview an area." % [action.tile.x, action.tile.y]

func select_citizen(id: int) -> void:
	selected = id
	view.selected_id = id
	if inspector != null:
		inspector.queue_free()
	inspector = PanelContainer.new()
	content.add_child(inspector)
	var inspector_rows: VBoxContainer = VBoxContainer.new()
	inspector.add_child(inspector_rows)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_rows.add_child(scroll)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var citizen: Dictionary = world.citizens[id - 1]
	label("%s - looking around\nPlaceholder movement, one tile per second.\nSkills and needs arrive with the worker loop." % citizen.name, rows)
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
	heading.add_theme_font_size_override("font_size", int(22 * text_scale))
	var close_button: Button = button("Close", close_sheet, top, 64)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var pause_button: Button = button("Pause", func() -> void: runner.pause(), top, 72)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var scroll: ScrollContainer = ScrollContainer.new()
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
			label("M0 touch prototype. Explore, select a traveler, paint an area, try the speeds, and save. Gathering, cooking, building, and survival follow after the phone test.", sheet_body)
			button("Begin", func() -> void:
				close_sheet()
				notice = "Tap Mira and Follow. Time starts paused.", sheet_body)
			button("Look around", close_sheet, sheet_body)
		"Build":
			label("Preview an area using taps, a drag, or nudge buttons. Confirmation queues a designation; no supplies are spent in this prototype.", sheet_body)
			button("Paint area", begin_placement, sheet_body)
		"People":
			for citizen in world.citizens:
				button(citizen.name, func() -> void:
					close_sheet()
					select_citizen(citizen.id), sheet_body)
		"Work":
			label("Worker assignment is the next milestone.\nMira: Cooking / Care\nOren: Building\nTavi: Gathering\nSela: Research", sheet_body)
		"Valley":
			label("The regional map and expeditions arrive in M4. This checkpoint tests the local map and mobile storage.", sheet_body)
		"Journal":
			label("Confirmed area: %d tiles\nPending actions: %d\nSimulation tick: %d\nThe prototype does not generate colony stories yet." % [world.designations.size(), world.pending_commands.size(), world.tick], sheet_body)
		"Menu":
			label("Brackenward 0.0.1-m0 | Godot 4.7.2\nTouch-prototype saves use a separate format from future campaigns.", sheet_body)
			button("Save prototype", save_local, sheet_body)
			button("Load prototype", load_local, sheet_body)
			button("Export save", func() -> void: choose_document(true), sheet_body)
			button("Import save", func() -> void: choose_document(false), sheet_body)
			button("Text size: %d%%" % int(text_scale * 100), func() -> void:
				text_scale = 1.25 if text_scale == 1.0 else (1.5 if text_scale == 1.25 else 1.0)
				_build_theme()
				show_sheet("Menu"), sheet_body)
			button("Handedness: " + ("Left" if left_handed else "Right"), func() -> void:
				left_handed = not left_handed
				show_sheet("Menu"), sheet_body)
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
	var header_height: float = (144.0 if wrap_navigation or width < 600 else 104.0) * text_scale
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

func save_local() -> void:
	var error: String = store.save(world)
	if error.is_empty():
		last_saved_tick = world.tick
		notice = "Saved and verified at tick %d." % world.tick
	else:
		runner.pause()
		notice = error + " Open Menu to retry or export."

func load_local() -> void:
	runner.pause()
	var result: Dictionary = store.load_latest()
	if result.has("error"):
		notice = result.error
		return
	_replace_world(result.world)
	notice = "Prototype restored. Time stays paused."

func _replace_world(state: PrototypeWorld) -> void:
	world = state
	runner = SimRunner.new(world)
	view.world = world
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
		export_bytes = PrototypeCodec.encode(world)
		if PrototypeCodec.decode(export_bytes).has("error"):
			notice = "Snapshot validation failed. Nothing exported."
			return
	if native_storage != null:
		document_pending = true
		if export:
			native_storage.chooseExportDestination(document_request, "brackenward-prototype.brackenward")
		else:
			native_storage.chooseImportDocument(document_request)
		return
	file_dialog = FileDialog.new()
	document_pending = true
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = true
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if export else FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.brackenward ; Brackenward prototype"])
	file_dialog.current_file = "brackenward-prototype.brackenward" if export else ""
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
		notice = "Export written and verified." if error == OK and not PrototypeCodec.decode(FileAccess.get_file_as_bytes(path)).has("error") else "Export write/verification failed."
	else:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null or file.get_length() > PrototypeCodec.MAX_BYTES:
			notice = "Could not read save, or file exceeds the prototype's 1 MiB limit."
			return
		_accept_import(file.get_buffer(file.get_length()))

func _native_result(request: int, result: String, bytes: PackedByteArray) -> void:
	if request != document_request:
		return
	if result not in ["export_selected", "import_selected"]:
		document_pending = false
	match result:
		"export_selected": native_storage.writeSelectedDocument(request, export_bytes)
		"import_selected": native_storage.readSelectedDocument(request, PrototypeCodec.MAX_BYTES)
		"read": _accept_import(bytes)
		"written": notice = "Export written and verified."
		"canceled": notice = "Picker canceled. Saves unchanged."
		_: notice = "Document operation failed: " + result

func _accept_import(bytes: PackedByteArray) -> void:
	var result: Dictionary = PrototypeCodec.decode(bytes)
	if result.has("error"):
		notice = result.error
		return
	_replace_world(result.world)
	notice = "Imported verified prototype. Time stays paused."

func suspend() -> void:
	if backgrounded:
		return
	backgrounded = true
	runner.pause()
	view.cancel_gesture()
	save_local()

func resume_from_background() -> void:
	backgrounded = false
	runner.pause()
	view.cancel_gesture()
	notice = "While you were away, nothing advanced."
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
