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
