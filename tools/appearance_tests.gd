class_name AppearanceTests
extends RefCounted

static func without_appearance(world: ColonyWorld, schema: int = 21) -> Dictionary:
	var result: Dictionary = world.payload().duplicate(true)
	result.schema_revision=schema
	for person in result.citizens: person.erase("appearance")
	return result

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var other: ColonyWorld = ColonyTests.world()
	var chosen: Dictionary = {"body":7,"skin":5,"hair":7,"hair_color":7,"coat":7,"scarf":7}
	var before: Dictionary = without_appearance(world)
	var metadata_art: Dictionary = ColonyState.unpack(JSON.parse_string(FileAccess.get_file_as_string("res://data/citizen_animation.json")))
	var all_frames: Dictionary = {}
	var atlas_valid: bool = CitizenArt.ATLAS.get_size()==Vector2(1408,1728) and CitizenArt.PORTRAITS.get_size()==Vector2(512,512)
	for state in CitizenArt.animations():
		var animation: Dictionary = CitizenArt.animations()[state]
		for direction in range(int(animation.directions)):
			for frame in range(int(animation.frames)):
				var rectangle: Rect2 = CitizenArt.frame_rect(ColonyAppearance.defaults(1),state,direction,frame)
				atlas_valid=atlas_valid and not all_frames.has(rectangle) and Rect2(Vector2.ZERO,CitizenArt.ATLAS.get_size()).encloses(rectangle)
				all_frames[rectangle]=true
	check.call("ART/all_99_authored_frames_have_distinct_in_bounds_regions",atlas_valid and all_frames.size()==99 and metadata_art.frames_per_body==99 and metadata_art.bodies==8 and metadata_art.hair_shapes==8)
	check.call("ART/appearance_defaults_are_valid_for_all_resident_ids",range(1,1001).all(func(id:int)->bool:return ColonyAppearance.valid(ColonyAppearance.defaults(id))))
	check.call("ART/cosmetic_command_changes_only_appearance",ColonyAppearance.command(world,{"target":1,"appearance":chosen})=="accepted" and world.citizens[0].appearance==chosen and without_appearance(world)==before)
	chosen.coat=0
	check.call("ART/command_owns_a_copy_of_choices",world.citizens[0].appearance.coat==7)
	for key in ColonyAppearance.OPTIONS:
		var invalid: Dictionary = world.citizens[0].appearance.duplicate()
		invalid[key]=ColonyAppearance.OPTIONS[key]
		check.call("ART/out_of_range_%s_rejected" % key,ColonyAppearance.command(world,{"target":1,"appearance":invalid})=="invalid_appearance")
	check.call("ART/missing_extra_float_and_boolean_choices_rejected",not ColonyAppearance.valid({}) and not ColonyAppearance.valid(chosen.merged({"extra":1})) and not ColonyAppearance.valid(chosen.merged({"body":1.0},true)) and not ColonyAppearance.valid(chosen.merged({"skin":true},true)))
	for i in range(100): world.step();other.step()
	check.call("ART/appearance_has_no_effect_on_simulation_after_100_ticks",without_appearance(world)==without_appearance(other))
	world.queue_command("citizen_appearance",{"target":2,"appearance":chosen})
	var loaded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("ART/paused_pending_choices_roundtrip_without_applying",loaded.has("world") and loaded.world.citizens[1].appearance==world.citizens[1].appearance and loaded.world.pending_commands==world.pending_commands)
	if loaded.has("world"):
		loaded.world.step()
		check.call("ART/public_command_applies_after_next_tick",loaded.world.citizens[1].appearance==chosen)
	world.pending_commands[0].args.appearance.skin=-1
	check.call("ART/malformed_pending_choice_cannot_load",ColonyCodec.decode(ColonyCodec.encode(world)).has("error"))
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/schema21-delta.json"))
	var root: String = "user://appearance-migration-%d" % Time.get_ticks_usec()
	var store: ColonyStore = ColonyStore.new();store.root_directory=root;store.select_slot(1)
	DirAccess.make_dir_recursive_absolute(store.directory)
	for pair in [["schema21-delta.brackenward","snapshot-0000000001.brackenward"],["schema21-delta.frames","journal-0000000001.frames"]]:
		DirAccess.copy_absolute("res://tests/fixtures/"+pair[0],store.directory.path_join(pair[1]))
	loaded=store.load_latest()
	check.call("SAVE/schema21_delta_migrates_exact_acknowledged_final_payload",loaded.has("world") and loaded.world.tick==metadata.end_tick and JSON.stringify(ColonyState.pack(without_appearance(loaded.world)),"",true).sha256_text()==metadata.final_canonical_hash,str(loaded.get("error","")))
	var originals: bool = true
	for pair in [["schema21-delta.brackenward","snapshot-0000000001.brackenward"],["schema21-delta.frames","journal-0000000001.frames"]]:
		originals=originals and FileAccess.get_sha256(store.directory.path_join(pair[1]))==metadata[pair[0]] and FileAccess.get_sha256(store.directory.path_join("migration-backup-"+pair[1]))==metadata[pair[0]]
	check.call("SAVE/migration_keeps_both_original_files_and_exact_backups",originals)
	check.call("SAVE/pruning_understands_old_schema_delta_pairs",store._generation_recoverable(store.directory.path_join("snapshot-0000000001.brackenward"),metadata["schema21-delta.brackenward"]))
	CampaignTests.remove_tree(root)
