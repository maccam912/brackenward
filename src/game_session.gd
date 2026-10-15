class_name GameSession
extends Control

var world: RefCounted = ColonyWorld.new(ColonyCatalog.load_data(), Crypto.new().generate_random_bytes(16).hex_encode())
var runner: SimRunner = SimRunner.new(world)
var store: PrototypeStore = ColonyStore.new()
var deletion: ColonyDeletion = ColonyDeletion.new()
var view: WorldView
var content: Control
var status: PanelContainer
var clock_label: Label
var clock_world_id: int = 0
var clock_tick: int = -1
var clock_speed: int = -1
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
var text_entry_error: String = ""
var inspector: PanelContainer
var selected: int = 0
var work_orders_page: int = 0
var sheet_name: String = ""
var sheet_route: String = ""
var sheet_title_key: String = ""
var sheet_camera_center: Vector2 = Vector2.ZERO
var sheet_entry_speed: int = 0
var placement_entry_speed: int = 0
var text_scale: float = 1.0
var left_handed: bool = false
var logical_scale: float = 1.0
var notice: String = "Four travelers. A ruined wayhouse. Make a place to stay."
var submitted_command: int = 0
var placement_commands: Array[int] = []
var placement_world_id: int = 0
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
var document_kind: String = "save"
var diagnostic_preview: Dictionary = {}
var diagnostics: FrameDiagnostics = FrameDiagnostics.new()
var test_insets: Vector4 = Vector4.ZERO
var controls: Array[Button] = []
var nav_labels: Array[Label] = []
var inspector_details: Label
var inspector_portrait: TextureRect
var listening_binding: String = ""
var sheet_heading: Label
var sheet_full_heading: Label
var soundscape: ColonyAudio
var quitting: bool = false
var native_smoke_target: int = 0
var native_smoke_remaining: int = 0
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
var tutorial_suggestions: Dictionary = {}
var forecast: Dictionary = {"portions":24,"ticks":21600,"label":"24 portions | 3 days stored runway"}

func _ready() -> void:
	Engine.max_fps = 30
	get_tree().auto_accept_quit=false
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var smoke: int = arguments.find("--native-smoke-frames")
	if smoke>=0:
		if arguments.count("--native-smoke-frames")!=1 or smoke+1>=arguments.size() or not arguments[smoke+1].is_valid_int() or int(arguments[smoke+1])<1 or int(arguments[smoke+1])>600:
			push_error("Invalid native smoke frame target");get_tree().quit(2);return
		native_smoke_target=int(arguments[smoke+1]);native_smoke_remaining=native_smoke_target
		store.root_directory="user://native-smoke-%d" % Time.get_ticks_usec();store.select_slot(1)
		settings.path=store.root_directory.path_join("settings.json")
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
	diagnostics.tick=world.tick;diagnostics.speed=runner.speed
	view = _make_world_view()
	view.diagnostics=diagnostics
	content.add_child(view)
	view.setup(world)
	if world is ColonyWorld:
		soundscape=_make_soundscape();add_child(soundscape);soundscape.bind_world(world,view)
		soundscape.diagnostics=diagnostics
	_apply_device_settings()
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
	show_sheet("Welcome","ui.sheet.welcome")
	if recovery_failed:
		show_recovery_problem()
	elif store is ColonyStore and store.root_directory == ColonyStore.CAMPAIGN_ROOT and not ColonyStore.occupied(store.slot):
		awaiting_first_colony = true
		show_new_colony(store.slot)
	if native_smoke_target>0:
		awaiting_first_colony=true;show_new_colony(1)
	if world is ColonyWorld and not awaiting_first_colony: save_queue.prime(world)

func _make_soundscape() -> ColonyAudio:
	return ColonyAudio.new()

func _make_world_view() -> WorldView:
	return WorldView.new()

func _build_theme() -> void:
	var ui_theme: Theme = Theme.new()
	ui_theme.default_font = ColonyFonts.body()
	ui_theme.default_font_size = int(16 * text_scale)
	ui_theme.set_color("font_color", "Label", Color("F8F3E7"))
	for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color","font_hover_pressed_color"]:
		ui_theme.set_color(state,"Button",Color("F8F3E7"))
	ui_theme.set_color("font_disabled_color", "Button", Color("B8BCAD"))
	for type_name in ["PanelContainer", "Button"]:
		var box: StyleBoxFlat = _box(Color("263C3B"))
		ui_theme.set_stylebox("panel" if type_name == "PanelContainer" else "normal", type_name, box)
	ui_theme.set_stylebox("hover", "Button", _box(Color("375749")))
	ui_theme.set_stylebox("pressed", "Button", _box(Color("6F6B86")))
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
	result.text = ColonyFonts.display(label)
	result.clip_text = true
	result.tooltip_text = ColonyFonts.display(label)
	var font_warning: String = ColonyFonts.warning(label)
	if not font_warning.is_empty(): result.tooltip_text+="\n"+font_warning
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
	if callback.is_valid(): result.pressed.connect(func()->void:
		if is_instance_valid(soundscape): soundscape.cue("ui_cancel" if label in ["Cancel","Close"] or label.begins_with("Back") else "ui_select")
		callback.call())
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
	result.text = ColonyFonts.display(text)
	result.tooltip_text=ColonyFonts.warning(text)
	if not result.tooltip_text.is_empty(): result.text+="\n"+result.tooltip_text
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
	var menu_button: Button = button(ColonyText.text("ui.action.menu"), func() -> void: show_sheet("Menu","ui.sheet.menu"), row, 64)
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
		var title_key: String=ColonyText.sheet_key(title)
		var display_title: String=ColonyText.text(title_key)
		var entry: Button = button(display_title, func() -> void: show_sheet(title,title_key), nav)
		entry.text = ""
		entry.tooltip_text = display_title
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
		caption.text = display_title
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
	button(ColonyText.text("ui.action.pause"), func() -> void: set_speed(0), speeds, 72)
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
	button(ColonyText.text("ui.action.cancel"), cancel_placement, placement_actions, 64)
	button(ColonyText.text("ui.action.pan"), func() -> void:
		view.cancel_gesture()
		view.gestures.mode = "paint" if view.gestures.mode == "pan" else "pan", placement_actions, 64)
	confirm_button = button(ColonyText.text("ui.action.confirm"), confirm_placement, placement_actions, 96)
	rotation_button = button(ColonyText.text("ui.action.rotate"), func() -> void:
		view.preview_rotation = (view.preview_rotation + 1) % 4
		view.fit_build_preview(), placement)
	rotation_button.visible = false
	placement_wide_row = HBoxContainer.new()
	placement_wide_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placement.add_child(placement_wide_row)

func _process(delta: float) -> void:
	var started: int = Time.get_ticks_usec()
	if is_node_ready() and not backgrounded and not quitting: diagnostics.frame(started,world.tick,runner.playback_speed())
	_advance_frame(delta)
	if not backgrounded and not quitting: diagnostics.record("session",Time.get_ticks_usec()-started)

func _advance_frame(delta: float) -> void:
	if quitting: return
	_sync_placement_world()
	if native_smoke_remaining>0:
		native_smoke_remaining-=1
		if native_smoke_remaining==0: quit_application();return
	if not is_node_ready() or backgrounded:
		return
	save_clock+=delta
	_finish_background_save()
	var preparation: Dictionary = save_queue.poll_preparation()
	_record_worker_timing("snapshot_worker",preparation)
	if not preparation.get("error","").is_empty(): _storage_failed(preparation.error)
	if store is ColonyStore and not _has_undurable_progress(): durable_at=save_clock
	if _storage_wait_required() and runner.speed>0:
		diagnostics.count("slow_storage_pauses")
		runner.pause()
		notice="Saving is slow; paused to protect recent progress. Resume after saving finishes."
	var tick_before: int = world.tick
	var simulation_started: int = Time.get_ticks_usec()
	runner.quiet_sleep_allowed=food_warning_level<2
	runner.advance_frame(delta)
	if world.tick>tick_before: diagnostics.record("simulation_batch",Time.get_ticks_usec()-simulation_started,world.tick,runner.frame_speed)
	diagnostics.speed=runner.frame_speed
	if not runner.notice.is_empty(): notice=runner.notice;runner.notice=""
	if runner.speed>0 and notice==ColonyText.text("ui.notice.paused"): notice=ColonyText.text("ui.notice.running")
	view.simulation_speed=runner.playback_speed()
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
			if world.citizens.any(func(c:Dictionary)->bool:return c.downed or c.death_recorded):
				if settings.values.auto_pauses.downed: show_care()
				else: notice="A resident needs urgent care. Open People > Injuries and care."
	if world is ColonyWorld and world.region_state.alert_serial>seen_region_alert:
		seen_region_alert=world.region_state.alert_serial
		if ColonyRegion.critical(world):
			if settings.values.auto_pauses.expedition: show_expeditions()
			else: notice="An expedition needs a decision. Open Valley > Expedition status."
	if world is ColonyWorld and world.fire_state.alert_serial>seen_fire_alert:
		seen_fire_alert=world.fire_state.alert_serial
		if not ColonyFire.active(world).is_empty():
			if settings.values.auto_pauses.fire: show_fires()
			else: notice="A building is on fire. Open People > Fires and water."
	if world is ColonyWorld and world.defense_state.alert_serial>seen_defense_alert:
		seen_defense_alert=world.defense_state.alert_serial
		if not ColonyDefense.active(world).is_empty():
			if settings.values.auto_pauses.hostile: show_defense()
			else: notice="A hostile party has arrived. Open People > Defense and shelter."
	if world is ColonyWorld:
		for event in world.opportunity_state.offers:
			if event.id<=seen_opportunity_id: continue
			seen_opportunity_id=event.id
			if event.state=="Offered": notice=event.definition.replace("_"," ").capitalize()+" offer: open Valley > Visitor opportunities. Two game days; declining has no penalty."
	if runner.speed_reduced:
		diagnostics.count("speed_reductions")
		notice = "Speed reduced to keep the colony responsive."
		runner.speed_reduced = false
	if runner.sleep_boost_limited:
		diagnostics.count("quiet_sleep_limits")
		notice=ColonyText.text("ui.notice.quiet_sleep_limited")
		runner.sleep_boost_limited=false
	var waiting: Array[int] = placement_commands.duplicate()
	if submitted_command>0 and not waiting.has(submitted_command): waiting.append(submitted_command)
	var rejected: Array[String] = []
	for command_id in waiting:
		if not world.receipts.has(command_id): continue
		var receipt: String = world.receipts[command_id]
		var accepted: bool = receipt=="accepted" or receipt.begins_with("Accepted ")
		if is_instance_valid(soundscape): soundscape.cue("ui_confirm" if accepted else "ui_error")
		notice = ColonyText.text("ui.placement.accepted") if receipt == "accepted" else (receipt if accepted else "Order rejected: " + receipt)
		if not accepted: rejected.append(receipt)
		placement_commands.erase(command_id)
		if submitted_command==command_id: submitted_command=0
		if not placement.visible: confirm_button.disabled=false
	if not rejected.is_empty(): notice="Order rejected: "+"; ".join(rejected)
	_update_inspector()
	if world is ColonyWorld:
		forecast_elapsed += delta
		if forecast_elapsed >= 1.0:
			forecast = FoodForecast.calculate(world)
			forecast_elapsed = 0.0
			var warning: int = 3 if forecast.ticks < 3600 else (2 if forecast.ticks < 7200 else (1 if forecast.ticks < 14400 else 0))
			if warning > food_warning_level:
				notice = ColonyText.text("ui.forecast.warning",{"runway":ColonyText.food_runway(forecast)})
				if is_instance_valid(soundscape): soundscape.cue("cue_warning",2,"",0.9)
				if warning==3 and settings.values.auto_pauses.low_food: runner.pause()
			food_warning_level = warning
	_refresh_clock()
	notice_label.text = ColonyFonts.display(("Unsaved progress | " if saving_disabled else "") + notice)
	if is_instance_valid(sheet_feedback):
		var feedback: String = text_entry_error if not text_entry_error.is_empty() else notice
		sheet_feedback.text = ColonyFonts.display(feedback)
		sheet_feedback.visible=sheet_route not in ["Welcome","Style"] and not feedback.is_empty() and not feedback.begins_with("Paused. Choose")
	# A canceled/confirmed preview must not keep validating its hidden footprint.
	if placement.visible: preview_label.text = ColonyFonts.display(_preview_text())
	if is_instance_valid(soundscape): soundscape.observe()
	journal_elapsed += delta
	if store is ColonyStore and journal_elapsed >= 1.0 and not save_queue.busy() and not saving_disabled and not recovery_failed and not awaiting_first_colony and sheet_route!="Delete saves":
		var new_commands: bool = world.next_command_id!=store.journal_payload.get("next_command_id",world.next_command_id)
		if world.tick!=store.journal_tick or new_commands: _start_background_save(world.tick==store.journal_tick)
		journal_elapsed = 0.0
	autosave_elapsed += delta
	if autosave_elapsed >= 30.0 and world.tick != last_saved_tick and not saving_disabled and not recovery_failed and not awaiting_first_colony and sheet_route!="Delete saves":
		if store is ColonyStore:
			if not save_queue.preparing() and not save_queue.ready(world): _start_snapshot_preparation()
			if save_queue.ready(world) and not save_queue.busy():
				_start_background_save(true)
				autosave_elapsed = 0.0
		else:
			save_local()
			autosave_elapsed = 0.0

func _refresh_clock() -> void:
	# Stock changes only at complete simulation ticks. A new world can share the
	# old tick, and pause/speed changes must still appear immediately.
	var identity: int = world.get_instance_id()
	var playback: int=runner.playback_speed()
	if clock_world_id==identity and clock_tick==world.tick and clock_speed==playback: return
	clock_world_id=identity;clock_tick=world.tick;clock_speed=playback
	var season_name: String = ColonyText.text(["ui.clock.spring","ui.clock.summer","ui.clock.autumn","ui.clock.winter"][ColonyAgriculture.season(world.tick)])
	var stock: String = ColonyText.text("ui.clock.stock",{"meals":world.available("meal"),"wood":world.available("wood")}) if world is ColonyWorld else ColonyText.plural("ui.clock.travelers",world.citizens.size())
	var speed_name: String = ColonyText.text("ui.clock.quiet_sleep",{"speed":runner.playback_speed()}) if runner.sleep_fast_forward else ColonyText.speed_label(runner.speed)
	clock_label.tooltip_text=ColonyText.text("ui.help.quiet_sleep",{"speed":runner.speed}) if runner.sleep_fast_forward else ""
	clock_label.text=ColonyText.text("ui.clock.status",{"season":season_name,"day":(world.tick/7200)%8+1,"year":world.tick/230400+1,"hour":"%02d" % ((world.tick%7200)/300),"minute":"%02d" % ((world.tick%300)/5),"stock":stock,"speed":speed_name})

func _start_background_save(full_snapshot: bool) -> void:
	var started: int = Time.get_ticks_usec()
	save_requested_at=save_clock
	var error: String = save_queue.start(store,world,full_snapshot,runner.playback_speed())
	diagnostics.record("save_capture",Time.get_ticks_usec()-started)
	if not error.is_empty(): _storage_failed(error)

func _start_snapshot_preparation() -> void:
	var started: int = Time.get_ticks_usec()
	var error: String = save_queue.start_preparation(world,runner.playback_speed())
	diagnostics.record("snapshot_capture",Time.get_ticks_usec()-started)
	if not error.is_empty(): _storage_failed(error)

func _finish_background_save(wait: bool = false, report_error: bool = true) -> String:
	var started: int = Time.get_ticks_usec()
	var error: String = _poll_background_save(wait,report_error)
	diagnostics.record("save_finish",Time.get_ticks_usec()-started)
	return error

func _poll_background_save(wait: bool, report_error: bool) -> String:
	if wait: _record_worker_timing("snapshot_worker",save_queue.discard_preparation())
	var result: Dictionary = save_queue.poll(wait)
	if result.is_empty(): return ""
	if result.world!=world or result.store!=store: return result.error
	_record_worker_timing("save_worker",result)
	if not result.error.is_empty():
		if report_error: _storage_failed(result.error)
		return result.error
	durable_at=save_requested_at
	if result.snapshot:
		last_saved_tick=result.tick
		_save_settings()
	return ""

func _record_worker_timing(stage: String, result: Dictionary) -> void:
	# A queue started without presentation context must not inherit poll-time
	# speed/tick. Every completion is consumed once by its normal polling path.
	if result.get("speed",-1)<0: return
	diagnostics.record(stage,result.worker_us,result.tick,result.speed)

func _storage_wait_required() -> bool:
	return store is ColonyStore and not saving_disabled and not recovery_failed and not awaiting_first_colony and _has_undurable_progress() and save_clock-durable_at>=1.75

func _has_undurable_progress() -> bool:
	return world.tick!=store.journal_tick or world.next_command_id!=store.journal_payload.get("next_command_id",world.next_command_id)

func set_speed(value: int) -> void:
	if quitting: return
	if value==0: placement_entry_speed=0;sheet_entry_speed=0
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
	if sheet!=null or backgrounded or (placement.visible and value != 0):
		notice = "Close the panel or confirm/cancel the area before resuming."
		return
	runner.set_speed(value)
	if value==0 and notice==ColonyText.text("ui.notice.running"): notice=ColonyText.text("ui.notice.paused")

func begin_placement() -> void:
	_sync_placement_world()
	if awaiting_first_colony:
		show_new_colony(store.slot)
		return
	var center: Vector2 = sheet_camera_center if sheet!=null and view.follow_id>0 else view.camera_center()
	placement_entry_speed=sheet_entry_speed if sheet!=null else runner.speed
	view.follow_id=0
	close_sheet()
	runner.pause()
	confirm_button.disabled = false
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
	notice = ColonyText.text("ui.placement.area_notice")
	_layout()
	view.center_camera(center)
	view.preview_start = view.screen_to_tile(view.size * 0.5)
	view.preview_end = view.preview_start

func cancel_placement() -> void:
	placement_entry_speed=0
	view.rejected_build_tiles.clear()
	view.cancel_gesture()
	view.preview_visible = false
	view.gestures.mode = "select"
	placement.visible = false
	notice = ColonyText.text("ui.placement.cancel_notice")
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
		if error.is_empty(): error=view.confirmed_build_error(view.preview_definition,view.preview_tiles())
		if not error.is_empty():
			notice = error
			return
	if placement_kind == "lodge":
		var error: String = ColonyConstruction.lodge_error(world,view.preview_start)
		if error.is_empty():
			for plan in ColonyConstruction.lodge(view.preview_start):
				error=view.confirmed_build_error(plan.definition,world.footprint(plan))
				if not error.is_empty(): break
		if not error.is_empty(): notice=error;return
	var paint_tiles: Array[Vector2i] = []
	if placement_kind == "build_area":
		var preview: Dictionary = _paint_preview()
		view.rejected_build_tiles=preview.rejected
		if preview.valid.is_empty(): notice="No valid tiles. Inspect the red cells or clear obstructions.";return
		paint_tiles.assign(preview.valid)
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
		submitted_command=world.queue_command("build_area",{"definition":paint_build_definition,"tiles":paint_tiles})
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
	placement_commands.append(submitted_command)
	view.cancel_gesture()
	view.preview_visible = false
	placement.visible = false
	view.gestures.mode = "select"
	notice = ColonyText.text("ui.placement.confirmed")
	view.refresh_confirmed_orders()
	_layout()
	var resume_speed: int = placement_entry_speed
	placement_entry_speed=0
	if resume_speed>0: set_speed(resume_speed)

