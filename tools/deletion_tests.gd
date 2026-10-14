class_name DeletionTests
extends RefCounted

class FailingRename extends ColonyDeletion:
	var calls: int=0
	func _rename(source: String, destination: String) -> Error:
		calls+=1
		return ERR_FILE_NO_PERMISSION if calls==2 else super(source,destination)

class FailingCleanup extends ColonyDeletion:
	func _remove(_path: String) -> Error: return ERR_FILE_NO_PERMISSION

static func write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE);file.store_string(text);file.close()

static func run(check: Callable) -> void:
	var root: String="user://deletion-tests-%d" % Time.get_ticks_usec()
	var store: ColonyStore=ColonyStore.new();store.root_directory=root;store.select_slot(1)
	var world: ColonyWorld=ColonyTests.world();var deletion: ColonyDeletion=ColonyDeletion.new()
	check.call("DELETE/invalid_slot_indices_rejected",deletion.preview(store,0).has("error") and deletion.preview(store,6).has("error") and deletion.preview(store,1,11).has("error"))
	check.call("DELETE/adopt_private_fixture",store.adopt(world,1).is_empty() and store.save_named(world,1,"Keep or delete").is_empty() and store.save_named(world,2,"Keep me").is_empty())
	write(store.directory.path_join("manual-01-9999999998.brackenward"),"damaged evidence")
	write(store.directory.path_join("manual-01-9999999999.brackenward.tmp"),"unfinished evidence")
	var reviewed: Dictionary=deletion.preview(store,1,1)
	var untouched: String=store.named_snapshots()[1].file
	var retained: PackedByteArray=FileAccess.get_file_as_bytes(store.directory.path_join(untouched))
	var original: Dictionary=deletion.preview(store,1)
	var failed: Dictionary=FailingRename.new().commit(store,reviewed)
	check.call("DELETE/failed_second_detachment_rolls_back_all_original_bytes",not failed.deleted and deletion.preview(store,1).token==original.token and deletion.cleanup_paths(store).is_empty(),str(failed))
	var result: Dictionary=deletion.commit(store,reviewed)
	check.call("DELETE/named_deletion_removes_valid_damaged_and_partial_copies_only",result.deleted and result.error.is_empty() and not store.named_snapshots()[0].exists and FileAccess.get_file_as_bytes(store.directory.path_join(untouched))==retained and store.load_latest().world.canonical_hash()==world.canonical_hash())
	check.call("DELETE/repeated_commit_cannot_remove_another_snapshot",not deletion.commit(store,reviewed).deleted and store.named_snapshots()[1].valid)
	reviewed=deletion.preview(store,1)
	write(store.directory.path_join("changed-after-review.txt"),"new bytes")
	check.call("DELETE/changed_manifest_requires_new_review",not deletion.commit(store,reviewed).deleted and ColonyStore.occupied(1,root))
	check.call("DELETE/independent_campaign_fixture",store.adopt(ColonyWorld.new(world.definitions,"keep-campaign-2"),2).is_empty())
	var independent: Dictionary=deletion.preview(store,2)
	store.select_slot(1);store.adopt(world,1,true)
	reviewed=deletion.preview(store,1)
	check.call("DELETE/review_includes_replaced_copies_and_named_saves",reviewed.targets.size()==2 and reviewed.files.any(func(row:Dictionary)->bool:return row.path.get_file()==untouched) and reviewed.files.any(func(row:Dictionary)->bool:return row.path.ends_with("changed-after-review.txt")) and reviewed.bytes>0)
	result=deletion.commit(store,reviewed)
	check.call("DELETE/campaign_deletion_reclaims_all_target_folders_and_preserves_other_slot",result.deleted and result.error.is_empty() and not deletion.has_saves(store,1) and deletion.preview(store,2).token==independent.token and deletion.cleanup_paths(store).is_empty())
	reviewed=deletion.preview(store,2)
	result=FailingCleanup.new().commit(store,reviewed)
	check.call("DELETE/cleanup_failure_is_visible_and_slot_stays_removed",result.deleted and not result.error.is_empty() and not ColonyStore.occupied(2,root) and not deletion.cleanup_paths(store).is_empty())
	check.call("DELETE/cleanup_can_be_retried_to_reclaim_storage",deletion.cleanup(store).is_empty() and deletion.cleanup_paths(store).is_empty())
	write(root.path_join("deleted-save-unrelated.txt"),"leave this alone")
	check.call("DELETE/cleanup_only_recognizes_exact_owned_names",deletion.cleanup(store).is_empty() and FileAccess.get_file_as_string(root.path_join("deleted-save-unrelated.txt"))=="leave this alone")
	if OS.get_name() in ["macOS","Linux"]:
		store.select_slot(1);store.adopt(world,1)
		write(root.path_join("outside/kept.txt"),"outside this campaign")
		var parent: DirAccess=DirAccess.open(store.directory)
		var link: String=store.directory.path_join("linked-folder")
		var linked: Error=parent.create_link(ProjectSettings.globalize_path(root.path_join("outside")),ProjectSettings.globalize_path(link))
		check.call("DELETE/linked_save_path_rejects_review_without_following_target",linked==OK and not deletion.preview(store,1).get("error","").is_empty() and FileAccess.get_file_as_string(root.path_join("outside/kept.txt"))=="outside this campaign",error_string(linked))
		DirAccess.remove_absolute(link)
	CampaignTests.remove_tree(root)

