class_name TextTests
extends RefCounted

static func run(check: Callable) -> void:
	check.call("TEXT/static_actions_keep_existing_english",ColonyText.text("ui.action.confirm")=="Confirm" and ColonyText.text("ui.action.cancel")=="Cancel" and ColonyText.text("ui.action.close")=="Close")
	var values: Dictionary = {"name":"Mira {count}","count":2}
	var before: String = JSON.stringify(values)
	check.call("TEXT/parameters_reorder_repeat_and_preserve_user_braces",ColonyText.format_template("{count} for {name}; {name}",values)=="2 for Mira {count}; Mira {count}" and JSON.stringify(values)==before)
	check.call("TEXT/zero_and_many_take_other_form",ColonyText.plural("ui.placement.blocked_cells",0)=="0 blocked cells stay unsubmitted" and ColonyText.plural("ui.placement.blocked_cells",2)=="2 blocked cells stay unsubmitted")
	check.call("TEXT/one_uses_singular_verb_and_noun",ColonyText.plural("ui.placement.blocked_cells",1)=="1 blocked cell stays unsubmitted")
	var conflicting: Dictionary = {"count":999}
	check.call("TEXT/plural_count_is_authoritative_without_mutating_arguments",ColonyText.plural("ui.placement.unmarked_trees",1,conflicting)=="1 unmarked tree" and conflicting.count==999)
	check.call("TEXT/non_count_named_fields_work_in_both_forms",ColonyText.plural("ui.placement.rectangle",1,{"width":1,"height":1,"mode":"Stockpile preview"})=="1 x 1 tile | Stockpile preview" and ColonyText.plural("ui.placement.rectangle",4,{"width":2,"height":2,"mode":"Stockpile preview"})=="2 x 2 tiles | Stockpile preview")

	var saved_quote: Dictionary={"portions":1,"ticks":7200,"label":"1 portions | 1 days 00:00 stored runway"}
	var exact_quote: String=JSON.stringify(saved_quote)
	check.call("TEXT/food_runway_uses_singular_without_rewriting_saved_label",ColonyText.food_runway(saved_quote)=="1 portion | 1 day 00:00 stored runway" and JSON.stringify(saved_quote)==exact_quote)
	check.call("TEXT/empty_food_and_no_residents_have_distinct_messages",ColonyText.food_runway({"portions":0,"ticks":0,"label":"0 portions | 0 days 00:00 stored runway"})=="0 portions | 0 days 00:00 stored runway" and ColonyText.food_runway({"portions":0,"ticks":0,"label":"No residents at home"})=="No residents at home")
	check.call("TEXT/food_runway_keeps_exact_quarter_hour_rounding",ColonyText.food_runway({"portions":24,"ticks":7200+5*300+89,"label":"canonical"})=="24 portions | 1 day 05:15 stored runway")
	check.call("TEXT/harvest_and_daily_demand_use_singular_and_plural",ColonyText.plural("ui.forecast.raw_food",1)=="1 raw food unit" and ColonyText.plural("ui.forecast.hours",1)=="1 hour" and ColonyText.plural("ui.forecast.daily_demand",1)=="1 meal portion/day" and ColonyText.plural("ui.forecast.raw_food",0)=="0 raw food units")
	var game: GameSession=GameSession.new();game.world=ColonyTests.world()
	var canonical: String=game.world.canonical_hash()
	check.call("TEXT/food_summary_formats_public_stock_without_gameplay_mutation",game.tutorial_forecast_text().begins_with("24 portions | 3 days 00:00 stored runway | 8 meal portions/day\nNo planted crops") and game.world.canonical_hash()==canonical)
	var field: Dictionary={"id":game.world._id(),"crop":"turnip","x":80,"y":70,"prepared":true,"planted":true,"growth":0,"growth_rem":0,"ripe_tick":0,"yield_count":1,"fertility":1000,"replant":true,"reason":"Growing"}
	field.growth=game.world.definitions.crops.turnip.growth-10;game.world.fields.append(field)
	check.call("TEXT/harvest_maturity_has_one_hour_and_one_raw_unit",game._tutorial_harvest_text()=="Next crop maturity: about 0 days 1 hour, 1 raw food unit, if current growing conditions continue.",game._tutorial_harvest_text())
	game.world.weather="drought";field.reason="Water {count}";game.world.weather_state.flooded.append(Vector2i(field.x,field.y));game.world.flood_cache_valid=false
	check.call("TEXT/paused_crop_reason_remains_literal_canonical_text",game._tutorial_harvest_text()=="Planted crops are paused: Water {count}")
	game.free()

	var titles_match: bool=true
	for identifier in ColonyText.SHEET_KEYS: titles_match=titles_match and ColonyText.text(ColonyText.sheet_key(identifier))==identifier
	check.call("TEXT/fixed_sheet_keys_retain_english_and_internal_identifiers",ColonyText.SHEET_KEYS.size()==75 and titles_match)
	check.call("TEXT/user_names_are_not_interpreted_as_template_keys",ColonyText.sheet_key("Mira {count}").is_empty() and ColonyText.sheet_key("ui.sheet.menu").is_empty())

	var entry: Dictionary={"stage":"frame_gap","speed":4,"count":1,"max_ms":50.75,"over_50ms":1,"p95_bucket_upper_ms":100.0}
	var entry_bytes: String=JSON.stringify(entry)
	check.call("TEXT/performance_template_preserves_values_and_reports_singular_sample",ColonyText.performance_timing(entry)=="frame gap / 4x: 1 sample, max 50.8 ms, 1 over 50 ms; p95 bucket upper 100.0 ms." and JSON.stringify(entry)==entry_bytes,ColonyText.performance_timing(entry))
	entry.count=2;entry.speed=0;entry.p95_bucket_upper_ms=null
	check.call("TEXT/performance_overflow_is_not_a_finite_percentile",ColonyText.performance_timing(entry)=="frame gap / Paused: 2 samples, max 50.8 ms, 1 over 50 ms; p95 bucket upper >1000 ms.")
	var stages_match: bool=ColonyText.PERFORMANCE_KEYS.size()==FrameDiagnostics.STAGES.size()
	for stage in FrameDiagnostics.STAGES: stages_match=stages_match and ColonyText.text(ColonyText.PERFORMANCE_KEYS[stage])==stage.replace("_"," ")
	check.call("TEXT/every_bounded_diagnostic_stage_has_a_named_message",stages_match)
	person_names(check)

