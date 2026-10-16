class_name AppearanceUITests
extends RefCounted

static func run(game: GameSession, check: Callable) -> void:
	game._replace_world(ColonyTests.world());game.close_sheet();game.close_inspector();game._tutorial_dismiss()
	# This test swaps simulation fixtures without adopting a campaign slot.
	# Autosave lifecycle is tested separately; keep it from saving this fixture
	# over the preceding lifecycle test's acknowledged store generation.
	var processing: bool = game.is_processing();game.set_process(false)
	var tree: SceneTree = game.get_tree()
	var original_size: Vector2i = tree.root.size
	var original_scale: float = game.text_scale
	var original: Dictionary = game.world.payload().duplicate(true)
	var expected: Dictionary = game.world.citizens[0].appearance.duplicate()
	game.show_appearance(1)
	await tree.process_frame
	game.sheet_body.find_child("Appearance_skin_Next",true,false).pressed.emit()
	await tree.process_frame
	check.call("ART/UI_preview_never_changes_world_or_queues_command",game.world.payload()==original and game.world.pending_commands.is_empty())
	game.sheet_body.find_child("CancelAppearance",true,false).pressed.emit()
	await tree.process_frame
	check.call("ART/UI_cancel_discards_preview",game.world.payload()==original)
	game.show_appearance(1)
	await tree.process_frame
	game.sheet_body.find_child("Appearance_coat_Next",true,false).pressed.emit()
	await tree.process_frame
	game.sheet_body.find_child("SaveAppearance",true,false).pressed.emit()
	expected.coat=posmod(expected.coat+1,8)
	check.call("ART/UI_confirm_queues_exact_choices_while_paused",game.runner.speed==0 and game.world.citizens[0].appearance==original.citizens[0].appearance and game.world.pending_commands.size()==1 and game.world.pending_commands[0].kind=="citizen_appearance" and game.world.pending_commands[0].args=={"target":1,"appearance":expected})
	game.world.step()
	check.call("ART/UI_choices_apply_on_next_simulation_tick",game.world.citizens[0].appearance==expected)
	game.submitted_command=0
	game.close_sheet();game.select_citizen(1)
	await tree.process_frame;await tree.process_frame
	check.call("ART/UI_selected_portrait_matches_saved_choices",game.inspector_portrait.get_meta("appearance")==expected and game.inspector_portrait.texture.region==Rect2(expected.body*64,expected.hair*64,64,64))
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var rect: Rect2 = game.inspector_portrait.get_global_rect()
		var point: Vector2 = rect.get_center()-Vector2(32,32)+Vector2(32.5,25.5)
		var skin: Color = tree.root.get_texture().get_image().get_pixelv(Vector2i(point))
		check.call("ART/UI_palette_shader_renders_selected_skin_on_GPU",skin.is_equal_approx(Color(CitizenArt.SKINS[expected.skin])),str([skin,Color(CitizenArt.SKINS[expected.skin])]))
	needs_card(game,check)
	for viewport in [Vector2i(360,640),Vector2i(640,360)]:
		tree.root.size=viewport;game.text_scale=1.5;game._build_theme();game.show_appearance(1)
		await tree.process_frame;await tree.process_frame
		var actions: Array = game.sheet_body.find_children("Appearance_*","Button",true,false)
		check.call("ART/UI_long_sheet_heading_keeps_top_strip_compact_%s" % str(viewport),game.sheet.find_child("SheetHeading",true,false).size.y<=64)
		check.call("ART/UI_twelve_color_shape_controls_at_least_48dp_%s" % str(viewport),actions.size()==12 and actions.all(func(entry:Button)->bool:return entry.size.x>=48 and entry.size.y>=48))
		check.call("ART/UI_no_horizontal_overflow_at_large_text_%s" % str(viewport),game.sheet_body.size.x<=viewport.x and actions.all(func(entry:Button)->bool:return entry.get_global_rect().end.x<=viewport.x))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			tree.root.get_texture().get_image().save_png("res://reports/appearance-%dx%d-150.png" % [viewport.x,viewport.y])
	tree.root.size=original_size;game.text_scale=original_scale;game._build_theme();game.close_sheet();game.close_inspector()
	game.journal_elapsed=0.0;game.set_process(processing)

static func needs_card(game: GameSession, check: Callable) -> void:
	var person: Dictionary=game.world.citizens[0]
	var fields: Array[String]=["fullness","rest","health","morale"]
	var original: Array=fields.map(func(field:String)->int:return person[field])
	for values in [[0,0,37,1000],[1000,1000,100,0]]:
		for index in range(fields.size()): person[fields[index]]=values[index]
		var canonical: String=game.world.canonical_hash()
		game.show_person(person.id)
		var panel: ResidentNeeds=game.sheet_body.find_child("ResidentNeeds",true,false)
		var exact: bool=panel!=null
		for index in range(fields.size()):
			var meter: ProgressBar=panel.find_child(fields[index],true,false)
			exact=exact and meter!=null and meter.value==values[index] and meter.max_value==[1000,1000,100,1000][index]
		check.call("ART/UI_resident_needs_show_exact_values_and_distinct_health_range_%d" % values[0],exact and game.runner.speed==0 and game.world.canonical_hash()==canonical)
	for index in range(fields.size()): person[fields[index]]=original[index]