func _map_intent(action: Dictionary) -> void:
	if action.kind == "notice": notice=action.text;return
	view.refresh_resident_markers()
	var candidates: Array[Dictionary] = []
	for citizen in world.citizens:
		if not view.resident_visible(citizen): continue
		var separation: float = view.resident_selection_point(citizen).distance_to(action.point)
		if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"citizen","object":citizen,"rank":0,"distance":separation})
	if world is ColonyWorld:
		for enemy in world.defense_state.enemies:
			if enemy.state=="Gone": continue
			var separation: float = view.tile_to_screen(AnimalSprite.route_point(enemy)).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"enemy","object":enemy,"rank":1,"distance":separation})
		for visitor in world.opportunity_state.visitors:
			if visitor.state in ["Waiting","Gone"]: continue
			var separation: float = view.tile_to_screen(AnimalSprite.route_point(visitor)).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"visitor","object":visitor,"rank":1,"distance":separation})
		for merchant in world.trade_state.merchants:
			if merchant.state not in ["Entering","Trading","Leaving"]: continue
			var separation: float = view.tile_to_screen(AnimalSprite.route_point(merchant)).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"merchant","object":merchant,"rank":1,"distance":separation})
		for animal in world.domestic_state.animals:
			if animal.health<=0 or animal.away: continue
			var separation: float = view.tile_to_screen(AnimalSprite.point_for(world,animal,"domestic")).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"domestic","object":animal,"rank":2,"distance":separation})
		for animal in world.wildlife_state.animals:
			if animal.health<=0: continue
			var separation: float = view.tile_to_screen(AnimalSprite.route_point(animal)).distance_to(action.point)
			if separation<=maxf(24,view.tile_size*0.6): candidates.append({"kind":"wildlife","object":animal,"rank":2,"distance":separation})
		for structure in world.structures:
			if world.footprint(structure).has(action.tile): candidates.append({"kind":"station","object":structure,"rank":3,"distance":0.0})
		for job in world.unfinished_jobs():
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
		show_sheet("Select object","ui.sheet.select_object")
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
			show_sheet("Unsubmitted building cell","ui.sheet.unsubmitted_building_cell");label(view.rejected_build_tiles[action.tile],sheet_body);return
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
			show_sheet("Carcass","ui.sheet.carcass")
			label("%s: %.1f game hours until spoilage. Gathering workers butcher it; outputs need hauling." % [_catalog_name(object.definition),(object.expires-world.tick)/300.0],sheet_body)
	view.inspected_object=object.id
	if candidate.kind in ["station","job"]: view.inspected_tiles=world.footprint(object)
	elif object.has("x") and object.has("y"): view.inspected_tiles.assign([Vector2i(object.x,object.y)])

func select_citizen(id: int) -> void:
	if settings.values.inspector_pause: runner.pause()
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
	if world is ColonyWorld:
		inspector_portrait=CitizenArt.portrait(citizen.appearance,64);rows.add_child(inspector_portrait)
	inspector_details = label("", rows)
	_update_inspector()
	if world is ColonyWorld: button(ColonyText.text("ui.action.assign_bed"),func()->void:show_beds(id),rows)
	var actions: HBoxContainer = HBoxContainer.new()
	inspector_rows.add_child(actions)
	button(ColonyText.text("ui.action.follow"), func() -> void:
		if view.tile_size<ResidentMarkers.ZOOM_LIMIT: view.zoom_at(32.0/view.tile_size,view.size*0.5)
		view.follow_id = id;_tutorial_action("follow",{"citizen":id});_refresh_guidance(), actions, 80)
	button(ColonyText.text("ui.action.close"), close_inspector, actions, 64)
	_layout()

func close_inspector() -> void:
	if inspector != null:
		inspector.queue_free()
		inspector = null
	selected = 0
	view.selected_id = 0
	view.inspected_tiles.clear();view.inspected_object=0

func show_details(title: String) -> void:
	show_sheet(title,"",true)

func show_sheet(title: String, title_key: String = "", literal_title: bool = false) -> void:
	listening_binding=""
	text_entry_error=""
	if notice==ColonyText.text("ui.notice.running"): notice=ColonyText.text("ui.notice.paused")
	if sheet==null:
		sheet_camera_center=view.camera_center()
		sheet_entry_speed=runner.speed
	runner.pause()
	view.cancel_gesture()
	if sheet != null:
		sheet.queue_free()
	close_inspector()
	sheet_name = title
	sheet_route="" if literal_title else title
	sheet_title_key=title_key
	var display_title: String=ColonyText.text(title_key) if not title_key.is_empty() else title
	sheet = PanelContainer.new()
	content.add_child(sheet)
	var rows: VBoxContainer = VBoxContainer.new()
	sheet.add_child(rows)
	var top: HBoxContainer = HBoxContainer.new()
	rows.add_child(top)
	var heading: Label = label(display_title, top)
	sheet_heading=heading
	heading.name="SheetHeading"
	heading.autowrap_mode=TextServer.AUTOWRAP_OFF
	heading.clip_text=true
	heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.tooltip_text=ColonyFonts.display(display_title)
	if not ColonyFonts.warning(display_title).is_empty(): heading.tooltip_text+="\n"+ColonyFonts.warning(display_title)
	heading.add_theme_font_override("font", ColonyFonts.heading())
	heading.add_theme_font_size_override("font_size", int(16 * text_scale))
	var close_button: Button = button(ColonyText.text("ui.action.close"), close_sheet, top, 64)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var pause_button: Button = button(ColonyText.text("ui.action.pause"), func() -> void: runner.pause(), top, 72)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var scroll: ScrollContainer = TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(scroll)
	sheet_body = VBoxContainer.new()
	sheet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sheet_body)
	sheet_full_heading=label(display_title,sheet_body)
	sheet_full_heading.name="FullSheetHeading"
	sheet_full_heading.add_theme_font_override("font",ColonyFonts.heading())
	sheet_full_heading.add_theme_font_size_override("font_size",int(16*text_scale))
	top.resized.connect(_adapt_sheet_heading)
	call_deferred("_adapt_sheet_heading")
	sheet_feedback = label(notice, sheet_body)
	sheet_feedback.visible=sheet_route!="Welcome" and not notice.is_empty() and not notice.begins_with("Paused. Choose")
	match sheet_route:
		"Welcome":
			label(ColonyText.text("ui.help.sheet.four_travelers_a_ruined_wayhouse_make_a"), sheet_body)
			label(ColonyText.text("ui.help.sheet.start_paused_gather_berries_and_wood_place"), sheet_body)
			label(ColonyText.text("ui.help.sheet.meals_3_days_of_starting_food_cooking"), sheet_body)
			button(ColonyText.text("ui.action.begin"), func() -> void:
				_tutorial_begin();close_sheet();_refresh_guidance()
				if not guidance_card.get("target",[]).is_empty():
					view.camera_tile=Vector2(guidance_card.target[0],guidance_card.target[1]);view._update_transform()
				notice = "Tap Mira and Follow. Time starts paused.", sheet_body)
			button(ColonyText.text("ui.action.look_around"), close_sheet, sheet_body)
		"Build":
			label(ColonyText.text("ui.help.sheet.blueprints_require_real_supplies_and_worker_time"), sheet_body)
			button(ColonyText.text("ui.action.paint_stockpile"), begin_placement, sheet_body)
			button(ColonyText.text("ui.action.plant_turnips"), begin_field, sheet_body)
			if world is ColonyWorld:
				button(ColonyText.text("ui.action.four_bed_lodge_w73_f8"),begin_lodge,sheet_body)
				for kind in world.definitions.buildings:
					var definition: Dictionary = world.definitions.buildings[kind]
					if not definition.buildable: continue
					button(kind.capitalize() + " | " + _cost_text(definition.materials), func() -> void: begin_build(kind), sheet_body)
		"People":
			if world is ColonyWorld: button(ColonyText.text("ui.action.defense_and_shelter"),show_defense,sheet_body)
			if world is ColonyWorld and not ColonyFire.active(world).is_empty(): button(ColonyText.text("ui.action.fires_and_water"),show_fires,sheet_body)
			if world is ColonyWorld: button(ColonyText.text("ui.action.newcomer_offers"),show_newcomers,sheet_body)
			if world is ColonyWorld: button(ColonyText.text("ui.action.injuries_and_care"),show_care,sheet_body)
			for citizen in world.citizens:
				button(citizen.name, func() -> void:
					if world is ColonyWorld: show_person(citizen.id)
					else:
						close_sheet()
						select_citizen(citizen.id), sheet_body)
			if world is ColonyWorld: label(ColonyText.text("ui.help.people.overview"),sheet_body)
		"Work":
			_work_sheet()
		"Valley":
			if world is ColonyWorld: show_valley()
		"Journal":
			if world is ColonyWorld:
				button(ColonyText.text("ui.action.chronicle"),show_chronicle,sheet_body)
				button(ColonyText.text("ui.action.charter"),show_charter,sheet_body)
				button(ColonyText.text("ui.action.pin_a_moment"),show_pin_moment,sheet_body)
				_tutorial_sheet()
		"Menu":
			button(ColonyText.text("ui.action.settings"),show_accessibility,sheet_body)
			button(ColonyText.text("ui.action.performance_report"),show_diagnostics,sheet_body)
			label("Brackenward %s\nCampaigns preserve inventory, work and needs. Time stays paused after recovery." % ProjectSettings.get_setting("application/config/version"), sheet_body)
			if world is ColonyWorld: button("Mode: "+world.care_state.mode,show_mode,sheet_body)
			if world is ColonyWorld: button(ColonyText.text("ui.action.map_and_seed"),show_map_details,sheet_body)
			button(ColonyText.text("ui.action.save_colony"), save_local, sheet_body)
			button(ColonyText.text("ui.action.load_colony"), load_local, sheet_body)
			button(ColonyText.text("ui.action.export_save"), func() -> void: choose_document(true), sheet_body)
			button(ColonyText.text("ui.action.import_save"), func() -> void: choose_document(false), sheet_body)
			button("Text size: %d%%" % int(text_scale * 100), func() -> void:
				text_scale = 1.25 if text_scale == 1.0 else (1.5 if text_scale == 1.25 else 1.0)
				_save_settings()
				_build_theme()
				show_sheet("Menu","ui.sheet.menu"), sheet_body)
			button("Handedness: " + ("Left" if left_handed else "Right"), func() -> void:
				left_handed = not left_handed
				_save_settings()
				show_sheet("Menu","ui.sheet.menu"), sheet_body)
			if world is ColonyWorld:
				button(ColonyText.text("ui.action.manage_saves"),show_campaigns,sheet_body)
				button(ColonyText.text("ui.action.named_snapshots"),show_named_snapshots,sheet_body)
				button(ColonyText.text("ui.action.weather_forecast"),show_weather,sheet_body)
				label("Travel rations are expedition reserves. Home use is " + ("on" if world.use_rations else "off") + ".",sheet_body)
				button("Keep rations for expeditions" if world.use_rations else "Use rations at home",func() -> void: _submit("food_policy", {"enabled":not world.use_rations}),sheet_body)
			button(ColonyText.text("ui.action.introduction"), func() -> void: show_sheet("Welcome","ui.sheet.welcome"), sheet_body)
	_layout()
	get_viewport().gui_release_focus()
	call_deferred("_layout")

func _adapt_sheet_heading() -> void:
	if sheet==null or not is_instance_valid(sheet_heading) or not is_instance_valid(sheet_full_heading): return
	var top: HBoxContainer = sheet_heading.get_parent()
	var available: float = top.size.x-top.get_theme_constant("separation")*2
	for child in top.get_children():
		if child is Button: available-=child.get_combined_minimum_size().x
	var raw_title: String = ColonyText.text(sheet_title_key) if not sheet_title_key.is_empty() else sheet_name
	var title: String = ColonyFonts.display(raw_title)
	var width: float = sheet_heading.get_theme_font("font").get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,sheet_heading.get_theme_font_size("font_size")).x
	var fits: bool = width<=available and ColonyFonts.warning(raw_title).is_empty()
	sheet_heading.text=title if fits else ""
	sheet_full_heading.visible=not fits

func close_sheet() -> void:
	listening_binding=""
	text_entry_error=""
	if is_instance_valid(view): view.inspected_tiles.clear();view.inspected_object=0
	if sheet != null:
		sheet.queue_free()
		sheet = null
	sheet_name = ""
	sheet_route=""
	sheet_title_key=""
	sheet_entry_speed=0
	notice = ColonyText.text("ui.notice.paused")
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
	var started: int = Time.get_ticks_usec()
	var error: String = _write_local_save()
	diagnostics.record("save_explicit",Time.get_ticks_usec()-started)
	return error

func _write_local_save() -> String:
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
		if sheet_route == "Save problem":
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
	diagnostics.reset();diagnostic_preview.clear()
	durable_at=save_clock
	journal_elapsed=0.0
	world = state
	tutorial_suggestions.clear()
	diagnostics.tick=world.tick;diagnostics.speed=0
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
	_apply_device_settings()
	view.world = world
	if is_instance_valid(soundscape): soundscape.bind_world(world,view)
	for actor in view.actors:
		if actor is CitizenSprite: actor.reset_pose()
	view.refresh_terrain()
	view.forecast_mask.clear()
	view.cancel_gesture()
	view.follow_id = 0
	close_inspector()
	cancel_placement()
	submitted_command = 0
	placement_commands.clear()
	confirm_button.disabled = false
	last_saved_tick = world.tick
	if world is ColonyWorld: save_queue.prime(world)

func choose_document(export: bool) -> void:
	if document_pending:
		notice = "A document operation is already open. Finish or cancel it first."
		return
	runner.pause()
	view.cancel_gesture()
	document_kind="save"
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
	var request: int = document_request
	file_dialog.file_selected.connect(func(path:String)->void:_desktop_selected(path,request))
	file_dialog.canceled.connect(func()->void:_cancel_document(request))
	file_dialog.popup_centered(Vector2i(720, 480))

func _cancel_document(request: int) -> void:
	if request!=document_request or not document_pending: return
	document_pending=false
	if is_instance_valid(file_dialog): file_dialog.queue_free();file_dialog=null
	notice="Performance report export canceled." if document_kind=="diagnostics" else "Picker canceled. Saves unchanged."

func _desktop_selected(path: String, request: int = -1) -> void:
	if not document_pending or (request>=0 and request!=document_request): return
	document_pending = false
	if is_instance_valid(file_dialog): file_dialog.queue_free();file_dialog=null
	if exporting:
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			notice = "Could not open selected export destination."
			return
		file.store_buffer(export_bytes)
		file.flush()
		var error: Error = file.get_error()
		file.close()
		var verified: bool = FileAccess.get_file_as_bytes(path)==export_bytes if document_kind=="diagnostics" else not store.decode(FileAccess.get_file_as_bytes(path)).has("error")
		notice = ("Performance report written and verified." if document_kind=="diagnostics" else "Export written and verified.") if error==OK and verified else "Export write/verification failed."
	else:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null or file.get_length() > ColonyCodec.MAX_BYTES:
			notice = "Could not read save, or file exceeds the colony's 64 MiB limit."
			return
		_accept_import(file.get_buffer(file.get_length()))

func _native_result(request: int, result: String, bytes: PackedByteArray) -> void:
	if request != document_request or not document_pending:
		return
	if result not in ["export_selected", "import_selected"]:
		document_pending = false
	match result:
		"export_selected": native_storage.writeSelectedDocument(request, export_bytes)
		"import_selected": native_storage.readSelectedDocument(request, ColonyCodec.MAX_BYTES)
		"read":
			if document_kind=="save": _accept_import(bytes)
			else: notice="Unexpected document response. No campaign imported."
		"written": notice = "Performance report written and verified." if document_kind=="diagnostics" else "Export written and verified."
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
	placement_entry_speed=0;sheet_entry_speed=0
	diagnostics.count("backgrounds");diagnostics.foreground=false;diagnostics.break_frame_clock()
	if is_instance_valid(soundscape): soundscape.suspend()
	runner.pause()
	view.cancel_gesture()
	if not saving_disabled and not recovery_failed:
		save_local()

func resume_from_background() -> void:
	if quitting: return
	backgrounded = false
	diagnostics.foreground=true;diagnostics.break_frame_clock()
	if is_instance_valid(soundscape): soundscape.resume()
	runner.pause()
	view.cancel_gesture()
	notice = "While you were away, nothing advanced."
	if recovery_failed:
		show_recovery_problem()
		return
	if not storage_error.is_empty() and not saving_disabled:
		_storage_failed(storage_error)
		return
	show_sheet("Welcome back","ui.sheet.welcome_back")
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
		quit_application()

func quit_application() -> void:
	if quitting: return
	quitting=true;suspend()
	if is_instance_valid(content): content.process_mode=Node.PROCESS_MODE_DISABLED
	var released: bool = true
	if is_instance_valid(soundscape): released=await soundscape.drain()
	if not released: push_error("Audio shutdown timed out; streaming playbacks remain in use")
	if native_smoke_target>0: print("BRACKENWARD_NATIVE_SMOKE_EXIT frames=%d audio_drained=%s isolated=true" % [native_smoke_target-native_smoke_remaining,str(released)])
	get_tree().quit(0 if released else 1)

func back() -> void:
	if quitting: return
	if is_instance_valid(soundscape): soundscape.cue("ui_cancel")
	view.cancel_gesture()
	if sheet != null:
		close_sheet()
	elif placement.visible:
		cancel_placement()
	elif inspector != null:
		close_inspector()
	else:
		show_sheet("Menu","ui.sheet.menu")

func _unhandled_key_input(event: InputEvent) -> void:
	if quitting: return
	if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if not _shortcut(ControlBindings.action_for(settings.values.bindings,event.get_keycode_with_modifiers())): return
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if quitting: return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if not listening_binding.is_empty():
		if event.keycode in [KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_META]: get_viewport().set_input_as_handled();return
		if event.keycode==KEY_ESCAPE: show_controls()
		else:
			var result: Dictionary = ControlBindings.rebind(settings.values.bindings,listening_binding,event.get_keycode_with_modifiers())
			if result.has("error"): notice=result.error
			else:
				settings.values.bindings=result.bindings;_save_settings();show_controls()
		get_viewport().set_input_as_handled();return
	if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:
		return
	# The configured pause key works even when a Button owns GUI focus.
	# Enter remains available to activate the focused button.
	if ControlBindings.action_for(settings.values.bindings,event.get_keycode_with_modifiers())=="pause":
		_shortcut("pause")
		get_viewport().set_input_as_handled()

func _shortcut(action: String) -> bool:
	match action:
		"back": back()
		"pause": set_speed(runner.previous_speed if runner.speed==0 else 0)
		"speed_1": set_speed(1)
		"speed_2": set_speed(2)
		"speed_4": set_speed(4)
		"build","work","people","valley","journal": show_sheet(action.capitalize(),ColonyText.sheet_key(action.capitalize()))
		"pan_up","pan_down","pan_left","pan_right":
			if sheet!=null: return false
			view.follow_id=0
			view.camera_tile+={"pan_up":Vector2.UP,"pan_down":Vector2.DOWN,"pan_left":Vector2.LEFT,"pan_right":Vector2.RIGHT}[action]*3
			view._update_transform()
		_: return false
	return true

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
		notice=ColonyText.text("ui.placement.paint_notice",{"building":_catalog_name(kind)})
		_layout();return
	begin_placement()
	view.preview_definition = kind
	view.preview_rotation = 0
	view.fit_build_preview()
	rotation_button.visible = true
	notice = ColonyText.text("ui.placement.build_notice",{"building":kind.capitalize()})
	_layout()

func begin_gather(kind: String) -> void:
	begin_placement()
	placement_kind = "gather"
	view.preview_resource = kind
	notice = ColonyText.text("ui.placement.gather_notice")
	_layout()

