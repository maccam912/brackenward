class_name SocialTests
extends RefCounted

static func leisure_fixture() -> ColonyWorld:
	var w: ColonyWorld = ColonyTests.world()
	for i in range(4):
		var person: Dictionary = w.citizens[i]
		var position: Vector2i = [Vector2i(66,66),Vector2i(67,66),Vector2i(90,90),Vector2i(95,90)][i]
		person.x = position.x; person.y = position.y
		person.edge_x = position.x; person.edge_y = position.y
		var job: Dictionary = w._job("leisure","","",person.id,position,0)
		job.worker = person.id; job.state = "Working"; person.job = job.id
	return w

static func advance(w: ColonyWorld,ticks: int) -> void:
	for i in range(ticks):
		w.tick += 1
		ColonySocial.advance(w)

static func run(check: Callable) -> void:
	var w: ColonyWorld = ColonyTests.world()
	check.call("PEOPLE/initial_bonds_symmetric",w.social_state.pairs["1:2"].score == 20 and w.social_state.pairs["3:4"].score == 20 and w.social_state.pairs["1:3"].score == 0 and ColonySocial.key(1,2) == ColonySocial.key(2,1))
	w = leisure_fixture()
	advance(w,149)
	check.call("PEOPLE/conversation_requires_half_hour",w.social_state.pairs["1:2"].score == 20)
	advance(w,1)
	check.call("PEOPLE/sociable_conversation_gain_once",w.social_state.pairs["1:2"].score == 23)
	advance(w,300)
	check.call("PEOPLE/repeated_conversation_same_day_no_extra_gain",w.social_state.pairs["1:2"].score == 23)
	check.call("PEOPLE/private_alone_leisure_memory",w.citizens[3].friend_leisure_until > w.tick and ColonySocial.mood_terms(w,w.citizens[3]).get("Quiet leisure") == 40)
	w = leisure_fixture()
	advance(w,75)
	w.citizens[1].x = 85
	advance(w,1)
	w.citizens[1].x = 67
	advance(w,75)
	check.call("PEOPLE/interruption_resets_partial_conversation",w.social_state.pairs["1:2"].score == 20 and w.social_state.pairs["1:2"].conversation_ticks == 75)
	w = leisure_fixture()
	w.social_state.pairs["1:2"].score = 37
	advance(w,150)
	check.call("PEOPLE/friend_label_and_daily_memory",w.social_state.pairs["1:2"].score == 40 and w.citizens[0].friend_leisure_until == w.tick+7200 and w.citizens[1].friend_leisure_until == w.tick+7200)
	w = leisure_fixture()
	for i in range(4):
		w.citizens[i].x = 66+i%2
		w.citizens[i].y = 66+i/2
	advance(w,150)
	check.call("PEOPLE/one_partner_nearest_then_id",w.social_state.pairs["1:2"].score == 23 and w.social_state.pairs["3:4"].score == 21 and w.social_state.pairs["1:3"].score == 0)
	w = ColonyTests.world()
	w.tick += 57600
	ColonySocial.advance(w)
	check.call("PEOPLE/eight_day_decay_one_toward_zero",w.social_state.pairs["1:2"].score == 19 and w.social_state.pairs["1:3"].score == 0)
	w = ColonyTests.world()
	var job: Dictionary = w._job("build","Building","Build",0,Vector2i(74,63),15000)
	job.worker_days = {1:0,2:0}
	ColonySocial.shared_building(w,job)
	ColonySocial.shared_building(w,job)
	check.call("PEOPLE/shared_building_once_per_pair_day",w.social_state.pairs["1:2"].score == 21)
	ColonySocial.rescue(w,1,2,100)
	ColonySocial.rescue(w,1,2,100)
	check.call("PEOPLE/kind_rescue_once_per_injury",w.social_state.pairs["1:2"].score == 46)
	ColonySocial.rescue(w,2,3,101)
	check.call("PEOPLE/ordinary_rescue_twenty",w.social_state.pairs["2:3"].score == 20)
	table_leisure(check)
	mediation(check)
	requests(check)
	irrigation(check)

