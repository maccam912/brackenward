class_name AccessibilityTests
extends RefCounted

static func run(check: Callable) -> void:
	var root: String = "user://accessibility-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	var settings: DeviceSettings = DeviceSettings.new();settings.path=root.path_join("settings.json")
	check.call("SETTINGS/defaults_match_release_pause_graphics_and_motion_policy",settings.values.quality=="Balanced" and not settings.values.reduced_motion and not settings.values.high_contrast and not settings.values.inspector_pause and settings.values.auto_pauses.values().all(func(v:Variant)->bool:return v))
	check.call("KEYS/defaults_are_complete_and_unambiguous",ControlBindings.valid(settings.values.bindings) and ControlBindings.action_for(settings.values.bindings,KEY_W)=="pan_up" and ControlBindings.action_for(settings.values.bindings,KEY_UP)=="pan_up")
	var changed: Dictionary = ControlBindings.rebind(settings.values.bindings,"pause",KEY_R|KEY_MASK_CTRL)
	check.call("KEYS/modifier_shortcut_changes_only_one_action",changed.has("bindings") and changed.bindings.pause==[KEY_R|KEY_MASK_CTRL] and changed.bindings.pan_up==[KEY_W,KEY_UP] and ControlBindings.action_for(changed.bindings,KEY_SPACE).is_empty())
	check.call("KEYS/collision_names_the_existing_action",ControlBindings.rebind(settings.values.bindings,"pause",KEY_B).get("error","").contains("Build") and settings.values.bindings.pause==[KEY_SPACE])
	check.call("KEYS/unknown_codes_and_malformed_collections_rejected",ControlBindings.rebind(settings.values.bindings,"pause",0).has("error") and not ControlBindings.valid({}) and not ControlBindings.valid(settings.values.bindings.merged({"pause":[KEY_B]},true)) and not ControlBindings.valid(settings.values.bindings.merged({"pause":[0.5]},true)))
	settings.values.bindings=changed.bindings;settings.values.reduced_motion=true;settings.values.high_contrast=true;settings.values.inspector_pause=true;settings.values.quality="Smooth";settings.values.auto_pauses.fire=false
	var error: String = settings.save_local()
	var loaded: DeviceSettings = DeviceSettings.new();loaded.path=settings.path;loaded.load_local()
	check.call("SETTINGS/all_release_controls_survive_restart",error.is_empty() and loaded.values==settings.values,error)
	var old: Dictionary = {"schema_version":2,"text_scale":1.5,"left_handed":true,"last_slot":3,"tutorials":{"retained":ColonyTutorial.initial_state()},"cameras":[[1.5,2.5,64],[10,20,24],[30,40,16],[50,60,32],[70,80,48]]}
	var file: FileAccess = FileAccess.open(settings.path,FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	var original: PackedByteArray = FileAccess.get_file_as_bytes(settings.path)
	loaded=DeviceSettings.new();loaded.path=settings.path;loaded.load_local()
	var expected: Dictionary = DeviceSettings.defaults();expected.merge(old,true);expected.schema_version=3
	for camera in expected.cameras:
		for index in range(3): camera[index]=float(camera[index])
	check.call("SETTINGS/schema_two_preserves_every_existing_preference",loaded.values==expected and FileAccess.get_file_as_bytes(settings.path)==original)
	for bad in [settings.values.merged({"quality":"Ultra"},true),settings.values.merged({"inspector_pause":1},true),settings.values.merged({"auto_pauses":{"fire":true}},true),settings.values.merged({"future":true},true)]:
		file=FileAccess.open(settings.path,FileAccess.WRITE);file.store_string(JSON.stringify(bad));file.close()
		loaded=DeviceSettings.new();loaded.path=settings.path;loaded.load_local()
		check.call("SETTINGS/malformed_release_preferences_use_safe_defaults_%d" % bad.hash(),loaded.values==DeviceSettings.defaults())
	var world: ColonyWorld = ColonyTests.world()
	world.citizens[1].health=25;world.citizens[1].fullness=0;world.citizens[1].starving_ticks=2099
	var runner: SimRunner = SimRunner.new(world);runner.auto_pauses.downed=false;runner.set_speed(4);runner.advance_frame(1)
	check.call("PAUSE/disabled_care_pause_keeps_time_advancing_after_downing",world.citizens[1].downed and world.tick>1801 and runner.speed==4)
	world=ColonyTests.world();world.citizens[0].morale=250;world.citizens[0].departure_clock=7200;world.citizens[0].departure_until=world.tick+7200
	runner=SimRunner.new(world);runner.set_speed(1)
	check.call("PAUSE/departure_ultimatum_pauses_once_with_named_cause",runner.advance_frame(0.1)==0 and runner.speed==0 and runner.notice.contains("Mira"))
	runner.set_speed(1);runner.advance_frame(0.1)
	check.call("PAUSE/acknowledged_ultimatum_does_not_block_resume",runner.speed==1 and world.tick==1801)
	runner=SimRunner.new(world);runner.auto_pauses.departure=false;runner.set_speed(1);runner.advance_frame(0.1)
	check.call("PAUSE/disabled_departure_pause_keeps_notice_and_time_advancing",runner.speed==1 and world.tick==1802 and runner.notice.contains("Mira"))
	var sprite: CitizenSprite = CitizenSprite.new()
	world.citizens[0].edge_x=world.citizens[0].x+1;world.citizens[0].progress=5000
	var before: String = world.canonical_hash()
	sprite.animate(world,world.citizens[0],0.5,4,false,true)
	check.call("ART/reduced_motion_keeps_authoritative_movement_but_freezes_pose",sprite.pose=="walk" and sprite.animation_frame==0 and world.citizens[0].progress==5000)
	check.call("ART/presentation_animation_never_changes_saved_state",world.canonical_hash()==before)
	sprite.free();CampaignTests.remove_tree(root)
