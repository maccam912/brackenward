class_name AudioTests
extends RefCounted

static func run(check: Callable) -> void:
	var plan: ColonySoundPlan = ColonySoundPlan.new()
	for index in range(12): plan.request("ambient_%d" % index,0,12,true)
	var critical: int = plan.request("critical",3,3)
	check.call("AUDIO/critical_replaces_oldest_ambient_without_a_thirteenth_voice",critical==0 and plan.slots.size()==12 and plan.slots.filter(func(s:Dictionary)->bool:return not s.is_empty()).size()==12 and plan.slots[0].kind=="critical")
	plan.reset()
	for index in range(12): plan.request("critical_%d" % index,3,3)
	check.call("AUDIO/nearby_work_cannot_steal_a_critical_voice",plan.request("work",1,1)<0 and plan.slots.all(func(s:Dictionary)->bool:return s.priority==3))
	plan.advance(3.01)
	check.call("AUDIO/expired_voices_release_capacity",plan.slots.all(func(s:Dictionary)->bool:return s.is_empty()) and plan.request("work",1,1)==0)
	plan.reset()
	var allowed: int = 0
	for index in range(8):
		if plan.request("footstep_%d" % (index%5),1,0.1,false,"footstep")>=0: allowed+=1
	check.call("AUDIO/variants_share_the_three_per_second_work_limit",allowed==3 and plan.repeats.footstep.size()==3)
	plan.advance(1.0)
	check.call("AUDIO/work_limit_reopens_after_the_exact_window",plan.request("footstep_0",1,0.1,false,"footstep")>=0 and plan.repeats.footstep.size()==1)
	plan.reset();plan.music("day");plan.advance(4)
	check.call("AUDIO/initial_music_fades_in_over_four_seconds",is_equal_approx(plan.weights.day,1) and is_zero_approx(plan.weights.night))
	plan.music("night");plan.advance(2)
	check.call("AUDIO/day_night_crossfade_has_both_tracks_at_halfway",is_equal_approx(plan.weights.day,0.5) and is_equal_approx(plan.weights.night,0.5))
	plan.music("tension");plan.advance(2)
	check.call("AUDIO/interrupted_crossfade_preserves_all_current_weights",is_equal_approx(plan.weights.day,0.25) and is_equal_approx(plan.weights.night,0.25) and is_equal_approx(plan.weights.tension,0.5))
	plan.music("day");plan.advance(4)
	check.call("AUDIO/danger_resolves_over_eight_seconds_without_a_linger_delay",is_equal_approx(plan.weights.day,0.625) and is_equal_approx(plan.weights.tension,0.25) and plan.fade_seconds==8)
	plan.advance(4)
	check.call("AUDIO/resolved_music_has_one_full_weight_and_no_residual_tracks",is_equal_approx(plan.weights.day,1) and is_zero_approx(plan.weights.night) and is_zero_approx(plan.weights.tension))
	plan.request("work",1,2,false,"work");plan.reset()
	check.call("AUDIO/reset_clears_pending_voices_rate_history_and_fades",plan.slots.all(func(s:Dictionary)->bool:return s.is_empty()) and plan.repeats.is_empty() and plan.target.is_empty())
	for theme in ["day","night","tension"]:
		var stream: AudioStreamOggVorbis = ColonyAudioLibrary.stream("music_"+theme)
		check.call("AUDIO/original_%s_is_a_ninety_second_engine_decodable_loop" % theme,stream.loop and absf(stream.get_length()-90.0)<0.001)
	for kind in ["rain","river","wind","fire"]:
		var stream: AudioStreamOggVorbis = ColonyAudioLibrary.stream("ambient_"+kind)
		check.call("AUDIO/original_%s_ambience_is_a_twelve_second_loop" % kind,stream.loop and absf(stream.get_length()-12.0)<0.001)
	check.call("AUDIO/all_approved_cues_and_effects_are_short_nonlooping_streams",ColonyAudioLibrary.IDS.filter(func(id:String)->bool:return not id.begins_with("ambient_") and not id.begins_with("music_")).all(func(id:String)->bool:
		var stream: AudioStreamOggVorbis = ColonyAudioLibrary.stream(id)
		return not stream.loop and stream.get_length()>0 and stream.get_length()<=4))
	check.call("AUDIO/original_cc0_license_bytes_are_retained",FileAccess.get_sha256("res://assets/licenses/kenney_interface_sounds.txt")=="f7966c773bbed0eca6a9c75081c44a178b38eae112724dbb5fdfbd4192d118a9" and FileAccess.get_sha256("res://assets/licenses/kenney_rpg_audio.txt")=="7dc7dac2e06d170a6f91bc58c2a3c1a35a9ab9c711b893a52539eb709826312d")
	var world: ColonyWorld = ColonyTests.world()
	var raid: Dictionary = ColonyDefense.announce(world,2)
	check.call("AUDIO/announced_amber_raid_does_not_start_tension",ColonyAudioLibrary.theme_for(world)=="day")
	raid.due=world.tick;ColonyDefense.arrive(world,raid)
	var canonical: String = world.canonical_hash()
	check.call("AUDIO/actual_hostile_arrival_selects_tension_without_mutating_state",ColonyAudioLibrary.theme_for(world)=="tension" and world.canonical_hash()==canonical)
	for enemy in world.defense_state.enemies: enemy.state="Retreating"
	check.call("AUDIO/retreat_ends_danger_and_selects_normal_music",ColonyAudioLibrary.theme_for(world)=="day")
	world.tick=18*300
	check.call("AUDIO/evening_selects_night_music",ColonyAudioLibrary.theme_for(world)=="night")
	settings(check)

