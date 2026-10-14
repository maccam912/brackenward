class_name TutorialUITests
extends RefCounted

static func run(game: GameSession, check: Callable) -> void:
	game._replace_world(ColonyTests.world())
	game.settings.values.tutorials[game.world.session_id]=ColonyTutorial.initial_state()
	game.close_sheet()
	var original: String = game.world.canonical_hash()
	game._tutorial_begin()
	var state: Dictionary = game._tutorial_state()
	check.call("TUTORIAL/UI_begin_is_paused_and_device_local",game.runner.speed==0 and game.tutorial_tick().id=="follow" and game.world.canonical_hash()==original)
	game._tutorial_show_me()
	check.call("TUTORIAL/UI_follow_show_me_selects_real_resident",game.selected==1 and game.world.pending_commands.is_empty())
	game._tutorial_action("follow",{"citizen":1})
	game._tutorial_skip()
	check.call("TUTORIAL/UI_skip_keeps_lesson_incomplete",state.skipped.has("forage") and not state.completed.has("forage"))
	game._tutorial_show_me()
	check.call("TUTORIAL/UI_lodge_show_me_previews_without_orders",game.placement_kind=="lodge" and game.placement.visible and ColonyConstruction.lodge_error(game.world,game.view.preview_start).is_empty() and game.world.pending_commands.is_empty() and game.world.jobs.is_empty())
	check.call("TUTORIAL/UI_show_me_uses_revalidated_guidance_suggestion",game.tutorial_suggestions.get("lodge")==[game.view.preview_start.x,game.view.preview_start.y] and game.tutorial_suggestions.get("world")==game.world.get_instance_id())
	game.cancel_placement()
	ColonyTutorial.replay(state,"field");game._tutorial_show_me()
	check.call("TUTORIAL/UI_field_show_me_is_exactly_eight_tiles",game.placement_kind=="field" and game.view.preview_tiles().size()==8 and game.world.pending_commands.is_empty())
	game.cancel_placement()
	ColonyTutorial.replay(state,"cook");game._tutorial_show_me()
	check.call("TUTORIAL/UI_hearth_inspector_explains_real_recipe",state.visited.has("hearth") and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("allowed food units")))
	game.show_food_forecast()
	check.call("TUTORIAL/UI_forecast_has_daily_demand_and_harvest",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("8 meal portions/day") and n.text.contains("No planted crops")) and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("four raw food")))
	for node in game.sheet_body.get_children():
		if node is Button and node.text=="Pin forecast on map": node.pressed.emit();break
	check.call("TUTORIAL/UI_pin_forecast_uses_no_resources_or_commands",state.forecast_pinned and state.completed.has("forecast") and game.world.canonical_hash()==original and game.world.pending_commands.is_empty())
	game.show_tutorials()
	check.call("TUTORIAL/UI_lessons_list_distinguishes_skipped_from_complete",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Bring food home - Skipped") and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Meet Mira - Completed"))
	ColonyTutorial.replay(state,"follow");game.tutorial_tick()
	check.call("TUTORIAL/UI_completed_lesson_replay_survives_refresh",state.active=="follow" and not game.tutorial_tick().is_empty())
	game._tutorial_dismiss();game.close_sheet()
	check.call("TUTORIAL/UI_dismiss_hides_prompt_without_erasing_history",game.tutorial_tick().is_empty() and state.completed.has("follow") and state.skipped.has("forage"))
	game.world.researched.append("farming")
	ColonyAgriculture.designate(game.world,{"crop":"flax","tiles":[Vector2i(80,70)]})
	game.world.fields[-1].planted=true;game.world.fields[-1].ripe_tick=game.world.tick
	check.call("TUTORIAL/UI_nonfood_crops_never_count_as_future_food",game._tutorial_harvest_text().begins_with("No planted crops"))
	loaded_alerts(game,check)

static func loaded_alerts(game: GameSession, check: Callable) -> void:
	game.close_sheet();game.select_citizen(1)
	game.seen_fire_alert=99;game.seen_defense_alert=99;game.seen_region_alert=99;game.seen_opportunity_id=999999
	game.food_warning_level=3;game.charter_epilogue_session=game.world.session_id
	var world: ColonyWorld = ColonyTests.world()
	var wall: Dictionary = world._structure("wood_wall",Vector2i(74,54),0)
	ColonyFire.ignite(world,"structure",wall.id)
	game._replace_world(world)
	check.call("SAVE/UI_adoption_clears_old_selection_and_warning_counters",game.selected==0 and game.inspector==null and game.seen_region_alert==-1 and game.seen_opportunity_id==0 and game.food_warning_level==0 and game.charter_epilogue_session.is_empty() and game.tutorial_suggestions.is_empty())
	game._process(0.0)
	check.call("SAVE/UI_loaded_fire_reopens_even_after_higher_prior_alert_count",game.sheet_name=="Fire and water" and game.runner.speed==0)
	world=ColonyTests.world();DefenseTests.raid(world)
	game.seen_defense_alert=99;game._replace_world(world);game._process(0.0)
	check.call("SAVE/UI_loaded_raid_reopens_even_after_higher_prior_alert_count",game.sheet_name=="Defense" and game.runner.speed==0,game.sheet_name)
	game._replace_world(ColonyTests.world());game.close_sheet()
