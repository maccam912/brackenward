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
	check.call("TEXT/UI_low_food_and_rest_explains_work_priority_without_state_changes",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("instead of restarting it") and n.text.contains("rest 100")) and game.world.canonical_hash()==before_person)
	game.close_sheet()
