class_name AccessibilityUITests
extends RefCounted

static func key(code: int, ctrl: bool = false) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new();event.pressed=true;event.keycode=code;event.ctrl_pressed=ctrl
	return event

static func contrast(a: Color, b: Color) -> float:
	var first: Color = a.srgb_to_linear();var second: Color = b.srgb_to_linear()
	var l1: float = first.r*0.2126+first.g*0.7152+first.b*0.0722
	var l2: float = second.r*0.2126+second.g*0.7152+second.b*0.0722
	return (maxf(l1,l2)+0.05)/(minf(l1,l2)+0.05)

static func run(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree = previous.get_tree()
	var processing: bool = previous.is_processing();var visible: bool = previous.visible
	previous.set_process(false);previous.hide()
	var root: String = "user://accessibility-ui-%d" % Time.get_ticks_usec()
	var original_size: Vector2i = tree.root.size
	var game: GameSession = load("res://scenes/game.tscn").instantiate()
	game.world=ColonyTests.world();game.runner=SimRunner.new(game.world)
	game.store.root_directory=root;game.store.select_slot(1);game.settings.path=root.path_join("settings.json")
	tree.root.add_child(game);game.close_sheet();game._tutorial_dismiss();game.set_process(false)
	menu_feedback(game,check)
	await menu_lifetime(game,check)
	var initial: String = game.world.canonical_hash()
	for state in ["normal","hover","pressed","disabled"]:
		var text: String = {"normal":"font_color","hover":"font_hover_color","pressed":"font_pressed_color","disabled":"font_disabled_color"}[state]
		var ratio: float = contrast(game.theme.get_color(text,"Button"),game.theme.get_stylebox(state,"Button").bg_color)
		check.call("SETTINGS/UI_actual_%s_button_text_contrast_at_least_4_5" % state,ratio>=4.5,"%.3f:1" % ratio)
	var body_ratio: float = contrast(game.theme.get_color("font_color","Label"),game.theme.get_stylebox("panel","PanelContainer").bg_color)
	check.call("SETTINGS/UI_actual_body_text_contrast_at_least_4_5",body_ratio>=4.5,"%.3f:1" % body_ratio)
	game.show_accessibility();await tree.process_frame
	game.sheet_body.find_child("Setting_reduced_motion",true,false).pressed.emit();await tree.process_frame
	game.sheet_body.find_child("Setting_high_contrast",true,false).pressed.emit();await tree.process_frame
	game.sheet_body.find_child("Setting_inspector_pause",true,false).pressed.emit();await tree.process_frame
	check.call("SETTINGS/UI_toggles_apply_without_modifying_campaign",game.view.reduced_motion and game.view.high_contrast and game.settings.values.inspector_pause and game.world.canonical_hash()==initial)
	game.close_sheet();game.set_speed(2);game.select_citizen(1)
	check.call("SETTINGS/UI_inspector_pause_preserves_previous_speed",game.runner.speed==0 and game.runner.previous_speed==2)
	game.close_inspector();game.show_accessibility()
	var choices: Array = game.sheet_body.find_children("*","CycleChoiceButton",true,false)
	check.call("SETTINGS/UI_reopened_graphics_caption_matches_saved_balanced_choice",game.settings.values.quality=="Balanced" and choices[0].selected==1 and choices[0].text=="Balanced  >")
	var selection_events: Array=[0]
	choices[0].item_selected.connect(func(_index:int)->void:selection_events[0]+=1)
	choices[0].selected=2
	check.call("SETTINGS/UI_programmatic_choice_updates_caption_without_user_action_or_setting_write",choices[0].text=="Smooth  >" and selection_events[0]==0 and game.settings.values.quality=="Balanced" and game.world.canonical_hash()==initial)
	choices[0].selected=2;choices[0].item_selected.emit(2)
	check.call("SETTINGS/UI_smooth_sets_60fps_without_changing_simulation",Engine.max_fps==60 and game.settings.values.quality=="Smooth" and game.world.canonical_hash()==initial)
	game.show_controls();await tree.process_frame
	game.sheet_body.find_child("Bind_pause",true,false).pressed.emit()
	game._input(key(KEY_CTRL))
	check.call("KEYS/UI_modifier_alone_waits_for_the_complete_shortcut",game.listening_binding=="pause")
	game._input(key(KEY_B))
	check.call("KEYS/UI_collision_keeps_old_binding_and_names_conflict",game.listening_binding=="pause" and game.settings.values.bindings.pause==[KEY_SPACE] and game.notice.contains("Build"))
	game._input(key(KEY_R,true))
	check.call("KEYS/UI_capture_saves_shortcut_without_running_it",game.listening_binding.is_empty() and game.settings.values.bindings.pause==[KEY_R|KEY_MASK_CTRL] and game.runner.speed==0)
	game.close_sheet();game.set_speed(1)
	game.speeds.get_children()[0].grab_focus()
	game._input(key(KEY_SPACE))
	check.call("KEYS/UI_old_pause_key_stops_being_a_global_shortcut",game.runner.speed==1)
	game._input(key(KEY_R,true))
	check.call("KEYS/UI_new_pause_shortcut_works_with_button_focus",game.runner.speed==0)
	game.settings.values.bindings=ControlBindings.rebind(game.settings.values.bindings,"pan_right",KEY_K).bindings
	game.view.camera_tile=Vector2(60,60);game.view.follow_id=1
	game._unhandled_key_input(key(KEY_K))
	check.call("KEYS/UI_rebound_pan_stops_follow_and_moves_camera",game.view.follow_id==0 and game.view.camera_tile==Vector2(63,60))
	game.show_key_capture("build");game._input(key(KEY_ESCAPE))
	check.call("KEYS/UI_escape_cancels_capture_without_rebinding",game.listening_binding.is_empty() and game.settings.values.bindings.build==[KEY_B])
	game.show_controls();game.sheet_body.find_child("RestoreKeys",true,false).pressed.emit()
	check.call("KEYS/UI_restore_defaults_restores_all_primary_and_arrow_keys",game.settings.values.bindings==ControlBindings.DEFAULTS)
	var restarted: DeviceSettings = DeviceSettings.new();restarted.path=game.settings.path;restarted.load_local()
	check.call("SETTINGS/UI_preferences_and_binding_changes_survive_restart",restarted.values==game.settings.values)
	game.close_sheet();game.close_inspector();game.settings.values.inspector_pause=false
	game.settings.values.auto_pauses.low_food=true;game._apply_device_settings()
	for stack in game.world.nonempty_stacks():
		if stack.item in ["meal","berry","mushroom","turnip","grain","meat","travel_ration"]:
			game.world._record("consumed",stack.item,stack.count);stack.count=0
	game.forecast_elapsed=2.0;game.food_warning_level=0;game.set_speed(1);game.saving_disabled=true;game._process(0)
	check.call("PAUSE/UI_half_day_food_crossing_pauses_with_visible_cause",game.runner.speed==0 and game.notice.contains("runway"))
	game.set_speed(1);game._process(1.1)
	check.call("PAUSE/UI_same_low_food_warning_allows_explicit_resume",game.runner.speed==1)
	game.settings.values.auto_pauses.low_food=false;game.food_warning_level=0;game.forecast_elapsed=2.0;game._apply_device_settings();game._process(0)
	check.call("PAUSE/UI_disabled_food_pause_keeps_notice_and_time",game.runner.speed==1 and game.notice.contains("runway"))
	game.runner.pause();game.settings.values.auto_pauses.fire=false;game._apply_device_settings()
	var target: Dictionary = game.world.structures.filter(func(s:Dictionary)->bool:return s.definition=="bedroll")[0]
	ColonyFire.ignite(game.world,"structure",target.id);game.set_speed(1);game._process(0)
	check.call("PAUSE/UI_disabled_fire_pause_does_not_open_a_modal",game.runner.speed==1 and game.sheet==null and game.notice.contains("fire"))
	game.settings.values.auto_pauses.departure=false;game._apply_device_settings()
	game.world.citizens[0].departure_clock=7200;game.world.citizens[0].morale=250;game.world.citizens[0].departure_until=game.world.tick+7200;game._process(0)
	check.call("PAUSE/UI_disabled_departure_pause_keeps_named_notice_and_time",game.runner.speed==1 and game.sheet==null and game.notice.contains("Mira"))
	game.show_person(1)
	check.call("PAUSE/UI_person_exposes_exact_departure_deadline_and_recovery",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("24.0 game hours") and n.text.contains("morale 300")))
	for viewport in [Vector2i(360,640),Vector2i(640,360)]:
		tree.root.size=viewport;game.size=Vector2(viewport);game.text_scale=1.5;game._build_theme()
		for screen in [game.show_accessibility,game.show_auto_pauses,game.show_controls]:
			screen.call();await tree.process_frame;await tree.process_frame
			var actions: Array = game.sheet_body.find_children("*","Button",true,false)
			check.call("SETTINGS/UI_complete_title_visible_at_large_text_%s_%s" % [str(viewport),game.sheet_name],(not game.sheet_heading.text.is_empty() and game.sheet_heading.text==game.sheet_name) or (game.sheet_full_heading.visible and game.sheet_full_heading.text==game.sheet_name))
			check.call("SETTINGS/UI_large_text_controls_fit_%s_%s" % [str(viewport),game.sheet_name],game.sheet_body.size.x<=viewport.x and actions.all(func(entry:Button)->bool:return entry.size.x>=48 and entry.size.y>=48 and entry.get_global_rect().end.x<=viewport.x))
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				tree.root.get_texture().get_image().save_png("res://reports/settings-%s-%dx%d-150.png" % [game.sheet_name.replace(" ","-"),viewport.x,viewport.y])
	game.queue_free();await tree.process_frame
	CampaignTests.remove_tree(root);tree.root.size=original_size
	previous.visible=visible;previous.set_process(processing);previous._apply_device_settings()

