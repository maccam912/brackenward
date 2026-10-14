class_name AudioUITests
extends RefCounted

static func touch(tree: SceneTree, point: Vector2, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=pressed
	Input.parse_input_event(event);await tree.process_frame

static func drag(tree: SceneTree, point: Vector2, relative: Vector2) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new();event.index=0;event.position=point;event.relative=relative
	Input.parse_input_event(event);await tree.process_frame

static func run(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree = previous.get_tree()
	var processing: bool = previous.is_processing();var visible: bool = previous.visible
	var original_size: Vector2i = tree.root.size
	previous.set_process(false);previous.hide();tree.root.size=Vector2i(960,600)
	var root: String = "user://audio-ui-%d" % Time.get_ticks_usec()
	var game: GameSession = load("res://scenes/game.tscn").instantiate()
	game.world=ColonyTests.world();game.runner=SimRunner.new(game.world)
	game.store.root_directory=root;game.store.select_slot(1);game.settings.path=root.path_join("settings.json")
	tree.root.add_child(game);game.close_sheet();game._tutorial_dismiss();game.set_process(false)
	await tree.process_frame;await tree.process_frame
	var audio: ColonyAudio = game.soundscape
	var canonical: String = game.world.canonical_hash()
	check.call("AUDIO/UI_has_twelve_reused_effect_players_and_three_streaming_music_players",audio.voices.size()==12 and audio.music_players.size()==3 and audio.voices.all(func(p:AudioStreamPlayer)->bool:return p.max_polyphony==1 and p.playback_type==AudioServer.PLAYBACK_TYPE_STREAM))
	check.call("AUDIO/UI_graceful_close_overrides_immediate_engine_autoquit",not tree.auto_accept_quit)
	audio.stop_all()
	for index in range(12): audio.plan.request("ambient_wind",0,12,true,"",0.1)
	audio._sync_voices()
	audio.cue("cue_critical",3,"",1)
	check.call("AUDIO/UI_actual_critical_stream_replaces_ambient_within_twelve_players",audio.voices.filter(func(p:AudioStreamPlayer)->bool:return p.playing).size()==12 and audio.voices[0].stream==ColonyAudioLibrary.stream("cue_critical"))
	check.call("AUDIO/UI_critical_signal_ducks_lower_priority_effects",audio.voices[1].volume_db<-25 and is_zero_approx(audio.voices[0].volume_db))
	check.call("AUDIO/UI_audio_observation_and_mixing_never_mutate_saved_world",game.world.canonical_hash()==canonical)
	audio.stop_all();audio.clock_us=Time.get_ticks_usec()-500000
	audio.cue("ui_select");audio._process(0.5)
	check.call("AUDIO/UI_new_cue_survives_a_preceding_slow_frame",audio.plan.slots.any(func(s:Dictionary)->bool:return s.get("kind")=="ui_select") and audio.voices.any(func(p:AudioStreamPlayer)->bool:return p.playing and p.stream==ColonyAudioLibrary.stream("ui_select")))
	game.show_audio_settings();await tree.process_frame;await tree.process_frame
	var ui: TouchVolumeSlider = game.sheet_body.get_node("Volume_ui")
	ui.value=0;ui.drag_ended.emit(true)
	check.call("AUDIO/UI_interface_volume_is_independent_and_mutes_new_ui_sounds",is_zero_approx(game.settings.values.audio.ui) and game.settings.values.audio.effects==0.6 and game.settings.values.audio.music==0.35 and not audio.cue("ui_select") and AudioServer.is_bus_mute(AudioServer.get_bus_index(ColonyAudio.UI_BUS)))
	ui.value=35;ui.drag_ended.emit(true)
	var restarted: DeviceSettings = DeviceSettings.new();restarted.path=game.settings.path;restarted.load_local()
	check.call("AUDIO/UI_volume_changes_verify_and_survive_restart",is_equal_approx(restarted.values.audio.ui,0.35))
	game.settings.values.audio.master=0;game._apply_device_settings()
	check.call("AUDIO/UI_master_mute_covers_music_effects_and_interface",AudioServer.is_bus_mute(AudioServer.get_bus_index(ColonyAudio.ROOT_BUS)) and not audio.cue("cue_critical",3) and audio.music_players.values().all(func(p:AudioStreamPlayer)->bool:return not p.playing))
	game.settings.values.audio=DeviceSettings.audio_defaults();game._apply_device_settings();game.close_sheet()
	game._submit("food_policy",{"enabled":true});game.world.step();game._process(0)
	check.call("AUDIO/UI_accepted_real_command_plays_confirmation",audio.history.any(func(e:Dictionary)->bool:return e.kind=="ui_confirm"))
	game._submit("build",{"definition":"wood_wall","x":-1,"y":-1,"rotation":0});game.world.step();game._process(0)
	check.call("AUDIO/UI_rejected_real_command_has_error_sound_and_reason",game.notice.contains("rejected") and audio.history.any(func(e:Dictionary)->bool:return e.kind=="ui_error"))
	game.settings.values.audio.effects=0;game.settings.values.auto_pauses.low_food=false;game._apply_device_settings()
	for stack in game.world.nonempty_stacks():
		if game.world.definitions.items[stack.item].fullness>0: game.world._record("consumed",stack.item,stack.count);stack.count=0
	var events: int = audio.history.size()
	game.forecast_elapsed=2;game.food_warning_level=0;game.saving_disabled=true;game._process(0)
	check.call("AUDIO/UI_muted_warning_keeps_the_same_visible_food_notice",game.notice.contains("runway") and audio.history.size()==events)
	game.settings.values.audio=DeviceSettings.audio_defaults();game._apply_device_settings()
	game._replace_world(ColonyTests.world());game.close_sheet();game.saving_disabled=true
	game.view.tile_size=16;game.view.center_camera(Vector2(65.5,65.5));game._layout()
	await tree.process_frame;await tree.process_frame
	var far: Vector2i = Vector2i(78,65)
	check.call("AUDIO/UI_visible_tiles_beyond_twelve_are_silent",Rect2(Vector2.ZERO,game.view.size).has_point(game.view.tile_to_screen(Vector2(far)+Vector2.ONE*0.5)) and not audio.nearby(far,12) and audio.nearby(Vector2i(77,65),12))
	var door: Dictionary = game.world._structure("door",Vector2i(66,65),0)
	var person: Dictionary = game.world.citizens[0]
	person.x=66;person.edge_x=66;game.world.tick+=1;audio.observe()
	person.x=67;person.edge_x=67;game.world.tick+=1;audio.observe()
	check.call("AUDIO/UI_real_door_geometry_emits_open_and_close_on_passage",audio.history.any(func(e:Dictionary)->bool:return e.kind=="door_open") and audio.history.any(func(e:Dictionary)->bool:return e.kind=="door_close") and game.world.door_tiles.get(Vector2i(66,65))==door.id)
	audio.cue("ui_confirm");var before_suspend: int = audio.history.size();var tick: int = game.world.tick
	game.suspend()
	check.call("AUDIO/UI_backgrounding_stops_every_player_immediately",audio.suspended and audio.voices.all(func(p:AudioStreamPlayer)->bool:return not p.playing) and audio.music_players.values().all(func(p:AudioStreamPlayer)->bool:return not p.playing) and audio.plan.slots.all(func(s:Dictionary)->bool:return s.is_empty()))
	check.call("AUDIO/UI_background_cues_are_discarded",not audio.cue("ui_error") and audio.history.size()==before_suspend)
	game.resume_from_background();audio.observe()
	check.call("AUDIO/UI_return_is_paused_without_sound_or_time_backlog",game.runner.speed==0 and game.world.tick==tick and audio.history.size()==before_suspend and not audio.suspended)
	await sliders(game,check)
	check.call("AUDIO/UI_fixture_releases_streaming_playbacks_before_teardown",await audio.drain())
	game.queue_free();await tree.process_frame;await tree.process_frame
	CampaignTests.remove_tree(root);tree.root.size=original_size
	previous.visible=visible;previous.set_process(processing);previous._apply_device_settings()

static func sliders(game: GameSession, check: Callable) -> void:
	var tree: SceneTree = game.get_tree()
	for viewport in [Vector2i(360,640),Vector2i(640,360)]:
		tree.root.size=viewport;game.size=Vector2(viewport);game.text_scale=1.5;game._build_theme();game.close_sheet();game.show_audio_settings()
		await tree.process_frame;await tree.process_frame
		var ranges: Array = game.sheet_body.find_children("Volume_*","HSlider",true,false)
		check.call("AUDIO/UI_four_sliders_have_48dp_targets_at_large_text_%s" % str(viewport),ranges.size()==4 and ranges.all(func(slider:HSlider)->bool:return slider.size.y>=48 and slider.get_global_rect().end.x<=viewport.x))
		var master: TouchVolumeSlider = game.sheet_body.get_node("Volume_master")
		var scroll: TouchScrollContainer = game.sheet_body.get_parent()
		scroll.ensure_control_visible(master);await tree.process_frame;await tree.process_frame
		var point: Vector2 = master.get_global_rect().get_center()
		var original: float = master.value
		await touch(tree,point,true)
		check.call("AUDIO/UI_touch_press_waits_for_tap_or_drag_intent_%s" % str(viewport),is_equal_approx(master.value,original))
		await drag(tree,point+Vector2(1,-48),Vector2(1,-48));await touch(tree,point+Vector2(1,-48),false)
		check.call("AUDIO/UI_vertical_swipe_scrolls_without_changing_volume_%s" % str(viewport),is_equal_approx(master.value,original) and scroll.scroll_vertical>0)
		scroll.ensure_control_visible(master);await tree.process_frame;await tree.process_frame
		point=master.get_global_rect().get_center()
		var scroll_before: int = scroll.scroll_vertical
		await touch(tree,point,true);await drag(tree,point+Vector2(70,12),Vector2(70,12));await touch(tree,point+Vector2(70,12),false)
		check.call("AUDIO/UI_horizontal_drag_locks_slider_despite_vertical_finger_noise_%s" % str(viewport),not is_equal_approx(master.value,original) and scroll.scroll_vertical==scroll_before)
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			tree.root.get_texture().get_image().save_png("res://reports/audio-settings-%dx%d-150.png" % [viewport.x,viewport.y])
