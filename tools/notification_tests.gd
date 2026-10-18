class_name NotificationTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	var notifications: ColonyNotifications=ColonyNotifications.new();notifications.reset(world)
	world.production_state.project="storecraft";world.production_state.queue=["farming"]
	ColonyProduction.add_insight(world,world.definitions.research.storecraft.points+world.definitions.research.farming.points)
	var canonical: String=world.canonical_hash()
	notifications.observe(world);notifications.observe(world)
	check.call("UPDATES/insight_cascade_announces_each_discovery_once",notifications.pending().map(func(e:Dictionary)->String:return e.project)==["storecraft","farming"])
	notifications.dismiss()
	check.call("UPDATES/dismiss_reveals_next_and_keeps_history",notifications.pending().size()==1 and notifications.pending()[0].project=="farming" and notifications.entries.size()==2)
	check.call("UPDATES/observing_and_dismissing_preserve_simulation",world.canonical_hash()==canonical)
	var loaded: ColonyWorld=ColonyCodec.decode(ColonyCodec.encode(world)).world
	notifications.observe(loaded)
	check.call("UPDATES/loading_does_not_reannounce_old_research_or_keep_other_campaign_notices",notifications.entries.is_empty())
	var desk: Dictionary=loaded._structure("research_desk",Vector2i(80,80),0)
	loaded.production_state.project="weaving"
	check.call("UPDATES/bench_without_worker_is_idle",ColonyNotifications.benches(loaded)[0].state=="waiting")
	var worker: Dictionary=loaded.citizens[0]
	var job: Dictionary=loaded._job("research","Research","Study",desk.id,Vector2i(desk.x,desk.y),100000)
	job.definition="weaving";job.worker=worker.id;worker.job=job.id;job.state="Moving"
	check.call("UPDATES/walking_worker_is_not_shown_as_studying",ColonyNotifications.benches(loaded)[0].state=="traveling")
	job.state="Working"
	check.call("UPDATES/working_worker_is_shown_as_studying",ColonyNotifications.benches(loaded)[0].state=="working")
	desk.cooking=false
	check.call("UPDATES/suspended_bench_is_idle_even_before_stale_job_releases",ColonyNotifications.benches(loaded)[0].state=="suspended")
	desk.cooking=true;job.state="Complete";worker.job=0;loaded.production_state.project=""
	check.call("UPDATES/idle_bench_invites_project_selection",ColonyNotifications.benches(loaded)[0].state=="choose")
	desk.health=0
	check.call("UPDATES/destroyed_bench_does_not_count_as_idle",ColonyNotifications.benches(loaded).is_empty())