static func mediation(check: Callable) -> void:
	var w: ColonyWorld = ColonyTests.world()
	var pair: Dictionary = w.social_state.pairs["1:2"]
	pair.score = -40
	w.room_tiles = {Vector2i(74,69):1,Vector2i(75,69):1}; w.rooms_dirty = false
	for i in range(2):
		var actor: Dictionary = w.citizens[i]
		actor.x = 74+i; actor.y = 69; actor.edge_x = actor.x; actor.edge_y = actor.y
		var job: Dictionary = w._job("build","Building","Build",0,Vector2i(actor.x,actor.y),100000)
		job.worker = actor.id; job.state = "Working"; actor.job = job.id
	advance(w,1199)
	check.call("PEOPLE/disagreement_requires_four_hours",pair.score == -40 and pair.conflict_until == 0)
	advance(w,1)
	check.call("PEOPLE/disagreement_visible_and_bounded",pair.score == -43 and pair.conflict_until == w.tick+14400 and w.facts[-1].kind == "disagreement")
	w.citizens[0].broken_promise_until = w.tick+14400
	check.call("PEOPLE/conflict_and_broken_promise_do_not_stack",ColonySocial.mood_terms(w,w.citizens[0]) == {"Conflict or broken promise":-60})
	advance(w,1200)
	check.call("PEOPLE/conflict_two_day_cooldown",pair.score == -43)
	for actor in w.citizens:
		if actor.job > 0: w._release(w.find(w.jobs,actor.job),true)
	w.queue_command("mediate",{"definition":"1:2"})
	w.step()
	w.queue_command("mediate",{"definition":"1:2"})
	w.step()
	for i in range(250): w.step()
	check.call("PEOPLE/mediation_real_care_work_once",w.jobs.filter(func(j:Dictionary)->bool:return j.kind == "mediate").size() == 1 and w.jobs.any(func(j:Dictionary)->bool:return j.kind == "mediate" and j.state == "Complete") and pair.score == -35 and pair.conflict_until == 0 and w.invariant_errors().is_empty(),str(pair))

static func requests(check: Callable) -> void:
	var w: ColonyWorld = ColonyTests.world()
	w.tick = 3*7200+2400
	ColonyWeather.initialize(w)
	ColonySocial.advance(w)
	var request: Dictionary = w.social_state.requests[0]
	check.call("REQUEST/first_offer_day_four_oldest_resident",request.actor == 1 and request.kind == "quiet_bed" and request.state == "Offered" and request.deadline == 0)
	w.queue_command("request_decline",{"target":request.id})
	w.step()
	check.call("REQUEST/declining_has_no_morale_penalty",request.state == "Declined" and w.citizens[0].broken_promise_until == 0)
	w.tick = 7*7200+2400
	ColonyWeather.initialize(w); ColonySocial.advance(w)
	request = w.social_state.requests[-1]
	check.call("REQUEST/next_offer_rotates_oldest_person",request.actor == 2 and request.kind == "supper")
	w.queue_command("request_accept",{"target":request.id})
	w.step()
	check.call("REQUEST/accepted_deadline_four_days",request.state == "Accepted" and request.deadline == w.tick+28800)
	var snapshot: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("REQUEST/accepted_promise_survives_save",snapshot.has("world") and snapshot.world.canonical_hash() == w.canonical_hash(),str(snapshot.get("error","")))
	w.tick = request.deadline
	ColonyWeather.initialize(w); ColonySocial.advance(w)
	check.call("REQUEST/expired_promise_only_owner_two_day_penalty",request.state == "Failed" and w.citizens[1].broken_promise_until == w.tick+14400 and w.citizens[0].broken_promise_until == 0)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://tests/fixtures/m3-weather.brackenward")
	var migrated: Dictionary = ColonyCodec.decode(bytes)
	check.call("SAVE/M3_revision_one_additive_social_migration",migrated.has("world") and migrated.world.schema_revision == 2 and migrated.world.tick == 3135 and migrated.world.social_state.pairs["1:2"].score == 20,str(migrated.get("error","")))
	var directory: String = "user://social-migration-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	var original: FileAccess = FileAccess.open(directory.path_join("snapshot-0000000001.brackenward"),FileAccess.WRITE)
	original.store_buffer(bytes); original.close()
	var envelope: Dictionary = JSON.parse_string(bytes.get_string_from_utf8())
	var old_state: Dictionary = ColonyState.unpack(JSON.parse_string(envelope.payload))
	var journal: PackedByteArray = ColonyJournal.frame({"sequence":"1","kind":"tick","tick":old_state.tick,"state":old_state})
	original = FileAccess.open(directory.path_join("journal-0000000001.frames"),FileAccess.WRITE)
	original.store_buffer(journal); original.close()
	var store: ColonyStore = ColonyStore.new(); store.directory = directory
	var restored: Dictionary = store.load_latest()
	check.call("SAVE/additive_migration_retains_snapshot_and_journal",restored.has("world") and restored.world.schema_revision == 2 and FileAccess.get_file_as_bytes(directory.path_join("migration-backup-snapshot-0000000001.brackenward")) == bytes and FileAccess.get_file_as_bytes(directory.path_join("migration-backup-journal-0000000001.frames")) == journal)
	CampaignTests.remove_tree(directory)