static func ui(game: GameSession, check: Callable) -> void:
	game._finish_background_save(true)
	var previous: PrototypeStore=game.store
	var root: String="user://deletion-ui-%d" % Time.get_ticks_usec()
	var store: ColonyStore=ColonyStore.new();store.root_directory=root;store.select_slot(1)
	game.store=store;game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
	store.adopt(game.world,1);store.save_named(game.world,1,"Old spring");store.save_named(game.world,2,"Keep spring")
	var other: ColonyWorld=ColonyWorld.new(game.world.definitions,"ui-keep-campaign-2")
	store.adopt(other,2);store.select_slot(1);store.load_latest()
	game.show_named_snapshots()
	var buttons: Array=game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Delete snapshot 1...")
	check.call("DELETE/UI_named_snapshot_has_delete_control",buttons.size()==1 and buttons[0].custom_minimum_size.y>=48)
	buttons[0].pressed.emit()
	check.call("DELETE/UI_review_names_snapshot_before_any_deletion",game.sheet_name=="Delete saves" and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Old spring")) and store.named_snapshots()[0].valid)
	game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Cancel")[0].pressed.emit()
	check.call("DELETE/UI_cancel_preserves_snapshot",store.named_snapshots()[0].valid and game.sheet_name=="Named snapshots")
	game.show_delete_saves(1,1)
	var stale: Button=game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Permanently delete")[0]
	ColonyChronicle.command(game.world,"rename",{"target":1,"text":"Delete saves"});game.show_person(1)
	var before_stale: String=game.world.canonical_hash();stale.pressed.emit()
	check.call("DELETE/UI_resident_name_cannot_reactivate_a_stale_delete_review",game.sheet_name=="Delete saves" and game.sheet_route.is_empty() and store.named_snapshots()[0].valid and store.named_snapshots()[1].valid and game.world.canonical_hash()==before_stale)
	game.show_delete_saves(1,1)
	var confirm: Button=game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Permanently delete")[0]
	confirm.pressed.emit();confirm.pressed.emit()
	check.call("DELETE/UI_confirm_removes_one_named_slot_without_touching_campaign",not store.named_snapshots()[0].exists and store.named_snapshots()[1].valid and ColonyStore.occupied(1,root) and not game.awaiting_first_colony)
	game.show_campaigns()
	var signature: String=game.world.canonical_hash()
	game.show_delete_saves(2)
	game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Permanently delete")[0].pressed.emit()
	check.call("DELETE/UI_other_campaign_removed_without_changing_active_world",not ColonyStore.occupied(2,root) and game.world.canonical_hash()==signature and not game.awaiting_first_colony)
	game.world.step();game._start_background_save(false)
	game.show_delete_saves(1)
	check.call("DELETE/UI_review_joins_writer_and_stops_new_writes",not game.save_queue.busy() and not game.save_queue.preparing() and game.runner.speed==0)
	await game.get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		game.get_tree().root.get_texture().get_image().save_png("res://reports/delete-campaign-review.png")
	confirm=game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text=="Permanently delete")[0]
	confirm.pressed.emit();confirm.pressed.emit()
	check.call("DELETE/UI_current_campaign_removed_and_detached_from_autosave",game.awaiting_first_colony and game.runner.speed==0 and not ColonyStore.occupied(1,root) and not DirAccess.dir_exists_absolute(store.directory))
	game._advance_frame(60.0);game.suspend();game.resume_from_background();game.close_sheet()
	game.set_speed(4)
	check.call("DELETE/UI_deleted_campaign_cannot_return_after_time_background_or_resume",game.awaiting_first_colony and game.runner.speed==0 and game.sheet_name=="New colony" and not DirAccess.dir_exists_absolute(store.directory))
	game.store=previous;game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
	CampaignTests.remove_tree(root)
