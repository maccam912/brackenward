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
	await rest_disclosure(game,check)
	await object_cards(game,check)
	await production_cards(game,check)
	await animal_cards(game,check)
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

static func rest_disclosure(game: GameSession, check: Callable) -> void:
	var tree: SceneTree=game.get_tree()
	var person: Dictionary=game.world.citizens[0]
	var baseline: String=game.world.canonical_hash()
	var camera: Vector2=game.view.camera_center()
	for scale in [1.0,1.5]:
		tree.root.size=Vector2i(390,844);game.text_scale=scale;game._build_theme();game.show_person(person.id)
		await tree.process_frame;await tree.process_frame
		var toggle: Button=game.sheet_body.get_node("RestPolicyToggle")
		var details: VBoxContainer=game.sheet_body.get_node("RestPolicyDetails")
		var buttons: Array=game.sheet_body.get_children().filter(func(node:Node)->bool:return node is Button)
		var names: Array=buttons.map(func(node:Button)->String:return node.text)
		check.call("PERSON/UI_%d_common_actions_precede_cosmetics_and_rest_help_starts_collapsed" % roundi(scale*100),not details.visible and names.find("Work preferences")<names.find("Appearance") and names.find("View on map")<names.find("Appearance") and toggle.size.x<=game.sheet_body.size.x+1)
		toggle.button_pressed=true;await tree.process_frame
		var expected: String=ColonyText.text("ui.help.person.rest_policy",{"tired":ColonyRest.TIRED,"preferred":ColonyRest.PREFERRED_TIRED,"rested":ColonyRest.RESTED,"bed":ColonyRest.BED,"bedroll":ColonyRest.BEDROLL,"ground":ColonyRest.GROUND})
		check.call("PERSON/UI_%d_expansion_reveals_full_exact_rest_policy_without_world_or_camera_change" % roundi(scale*100),details.visible and details.get_child(0).text==ColonyFonts.display(expected) and game.runner.speed==0 and game.world.canonical_hash()==baseline and game.view.camera_center().is_equal_approx(camera))
		toggle.button_pressed=false;await tree.process_frame
		check.call("PERSON/UI_%d_rest_help_can_collapse_again" % roundi(scale*100),not details.visible and game.world.canonical_hash()==baseline)

static func object_cards(game: GameSession, check: Callable) -> void:
	var baseline: String=game.world.canonical_hash()
	var cart: Dictionary=game.world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]
	var rotation: int=cart.rotation
	for turn in range(4):
		cart.rotation=turn;var current: String=game.world.canonical_hash();game.show_station(cart)
		await object_picture(game,"building/supply_cart/%d" % turn,current,check)
	cart.rotation=rotation
	var berry: Dictionary=game.world.resources.filter(func(r:Dictionary)->bool:return r.definition=="berry_bush")[0]
	var count: int=berry.remaining
	for remaining in [count,0]:
		berry.remaining=remaining;var current: String=game.world.canonical_hash();game._resource_sheet(berry)
		await object_picture(game,"resource/berry_bush%s/0" % ("_depleted" if remaining==0 else ""),current,check)
	berry.remaining=count
	var definition: Dictionary=game.world.definitions.crops.turnip
	for stage in range(5):
		var field: Dictionary={"id":9999,"crop":"turnip","x":90,"y":80,"prepared":true,"planted":stage>0,"growth":int(definition.growth*[0.0,0.0,0.2,0.6,1.0][stage]),"ripe_tick":game.world.tick if stage==4 else 0,"yield_count":definition.yield_count,"fertility":1000,"replant":true,"reason":"Test crop"}
		game._field_sheet(field)
		await object_picture(game,"crop/turnip/%d" % stage,baseline,check)
	check.call("ART/UI_object_cards_preserve_all_original_world_fields",game.world.canonical_hash()==baseline)