func _preview_text() -> String:
	if placement_kind=="rally": return ColonyText.text("ui.placement.rally",{"count":defend_citizens.size(),"retreat":ColonyText.text("ui.placement.stand_fast" if defend_stand_fast else "ui.placement.retreat")})
	if placement_kind=="cart_move":
		var error: String = ColonyMaintenance.cart_position_error(world,world.find(world.structures,moving_target),view.preview_start)
		return ColonyText.text("ui.placement.cart",{"status":ColonyText.text("ui.placement.cart_route") if error.is_empty() else error})
	if placement_kind=="move_furniture":
		var error: String = world.placement_error(view.preview_definition,view.preview_start,view.preview_rotation,0,moving_target)
		return ColonyText.text("ui.placement.furniture",{"building":_catalog_name(view.preview_definition),"work":world.definitions.buildings[view.preview_definition].work_milli/1000,"status":ColonyText.text("ui.placement.valid_destination") if error.is_empty() else error})
	if placement_kind=="lodge":
		var key: String = "lodge|%s|%d" % [view.preview_start,world.tick]
		if key!=placement_cache_key:
			placement_cache_key=key;placement_cache={"error":ColonyConstruction.lodge_error(world,view.preview_start)}
		return ColonyText.text("ui.placement.lodge",{"status":ColonyText.text("ui.placement.valid_lodge") if placement_cache.error.is_empty() else placement_cache.error})
	if placement_kind=="build_area":
		var key: String = "%s|%s|%s|%d|%d" % [paint_build_definition,view.preview_start,view.preview_end,world.tick,world.next_command_id]
		if key!=placement_cache_key:
			placement_cache_key=key;placement_cache=_paint_preview()
		view.rejected_build_tiles=placement_cache.rejected
		var cost: Dictionary = {}
		for item in world.definitions.buildings[paint_build_definition].materials: cost[item]=world.definitions.buildings[paint_build_definition].materials[item]*placement_cache.valid.size()
		var tiles: Array = view.preview_tiles()
		var dimensions: Vector2i = (tiles[-1]-tiles[0]).abs()+Vector2i.ONE
		return ColonyText.text("ui.placement.build_area",{"building":_catalog_name(paint_build_definition),"width":dimensions.x,"height":dimensions.y,"valid":placement_cache.valid.size(),"cost":_cost_text(cost),"blocked":ColonyText.plural("ui.placement.blocked_cells",placement_cache.rejected.size()),"reason":"" if placement_cache.rejected.is_empty() else ": "+placement_cache.rejected.values()[0]})
	if placement_kind == "pen": return ColonyText.text("ui.placement.pen")
	if placement_kind == "forest": return ColonyText.text("ui.placement.forest")
	if placement_kind == "gather":
		var count: int = world.gather_targets(view.preview_resource,view.preview_tiles()).size()
		return ColonyText.text("ui.placement.gather",{"item":world.definitions.resources[view.preview_resource].item,"targets":ColonyText.plural("ui.placement.unmarked_trees" if view.preview_resource=="tree" else "ui.placement.unmarked_resources",count)})
	if world is ColonyWorld and not view.preview_definition.is_empty():
		var error: String = world.placement_error(view.preview_definition,view.preview_start,view.preview_rotation,0,moving_target)
		var definition: Dictionary = world.definitions.buildings[view.preview_definition]
		return ColonyText.text("ui.placement.building",{"building":view.preview_definition.capitalize(),"cost":_cost_text(definition.materials),"work":definition.work_milli/1000,"status":ColonyText.text("ui.placement.valid") if error.is_empty() else error})
	var width: int = absi(view.preview_end.x-view.preview_start.x)+1
	var height: int = absi(view.preview_end.y-view.preview_start.y)+1
	return ColonyText.plural("ui.placement.rectangle",width*height,{"width":width,"height":height,"mode":ColonyText.text("ui.placement.pan_mode" if view.gestures.mode=="pan" else ("ui.placement.turnip_mode" if placement_kind=="field" else "ui.placement.stockpile_mode"))})

func _paint_preview() -> Dictionary:
	var result: Dictionary = ColonyConstruction.paint_preview(world,paint_build_definition,view.preview_tiles())
	for tile in result.valid.duplicate():
		var error: String = view.confirmed_build_error(paint_build_definition,[tile])
		if error.is_empty(): continue
		result.valid.erase(tile);result.rejected[tile]=error
	return result

func _update_inspector() -> void:
	if selected <= 0 or not is_instance_valid(inspector_details):
		return
	var citizen: Dictionary = world.find(world.citizens,selected) if world is ColonyWorld else world.citizens[selected-1]
	if world is ColonyWorld:
		if is_instance_valid(inspector_portrait): CitizenArt.update_portrait(inspector_portrait,citizen.appearance)
		var job: Dictionary = world.find(world.jobs, citizen.job)
		inspector_details.text = "%s - %s\nFood %d/1000 | Rest %d/1000\nHealth %d | %s first\n%s" % [citizen.name, citizen.activity, citizen.fullness, citizen.rest, citizen.health, citizen.preferred,
			("Work %d/%d WU" % [job.work / 1000, job.required / 1000]) if not job.is_empty() and job.required > 0 else ("Needs take priority over ordinary work." if not job.is_empty() else "Choose orders in Work or Build.")]
		if citizen.departure_until>world.tick: inspector_details.text+="\n"+departure_description(citizen)
	else:
		inspector_details.text = "%s - looking around\nM0 touch fixture movement." % citizen.name
	inspector_details.text=ColonyFonts.display(inspector_details.text)

func _submit(kind: String, args: Dictionary) -> void:
	if quitting: return
	_sync_placement_world()
	if awaiting_first_colony:
		notice = ColonyText.text("ui.notice.choose_colony_first")
		return
	if submitted_command > 0 and not placement_commands.has(submitted_command) and kind not in ["preference","schedule","priority","stock_filter","food_policy"]:
		notice = ColonyText.text("ui.notice.order_already_pending")
		return
	submitted_command = world.queue_command(kind, args)
	confirm_button.disabled = true
	notice = ColonyText.text("ui.notice.order_pending")

func _sync_placement_world() -> void:
	if placement_world_id==world.get_instance_id(): return
	placement_world_id=world.get_instance_id()
	placement_commands.clear()

func _resource_sheet(resource: Dictionary) -> void:
	show_details(resource.definition.capitalize())
	var definition: Dictionary = world.definitions.resources[resource.definition]
	label(ColonyText.text("ui.resource.remaining",{"count":resource.remaining,"item":definition.item,"work":int(definition.work_milli/1000),"basis":ColonyText.text("ui.resource.work.per_unit" if definition.per_unit else "ui.resource.work.per_harvest")}), sheet_body)
	label(ColonyText.text("ui.help.resource_sheet.a_gatherer_works_beside_the_resource_the"), sheet_body)
	if resource.definition=="tree":
		label(ColonyText.text("ui.help.resource_sheet.tree_passage"),sheet_body)
		if ColonyNature.door_approach(world,Vector2i(resource.x,resource.y)):
			label(ColonyText.text("ui.help.resource_sheet.tree_at_door"),sheet_body)
	if resource.definition == "tree" and resource.remaining == 0:
		var state: Dictionary = ColonyNature.tree(world,resource.id)
		label(ColonyText.text("ui.resource.growing",{"days":"%.1f" % (float(state.age)/7200.0)}) if state.planted else ColonyText.text("ui.resource.stump"),sheet_body)
		button(ColonyText.text("ui.action.clear_sapling" if state.planted else "ui.action.replant_tree"),func()->void:
			_submit("clear_sapling" if state.planted else "replant_tree",{"target":resource.id})
			close_sheet(),sheet_body)

	if resource.remaining > 0:
		button(ColonyText.text("ui.action.gather"), func() -> void:
			_submit("gather", {"target": resource.id})
			close_sheet()
			view.camera_tile = Vector2(resource.x, resource.y), sheet_body)

func _job_sheet(job: Dictionary) -> void:
	show_sheet("Work order","ui.sheet.work_order")
	label(ColonyText.text("ui.work.order_details",{"kind":job.kind.capitalize(),"state":job.state,"work":int(job.work/1000),"required":int(job.required/1000),"reason":job.reason}), sheet_body)
	if job.state=="Queued": label(ColonyText.text("ui.help.job_sheet.waiting_for_work_capacity_the_order_keeps"),sheet_body).name="QueuedOrderExplanation"
	if not job.inputs.is_empty():
		label(ColonyText.text("ui.work.required_materials",{"cost":_cost_text(job.inputs)}), sheet_body)
	if job.category in ColonyWorld.CATEGORIES:
		button(ColonyText.text("ui.label.priority",{"priority":["",ColonyText.text("ui.priority.low"),ColonyText.text("ui.priority.normal"),ColonyText.text("ui.priority.urgent")][job.priority]}),func() -> void: _submit("priority",{"target":job.id,"value":job.priority%3+1}),sheet_body)
		for citizen in world.citizens:
			button(ColonyText.text("ui.work.do_next",{"name":citizen.name}),func() -> void:
				_submit("pin",{"target":job.id,"citizen":citizen.id})
				close_sheet(),sheet_body)
	button(ColonyText.text("ui.action.cancel_order"), func() -> void:
		_submit("cancel", {"target": job.id})
		close_sheet(), sheet_body)

func _work_sheet() -> void:
	if not world is ColonyWorld:
		label(ColonyText.text("ui.help.work_sheet.m0_fixture_real_worker_loop_is_in"), sheet_body)
		return
	label(ColonyText.text("ui.help.work_sheet.choose_a_resource_drag_a_rectangle_then"), sheet_body)
	for kind in ["tree", "berry_bush", "mushroom_patch", "herb_patch", "stone_node", "clay_bank", "iron_seam"]:
		button(ColonyText.text("ui.work.gather",{"item":world.definitions.resources[kind].item}), func() -> void: begin_gather(kind), sheet_body)
	button(ColonyText.text("ui.action.paint_forest_zone"),begin_forest,sheet_body)
	button(ColonyText.text("ui.action.research"),show_research,sheet_body)
	button(ColonyText.text("ui.action.wildlife"),show_wildlife,sheet_body)
	button(ColonyText.text("ui.action.livestock_pens"),show_pens,sheet_body)
	label(ColonyText.text("ui.help.work_sheet.worker_assignments"),sheet_body)
	for citizen in world.citizens:
		button(ColonyText.text("ui.work.worker_gathering",{"name":citizen.name,"preference":[ColonyText.text("ui.choice.off"),ColonyText.text("ui.preference.last"),ColonyText.text("ui.preference.normal"),ColonyText.text("ui.preference.first")][citizen.preferences.Gathering]}),func() -> void: show_work_preferences(citizen.id),sheet_body)
	for zone in world.nature_state.forests:
		button(ColonyText.text("ui.work.forest",{"percent":zone.reserve}),func()->void:show_forest(zone),sheet_body)
	label(ColonyText.text("ui.help.work_sheet.storage"),sheet_body)
	for store in world.stores:
		button(ColonyText.text("ui.work.storage",{"id":store.id}),func() -> void: _storage_sheet(store),sheet_body)
	var orders: Array = world.unfinished_jobs()
	var queued: int = orders.filter(func(j:Dictionary)->bool:return j.state=="Queued").size()
	label(ColonyText.text("ui.work.order_counts",{"total":orders.size(),"queued":queued}),sheet_body).name="WorkOrderCounts"
	var pages: int = maxi(1,(orders.size()+31)/32)
	work_orders_page=clampi(work_orders_page,0,pages-1)
	if pages>1:
		var pager: HBoxContainer = HBoxContainer.new();sheet_body.add_child(pager)
		var previous: Button = button(ColonyText.text("ui.action.previous"),func()->void:_show_work_page(work_orders_page-1),pager,96)
		previous.name="WorkOrdersPrevious";previous.disabled=work_orders_page==0
		label(ColonyText.text("ui.work.page",{"page":work_orders_page+1,"pages":pages}),pager)
		var next: Button = button(ColonyText.text("ui.action.next"),func()->void:_show_work_page(work_orders_page+1),pager,72)
		next.name="WorkOrdersNext";next.disabled=work_orders_page==pages-1
	for job in orders.slice(work_orders_page*32,(work_orders_page+1)*32):
		button(ColonyText.text("ui.work.row",{"kind":job.kind.capitalize(),"state":job.state}), func() -> void: _job_sheet(job), sheet_body).name="WorkOrderRow"+str(job.id)
		if not job.reason.is_empty(): label(job.reason,sheet_body)

func _show_work_page(page: int) -> void:
	work_orders_page=page;show_sheet("Work","ui.sheet.work")
	_scroll_work_orders.call_deferred()

func _scroll_work_orders() -> void:
	if sheet_route!="Work" or not is_instance_valid(sheet_body): return
	var heading: Control = sheet_body.get_node_or_null("WorkOrderCounts")
	if heading!=null: (sheet_body.get_parent() as ScrollContainer).ensure_control_visible(heading)

func _tutorial_sheet() -> void:
	label(ColonyText.text("ui.help.tutorial_sheet.first_steps"), sheet_body)
	var state: Dictionary = _tutorial_state()
	label(ColonyText.text("ui.help.tutorial_sheet.lessons_use_real_work_and_supplies_skipping"),sheet_body)
	button(ColonyText.text("ui.action.resume_first_steps"),func()->void:_tutorial_begin();close_sheet(),sheet_body)
	for lesson in ColonyTutorial.OPENING+state.triggered:
		var status_text: String = "Completed" if state.completed.has(lesson) else ("Skipped" if state.skipped.has(lesson) else "Available")
		button("%s - %s" % [ColonyTutorial.TITLES[lesson],status_text],func()->void:
			ColonyTutorial.replay(state,lesson);_save_settings();close_sheet();_tutorial_show_me(),sheet_body)
	button(ColonyText.text("ui.action.food_forecast"),show_food_forecast,sheet_body)

func _tutorial_state() -> Dictionary:
	return ColonyTutorial.campaign(settings,world.session_id)

func tutorial_tick() -> Dictionary:
	if not world is ColonyWorld or awaiting_first_colony: return {}
	var state: Dictionary = _tutorial_state()
	var previous: String = JSON.stringify(state)
	var added: Array = ColonyTutorial.evaluate(world,state)
	if JSON.stringify(state)!=previous: _save_settings()
	if not added.is_empty(): notice="New lesson: "+ColonyTutorial.TITLES[added[0]]+". Open ? to see the action."
	return ColonyTutorial.card(world,state,tutorial_suggestions)

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
	show_sheet("Lessons","ui.sheet.lessons")
	_tutorial_sheet()

func _tutorial_show_me() -> void:
	runner.pause()
	var card: Dictionary = ColonyTutorial.card(world,_tutorial_state(),tutorial_suggestions)
	if card.is_empty(): show_tutorials();return
	if not card.prerequisite.is_empty():
		show_details(card.title);label(card.prerequisite,sheet_body)
		button(ColonyText.text("ui.action.skip_this_lesson"),func()->void:_tutorial_skip();close_sheet(),sheet_body)
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
	return ColonyText.text("ui.forecast.summary",{"runway":ColonyText.food_runway(FoodForecast.calculate(world)),"demand":ColonyText.plural("ui.forecast.daily_demand",residents*2),"harvest":_tutorial_harvest_text()})

func _tutorial_harvest_text() -> String:
	var soonest: int = 2147483647
	var quantity: int = 0
	var reason: String = ColonyText.text("ui.forecast.harvest.none")
	for field in world.fields:
		if not field.planted: continue
		var definition: Dictionary = world.definitions.crops[field.crop]
		if world.definitions.items[definition.item].fullness<=0 and definition.item not in world.definitions.recipes.cook_meals.alternatives: continue
		if field.ripe_tick>0: return ColonyText.text("ui.forecast.harvest.ready")
		if ColonyAgriculture.season(world.tick) not in definition.seasons or world.roofed(Vector2i(field.x,field.y))!=definition.roof or world.is_flooded(Vector2i(field.x,field.y)):
			reason=ColonyText.text("ui.forecast.harvest.paused",{"reason":field.reason});continue
		var watered: bool = world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="well" and absi(s.x-field.x)+absi(s.y-field.y)<=8)
		var rate: int = field.fertility*(500 if world.weather=="drought" and not watered else 1000)/1000
		if rate<=0: continue
		var remaining: int = maxi(0,((definition.growth-field.growth)*7200-field.growth_rem+rate-1)/rate)
		if remaining<soonest: soonest=remaining;quantity=field.yield_count
		elif remaining==soonest: quantity+=field.yield_count
	if soonest==2147483647: return reason
	var hours: int = (soonest+299)/300
	return ColonyText.text("ui.forecast.harvest.maturity",{"days":ColonyText.plural("ui.forecast.days",hours/24),"hours":ColonyText.plural("ui.forecast.hours",hours%24),"food":ColonyText.plural("ui.forecast.raw_food",quantity)})

func begin_field() -> void:
	begin_placement()
	placement_kind = "field"
	view._update_transform()
	notice = ColonyText.text("ui.notice.field_turnips")

func _field_sheet(field: Dictionary) -> void:
	show_details(field.crop.capitalize())
	var definition: Dictionary = world.definitions.crops[field.crop]
	label(ColonyText.text("ui.field.details",{"reason":field.reason,"growth":field.growth,"required":definition.growth,"yield":field.yield_count,"percent":int(field.fertility/10),"replant":ColonyText.text("ui.field.replant_on" if field.replant else "ui.field.replant_off")}),sheet_body)
	if field.planted:
		if field.growth * 2 >= definition.growth:
			label(ColonyText.plural("ui.field.early_harvest",mini(field.yield_count,maxi(1,definition.yield_count * field.growth / definition.growth))),sheet_body)
			button(ColonyText.text("ui.action.harvest_early"),func() -> void:
				_submit("early_harvest",{"target":field.id})
				close_sheet(),sheet_body)
		else:
			label(ColonyText.text("ui.help.field_sheet.early_harvest_requires_50_growth_clearing_now"),sheet_body)
	label(ColonyText.text("ui.help.field_sheet.clearing_removes_this_field_and_its_unharvested"),sheet_body)
	button(ColonyText.text("ui.action.clear_field"),func() -> void:
		_submit("clear_field",{"target":field.id})
		close_sheet(),sheet_body)

func _storage_sheet(storage: Dictionary) -> void:
	show_sheet("Storage","ui.sheet.storage")
	var count: int = 0
	for stack in world.stacks:
		if stack.location == "store" and stack.owner == storage.id:
			count += stack.count
	label(ColonyText.text("ui.storage.capacity",{"count":count,"capacity":storage.capacity}),sheet_body)
	button(ColonyText.text("ui.label.priority",{"priority":["",ColonyText.text("ui.priority.low"),ColonyText.text("ui.priority.normal"),ColonyText.text("ui.priority.high")][storage.priority]}),func() -> void:
		_submit("stock_filter",{"target":storage.id,"filters":storage.filters,"priority":storage.priority%3+1}),sheet_body)
	for item in world.definitions.items:
		var stored: int = 0
		var reserved: int = 0
		for stack in world.stacks:
			if stack.location == "store" and stack.owner == storage.id and stack.item == item:
				stored += stack.count
				reserved += world._reserved(stack)
		label(ColonyText.text("ui.storage.item_counts",{"item":item.capitalize(),"stored":stored,"reserved":reserved}),sheet_body)
		button(ColonyText.text("ui.storage.item_filter",{"item":item.capitalize(),"status":ColonyText.text("ui.choice.on" if storage.filters.has(item) else "ui.choice.off")}),func() -> void:
			var filters: Array = storage.filters.duplicate()
			if filters.has(item): filters.erase(item)
			else: filters.append(item)
			_submit("stock_filter",{"target":storage.id,"filters":filters,"priority":storage.priority}),sheet_body)