static func person_names(check: Callable) -> void:
	var exact: bool=ColonyText.TRAIT_KEYS.size()==ColonyPopulation.TRAITS.size() and ColonyText.FOOD_TAG_KEYS.size()==ColonyPopulation.FOODS.size() and ColonyText.SKILL_KEYS.size()==ColonyWorld.SKILLS.size()
	for value in ColonyPopulation.TRAITS:exact=exact and ColonyText.trait_name(value)==value
	for value in ColonyPopulation.FOODS:exact=exact and ColonyText.food_tag_name(value)==value
	for value in ColonyWorld.SKILLS:exact=exact and ColonyText.skill_name(value)==value
	check.call("TEXT/all_stored_trait_food_and_skill_ids_have_exact_english_presentation",exact)
	exact=ColonyText.ACTIVITY_KEYS.size()==54
	for value in ColonyText.ACTIVITY_KEYS:exact=exact and ColonyText.activity_name(value)==value
	check.call("TEXT/fifty_four_fixed_activities_preserve_canonical_english",exact)
	var literal: String="Mira {hours} ui.activity.sleeping"
	check.call("TEXT/unknown_names_activities_and_composed_saved_reasons_stay_literal",ColonyText.trait_name(literal)==literal and ColonyText.food_tag_name(literal)==literal and ColonyText.skill_name(literal)==literal and ColonyText.activity_name(literal)==literal and ColonyText.activity_name("Carrying Mira {hours} to safety")=="Carrying Mira {hours} to safety" and ColonyText.activity_name("ui.activity.sleeping")=="ui.activity.sleeping")
	var world: ColonyWorld=ColonyTests.world();var person: Dictionary=world.citizens[0];exact=true
	var bed: Dictionary=world._structure("bed",Vector2i(80,80),0)
	var cases: int=0
	for target in [0,world.structures[0].id,bed.id]:
		person.bed=target;var before: String=world.canonical_hash()
		exact=exact and ColonyText.bed_description(world,person)==ColonyBeds.description(world,person) and world.canonical_hash()==before;cases+=1
	person.bed=bed.id;bed.health=0
	exact=exact and ColonyText.bed_description(world,person)==ColonyBeds.description(world,person) and ColonyText.bed_description(world,person)=="No assigned bed | ground rest 45/hour";cases+=1
	bed.health=200
	for delta in ColonyNavigation.NEIGHBORS:world._structure("wood_wall",Vector2i(80,80)+delta,0)
	var before: String=world.canonical_hash()
	exact=exact and world.roofed(Vector2i(80,80)) and ColonyText.bed_description(world,person)==ColonyBeds.description(world,person) and ColonyText.bed_description(world,person).contains("Roofed | rest 75/hour") and world.canonical_hash()==before;cases+=1
	check.call("TEXT/keyed_bed_description_matches_unchanged_shared_oracle_and_actual_rates",exact and cases==5)
	check.call("TEXT/care_templates_preserve_numeric_format_and_user_braces",ColonyText.text("ui.care.person",{"name":"Mira {health}","health":9,"food":500,"rest":300,"activity":ColonyText.activity_name("Downed: bleeding, needs care")})=="Mira {health} | Health 9/100 | Food 500/1000 | Rest 300/1000\nDowned: bleeding, needs care" and ColonyText.text("ui.care.resting",{"rate":8,"hours":"%.1f" % [25.0/8]})=="Stabilized. Resting restores 8 health/hour; about 3.1 hours to work at 50 health. Treatment recovery lasts 12 hours, then resting gives 2/hour.")
	check.call("TEXT/newcomer_actions_and_deadline_keep_names_literal_and_rounding",ColonyText.text("ui.newcomers.accept",{"name":"Guest {hours}"})=="Accept Guest {hours}" and ColonyText.text("ui.newcomers.decline",{"name":"Guest {hours}"})=="Decline Guest {hours}" and ColonyText.text("ui.newcomers.waits",{"hours":"%.1f" % [48.0]})=="Waits 48.0 more game hours. No hidden reputation penalty if this expires.")

