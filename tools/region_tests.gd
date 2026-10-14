class_name RegionTests
extends RefCounted

static func args(definition: String = "berry_hollow", party: Array = [2,3]) -> Dictionary:
	return {"definition":definition,"party":party,"goats":[],"cargo":{},"feed":"grain","pen":0,"variant":0,"pickup":false}

static func run(check: Callable) -> void:
	preparation_needs(check)
	var world: ColonyWorld = ColonyTests.world();var twin: ColonyWorld = ColonyTests.world()
	check.call("REGION/seeded_81_nodes_and_topology",world.region_state==twin.region_state and world.region_state.nodes.size()==81 and world.region_state.nodes.filter(func(n:Dictionary)->bool:return n.definition!="transit").size()==12)
	var plan: Dictionary = args();var quote: Dictionary = ColonyRegion.preview(world,plan)
	check.call("EXP/adjacent_berry_trip_exact_rations_time_capacity",quote.error.is_empty() and quote.edges==1 and quote.hours==18 and quote.rations==8 and quote.capacity==24 and quote.readiness==5 and quote.shortfall==0 and quote.rewards=={"berry":12,"herb":4},str(quote))
	check.call("EXP/leave_two_home",ColonyRegion.preview(world,args("berry_hollow",[1,2,3])).error.contains("two living"))
	check.call("EXP/distinct_party_required",ColonyRegion.preview(world,args("berry_hollow",[2,2])).error.contains("distinct"))
	check.call("EXP/nonadjacent_trailcraft_gate",ColonyRegion.preview(world,args("broken_causeway")).error.contains("Trailcraft"))
	world.citizens[1].health=69
	check.call("EXP/healthy_dispatch_gate",ColonyRegion.preview(world,plan).error.contains("health 70"))
	world.citizens[1].health=100
	var command: int = world.queue_command("expedition_prepare",plan);world.step();var trip: Dictionary = world.region_state.trips[0]
	check.call("EXP/preparation_reserves_cargo_without_departure",world.receipts[command]=="accepted" and trip.state=="Preparing" and ColonyRegion.home(world).size()==4 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var saved: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/expedition_preparation_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	for index in range(1500):
		world.step()
		if trip.state=="Ready": break
	check.call("EXP/physical_packing_and_party_meet_before_depart",trip.state=="Ready" and ColonyRegion.cargo(world,trip).travel_ration==8 and ColonyRegion.ready(world,trip).is_empty(),trip.note)
	command=world.queue_command("expedition_depart",{"target":trip.id,"unprepared":false});world.step()
	check.call("EXP/separate_depart_removes_two_workers_and_fixes_readiness",world.receipts[command]=="accepted" and ColonyRegion.home(world).size()==2 and trip.state=="Walking out" and trip.readiness==5)
	for index in range(3000):
		world.step()
		if trip.state=="Decision": break
	check.call("EXP/physical_boundary_walk_before_midpoint_choice",trip.state=="Decision" and trip.elapsed==900 and world.citizens[1].job==0 and Vector2i(world.citizens[1].x,world.citizens[1].y)==trip.entry,trip.note)
	saved=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/off_map_party_cargo_and_decision_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	check.call("EXP/repair_disabled_without_packed_wood",ColonyRegion.choice_error(world,trip,"repair").contains("wood"))
	check.call("EXP/free_continue_always_available",ColonyRegion.choice(world,trip,"continue")=="accepted" and trip.state=="Outbound")
	for index in range(3000):
		world.step()
		if trip.state=="Collect": break
	check.call("EXP/site_work_finishes_before_reward_commit",trip.state=="Collect" and not trip.reward_committed and world.ledger.expedition_gain.is_empty())
	var keep: Dictionary = ColonyRegion.default_keep(world,trip)
	check.call("EXP/default_keep_preserves_return_food_within_capacity",keep=={"berry":12,"herb":4},str(keep))
	command=world.queue_command("expedition_collect",{"target":trip.id,"keep":keep});world.step()
	check.call("EXP/one_atomic_site_outcome_mints_only_kept_cargo",world.receipts[command]=="accepted" and trip.reward_committed and world.ledger.expedition_gain=={"berry":12,"herb":4} and trip.state=="Returning" and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var again: String = ColonyRegion.collect(world,trip,keep)
	check.call("EXP/outcome_cannot_repeat",again.contains("already") and world.ledger.expedition_gain.berry==12)
	for index in range(5000):
		world.step()
		if trip.state=="Done": break
	check.call("EXP/physical_return_and_unload_restore_home_workers",trip.state=="Done" and ColonyRegion.home(world).size()==4 and ColonyRegion.cargo(world,trip).is_empty() and world.region_state.progress.berry_hollow.returned_at>0 and world.citizens[1].successful_trips==1 and world.invariant_errors().is_empty(),trip.state+": "+str(world.invariant_errors())+" cargo "+str(ColonyRegion.cargo(world,trip)))
	saved=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/returned_trip_and_cooldown_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	check.call("EXP/repeat_site_cooldown_starts_on_return",ColonyRegion.preview(world,plan).error.contains("cooldown"))
	world=ColonyTests.world();ColonyRegion.prepare(world,plan);trip=world.region_state.trips[0];ColonyRegion.cancel(world,trip)
	check.call("EXP/cancel_preparation_releases_people_and_supplies",trip.state=="Canceled" and world.citizens.all(func(c:Dictionary)->bool:return c.expedition==0 and not c.away) and world.total("travel_ration")==8 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();world.tick=174600;ColonyWeather.initialize(world)
	check.call("EXP/berry_hollow_unavailable_in_winter",ColonyRegion.preview(world,plan).error.contains("Winter"))
	for destination in ColonyRegion.SITES:
		world=expanded()
		plan=args(destination,[2,3,world.citizens[4].id,world.citizens[5].id] if destination=="broken_causeway" else [2,3])
		if destination=="lost_goats": plan.pen=world.domestic_state.pens[0].id
		var skill: String = world.definitions.expeditions[destination].skill
		for id in plan.party: level(world.find(world.citizens,id),skill,5)
		quote=ColonyRegion.preview(world,plan)
		check.call("EXP/%s_full_exact_catalog_quote" % destination,quote.error.is_empty() and quote.shortfall==0 and quote.rewards==world.definitions.expeditions[destination].rewards,str(quote))
		trip=depart(world,plan)
		if trip.is_empty(): check.call("EXP/%s_dispatch" % destination,false);continue
		until(world,trip,"Collect")
		keep=ColonyRegion.default_keep(world,trip)
		var collected: String = ColonyRegion.collect(world,trip,keep)
		check.call("EXP/%s_full_outcome_receipt" % destination,collected=="accepted" and trip.reward_committed and world.region_state.progress[destination].completed and world.invariant_errors().is_empty(),str(world.invariant_errors()))
		saved=ColonyCodec.decode(ColonyCodec.encode(world))
		check.call("SAVE/%s_outcome_roundtrip" % destination,saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
		until(world,trip,"Done")
		check.call("EXP/%s_return_unloads_once" % destination,trip.state=="Done" and world.citizens.all(func(c:Dictionary)->bool:return not c.away) and world.invariant_errors().is_empty(),trip.state+str(world.invariant_errors()))
		if destination=="lost_goats": check.call("EXP/tamed_goat_arrives_with_feed_and_handler",world.domestic_state.animals.size()==1 and world.domestic_state.animals[0].definition=="pack_goat" and world.ledger.consumed.get("grain",0)==2 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="lead_animal"))
		if destination=="old_quarry" and not world.region_state.progress.old_quarry.leftovers.is_empty():
			var leftovers: Dictionary = world.region_state.progress.old_quarry.leftovers.duplicate()
			plan=args("old_quarry");plan.pickup=true
			for id in plan.party:
				var person: Dictionary = world.find(world.citizens,id);person.fullness=800;person.rest=800
			trip=depart(world,plan);until(world,trip,"Collect")
			check.call("EXP/leftover_pickup_has_zero_work_challenge_and_no_new_loot",trip.quote.rewards==leftovers and trip.quote.challenge==0 and ColonyRegion.definition_data(world,"old_quarry",true).site_hours==0 and trip.decision==-1)
			ColonyRegion.collect(world,trip,ColonyRegion.default_keep(world,trip));until(world,trip,"Done")
			check.call("EXP/leftover_pickup_cannot_regenerate",world.region_state.progress.old_quarry.pickup_used and ColonyRegion.preview(world,plan).error.contains("pickup"))
	world=expanded();plan=args("old_quarry");level(world.citizens[1],"Build",1);level(world.citizens[2],"Build",0)
	trip=depart(world,plan);until(world,trip,"Collect")
	check.call("EXP/two_point_shortfall_quotes_three_quarter_reward",trip.quote.shortfall==2 and trip.quote.rewards=={"stone":18} and trip.quote.readiness==3)
	level(world.citizens[1],"Build",5);level(world.citizens[2],"Build",5)
	ColonyRegion.collect(world,trip,ColonyRegion.default_keep(world,trip))
	check.call("EXP/frozen_readiness_and_injured_leader",trip.readiness==3 and trip.quote.shortfall==2 and world.citizens[1].health==80 and world.citizens[2].health==100 and world.citizens[1].stabilized)
	world=expanded();plan=args("old_quarry");plan.cargo={"medicine":1};level(world.citizens[1],"Build",0);level(world.citizens[2],"Build",0)
	trip=depart(world,plan);until(world,trip,"Collect");ColonyRegion.collect(world,trip,ColonyRegion.default_keep(world,trip))
	check.call("EXP/one_precaution_medicine_only_on_injury",trip.readiness==4 and trip.quote.shortfall==1 and world.ledger.consumed.get("medicine",0)==1 and world.citizens[1].health==100)
	world=expanded();plan=args("wayhouse_archive");level(world.citizens[1],"Study",0);level(world.citizens[2],"Study",0)
	trip=depart(world,plan,false)
	check.call("EXP/unprepared_departure_needs_explicit_choice",trip.state in ["Preparing","Ready"] and not world.citizens[1].away and trip.quote.shortfall==4)
	ColonyRegion.command(world,"expedition_depart",{"target":trip.id,"unprepared":true});until(world,trip,"Collect");ColonyRegion.collect(world,trip,{})
	check.call("EXP/unprepared_has_half_insight_no_items_two_bounded_injuries",world.production_state.insight==150 and world.ledger.expedition_gain.is_empty() and world.citizens[1].health==80 and world.citizens[2].health==80 and world.citizens[1].stabilized and world.citizens[2].stabilized)
	world=expanded();plan=args();trip=depart(world,plan)
	world.step();var before_walk: Vector2i = Vector2i(world.citizens[1].x,world.citizens[1].y)
	ColonyRegion.command(world,"expedition_recall",{"target":trip.id})
	check.call("EXP/recall_during_local_departure_never_teleports",trip.state=="Walking in" and Vector2i(world.citizens[1].x,world.citizens[1].y)==before_walk)
	until(world,trip,"Done")
	check.call("EXP/local_recall_preserves_unconsumed_cargo",trip.state=="Done" and world.ledger.expedition_gain.is_empty() and world.total("travel_ration")==world.ledger.produced.travel_ration-world.ledger.consumed.get("travel_ration",0))
	world=expanded();plan=args();trip=depart(world,plan);until(world,trip,"Decision")
	var outbound: int = trip.elapsed;ColonyRegion.command(world,"expedition_recall",{"target":trip.id})
	check.call("EXP/midpoint_recall_uses_elapsed_outbound_time",trip.state=="Returning" and trip.remaining==outbound and not trip.reward_committed)
	until(world,trip,"Done")
	check.call("EXP/recalled_site_has_no_completion_or_reward",not world.region_state.progress.berry_hollow.completed and world.ledger.expedition_gain.is_empty())
	world=expanded();plan=args();trip=depart(world,plan);until(world,trip,"Decision",false)
	var tick_before_choice: int = world.tick;var runner: SimRunner = SimRunner.new(world);runner.set_speed(4)
	check.call("EXP/unresolved_decision_cannot_advance_time",runner.advance_frame(1)==0 and world.tick==tick_before_choice and runner.speed==0)
	check.call("EXP/wait_within_same_trip_day_preserves_reserve",ColonyRegion.choice_error(world,trip,"wait").is_empty())
	ColonyRegion.choice(world,trip,"wait")
	check.call("EXP/optional_carrier_reward_survives_recall",ColonyRegion.cargo(world,trip).cloth==4 and world.ledger.expedition_gain.cloth==4 and trip.quote.hours==24 and world.region_state.progress.berry_hollow.decision_after==world.tick+57600)
	ColonyRegion.command(world,"expedition_recall",{"target":trip.id});until(world,trip,"Done")
	check.call("EXP/recalled_optional_reward_is_not_site_loot",world.total("cloth")==world.ledger.produced.get("cloth",0)+4 and not world.region_state.progress.berry_hollow.completed)


	world=expanded();plan=args("orchard_kin");trip=depart(world,plan);until(world,trip,"Collect")
	ColonyRegion.collect(world,trip,{});until(world,trip,"Done")
	check.call("EXP/community_visit_only_delivers_contract_without_second_stock",trip.state=="Done" and trip.decision==-1 and world.trade_state.reputation.orchard_kin==30 and world.ledger.traded_out.get("travel_ration",0)==12 and world.ledger.expedition_gain.is_empty() and world.region_state.progress.orchard_kin.returned_at>0)
	world=expanded();plan=args();plan.cargo={"meal":4};world.use_rations=true
	quote=ColonyRegion.preview(world,plan)
	var projected: Dictionary = ColonyTrade.reservation_plan(world,quote.inputs,Vector2i(66,63));var removals: Dictionary = {}
	for request in projected.requests: removals[request.stack]=request.count
	check.call("EXP/home_food_preview_excludes_departing_cargo",quote.home_forecast==FoodForecast.calculate(world,4,removals) and quote.home_forecast.portions<FoodForecast.calculate(world,4).portions)
	world=expanded();plan=args("old_quarry");trip=depart(world,plan);until(world,trip,"Decision",false)
	check.call("EXP/hungry_traveler_cannot_spend_return_reserve",ColonyRegion.choice_error(world,trip,"give").contains("rations"))
	check.call("EXP/continuing_costs_no_reputation",ColonyRegion.choice(world,trip,"continue")=="accepted" and world.trade_state.reputation.road_fellowship==20)
	world=expanded();plan=args("raider_cache");trip=depart(world,plan);until(world,trip,"Decision",false)
	check.call("EXP/six_hour_delay_reprices_full_trip_days",ColonyRegion.choice_error(world,trip,"survey").contains("rations"))
	world=expanded();plan=args();var pen: Dictionary = world.domestic_state.pens[0]
	var goat: Dictionary = ColonyDomestic.acquire(world,"pack_goat",pen.id,pen.tiles[0]).animal;goat.health=40;plan.goats=[goat.id]
	quote=ColonyRegion.preview(world,plan)
	check.call("EXP/pack_goat_adds_capacity_and_real_feed",quote.error.is_empty() and quote.capacity==36 and quote.feed==2 and quote.inputs.grain==2)
	trip=depart(world,plan);until(world,trip,"Decision",false)
	check.call("EXP/away_goat_uses_trip_feed_and_recovers_without_milk",goat.away and goat.health==50 and goat.pending==0 and trip.fed_days==1)
	var malformed: Dictionary = world.region_state.duplicate(true);malformed.trips[0].quote.capacity=999
	check.call("SAVE/rejects_impossible_expedition_capacity",not ColonyRegion.validate(malformed,world.citizens,world.definitions,world.tick))


	for destination in ColonyRegion.SITES:
		world=expanded();plan=args(destination,[2,3,world.citizens[4].id,world.citizens[5].id] if destination=="broken_causeway" else [2,3])
		if destination=="lost_goats": plan.pen=world.domestic_state.pens[0].id
		for id in plan.party:
			var person: Dictionary = world.find(world.citizens,id);level(person,world.definitions.expeditions[destination].skill,0)
			if not person.equipment.weapon.is_empty(): world._make_stack(person.equipment.weapon,1,"ground",0,Vector2i(person.x,person.y),false);person.equipment.weapon=""
		trip=depart(world,plan)
		focused_arrival(world,trip)
		var packed_before: Dictionary = ColonyRegion.cargo(world,trip).duplicate()
		var recalled: String = ColonyRegion.command(world,"expedition_recall",{"target":trip.id})
		check.call("EXP/%s_recall_before_outcome_has_no_reward_or_payment" % destination,recalled=="accepted" and trip.state=="Returning" and not trip.reward_committed and ColonyRegion.cargo(world,trip)==packed_before and world.ledger.expedition_gain.is_empty() and world.ledger.traded_out.is_empty())
		trip.state="Collect"
		var failed: String = ColonyRegion.collect(world,trip,{})
		var expected_insight: int = world.definitions.expeditions[destination].insight/2
		check.call("EXP/%s_failed_attempt_has_no_items_and_preserves_contract_inputs" % destination,failed=="accepted" and trip.quote.shortfall>2 and world.ledger.expedition_gain.is_empty() and world.production_state.insight==expected_insight and trip.quote.payment.keys().all(func(item:String)->bool:return ColonyRegion.cargo(world,trip).get(item,0)==packed_before.get(item,0)) and not trip.reward_animal and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=expanded();plan=args();trip=depart(world,plan);focused_arrival(world,trip)
	ColonyRegion.collect(world,trip,ColonyRegion.default_keep(world,trip));trip.remaining=0
	var raid: Dictionary = DefenseTests.raid(world)
	var traveler: Dictionary = world.find(world.citizens,trip.args.party[0]);traveler.fullness=0;traveler.starving_ticks=2099
	var food_before: Dictionary = ColonyRegion.cargo(world,trip).duplicate();var health_before: int = traveler.health
	ColonyRegion.advance(world);ColonyRegion.needs(world,traveler)
	check.call("EXP/returning_party_waits_for_raid_without_extra_food_or_starvation",trip.state=="Returning" and trip.note.contains("without extra food") and ColonyRegion.cargo(world,trip)==food_before and traveler.health==health_before and traveler.starving_ticks==2099)
	world.tick=raid.arrival+1800
	check.call("EXP/raid_food_waiver_is_bounded_by_original_six_hour_limit",not ColonyRegion.waiting_for_raid(world,trip))
	raid.state="Resolved";ColonyRegion.advance(world)
	check.call("EXP/return_resumes_from_boundary_after_raid",trip.state=="Walking in")

static func level(person: Dictionary, skill: String, value: int) -> void:
	person.skills[skill]=value;person.xp[skill]=ColonyWorld.THRESHOLDS[value]*1000

static func expanded() -> ColonyWorld:
	var world: ColonyWorld = DomesticTests.setup();var wagon: Dictionary = ColonyTrade.cart(world)
	world.researched.assign(world.definitions.research.keys())
	for item in {"meal":60,"travel_ration":24,"wood":16,"grain":8,"cloth":4,"medicine":2}:
		world._make_stack(item,{"meal":60,"travel_ration":24,"wood":16,"grain":8,"cloth":4,"medicine":2}[item],"ground",0,Vector2i(wagon.x,wagon.y),true)
	for index in range(2):
		world._structure("bedroll",Vector2i(75,65+index),0);var offer: Dictionary = ColonyPopulation.offer(world)
		ColonyPopulation.command(world,{"target":offer.id,"accept":true});var person: Dictionary = world.citizens[-1];person.x=wagon.x;person.y=wagon.y
		ColonyPopulation.arrival_work(world,person,world.find(world.jobs,person.job))
	var tiles: Array[Vector2i] = []
	for y in range(65,73):
		for x in range(85,93): tiles.append(Vector2i(x,y))
	world.queue_designation(tiles);world.step()
	return world

static func preparation_needs(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var wagon: Dictionary = ColonyTrade.cart(world)
	for id in [2,3]:
		var person: Dictionary = world.find(world.citizens,id)
		person.x=wagon.x;person.y=wagon.y;person.edge_x=wagon.x;person.edge_y=wagon.y
		person.fullness=600;person.rest=600
	var accepted: String = ColonyRegion.prepare(world,args())
	var trip: Dictionary = ColonyRegion.active(world)
	check.call("EXP/preparation_needs_fixture_uses_normal_dispatch",accepted=="accepted" and trip.state=="Preparing")
	for id in [2,3]:
		var person: Dictionary = world.find(world.citizens,id)
		person.fullness=480;person.rest=480
		world._assign(person)
	check.call("EXP/preparing_travelers_eat_before_departure_threshold",[2,3].all(func(id:int)->bool:return world.find(world.jobs,world.find(world.citizens,id).job).get("kind")=="eat"))
	world.citizens[0].fullness=480;world.citizens[0].rest=480
	world._assign(world.citizens[0])
	check.call("EXP/home_workers_keep_ordinary_need_thresholds",world.find(world.jobs,world.citizens[0].job).get("kind") not in ["eat","sleep"])
	for index in range(30): world.step()
	var saved: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/preparing_needs_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	var saw_sleep: bool = false
	for index in range(3570):
		world.step()
		saw_sleep=saw_sleep or [2,3].any(func(id:int)->bool:return world.find(world.jobs,world.find(world.citizens,id).job).get("kind")=="sleep")
		if trip.state=="Ready": break
	check.call("EXP/preparing_travelers_really_rest_and_reach_departure",saw_sleep and trip.state=="Ready" and ColonyRegion.ready(world,trip).is_empty(),trip.note)
	check.call("EXP/preparation_consumes_real_food_without_auto_departure",world.ledger.consumed.get("meal",0)>=2 and world.citizens.all(func(c:Dictionary)->bool:return not c.away) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	ColonyRegion.cancel(world,trip)
	check.call("EXP/cancel_restores_normal_need_thresholds",not ColonyRegion.preparing(world,world.citizens[1]) and world.citizens[1].expedition==0)

static func depart(world: ColonyWorld, plan: Dictionary, allow_unprepared: bool = true) -> Dictionary:
	if ColonyRegion.prepare(world,plan)!="accepted": return {}
	var trip: Dictionary = ColonyRegion.active(world)
	until(world,trip,"Ready")
	ColonyRegion.command(world,"expedition_depart",{"target":trip.id,"unprepared":allow_unprepared})
	return trip

static func until(world: ColonyWorld, trip: Dictionary, state: String, continue_choices: bool = true) -> void:
	if trip.is_empty(): return
	for index in range(16000):
		if trip.state==state: return
		if continue_choices and trip.state=="Decision": ColonyRegion.choice(world,trip,"continue")
		world.step()

static func focused_arrival(world: ColonyWorld, trip: Dictionary) -> void:
	for id in trip.args.party:
		var person: Dictionary = world.find(world.citizens,id);world._release(world.find(world.jobs,person.job),true);person.x=trip.entry.x;person.y=trip.entry.y;person.progress=0
	trip.state="Collect";trip.remaining=0;trip.decision_done=true