static func settings(check: Callable) -> void:
	var folder: String = "user://audio-settings-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(folder)
	var preferences: DeviceSettings = DeviceSettings.new();preferences.path=folder.path_join("settings.json")
	check.call("AUDIO/default_volume_mix_and_haptics_match_the_design",preferences.values.audio=={"master":0.8,"music":0.35,"effects":0.6,"ui":0.6} and not preferences.values.haptics)
	preferences.values.audio={"master":0.0,"music":0.15,"effects":0.25,"ui":1.0};preferences.values.haptics=true
	var error: String = preferences.save_local()
	var loaded: DeviceSettings = DeviceSettings.new();loaded.path=preferences.path;loaded.load_local()
	check.call("AUDIO/all_four_levels_and_tactile_preference_roundtrip",error.is_empty() and loaded.values==preferences.values,error)
	var legacy: Dictionary = preferences.values.duplicate(true);legacy.erase("audio");legacy.erase("haptics");legacy.erase("quiet_sleep_speed");legacy.schema_version=3
	legacy.reduced_motion=true;legacy.high_contrast=true;legacy.quality="Smooth";legacy.auto_pauses.fire=false
	legacy.bindings=ControlBindings.rebind(legacy.bindings,"pause",KEY_R|KEY_MASK_CTRL).bindings
	var file: FileAccess = FileAccess.open(preferences.path,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	var original: PackedByteArray = FileAccess.get_file_as_bytes(preferences.path)
	loaded=DeviceSettings.new();loaded.path=preferences.path;loaded.load_local()
	var expected: Dictionary = legacy.duplicate(true);expected.schema_version=DeviceSettings.VERSION;expected["audio"]=DeviceSettings.audio_defaults();expected["haptics"]=false;expected["quiet_sleep_speed"]=true
	check.call("AUDIO/schema_three_preserves_controls_cameras_and_lessons",loaded.values==expected and FileAccess.get_file_as_bytes(preferences.path)==original)
	for value in [-0.1,1.1,true,"0.5"]:
		var malformed: Dictionary = preferences.values.duplicate(true);malformed.audio.music=value
		check.call("AUDIO/invalid_level_rejected_%s" % str(value),not preferences._valid(malformed))
	CampaignTests.remove_tree(folder)
