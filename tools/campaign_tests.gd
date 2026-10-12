class_name CampaignTests
extends RefCounted

static func remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for child in DirAccess.get_directories_at(path): remove_tree(path.path_join(child))
	for file in DirAccess.get_files_at(path): DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)

static func run(check: Callable) -> void:
	var root: String = "user://campaign-tests-%d" % Time.get_ticks_usec()
	var store: ColonyStore = ColonyStore.new()
	store.root_directory = root
	store.select_slot(1)
	var w: ColonyWorld = ColonyTests.world()
	check.call("SAVE/campaign_staged_adoption",store.adopt(w,1).is_empty() and ColonyStore.occupied(1,root) and not ColonyStore.occupied(2,root))
	var expected: String = w.canonical_hash()
	for index in range(1,11):
		check.call("SAVE/named_slot_%d" % index,store.save_named(w,index,"Spring snapshot %d" % index).is_empty())
	check.call("SAVE/eleventh_named_slot_rejected",not store.save_named(w,11,"Overflow").is_empty())
	var rows: Array[Dictionary] = store.named_snapshots()
	var retained: Dictionary = {}
	for row in rows:
		retained[row.index] = FileAccess.get_file_as_bytes(store.directory.path_join(row.file))
	check.call("SAVE/occupied_named_requires_choice",not store.save_named(w,1,"Unconfirmed overwrite").is_empty() and FileAccess.get_file_as_bytes(store.directory.path_join(rows[0].file)) == retained[1])
	for i in range(5): w.step()
	check.call("SAVE/confirmed_named_replaces_only_one",store.save_named(w,1,"Later spring",true).is_empty() and store.named_snapshots()[0].name == "Later spring")
	var unchanged: bool = true
	rows = store.named_snapshots()
	for row in rows.slice(1):
		unchanged = unchanged and FileAccess.get_file_as_bytes(store.directory.path_join(row.file)) == retained[row.index]
	check.call("SAVE/other_nine_named_unchanged",unchanged)
	for i in range(5):
		w.step()
		store.save(w)
	check.call("SAVE/three_autosaves_separate_from_ten_named",store._generations().size() == 3 and store.named_snapshots().filter(func(r:Dictionary)->bool:return r.valid).size() == 10)
	var named: Dictionary = store.load_named(2)
	check.call("SAVE/named_snapshot_restores_exact_world",named.has("world") and named.world.canonical_hash() == expected and named.snapshot_name == "Spring snapshot 2")
	var other: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data(),"independent-campaign-2")
	check.call("SAVE/independent_campaign_two",store.adopt(other,2).is_empty())
	var independent_bytes: PackedByteArray = FileAccess.get_file_as_bytes(store.directory.path_join("snapshot-0000000001.brackenward"))
	check.call("SAVE/occupied_campaign_requires_confirmation",not store.adopt(other,1).is_empty())
	var replacement: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data(),"replacement-campaign-1")
	check.call("SAVE/campaign_replacement_verified_before_adoption",store.adopt(replacement,1,true).is_empty())
	var archive_found: bool = false
	for directory in DirAccess.get_directories_at(root):
		if directory.begins_with("replaced-slot-1-"):
			var archive: ColonyStore = ColonyStore.new()
			archive.directory = root.path_join(directory)
			archive_found = archive.named_snapshots().filter(func(r:Dictionary)->bool:return r.valid).size() == 10
	check.call("SAVE/previous_campaign_archived_with_named_saves",archive_found)
	check.call("SAVE/unrelated_campaign_unchanged",FileAccess.get_file_as_bytes(root.path_join("slot-2/snapshot-0000000001.brackenward")) == independent_bytes)
	check.call("SAVE/fifth_campaign_slot_supported",store.adopt(ColonyTests.world(),5).is_empty() and ColonyStore.occupied(5,root))
	check.call("SAVE/sixth_campaign_slot_rejected",not store.adopt(ColonyTests.world(),6).is_empty())
	var preferences: DeviceSettings = DeviceSettings.new()
	preferences.path = root.path_join("settings.json")
	preferences.values.last_slot = 2
	preferences.values.text_scale = 1.25
	preferences.values.left_handed = true
	preferences.values.cameras[1] = [50.0,60.0,24.0]
	check.call("SETTINGS/device_preferences_verify_before_replace",preferences.save_local().is_empty())
	var loaded: DeviceSettings = DeviceSettings.new()
	loaded.path = preferences.path
	loaded.load_local()
	check.call("SETTINGS/restart_retains_last_campaign_and_camera",loaded.values == preferences.values)
	store.adopt(ColonyTests.world(),3)
	loaded.load_local()
	check.call("SETTINGS/import_does_not_replace_device_preferences",loaded.values == preferences.values)
	var corrupt: FileAccess = FileAccess.open(preferences.path,FileAccess.WRITE)
	corrupt.store_string("{truncated")
	corrupt.close()
	loaded = DeviceSettings.new()
	loaded.path = preferences.path
	loaded.load_local()
	check.call("SETTINGS/corrupt_preferences_use_defaults_preserve_evidence",loaded.values.last_slot == 1 and FileAccess.get_file_as_string(preferences.path) == "{truncated")
	remove_tree(root)
