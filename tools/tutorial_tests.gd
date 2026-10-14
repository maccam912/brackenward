class_name TutorialTests
extends RefCounted
## Isolated lesson/persistence contracts; gameplay evidence uses real work transactions.
static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var state: Dictionary = ColonyTutorial.initial_state()
	var original: String = world.canonical_hash()
	check.call("TUTORIAL/look_around_starts_without_prompts",ColonyTutorial.card(world,state).is_empty() and not state.enabled)
	ColonyTutorial.begin(state)
	check.call("TUTORIAL/begin_starts_follow_without_timer",state.active=="follow" and ColonyTutorial.card(world,state).entity==1 and world.tick==1800)
	ColonyTutorial.action(world,state,"follow",{"citizen":999999})
	check.call("TUTORIAL/missing_follow_target_cannot_complete",not state.completed.has("follow"))
	ColonyTutorial.action(world,state,"follow",{"citizen":1})
	check.call("TUTORIAL/real_follow_advances_to_forage",state.completed==["follow"] and state.active=="forage")
	ColonyTutorial.skip(state)
	check.call("TUTORIAL/skip_is_not_completion",state.skipped==["forage"] and not state.completed.has("forage") and state.active=="lodge")
	ColonyTutorial.dismiss(state)
	check.call("TUTORIAL/dismiss_retains_progress",not state.enabled and state.active=="lodge" and state.completed==["follow"])
	ColonyTutorial.replay(state,"follow");ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/replay_keeps_completed_lesson_visible",state.active=="follow" and state.replaying and not ColonyTutorial.card(world,state).is_empty())
	check.call("TUTORIAL/lessons_never_change_authoritative_world",original==world.canonical_hash())
	ColonyTutorial.replay(state,"forage")
	var first: Dictionary = ColonyTutorial.card(world,state)
	world.find(world.resources,first.entity).remaining=0
	var replacement: Dictionary = ColonyTutorial.card(world,state)
	check.call("UI09/depleted_target_is_reselected",replacement.entity!=first.entity and (replacement.entity>0 or not replacement.prerequisite.is_empty()))
	for resource in world.resources:
		if resource.definition=="berry_bush": resource.remaining=0
	var missing: Dictionary = ColonyTutorial.card(world,state)
	check.call("UI09/no_valid_target_explains_prerequisite",missing.target.is_empty() and missing.entity==0 and missing.prerequisite.contains("No safe ripe"))
	world=ColonyTests.world();state=ColonyTutorial.initial_state()
	var berry: Dictionary = world._make_stack("berry",1,"ground",0,Vector2i(66,63),true)
	var person: Dictionary = world.citizens[0]
	var haul: Dictionary = world._job("haul","Hauling","",berry.id,Vector2i(berry.x,berry.y),0);haul.source=berry.id
	ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/issued_order_is_not_berry_delivery",not state.completed.has("forage"))
	if world._reserve(haul,person):
		person.job=haul.id;person.x=berry.x;person.y=berry.y;world._work(person,haul)
		person.x=haul.work_x;person.y=haul.work_y;world._work(person,haul)
	ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/actual_berry_delivery_records_evidence",haul.state=="Complete" and state.completed.has("forage") and world.invariant_errors().is_empty())
	var site: Array = ColonyTutorial.lodge_target(world)
	check.call("TUTORIAL/lodge_suggestion_is_valid_and_deterministic",not site.is_empty() and site==ColonyTutorial.lodge_target(world) and ColonyConstruction.lodge_error(world,Vector2i(site[0],site[1])).is_empty())
	if not site.is_empty(): ColonyConstruction.command(world,"lodge",{"x":site[0],"y":site[1]})
	ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/lodge_requires_real_blueprints",state.completed.has("lodge") and world.construction_state.groups[0].members.size()==28)
	world=ColonyTests.world();state=ColonyTutorial.initial_state()
	var hearth: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	var cook: Dictionary = world._job("cook","Cooking","Cooking",hearth.id,Vector2i(hearth.x,hearth.y),24000)
	cook.inputs={"berry":4,"wood":1};cook.output={"meal":2}
	ColonyTutorial.action(world,state,"hearth");ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/inspection_and_queued_cooking_are_not_a_batch",not state.completed.has("cook"))
	for item in cook.inputs: world._make_stack(item,cook.inputs[item],"escrow",cook.id,Vector2i(hearth.x,hearth.y),true)
	person=world.citizens[0];cook.worker=person.id;person.job=cook.id;world._finish(person,cook)
	ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/actual_cooked_batch_and_inspection_complete",state.completed.has("cook") and world.ledger.produced.meal==26 and world.invariant_errors().is_empty())
	var field_site: Array = ColonyTutorial.field_target(world)
	var tiles: Array[Vector2i] = []
	for y in range(field_site[1],field_site[1]+2):
		for x in range(field_site[0],field_site[0]+4): tiles.append(Vector2i(x,y))
	var accepted: String = ColonyAgriculture.designate(world,{"crop":"turnip","tiles":tiles})
	ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/field_requires_eight_planted_tiles",accepted=="accepted" and not state.completed.has("field"))
	for field in world.fields: field.planted=true
	ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/planted_field_evidence_completes",state.completed.has("field"))
	person.preferences.Cooking=3;ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/priority_waits_for_real_assignment",not state.completed.has("cooking_priority"))
	var next: Dictionary = world._job("cook","Cooking","Cooking",hearth.id,Vector2i(hearth.x,hearth.y),24000);next.worker=person.id;person.job=next.id
	ColonyTutorial.action(world,state,"work_preferences",{"citizen":person.id})
	ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/priority_observes_next_cooking_assignment",state.completed.has("cooking_priority"))
	ColonyTutorial.action(world,state,"pin_forecast")
	check.call("TUTORIAL/forecast_pin_is_device_local",state.forecast_pinned and state.completed.has("forecast") and not world.payload().has("tutorial"))
	world=ColonyTests.world();state=ColonyTutorial.initial_state();world.tick=24*7200;world.citizens[0].health=90
	world._structure("research_desk",Vector2i(80,70),0);world.researched.append("trailcraft")
	var triggered: Array = ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/four_context_lessons_trigger_once",triggered==ColonyTutorial.TRIGGERS and ColonyTutorial.evaluate(world,state).is_empty())
	ColonyTutorial.replay(state,"cooking_priority");world.citizens[0].departed=true
	var gone: Dictionary = ColonyTutorial.card(world,state)
	check.call("UI09/departed_priority_target_is_not_highlighted",gone.entity==0 and gone.target.is_empty() and gone.prerequisite.contains("no longer"))
	generated_suggestions(check)
	planned_field_conflicts(check)
	explicit_meal_batch(check)
	persistence(check)

