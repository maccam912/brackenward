class_name WorkBudgetUITests
extends RefCounted

static func run(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree = previous.get_tree();var original_size: Vector2i = tree.root.size
	var processing: bool = previous.is_processing();var view_processing: bool = previous.view.is_processing();var visible: bool = previous.visible
	previous.set_process(false);previous.view.set_process(false);previous.hide()
	var world: ColonyWorld = ColonyTests.world();var tiles: Array[Vector2i] = []
	for y in range(82,102):
		for x in range(42,74): tiles.append(Vector2i(x,y))
	world.queue_command("build_area",{"definition":"wood_floor","tiles":tiles});world.step()
	var scratch: String = "user://work-budget-ui-%d" % Time.get_ticks_usec()
	var game: GameSession = load("res://scenes/game.tscn").instantiate()
	game.world=world;game.runner=SimRunner.new(world);game.store.root_directory=scratch;game.store.select_slot(1);game.settings.path=scratch.path_join("settings.json")
	tree.root.add_child(game);game.close_sheet();game._tutorial_dismiss();game.set_process(false)
	game.text_scale=1.5;game._build_theme();var before: String = world.canonical_hash();var camera_before: Vector2 = game.view.camera_center()
	for viewport in [Vector2i(360,640),Vector2i(640,360)]:
		tree.root.size=viewport;game.size=Vector2(viewport);game.work_orders_page=0;game.show_sheet("Work")
		await tree.process_frame;await tree.process_frame
		var rows: Array = game.sheet_body.find_children("WorkOrderRow*","Button",true,false)
		var total: Label = game.sheet_body.get_node("WorkOrderCounts")
		var next: Button = game.sheet_body.find_child("WorkOrdersNext",true,false)
		var scroll: ScrollContainer = game.sheet_body.get_parent()
		scroll.ensure_control_visible(next);await tree.process_frame;await tree.process_frame
		check.call("BUDGET/UI_large_queue_builds_only_one_page_%s" % str(viewport),rows.size()==32 and game.sheet_body.find_children("*","Button",true,false).size()<70 and total.text.contains("640 total") and next.size.y>=48 and next.get_global_rect().end.x<=viewport.x)
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;tree.root.get_texture().get_image().save_png("res://reports/work-order-page-%dx%d-150.png" % [viewport.x,viewport.y])
		var point: Vector2 = next.get_global_rect().get_center()
		await AudioUITests.touch(tree,point,true);await AudioUITests.touch(tree,point,false)
		check.call("BUDGET/UI_real_touch_moves_to_next_order_page_%s" % str(viewport),game.work_orders_page==1 and game.sheet_body.find_children("WorkOrderRow*","Button",true,false).size()==32)
		await tree.process_frame;await tree.process_frame
		check.call("BUDGET/UI_paging_stays_at_order_section_%s" % str(viewport),(game.sheet_body.get_parent() as ScrollContainer).scroll_vertical>0 and game.sheet_body.find_child("WorkOrdersNext",true,false).get_global_rect().get_center().y<viewport.y)
		game.work_orders_page=19;game.show_sheet("Work");await tree.process_frame;await tree.process_frame
		rows=game.sheet_body.find_children("WorkOrderRow*","Button",true,false)
		check.call("BUDGET/UI_final_page_keeps_last_queued_order_%s" % str(viewport),rows.size()==32 and game.sheet_body.find_child("WorkOrdersNext",true,false).disabled and rows[-1].text.contains("Queued"))
		rows[-1].pressed.emit();await tree.process_frame;await tree.process_frame
		check.call("BUDGET/UI_queued_card_explains_recovery_actions_%s" % str(viewport),game.sheet_body.has_node("QueuedOrderExplanation") and game.sheet_body.find_children("*","Button",true,false).any(func(b:Button)->bool:return b.text.begins_with("Do next:")))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;tree.root.get_texture().get_image().save_png("res://reports/queued-order-%dx%d-150.png" % [viewport.x,viewport.y])
	check.call("BUDGET/UI_paging_inspection_keeps_camera_and_authoritative_state",world.canonical_hash()==before and game.runner.speed==0 and game.view.camera_center().is_equal_approx(camera_before))
	check.call("BUDGET/UI_queue_fixture_drains_audio",await game.soundscape.drain())
	game._finish_background_save(true,false);game.queue_free();await tree.process_frame;await tree.process_frame
	CampaignTests.remove_tree(scratch);tree.root.size=original_size;previous.visible=visible;previous.set_process(processing);previous.view.set_process(view_processing);previous._apply_device_settings()