static func person_panels(game: GameSession, check: Callable) -> void:
	game._replace_world(ColonyTests.world());game.close_sheet();game.close_inspector();game._tutorial_dismiss()
	var processing: bool=game.is_processing();game.set_process(false)
	var person: Dictionary=game.world.citizens[0];person.name="Mira {food}";person.activity="Sleeping"
	var before: String=game.world.canonical_hash();var camera: Vector2=game.view.camera_center()
	game.show_person(person.id)
	var summary: String="%s\n%s | %s\n%s work, %s food" % [person.activity,person.traits[0],person.traits[1],person.preferred,person.food_tag]
	var needs: Array=game.sheet_body.find_child("ResidentNeeds",true,false).find_children("*","Label",true,false).map(func(n:Node)->String:return n.text)
	var exact_needs: bool=needs==["Food %d/1000" % person.fullness,"Rest %d/1000" % person.rest,"Health %d/100" % person.health,"Morale %d/1000" % person.morale]
	check.call("TEXT/UI_person_labels_and_real_bed_rate_preserve_state_and_camera",exact_needs and (game.sheet_heading.text==person.name or game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text==person.name)) and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text==summary) and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text==ColonyBeds.description(game.world,person)) and game.world.canonical_hash()==before and game.view.camera_center().is_equal_approx(camera),JSON.stringify({"summary":summary,"labels":game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Label).map(func(n:Node)->String:return n.text),"same_state":game.world.canonical_hash()==before,"camera_before":camera,"camera_after":game.view.camera_center()}))

	var care_exact: bool=true;var care_rows: Array=[]
	person.name="Patient {hours}";person.downed=true;person.health=9
	for kind in ["bleeding","treated","hearthside"]:
		person.stabilized=kind!="bleeding";person.hearthside_until=game.world.tick+7200 if kind=="hearthside" else 0
		person.recovery_rate=8;person.recovery_until=game.world.tick+3600
		before=game.world.canonical_hash();game.show_care()
		var expected: String="Hearthside recovery: 1.0 days until waking at 40 health." if kind=="hearthside" else ("Bleeding: 2 health/hour. About 5.0 hours until zero health without care." if kind=="bleeding" else "Stabilized. Resting restores 8 health/hour; about 5.1 hours to work at 50 health. Treatment recovery lasts 12 hours, then resting gives 2/hour.")
		care_rows.append({"kind":kind,"expected":expected,"labels":game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Label).map(func(n:Node)->String:return n.text),"same_state":game.world.canonical_hash()==before,"camera":game.view.camera_center()})
		care_exact=care_exact and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text==expected) and game.world.canonical_hash()==before and game.view.camera_center().is_equal_approx(camera)
	check.call("TEXT/UI_care_cases_show_original_bleeding_treatment_and_hearthside_numbers",care_exact,JSON.stringify(care_rows))
	person.hearthside_until=0;game.world.citizens[1].name="Care {hours}";game.show_care()
	var treat: Button
	for child in game.sheet_body.get_children():
		if child is Button and child.text=="Treat with Care {hours}":treat=child;break
	if is_instance_valid(treat):treat.pressed.emit()
	check.call("TEXT/UI_named_care_action_keeps_real_patient_worker_ids",is_instance_valid(treat) and game.world.pending_commands.size()==1 and game.world.pending_commands[0].kind=="treat_now" and game.world.pending_commands[0].args=={"target":person.id,"citizen":2} and game.world.tick==1800)

	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
	game.world._structure("bedroll",Vector2i(80,80),0)
	var request: Dictionary=ColonyPopulation.offer(game.world);request.candidate.name="Guest {hours}"
	before=game.world.canonical_hash();game.show_newcomers()
	var candidate: Dictionary=request.candidate
	var expected: String="%s · %s first · %s / %s · prefers %s food" % [candidate.name,candidate.preferred,candidate.traits[0],candidate.traits[1],candidate.food]
	check.call("TEXT/UI_newcomer_names_and_stored_tags_remain_literal_and_unchanged",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text==expected) and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Decline Guest {hours}") and game.world.canonical_hash()==before)
	var accept: Button
	for child in game.sheet_body.get_children():
		if child is Button and child.text=="Accept Guest {hours}":accept=child;break
	if is_instance_valid(accept):accept.pressed.emit()
	check.call("TEXT/UI_named_newcomer_accept_keeps_offer_id_without_a_tick",is_instance_valid(accept) and game.world.pending_commands.size()==1 and game.world.pending_commands[0].kind=="newcomer" and game.world.pending_commands[0].args=={"target":request.id,"accept":true} and request.state=="Offered" and game.world.tick==1800)
	game.close_sheet();game._replace_world(ColonyTests.world());game.journal_elapsed=0.0;game.set_process(processing)

