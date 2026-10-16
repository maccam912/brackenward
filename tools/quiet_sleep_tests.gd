class_name QuietSleepTests
extends RefCounted

class FireWorld extends ColonyWorld:
	var fired: bool=false
	var fire_target: int=0
	func _init(catalog: Dictionary) -> void: super(catalog)
	func step() -> void:
		super.step()
		if not fired:
			fired=true;ColonyFire.ignite(self,"structure",fire_target)

static func fixture() -> ColonyWorld:
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/content5-rested-sleepers.brackenward"))
	assert(decoded.has("world"))
	var world: ColonyWorld=decoded.world
	for person in world.citizens: person.rest=300;person.rest_rem=0
	return world

static func fire_fixture() -> FireWorld:
	var source: ColonyWorld=fixture();var world: FireWorld=FireWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: world.get(field).assign(value.duplicate(true))
		elif value is Dictionary: world.set(field,value.duplicate(true))
		else: world.set(field,value)
	world.record_indexes.clear();world.reset_job_queries();world.reset_stack_queries()
	world.navigation_dirty=true;world.reachability_dirty=true;world.rooms_dirty=true
	world.fire_target=world._structure("wood_wall",Vector2i(90,80),0).id
	return world

static func run(check: Callable) -> void:
	adaptive_playback(check)
	var world: ColonyWorld=fixture();var twin: ColonyWorld=ColonyCodec.decode(ColonyCodec.encode(world)).world
	var runner: SimRunner=SimRunner.new(world);runner.set_speed(1)
	var count: int=0
	for frame in range(20): count+=runner.advance_frame(1.0/120.0)
	for index in range(count): twin.step()
	check.call("NIGHT/quiet_sleep_runs_at_twelve_times_while_preserving_selected_speed",count==80 and runner.speed==1 and runner.previous_speed==1 and runner.playback_speed()==12 and runner.sleep_fast_forward)
	check.call("NIGHT/accelerated_ticks_match_ordinary_complete_ticks_exactly",world.canonical_hash()==twin.canonical_hash() and world.invariant_errors().is_empty())
	for tier in range(3):
		for selected in [1,2,4]:
			world=fixture();runner=SimRunner.new(world);runner.set_speed(selected);runner.sleep_speed_tier=tier;runner.advance_frame(1.0/120.0)
			world.citizens[0].rest=899;world.citizens[0].rest_rem=240
			twin=ColonyCodec.decode(ColonyCodec.encode(world)).world;twin.step()
			count=runner.advance_frame(1.0/120.0)
			check.call("NIGHT/first_actual_wake_stops_at_its_exact_tick_and_restores_%dx" % selected+("" if tier==0 else "_from_%dx" % SimRunner.SLEEP_SPEED_STEPS[tier]),count==1 and world.canonical_hash()==twin.canonical_hash() and not runner.sleep_fast_forward and runner.speed==selected and runner.previous_speed==selected and runner.playback_speed()==selected and runner.accumulator==0.0)
	world=fixture();runner=SimRunner.new(world);runner.set_speed(4)
	check.call("NIGHT/frame_burst_still_has_an_eight_tick_cap",runner.advance_frame(1.0)==8)
	runner.pause();var before: String=world.canonical_hash()
	check.call("NIGHT/pause_stops_acceleration_and_all_logical_time",runner.advance_frame(600)==0 and runner.playback_speed()==0 and not runner.sleep_fast_forward and world.canonical_hash()==before and runner.accumulator==0.0)
	world=fixture();runner=SimRunner.new(world);runner.quiet_sleep_enabled=false;runner.set_speed(4)
	count=runner.advance_frame(0.025)
	check.call("NIGHT/setting_off_preserves_exact_manual_speed",count==4 and not runner.sleep_fast_forward and runner.playback_speed()==4)
	world=fixture();runner=SimRunner.new(world);runner.quiet_sleep_allowed=false;runner.set_speed(2)
	check.call("NIGHT/low_food_or_session_guard_prevents_acceleration",runner.advance_frame(0.025)==2 and not runner.sleep_fast_forward)
	world=fixture();runner=SimRunner.new(world);runner.set_speed(2);world.queue_designation([Vector2i(94,80)])
	check.call("NIGHT/new_queued_order_is_processed_at_selected_speed",runner.advance_frame(0.025)==2 and not runner.sleep_fast_forward and world.pending_commands.is_empty())
	world=fixture();runner=SimRunner.new(world);runner.set_speed(4);world.citizens[0].fullness=350
	check.call("NIGHT/hungry_sleepers_need_attention_instead_of_fast_forward",not runner._all_asleep())
	world=fixture();runner=SimRunner.new(world);world.citizens[0].downed=true
	check.call("NIGHT/downed_resident_is_not_a_quiet_sleep_case",not runner._all_asleep())
	world=fixture();runner=SimRunner.new(world);world.citizens[0].departure_until=world.tick+7200
	check.call("NIGHT/pending_departure_is_not_a_quiet_sleep_case",not runner._all_asleep())
	world=fixture();runner=SimRunner.new(world);world.weather_state.flooded.assign([Vector2i(90,80)])
	check.call("NIGHT/flooding_blocks_quiet_sleep_speed",not runner._quiet())
	world=fixture();runner=SimRunner.new(world);world.region_state.trips.append({"state":"Decision"})
	check.call("NIGHT/expedition_decision_blocks_quiet_sleep_speed",not runner._quiet())
	world=fixture();runner=SimRunner.new(world);world.opportunity_state.offers.append({"state":"Offered"})
	check.call("NIGHT/visitor_offer_blocks_quiet_sleep_speed",not runner._quiet())
	world=fixture();runner=SimRunner.new(world);ColonyPopulation.offer(world)
	check.call("NIGHT/recruitment_offer_blocks_quiet_sleep_speed",not runner._quiet())
	world=fixture();runner=SimRunner.new(world);world.trade_state.merchants.append({"state":"Entering"})
	check.call("NIGHT/merchant_arrival_blocks_quiet_sleep_speed",not runner._quiet())
	for tier in range(3):
		for pause_fire in [true,false]:
			var incident: FireWorld=fire_fixture();runner=SimRunner.new(incident);runner.auto_pauses.fire=pause_fire;runner.set_speed(4);runner.sleep_speed_tier=tier
			count=runner.advance_frame(1.0/120.0)
			check.call("NIGHT/new_real_fire_ends_boost_immediately_pause_%s" % str(pause_fire)+("" if tier==0 else "_from_%dx" % SimRunner.SLEEP_SPEED_STEPS[tier]),count==1 and not runner.sleep_fast_forward and runner.speed==(0 if pause_fire else 4) and ColonyFire.active(incident).size()==1 and incident.invariant_errors().is_empty(),str([count,runner.speed,incident.invariant_errors()]))
	world=fixture();runner=SimRunner.new(world);runner.set_speed(2)
	var clock: Dictionary={"now":0}
	runner.frame_clock=func()->int:clock.now+=9000;return clock.now
	var bounded: bool=true
	var transitions: Array=[]
	for frame in range(120):
		var tier: int=runner.sleep_speed_tier
		bounded=bounded and runner.advance_frame(0.1)==1
		if runner.sleep_speed_tier!=tier:transitions.append(runner.playback_speed())
		if runner.sleep_boost_limited:break
	check.call("NIGHT/sustained_overload_tries_8x_then_6x_before_manual_fallback",transitions==[8,6])
	check.call("NIGHT/cpu_budget_caps_each_boost_batch_and_retains_selected_speed",bounded and runner.sleep_boost_limited and runner.sleep_boost_suppressed and runner.speed==2 and runner.previous_speed==2 and not runner.sleep_fast_forward and runner.accumulator==0.0)
	check.call("NIGHT/slow_boost_falls_back_without_repeatedly_retrying",runner.advance_frame(0.025)==2 and not runner.sleep_fast_forward and runner.sleep_boost_suppressed)
	world.citizens[0].rest=900;runner.advance_frame(0.1)
	check.call("NIGHT/a_wake_clears_the_per_sleep_period_cpu_limit",not runner.sleep_boost_suppressed)
	var prototype: PrototypeWorld=PrototypeWorld.new();runner=SimRunner.new(prototype);runner.set_speed(4)
	check.call("NIGHT/prototype_uses_the_same_faster_manual_baseline",runner.advance_frame(0.025)==4 and prototype.tick==1804 and not runner.sleep_fast_forward)