static func explicit_meal_batch(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var state: Dictionary = ColonyTutorial.initial_state()
	var hearth: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	world._make_stack("berry",4,"ground",0,Vector2i(hearth.x,hearth.y),true)
	ColonyTutorial.action(world,state,"hearth")
	world.queue_command("recipe_order",{"target":hearth.id,"definition":"cook_meals","mode":"Repeat","value":1,"priority":2,"filters":["berry"]})
	world.step();ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/explicit_batch_waits_for_physical_completion",not state.completed.has("cook"))
	for index in range(1500): world.step()
	ColonyTutorial.evaluate(world,state)
	check.call("TUTORIAL/hearth_make_one_batch_completes_cooking_lesson",state.completed.has("cook") and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="craft" and j.definition=="cook_meals" and j.state=="Complete") and world.ledger.produced.meal==26 and world.invariant_errors().is_empty(),str(world.invariant_errors()))

static func generated_suggestions(check: Callable) -> void:
	for site in ColonyGeneration.SITES:
		var world: ColonyWorld = ColonyTests.world()
		var error: String = ColonyGeneration.configure(world,718,site)
		var before: String = world.canonical_hash()
		var lodge: Array = ColonyTutorial.lodge_target(world)
		var field: Array = ColonyTutorial.field_target(world)
		var overlap: bool = false
		if not lodge.is_empty():
			for point in world.terrain_state.starter_field:
				if point.x>=lodge[0] and point.x<lodge[0]+8 and point.y>=lodge[1] and point.y<lodge[1]+6: overlap=true
		check.call("TUTORIAL/generated_%s_has_safe_suggestions" % site,error.is_empty() and not lodge.is_empty() and not field.is_empty() and not overlap and ColonyConstruction.lodge_error(world,Vector2i(lodge[0],lodge[1])).is_empty() and world.canonical_hash()==before,error)