static func ui(game: GameSession, check: Callable) -> void:
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
	var before: String = game.world.canonical_hash()
	game.begin_placement();game.view.preview_start=Vector2i(50,60);game.view.preview_end=game.view.preview_start
	check.call("TEXT/UI_single_cell_preview_uses_singular_tile",game._preview_text()=="1 x 1 tile | Stockpile preview")
	game.view.preview_end=Vector2i(51,61)
	check.call("TEXT/UI_area_preview_uses_plural_tiles",game._preview_text()=="2 x 2 tiles | Stockpile preview")
	game.begin_build("door");game.view.preview_start=Vector2i(66,63);game.view.preview_end=game.view.preview_start
	check.call("TEXT/UI_one_rejected_cell_has_singular_explanation",game._preview_text().contains("1 blocked cell stays unsubmitted"),game._preview_text())
	game.view.preview_end=Vector2i(67,63)
	check.call("TEXT/UI_many_rejected_cells_have_plural_explanation",game._preview_text().contains("2 blocked cells stay unsubmitted"),game._preview_text())
	var tree: Dictionary = game.world.resources.filter(func(r:Dictionary)->bool:return r.definition=="tree")[0]
	game.begin_gather("tree");game.view.preview_start=Vector2i(tree.x,tree.y);game.view.preview_end=game.view.preview_start
	check.call("TEXT/UI_one_resource_uses_singular_tree",game._preview_text().contains("1 unmarked tree\n"),game._preview_text())
	check.call("TEXT/UI_localized_previews_do_not_change_saved_state",game.world.canonical_hash()==before and game.world.pending_commands.is_empty())
	game.cancel_placement()

	game.show_sheet("Build","ui.sheet.build")
	check.call("TEXT/UI_translated_heading_keeps_internal_build_route",game.sheet_name=="Build" and game.sheet_title_key=="ui.sheet.build" and game.sheet_full_heading.text=="Build" and game.sheet_heading.tooltip_text=="Build")
	game.show_sheet("Mira {count}")
	check.call("TEXT/UI_literal_name_heading_keeps_braces_and_no_localization_key",game.sheet_name=="Mira {count}" and game.sheet_title_key.is_empty() and game.sheet_full_heading.text=="Mira {count}")
	game.close_sheet();game._shortcut("journal")
	check.call("TEXT/UI_keyboard_route_uses_key_without_changing_id",game.sheet_name=="Journal" and game.sheet_title_key=="ui.sheet.journal" and game.sheet_full_heading.text=="Journal")
	game.close_sheet()

	var person: Dictionary=game.world.citizens[0];person.fullness=200;person.rest=200
	var before_person: String=game.world.canonical_hash();game.show_person(person.id)
	check.call("TEXT/UI_low_food_and_rest_explains_work_priority_without_state_changes",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("clearing door access over construction") and n.text.contains("rest 100")) and game.world.canonical_hash()==before_person)
	game.sheet_body.get_node("RestPolicyToggle").button_pressed=true
	check.call("TEXT/UI_rest_card_exposes_tired_wake_and_actual_recovery_rates",game.sheet_body.find_children("*","Label",true,false).any(func(n:Node)->bool:return n.is_visible_in_tree() and n.text.contains("tired at 300") and n.text.contains("Wake at 900/1000") and n.text.contains("bed 75, bedroll 60, ground 45")) and game.world.canonical_hash()==before_person)
	var bedroll: Dictionary=game.world.structures.filter(func(s:Dictionary)->bool:return s.definition=="bedroll")[0]
	game.show_station(bedroll)
	check.call("TEXT/UI_bedroll_station_reports_current_recovery_rate",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.begins_with("Rest 60/hour.")) and game.world.canonical_hash()==before_person)
	var bed: Dictionary=game.world._structure("bed",Vector2i(90,80),0)
	var before_bed: String=game.world.canonical_hash();game.show_station(bed)
	check.call("TEXT/UI_bed_station_reports_current_recovery_rate",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.begins_with("Rest 75/hour.")) and game.world.canonical_hash()==before_bed)
	game.close_sheet()
	access_help(game,check)