static func adaptive_playback(check: Callable) -> void:
	for clock_step in [3000,4500]:
		var expected_speed: int=8 if clock_step==3000 else 6
		var world: ColonyWorld=fixture();var twin: ColonyWorld=ColonyCodec.decode(ColonyCodec.encode(world)).world
		var runner: SimRunner=SimRunner.new(world);runner.set_speed(4)
		var clock: Array=[0];runner.frame_clock=func()->int:clock[0]+=clock_step;return clock[0]
		var total: int=0
		for frame in range(1200):
			total+=runner.advance_frame(1.0/120.0)
			if runner.playback_speed()==expected_speed:break
		var stable_count: int=0;var bounded: bool=true
		for frame in range(60):
			var count: int=runner.advance_frame(1.0/120.0);stable_count+=count
			bounded=bounded and count<=(3 if clock_step==3000 else 2) and runner.playback_speed()==expected_speed
		total+=stable_count
		for tick in range(total):twin.step()
		check.call("NIGHT/adapts_to_sustainable_%dx_with_exact_ticks_and_retained_selected_speed" % expected_speed,bounded and stable_count==expected_speed*20 and runner.speed==4 and runner.previous_speed==4 and runner.sleep_fast_forward and not runner.sleep_boost_limited and not runner.sleep_boost_suppressed and world.payload()==twin.payload())
		runner.pause();runner.set_speed(4);runner.advance_frame(1.0/120.0)
		check.call("NIGHT/pausing_preserves_the_learned_%dx_sleep_tier" % expected_speed,runner.playback_speed()==expected_speed and runner.speed==4)
		world.citizens[0].rest=900;runner.advance_frame(1.0/120.0)
		check.call("NIGHT/actual_wake_resets_the_%dx_tier_for_the_next_sleep_period" % expected_speed,runner.sleep_speed_tier==0 and not runner.sleep_boost_suppressed and not runner.sleep_fast_forward and runner.speed==4)
	var world: ColonyWorld=fixture();var runner: SimRunner=SimRunner.new(world);runner.set_speed(2)
	var clock: Array=[0];runner.frame_clock=func()->int:clock[0]+=9000;return clock[0]
	for frame in range(20):runner.advance_frame(0.1)
	check.call("NIGHT/brief_backlog_does_not_downgrade_sleep_playback",runner.playback_speed()==12 and runner.sleep_speed_tier==0 and not runner.sleep_boost_limited and runner.speed==2)