func _storage_failed(error: String) -> void:
	placement_entry_speed=0;sheet_entry_speed=0
	diagnostics.count("storage_alerts")
	storage_error = error
	runner.pause()
	view.cancel_gesture()
	notice = error
	show_sheet("Save problem","ui.sheet.save_problem")
	label(error + "\nCurrent progress remains in memory. No earlier valid save was replaced.",sheet_body)
	button(ColonyText.text("ui.action.retry_save"),save_local,sheet_body)
	button(ColonyText.text("ui.action.export_current_colony"),func() -> void: choose_document(true),sheet_body)
	label(ColonyText.text("ui.help.storage_failed.continue_without_saving_can_lose_progress_when"),sheet_body)
	button(ColonyText.text("ui.action.continue_without_saving"),func() -> void:
		saving_disabled = true
		close_sheet()
		notice = "Saving is disabled. Retry Save in Menu to restore it.",sheet_body)
	button(ColonyText.text("ui.action.manage_saves"),func()->void:show_campaigns(true),sheet_body)

func show_recovery_problem() -> void:
	runner.pause()
	show_sheet("Recovery stopped","ui.sheet.recovery_stopped")
	label(storage_error + "\nOriginal campaign files are retained. Choose another campaign or import a verified snapshot. This preview will not overwrite the failed campaign.",sheet_body)
	button(ColonyText.text("ui.action.campaign_slots"),show_campaigns,sheet_body)
	button(ColonyText.text("ui.action.import_verified_save"),func() -> void: choose_document(false),sheet_body)

func show_campaigns(skip_save: bool = false) -> void:
	if not store is ColonyStore:
		return
	if not skip_save and not recovery_failed and not saving_disabled and not save_local().is_empty():
		return
	show_sheet("Campaigns","ui.sheet.campaigns")
	label(ColonyText.text("ui.help.campaigns.five_independent_campaign_slots_switching_first_saves"),sheet_body)
	for number in range(1,6):
		var exists: bool = ColonyStore.occupied(number,store.root_directory)
		button(ColonyText.text("ui.save.load_campaign" if exists else "ui.save.new_campaign",{"slot":number}),func() -> void: _switch_campaign(number,exists),sheet_body)
		if deletion.has_saves(store,number):
			button(ColonyText.text("ui.action.delete_campaign",{"slot":number}),func()->void:show_delete_saves(number),sheet_body)
	if not deletion.cleanup_paths(store).is_empty():
		button(ColonyText.text("ui.action.retry_deletion_cleanup"),func()->void:
			var error: String=deletion.cleanup(store)
			show_campaigns(true)
			notice=error if not error.is_empty() else ColonyText.text("ui.save.cleanup_done"),sheet_body)

func show_delete_saves(number: int, snapshot: int = 0) -> void:
	if not store is ColonyStore: return
	runner.pause();placement_entry_speed=0;sheet_entry_speed=0
	_finish_background_save(true,false)
	var owner: ColonyStore=store
	var session: String=world.session_id
	var review: Dictionary=deletion.preview(owner,number,snapshot)
	show_sheet("Delete saves","ui.sheet.delete_saves")
	notice=""
	if not review.get("error","").is_empty(): label(review.error,sheet_body);return
	if review.targets.is_empty(): label(ColonyText.text("ui.save.already_removed"),sheet_body);return
	var name: String=""
	if snapshot>0:
		var previous: ColonyStore=ColonyStore.new();previous.root_directory=owner.root_directory;previous.select_slot(number)
		name=previous.named_snapshots()[snapshot-1].name
	label(ColonyText.text("ui.save.delete_campaign_review",{"slot":number}) if snapshot==0 else ColonyText.text("ui.save.delete_snapshot_review",{"slot":snapshot,"name":name,"campaign":number}),sheet_body)
	label(ColonyText.plural("ui.save.files_to_remove",review.files.size(),{"bytes":String.humanize_size(review.bytes)}),sheet_body)
	button(ColonyText.text("ui.action.permanently_delete"),func()->void:_delete_saves(owner,session,review),sheet_body)
	button(ColonyText.text("ui.action.cancel"),func()->void:
		if snapshot==0: show_campaigns(true)
		else: show_named_snapshots(),sheet_body)

func _delete_saves(owner: ColonyStore, session: String, review: Dictionary) -> void:
	if store!=owner or world.session_id!=session or sheet_route!="Delete saves": return
	_finish_background_save(true,false)
	var result: Dictionary=deletion.commit(owner,review)
	if (result.deleted or result.get("unsafe_to_resume",false)) and review.snapshot==0 and review.slot==store.slot:
		_replace_world(ColonyWorld.new(ColonyCatalog.load_data(),Crypto.new().generate_random_bytes(16).hex_encode()))
		store.select_slot(review.slot)
		awaiting_first_colony=true
		_save_settings()
	if not result.deleted:
		if result.get("unsafe_to_resume",false): show_campaigns(true)
		notice=result.error
		return
	if review.snapshot==0: show_campaigns(true)
	else: show_named_snapshots()
	notice=result.error if not result.error.is_empty() else ColonyText.text("ui.save.campaign_deleted",{"slot":review.slot}) if review.snapshot==0 else ColonyText.text("ui.save.snapshot_deleted",{"slot":review.snapshot})

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
	notice = ColonyText.text("ui.save.campaign_ready",{"slot":number})

func show_import_slots() -> void:
	if pending_import_world == null:
		return
	show_sheet("Import campaign","ui.sheet.import_campaign")
	label(ColonyText.text("ui.help.import_slots.the_complete_snapshot_is_verified_select_an"),sheet_body)
	for number in range(1,6):
		var exists: bool = ColonyStore.occupied(number,store.root_directory)
		button(ColonyText.text("ui.save.replace_campaign" if exists else "ui.save.import_into_campaign",{"slot":number}),func() -> void:
			if exists:
				show_sheet("Confirm replacement","ui.sheet.confirm_replacement")
				label(ColonyText.text("ui.save.confirm_import_replacement",{"slot":number}),sheet_body)
				button(ColonyText.text("ui.save.replace_campaign",{"slot":number}),func() -> void: _adopt_import(number,true),sheet_body)
				button(ColonyText.text("ui.action.choose_another_slot"),show_import_slots,sheet_body)
			else:
				_adopt_import(number,false),sheet_body)
	button(ColonyText.text("ui.action.cancel_import"),func() -> void:
		pending_import_world = null
		close_sheet()
		notice = ColonyText.text("ui.save.import_cancelled"),sheet_body)

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
	notice = ColonyText.text("ui.save.imported_campaign",{"slot":number})

func show_named_snapshots() -> void:
	if not store is ColonyStore or recovery_failed:
		return
	show_sheet("Named snapshots","ui.sheet.named_snapshots")
	label(ColonyText.text("ui.help.named_snapshots.ten_named_snapshots_per_campaign_autosaves_use"),sheet_body)
	for row in store.named_snapshots():
		label(ColonyText.text("ui.save.snapshot_row",{"slot":row.index,"name":row.name}),sheet_body)
		if row.valid:
			button(ColonyText.text("ui.save.load_snapshot",{"slot":row.index}),func() -> void: _load_named(row.index),sheet_body)
		button(ColonyText.text("ui.save.replace_snapshot" if row.exists else "ui.save.save_snapshot",{"slot":row.index}),func() -> void: _name_snapshot(row.index,row.exists,row.name),sheet_body)
		if row.exists: button(ColonyText.text("ui.action.delete_snapshot",{"slot":row.index}),func()->void:show_delete_saves(store.slot,row.index),sheet_body)