static func ui(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree=previous.get_tree()
	var processing: bool=previous.is_processing();var visible: bool=previous.visible
	previous.set_process(false);previous.hide()
	var original_size: Vector2i=tree.root.size
	var directory: String="user://notification-ui-%d" % Time.get_ticks_usec()
	var game: GameSession=load("res://scenes/game.tscn").instantiate()
	game.world=ColonyTests.world();game.runner=SimRunner.new(game.world)
	game.store.root_directory=directory;game.store.select_slot(1);game.settings.path=directory.path_join("settings.json")
	tree.root.add_child(game);game.set_process(false);game.close_sheet(false);game._tutorial_dismiss()
	game.world._structure("research_desk",Vector2i(80,80),0)
	game._refresh_clock();game._refresh_guidance()
	game.set_speed(2);game._refresh_notifications()
	check.call("UPDATES/UI_idle_indicator_does_not_pause_or_repeat_notifications",game.runner.speed==2 and game.notifications.pending().is_empty() and game.notification_panel.research_label.text.contains("Research idle"))
	game.world.production_state.insight=1000
	game.world.production_state.progress.storecraft=(game.world.definitions.research.storecraft.points-1000)*1000
	game.world.queue_command("research_select",{"definition":"storecraft"})
	var camera: Vector2=game.view.camera_center()
	var zoom: float=game.view.tile_size
	game._process(0.05);game._refresh_notifications()
	var canonical: String=game.world.canonical_hash()
	check.call("UPDATES/UI_completion_queues_without_pause_or_overwriting_status",game.runner.speed==2 and game.notifications.pending().size()==1 and game.notification_panel.message.text.contains("Storecraft research complete"))
	check.call("UPDATES/UI_completion_preserves_camera_and_zoom",game.view.camera_center().is_equal_approx(camera) and game.view.tile_size==zoom)
	for viewport in [Vector2i(360,640),Vector2i(390,844),Vector2i(640,360),Vector2i(960,600)]:
		for scale_factor in [1.0,1.5]:
			tree.root.size=viewport;game.size=Vector2(viewport);game.text_scale=scale_factor;game.test_insets=Vector4(8,12,8,12)
			game._build_theme();game._refresh_notifications();game._layout()
			await tree.process_frame;await tree.process_frame;await tree.process_frame
			var panel: NotificationPanel=game.notification_panel
			var fits: bool=panel.visible and panel.position.x>=0 and panel.position.x+panel.size.x<=game.content.size.x and panel.position.y+panel.size.y<=game.speeds.position.y
			var actions: Array=panel.find_children("*","Button",true,false)
			fits=fits and actions.all(func(b:Button)->bool:return not b.is_visible_in_tree() or (b.size.x>=48 and b.size.y>=48 and panel.get_global_rect().encloses(b.get_global_rect())))
			check.call("UPDATES/UI_card_and_targets_fit_%dx%d_%d" % [viewport.x,viewport.y,int(scale_factor*100)],fits,str([panel.get_rect(),game.speeds.position]))
			check.call("UPDATES/UI_guidance_does_not_cover_updates_%dx%d_%d" % [viewport.x,viewport.y,int(scale_factor*100)],not game.guidance_panel.visible or not panel.get_global_rect().intersects(game.guidance_panel.get_global_rect()))
			if DisplayServer.get_name()!="headless" and viewport in [Vector2i(390,844),Vector2i(640,360)]:
				await RenderingServer.frame_post_draw
				check.call("UPDATES/UI_capture_%dx%d_%d" % [viewport.x,viewport.y,int(scale_factor*100)],tree.root.get_texture().get_image().save_png("res://reports/notifications-%dx%d-%d.png" % [viewport.x,viewport.y,int(scale_factor*100)])==OK)
	game.notification_panel.card.get_child(1).get_child(0).pressed.emit()
	check.call("UPDATES/UI_notice_action_opens_research_and_acknowledges_only_the_notice",game.sheet_route=="Research" and game.notifications.pending().is_empty() and game.runner.speed==0)
	game.close_sheet();game.notifications.entries[0].read=false;game._refresh_notifications()
	game.notification_panel.research_button.pressed.emit()
	check.call("UPDATES/UI_idle_indicator_opens_research",game.sheet_route=="Research" and game.runner.speed==0)
	game.close_sheet()
	check.call("UPDATES/UI_research_close_restores_previous_speed",game.runner.speed==2)
	game.notification_panel.card.get_child(1).get_child(1).pressed.emit()
	check.call("UPDATES/UI_dismiss_clears_card_keeps_research_status_and_speed",game.notifications.pending().is_empty() and not game.notification_panel.card.visible and game.notification_panel.research_button.visible and game.runner.speed==2)
	game.show_sheet("Journal","ui.sheet.journal")
	game.sheet_body.find_children("*","Button",true,false).filter(func(b:Button)->bool:return b.text=="Updates")[0].pressed.emit()
	check.call("UPDATES/UI_dismissed_discovery_remains_in_updates",game.sheet_route=="Updates" and game.sheet_body.find_children("*","Label",true,false).any(func(l:Label)->bool:return l.text.contains("Storecraft research complete")))
	check.call("UPDATES/UI_information_controls_preserve_authoritative_state",game.world.canonical_hash()==canonical)
	game.close_sheet(false);game._replace_world(ColonyCodec.decode(ColonyCodec.encode(game.world)).world);game._refresh_notifications()
	check.call("UPDATES/UI_loaded_colony_keeps_current_bench_status_without_old_popups",game.notifications.entries.is_empty() and game.notification_panel.research_button.visible)
	game._replace_world(ColonyTests.world());game._refresh_notifications()
	check.call("UPDATES/UI_campaign_replacement_clears_notices_and_stale_benches",game.notifications.entries.is_empty() and not game.notification_panel.visible)
	if is_instance_valid(game.soundscape): await game.soundscape.drain()
	game.queue_free();await tree.process_frame
	CampaignTests.remove_tree(directory);tree.root.size=original_size
	previous.visible=visible;previous.set_process(processing)