static func menu_lifetime(game: GameSession, check: Callable) -> void:
	var tree: SceneTree=game.get_tree()
	game.close_sheet(false)
	await tree.process_frame;await tree.process_frame
	game._layout()
	var count: int=game.controls.size()
	var canonical: String=game.world.canonical_hash()
	for index in range(12):
		game.show_sheet(["Build","Work","People"][index%3])
		await tree.process_frame
		game.close_sheet(false)
		await tree.process_frame
	await tree.process_frame
	game._layout()
	var live: int=0
	for control in game.controls:
		if is_instance_valid(control): live+=1
	check.call("MENU/repeated_panel_use_releases_freed_button_registry_entries",live==game.controls.size() and game.controls.size()<=count,"before=%d after=%d live=%d" % [count,game.controls.size(),live])
	check.call("MENU/button_registry_cleanup_retains_live_navigation_and_world",game.nav.get_children().all(func(control:Button)->bool:return game.controls.has(control)) and game.speeds.get_children().all(func(control:Button)->bool:return game.controls.has(control)) and game.world.canonical_hash()==canonical)

static func menu_feedback(game: GameSession, check: Callable) -> void:
	var hearth: Dictionary = game.world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	for speed in [0,1,2,4]:
		game.set_speed(speed);game.show_station(hearth)
		check.call("MENU/hearth_pauses_entry_speed_%d" % speed,game.runner.speed==0)
		var close: Button = game.sheet.find_children("*","Button",true,false).filter(func(b:Button)->bool:return b.text=="Close")[0]
		close.pressed.emit()
		check.call("MENU/hearth_close_restores_exact_entry_speed_%d" % speed,game.sheet==null and game.runner.speed==speed)
		game.show_sheet("Work");game.show_research();game.show_sheet("Build");game.back()
		check.call("MENU/nested_panels_restore_original_speed_%d" % speed,game.sheet==null and game.runner.speed==speed)
		game.settings.values.inspector_pause=true
		game.select_citizen(1);game.select_citizen(2);game.close_inspector()
		check.call("MENU/switching_citizen_inspectors_keeps_original_speed_%d" % speed,game.runner.speed==speed)
		game.select_citizen(1);game.show_station(hearth);game.close_sheet()
		check.call("MENU/inspector_to_station_preserves_original_speed_%d" % speed,game.runner.speed==speed)
		game.settings.values.inspector_pause=false
	game.set_speed(4);game.show_station(hearth)
	var pause: Button = game.sheet.find_children("*","Button",true,false).filter(func(b:Button)->bool:return b.text=="Pause")[0]
	pause.pressed.emit();game.close_sheet()
	check.call("MENU/explicit_panel_pause_cancels_auto_resume",game.runner.speed==0)
	game.set_speed(2);game.show_sheet("Work");game._shortcut("pause");game.close_sheet()
	check.call("MENU/explicit_keyboard_pause_cancels_auto_resume",game.runner.speed==0)
	game.set_speed(4);game.show_sheet("Build");game.show_sheet("Work");game.suspend();game.resume_from_background();game.close_sheet()
	check.call("MENU/background_return_cancels_panel_auto_resume",game.runner.speed==0)
	game.set_speed(4);game.show_station(hearth);game._storage_failed("Controlled menu storage failure");game.close_sheet()
	check.call("MENU/storage_error_close_keeps_game_paused",game.runner.speed==0)
	game.storage_error="";game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
	game.set_speed(4);game.show_sheet("Work");game._replace_world(ColonyTests.world());game.close_sheet()
	check.call("MENU/world_replacement_cancels_panel_auto_resume",game.runner.speed==0)
	game.show_sheet("Build")
	var buildings: Array = game.sheet_body.find_children("*","Button",true,false).map(func(b:Button)->String:return b.text)
	var hidden: bool = true;var available: bool = true
	for definition in game.world.definitions.buildings.values():
		if not definition.buildable: continue
		var present: bool = buildings.any(func(text:String)->bool:return text.begins_with(definition.id.capitalize()+" | "))
		if definition.unlock=="initial": available=available and present
		else: hidden=hidden and not present
	check.call("BUILD/menu_shows_initial_buildings_and_hides_every_locked_structure",available and hidden)
	game.world.researched.append("masonry");game.show_sheet("Build")
	check.call("BUILD/stone_path_appears_when_masonry_is_researched",game.sheet_body.find_children("*","Button",true,false).any(func(b:Button)->bool:return b.text.begins_with("stone_path".capitalize()+" | ")))
	game.show_research()
	check.call("BUILD/research_keeps_future_unlocks_discoverable",game.sheet_body.find_children("*","Label",true,false).any(func(l:Label)->bool:return l.text.begins_with("Unlocks: ")))
	game.close_sheet();game._replace_world(ColonyTests.world());game._tutorial_dismiss()
	game.show_work_preferences(1)
	var hauling: Button = game.sheet_body.find_children("*","Button",true,false).filter(func(b:Button)->bool:return b.text=="Hauling: Last")[0]
	check.call("HAUL/UI_default_last_and_fallback_rule_are_visible",hauling!=null and game.sheet_body.find_children("*","Label",true,false).any(func(l:Label)->bool:return l.text.contains("Hauling at Last happens only after other feasible work")))
	hauling.pressed.emit()
	check.call("HAUL/UI_can_raise_one_resident_to_normal_while_paused",hauling.text=="Hauling: Normal (pending)" and game.world.citizens[0].preferences.Hauling==1 and game.world.pending_commands.size()==1)
	game.world.step();game.show_work_preferences(1)
	check.call("HAUL/UI_explicit_priority_applies_and_reopens_as_normal",game.world.citizens[0].preferences.Hauling==2 and game.sheet_body.find_children("*","Button",true,false).any(func(b:Button)->bool:return b.text=="Hauling: Normal"))
	game.close_sheet();game._replace_world(ColonyTests.world());game._tutorial_dismiss()