static func table_leisure(check: Callable) -> void:
	var w: ColonyWorld = ColonyTests.world()
	var table: Dictionary = w._structure("table",Vector2i(74,64),0)
	check.call("PEOPLE/table_has_four_exact_seats",ColonySocial.seats_for(w,table) == [Vector2i(74,63),Vector2i(74,65),Vector2i(75,63),Vector2i(75,65)])
	table.rotation = 1
	check.call("PEOPLE/table_seats_rotate_with_footprint",ColonySocial.seats_for(w,table) == [Vector2i(75,64),Vector2i(73,64),Vector2i(75,65),Vector2i(73,65)])
	table.rotation = 0
	var seats: Array[Vector2i] = ColonySocial.seats_for(w,table)
	for i in range(3):
		var person: Dictionary = w.citizens[i]
		person.x = seats[i].x; person.y = seats[i].y
		var job: Dictionary = w._job("leisure","","",person.id,seats[i],0)
		job.worker = person.id; job.state = "Working"; person.job = job.id
	advance(w,149)
	check.call("REQUEST/supper_requires_three_and_half_hour",w.social_state.supper_history.is_empty())
	advance(w,1)
	check.call("REQUEST/supper_three_people_complete_together",w.social_state.supper_history.size() == 3 and w.social_state.supper_history[1] == w.tick)
	var bytes: Dictionary = ColonyCodec.decode(ColonyCodec.encode(w))
	check.call("PEOPLE/conversation_and_supper_roundtrip",bytes.has("world") and bytes.world.canonical_hash() == w.canonical_hash(),str(bytes.get("error","")))
	w = ColonyTests.world()
	w._structure("table",Vector2i(70,66),0)
	var seat: Vector2i = ColonySocial.leisure_seat(w,w.citizens[0])
	check.call("PEOPLE/leisure_chooses_reachable_table_before_grass",ColonySocial.table_at(w,seat) > 0 and w.walkable(seat))

static func irrigation(check: Callable) -> void:
	var w: ColonyWorld = ColonyTests.world()
	ColonyAgriculture.designate(w,{"crop":"turnip","tiles":[Vector2i(75,55),Vector2i(74,55)]})
	for field in w.fields: field.planted = true
	w.weather = "drought"
	w._structure("well",Vector2i(83,55),0)
	for i in range(7200): ColonyAgriculture.advance(w)
	check.call("CROP/well_restores_growth_at_eight_tiles",w.fields[0].growth == 1000 and w.fields[0].reason.contains("well stabilizes"))
	check.call("CROP/nine_tiles_outside_well_half_growth_explained",w.fields[1].growth == 500 and w.fields[1].reason.contains("half rate"))