static func planned_field_conflicts(check: Callable) -> void:
	for site in ColonyGeneration.SITES:
		var world: ColonyWorld = ColonyTests.world()
		ColonyGeneration.configure(world,104729,site)
		var lodge: Array = ColonyTutorial.lodge_target(world)
		ColonyConstruction.command(world,"lodge",{"x":lodge[0],"y":lodge[1]})
		var bed_job: Dictionary = world.find(world.jobs,world.construction_state.groups[0].first[0])
		var blocked: String = ColonyAgriculture.designate(world,{"crop":"turnip","tiles":[Vector2i(bed_job.x,bed_job.y)]})
		var field: Array = ColonyTutorial.field_target(world)
		var clear: bool = not field.is_empty()
		if clear:
			clear=not Rect2i(lodge[0],lodge[1],8,6).intersects(Rect2i(field[0],field[1],4,2))
		check.call("TUTORIAL/%s_next_field_avoids_unfinished_lodge_and_future_roof" % site,clear and blocked.contains("planned construction") and world.fields.is_empty(),str(field))
	var world: ColonyWorld = ColonyTests.world()
	var bed: Dictionary = world.find(world.structures,world.citizens[0].bed)
	var result: String = ColonyMaintenance.move_command(world,{"target":bed.id,"x":80,"y":70,"rotation":0})
	var blocked: String = ColonyAgriculture.designate(world,{"crop":"turnip","tiles":[Vector2i(80,70)]})
	var move_job: Dictionary = world.jobs[-1]
	world._release(move_job,true)
	var freed: String = ColonyAgriculture.designate(world,{"crop":"turnip","tiles":[Vector2i(80,70)]})
	check.call("TUTORIAL/field_respects_move_destination_until_canceled",result=="accepted" and blocked.contains("move destination") and freed=="accepted")

static func persistence(check: Callable) -> void:
	var settings: DeviceSettings = DeviceSettings.new()
	settings.path="user://tutorial-test-%d.json" % Time.get_ticks_usec()
	settings.values.text_scale=1.5;settings.values.left_handed=true
	var state: Dictionary = ColonyTutorial.campaign(settings,"campaign-a")
	ColonyTutorial.begin(state);ColonyTutorial.skip(state)
	var other: Dictionary = ColonyTutorial.campaign(settings,"campaign-b")
	check.call("TUTORIAL/campaigns_keep_independent_lesson_state",state.skipped==["follow"] and other.skipped.is_empty() and not other.enabled)
	var error: String = settings.save_local()
	var restored: DeviceSettings = DeviceSettings.new();restored.path=settings.path;restored.load_local()
	check.call("TUTORIAL/settings_roundtrip_preserves_lessons_and_accessibility",error.is_empty() and restored.values==settings.values,error)
	var legacy: Dictionary = {}
	for key in ["schema_version","text_scale","left_handed","last_slot","cameras"]: legacy[key]=settings.values[key]
	legacy.schema_version=1
	var handle: FileAccess = FileAccess.open(settings.path,FileAccess.WRITE);handle.store_string(JSON.stringify(legacy));handle.close()
	restored=DeviceSettings.new();restored.path=settings.path;restored.load_local()
	check.call("TUTORIAL/old_device_settings_upgrade_without_reset",restored.values.schema_version==3 and restored.values.text_scale==1.5 and restored.values.left_handed and restored.values.tutorials.is_empty())
	var invalid: Dictionary = ColonyTutorial.initial_state();invalid.completed=["invented"]
	check.call("TUTORIAL/malformed_lessons_rejected",not ColonyTutorial.valid(invalid))
	DirAccess.remove_absolute(settings.path)