static func ui(game: GameSession, check: Callable) -> void:
	var processing: bool=game.is_processing();game.set_process(false)
	var preferences: Dictionary=game.settings.values.duplicate(true)
	game._replace_world(fixture());game.close_sheet();game.close_inspector();game._tutorial_dismiss();game.saving_disabled=true
	game.settings.values.quiet_sleep_speed=true;game._apply_device_settings();game.runner.frame_clock=func()->int:return 0
	game.view.center_camera(Vector2(68,64));game.runner.set_speed(4);game._advance_frame(1.0/120.0);game._refresh_clock()
	check.call("NIGHT/UI_clock_explains_automatic_twelve_times_and_retained_speed",game.clock_label.text.ends_with("12x sleep") and game.clock_label.tooltip_text.contains("4x") and game.runner.speed==4 and game.diagnostics.samples.has("simulation_batch:12"))
	check.call("NIGHT/UI_running_sleep_does_not_claim_it_is_paused",game.notice==ColonyText.text("ui.notice.running"))
	game.runner.sleep_speed_tier=1;game._advance_frame(1.0/120.0);game._refresh_clock()
	check.call("NIGHT/UI_clock_and_diagnostics_show_actual_adaptive_speed",game.clock_label.text.ends_with("8x sleep") and game.clock_label.tooltip_text.contains("4x") and game.runner.speed==4 and game.diagnostics.samples.has("simulation_batch:8") and game._performance_report().metadata.playback_speed==8)
	await game.get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		game.get_tree().root.get_texture().get_image().save_png("res://reports/quiet-sleep-clock.png")
	game.show_sheet("Build");game.begin_build("wood_floor");game.view.preview_start=Vector2i(90,80);game.view.preview_end=game.view.preview_start;game.confirm_placement()
	check.call("NIGHT/UI_placement_restores_selected_speed_after_automatic_sleep",game.runner.speed==4 and game.world.pending_commands.size()==1 and not game.placement.visible)
	game._advance_frame(1.0/120.0);game._advance_frame(1.0/120.0)
	check.call("NIGHT/UI_quiet_sleep_can_resume_after_confirmed_order_is_processed",game.runner.speed==4 and game.runner.sleep_fast_forward and game.world.pending_commands.is_empty())
	game.show_accessibility()
	var toggle: Button=game.sheet_body.find_child("Setting_quiet_sleep_speed",true,false) as Button
	check.call("NIGHT/UI_setting_is_explicit_and_accessible",toggle is Button and toggle.custom_minimum_size.y>=48)
	toggle.pressed.emit()
	check.call("NIGHT/UI_turning_off_quiet_speed_preserves_paused_time",not game.settings.values.quiet_sleep_speed and not game.runner.quiet_sleep_enabled and game.runner.speed==0)
	game.close_sheet();game.runner.set_speed(4);game._advance_frame(1.0/120.0)
	check.call("NIGHT/UI_opt_out_runs_only_the_selected_speed",game.runner.speed==4 and game.runner.playback_speed()==4 and not game.runner.sleep_fast_forward)
	game.settings.values.quiet_sleep_speed=true;game._apply_device_settings();game.runner.frame_clock=func()->int:return 0;game._advance_frame(1.0/120.0)
	var tick: int=game.world.tick;game.suspend();game._advance_frame(600)
	check.call("NIGHT/UI_background_stops_bonus_and_every_tick",game.world.tick==tick and game.runner.speed==0 and not game.runner.sleep_fast_forward)
	game.resume_from_background();game.close_sheet();game._advance_frame(1.0)
	check.call("NIGHT/UI_return_stays_paused_without_a_bonus_backlog",game.world.tick==tick and game.runner.speed==0 and game.runner.accumulator==0.0)
	game.settings.values=preferences;game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss();game._save_settings();game.set_process(processing)
