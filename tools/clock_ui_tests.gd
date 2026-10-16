class_name ClockUITests
extends RefCounted

class CountingWorld extends ColonyWorld:
	var stock_reads: int = 0
	func _init(catalog: Dictionary) -> void: super(catalog)
	func available(item: String) -> int:
		stock_reads+=1
		return super(item)

static func run(game: GameSession, check: Callable) -> void:
	var base: ColonyWorld=ColonyTests.world()
	var counted: CountingWorld=CountingWorld.new(base.definitions)
	for field in base.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=base.get(field)
		if value is Array: counted.get(field).assign(value.duplicate(true))
		elif value is Dictionary: counted.set(field,value.duplicate(true))
		else: counted.set(field,value)
	counted.record_indexes.clear();counted.reset_job_queries();counted.reset_stack_queries()
	game._replace_world(counted);game.close_sheet();game._tutorial_dismiss()
	counted.stock_reads=0
	var canonical: String=counted.canonical_hash()
	game._refresh_clock()
	var initial: String=game.clock_label.text
	for frame in range(120): game._refresh_clock()
	check.call("PERF/UI_unchanged_clock_reads_stock_once",counted.stock_reads==2 and game.clock_label.text==initial)
	check.call("TEXT/UI_new_colony_clock_keeps_exact_english",initial=="Spring 1 Y1  06:00 Dawn\nMeals 24  Wood 40 | Paused",initial)
	game.runner.set_speed(4);game._refresh_clock()
	check.call("PERF/UI_speed_changes_without_waiting_for_a_tick",game.clock_label.text.ends_with(" | 4x") and counted.tick==1800)
	game.runner.pause();game._refresh_clock()
	check.call("PERF/UI_pause_changes_without_waiting_for_a_tick",game.clock_label.text.ends_with(" | Paused") and counted.tick==1800)
	check.call("PERF/UI_clock_queries_preserve_all_simulation_state",counted.canonical_hash()==canonical)
	counted._make_stack("meal",3,"ground",0,Vector2i(66,63),true);counted.tick+=5
	game._refresh_clock()
	check.call("PERF/UI_next_tick_refreshes_time_and_real_stock",game.clock_label.text=="Spring 1 Y1  06:01 Dawn\nMeals 27  Wood 40 | Paused",game.clock_label.text)
	var replacement: ColonyWorld=ColonyTests.world();replacement.tick=counted.tick
	replacement._make_stack("meal",7,"ground",0,Vector2i(66,63),true)
	game._replace_world(replacement);game.close_sheet();game._refresh_clock()
	check.call("PERF/UI_world_adoption_at_same_tick_refreshes_stock",game.clock_label.text=="Spring 1 Y1  06:01 Dawn\nMeals 31  Wood 40 | Paused",game.clock_label.text)
	var labels: Array=[]
	for season in range(4):
		replacement.tick=season*57600+23*300+59*5;game._refresh_clock();labels.append(game.clock_label.text.get_slice("\n",0))
	replacement.tick=230400;game._refresh_clock()
	check.call("TEXT/UI_calendar_seasons_and_year_rollover",labels==["Spring 1 Y1  23:59 Night","Summer 1 Y1  23:59 Night","Autumn 1 Y1  23:59 Night","Winter 1 Y1  23:59 Night"] and game.clock_label.text.begins_with("Spring 1 Y2  00:00 Night"),str(labels))
	for count in [0,1,4]:
		var prototype: PrototypeWorld=PrototypeWorld.new();prototype.citizens.resize(count)
		game.world=prototype;game.runner=SimRunner.new(prototype);game._refresh_clock()
		check.call("TEXT/UI_prototype_traveler_plural_%d" % count,game.clock_label.text=="Spring 1 Y1  06:00 Dawn\n%d %s | Paused" % [count,"traveler" if count==1 else "travelers"],game.clock_label.text)
	game._replace_world(ColonyTests.world());game.close_sheet();game._tutorial_dismiss()
