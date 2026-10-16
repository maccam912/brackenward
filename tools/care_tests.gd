class_name CareTests
extends RefCounted

static func run(check: Callable) -> void:
	var w: ColonyWorld = ColonyTests.world()
	var patient: Dictionary = w.citizens[1]
	ColonyCare.hurt(w,patient,1000,true)
	check.call("CARE/attack_downing_caps_at_ten_and_releases_work",patient.health == 10 and patient.downed and not patient.stabilized and patient.job == 0)
	ColonyCare.hurt(w,patient,8,true)
	check.call("CARE/downed_not_attack_target",patient.health == 10)
	for i in range(299): w.tick += 1; ColonyCare.advance(w)
	check.call("CARE/no_bleed_before_whole_hour",patient.health == 10)
	w.tick += 1; ColonyCare.advance(w)
	check.call("CARE/bleeding_exactly_two_per_hour",patient.health == 8 and patient.bleed_ticks == 0)
	w = ColonyTests.world()
	patient = w.citizens[1]
	ColonyCare.hurt(w,patient,90,true)
	var healer: Dictionary = w.citizens[0]
	var job: Dictionary = w._job("treat","Care","Care",patient.id,Vector2i(patient.x,patient.y),16000)
	job.definition = "herb"; job.inputs = {"herb":1}; job.work = 16000
	w._make_stack("herb",1,"escrow",job.id,Vector2i(patient.x,patient.y),true)
	w._finish(healer,job)
	check.call("CARE/herb_atomic_consumption_and_effect",patient.stabilized and patient.health == 20 and patient.recovery_rate == 4 and patient.recovery_until == w.tick+3600 and w.ledger.consumed.herb == 1 and w.invariant_errors().is_empty())
	for i in range(300): w.tick += 1; ColonyCare.advance(w)
	check.call("CARE/healing_four_per_hour_with_fractional_remainder",patient.health == 21 and not patient.downed and patient.healing_ticks == 0)
	# Walking patients stop ground recovery: only their resting ticks earned healing.
	patient.downed = true; patient.health = 20
	for i in range(300): w.tick += 1; ColonyCare.advance(w)
	check.call("CARE/mobile_patient_does_not_heal_without_rest",patient.health == 21)
	w = ColonyTests.world()
	patient = w.citizens[1]
	ColonyCare.hurt(w,patient,90,true)
	job = w._job("treat","Care","Care",patient.id,Vector2i(patient.x,patient.y),10000)
	job.definition = "medicine"; job.inputs = {"medicine":1}; job.work = 10000
	w._make_stack("medicine",1,"escrow",job.id,Vector2i(patient.x,patient.y),true)
	w._finish(w.citizens[0],job)
	check.call("CARE/medicine_twenty_immediate_eight_per_hour",patient.health == 30 and not patient.downed and patient.recovery_rate == 8 and w.ledger.consumed.medicine == 1)
	job = w._job("treat","Care","Care",patient.id,Vector2i(patient.x,patient.y),24000)
	job.definition = "stabilize"; job.work = 24000
	w._finish(w.citizens[0],job)
	check.call("CARE/recovery_rates_never_add_or_downgrade",patient.recovery_rate == 8)
	var recover: Dictionary = w._job("recover","","",patient.bed,Vector2i(patient.x,patient.y),0)
	recover.worker = patient.id; recover.state = "Working"; patient.job = recover.id
	for i in range(300): w.tick += 1; ColonyCare.advance(w)
	check.call("CARE/resting_medicine_exact_hour",patient.health == 38 and patient.healing_ticks == 0)
	patient.recovery_windows.medicine = w.tick
	for i in range(300): w.tick += 1; ColonyCare.advance(w)
	check.call("CARE/after_window_rest_heals_two",patient.health == 40)
	w = ColonyTests.world()
	patient = w.citizens[1]; patient.fullness = 100
	ColonyCare.hurt(w,patient,90,true)
	for person in w.citizens:
		for category in person.preferences: person.preferences[category] = 0
	w.citizens[0].preferences.Care = 3
	for i in range(2000): w.step()
	check.call("CARE/real_rescue_treat_feed_and_rest",patient.health >= 21 and patient.stabilized and patient.fullness > 0 and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "rescue" and j.state == "Complete") and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "treat" and j.state == "Complete") and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "feed" and j.state == "Complete") and w.invariant_errors().is_empty(),str([patient,w.invariant_errors()]))
	check.call("CARE/kind_rescue_credit_once",w.social_state.pairs["1:2"].score == 45)
	var snapshot: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("CARE/treatment_and_recovery_roundtrip",snapshot.has("world") and snapshot.world.canonical_hash() == w.canonical_hash(),str(snapshot.get("error","")))
	w = ColonyTests.world()
	patient = w.citizens[1]
	ColonyCare.hurt(w,patient,90,true)
	for person in w.citizens:
		for category in person.preferences: person.preferences[category] = 0
	for i in range(200): w.step()
	check.call("CARE/rescue_overrides_off_but_not_treatment",w.jobs.any(func(j:Dictionary)->bool:return j.kind == "rescue" and j.state == "Complete") and not w.jobs.any(func(j:Dictionary)->bool:return j.kind == "treat" and j.state == "Complete"))
	var result: String = ColonyCare.command(w,"treat_now",{"target":patient.id,"citizen":1})
	for i in range(700): w.step()
	check.call("CARE/explicit_treat_now_overrides_care_off_once",result == "accepted" and patient.stabilized and w.citizens[0].preferences.Care == 0 and w.citizens[0].pinned_job == 0)
	w = ColonyTests.world()
	patient = w.citizens[1]
	var walking: Dictionary = w.citizens[0]
	walking.x = 74; walking.y = 63; walking.edge_x = 74; walking.edge_y = 63
	walking.carrying_patient = patient.id; patient.carried_by = walking.id
	for i in range(13): w._walk(walking,Vector2i(75,63))
	check.call("CARE/carrier_slowed_twenty_five_percent",walking.x == 74)
	w._walk(walking,Vector2i(75,63))
	check.call("CARE/carrier_reaches_tile_on_tick_fourteen",walking.x == 75)
	w = ColonyTests.world()
	patient = w.citizens[1]
	ColonyCare.hurt(w,patient,90,true); ColonyCare.create_jobs(w)
	job = w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "rescue")[0]
	walking = w.citizens[0]; walking.x = patient.x; walking.y = patient.y
	w._reserve(job,walking); walking.job = job.id
	ColonyCare.rescue_work(w,walking,job)
	check.call("CARE/rescue_holds_patient_and_both_hands",patient.carried_by == walking.id and walking.carrying_patient == patient.id)
	snapshot = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("CARE/carried_patient_mid_route_roundtrip",snapshot.has("world") and snapshot.world.canonical_hash() == w.canonical_hash(),str(snapshot.get("error","")))
	w._release(job,true)
	check.call("CARE/interrupted_rescue_drops_patient_without_loss",patient.carried_by == 0 and walking.carrying_patient == 0 and patient.x == walking.x and patient.y == walking.y and w.invariant_errors().is_empty())
	w = ColonyTests.world()
	patient = w.citizens[1]
	w.social_state.pairs["1:2"].score = 50
	var initial: Dictionary = {}
	for item in w.definitions.items: initial[item] = w.total(item)
	ColonyCare.hurt(w,patient,100,false)
	ColonyCare.hurt(w,patient,100,false)
	check.call("DEATH/recorded_once_equipment_and_items_conserved",patient.death_recorded and w.social_state.deaths.size() == 1 and w.care_state.bodies.size() == 1 and w.definitions.items.keys().all(func(item:Variant)->bool:return w.total(item) == initial[item]) and w.invariant_errors().is_empty())
	var grief: Dictionary = ColonyCare.mood_terms(w,w.citizens[0])
	check.call("DEATH/friend_grief_and_unburied_body",grief.get("Grief for Oren") == -180 and grief.get("Unburied resident nearby") == -40)
	w.tick += 10800
	ColonyWeather.initialize(w)
	grief = ColonyCare.mood_terms(w,w.citizens[0])
	check.call("DEATH/grief_declines_linearly",grief.get("Grief for Oren") == -90)
	var body: Dictionary = w.care_state.bodies[0]
	ColonyCare.command(w,"burial",{"target":body.id,"x":body.x,"y":body.y})
	for i in range(1200): w.step()
	check.call("DEATH/burial_real_twelve_wu_removes_body_penalty",body.buried and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "bury" and j.state == "Complete") and not ColonyCare.mood_terms(w,w.citizens[0]).has("Unburied resident nearby"))
	snapshot = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("DEATH/history_burial_equipment_roundtrip",snapshot.has("world") and snapshot.world.canonical_hash() == w.canonical_hash(),str(snapshot.get("error","")))
	for person in w.citizens: ColonyCare.hurt(w,person,1000,false)
	w.step()
	var ended: int = w.tick
	w.step()
	check.call("DEATH/no_living_residents_freezes_terminal_colony",w.care_state.ended and w.tick == ended)
	w = ColonyTests.world()
	w.care_state.mode = "Hearthside"
	patient = w.citizens[1]
	ColonyCare.hurt(w,patient,1000,false)
	var until: int = patient.hearthside_until
	for i in range(14399): w.tick += 1; ColonyCare.advance(w)
	check.call("HEARTHSIDE/no_death_or_instant_resurrection",patient.health == 0 and patient.hearthside_until == until and not patient.death_recorded and w.social_state.deaths.is_empty())
	w.tick += 1; ColonyCare.advance(w)
	check.call("HEARTHSIDE/wakes_after_two_days_at_forty",patient.health == 40 and patient.hearthside_until == 0 and not patient.downed and not w.care_state.ended)
	w = ColonyTests.world()
	patient = w.citizens[1]; patient.health = 25; patient.fullness = 0; patient.starving_ticks = 2099
	var runner: SimRunner = SimRunner.new(w)
	runner.set_speed(4); runner.advance_frame(1.0)
	check.call("CARE/critical_downing_pauses_before_extra_ticks",runner.speed == 0 and w.tick == 1801 and patient.health == 20 and patient.downed)
	var older: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-production.brackenward"))
	check.call("SAVE/M4_production_additive_care_migration",older.has("world") and older.world.tick == 3415 and older.world.production_state.project == "storecraft" and older.world.schema_revision == ColonyWorld.SCHEMA_REVISION and older.world.citizens[0].health == 100,str(older.get("error","")))
	w = ColonyTests.world()
	patient = w.citizens[1]; patient.health = 70
	ColonyCare.command(w,"treat_now",{"target":patient.id,"citizen":1})
	w._assign(patient)
	check.call("CARE/mobile_patient_waits_for_requested_treatment",patient.job == 0 and patient.activity == "Resting for treatment")
	for stack in w.stacks:
		if stack.item == "herb": w._record("spoiled","herb",stack.count); stack.count = 0
	job = w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "treat")[0]
	job.work = 5000; job.pending_xp[1] = 5000
	w._reserve(job,w.citizens[0])
	check.call("CARE/missing_dressing_falls_back_retaining_work",job.definition == "stabilize" and job.required == 24000 and job.work == 5000 and job.inputs.is_empty())
	w = ColonyTests.world()
	patient = w.citizens[1]; patient.rest = 100; patient.fullness = 100
	for stack in w.stacks:
		if w.definitions.items[stack.item].fullness > 0: w._record("consumed",stack.item,stack.count); stack.count = 0
	w._assign(patient)
	check.call("CARE/hard_rest_refuses_work_even_without_food",w.find(w.jobs,patient.job).kind == "sleep" and w.find(w.jobs,patient.job).target == patient.bed)
	w = ColonyTests.world()
	patient = w.citizens[1]
	ColonyCare.hurt(w,patient,90,true)
	patient.x = 120; patient.y = 120; patient.edge_x = 120; patient.edge_y = 120
	for person in w.citizens:
		for category in person.preferences: person.preferences[category] = 0
	ColonyCare.create_jobs(w)
	check.call("CARE/unsafe_transport_creates_emergency_stabilization",not w.jobs.any(func(j:Dictionary)->bool:return j.kind == "rescue") and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "treat" and j.emergency))
	for i in range(1600):
		w.step()
		if w.jobs.any(func(j:Dictionary)->bool:return j.kind == "treat" and j.state == "Complete"): break
	check.call("CARE/critical_in_place_care_overrides_off_without_teleport",patient.stabilized and not patient.death_recorded and patient.x == 120 and patient.y == 120 and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "treat" and j.state == "Complete") and w.invariant_errors().is_empty())
	w = ColonyTests.world()
	w.researched.append("herbalism")
	w._structure("herbal_bench",Vector2i(74,63),0)
	w._make_stack("cloth",2,"ground",0,Vector2i(74,63),true)
	for i in range(1400): w.step()
	check.call("CARE/herbal_bench_maintains_four_real_medicines",w.total("medicine") == 4 and w.ledger.consumed.get("cloth") == 2 and w.ledger.consumed.get("herb") == 4 and w.production_state.orders[0].quantity == 4 and w.invariant_errors().is_empty(),str(w.invariant_errors()))
	w = ColonyTests.world()
	patient = w.citizens[1]
	patient.recovery_windows = {"medicine":w.tick+300,"herb":w.tick+600}
	w.tick += 300
	ColonyCare.advance(w)
	check.call("CARE/weaker_dressing_does_not_extend_medicine_window",patient.recovery_rate == 4 and patient.recovery_until == w.tick+300)
	var care_fixture: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-care.brackenward"))
	check.call("SAVE/native_care_windows_migrate_without_losing_treatment",care_fixture.has("world") and care_fixture.world.tick == 2860 and care_fixture.world.citizens[2].health == 27 and care_fixture.world.citizens[2].recovery_windows.has("herb") and care_fixture.world.invariant_errors().is_empty(),str(care_fixture.get("error","")))
	w = ColonyTests.world()
	patient = w.citizens[1]; patient.rest = 500
	ColonyCare.hurt(w,patient,90,true)
	for i in range(300): w._needs(patient)
	check.call("CARE/downed_ground_rest_uses_actual_location",patient.rest == 545)
	w = ColonyTests.world()
	ColonyCare.hurt(w,w.citizens[1],100,false)
	w.queue_command("build",{"definition":"bed","x":74,"y":63,"rotation":0})
	for i in range(1400): w.step()
	check.call("DEATH/new_bed_skips_dead_resident_and_uses_live_assignment",w.citizens[1].bed == 0 and w.citizens[0].bed != 0 and w.find(w.structures,w.citizens[0].bed).definition == "bed" and w.invariant_errors().is_empty())