static func object_picture(game: GameSession, semantic: String, baseline: String, check: Callable) -> void:
	await game.get_tree().process_frame;await game.get_tree().process_frame
	var picture: TextureRect=game.sheet_body.find_child("ObjectPortrait",true,false)
	var fits: bool=picture!=null and picture.texture is AtlasTexture and picture.texture.region==EnvironmentArt.rectangle(semantic)
	if fits:
		var row: HBoxContainer=picture.get_parent().get_parent()
		fits=row.size.x<=game.sheet_body.size.x+1 and row.get_child(1).get_global_rect().end.x<=game.sheet_body.get_global_rect().end.x+1
	check.call("ART/UI_detail_%s_matches_actual_art_and_wraps_at_large_phone_text" % semantic,fits and game.world.canonical_hash()==baseline)

static func production_cards(game: GameSession, check: Callable) -> void:
	var tree: SceneTree=game.get_tree()
	var original: ColonyWorld=game.world
	var world: ColonyWorld=ColonyTests.world();game._replace_world(world);game._tutorial_dismiss()
	tree.root.size=Vector2i(390,844)
	for scale in [1.0,1.5]:
		game.text_scale=scale;game._build_theme()
		for recipe in world.definitions.recipes.values():
			var station: Dictionary=world._structure(recipe.station,Vector2i(90,80),0)
			var baseline: String=world.canonical_hash();game.show_station(station)
			await tree.process_frame;await tree.process_frame
			var card: PanelContainer=game.sheet_body.get_node("Recipe_"+recipe.id)
			var picture: TextureRect=card.find_child("ObjectPortrait",true,false)
			var locked: bool=recipe.unlock!="initial"
			var actions: Array=card.find_children("*","Button",true,false)
			var maintenance: Array=game.sheet_body.find_children("*","Button",true,false).filter(func(b:Button)->bool:return b.text=="Repair or demolish")
			var primary_first: bool=maintenance.size()==1 and card.get_index()<maintenance[0].get_index()
			check.call("PRODUCTION/UI_%s_recipe_art_actions_fit_text_%s" % [recipe.id,scale],picture.get_meta("semantic")=="item/%s/0" % recipe.outputs.keys()[0] and card.size.x<=game.sheet_body.size.x+1 and actions.size()==(1 if locked else 2) and primary_first and world.canonical_hash()==baseline)
			if recipe.id=="make_toolkit" and scale==1.0:
				actions[0].pressed.emit()
				check.call("PRODUCTION/UI_illustrated_batch_keeps_exact_recipe_command",world.pending_commands.size()==1 and world.pending_commands[0].kind=="recipe_order" and world.pending_commands[0].args=={"target":station.id,"definition":"make_toolkit","mode":"Repeat","value":1,"priority":2,"filters":recipe.alternatives})
				world.pending_commands.clear();game.submitted_command=0
	var damaged: Dictionary=world._structure("workbench",Vector2i(90,80),0);damaged.health-=1
	var damaged_baseline: String=world.canonical_hash();game.show_station(damaged)
	var repairs: Array=game.sheet_body.find_children("*","Button",true,false).filter(func(b:Button)->bool:return b.text=="Repair or demolish")
	check.call("PRODUCTION/UI_damaged_station_keeps_one_early_repair_action",repairs.size()==1 and repairs[0].get_index()<game.sheet_body.get_node("Recipe_make_toolkit").get_index() and world.canonical_hash()==damaged_baseline)
	game.close_sheet(false);game._replace_world(original);game._tutorial_dismiss()

