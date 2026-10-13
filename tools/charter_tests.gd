class_name CharterTests
extends RefCounted
## These are isolated rule fixtures, not evidence of an ordinary-play charter campaign.

static func supper_world() -> ColonyWorld:
	var world: ColonyWorld = ColonyTests.world()
	world.tick=5390
	world.charter_state=ColonyCharter.initial_state(world.tick)
	world.researched.append("commonlife")
	for index in range(4):
		var base: Dictionary = world.citizens[index]
		var person: Dictionary = ColonyWorld.citizen_record(world._id(),"Guest %d" % index,Vector2i(64+index,64),base.skills.duplicate(),base.xp.duplicate(),base.traits.duplicate(),base.preferred,base.preferences.duplicate(),base.food_tag,"")
		person.equipment={"toolkit":"","cloak":"","weapon":"","vest":""}
		world.citizens.append(person)
	world.social_state=ColonySocial.initial_state(world.citizens,world.tick)
	world.equipment_state=ColonyEquipment.initial_state(world.citizens)
	world._structure("table",Vector2i(66,66),0)
	for person in world.citizens:
		person.fullness=1000;person.rest=1000
		for category in person.preferences: person.preferences[category]=0
	for structure in world.structures:
		if structure.definition=="hearth": structure.cooking=false
	ColonyWeather.initialize(world)
	return world

static func _command(world: ColonyWorld, kind: String, args: Dictionary = {}) -> String:
	var id: int = world.queue_command(kind,args)
	world.step()
	return world.receipts[id]

static func _roof_beds(world: ColonyWorld) -> void:
	for x in range(74,84):
		world._structure("wood_wall",Vector2i(x,68),0);world._structure("wood_wall",Vector2i(x,74),0)
	for y in range(69,74):
		world._structure("door" if y==70 else "wood_wall",Vector2i(74,y),0);world._structure("wood_wall",Vector2i(83,y),0)
	for index in range(world.citizens.size()):
		var citizen: Dictionary = world.citizens[index]
		var previous: Dictionary = world.find(world.structures,citizen.bed)
		if not previous.is_empty(): previous.user=0
		var bed: Dictionary = world._structure("bed",Vector2i(75+(index%4)*2,69+(index/4)*2),0)
		citizen.bed=bed.id;bed.user=citizen.id

