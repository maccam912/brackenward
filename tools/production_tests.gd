class_name ProductionTests
extends RefCounted

static func run(check: Callable) -> void:
	var w: ColonyWorld = ColonyTests.world()
	var forecast_before: Dictionary = FoodForecast.calculate(w)
	var stock_before: int = ColonyProduction.policy_stock(w,"meal")
	for index in range(50): w._make_stack("meal",0,"ground",0,Vector2i(66,64),false)
	check.call("PRODUCTION/empty_history_does_not_change_stock_or_forecast",FoodForecast.calculate(w)==forecast_before and ColonyProduction.policy_stock(w,"meal")==stock_before)
	w._make_stack("meal",1,"ground",0,Vector2i(66,64),true)
	check.call("PRODUCTION/new_food_after_empty_history_immediately_counted",ColonyProduction.policy_stock(w,"meal")==stock_before+1 and FoodForecast.calculate(w).portions==forecast_before.portions+1)
	w=ColonyTests.world()
	check.call("CATALOG/all_definitions_and_research_total",w.definitions.items.size() == 28 and w.definitions.buildings.size() == 34 and w.definitions.recipes.size() == 13 and w.definitions.research.values().reduce(func(total:int,r:Dictionary)->int:return total+r.points,0) == 4700)
	check.call("GEAR/starting_equipment_in_conservation_ledger",w.total("toolkit") == 4 and w.total("cloak") == 4 and w.total("bow") == 2 and w.total("spear") == 2 and w.invariant_errors().is_empty())
	var simple: Dictionary = w.citizens[1]
	var rate_job: Dictionary = w._job("build","Building","Build",0,Vector2i(74,63),100000)
	simple.equipment.toolkit = "forged_toolkit"
	var work: int = 0
	for i in range(100): work += w._rate(simple,rate_job)
	check.call("GEAR/forged_toolkit_fifteen_percent_exact",work == 14950)
	w = ColonyTests.world()
	var bench: Dictionary = w._structure("workbench",Vector2i(74,63),0)
	w.queue_command("recipe_order",{"target":bench.id,"definition":"make_toolkit","mode":"Repeat","value":2,"priority":2,"filters":[]})
	for i in range(1800): w.step()
	check.call("PRODUCTION/two_real_batches_fetch_work_consume_haul",w.production_state.orders[0].quantity == 0 and w.total("toolkit") == 6 and w.ledger.consumed.get("wood",0) == 4 and w.ledger.consumed.get("stone",0) == 2 and w.invariant_errors().is_empty(),str(w.invariant_errors()))
	var saved: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("PRODUCTION/policy_and_completed_batches_roundtrip",saved.has("world") and saved.world.canonical_hash() == w.canonical_hash(),str(saved.get("error","")))
	w = ColonyTests.world()
	bench = w._structure("workbench",Vector2i(74,63),0)
	w.queue_command("recipe_order",{"target":bench.id,"definition":"make_toolkit","mode":"Maintain","value":2,"priority":2,"filters":[]})
	for i in range(1800): w.step()
	check.call("PRODUCTION/maintain_counts_two_available_units_once",w.total("toolkit") == 6 and w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "craft").size() == 2)
	w = ColonyTests.world()
	var stations: Array[int] = []
	for x in [74,78,82]:
		bench=w._structure("workbench",Vector2i(x,63),0);stations.append(bench.id)
		ColonyProduction.command(w,"recipe_order",{"target":bench.id,"definition":"make_toolkit","mode":"Maintain","value":2,"priority":2,"filters":[]})
	ColonyProduction.command(w,"recipe_order",{"target":stations[0],"definition":"make_toolkit","mode":"Repeat","value":1,"priority":3,"filters":[]})
	ColonyProduction.create_jobs(w)
	var batches: Array = w.jobs.filter(func(j:Dictionary)->bool:return j.kind=="craft")
	check.call("PRODUCTION/shared_maintain_target_counts_new_batches_and_station_occupancy",batches.size()==2 and batches[0].target==stations[0] and batches[1].target==stations[1] and batches[0].priority==3)
	w = ColonyTests.world()
	bench = w._structure("workbench",Vector2i(74,63),0)
	w.queue_command("recipe_order",{"target":bench.id,"definition":"make_bow","mode":"Repeat","value":1,"priority":2,"filters":[]})
	w.step()
	check.call("PRODUCTION/locked_recipe_names_research",w.production_state.orders.is_empty() and w.receipts[1].contains("Woodcraft"))
	var all_points: int = 0
	w = ColonyTests.world()
	var desk: Dictionary = w._structure("research_desk",Vector2i(74,63),0)
	w.queue_command("research_select",{"definition":"metalwork"})
	w.step()
	check.call("RESEARCH/prerequisites_visible_and_enforced",w.production_state.project.is_empty() and w.receipts[1].contains("Masonry"))
	for project in ["storecraft","farming","herbalism","woodcraft","masonry","weaving","metalwork","husbandry","trailcraft","commonlife","signalcraft","valley_charter"]:
		var result: String = ColonyProduction.command(w,"research_select",{"definition":project})
		var researcher: Dictionary = w.citizens[3]
		var job: Dictionary = w._job("research","Research","Study",desk.id,Vector2i(desk.x,desk.y),w.definitions.research[project].points*1000)
		job.definition = project; job.state = "Working"; job.worker = researcher.id; researcher.job = job.id
		for tick in range(15000):
			if job.state == "Complete": break
			ColonyProduction.research_work(w,researcher,job)
		check.call("RESEARCH/completes_"+project,result == "accepted" and w.researched.has(project) and w.production_state.progress[project] == w.definitions.research[project].points*1000)
		all_points += w.definitions.research[project].points
	check.call("RESEARCH/exact_4700_points_and_productive_xp",all_points == 4700 and w.citizens[3].xp.Study == 7100000 and w.citizens[3].skills.Study == 5)
	w = ColonyTests.world()
	desk = w._structure("research_desk",Vector2i(74,63),0)
	for person in w.citizens: person.preferences.Research = 0
	w.citizens[3].preferences.Research = 3
	w.queue_command("research_select",{"definition":"storecraft"})
	for tick in range(3000): w.step()
	check.call("RESEARCH/real_scheduler_walks_and_finishes_project",w.researched.has("storecraft") and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "research" and j.state == "Complete") and w.invariant_errors().is_empty())
	var legacy: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m3-social.brackenward"))
	check.call("SAVE/M3_social_to_complete_catalog_and_equipment",legacy.has("world") and legacy.world.citizens[0].preferences.Gathering == 3 and legacy.world.total("toolkit") == 4 and legacy.world.invariant_errors().is_empty(),str(legacy.get("error","")))
	w = ColonyTests.world()
	ColonyProduction.add_insight(w,1200)
	check.call("RESEARCH/insight_bank_capped_without_project",w.production_state.insight == 1000)
	ColonyProduction.command(w,"research_queue",{"definition":"farming"})
	ColonyProduction.command(w,"research_queue",{"definition":"weaving"})
	ColonyProduction.command(w,"research_select",{"definition":"storecraft"})
	check.call("RESEARCH/insight_carries_through_prerequisite_queue",w.researched == ["storecraft","farming","weaving"] and w.production_state.insight == 100 and w.production_state.project == "" and w.citizens[3].xp.Study == 2400000)
	check.call("RESEARCH/curious_discovery_memory",w.production_state.discoveries.get(4) == w.tick+14400)
	w = ColonyTests.world()
	desk = w._structure("research_desk",Vector2i(74,63),0)
	ColonyProduction.command(w,"research_select",{"definition":"storecraft"})
	var retained: Dictionary = w._job("research","Research","Study",desk.id,Vector2i(desk.x,desk.y),240000)
	retained.definition = "storecraft"; retained.worker = 4; retained.state = "Working"; w.citizens[3].job = retained.id
	for tick in range(100): ColonyProduction.research_work(w,w.citizens[3],retained)
	var original_progress: int = w.production_state.progress.storecraft
	ColonyProduction.command(w,"research_select",{"definition":"farming"})
	check.call("RESEARCH/switch_releases_worker_keeps_work",retained.worker == 0 and retained.work == original_progress and w.production_state.progress.storecraft == original_progress)
	ColonyProduction.command(w,"research_select",{"definition":"storecraft"})
	ColonyProduction.add_insight(w,240)
	check.call("RESEARCH/inactive_contributor_xp_awarded_once",retained.state == "Complete" and w.citizens[3].xp.Study == 2400000+original_progress and w.researched.count("storecraft") == 1)
	var queued: Array[String] = ["farming","herbalism","woodcraft"]
	for id in queued: ColonyProduction.command(w,"research_queue",{"definition":id})
	check.call("RESEARCH/queue_limit_and_duplicates",ColonyProduction.command(w,"research_queue",{"definition":"trailcraft"}).contains("three") and w.production_state.queue == queued)
	w = ColonyTests.world()
	var hearth: Dictionary = w.structures.filter(func(s:Dictionary)->bool:return s.definition == "hearth")[0]
	var cooking: Dictionary = w._job("cook","Cooking","Cooking",hearth.id,Vector2i(hearth.x,hearth.y),8000)
	cooking.inputs = {"wood":1,"berry":4}; cooking.output = {"meal":2}; cooking.work = 4000; cooking.pending_xp[1] = 4000
	var old: Dictionary = w._make_stack("berry",4,"escrow",cooking.id,Vector2i(hearth.x,hearth.y),true)
	old.age = w.definitions.items.berry.shelf_ticks-1
	w._make_stack("mushroom",4,"ground",0,Vector2i(hearth.x,hearth.y),true)
	ColonyLiving.advance(w)
	check.call("PRODUCTION/spoiled_inputs_retain_partial_work",cooking.work == 4000 and cooking.pending_xp[1] == 4000 and cooking.state == "Blocked")
	ColonyProduction.replace_food(w,cooking)
	check.call("PRODUCTION/replacement_uses_allowed_fresh_alternative",cooking.inputs == {"wood":1,"mushroom":4})
	w = ColonyTests.world()
	hearth = w.structures.filter(func(s:Dictionary)->bool:return s.definition == "hearth")[0]
	w._make_stack("berry",4,"ground",0,Vector2i(hearth.x,hearth.y),true)
	ColonyProduction.command(w,"recipe_order",{"target":hearth.id,"definition":"cook_meals","mode":"Repeat","value":1,"priority":3,"filters":["berry"]})
	w._create_work(); ColonyProduction.create_jobs(w)
	check.call("PRODUCTION/explicit_hearth_order_replaces_default_policy",w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "cook").is_empty() and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "craft" and j.inputs.get("berry") == 4 and j.priority == 3))
	var malformed: Dictionary = w.payload().duplicate(true)
	malformed.production_state.queue = ["farming","farming"]
	check.call("SAVE/rejects_duplicate_research_queue",ColonyCodec.restore(malformed).has("error"))
	var native: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-production.brackenward"))
	check.call("SAVE/native_M4_research_fixture_retained",native.has("world") and native.world.tick == 3415 and native.world.production_state.project == "storecraft" and native.world.total("toolkit") == 4,str(native.get("error","")))