static func animal_cards(game: GameSession, check: Callable) -> void:
	var tree: SceneTree=game.get_tree();var original: ColonyWorld=game.world
	if DisplayServer.get_name()!="headless":
		check.call("ANIMALS/UI_capture_directory_is_available",DirAccess.make_dir_recursive_absolute("res://reports/visual-polish")==OK)
	var world: ColonyWorld=DomesticTests.setup();world.wildlife_state.animals.clear()
	for kind in ["hare","deer","boar","marsh_goose"]:ColonyWildlife.spawn(world,kind,Vector2i(90,80))
	var pen: Dictionary=world.domestic_state.pens[0]
	for kind in ["hen","pack_goat"]:ColonyDomestic.acquire(world,kind,pen.id,Vector2i(66,63))
	game._replace_world(world);game._tutorial_dismiss();tree.root.size=Vector2i(390,844)
	for scale in [1.0,1.5]:
		game.text_scale=scale;game._build_theme()
		var baseline: String=world.canonical_hash();game.show_wildlife()
		await tree.process_frame;await tree.process_frame
		var choices: Array=game.sheet_body.find_children("*","Button",true,false)
		check.call("ANIMALS/UI_wildlife_list_art_and_actions_text_%s" % scale,choices.size()==4 and choices.all(func(b:Button)->bool:return b.size.x<=game.sheet_body.size.x+1 and (scale>1 or (b.icon is AtlasTexture and b.icon.atlas==AnimalArt.ATLAS))) and world.canonical_hash()==baseline)
		if DisplayServer.get_name()!="headless":
			check.call("ANIMALS/UI_list_capture_saved_text_%s" % scale,(await EnvironmentUITests.screenshot(tree)).save_png("res://reports/visual-polish/animals-list-%s.png" % scale)==OK)
		choices[0].pressed.emit()
		check.call("ANIMALS/UI_illustrated_choice_opens_actual_animal_without_hunt_text_%s" % scale,game.sheet_body.find_child("ObjectPortrait",true,false).texture.region==AnimalArt.frame_rect("hare","idle",1,0) and world.canonical_hash()==baseline)
		for animal in world.wildlife_state.animals:
			game._wildlife_sheet(animal)
			await _animal_card_check(game,animal,false,scale,baseline,check)
		for animal in world.domestic_state.animals:
			for juvenile in [false,true]:
				animal.juvenile_until=world.tick+7200 if juvenile else 0;baseline=world.canonical_hash()
				game.show_domestic_animal(animal)
				await _animal_card_check(game,animal,true,scale,baseline,check)
				if animal.definition=="pack_goat" and DisplayServer.get_name()!="headless":
					check.call("ANIMALS/UI_goat_capture_saved_text_%s_young_%s" % [scale,juvenile],(await EnvironmentUITests.screenshot(tree)).save_png("res://reports/visual-polish/animal-goat-%s-young-%s.png" % [scale,juvenile])==OK)
		baseline=world.canonical_hash();game.show_pen(pen)
		await tree.process_frame;await tree.process_frame
		var animal_choices: Array=game.sheet_body.find_children("*","Button",true,false).filter(func(b:Button)->bool:return b.text.contains("health"))
		check.call("ANIMALS/UI_pen_retains_both_named_animal_actions_text_%s" % scale,animal_choices.size()==2 and world.canonical_hash()==baseline)
	game.close_sheet(false);game._replace_world(original);game._tutorial_dismiss()

static func _animal_card_check(game: GameSession, animal: Dictionary, domestic: bool, scale: float, baseline: String, check: Callable) -> void:
	await game.get_tree().process_frame;await game.get_tree().process_frame
	var picture: TextureRect=game.sheet_body.find_child("ObjectPortrait",true,false)
	var young: bool=domestic and animal.juvenile_until>game.world.tick
	var valid: bool=picture!=null and picture.texture is AtlasTexture
	if valid:
		valid=picture.texture.atlas==AnimalArt.ATLAS and picture.texture.region==AnimalArt.frame_rect(animal.definition,"idle",1,0) and is_equal_approx(24.0/(picture.texture.region.size.x+picture.texture.margin.size.x),0.7 if young else 1.0)
		var row: Control=picture.get_parent().get_parent()
		valid=valid and row.size.x<=game.sheet_body.size.x+1 and row.get_child(1).get_global_rect().end.x<=game.sheet_body.get_global_rect().end.x+1
	check.call("ANIMALS/UI_%s_portrait_young_%s_text_%s_matches_map_and_fits" % [animal.definition,young,scale],valid and game.world.canonical_hash()==baseline)