static func access_help(game: GameSession, check: Callable) -> void:
	game._replace_world(PolicyTests.enclosed_tree_world());game.close_sheet();game._tutorial_dismiss()
	var person: Dictionary=game.world.citizens[0];person.name="Mira {portions}"
	var tree: Dictionary=game.world.resources[-1]
	var before: String=game.world.canonical_hash()
	game.show_person(person.id)
	check.call("TEXT/UI_trapped_hungry_person_explains_stored_but_unreachable_food",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Mira {portions} cannot reach") and n.text.contains("blocked entrances") and n.text.contains("reservations")))
	check.call("TEXT/UI_food_access_diagnosis_is_read_only_and_paused",game.world.canonical_hash()==before and game.world.pending_commands.is_empty() and game.runner.speed==0)
	game._resource_sheet(tree)
	check.call("TEXT/UI_mature_tree_at_door_explains_cutting_to_reopen_access",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("beside a door or gate") and n.text.contains("gather a mature tree")) and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Gather") and game.world.canonical_hash()==before)
	tree.remaining=0;game.world.navigation_dirty=true;game.world.reachability_dirty=true
	before=game.world.canonical_hash();game._resource_sheet(tree)
	check.call("TEXT/UI_stump_warns_before_replanting_a_future_solid_exit",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("Mature trees are solid")) and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text=="Replant tree (4 WU)") and game.world.canonical_hash()==before)
	check.call("TEXT/UI_reopened_exit_clears_food_access_warning_without_ticking",game.food_access_description(person).is_empty() and game.world.canonical_hash()==before)
	tree.remaining=8;game.world.navigation_dirty=true;game.world.reachability_dirty=true
	var excluded: bool=true
	for state in ["away","downed","departed","death_recorded"]:
		person[state]=true
		excluded=excluded and game.food_access_description(person).is_empty()
		person[state]=false
	person.fullness=500
	check.call("TEXT/UI_access_warning_only_describes_living_home_hungry_walkers",excluded and game.food_access_description(person).is_empty())
	game.close_sheet()

static func literal_routes(game: GameSession, check: Callable) -> void:
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
	var cart: Dictionary=ColonyTrade.cart(game.world)
	for name in ["Build","Menu","Work","Delete saves","Save problem"]:
		for target in [1,cart.id]:
			var result: String=ColonyChronicle.command(game.world,"rename",{"target":target,"text":name})
			var before: String=game.world.canonical_hash()
			if target==1: game.show_person(target)
			else: game.show_station(cart)
			var literal: bool=game.sheet_name==name and game.sheet_route.is_empty() and game.sheet_title_key.is_empty() and game.sheet_full_heading.text==name
			var clean: bool=game.sheet_body.get_node_or_null("WorkOrderCounts")==null and not game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text in ["Paint stockpile","Manage saves"])
			game.close_sheet()
			check.call("TEXT/UI_%s_named_%s_stays_a_read_only_literal_card" % ["resident" if target==1 else "station",name.to_lower().replace(" ","_")],result=="accepted" and literal and clean and game.sheet==null and game.sheet_route.is_empty() and game.runner.speed==0 and game.world.canonical_hash()==before and game.world.pending_commands.is_empty())
	for route in ["Build","Menu"]:
		game.show_sheet(route,ColonyText.sheet_key(route))
		var expected: String="Paint stockpile" if route=="Build" else "Manage saves"
		check.call("TEXT/UI_builtin_%s_keeps_its_explicit_route_and_actions" % route.to_lower(),game.sheet_route==route and not game.sheet_title_key.is_empty() and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Button and n.text==expected))
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