static func _roundtrip(check: Callable, label: String, world: ColonyWorld) -> ColonyWorld:
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call(label,decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	return decoded.get("world",world)

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	check.call("CHARTER/day_one_visible_ordered_checklist",ColonyCharter.checklist(world).map(func(r:Dictionary)->String:return r.id)==ColonyCharter.STAGES and world.charter_state.completed.is_empty())
	check.call("SUPPER/commonlife_is_required",_command(world,"start_supper").contains("Commonlife"))
	world.researched.append("commonlife")
	check.call("SUPPER/eight_healthy_home_residents_required",_command(world,"start_supper").contains("eight home"))
	world=supper_world();world.citizens[-1].health=59
	check.call("SUPPER/injured_resident_does_not_meet_launch_minimum",_command(world,"start_supper").contains("60 health"))
	world.citizens[-1].health=100;world.citizens[-1].away=true
	check.call("SUPPER/expedition_resident_does_not_meet_launch_minimum",_command(world,"start_supper").contains("eight home"))
	world=supper_world()
	var table: Dictionary = world.structures[-1]
	world._structure("wood_wall",Vector2i(table.x,table.y-1),0)
	check.call("SUPPER/four_reachable_seats_required",_command(world,"start_supper").contains("four safe"))
	world=supper_world()
	var original: int = world.total("meal")
	check.call("SUPPER/launch_reserves_two_per_home_without_consuming",_command(world,"start_supper")=="accepted" and world.available("meal")==original-16 and world.total("meal")==original and world.charter_state.supper.start==5400 and world.charter_state.supper.end==6000)
	var first_job: int = world.charter_state.supper.job
	check.call("SUPPER/double_start_is_rejected",_command(world,"start_supper").contains("already") and world.charter_state.supper.job==first_job)
	world=_roundtrip(check,"SAVE/supper_scheduled_reservations_roundtrip",world)
	for malformed in ["missing_event","empty_slot","scalar_slot","missing_eligible","scalar_eligible"]:
		var payload: Dictionary = world.payload().duplicate(true)
		match malformed:
			"missing_event": payload.charter_state.supper={}
			"empty_slot": payload.charter_state.supper.slots=[{}]
			"scalar_slot": payload.charter_state.supper.slots=[7]
			"missing_eligible": payload.charter_state.supper.erase("eligible")
			"scalar_eligible": payload.charter_state.supper.eligible=7
		check.call("SAVE/rejects_malformed_supper_"+malformed,ColonyCodec.restore(payload).has("error"))
	var saved_phases: Array = []
	var max_seated: int = 0
	while world.tick<6000 and world.charter_state.supper.state!="Complete":
		world.step()
		var seated: int = 0
		for person in world.citizens:
			var job: Dictionary = world.find(world.jobs,person.job)
			if job.get("kind")!="supper": continue
			if job.state=="Working": seated+=1
			var phase: String = job.state+("_eaten" if job.amount==1 else "_unfed")
			if phase not in saved_phases:
				saved_phases.append(phase)
				_roundtrip(check,"SAVE/supper_phase_"+phase,world)
		max_seated=maxi(max_seated,seated)
	check.call("SUPPER/physical_four_seat_waves_finish_eight_distinct",world.charter_state.supper.state=="Complete" and world.charter_state.supper.attended.size()==8 and max_seated<=4 and saved_phases.has("Fetching_unfed") and saved_phases.has("Delivering_unfed") and saved_phases.has("Working_eaten"),str(world.charter_state.supper))
	check.call("SUPPER/exactly_one_meal_each_even_when_full",world.total("meal")==original-8 and world.ledger.consumed.get("meal",0)==8 and world.charter_state.supper.eaten.size()==8)
	check.call("SUPPER/buffer_released_and_memory_once",world.available("meal")==original-8 and world.charter_state.supper_memories.size()==8 and ColonyCharter.mood_terms(world,world.citizens[0]).get("Communal supper",0)==60 and world.facts.filter(func(f:Dictionary)->bool:return f.kind=="supper_complete").size()==1 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	check.call("SUPPER/eight_day_cooldown",_command(world,"start_supper").contains("eight days"))
	var supper_fact: Dictionary = ColonyChronicle.fact(world.chronicle_state,ColonyChronicle.causes(world,"supper:"+str(world.charter_state.supper.job))[0])
	check.call("STORY/communal_supper_memory_has_real_people_and_start_cause",supper_fact.kind=="supper_complete" and supper_fact.participants.size()==8 and supper_fact.causes.size()==1 and supper_fact.changes=={"meal":-8} and supper_fact.location==[66,63])
	world=_roundtrip(check,"SAVE/completed_supper_roundtrip",world)
	var damaged: Dictionary = world.payload().duplicate(true)
	damaged.charter_state.supper.attended.append(world.citizens[0].id)
	damaged.charter_state.supper.attended.append(world.citizens[0].id)
	check.call("SAVE/rejects_duplicate_supper_attendee",ColonyCodec.restore(damaged).has("error"))
	world=supper_world();world.tick=5400
	check.call("SUPPER/confirmation_at_eighteen_schedules_tomorrow",_command(world,"start_supper")=="accepted" and world.charter_state.supper.start==12600)
	check.call("SUPPER/cancel_before_window_returns_every_meal",_command(world,"cancel_supper")=="accepted" and world.total("meal")==24 and world.available("meal")==24 and world.invariant_errors().is_empty())
	world=supper_world();_command(world,"start_supper")
	while world.charter_state.supper.eaten.is_empty() and world.tick<5800: world.step()
	var eaten: int = world.charter_state.supper.eaten.size()
	check.call("SUPPER/eating_precedes_attendance",eaten>0 and world.charter_state.supper.attended.is_empty())
	_command(world,"cancel_supper")
	check.call("SUPPER/cancel_preserves_eaten_food_consumption",world.total("meal")==24-eaten and world.charter_state.supper.attended.is_empty() and world.charter_state.last_supper==0 and world.charter_state.supper.reason.contains("stay consumed") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=supper_world();_command(world,"start_supper")
	for person in world.citizens:
		person.x=100;person.y=100;person.edge_x=100;person.edge_y=100
	while world.tick<6000: world.step()
	check.call("SUPPER/long_travel_cannot_teleport_or_fake_attendance",world.charter_state.supper.state=="Failed" and world.charter_state.supper.attended.is_empty() and world.charter_state.supper.eaten.is_empty() and world.total("meal")==24 and world.charter_state.supper.reason.contains("Evening window ended") and world.invariant_errors().is_empty())
	world=supper_world();_command(world,"start_supper")
	world.citizens[0].rest=0
	for i in range(25): world.step()
	check.call("SUPPER/life_critical_sleep_takes_precedence",world.find(world.jobs,world.citizens[0].job).get("kind")=="sleep" and not world.charter_state.supper.eaten.has(world.citizens[0].id))
	world=supper_world()
	# Reserve the entire edible inventory, then demonstrate life-critical release.
	var remove_meals: int = 8
	for stack in world.stacks:
		if stack.item=="meal" and stack.count>0 and remove_meals>0:
			var removed: int = mini(remove_meals,stack.count);stack.count-=removed;remove_meals-=removed;world._record("consumed","meal",removed)
	world.tick=5400;_command(world,"start_supper");world.citizens[0].fullness=0
	for i in range(150): world.step()
	check.call("SUPPER/life_critical_hunger_can_use_reserved_buffer",world.citizens[0].fullness>0 and world.charter_state.supper.state=="Scheduled" and world.charter_state.supper.reason.contains("Life-critical") and world.invariant_errors().is_empty(),str({"person":world.citizens[0],"supper":world.charter_state.supper,"invariants":world.invariant_errors()}))
	world=supper_world();_command(world,"start_supper")
	while not world.stacks.any(func(s:Dictionary)->bool:return s.item=="meal" and s.location=="carry") and world.tick<5700: world.step()
	var had_carried_meal: bool = world.stacks.any(func(s:Dictionary)->bool:return s.item=="meal" and s.location=="carry")
	for stack in world.stacks:
		if stack.item=="meal" and stack.count>0: stack.age=world.definitions.items.meal.shelf_ticks-1
	while world.tick<6000: world.step()
	check.call("SUPPER/spoiled_carried_and_reserved_food_cannot_be_eaten",had_carried_meal and world.charter_state.supper.state=="Failed" and world.charter_state.supper.eaten.is_empty() and world.ledger.spoiled.get("meal",0)==24 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=supper_world();_command(world,"start_supper")
	while world.charter_state.supper.eaten.is_empty() and world.tick<5800: world.step()
	world.structures.filter(func(s:Dictionary)->bool:return s.definition=="table")[0].health=0
	while world.tick<6000: world.step()
	check.call("SUPPER/destroyed_table_never_completes_remote_attendance",world.charter_state.supper.state=="Failed" and world.charter_state.supper.attended.is_empty() and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="supper" and j.reason.contains("seat lost")) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=supper_world();_roof_beds(world)
	for structure in world.structures:
		if structure.definition=="hearth": structure.cooking=true
	world._make_stack("meal",40,"store",world.stores[0].id,Vector2i(66,63),true)
	world.step()
	while world.tick%10!=0: world.step()
	check.call("CHARTER/shelter_requires_real_simultaneous_snapshot",world.charter_state.completed==["shelter"] and world.charter_state.snapshots.shelter.beds==8 and world.production_state.insight==100)
	world.citizens[0].bed=0
	world.structures.filter(func(s:Dictionary)->bool:return s.definition=="table")[0].health=0
	for i in range(20): world.step()
	check.call("REGION10/earned_stage_never_retracted_or_paid_twice",world.charter_state.completed==["shelter"] and world.production_state.insight==100)
	winter(check)
	ceremony(check)

static func winter(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	world.tick=24*7200+100
	world.charter_state=ColonyCharter.initial_state(world.tick)
	# Observe only the charter monitor to isolate exact full-day bookkeeping.
	while world.tick<25*7200: world.tick+=1;ColonyCharter.advance(world)
	check.call("CHARTER/partial_winter_day_never_counts",world.charter_state.winter_completed_at==0)
	world.citizens[0].fullness=0;world.tick+=1;ColonyCharter.advance(world);world.citizens[0].fullness=750
	while world.tick<26*7200: world.tick+=1;ColonyCharter.advance(world)
	check.call("CHARTER/one_zero_fullness_tick_fails_whole_winter_day",world.charter_state.winter_completed_at==0)
	while world.tick<27*7200: world.tick+=1;ColonyCharter.advance(world)
	check.call("CHARTER/entire_winter_day_records_permanent_progress",world.charter_state.winter_completed_at==27*7200)
	world.citizens[0].fullness=0;world.tick+=1;ColonyCharter.advance(world)
	check.call("CHARTER/later_hunger_preserves_winter_snapshot",world.charter_state.winter_completed_at==27*7200)

static func ceremony(check: Callable) -> void:
	var world: ColonyWorld = supper_world()
	_roof_beds(world)
	world.tick=32*7200+1800;world.charter_state=ColonyCharter.initial_state(world.tick)
	world.charter_state.winter_completed_at=32*7200
	world.charter_state.last_supper=world.tick-100
	world.researched.assign(["commonlife","storecraft","farming","valley_charter"])
	world._structure("granary",Vector2i(72,63),0)
	world._structure("beacon",Vector2i(87,63),0)
	for i in range(24): world.fields.append({"id":world._id(),"crop":"turnip","x":80+i%8,"y":80+i/8,"growth":0,"growth_rem":0,"ripe_tick":0,"planted":true,"prepared":true,"replant":true,"yield_count":4,"fertility":1000,"reason":"Growing"})
	world.region_state.progress.berry_hollow.returned_at=world.tick-100
	world.region_state.progress.old_quarry.returned_at=world.tick-50
	world.trade_state.reputation.orchard_kin=40;world.trade_state.reputation.riverward=40
	for structure in world.structures:
		if structure.definition=="hearth": structure.cooking=true
	world._make_stack("meal",64,"store",world.stores[0].id,Vector2i(66,63),true)
	ColonyWeather.initialize(world)
	ColonyCharter.advance(world)
	check.call("CHARTER/four_stages_complete_in_order_without_animals",world.charter_state.completed==["shelter","provision","connection","refuge"] and world.production_state.insight==600 and not world.researched.has("husbandry"))
	check.call("CHARTER/ceremony_starts_only_after_all_live_gates",_command(world,"start_ceremony")=="accepted")
	var started: int = world.charter_state.ceremony.start
	world.tick=started+599;ColonyCharter.advance(world)
	check.call("CHARTER/ceremony_needs_two_full_hours",not world.charter_state.ending)
	world.tick+=1;ColonyCharter.advance(world)
	check.call("CHARTER/one_ending_and_frozen_start_conditions",world.charter_state.ending and world.charter_state.completed==ColonyCharter.STAGES and world.charter_state.snapshots.charter.tick==started and world.facts.filter(func(f:Dictionary)->bool:return f.kind=="charter_complete").size()==1)
	var final_stage: Dictionary = ColonyChronicle.fact(world.chronicle_state,ColonyChronicle.causes(world,"charter:charter")[0])
	var endings: Array = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="charter_complete")
	check.call("STORY/final_stage_and_ending_share_one_ceremony_chain",endings.size()==1 and endings[0].chain==final_stage.chain and endings[0].causes==[final_stage.id])
	check.call("CHARTER/continue_preserves_settlement_and_completed_stages",_command(world,"continue_settlement")=="accepted" and world.charter_state.continued and world.charter_state.completed.size()==5)
	check.call("CHARTER/ceremony_cannot_repeat_completion",_command(world,"start_ceremony").contains("already complete") and world.facts.filter(func(f:Dictionary)->bool:return f.kind=="charter_complete").size()==1)
	world.charter_state.completed.pop_back();world.charter_state.snapshots.erase("charter");world.charter_state.ending=false;world.charter_state.continued=false;world.charter_state.ceremony={}
	_command(world,"start_ceremony")
	var announcement: Dictionary = ColonyDefense.announce(world,2)
	announcement.arrival=world.tick+1
	world.tick+=1;ColonyCharter.advance(world)
	check.call("REGION10/hostile_arrival_cancels_ceremony_only",world.charter_state.ceremony.state=="Canceled" and world.charter_state.completed.size()==4 and not world.charter_state.ending)
