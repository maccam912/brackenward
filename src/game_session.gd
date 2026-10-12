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
var forecast_elapsed: float = 0.0
var food_warning_level: int = 0
var saving_disabled: bool = false
var storage_error: String = ""
var recovery_failed: bool = false
var pending_import_world: ColonyWorld
var forecast: Dictionary = {"portions":24,"ticks":21600,"label":"24 portions | 3 days stored runway"}

func _ready() -> void:
	Engine.max_fps = 30
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
	if recovery_failed:
		show_recovery_problem()

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
	result.clip_text = true
	result.tooltip_text = label
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
			if not view.preview_definition.is_empty():
				view.preview_start += direction
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
	rotation_button = button("Rotate", func() -> void:
		view.preview_rotation = (view.preview_rotation + 1) % 4
		view.fit_build_preview(), placement)
	rotation_button.visible = false
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
	if store is ColonyStore and journal_elapsed >= 2.0 and not saving_disabled and not recovery_failed:
		var error: String = store.checkpoint(world)
		if not error.is_empty():
			_storage_failed(error)
		journal_elapsed = 0.0
	autosave_elapsed += delta
	if autosave_elapsed >= 30.0 and world.tick != last_saved_tick and not saving_disabled and not recovery_failed:
		save_local()
		autosave_elapsed = 0.0

func set_speed(value: int) -> void:
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
	close_sheet()
	runner.pause()
	view.cancel_gesture()
	view.follow_id = 0
	view.preview_visible = true
	view.preview_definition = ""
	placement_kind = "stockpile"
	rotation_button.visible = false
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
	if world is ColonyWorld and not view.preview_definition.is_empty():
		var error: String = world.placement_error(view.preview_definition, view.preview_start, view.preview_rotation)
		if not error.is_empty():
			notice = error
			return
	confirm_button.disabled = true
	if world is ColonyWorld and not view.preview_definition.is_empty():
		submitted_command = world.queue_command("build", {"definition": view.preview_definition, "x": view.preview_start.x, "y": view.preview_start.y, "rotation": view.preview_rotation})
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
	if action.kind == "notice":
		notice = action.text
		return
	var candidates: Array[Dictionary] = []
	for citizen in world.citizens:
		var position_on_screen: Vector2 = view.tile_to_screen(view.citizen_point(citizen))
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
		if world is ColonyWorld:
			for field in world.fields:
				if Vector2i(field.x,field.y) == action.tile:
					_field_sheet(field)
					return
			for resource in world.resources:
				if Vector2i(resource.x, resource.y) == action.tile:
					_resource_sheet(resource)
					return
			for job in world.jobs:
				if job.kind == "build" and job.state not in ["Complete", "Canceled"] and world.footprint(job).has(action.tile):
					_job_sheet(job)
					return
			notice = "Terrain (%d, %d). Use Build to place a blueprint." % [action.tile.x, action.tile.y]

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
				for kind in world.definitions.buildings:
					var definition: Dictionary = world.definitions.buildings[kind]
					button(kind.capitalize() + " | " + _cost_text(definition.materials), func() -> void: begin_build(kind), sheet_body)
		"People":
			for citizen in world.citizens:
				button(citizen.name, func() -> void:
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
			label("Brackenward 0.2.0-m2 | Godot 4.7.2\nDevelopment colony saves preserve inventory, jobs, needs and work progress. M0 saves remain separate.", sheet_body)
			button("Save colony", save_local, sheet_body)
			button("Load colony", load_local, sheet_body)
			button("Export save", func() -> void: choose_document(true), sheet_body)
			button("Import save", func() -> void: choose_document(false), sheet_body)
			button("Text size: %d%%" % int(text_scale * 100), func() -> void:
				text_scale = 1.25 if text_scale == 1.0 else (1.5 if text_scale == 1.25 else 1.0)
				_build_theme()
				show_sheet("Menu"), sheet_body)
			button("Handedness: " + ("Left" if left_handed else "Right"), func() -> void:
				left_handed = not left_handed
				show_sheet("Menu"), sheet_body)
			if world is ColonyWorld:
				button("Campaign slots",show_campaigns,sheet_body)
				button("Named snapshots",show_named_snapshots,sheet_body)
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

func save_local() -> String:
	if recovery_failed:
		return "Recovery failed; original campaign will not be overwritten"
	var error: String = store.save(world)
	if error.is_empty():
		last_saved_tick = world.tick
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
	recovery_failed = false
	storage_error = ""
	saving_disabled = false
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
	begin_placement()
	view.preview_definition = kind
	view.preview_rotation = 0
	view.preview_start = Vector2i(74, 63)
	view.fit_build_preview()
	view.camera_tile = Vector2(74, 63)
	rotation_button.visible = true
	notice = "Place %s. Tap a tile or use the arrows; Confirm spends nothing until built." % kind.capitalize()
	_layout()

func _preview_text() -> String:
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
	if submitted_command > 0:
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
	label("Gather berries or wood, then resume. Workers fetch their own inputs even with Hauling off. Preferences never override hunger or sleep.", sheet_body)
	for kind in ["tree", "berry_bush", "mushroom_patch", "herb_patch", "stone_node"]:
		var resource: Dictionary = {}
		for candidate in world.resources:
			if candidate.definition == kind and candidate.remaining > 0 and not world.jobs.any(func(job: Dictionary) -> bool: return job.kind == "gather" and job.target == candidate.id and job.state not in ["Complete", "Canceled"]):
				resource = candidate
				break
		if not resource.is_empty():
			button("Gather " + world.definitions.resources[kind].item, func() -> void:
				_submit("gather", {"target": resource.id})
				close_sheet()
				view.camera_tile = Vector2(resource.x, resource.y), sheet_body)
	for citizen in world.citizens:
		label(citizen.name + " - " + citizen.activity, sheet_body)
		button(citizen.shift, func() -> void:
			_submit("schedule", {"citizen":citizen.id,"shift":"Night shift" if citizen.shift == "Normal" else "Normal"}), sheet_body)
		for category in ColonyWorld.CATEGORIES:
			button(category + ": " + ["Off", "Last", "Normal", "First"][citizen.preferences[category]], func() -> void:
				_submit("preference", {"citizen": citizen.id, "category": category, "value": (citizen.preferences[category] + 1) % 4}), sheet_body)
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
	view.preview_start = Vector2i(74,54)
	view.preview_end = Vector2i(77,57)
	notice = "Turnips: prepare 4 WU, sow 1 WU, harvest 2 WU per tile. Two days of growth gives four vegetables."

func _field_sheet(field: Dictionary) -> void:
	show_sheet(field.crop.capitalize())
	var definition: Dictionary = world.definitions.crops[field.crop]
	label("%s\nGrowth %d/%d | Yield %d\nSoil %d%% | %s" % [field.reason,field.growth,definition.growth,field.yield_count,field.fertility/10,"Automatic replanting" if field.replant else "Replant off"],sheet_body)
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
	_replace_world(result.world)
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
	_replace_world(pending_import_world)
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
