class_name DiagnosticsUITests
extends RefCounted

class PickerStub extends RefCounted:
	var requests: Array = []
	var writes: Array = []
	func chooseExportDestination(request: int, name: String) -> void:
		requests.append({"id":request,"name":name})
	func writeSelectedDocument(request: int, bytes: PackedByteArray) -> void:
		writes.append({"id":request,"bytes":bytes.duplicate()})

static func run(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree = previous.get_tree()
	var processing: bool = previous.is_processing();var visible: bool = previous.visible;var original_size: Vector2i = tree.root.size
	previous.set_process(false);previous.hide()
	var root: String = "user://diagnostic-ui-%d" % Time.get_ticks_usec()
	var game: GameSession = load("res://scenes/game.tscn").instantiate()
	game.world=ColonyTests.world();game.runner=SimRunner.new(game.world);game.store.root_directory=root;game.store.select_slot(1);game.settings.path=root.path_join("settings.json")
	tree.root.add_child(game);game.close_sheet();game._tutorial_dismiss();game.set_process(false)
	await tree.process_frame;await tree.process_frame
	var canonical: String = game.world.canonical_hash()
	game.diagnostics.reset();game.diagnostics.frame(1000,game.world.tick,4);game.diagnostics.frame(501000,game.world.tick,4);game.diagnostics.record("simulation_batch",400000)
	game.show_diagnostics()
	var bytes: PackedByteArray = game._diagnostic_bytes()
	var text: String = bytes.get_string_from_utf8()
	check.call("PERF/UI_preview_has_hardware_build_and_readable_timing_evidence",game.sheet_name=="Performance report" and game.diagnostic_preview.metadata.has_all(["build","platform","os_version","device_model","gpu","seed","tick","quality","fps_cap"]) and game.diagnostic_preview.slow_events.size()==2 and game.runner.speed==0)
	check.call("PERF/UI_report_contains_no_campaign_names_save_payload_or_paths",not text.contains(game.world.citizens[0].name) and not text.contains("session_id") and not text.contains("res://") and not text.contains("user://") and not text.contains("/Users/") and not text.contains("content://") and not text.contains("payload"))
	game.sheet_body.get_node("PreviewDiagnostics").pressed.emit();await tree.process_frame
	game.diagnostics.record("session",800000)
	for child in game.sheet_body.get_children():
		if child is Button and child.text=="Back to report": child.pressed.emit();break
	check.call("PERF/UI_raw_preview_and_back_preserve_exact_export_bytes",game._diagnostic_bytes()==bytes)
	var picker: PickerStub = PickerStub.new();game.native_storage=picker
	game.choose_diagnostics();var request: int = game.document_request
	game.choose_diagnostics()
	check.call("PERF/UI_native_export_waits_for_one_explicit_picker_and_preserves_preview",picker.requests.size()==1 and picker.requests[0].name=="brackenward-performance.json" and game.document_pending and game.document_kind=="diagnostics" and game.export_bytes==bytes)
	game._native_result(request-1,"export_selected",PackedByteArray())
	check.call("PERF/UI_stale_picker_callback_cannot_write_or_finish_report",picker.writes.is_empty() and game.document_pending)
	game._native_result(request,"export_selected",PackedByteArray());game._native_result(request,"written",PackedByteArray())
	check.call("PERF/UI_native_export_writes_exact_reviewed_bytes_and_reports_verified",picker.writes.size()==1 and picker.writes[0].bytes==bytes and not game.document_pending and game.notice=="Performance report written and verified.")
	game.choose_diagnostics();game._native_result(game.document_request,"canceled",PackedByteArray())
	check.call("PERF/UI_cancel_leaves_campaign_and_preview_unchanged",not game.document_pending and game.world.canonical_hash()==canonical and game._diagnostic_bytes()==bytes)
	var canceled_notice: String = game.notice
	game._native_result(game.document_request,"read",bytes)
	check.call("PERF/UI_completed_or_canceled_request_ignores_late_responses",game.notice==canceled_notice and game.world.canonical_hash()==canonical)
	DirAccess.make_dir_recursive_absolute(root)
	game.document_pending=true
	game._desktop_selected(root.path_join("performance.json"))
	check.call("PERF/UI_desktop_export_reads_back_the_exact_json_bytes",FileAccess.get_file_as_bytes(root.path_join("performance.json"))==bytes and game.notice=="Performance report written and verified.")
	game.choose_diagnostics();game._native_result(game.document_request,"read",bytes)
	check.call("PERF/UI_diagnostic_operation_cannot_import_its_bytes_as_a_campaign",game.world.canonical_hash()==canonical and game.notice.begins_with("Unexpected document"))
	game.choose_document(true)
	check.call("PERF/UI_next_save_export_restores_normal_save_kind_and_validation",game.document_kind=="save" and picker.requests[-1].name.ends_with(".brackenward") and ColonyCodec.decode(game.export_bytes).has("world"))
	game._native_result(game.document_request,"canceled",PackedByteArray())
	for viewport in [Vector2i(360,640),Vector2i(640,360)]:
		tree.root.size=viewport;game.size=Vector2(viewport);game.text_scale=1.5;game._build_theme();game.notice="";game.show_diagnostics()
		await tree.process_frame;await tree.process_frame
		var buttons: Array = game.sheet_body.find_children("*Diagnostics","Button",true,false)
		check.call("PERF/UI_large_text_report_controls_keep_48dp_targets_%s" % str(viewport),buttons.size()==4 and buttons.all(func(b:Button)->bool:return b.size.y>=48 and b.get_global_rect().end.x<=viewport.x))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			tree.root.get_texture().get_image().save_png("res://reports/performance-report-%dx%d-150.png" % [viewport.x,viewport.y])
	game.sheet_body.get_node("ResetDiagnostics").pressed.emit()
	check.call("PERF/UI_reset_changes_no_gameplay_field",game.diagnostics.samples.is_empty() and game.world.canonical_hash()==canonical)
	game.diagnostics.record("session",100000);game._replace_world(ColonyTests.world())
	check.call("PERF/UI_campaign_adoption_clears_old_measurements_and_seed_preview",game.diagnostics.samples.is_empty() and game.diagnostic_preview.is_empty())
	check.call("PERF/UI_diagnostics_fixture_drains_audio",await game.soundscape.drain())
	game.queue_free();await tree.process_frame;await tree.process_frame
	CampaignTests.remove_tree(root);tree.root.size=original_size;previous.visible=visible;previous.set_process(processing);previous._apply_device_settings()