func _name_snapshot(index: int, exists: bool, previous_name: String) -> void:
	show_sheet("Name snapshot","ui.sheet.name_snapshot")
	label(ColonyText.text("ui.save.replacing_snapshot",{"name":previous_name}) if exists else ColonyText.text("ui.save.name_snapshot"),sheet_body)
	label(ColonyText.text("ui.help.name_snapshot.use_1_64_printable_basic_latin_characters"),sheet_body)
	var entry: LineEdit = LineEdit.new()
	entry.placeholder_text = ColonyText.text("ui.save.snapshot_name_placeholder")
	entry.max_length = 64
	entry.custom_minimum_size = Vector2(48,48)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet_body.add_child(entry)
	entry.text_changed.connect(_clear_text_entry_error)
	button(ColonyText.text("ui.action.continue" if exists else "ui.action.save_snapshot"),func() -> void:
		var snapshot_name: String = entry.text.strip_edges()
		if not ColonyChronicle._printable(snapshot_name,64):
			_text_entry_error(ColonyText.text("ui.save.invalid_snapshot_name"))
			return
		if exists:
			show_sheet("Confirm snapshot replacement","ui.sheet.confirm_snapshot_replacement")
			label(ColonyText.text("ui.save.confirm_snapshot_replacement",{"previous":previous_name,"name":snapshot_name,"slot":index}),sheet_body)
			button(ColonyText.text("ui.action.replace_snapshot"),func() -> void: _save_named(index,snapshot_name,true),sheet_body)
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
	notice = ColonyText.text("ui.save.named_saved")

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
	notice = ColonyText.text("ui.save.named_restored")

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

func _apply_device_settings() -> void:
	runner.auto_pauses=settings.values.auto_pauses.duplicate()
	runner.frame_clock=func()->int:return Time.get_ticks_usec()
	runner.tick_observer=func(elapsed:int,tick:int,speed:int)->void:diagnostics.record("simulation_tick",elapsed,tick,speed)
	if runner.quiet_sleep_enabled!=settings.values.quiet_sleep_speed:
		runner.sleep_boost_suppressed=false;runner.sleep_fast_forward=false;runner.sleep_speed_tier=0
	runner.quiet_sleep_enabled=settings.values.quiet_sleep_speed
	Engine.max_fps=60 if settings.values.quality=="Smooth" else 30
	if is_instance_valid(view):
		view.reduced_motion=settings.values.reduced_motion
		view.high_contrast=settings.values.high_contrast
		view.quality=settings.values.quality
	if is_instance_valid(soundscape): soundscape.apply_settings(settings.values.audio,settings.values.haptics)

func _performance_report() -> Dictionary:
	var memory: int = OS.get_static_memory_usage()
	var metadata: Dictionary = {"build":str(ProjectSettings.get_setting("application/config/version")),"engine":Engine.get_version_info().string,"platform":OS.get_name(),"os_version":OS.get_version().left(128),"device_model":OS.get_model_name().left(128),"gpu":RenderingServer.get_video_adapter_name().left(128),"renderer":RenderingServer.get_current_rendering_method(),"quality":settings.values.quality,"fps_cap":Engine.max_fps,"engine_static_memory_bytes":memory if memory>0 else null,"viewport":[get_viewport_rect().size.x,get_viewport_rect().size.y]}
	metadata.merge({"selected_speed":runner.speed,"playback_speed":runner.playback_speed(),"quiet_sleep_accelerated":runner.sleep_fast_forward})
	if OS.get_name()=="Android":metadata.merge(_android_pss_metadata(native_storage))
	if world is ColonyWorld:
		var orders: Array = world.unfinished_jobs()
		metadata["executable_jobs"]=orders.filter(func(j:Dictionary)->bool:return ColonyWorkBudget.executable(j,world.tick)).size()
		metadata["queued_orders"]=orders.filter(func(j:Dictionary)->bool:return j.state=="Queued").size()
		metadata.merge({"content":world.CONTENT_VERSION,"schema":world.SCHEMA_REVISION,"site":world.site_id,"seed":str(world.seed),"tick":str(world.tick),"resident_records":world.citizens.size(),"structure_records":world.structures.size(),"nonempty_stacks":world.nonempty_stacks().size(),"unfinished_jobs":world.unfinished_jobs().size(),"pooled_extra_actors":view.extra_actors.size(),"visible_extra_actors":view.extra_actors.values().filter(func(actor:Node)->bool:return actor.visible).size(),"writer_busy":save_queue.busy(),"snapshot_preparing":save_queue.preparing(),"storage_error_present":not storage_error.is_empty(),"saving_disabled":saving_disabled})
	return diagnostics.report(metadata)

## Only an explicit report reads OS process memory; never poll it while playing.
func _android_pss_metadata(bridge: Object) -> Dictionary:
	var result: Dictionary={"android_process_pss_bytes":null,"android_pss_query_us":null,"android_pss_source":"android.os.Debug.MemoryInfo.totalPss","android_pss_scope":"One process PSS sample while preparing this report; no continuous memory/thermal/battery measurement"}
	# JNI singletons dispatch plugin calls dynamically; has_method is not supported.
	# The non-null bridge is our plugin packaged with this same APK.
	if bridge==null:return result
	var started: int=Time.get_ticks_usec();var kib: Variant=bridge.call("getProcessPssKiB")
	result.android_pss_query_us=Time.get_ticks_usec()-started
	if kib is int and kib>0 and kib<=2147483647:result.android_process_pss_bytes=kib*1024
	return result

func show_diagnostics(refresh: bool = true) -> void:
	show_sheet("Performance report","ui.sheet.performance_report")
	if refresh or diagnostic_preview.is_empty(): diagnostic_preview=_performance_report()
	label(ColonyText.text("ui.help.diagnostics.device_seed_and_timing_measurements_review_before"),sheet_body)
	button(ColonyText.text("ui.action.view_included_report"),func()->void:
		show_sheet("Included report","ui.sheet.included_report");label(JSON.stringify(diagnostic_preview,"  ",true),sheet_body)
		button(ColonyText.text("ui.action.back_to_report"),func()->void:show_diagnostics(false),sheet_body),sheet_body).name="PreviewDiagnostics"
	button(ColonyText.text("ui.action.export_this_report"),choose_diagnostics,sheet_body).name="ExportDiagnostics"
	button(ColonyText.text("ui.action.copy_this_report"),func()->void:
		var bytes: PackedByteArray = _diagnostic_bytes()
		if bytes.is_empty(): return
		DisplayServer.clipboard_set(bytes.get_string_from_utf8());notice=ColonyText.text("ui.notice.performance_copied"),sheet_body).name="CopyDiagnostics"
	button(ColonyText.text("ui.action.reset_measurements"),func()->void:diagnostics.reset();show_diagnostics(),sheet_body).name="ResetDiagnostics"
	label(ColonyText.text("ui.performance.device",{"build":diagnostic_preview.metadata.build,"platform":diagnostic_preview.metadata.platform,"model":diagnostic_preview.metadata.device_model}),sheet_body)
	if diagnostic_preview.metadata.get("android_process_pss_bytes")!=null:
		label(ColonyText.text("ui.performance.android_pss",{"mib":"%.1f" % (float(diagnostic_preview.metadata.android_process_pss_bytes)/1048576.0)}),sheet_body)
	label(ColonyText.text("ui.help.diagnostics.includes_device_os_gpu_map_seed_tick"),sheet_body)
	if diagnostic_preview.timings.is_empty(): label(ColonyText.text("ui.help.diagnostics.no_samples_yet_close_this_panel_play"),sheet_body)
	for entry in diagnostic_preview.timings:
		label(ColonyText.performance_timing(entry),sheet_body)
	label(ColonyText.text("ui.help.diagnostics.nested_callback_times_overlap_do_not_add"),sheet_body)

func _diagnostic_bytes() -> PackedByteArray:
	var bytes: PackedByteArray = JSON.stringify(diagnostic_preview,"\t",true).to_utf8_buffer()
	if diagnostic_preview.get("format")!="brackenward-performance" or bytes.size()>FrameDiagnostics.MAX_EXPORT_BYTES:
		notice=ColonyText.text("ui.notice.performance_unavailable");return PackedByteArray()
	return bytes

func choose_diagnostics() -> void:
	if document_pending: notice="A document operation is already open. Finish or cancel it first.";return
	var bytes: PackedByteArray = _diagnostic_bytes()
	if bytes.is_empty(): return
	runner.pause();view.cancel_gesture();exporting=true;document_kind="diagnostics";export_bytes=bytes;document_request+=1;document_pending=true
	if native_storage!=null:
		native_storage.chooseExportDestination(document_request,"brackenward-performance.json");return
	file_dialog=FileDialog.new();file_dialog.access=FileDialog.ACCESS_FILESYSTEM;file_dialog.use_native_dialog=true
	file_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;file_dialog.filters=PackedStringArray(["*.json ; Performance report"]);file_dialog.current_file="brackenward-performance.json"
	add_child(file_dialog)
	var request: int = document_request
	file_dialog.file_selected.connect(func(path:String)->void:_desktop_selected(path,request))
	file_dialog.canceled.connect(func()->void:_cancel_document(request))
	file_dialog.popup_centered(Vector2i(720,480))

func show_accessibility() -> void:
	show_sheet("Settings","ui.sheet.settings")
	button(ColonyText.text("ui.setting.text_size",{"percent":int(text_scale*100)}),func()->void:
		text_scale=1.25 if text_scale==1.0 else (1.5 if text_scale==1.25 else 1.0)
		_save_settings();_build_theme();show_accessibility(),sheet_body)
	button(ColonyText.text("ui.setting.hand",{"hand":ColonyText.text("ui.choice.left" if left_handed else "ui.choice.right")}),func()->void:left_handed=not left_handed;_save_settings();show_accessibility(),sheet_body)
	for key in ["reduced_motion","high_contrast","inspector_pause"]:
		var title: String = ColonyText.text({"reduced_motion":"ui.setting.reduced_motion","high_contrast":"ui.setting.high_contrast","inspector_pause":"ui.setting.inspector_pause"}[key])
		var row: HBoxContainer = HBoxContainer.new();sheet_body.add_child(row)
		label(title,row)
		var toggle: Button = button(ColonyText.text("ui.choice.on" if settings.values[key] else "ui.choice.off"),func()->void:
			settings.values[key]=not settings.values[key];_apply_device_settings();_save_settings();show_accessibility(),row,64)
		toggle.size_flags_horizontal=Control.SIZE_SHRINK_END;toggle.name="Setting_"+key
	button(ColonyText.text("ui.action.quiet_sleep_on" if settings.values.quiet_sleep_speed else "ui.action.quiet_sleep_off"),func()->void:
		settings.values.quiet_sleep_speed=not settings.values.quiet_sleep_speed;_apply_device_settings();_save_settings();show_accessibility(),sheet_body).name="Setting_quiet_sleep_speed"
	label(ColonyText.text("ui.help.quiet_sleep_setting"),sheet_body)
	var graphics: HBoxContainer = HBoxContainer.new();sheet_body.add_child(graphics);label(ColonyText.text("ui.help.accessibility.graphics"),graphics)
	var quality: CycleChoiceButton = CycleChoiceButton.new()
	for choice in ["Battery","Balanced","Smooth"]: quality.add_item(ColonyText.text({"Battery":"ui.setting.graphics.battery","Balanced":"ui.setting.graphics.balanced","Smooth":"ui.setting.graphics.smooth"}[choice]))
	quality.selected=["Battery","Balanced","Smooth"].find(settings.values.quality);quality.custom_minimum_size=Vector2(120,48);graphics.add_child(quality)
	quality.item_selected.connect(func(index:int)->void:settings.values.quality=["Battery","Balanced","Smooth"][index];_apply_device_settings();_save_settings())
	label(ColonyText.text("ui.help.accessibility.battery_balanced_30_fps_smooth_60_fps"),sheet_body)
	button(ColonyText.text("ui.action.automatic_pauses"),show_auto_pauses,sheet_body)
	button(ColonyText.text("ui.action.sound"),show_audio_settings,sheet_body)
	button(ColonyText.text("ui.action.keyboard_controls"),show_controls,sheet_body)

func show_audio_settings() -> void:
	show_sheet("Sound","ui.sheet.sound")
	label(ColonyText.text("ui.help.audio_settings.warnings_stay_visible_when_sound_is_muted"),sheet_body)
	for channel in settings.values.audio:
		var name: String = ColonyText.text({"master":"ui.setting.audio.master","music":"ui.setting.audio.music","effects":"ui.setting.audio.effects","ui":"ui.setting.audio.interface"}[channel])
		var title: Label = label(ColonyText.text("ui.setting.audio.volume",{"channel":name,"percent":roundi(settings.values.audio[channel]*100)}),sheet_body)
		var slider: TouchVolumeSlider = TouchVolumeSlider.new();slider.name="Volume_"+channel
		slider.min_value=0;slider.max_value=100;slider.step=1;slider.value=settings.values.audio[channel]*100
		slider.custom_minimum_size=Vector2(48,48);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sheet_body.add_child(slider)
		slider.value_changed.connect(func(value:float)->void:
			settings.values.audio[channel]=value/100.0;title.text=ColonyText.text("ui.setting.audio.volume",{"channel":name,"percent":roundi(value)})
			if is_instance_valid(soundscape): soundscape.apply_settings(settings.values.audio,settings.values.haptics))
		slider.drag_ended.connect(func(changed:bool)->void:
			if changed: _save_settings())
		slider.focus_exited.connect(_save_settings)
	if OS.has_feature("android"):
		button(ColonyText.text("ui.setting.vibration",{"status":ColonyText.text("ui.choice.on" if settings.values.haptics else "ui.choice.off")}),func()->void:settings.values.haptics=not settings.values.haptics;_apply_device_settings();_save_settings();show_audio_settings(),sheet_body).name="Haptics"
	else: label(ColonyText.text("ui.help.audio_settings.vibration_is_available_on_android"),sheet_body)
	button(ColonyText.text("ui.action.back_to_settings"),show_accessibility,sheet_body)

func show_auto_pauses() -> void:
	show_sheet("Auto pauses","ui.sheet.auto_pauses")
	label(ColonyText.text("ui.help.auto_pauses.each_event_pauses_once_turning_a_pause"),sheet_body)
	for key in settings.values.auto_pauses:
		var title: String = ColonyText.text({"downed":"ui.setting.pause.downed","hostile":"ui.setting.pause.hostile","fire":"ui.setting.pause.fire","expedition":"ui.setting.pause.expedition","departure":"ui.setting.pause.departure","low_food":"ui.setting.pause.low_food"}[key])
		var row: HBoxContainer = HBoxContainer.new();sheet_body.add_child(row);label(title,row)
		var toggle: Button = button(ColonyText.text("ui.choice.on" if settings.values.auto_pauses[key] else "ui.choice.off"),func()->void:
			settings.values.auto_pauses[key]=not settings.values.auto_pauses[key];_apply_device_settings();_save_settings();show_auto_pauses(),row,64)
		toggle.size_flags_horizontal=Control.SIZE_SHRINK_END;toggle.name="AutoPause_"+key
	button(ColonyText.text("ui.action.back_to_settings"),show_accessibility,sheet_body)

func show_controls() -> void:
	show_sheet("Keys","ui.sheet.keys")
	label(ColonyText.text("ui.help.controls.choose_an_action_then_press_a_key"),sheet_body)
	for action in ControlBindings.DEFAULTS:
		var row: HBoxContainer = HBoxContainer.new();sheet_body.add_child(row)
		label(ControlBindings.LABELS[action],row)
		var assign: Button = button(ControlBindings.describe(settings.values.bindings[action]),func()->void:show_key_capture(action),row,96)
		assign.size_flags_horizontal=Control.SIZE_SHRINK_END;assign.name="Bind_"+action
	button(ColonyText.text("ui.action.restore_default_keys"),func()->void:settings.values.bindings=ControlBindings.DEFAULTS.duplicate(true);_save_settings();show_controls(),sheet_body).name="RestoreKeys"
	button(ColonyText.text("ui.action.back_to_settings"),show_accessibility,sheet_body)

func show_key_capture(action: String) -> void:
	show_sheet("Choose key","ui.sheet.choose_key")
	label(ControlBindings.LABELS[action]+"\nCurrent: "+ControlBindings.describe(settings.values.bindings[action])+"\nPress a key or shortcut. Escape cancels this choice.",sheet_body)
	button(ColonyText.text("ui.action.cancel"),show_controls,sheet_body)
	listening_binding=action

func show_weather() -> void:
	_tutorial_action("weather")
	show_sheet("Weather forecast","ui.sheet.weather_forecast")
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
			button(ColonyText.text("ui.action.view_flood_area"),func() -> void:
				view.forecast_mask.assign(entry.mask)
				view.camera_tile = Vector2(38,64)
				view.tile_size = 16
				close_sheet()
				notice = "Striped low ground floods from 06:00 to 18:00 on the forecast date. High ground is safe.",sheet_body)
	if not view.forecast_mask.is_empty():
		button(ColonyText.text("ui.action.hide_flood_preview"),func() -> void:
			view.forecast_mask.clear()
			close_sheet(),sheet_body)

func show_work_preferences(id: int) -> void:
	_tutorial_action("work_preferences",{"citizen":id})
	var citizen: Dictionary = world.find(world.citizens,id)
	show_details(citizen.name+" - Work")
	label(citizen.activity+"\nCategories set to Off retain their queued jobs for other eligible workers. Hunger, sleep and taking a break come first.",sheet_body)
	button(citizen.shift,func() -> void:
		_submit("schedule",{"citizen":id,"shift":"Night shift" if citizen.shift == "Normal" else "Normal"}),sheet_body)
	for category in ColonyWorld.CATEGORIES:
		var entry: Button = button(category+": "+["Off","Last","Normal","First"][_queued_preference(id,category)],Callable(),sheet_body)
		entry.pressed.connect(func() -> void:
			var value: int = (_queued_preference(id,category)+1)%4
			_submit("preference",{"citizen":id,"category":category,"value":value})
			entry.text = category+": "+["Off","Last","Normal","First"][value]+" (pending)")
	button(ColonyText.text("ui.action.all_work_orders"),func() -> void:show_sheet("Work","ui.sheet.work"),sheet_body)

func _queued_preference(id: int,category: String) -> int:
	var value: int = world.find(world.citizens,id).preferences[category]
	for command in world.pending_commands:
		if command.kind == "preference" and command.args.citizen == id and command.args.category == category: value = command.args.value
	return value

func show_beds(id: int) -> void:
	var person: Dictionary = world.find(world.citizens,id)
	if person.is_empty(): return
	show_details("Bed: "+person.name)
	label(ColonyBeds.description(world,person),sheet_body)
	label(ColonyText.text("ui.help.beds.choose_a_free_bed_or_bedroll_assignment"),sheet_body)
	if person.bed>0: button(ColonyText.text("ui.action.unassign_current_bed"),func()->void:show_bed_choice(id,0),sheet_body)
	for bed in world.structures:
		if bed.health<=0 or bed.definition not in ["bed","bedroll"]: continue
		var owner: String = "Assigned to "+ColonyChronicle.display_name(world,bed.user) if bed.user>0 else "Free"
		label("%s at %d,%d | %s | %s" % [ColonyChronicle.display_name(world,bed.id),bed.x,bed.y,owner,"Roofed" if world.roofed(Vector2i(bed.x,bed.y)) else "Outdoors"],sheet_body)
		if bed.user==0: button("Choose %d,%d" % [bed.x,bed.y],func()->void:show_bed_choice(id,bed.id),sheet_body)
	button("Back to "+person.name,func()->void:show_person(id),sheet_body)

func show_bed_choice(id: int, target: int) -> void:
	var person: Dictionary = world.find(world.citizens,id)
	if person.is_empty(): return
	show_details(person.name+" bed")
	var error: String = ColonyBeds.quote(world,id,target)
	if not error.is_empty(): label(error,sheet_body)
	else:
		var bed: Dictionary = world.find(world.structures,target)
		label(ColonyText.text("ui.help.beds.ground_rate",{"rate":ColonyRest.GROUND}) if target==0 else "%s at %d,%d" % [ColonyChronicle.display_name(world,target),bed.x,bed.y],sheet_body)
		button("Unassign" if target==0 else "Assign this bed",func()->void:_submit("assign_bed",{"citizen":id,"target":target});close_sheet(),sheet_body)
		label(person.name+" will sleep on safe ground without an assigned bed." if target==0 else person.name+" walks here when tired. Assignment does not move them or add rest.",sheet_body)
	button(ColonyText.text("ui.action.back_to_beds"),func()->void:show_beds(id),sheet_body)

func show_appearance(id: int, draft: Dictionary = {}) -> void:
	var person: Dictionary = world.find(world.citizens,id)
	if person.is_empty() or person.death_recorded or person.departed: return
	var choices: Dictionary = person.appearance.duplicate() if draft.is_empty() else draft.duplicate()
	show_sheet("Style","ui.sheet.style")
	sheet_feedback.visible=false
	var preview_row: HBoxContainer = HBoxContainer.new();sheet_body.add_child(preview_row)
	preview_row.add_child(CitizenArt.portrait(choices,64))
	label(person.name+"\nAll choices are cosmetic.",preview_row)
	for key in ColonyAppearance.OPTIONS:
		var row: HBoxContainer = HBoxContainer.new();sheet_body.add_child(row)
		var value: Label = label(CitizenArt.LABELS[key]+": "+CitizenArt.label_for(key,choices[key]),row)
		value.size_flags_horizontal=Control.SIZE_EXPAND_FILL;value.custom_minimum_size.x=80
		for step in [-1,1]:
			var change: Button = button("<" if step<0 else ">",func()->void:
				var next: Dictionary = choices.duplicate()
				next[key]=posmod(next[key]+step,ColonyAppearance.OPTIONS[key])
				show_appearance(id,next),row)
			change.name="Appearance_"+key+("_Previous" if step<0 else "_Next")
			change.size_flags_horizontal=Control.SIZE_SHRINK_END
			change.tooltip_text=("Previous " if step<0 else "Next ")+CitizenArt.LABELS[key]
	button(ColonyText.text("ui.action.save_appearance"),func()->void:_submit("citizen_appearance",{"target":id,"appearance":choices});close_sheet(),sheet_body).name="SaveAppearance"
	button(ColonyText.text("ui.action.cancel"),func()->void:show_person(id),sheet_body).name="CancelAppearance"

func departure_description(person: Dictionary) -> String:
	return "Departure ultimatum: %.1f game hours remaining. Reach morale 300 before the deadline. Improve bed, food, warmth or workload; inspect the active morale causes." % [maxi(0,person.departure_until-world.tick)/300.0]

func food_access_description(person: Dictionary) -> String:
	if person.death_recorded or person.departed or person.downed or person.away or person.fullness>350: return ""
	var current: Dictionary=world.find(world.jobs,person.job)
	if current.get("kind")=="eat" or not world._food(person,current).is_empty(): return ""
	if FoodForecast.calculate(world).portions<=0: return ""
	return ColonyText.text("ui.help.person.food_access",{"name":person.name})

func show_person(id: int) -> void:
	var citizen: Dictionary = world.find(world.citizens,id)
	show_details(citizen.name)
	sheet_body.add_child(CitizenArt.portrait(citizen.appearance))
	if not citizen.death_recorded and not citizen.departed: button(ColonyText.text("ui.action.appearance"),func()->void:show_appearance(id),sheet_body)
	button(ColonyText.text("ui.action.rename"),func()->void:show_rename(id),sheet_body)
	button(ColonyText.text("ui.action.remembered_moments"),func()->void:show_person_history(id),sheet_body)
	label("%s\nFood %d/1000 | Rest %d/1000 | Health %d\nMorale %d/1000\n%s | %s\n%s work, %s food" % [citizen.activity,citizen.fullness,citizen.rest,citizen.health,citizen.morale,citizen.traits[0],citizen.traits[1],citizen.preferred,citizen.food_tag],sheet_body)
	label(ColonyBeds.description(world,citizen),sheet_body)
	var food_access: String=food_access_description(citizen)
	if not food_access.is_empty(): label(food_access,sheet_body)
	label(ColonyText.text("ui.help.person.rest_policy",{"tired":ColonyRest.TIRED,"preferred":ColonyRest.PREFERRED_TIRED,"rested":ColonyRest.RESTED,"bed":ColonyRest.BED,"bedroll":ColonyRest.BEDROLL,"ground":ColonyRest.GROUND}),sheet_body)
	if not citizen.death_recorded and not citizen.departed and not citizen.downed and not citizen.away and citizen.fullness<=350 and citizen.rest<=300:
		label(ColonyText.text("ui.help.person.food_and_rest_priority"),sheet_body)
	if citizen.departure_until>world.tick: label(departure_description(citizen),sheet_body)
	for trait_name in citizen.traits:
		var row: HBoxContainer = HBoxContainer.new();sheet_body.add_child(row)
		var icon: TextureRect = TextureRect.new();icon.texture=load("res://assets/exported/ui/traits/%s.svg" % trait_name.to_lower());icon.custom_minimum_size=Vector2(48,48);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(icon)
		label(trait_name,row)
	if not citizen.death_recorded and not citizen.departed: button(ColonyText.text("ui.action.assign_bed"),func()->void:show_beds(id),sheet_body)
	if citizen.health < 100: button(ColonyText.text("ui.action.care_and_recovery"),show_care,sheet_body)
	label(ColonyText.text("ui.help.person.active_morale_causes"),sheet_body)
	for term in citizen.mood_terms: label("%s: %+d" % [term,citizen.mood_terms[term]],sheet_body)
	if not citizen.away and not citizen.downed and not citizen.death_recorded and not citizen.departed: button(ColonyText.text("ui.action.defend"),func()->void:show_squad([id]),sheet_body)
	button(ColonyText.text("ui.action.equipment"),func()->void:show_equipment(id),sheet_body)
	button(ColonyText.text("ui.action.work_preferences"),func() -> void:show_work_preferences(id),sheet_body)
	button(ColonyText.text("ui.action.view_on_map"),func() -> void:
		close_sheet()
		select_citizen(id)
		view.camera_tile = Vector2(citizen.x,citizen.y),sheet_body)
	label(ColonyText.text("ui.help.person.relationships"),sheet_body)
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
			label(ColonyText.text("ui.help.person.optional_accepting_gives_four_days_decline_without"),sheet_body)
			button(ColonyText.text("ui.action.accept_four_days"),func() -> void:
				_submit("request_accept",{"target":request.id})
				close_sheet(),sheet_body)
			button(ColonyText.text("ui.action.decline_without_penalty"),func() -> void:
				_submit("request_decline",{"target":request.id})
				close_sheet(),sheet_body)
		else:
			label("Deadline: %s %d at %02d:00 | about %.1f days left" % [["Spring","Summer","Autumn","Winter"][(request.deadline/57600)%4],(request.deadline/7200)%8+1,(request.deadline%7200)/300,maxf(0,float(request.deadline-world.tick)/7200.0)],sheet_body)

func show_research() -> void:
	_tutorial_action("research")
	show_sheet("Research","ui.sheet.research")
	label(ColonyText.text("ui.help.research.one_active_project_up_to_two_desks"),sheet_body)
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
		button(ColonyText.text("ui.action.rebuild"),func()->void:_submit("rebuild",{"target":station.id});close_sheet(),sheet_body)
		return
	show_details(ColonyChronicle.display_name(world,station.id))
	button(ColonyText.text("ui.action.rename"),func()->void:show_rename(station.id),sheet_body)
	var definition: Dictionary = world.definitions.buildings[station.definition]
	label("Health %d/%d | %s\n%s" % [station.health,definition.health,"Flammable" if definition.flammable else "Does not spread fire",("Store capacity %d" % definition.storage_capacity) if definition.storage_capacity > 0 else "Work needs inputs and an eligible resident"],sheet_body)
	if station.definition == "supply_cart":
		button(ColonyText.text("ui.action.charter"),show_charter,sheet_body)
		button(ColonyText.text("ui.action.communal_supper"),show_supper,sheet_body)
		button(ColonyText.text("ui.action.move_supply_cart"),func()->void:begin_cart_move(station),sheet_body)
		button(ColonyText.text("ui.action.neighbors_and_trade"),show_valley,sheet_body)
	if station.definition != "supply_cart":
		button(ColonyText.text("ui.action.repair_or_demolish"),func()->void:show_maintenance(station),sheet_body)
	if station.definition in ["bed","bedroll"]:
		label("Assigned to "+ColonyChronicle.display_name(world,station.user) if station.user>0 else "Unassigned sleeping place",sheet_body)
		label(ColonyText.text("ui.help.beds.recovery_rate",{"rate":ColonyRest.recovery_rate(station.definition)}),sheet_body)
		if station.user>0: button(ColonyText.text("ui.action.unassign_bed"),func()->void:show_bed_choice(station.user,0),sheet_body)
		else:
			for person in world.citizens:
				if person.death_recorded or person.departed: continue
				button("Assign "+person.name,func()->void:show_bed_choice(person.id,station.id),sheet_body)
		return
	if station.definition in ColonyFire.INDUSTRIAL:
		var hazards: Array = ColonyFire.unsafe(world,station)
		label("Unsafe operating perimeter: suspend the station or move wood/fiber/cloth and flammable structures at least two tiles away, including diagonals." if not hazards.is_empty() else "Perimeter safe or station idle. An operating kiln/smelter near flammable objects can receive a twelve-hour overheating warning; suspending or clearing the fixed target prevents ignition.",sheet_body)
	if ColonyFire.burning(world,"structure",station.id): button(ColonyText.text("ui.action.fire_and_water_tasks"),show_fires,sheet_body)
	if station.definition == "hearth":
		label(ColonyText.text("ui.help.station.without_production_orders_cooking_keeps_four_meals"),sheet_body)
	if station.definition == "fishing_pier":
		var fish: Dictionary = world.nature_state.fishing
		label("Fishing: 12 WU for two fish. Pier %d/8, entire river %d/16 caught this day. Limits recover at 06:00; output must be hauled and cooked." % [fish.piers.get(station.id,0),fish.river],sheet_body)
	if station.definition == "research_desk":
		button(ColonyText.text("ui.action.research_projects"),show_research,sheet_body)
	for recipe in world.definitions.recipes.values():
		if recipe.station != station.definition: continue
		label("%s\n%s -> %s | %d WU" % [recipe.id.replace("_"," ").capitalize(),_cost_text(recipe.materials)+(" + %d allowed food units" % recipe.food_count if recipe.food_count > 0 else ""),_cost_text(recipe.outputs),recipe.work_milli/1000],sheet_body)
		if recipe.unlock != "initial" and not world.researched.has(recipe.unlock):
			label("Requires "+recipe.unlock.capitalize()+" research.",sheet_body)
			button(ColonyText.text("ui.action.show_research"),show_research,sheet_body)
		else:
			button(ColonyText.text("ui.action.make_one_batch"),func() -> void:
				_submit("recipe_order",{"target":station.id,"definition":recipe.id,"mode":"Repeat","value":1,"priority":2,"filters":recipe.alternatives.duplicate()})
				close_sheet(),sheet_body)
			button(ColonyText.text("ui.action.set_production_policy"),func() -> void: show_recipe_policy(station,recipe),sheet_body)
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
		button(ColonyText.text("ui.action.storage_filters_and_priority"),func() -> void: _storage_sheet(world.find(world.stores,station.id)),sheet_body)

func _catalog_name(id: String) -> String:
	var key: String = id.get_slice(":",1) if id.contains(":") else id
	if catalog_strings.is_empty(): catalog_strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalogs/en_colony_v2.json"))
	return catalog_strings.get(key+".name",key.replace("_"," ").capitalize())

func show_recipe_policy(station: Dictionary, recipe: Dictionary) -> void:
	show_sheet("Production policy","ui.sheet.production_policy")
	label(_catalog_name(recipe.id)+" at "+_catalog_name(station.definition),sheet_body)
	label(ColonyText.text("ui.help.recipe_policy.repeat_counts_completed_batches_maintain_counts_available"),sheet_body)
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
	button(ColonyText.text("ui.action.add_order"),func() -> void:
		var filters: Array = choices.keys().filter(func(id:Variant)->bool:return choices[id].button_pressed)
		if recipe.food_count > 0 and filters.is_empty():
			notice = "Allow at least one food ingredient."
			return
		_submit("recipe_order",{"target":station.id,"definition":recipe.id,"mode":"Repeat" if mode.selected == 0 else "Maintain","value":int(quantity.value),"priority":priority.selected+1,"filters":filters})
		close_sheet(),sheet_body)

func show_mode() -> void:
	show_sheet("Colony mode","ui.sheet.colony_mode")
	label(ColonyText.text("ui.help.mode.standard_allows_sustained_hunger_and_untreated_injuries"),sheet_body)
	for mode in ["Standard","Hearthside"]:
		button("Choose "+mode,func()->void:
			_submit("care_mode",{"mode":mode})
			close_sheet(),sheet_body)

func show_care() -> void:
	_tutorial_action("care")
	show_sheet("Injuries and care","ui.sheet.injuries_and_care")
	label(ColonyText.text("ui.help.care.rescue_carries_a_downed_person_to_the"),sheet_body)
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
		label(ColonyText.text("ui.help.care.stabilize_no_input_24_wu_2_health"),sheet_body)
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
		button(ColonyText.text("ui.action.mark_burial_here"),func()->void:
			_submit("burial",{"target":body.id,"x":body.x,"y":body.y})
			close_sheet(),sheet_body)
	if world.citizens.all(func(c:Dictionary)->bool:return c.downed or c.death_recorded or c.departed):
		label(ColonyText.text("ui.help.care.everyone_at_home_is_downed_available_recovery"),sheet_body)
	button(ColonyText.text("ui.action.work_preferences"),func()->void:show_sheet("Work","ui.sheet.work"),sheet_body)

func show_epilogue() -> void:
	runner.pause()
	show_sheet("Colony epilogue","ui.sheet.colony_epilogue")
	label(ColonyText.text("ui.help.epilogue.no_living_residents_remain_in_this_colony"),sheet_body)
	button(ColonyText.text("ui.action.load_save"),show_named_snapshots,sheet_body)
	button(ColonyText.text("ui.action.new_colony_with_this_seed"),show_seed_restart,sheet_body)
	button(ColonyText.text("ui.action.return_to_menu"),func()->void: show_sheet("Menu","ui.sheet.menu"),sheet_body)

func show_seed_restart() -> void:
	show_sheet("New colony with this seed","ui.sheet.new_colony_with_this_seed")
	label("Seed %d. Choose a campaign slot; an occupied slot is archived only after confirmation. Other campaigns stay intact." % world.seed,sheet_body)
	for number in range(1,6):
		var exists: bool = ColonyStore.occupied(number,store.root_directory)
		button(("Replace" if exists else "New")+" campaign %d" % number,func()->void:
			if exists:
				show_sheet("Confirm new colony","ui.sheet.confirm_new_colony")
				label("Archive campaign %d and start again with seed %d?" % [number,world.seed],sheet_body)
				button(ColonyText.text("ui.action.archive_and_restart"),func()->void:_restart_seed(number,true),sheet_body)
			else: _restart_seed(number,false),sheet_body)

func _restart_seed(number: int, replace: bool) -> void:
	_create_new_colony(number,world.seed,world.site_id,world.care_state.mode,replace)

func show_new_colony(number: int) -> void:
	show_sheet("New colony","ui.sheet.new_colony")
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
	label(ColonyText.text("ui.help.new_colony.seed_0_to_4294967295_same_seed_and"),sheet_body)
	var mode: CycleChoiceButton = CycleChoiceButton.new()
	mode.add_item("Standard"); mode.add_item("Hearthside")
	mode.custom_minimum_size = Vector2(48,48); sheet_body.add_child(mode)
	label(ColonyText.text("ui.help.new_colony.standard_raids_untreated_injuries_can_kill_hearthside"),sheet_body)
	var create: Button = button(ColonyText.text("ui.action.create_colony"),func()->void:
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
	show_sheet("Growing the valley","ui.sheet.growing_the_valley")
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
		show_sheet("Generation problem","ui.sheet.generation_problem")
		label(result.error,sheet_body)
		button(ColonyText.text("ui.action.choose_another_seed"),func()->void:show_new_colony(number),sheet_body)
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
	show_sheet("Welcome","ui.sheet.welcome")
	if world.terrain_state.fallback: notice = "This seed uses the verified fallback layout. See generation details in Menu."

func _exit_tree() -> void:
	_finish_background_save(true,false)
	if creation_thread != null and creation_thread.is_started(): creation_thread.wait_to_finish()

func _home_tile(point: Vector2i) -> Vector2i:
	return ColonyGeneration.transformed(point,world.terrain_state.transform) if world is ColonyWorld and world.generator_version > 0 else point

func show_map_details() -> void:
	show_sheet("Map and seed","ui.sheet.map_and_seed")
	label("%s | Seed %d" % [_catalog_name(world.site_id),world.seed],sheet_body)
	if world.generator_version == 0:
		label(ColonyText.text("ui.help.map_details.this_campaign_keeps_its_original_starter_map"),sheet_body)
	elif world.terrain_state.fallback:
		label(ColonyText.text("ui.help.map_details.verified_fallback_layout_normal_soil_standard_floodplain"),sheet_body)
	else:
		label(ColonyText.text("ui.help.map_details.generated_terrain_is_stored_with_the_campaign"),sheet_body)
		label("Generation attempt %d" % world.terrain_state.attempt,sheet_body)
	button(ColonyText.text("ui.action.show_weather"),show_weather,sheet_body)
	button("Rooms overlay: "+("On" if view.rooms_overlay else "Off"),func()->void:
		view.rooms_overlay=not view.rooms_overlay;close_sheet()
		notice="Room roofs are faded. Enclose 1-64 tiles with walls and doors." if view.rooms_overlay else "Rooms overlay off.",sheet_body).name="RoomsOverlay"

func begin_forest() -> void:
	begin_placement()
	placement_kind = "forest"
	view._update_transform()
	notice = "Drag around trees. The forest keeps 75% mature and replants cut cells; individual cuts can go below that reserve."

func show_forest(zone: Dictionary) -> void:
	show_sheet("Forest zone","ui.sheet.forest_zone")
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
	show_sheet("Wildlife","ui.sheet.wildlife")
	label(ColonyText.text("ui.help.wildlife.wild_animals_forage_and_flee_mark_a"),sheet_body)
	for animal in world.wildlife_state.animals:
		if animal.health<=0: continue
		button("%s · health %d" % [_catalog_name(animal.definition),animal.health],func()->void:
			view.camera_tile = Vector2(animal.x,animal.y); _wildlife_sheet(animal),sheet_body)

func _wildlife_sheet(animal: Dictionary) -> void:
	show_details(_catalog_name(animal.definition))
	var definition: Dictionary = world.definitions.animals[animal.definition]
	label("Health %d/%d. %s" % [animal.health,definition.health,catalog_strings.get(animal.definition+".description","")],sheet_body)
	label("After butchering (%d WU): %s. Carcass spoils in two days; outputs need hauling. Hunters retreat at health 40." % [definition.work_milli/1000,_cost_text(definition.outputs)],sheet_body)
	if world.jobs.any(func(j:Dictionary)->bool:return j.kind == "hunt" and j.target == animal.id and j.state not in ["Complete","Canceled"]):
		label(ColonyText.text("ui.help.wildlife_sheet.hunt_marked_eligible_armed_gathering_workers_take"),sheet_body)
		for job in world.jobs:
			if job.kind == "hunt" and job.target == animal.id and job.state not in ["Complete","Canceled"]: button(ColonyText.text("ui.action.inspect_hunt"),func()->void:_job_sheet(job),sheet_body)
		return
	label(ColonyText.text("ui.help.wildlife_sheet.bows_can_reach_fleeing_wildlife_from_six"),sheet_body)
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
		button(ColonyText.text("ui.action.solo_hunt_risk"),func()->void:
			var chosen: int = hunter_ids[hunter.selected]
			show_sheet("Solo boar hunt","ui.sheet.solo_boar_hunt")
			label(ColonyText.text("ui.help.wildlife_sheet.a_wounded_boar_deals_12_damage_every"),sheet_body)
			button(ColonyText.text("ui.action.confirm_solo_hunt"),func()->void:_submit("hunt",{"target":animal.id,"solo":true,"citizen":chosen});close_sheet(),sheet_body),sheet_body)

func begin_pen() -> void:
	begin_placement();placement_kind="pen"
	notice="Paint inside completed fences or walls. A gate permits handlers to lead animals. Each animal needs four free tiles and one barn shelter slot."

func show_pens() -> void:
	show_sheet("Livestock pens","ui.sheet.livestock_pens")
	label(ColonyText.text("ui.help.pens.husbandry_unlocks_pens_and_animal_acquisition_build"),sheet_body)
	button(ColonyText.text("ui.action.paint_pen"),begin_pen,sheet_body)
	for pen in world.domestic_state.pens:
		var info: Dictionary = ColonyDomestic.status(world,pen)
		button("Pen %d · %d/%d animals" % [pen.id,info.count,info.capacity],func()->void:show_pen(pen),sheet_body)

func show_pen(pen: Dictionary) -> void:
	show_sheet("Livestock pen","ui.sheet.livestock_pen")
	var info: Dictionary = ColonyDomestic.status(world,pen)
	var animals: Array = ColonyDomestic.occupants(world,pen.id)
	var daily: int = 0
	for animal in animals:
		if not animal.away: daily += ColonyDomestic.demand(world,animal,world.tick/7200+1)
	label("%d/%d animals. Four interior tiles and one shelter slot each; colony limit twelve. Feed demand: %d grain/vegetable units per day, removed at 06:00. Animals Off stops stocking and collection." % [info.count,info.capacity,daily],sheet_body)
	label(info.error if not info.error.is_empty() else pen.reason,sheet_body)
	for barn in info.barns:
		label("Barn %d: feed %d/24 · products %d/24. Fed adults accrue up to two days of products; collection costs 4 WU." % [barn,ColonyDomestic.feed_count(world,barn),ColonyDomestic.output_count(world,barn)],sheet_body)
	label(ColonyText.text("ui.help.pen.breeding_one_juvenile_after_eight_days_with"),sheet_body)
	button("Disable breeding" if pen.breeding else "Enable breeding",func()->void:_submit("breeding",{"target":pen.id,"enabled":not pen.breeding});close_sheet(),sheet_body)
	for animal in animals: button(animal.name+" · health "+str(animal.health),func()->void:show_domestic_animal(animal),sheet_body)

func show_domestic_animal(animal: Dictionary) -> void:
	show_details(animal.name)
	var definition: Dictionary = world.definitions.animals[animal.definition]
	label("%s · health %d/%d. %s" % [_catalog_name(animal.definition),animal.health,definition.health,"Juvenile: %.1f days until maturity" % ((animal.juvenile_until-world.tick)/7200.0) if animal.juvenile_until>world.tick else "Adult"],sheet_body)
	label("%d unfed days. Two days of grace; then 10 health/day. Feeding restores 10/day. %d products await collection; no milk from goats away on expedition." % [animal.unfed,animal.pending],sheet_body)
	button(ColonyText.text("ui.action.inspect_pen"),func()->void:show_pen(world.find(world.domestic_state.pens,animal.pen)),sheet_body)
	if animal.away: label(ColonyText.text("ui.help.domestic_animal.away_on_expedition_local_work_unavailable"),sheet_body);return
	button(ColonyText.text("ui.action.slaughter"),func()->void:
		show_details("Slaughter "+animal.name)
		label("Confirm slaughter of %s? Ten WU produces %s. This kills this named animal. Slaughter and breeding are optional; the charter can be completed without them." % [animal.name,_cost_text(definition.slaughter_outputs)],sheet_body)
		button("Confirm slaughter "+animal.name,func()->void:_submit("slaughter",{"target":animal.id});close_sheet(),sheet_body),sheet_body)

func begin_lodge() -> void:
	begin_placement();placement_kind="lodge";view.preview_lodge=true
	view.fit_build_preview();rotation_button.visible=false
	notice="Four beds, 23 walls and a south door. W73 F8; 206 WU. Clear an 8×6 footprint; the preset uses normal blueprints and can be edited individually."

func show_equipment(id: int) -> void:
	var person: Dictionary = world.find(world.citizens,id)
	show_details(person.name+" · Equipment")
	button(ColonyText.text("ui.action.work_preferences"),func()->void:show_work_preferences(id),sheet_body)
	label(ColonyText.text("ui.help.equipment.the_wearer_fetches_each_item_and_equips"),sheet_body)
	label(ColonyText.text("ui.help.equipment.missing_toolkit_half_build_craft_field_speed"),sheet_body)
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
	show_details(_catalog_name(station.definition)+" · Maintenance")
	var definition: Dictionary = world.definitions.buildings[station.definition]
	var missing: int = definition.health-station.health
	if missing>0:
		label("Repair restores %d health for %d %s and %.1f WU. Cost rounds up once per repair task; further damage can remain after this work." % [missing,(missing+49)/50,ColonyMaintenance.dominant(definition),missing/10.0],sheet_body)
		button(ColonyText.text("ui.action.repair"),func()->void:_submit("repair",{"target":station.id});close_sheet(),sheet_body)
	else: label(ColonyText.text("ui.help.maintenance.full_health_no_repair_materials_needed"),sheet_body)
	var refund: Dictionary = {}
	for item in definition.materials:
		if definition.materials[item]/2>0: refund[item]=definition.materials[item]/2
	label("Demolition: %d WU; returns %s, half materials rounded down. Stored goods/fuel fall to the ground without freshening. Beds lose assignment and production stops." % [((definition.work_milli+1999)/2000),"no materials" if refund.is_empty() else _cost_text(refund)],sheet_body)
	if station.definition in ColonyMaintenance.MOVABLE:
		label(ColonyText.text("ui.help.maintenance.move_full_original_wu_all_construction_materials"),sheet_body)
		button(ColonyText.text("ui.action.move_furniture"),func()->void:begin_furniture_move(station),sheet_body)
	button(ColonyText.text("ui.action.demolish"),func()->void:
		show_sheet("Demolish "+_catalog_name(station.definition))
		label("Remove this structure for %d WU and recover %s? Rebuilding later costs the full original materials and WU." % [((definition.work_milli+1999)/2000),"no materials" if refund.is_empty() else _cost_text(refund)],sheet_body)
		button(ColonyText.text("ui.action.confirm_demolition"),func()->void:_submit("demolish",{"target":station.id});close_sheet(),sheet_body),sheet_body)

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
	show_sheet("Newcomer offers","ui.sheet.newcomer_offers")
	label(ColonyText.text("ui.help.newcomers.adult_travelers_offer_to_join_every_four"),sheet_body)
	var waiting: Array = world.population_state.offers.filter(func(o:Dictionary)->bool:return o.state in ["Offered","Accepted"])
	if waiting.is_empty(): label(ColonyText.text("ui.help.newcomers.no_traveler_is_waiting_the_next_offers"),sheet_body)
	for request in waiting:
		var person: Dictionary = request.candidate
		label("%s · %s first · %s / %s · prefers %s food" % [person.name,person.preferred,person.traits[0],person.traits[1],person.food],sheet_body)
		var skill_text: Array[String] = []
		for skill in person.skills: skill_text.append(skill+" "+str(person.skills[skill]))
		label(", ".join(skill_text),sheet_body)
		if request.state=="Accepted": label(ColonyText.text("ui.help.newcomers.walking_in_from_the_boundary_the_arrival"),sheet_body);continue
		label("Waits %.1f more game hours. No hidden reputation penalty if this expires." % ((request.deadline-world.tick)/300.0),sheet_body)
		var check: Dictionary = ColonyPopulation.acceptance(world,request)
		label("Ready: free sleeping place and at least two days of food for the enlarged household." if check.error.is_empty() else check.error,sheet_body)
		if check.error.is_empty(): button("Accept "+person.name,func()->void:_submit("newcomer",{"target":request.id,"accept":true});close_sheet(),sheet_body)
		else:
			button(ColonyText.text("ui.action.build_sleeping_place"),func()->void:begin_build("bedroll"),sheet_body)
			button(ColonyText.text("ui.action.food_forecast"),func()->void:show_sheet("Journal","ui.sheet.journal"),sheet_body)
		button("Decline "+person.name,func()->void:_submit("newcomer",{"target":request.id,"accept":false});close_sheet(),sheet_body)

func show_valley() -> void:
	show_sheet("Valley and neighbors","ui.sheet.valley_and_neighbors")
	button(ColonyText.text("ui.action.incident_forecast_and_pressure"),show_incidents,sheet_body)
	button(ColonyText.text("ui.action.visitor_opportunities"),show_opportunities,sheet_body)
	button(ColonyText.text("ui.action.regional_map"),show_region,sheet_body)
	button(ColonyText.text("ui.action.expedition_status"),show_expeditions,sheet_body)
	label(ColonyText.text("ui.help.valley.merchants_visit_every_four_days_beginning_day"),sheet_body)
	label("Next visit: %s in %.1f game hours" % [ColonyTrade.COMMUNITIES[world.trade_state.visit_index%3].capitalize(),maxf(0,(world.trade_state.next_visit-world.tick)/300.0)],sheet_body)
	for community in ColonyTrade.COMMUNITIES:
		var score: int = world.trade_state.reputation[community]
		label("%s | %d · %s\nRequested delivery: %s. Next eligible in %.1f days." % [community.capitalize(),score,"Trusted" if score>=70 else ("Friendly" if score>=40 else "Neighbor"),_cost_text(world.definitions.communities[community].delivery),maxf(0,(world.trade_state.delivery_after[community]-world.tick)/7200.0)],sheet_body)
	for merchant in world.trade_state.merchants:
		if merchant.state=="Gone": continue
		label("%s: %s · %s" % [merchant.community.capitalize(),merchant.state,merchant.note],sheet_body)
		if merchant.state=="Trading":
			button("Trade with "+merchant.community.capitalize(),func()->void:show_trade(merchant),sheet_body)
			button(ColonyText.text("ui.action.deliver_community_request"),func()->void:_preview_trade(merchant,{},world.definitions.communities[merchant.community].delivery.duplicate(),0,true),sheet_body)
	for exchange in world.trade_state.exchanges:
		if exchange.state!="Packing": continue
		label("%s payment delivery: %s" % [exchange.community.capitalize(),_cost_text(exchange.pay)],sheet_body)
		button("Cancel unpaid exchange "+str(exchange.id),func()->void:_submit("trade_cancel",{"target":exchange.id});close_sheet(),sheet_body)
	var receipts: Array = world.trade_state.exchanges.filter(func(e:Dictionary)->bool:return e.state=="Complete")
	for exchange in receipts.slice(maxi(0,receipts.size()-10)):
		label("Receipt %d: %s paid %s; received %s; gift %d%s" % [exchange.id,exchange.community.capitalize(),_cost_text(exchange.pay),_cost_text(exchange.buy),exchange.gift,"; delivery +10 reputation" if exchange.delivery else ""],sheet_body)

func show_trade(merchant: Dictionary) -> void:
	show_sheet("Trade · "+merchant.community.capitalize())
	label(ColonyText.text("ui.help.trade.choose_quantities_then_preview_payment_is_reserved"),sheet_body)
	if FoodForecast.calculate(world).ticks<3600 and merchant.stock.get("meal",0)>0: label(ColonyText.text("ui.help.trade.food_recovery_consider_meals_paid_with_wood"),sheet_body)
	var buys: Dictionary = {};var pays: Dictionary = {}
	label(ColonyText.text("ui.help.trade.merchant_goods"),sheet_body)
	for item in merchant.stock:
		var remaining: int = ColonyTrade.available(world,merchant,item)
		if remaining<=0: continue
		label(item.capitalize()+" | "+str(remaining)+" available",sheet_body)
		var quantity: SpinBox = SpinBox.new();quantity.min_value=0;quantity.max_value=remaining;quantity.value=0;quantity.custom_minimum_size=Vector2(96,48);sheet_body.add_child(quantity);buys[item]=quantity
	label(ColonyText.text("ui.help.trade.your_offer"),sheet_body)
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
	button(ColonyText.text("ui.action.preview_exchange"),func()->void:
		var buy: Dictionary = {};var pay: Dictionary = {}
		for item in buys:
			if buys[item].value>0: buy[item]=int(buys[item].value)
		for item in pays:
			if pays[item].value>0: pay[item]=int(pays[item].value)
		_preview_trade(merchant,buy,pay,0 if pen_choice.selected==0 else pens[pen_choice.selected-1].id,false),sheet_body)

func _preview_trade(merchant: Dictionary, buy: Dictionary, pay: Dictionary, pen: int, delivery: bool) -> void:
	var quote: Dictionary = ColonyTrade.preview(world,merchant,buy,pay,pen,delivery)
	show_sheet("Delivery preview" if delivery else "Exchange preview","ui.sheet.delivery_preview" if delivery else "ui.sheet.exchange_preview")
	label("Pay: %s\nReceive: %s" % [_cost_text(pay),"Ten reputation; no deadline after acceptance" if delivery else _cost_text(buy)],sheet_body)
	if not quote.error.is_empty():
		label(quote.error,sheet_body);button(ColonyText.text("ui.action.back_to_trade"),func()->void:show_trade(merchant),sheet_body);return
	label("Price %d · offer %d · surplus gift %d. The gift gives no extra reputation. Supplies stay reserved until physical payment or cancellation. Animals go to pen %d." % [quote.cost,quote.offered,quote.gift,pen],sheet_body)
	button("Accept delivery" if delivery else "Accept exchange",func()->void:_submit("trade",{"target":merchant.id,"buy":buy,"pay":pay,"pen":pen,"delivery":delivery});close_sheet(),sheet_body)
	button(ColonyText.text("ui.action.cancel_preview"),show_valley,sheet_body)

func show_region() -> void:
	show_sheet("Regional map","ui.sheet.regional_map")
	label(ColonyText.text("ui.help.region.known_9_x_9_valley_h_is"),sheet_body)
	var scroll: ScrollContainer = TouchScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.custom_minimum_size=Vector2(0,420);sheet_body.add_child(scroll)
	var grid: GridContainer = GridContainer.new();grid.columns=9;scroll.add_child(grid)
	for node in world.region_state.nodes:
		var mark: String = "H" if node.definition=="home" else ("S" if node.definition in ColonyRegion.SITES else ("N" if node.definition in ColonyTrade.COMMUNITIES else ""))
		var tile: Button = button(mark,func()->void:
			if node.definition=="home": show_station(ColonyTrade.cart(world))
			else: show_expedition_prepare(node.definition,false),grid,48)
		tile.tooltip_text=node.scenery if node.definition=="transit" else node.definition.capitalize()
		tile.disabled=node.definition=="transit"
	button(ColonyText.text("ui.action.current_expedition"),show_expeditions,sheet_body)
	for definition in ColonyRegion.SITES+ColonyTrade.COMMUNITIES:
		var path: Array = ColonyRegion.route(world,definition)
		var progress: Dictionary = world.region_state.progress[definition]
		button(definition.capitalize()+" · "+str(path.size()-1)+" edges"+(" · landmark" if progress.completed and definition in ColonyRegion.SITES and world.definitions.expeditions[definition].cooldown_days==0 else ""),func()->void:show_expedition_prepare(definition,false),sheet_body)
		if not progress.leftovers.is_empty() and not progress.pickup_used:
			button("Pick up leftovers: "+definition.capitalize(),func()->void:show_expedition_prepare(definition,true),sheet_body)

func show_expedition_prepare(definition: String, pickup: bool) -> void:
	show_details(definition.capitalize())
	var data: Dictionary = ColonyRegion.definition_data(world,definition,pickup)
	var edges: int = ColonyRegion.route(world,definition).size()-1
	label("%d edges each way · %d site hours · %d regional hours total\nSkill %s / challenge %d\nContract inputs: %s\nReward: %s; %d insight; %s" % [edges,data.site_hours,edges*12+data.site_hours,data.skill,data.challenge,_cost_text(data.payment),_cost_text(data.rewards),data.insight,str(data.reputation)],sheet_body)
	label(ColonyText.text("ui.help.expedition_prepare.packing_plan_select_two_to_four_residents"),sheet_body)
	var rules: VBoxContainer = VBoxContainer.new();sheet_body.add_child(rules);rules.visible=false
	button(ColonyText.text("ui.action.travel_and_outcome_rules"),func()->void:rules.visible=not rules.visible,sheet_body)
	label(ColonyText.text("ui.help.expedition_prepare.select_two_to_four_healthy_residents_and"),rules)
	var people: Dictionary = {};var goats: Dictionary = {};var extras: Dictionary = {}
	for person in ColonyRegion.home(world):
		var choice: CheckButton = CheckButton.new();choice.text=ColonyFonts.display(person.name);choice.tooltip_text=ColonyFonts.warning(person.name);choice.custom_minimum_size.y=48;choice.button_pressed=person.id in [2,3];sheet_body.add_child(choice);people[person.id]=choice
		label("%s %d · health %d · fullness %d · rest %d\n%s" % [data.skill,person.skills[data.skill],person.health,person.fullness,person.rest,"Unarmed" if person.equipment.weapon.is_empty() else person.equipment.weapon.capitalize()],sheet_body)
	for animal in world.domestic_state.animals:
		if animal.definition!="pack_goat" or animal.health<=0 or animal.away: continue
		var choice: CheckButton = CheckButton.new();choice.text=ColonyFonts.display(animal.name);choice.tooltip_text=ColonyFonts.warning(animal.name);choice.custom_minimum_size.y=48;sheet_body.add_child(choice);goats[animal.id]=choice
		label(ColonyText.text("ui.help.expedition_prepare.twelve_extra_cargo_units_two_grain_vegetable"),sheet_body)
	var feed: CycleChoiceButton = CycleChoiceButton.new();feed.add_item("Grain feed");feed.add_item("Vegetable feed");feed.custom_minimum_size.y=48;sheet_body.add_child(feed)
	var variant: CycleChoiceButton = CycleChoiceButton.new();variant.add_item("Stone 24" if definition=="old_quarry" and not pickup else "Listed reward")
	if definition=="old_quarry" and not pickup: variant.add_item("Iron ore 12")
	variant.custom_minimum_size.y=48;sheet_body.add_child(variant)
	var pens: Array = world.domestic_state.pens
	var pen: CycleChoiceButton = CycleChoiceButton.new();pen.add_item("No animal destination")
	for enclosure in pens: pen.add_item("Returning goat to pen "+str(enclosure.id))
	pen.custom_minimum_size.y=48;sheet_body.add_child(pen)
	var extra_panel: VBoxContainer = VBoxContainer.new();sheet_body.add_child(extra_panel);extra_panel.visible=false
	button(ColonyText.text("ui.action.optional_extra_cargo"),func()->void:extra_panel.visible=not extra_panel.visible,sheet_body)
	for item in ColonyTrade.accessible_goods(world):
		var available: int = ColonyTrade.accessible_goods(world)[item]
		if available<=0: continue
		label(item.capitalize()+" extra",extra_panel)
		var count: SpinBox = SpinBox.new();count.max_value=available;count.custom_minimum_size=Vector2(96,48);extra_panel.add_child(count);extras[item]=count
	button(ColonyText.text("ui.action.preview_packing_plan"),func()->void:
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
	show_sheet("Expedition packing preview","ui.sheet.expedition_packing_preview")
	if not quote.error.is_empty(): label(quote.error,sheet_body);button(ColonyText.text("ui.action.change_party_or_cargo"),func()->void:show_expedition_prepare(plan.definition,plan.pickup),sheet_body);return
	label("%s · %d hours · readiness %d / challenge %d\nPack: %s\nDeparture capacity %d; return capacity %d\nExpected items: %s; insight %d\nHome forecast without travelers: %s" % [plan.definition.capitalize(),quote.hours,quote.readiness,quote.challenge,_cost_text(quote.inputs),quote.capacity,quote.return_capacity,_cost_text(quote.rewards),quote.insight,ColonyText.food_runway(quote.home_forecast)],sheet_body)
	var removed: Array[String] = []
	for id in plan.party:
		var person: Dictionary = world.find(world.citizens,id);removed.append(person.name+" · "+str(person.skills))
	label("Skills leaving home:\n"+"\n".join(removed),sheet_body)
	label(ColonyText.text("ui.help.expedition_preview.one_midpoint_choice_with_a_free_continue"),sheet_body)
	button(ColonyText.text("ui.action.start_packing"),func()->void:_submit("expedition_prepare",plan);close_sheet(),sheet_body)
	button(ColonyText.text("ui.action.change_plan"),func()->void:show_expedition_prepare(plan.definition,plan.pickup),sheet_body)

func show_expeditions() -> void:
	_tutorial_action("expedition")
	show_sheet("Expedition","ui.sheet.expedition")
	var trip: Dictionary = ColonyRegion.active(world)
	if trip.is_empty(): label(ColonyText.text("ui.help.expeditions.no_expedition_is_active_choose_a_known"),sheet_body);button(ColonyText.text("ui.action.regional_map"),show_region,sheet_body);return
	label(trip.args.definition.capitalize()+" · "+trip.state+"\n"+trip.note,sheet_body)
	label("Party: "+", ".join(trip.args.party.map(func(id:int)->String:return world.find(world.citizens,id).name))+"\nCargo: "+_cost_text(ColonyRegion.cargo(world,trip))+"\nReadiness %d / %d · remaining phase %.1f hours" % [trip.readiness,trip.quote.challenge,trip.remaining/300.0],sheet_body)
	if trip.state in ["Preparing","Ready"]:
		label(ColonyText.text("ui.help.expeditions.travelers_eat_at_fullness_500_and_sleep"),sheet_body)
		var error: String = ColonyRegion.ready(world,trip)
		label("Ready for Depart" if error.is_empty() else error,sheet_body)
		if error.is_empty():
			if trip.quote.shortfall>2:
				button(ColonyText.text("ui.action.review_attempt_unprepared"),func()->void:
					show_sheet("Attempt unprepared?","ui.sheet.attempt_unprepared");label(ColonyText.text("ui.help.expeditions.no_item_reward_half_insight_twenty_health"),sheet_body)
					button(ColonyText.text("ui.action.attempt_unprepared"),func()->void:_submit("expedition_depart",{"target":trip.id,"unprepared":true});close_sheet(),sheet_body),sheet_body)
			else: button(ColonyText.text("ui.action.depart"),func()->void:_submit("expedition_depart",{"target":trip.id,"unprepared":false});close_sheet(),sheet_body)
		button(ColonyText.text("ui.action.cancel_packing"),func()->void:_submit("expedition_cancel",{"target":trip.id});close_sheet(),sheet_body)
	elif trip.state=="Decision":
		var options: Array = [["wait","repair","continue"],["give","continue"],["survey","continue"]][trip.decision]
		var descriptions: Dictionary = {"wait":"Wait for carrier: +6 hours, cloth 4","repair":"Repair path: wood 4, cloth 4, no delay","give":"Give rations: 2 rations, +3 Road reputation","survey":"Survey shortcut: +6 hours, +80 insight","continue":"Continue on the original route: free"}
		if world.tick<world.region_state.progress[trip.args.definition].decision_after: label(ColonyText.text("ui.help.expeditions.optional_bonus_is_cooling_down_no_extra"),sheet_body)
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
		button(ColonyText.text("ui.action.collect_kept_rewards_and_return"),func()->void:
			var keep: Dictionary = {}
			for item in quantities:
				if quantities[item].value>0: keep[item]=int(quantities[item].value)
			_submit("expedition_collect",{"target":trip.id,"keep":keep});close_sheet();runner.set_speed(runner.previous_speed),sheet_body)
	if trip.state not in ["Preparing","Ready","Returning","Walking in","Unloading"]: button(ColonyText.text("ui.action.recall_without_committing_new_site_rewards"),func()->void:_submit("expedition_recall",{"target":trip.id});close_sheet();runner.set_speed(runner.previous_speed),sheet_body)

func show_fires() -> void:
	show_sheet("Fire and water","ui.sheet.fire_and_water")
	label(ColonyText.text("ui.help.fires.emergency_crews_override_ordinary_care_off_and"),sheet_body)
	for fire in ColonyFire.active(world):
		var object: Dictionary = world.find(world.structures if fire.kind=="structure" else world.stacks,fire.target)
		label("%s at (%d, %d) · %.1f/8 WU applied\n%s" % [object.get("definition",object.get("item","")),object.x,object.y,fire.work/1000.0,"Two health/sec; touching wood can ignite every thirty seconds" if fire.kind=="structure" else "One item/sec; food and the cart itself do not propagate fire"],sheet_body)
		button("Look at fire "+str(fire.id),func()->void:view.camera_tile=Vector2(object.x,object.y);view.follow_id=0;view._update_transform();close_sheet(),sheet_body)
	button(ColonyText.text("ui.action.work_preferences"),func()->void:show_sheet("Work","ui.sheet.work"),sheet_body)
	button(ColonyText.text("ui.action.build_a_well"),func()->void:begin_build("well"),sheet_body)

func show_incidents() -> void:
	show_sheet("Incident forecast","ui.sheet.incident_forecast")
	var pressure: Dictionary = ColonyDirector.pressure(world)
	label("Pressure %d/100. No new major at fifty or more, with a downed resident, or while an incident remains unresolved." % pressure.score,sheet_body)
	for cause in pressure.terms: label(cause+": +"+str(pressure.terms[cause]),sheet_body)
	var gate: String = ColonyDirector.gates(world)
	label("No new major incident while recovering: "+gate if not gate.is_empty() else "Major consideration at 06:00 from day eight. Starts stay seventy-two hours apart; resolution gives forty-eight recovery hours. Already shown extreme weather reserves the same spacing.",sheet_body)
	var major: Dictionary = world.director_state.major
	if not major.is_empty(): label(major.kind.capitalize()+" · "+major.state+"\n"+major.reason+"\nDue in %.1f hours" % maxf(0,(major.due-world.tick)/300.0),sheet_body)
	button(ColonyText.text("ui.action.defense_and_supplies"),show_defense,sheet_body)
	if not ColonyFire.active(world).is_empty(): button(ColonyText.text("ui.action.fire_response"),show_fires,sheet_body)
	if not major.is_empty() and major.kind=="overheat":
		var station: Dictionary = world.find(world.structures,major.target)
		button(ColonyText.text("ui.action.suspend_overheating_station"),func()->void:_submit("station_enabled",{"target":station.id,"enabled":false});close_sheet(),sheet_body)
		button(ColonyText.text("ui.action.inspect_fixed_target"),func()->void:show_station(station),sheet_body)

func show_defense() -> void:
	show_sheet("Defense","ui.sheet.defense")
	var raid: Dictionary = ColonyDefense.active(world)
	if raid.is_empty(): label(ColonyText.text("ui.help.defense.no_road_party_is_active_choose_a"),sheet_body)
	else:
		label("Party: "+", ".join(raid.party.map(func(k:String)->String:return k.capitalize()))+"\nBudget %d · theft quota %d units · supplies price %d barter value\nEntry (%d,%d) · %s\n%s" % [raid.budget,raid.party.size()*4,raid.budget*8,raid.entry.x,raid.entry.y,raid.state,raid.reason],sheet_body)
		label("Arrival in %.1f hours. Active siege remaining %.1f hours. Worn equipment and expedition cargo cannot be stolen. Downed visitors are stable, neutral and never executed." % [maxf(0,(raid.due-world.tick)/300.0),maxf(0,(raid.arrival+1800-world.tick)/300.0) if raid.arrival>0 else 6.0],sheet_body)
		if raid.state not in ["Payment","Retreating","Resolved"]: button(ColonyText.text("ui.action.offer_supplies"),func()->void:show_raid_offer(raid),sheet_body)
		button(ColonyText.text("ui.action.acknowledge_arrival"),func()->void:_submit("raid_ack",{});close_sheet(),sheet_body)
	button(ColonyText.text("ui.action.choose_defending_squad"),func()->void:show_squad([]),sheet_body)
	button("Shelter everyone" if not world.defense_state.shelter else "End shelter order",func()->void:_submit("shelter",{"enabled":not world.defense_state.shelter});close_sheet(),sheet_body)
	button("Open passage" if not world.defense_state.open_passage else "Close hostile passage",func()->void:_submit("open_passage",{"enabled":not world.defense_state.open_passage});close_sheet(),sheet_body)
	button(ColonyText.text("ui.action.stand_down_return_everyone_to_ordinary_work"),func()->void:_submit("stand_down",{});close_sheet(),sheet_body)
	for enemy in world.defense_state.enemies:
		if enemy.state!="Gone": button(enemy.definition.capitalize()+" · "+enemy.state+" · "+str(enemy.health)+" health",func()->void:show_enemy(enemy),sheet_body)

func show_squad(initial: Array) -> void:
	show_sheet("Defending squad","ui.sheet.defending_squad")
	var people: Dictionary = {}
	for person in ColonyRegion.home(world):
		if person.downed: continue
		var choice: CheckButton = CheckButton.new();choice.text=ColonyFonts.display(person.name);choice.tooltip_text=ColonyFonts.warning(person.name);choice.button_pressed=initial.has(person.id);choice.custom_minimum_size.y=48;sheet_body.add_child(choice);people[person.id]=choice
		label("Health %d · Guard %d · %s" % [person.health,person.skills.Guard,"Unarmed" if person.equipment.weapon.is_empty() else person.equipment.weapon],sheet_body)
	button(ColonyText.text("ui.action.choose_rally_on_map"),func()->void:
		var selected: Array = []
		for id in people:
			if people[id].button_pressed: selected.append(id)
		if selected.is_empty(): notice="Choose at least one resident";return
		begin_defend_rally(selected,false),sheet_body)
	button(ColonyText.text("ui.action.review_stand_fast"),func()->void:
		var selected: Array = []
		for id in people:
			if people[id].button_pressed: selected.append(id)
		if selected.is_empty(): notice="Choose at least one resident";return
		show_sheet("Stand fast warning","ui.sheet.stand_fast_warning")
		label(ColonyText.text("ui.help.squad.automatic_retreat_at_forty_health_will_be"),sheet_body)
		button(ColonyText.text("ui.action.confirm_stand_fast_and_choose_rally"),func()->void:begin_defend_rally(selected,true),sheet_body),sheet_body)
	button(ColonyText.text("ui.action.undraft_selected"),func()->void:
		var selected: Array = []
		for id in people:
			if people[id].button_pressed: selected.append(id)
		_submit("undraft",{"citizens":selected});close_sheet(),sheet_body)

func begin_defend_rally(people: Array, stand_fast: bool) -> void:
	begin_placement();placement_kind="rally";defend_citizens=people.duplicate();defend_stand_fast=stand_fast
	view._update_transform()
	notice="Choose a rally point and Confirm. The squad holds within two tiles."

func show_enemy(enemy: Dictionary) -> void:
	show_details(enemy.definition.capitalize())
	var definition: Dictionary = world.definitions.enemies[enemy.definition]
	label("%s · health %d/%d · armor %d\n%s · %d damage every %d ticks; objective %s\nCollected goods: %s" % [enemy.state,enemy.health,definition.health,definition.armor,definition.weapon,definition.damage,definition.cooldown,definition.objective,str(enemy.loot)],sheet_body)
	if enemy.state=="Downed":
		label("Neutral and stable. Automatic recovery to twenty-five in %.1f hours; voluntary care gives three Road reputation once for this person." % maxf(0,(enemy.recovery_at-world.tick)/300.0),sheet_body)
		button(ColonyText.text("ui.action.voluntary_treatment"),func()->void:_submit("enemy_treat",{"target":enemy.id});close_sheet(),sheet_body)
	elif enemy.state in ["Active","Retreating"]:
		var squad: Array = world.citizens.filter(func(c:Dictionary)->bool:return c.drafted and not c.away).map(func(c:Dictionary)->int:return c.id)
		if not squad.is_empty(): button(ColonyText.text("ui.action.focus_with_drafted_squad"),func()->void:_submit("focus",{"citizens":squad,"target":enemy.id});close_sheet(),sheet_body)

func show_raid_offer(raid: Dictionary) -> void:
	show_sheet("Offer supplies","ui.sheet.offer_supplies")
	label("Need %d barter value at the marked meeting spot. Workers deliver it in eight-unit loads. The party waits six hours without attacks during payment; a failed delivery gives one warning hour. The absolute six-hour raid limit still prevents renewed attacks once elapsed. Payment gives no later budget increase. Retreating parties cannot be restarted." % (raid.budget*8),sheet_body)
	var choices: Dictionary = {}
	for item in ColonyTrade.accessible_goods(world):
		var available: int = ColonyTrade.accessible_goods(world)[item]
		if available<=0: continue
		label(item.capitalize()+" · value "+str(world.definitions.items[item].barter_value)+" · "+str(available)+" available",sheet_body)
		var count: SpinBox = SpinBox.new();count.max_value=available;count.custom_minimum_size=Vector2(96,48);sheet_body.add_child(count);choices[item]=count
	button(ColonyText.text("ui.action.preview_supplies"),func()->void:
		var pay: Dictionary = {};var value: int = 0
		for item in choices:
			if choices[item].value>0: pay[item]=int(choices[item].value);value+=pay[item]*world.definitions.items[item].barter_value
		show_sheet("Supply preview","ui.sheet.supply_preview")
		label("Pay "+_cost_text(pay)+"\nOffer value %d / needed %d\nMeeting (%d,%d). Surplus %d is a gift." % [value,raid.budget*8,raid.meeting.x,raid.meeting.y,maxi(0,value-raid.budget*8)],sheet_body)
		if value<raid.budget*8: label("Add "+str(raid.budget*8-value)+" value before accepting",sheet_body)
		else: button(ColonyText.text("ui.action.accept_and_deliver_supplies"),func()->void:_submit("raid_offer",{"target":raid.id,"pay":pay});close_sheet(),sheet_body),sheet_body)

func show_opportunities() -> void:
	show_sheet("Visitor offers","ui.sheet.visitor_offers")
	label(ColonyText.text("ui.help.opportunities.every_second_day_from_day_four_one"),sheet_body)
	var active: Array = world.opportunity_state.offers.filter(func(e:Dictionary)->bool:return e.state in ["Offered","Accepted","Hosted"])
	if active.is_empty(): label(ColonyText.text("ui.help.opportunities.no_offer_is_waiting_tables_friendships_and"),sheet_body)
	for event in active:
		var visitor: Dictionary = world.find(world.opportunity_state.visitors,event.visitor)
		label(event.definition.replace("_"," ").capitalize()+" · "+event.state,sheet_body)
		label({"traveling_storyteller":"Two meals host a storyteller for six hours. Residents who share a continuous half-hour of leisure nearby gain +40 morale target for one day.","stranded_carrier":"Deliver eight wood and complete twelve Building WU at the cart within two days. Receive four cloth and +3 Road fellowship reputation.","surplus_harvest":"Deliver twenty wood to the cart within two days. Receive sixteen grain.","shared_observation":"The named friends each contribute twenty Study WU at an available research desk within two days. Receive one hundred insight."}[event.definition],sheet_body)
		label("%s · %s
%.1f hours left to accept or finish payment/work. %s" % [visitor.state,visitor.note,maxf(0,(event.deadline-world.tick)/300.0),event.reason],sheet_body)
		if not event.people.is_empty(): label("Friends: "+", ".join(event.people.map(func(id:int)->String:return world.find(world.citizens,id).name)),sheet_body)
		if event.state=="Offered":
			button("Accept "+event.definition.replace("_"," "),func()->void:_submit("minor_event",{"target":event.id,"accept":true});close_sheet(),sheet_body)
			button(ColonyText.text("ui.action.decline_offer"),func()->void:_submit("minor_event",{"target":event.id,"accept":false});close_sheet(),sheet_body)
		for id in event.jobs:
			var job: Dictionary = world.find(world.jobs,id)
			if not job.is_empty(): button("Task: %s · %s" % ["Study together" if job.kind=="minor_study" else ("Repair cart" if event.definition=="stranded_carrier" else "Deliver supplies"),job.state],func()->void:_job_sheet(job),sheet_body)
	for event in world.opportunity_state.offers.slice(maxi(0,world.opportunity_state.offers.size()-10)):
		if event.state not in ["Offered","Accepted","Hosted"]: label("%s · %s · %s" % [event.definition.replace("_"," ").capitalize(),event.state,event.reason],sheet_body)

func show_charter() -> void:
	show_sheet("Charter","ui.sheet.charter")
	label(ColonyChronicle.display_name(world,0)+" - a refuge worth staying in",sheet_body)
	label(ColonyText.text("ui.help.charter.stages_complete_in_order_and_remain_recorded"),sheet_body)
	button(ColonyText.text("ui.action.communal_supper"),show_supper,sheet_body)
	button(ColonyText.text("ui.action.cart_appearance"),show_charter_appearance,sheet_body)
	button(ColonyText.text("ui.action.name_settlement"),func()->void:show_rename(0),sheet_body)
	for stage in ColonyCharter.checklist(world):
		label(("Recorded: " if stage.complete else "Next: " if world.charter_state.completed.size()==ColonyCharter.STAGES.find(stage.id) else "Later: ")+stage.title,sheet_body)
		if stage.complete: label("Day %d snapshot is retained." % world.charter_state.snapshots[stage.id].day,sheet_body)
		for condition in stage.conditions: label(("[x] " if condition.met else "[ ] ")+condition.text,sheet_body)
		if stage.reward>0: label("Reward: %d insight and a cosmetic cart appearance." % stage.reward,sheet_body)
	if world.charter_state.ending:
		button(ColonyText.text("ui.action.read_the_epilogue"),show_charter_ending,sheet_body)
	elif world.charter_state.ceremony.get("state","")=="Active":
		label("Ceremony: %.1f game hours remaining. A hostile arrival cancels it without using supplies." % (maxi(0,world.charter_state.ceremony.end-world.tick)/300.0),sheet_body)
		button(ColonyText.text("ui.action.cancel_ceremony"),func()->void:_submit("cancel_ceremony",{});close_sheet(),sheet_body)
	else:
		var reason: String = ColonyCharter.ceremony_error(world)
		if reason.is_empty(): button(ColonyText.text("ui.action.begin_two_hour_ceremony"),func()->void:_submit("start_ceremony",{});close_sheet(),sheet_body)
		else: label("Ceremony waits: "+reason,sheet_body)
	button(ColonyText.text("ui.action.food_forecast"),show_food_forecast,sheet_body)
	button(ColonyText.text("ui.action.research"),show_research,sheet_body)

func show_supper() -> void:
	show_sheet("Communal supper","ui.sheet.communal_supper")
	label(ColonyText.text("ui.help.supper.commonlife_and_eight_healthy_home_residents_60"),sheet_body)
	label(ColonyText.text("ui.help.supper.eight_distinct_attendees_complete_the_supper_unused"),sheet_body)
	var status: Dictionary = ColonyCharter.supper_status(world)
	label("%s - %d/8 attended\n%s" % [status.state,status.attended,status.reason],sheet_body)
	if not status.traveling.is_empty(): label("Traveling: "+", ".join(status.traveling),sheet_body)
	if not status.waiting.is_empty(): label("Waiting or seated: "+", ".join(status.waiting),sheet_body)
	if status.state in ColonyCharter.ACTIVE:
		var supper: Dictionary = world.charter_state.supper
		label("Day %d, 18:00-20:00. %d meals eaten; %d meals still reserved." % [supper.start/7200+1,supper.eaten.size(),world.stacks.reduce(func(n:int,s:Dictionary)->int:return n+s.reservations.get(supper.job,0),0)],sheet_body)
		button(ColonyText.text("ui.action.cancel_supper"),func()->void:_submit("cancel_supper",{});close_sheet(),sheet_body)
	else:
		var reason: String = ColonyCharter.supper_error(world)
		if reason.is_empty(): button(ColonyText.text("ui.action.reserve_meals_and_evening"),func()->void:_submit("start_supper",{});close_sheet(),sheet_body)
		else: label("Before scheduling: "+reason,sheet_body)
	button(ColonyText.text("ui.action.build_a_table"),func()->void:begin_build("table"),sheet_body)
	button(ColonyText.text("ui.action.food_forecast"),show_food_forecast,sheet_body)

func show_charter_appearance() -> void:
	show_sheet("Cart appearance","ui.sheet.cart_appearance")
	label(ColonyText.text("ui.help.charter_appearance.charter_rewards_change_the_cart_s_appearance"),sheet_body)
	for stage in ColonyCharter.STAGES.slice(0,4):
		var title: String = {"shelter":"Settlement banner","provision":"Courtyard palette","connection":"Route plaque","refuge":"Refuge sign"}[stage]
		if world.charter_state.completed.has(stage):
			var enabled: bool = world.charter_state.appearances.has(stage)
			button(("Remove " if enabled else "Apply ")+title,func()->void:_submit("charter_appearance",{"definition":stage,"enabled":not enabled});close_sheet(),sheet_body)
		else: label(title+" waits for "+ColonyCharter.TITLES[stage]+".",sheet_body)

func show_charter_ending() -> void:
	runner.pause()
	show_sheet("Brackenward restored","ui.sheet.brackenward_restored")
	label(ColonyChronicle.display_name(world,0)+" has completed its charter. The beacon watches over a living settlement. These moments come from the colony's recorded history.",sheet_body)
	for fact in ColonyChronicle.epilogue(world):
		button("Day %d: %s" % [fact.tick/7200+1,fact.text],func()->void:show_fact(fact.id),sheet_body)
	button(ColonyText.text("ui.action.continue_settlement"),func()->void:_submit("continue_settlement",{});close_sheet(),sheet_body)
	button(ColonyText.text("ui.action.save_and_leave"),func()->void:
		if save_local().is_empty(): show_sheet("Menu","ui.sheet.menu"),sheet_body)
	button(ColonyText.text("ui.action.new_seed"),show_campaigns,sheet_body)
	button(ColonyText.text("ui.action.view_settlement"),func()->void:close_sheet();view.camera_tile=Vector2(ColonyTrade.cart(world).x,ColonyTrade.cart(world).y),sheet_body)

func show_chronicle() -> void:
	show_sheet("Chronicle","ui.sheet.chronicle")
	button(ColonyText.text("ui.action.pin_a_moment"),show_pin_moment,sheet_body)
	button(ColonyText.text("ui.action.charter"),show_charter,sheet_body)
	button(ColonyText.text("ui.action.full_event_ledger"),show_ledger,sheet_body)
	var days: Array = world.chronicle_state.journal
	if days.is_empty(): label(ColonyText.text("ui.help.chronicle.at_22_00_up_to_three_consequential"),sheet_body)
	for day in days.slice(maxi(0,days.size()-32)):
		if day.fact_ids.is_empty(): continue
		label("Day "+str(day.day+1),sheet_body)
		for id in day.fact_ids:
			var fact: Dictionary = ColonyChronicle.fact(world.chronicle_state,id)
			label(fact.text,sheet_body)
			button("Details of event "+str(id),func()->void:show_fact(id),sheet_body)

func show_ledger(before: int = 0) -> void:
	show_sheet("Event ledger","ui.sheet.event_ledger")
	label(ColonyText.text("ui.help.ledger.exact_simulation_facts_including_routine_work_recent"),sheet_body)
	var records: Array = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return before==0 or f.id<before)
	var page: Array = records.slice(maxi(0,records.size()-40))
	page.reverse()
	for fact in page:
		label("Day %d %02d:%02d - %s" % [fact.tick/7200+1,(fact.tick%7200)/300,(fact.tick%300)/5,fact.text],sheet_body)
		button("Inspect event "+str(fact.id),func()->void:show_fact(fact.id),sheet_body)
	if records.size()>page.size(): button(ColonyText.text("ui.action.earlier_events"),func()->void:show_ledger(page[-1].id),sheet_body)

func show_fact(id: int, expanded: bool = false) -> void:
	var fact: Dictionary = ColonyChronicle.fact(world.chronicle_state,id)
	show_sheet("Event details","ui.sheet.event_details")
	if fact.is_empty(): label(ColonyText.text("ui.help.fact.this_routine_event_is_outside_retained_history"),sheet_body);return
	label("Day %d %02d:%02d\n%s" % [fact.tick/7200+1,(fact.tick%7200)/300,(fact.tick%300)/5,fact.text],sheet_body)
	if not fact.names.is_empty(): label("Names at the time: "+", ".join(fact.names.values()),sheet_body)
	if not fact.get("location",[]).is_empty():
		button(ColonyText.text("ui.action.view_location"),func()->void:close_sheet();view.camera_tile=Vector2(fact.location[0],fact.location[1]),sheet_body)
	if not fact.changes.is_empty(): label("Recorded inventory changes: "+str(fact.changes),sheet_body)
	if fact.causes.is_empty(): label(ColonyText.text("ui.help.fact.no_immediate_cause_was_recorded_for_this"),sheet_body)
	var causes: Array = fact.causes if expanded else fact.causes.slice(0,4)
	for cause in causes:
		var evidence: Dictionary = ColonyChronicle.fact(world.chronicle_state,cause)
		label(evidence.text,sheet_body)
		button("Why: event "+str(cause),func()->void:show_fact(cause),sheet_body)
	if fact.causes.size()>4 and not expanded: button(ColonyText.text("ui.action.show_all_causes"),func()->void:show_fact(id,true),sheet_body)
	button(ColonyText.text("ui.action.back_to_chronicle"),show_chronicle,sheet_body)

func show_pin_moment() -> void:
	show_sheet("Pin a moment","ui.sheet.pin_a_moment")
	label(ColonyText.text("ui.help.pin_moment.optional_personal_note_up_to_256_printable"),sheet_body)
	var entry: LineEdit = LineEdit.new();entry.max_length=256;entry.placeholder_text="A moment to remember";entry.custom_minimum_size.y=48;sheet_body.add_child(entry)
	entry.text_changed.connect(_clear_text_entry_error)
	button(ColonyText.text("ui.action.pin_this_moment"),func()->void:
		if not ColonyChronicle._printable(entry.text.strip_edges(),256,true):
			_text_entry_error("Moment text supports up to 256 printable Basic Latin characters.");return
		_submit("pin_moment",{"text":entry.text});close_sheet(),sheet_body)

func show_rename(id: int) -> void:
	show_sheet("Name this place" if id==0 else "Rename","ui.sheet.name_this_place" if id==0 else "ui.sheet.rename")
	label(ColonyText.text("ui.help.rename.names_are_cosmetic_use_1_32_printable"),sheet_body)
	var entry: LineEdit = LineEdit.new();entry.max_length=32;entry.text=ColonyChronicle.display_name(world,id);entry.custom_minimum_size.y=48;sheet_body.add_child(entry)
	entry.text_changed.connect(_clear_text_entry_error)
	button(ColonyText.text("ui.action.save_name"),func()->void:
		if not ColonyChronicle._printable(entry.text.strip_edges(),32):
			_text_entry_error("Names require 1-32 printable Basic Latin characters after trimming.");return
		_submit("rename",{"target":id,"text":entry.text});close_sheet(),sheet_body)

func _text_entry_error(message: String) -> void:
	text_entry_error=message
	if is_instance_valid(sheet_feedback): sheet_feedback.text=ColonyFonts.display(message);sheet_feedback.show()

func _clear_text_entry_error(_text: String) -> void:
	text_entry_error=""
	if is_instance_valid(sheet_feedback):
		sheet_feedback.text=ColonyFonts.display(notice)
		sheet_feedback.visible=not notice.is_empty() and not notice.begins_with("Paused. Choose")

func show_person_history(id: int) -> void:
	show_sheet("Remembered moments","ui.sheet.remembered_moments")
	label(ColonyChronicle.display_name(world,id),sheet_body)
	var person: Dictionary = world.find(world.citizens,id)
	var memories: Array = ColonyChronicle.active_memories(world,person)
	if memories.is_empty(): label(ColonyText.text("ui.help.person_history.no_timed_memories_are_currently_affecting_morale"),sheet_body)
	for memory in memories:
		label("%s: %+d morale target. Expires day %d at %02d:%02d (%.1f hours remaining)." % [memory.text,memory.modifier,memory.expires/7200+1,(memory.expires%7200)/300,(memory.expires%300)/5,(memory.expires-world.tick)/300.0],sheet_body)
		if memory.fact_id>0: button(ColonyText.text("ui.action.remember_this_event"),func()->void:show_fact(memory.fact_id),sheet_body)
		else: label(ColonyText.text("ui.help.person_history.the_original_event_was_not_retained_in"),sheet_body)
	for fact in ColonyChronicle.highlights(world,id):
		label(fact.text,sheet_body)
		button("Details of event "+str(fact.id),func()->void:show_fact(fact.id),sheet_body)

func show_food_forecast() -> void:
	show_sheet("Food forecast","ui.sheet.food_forecast")
	_tutorial_action("forecast")
	label(tutorial_forecast_text(),sheet_body)
	label(ColonyText.text("ui.help.food_forecast.this_uses_accessible_unreserved_food_already_at"),sheet_body)
	var state: Dictionary = _tutorial_state()
	button(ColonyText.text("ui.action.unpin_forecast") if state.forecast_pinned else ColonyText.text("ui.action.pin_forecast_on_map"),func()->void:
		if state.forecast_pinned: state.forecast_pinned=false;_save_settings()
		else: _tutorial_action("pin_forecast")
		close_sheet(),sheet_body)
	var cooking: bool = world.citizens.any(func(c:Dictionary)->bool:return not c.away and not c.death_recorded and not c.departed and c.preferences.Cooking>0)
	var hearth: bool = world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="hearth" and s.cooking and not ColonyFire.burning(world,"structure",s.id))
	var raw: int = 0
	for item in world.definitions.recipes.cook_meals.alternatives: raw+=world.available(item)
	var bottlenecks: Array[String] = []
	if not cooking: bottlenecks.append(ColonyText.text("ui.help.food_forecast.enable_cooking"))
	if not hearth: bottlenecks.append(ColonyText.text("ui.help.food_forecast.usable_hearth"))
	if raw<4: bottlenecks.append(ColonyText.text("ui.help.food_forecast.raw_batch"))
	if world.available("wood")<1: bottlenecks.append(ColonyText.text("ui.help.food_forecast.cooking_fuel"))
	label(ColonyText.text("ui.forecast.cooking",{"status":ColonyText.text("ui.help.food_forecast.inputs_available") if bottlenecks.is_empty() else " ".join(bottlenecks)}),sheet_body)
	button(ColonyText.text("ui.action.gather_berries"),func()->void:begin_gather("berry_bush"),sheet_body)
	button(ColonyText.text("ui.action.plant_turnips"),begin_field,sheet_body)
	button(ColonyText.text("ui.action.work_preferences"),func()->void:show_sheet("Work","ui.sheet.work"),sheet_body)
	button(ColonyText.text("ui.action.weather_forecast"),show_weather,sheet_body)

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
	button(ColonyText.text("ui.action.show_me"),func()->void:_tutorial_show_me();_refresh_guidance(),guidance_actions)
	button(ColonyText.text("ui.action.skip"),func()->void:_tutorial_skip();_refresh_guidance(),guidance_actions)
	button(ColonyText.text("ui.action.hide"),func()->void:_tutorial_dismiss();_refresh_guidance(),guidance_actions)
	guidance_forecast_button=button(ColonyText.text("ui.action.food_forecast"),show_food_forecast,rows)

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
