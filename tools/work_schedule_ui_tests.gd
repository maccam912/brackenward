class_name WorkScheduleUITests
extends RefCounted

static func schedule(game: GameSession) -> Button:
	return game.sheet_body.find_child("WorkSchedule",true,false)

static func run(game: GameSession, check: Callable) -> void:
	game._replace_world(ColonyTests.world());game.close_sheet();game.close_inspector();game._tutorial_dismiss()
	var processing: bool=game.is_processing();game.set_process(false)
	game.runner.set_speed(4);game.show_work_preferences(1)
	var tick: int=game.world.tick;var camera: Vector2=game.view.camera_tile
	var shift: Button=schedule(game);shift.pressed.emit()
	check.call("WORK/UI_paused_shift_immediately_shows_queued_value_without_advancing",shift.text=="Night shift (pending)" and shift.tooltip_text==shift.text and game.world.pending_commands.size()==1 and game.world.pending_commands[0].kind=="schedule" and game.world.pending_commands[0].args.shift=="Night shift" and game.world.citizens[0].shift=="Normal" and game.world.tick==tick and game.runner.speed==0)
	game.show_work_preferences(1);shift=schedule(game)
	check.call("WORK/UI_reopening_preferences_keeps_pending_shift_and_camera",shift.text=="Night shift (pending)" and shift.tooltip_text==shift.text and game.world.pending_commands.size()==1 and game.world.tick==tick and game.view.camera_tile==camera)
	shift.pressed.emit()
	var values: Array=game.world.pending_commands.map(func(command:Dictionary)->String:return command.args.shift)
	check.call("WORK/UI_repeated_paused_shift_toggles_from_latest_pending_value",shift.text=="Normal (pending)" and shift.tooltip_text==shift.text and values==["Night shift","Normal"] and game.world.citizens[0].shift=="Normal" and game.world.tick==tick and game.view.camera_tile==camera)
	game.world.step();game.show_work_preferences(1)
	check.call("WORK/UI_pending_shift_batch_applies_once_in_order_and_clears_caption",schedule(game).text=="Normal" and game.world.citizens[0].shift=="Normal" and game.world.pending_commands.is_empty() and game.world.receipts.values()==["accepted","accepted"] and game.world.tick==tick+1 and game.world.invariant_errors().is_empty())
	game.close_sheet();game._replace_world(ColonyTests.world());game.journal_elapsed=0.0;game.set_process(processing)
