class_name FontUITests
extends RefCounted

static func tap(game: GameSession, title: String) -> void:
	await game.get_tree().process_frame;await game.get_tree().process_frame
	var action: Button
	for child in game.sheet_body.get_children():
		if child is Button and child.text==title: action=child;break
	if action==null: return
	(game.sheet_body.get_parent() as ScrollContainer).ensure_control_visible(action)
	await game.get_tree().process_frame;await game.get_tree().process_frame
	var point: Vector2 = action.get_global_rect().get_center()
	await AudioUITests.touch(game.get_tree(),point,true);await AudioUITests.touch(game.get_tree(),point,false)

static func entry(game: GameSession) -> LineEdit:
	for child in game.sheet_body.get_children():
		if child is LineEdit: return child
	return null

static func run(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree = previous.get_tree();var original_size: Vector2i = tree.root.size
	var processing: bool = previous.is_processing();var view_processing: bool = previous.view.is_processing();var visible: bool = previous.visible
	previous.set_process(false);previous.view.set_process(false);previous.hide()
	var scratch: String = "user://fonts-ui-%d" % Time.get_ticks_usec()
	var game: GameSession = load("res://scenes/game.tscn").instantiate()
	game.world=ColonyTests.world();game.runner=SimRunner.new(game.world);game.store.root_directory=scratch;game.store.select_slot(1);game.settings.path=scratch.path_join("settings.json")
	tree.root.add_child(game);game.close_sheet();game._tutorial_dismiss();game.set_process(false)
	game.text_scale=1.5;game._build_theme()
	var slot: int = 0
	for viewport in [Vector2i(360,640),Vector2i(640,360)]:
		slot+=1;tree.root.size=viewport
		game.notice=""
		game.show_sheet("A[]^{}~ 8×6 · -5 °C …")
		var legacy: String = "Old supper 18:00\u201320:00"
		var body: Label = game.label(legacy,game.sheet_body)
		var unsupported: Label = game.label("Old \u4e00",game.sheet_body)
		await tree.process_frame;await tree.process_frame
		check.call("FONT/UI_explicit_body_and_approved_heading_chain_%s" % str(viewport),game.theme.default_font==ColonyFonts.body() and game.sheet_heading.get_theme_font("font")==ColonyFonts.heading() and body.text=="Old supper 18:00-20:00" and unsupported.text.contains("Old ?") and unsupported.text.contains("original text is kept") and legacy.contains("\u2013"))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;tree.root.get_texture().get_image().save_png("res://reports/font-coverage-%dx%d-150.png" % [viewport.x,viewport.y])
		game._replace_world(ColonyTests.world());game.show_rename(1)
		var before: String = game.world.canonical_hash();entry(game).text="Jun\u4e00iper"
		await tap(game,"Save name")
		check.call("FONT/UI_invalid_rename_keeps_form_and_world_%s" % str(viewport),game.sheet_name=="Rename" and game.sheet_feedback.visible and game.sheet_feedback.text.contains("Basic Latin") and game.world.canonical_hash()==before and game.world.pending_commands.is_empty(),str([game.sheet_name,game.notice,game.sheet_feedback.text,game.world.pending_commands,entry(game).text if entry(game)!=null else "NO ENTRY"]))
		game.notice="Weather forecast updated.";game._process(0.0)
		check.call("FONT/UI_form_error_survives_unrelated_notice_%s" % str(viewport),game.sheet_feedback.text.contains("Basic Latin") and game.world.canonical_hash()==before)
		entry(game).text="  Juniper  ";await tap(game,"Save name");game.world.step()
		check.call("FONT/UI_corrected_rename_uses_normal_command_%s" % str(viewport),game.world.citizens[0].name=="Juniper" and game.world.receipts.values()==["accepted"] and game.world.invariant_errors().is_empty())
		game._replace_world(ColonyTests.world());game.show_pin_moment();before=game.world.canonical_hash();entry(game).text="\u4e00"
		await tap(game,"Pin this moment")
		check.call("FONT/UI_invalid_note_keeps_form_and_world_%s" % str(viewport),game.sheet_name=="Pin a moment" and game.sheet_feedback.text.contains("Basic Latin") and game.world.canonical_hash()==before,str([game.sheet_name,game.notice,game.sheet_feedback.text,entry(game).text if entry(game)!=null else "NO ENTRY"]))
		entry(game).text="";await tap(game,"Pin this moment");game.world.step()
		check.call("FONT/UI_optional_empty_note_still_pins_moment_%s" % str(viewport),game.world.chronicle_state.facts.any(func(f:Dictionary)->bool:return f.kind=="pin_moment") and game.world.invariant_errors().is_empty())
		game._replace_world(ColonyTests.world());game._name_snapshot(slot,false,"");before=game.world.canonical_hash();entry(game).text="Bad\u4e00"
		await tap(game,"Save snapshot")
		check.call("FONT/UI_invalid_snapshot_name_stays_editable_%s" % str(viewport),game.sheet_name=="Name snapshot" and game.sheet_feedback.text.contains("Basic Latin") and not game.store.named_snapshots()[slot-1].exists and game.world.canonical_hash()==before,str([game.sheet_name,game.notice,game.sheet_feedback.text,entry(game).text if entry(game)!=null else "NO ENTRY"]))
		if entry(game)==null: break
		entry(game).text="Quiet evening "+str(slot);await tap(game,"Save snapshot")
		var row: Dictionary = game.store.named_snapshots()[slot-1]
		check.call("FONT/UI_corrected_snapshot_name_saves_without_simulation_%s" % str(viewport),row.valid and row.name=="Quiet evening "+str(slot) and game.world.canonical_hash()==before)
		var retained: PackedByteArray = FileAccess.get_file_as_bytes(game.store.directory.path_join(row.file))
		game._name_snapshot(slot,true,row.name);entry(game).text="Bad\u4e00";await tap(game,"Continue")
		check.call("FONT/UI_invalid_replacement_does_not_reach_confirmation_%s" % str(viewport),game.sheet_name=="Name snapshot" and game.sheet_feedback.text.contains("Basic Latin") and FileAccess.get_file_as_bytes(game.store.directory.path_join(row.file))==retained)
	check.call("FONT/UI_fixture_drains_audio",await game.soundscape.drain())
	game._finish_background_save(true,false);game.queue_free();await tree.process_frame;await tree.process_frame
	CampaignTests.remove_tree(scratch);tree.root.size=original_size;previous.visible=visible;previous.set_process(processing);previous.view.set_process(view_processing);previous._apply_device_settings()
