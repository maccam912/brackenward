class_name OpportunityTests
extends RefCounted

static func finish(world: ColonyWorld, event: Dictionary, ticks: int = 3000) -> void:
	for index in range(ticks):
		world.step()
		if event.state in ColonyOpportunities.ENDED: break

static func roundtrip(check: Callable, name: String, world: ColonyWorld) -> void:
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call(name,decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))

static func accept(world: ColonyWorld, event: Dictionary) -> int:
	var command: int = world.queue_command("minor_event",{"target":event.id,"accept":true});world.step();return command

static func run(check: Callable) -> void:
	carrier(check)
	harvest(check)
	observation(check)
	storytelling(check)
	edges(check)
	scheduling(check)
	validation(check)

static func carrier(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var event: Dictionary = ColonyOpportunities.offer(world,"stranded_carrier")
	var visitor: Dictionary = world.find(world.opportunity_state.visitors,event.visitor)
	check.call("MINOR/visitor_starts_on_boundary",visitor.state=="Entering" and (visitor.x in [0,127] or visitor.y in [0,127]))
	roundtrip(check,"SAVE/minor_offer_and_rng_roundtrip",world)
	var command: int = accept(world,event);var job: Dictionary = world.find(world.jobs,event.jobs[0])
	check.call("MINOR/carrier_accept_reserves_eight_wood_without_consuming",world.receipts[command]=="accepted" and world.total("wood")==44 and world.stacks.reduce(func(n:int,s:Dictionary)->int:return n+s.reservations.get(job.id,0),0)==8 and world.total("cloth")==0 and job.required==12000)
	check.call("MINOR/carrier_waits_for_physical_visitor",not ColonyOpportunities.reserve(world,job,world.citizens[1]) and job.reason.contains("Visitor"))
	roundtrip(check,"SAVE/accepted_minor_reservations_roundtrip",world)
	world.queue_command("minor_event",{"target":event.id,"accept":true},command);world.step()
	check.call("MINOR/repeated_command_cannot_create_second_payment",event.jobs.size()==1 and world.stacks.reduce(func(n:int,s:Dictionary)->int:return n+s.reservations.get(job.id,0),0)==8)
	finish(world,event)
	check.call("MINOR/carrier_physical_repair_exact_payment_work_reward",event.state=="Complete" and event.receipt==event.id and job.state=="Complete" and job.work==12000 and world.total("wood")==36 and world.total("cloth")==4 and world.trade_state.reputation.road_fellowship==23 and world.ledger.consumed.get("wood",0)==8 and world.invariant_errors().is_empty(),str(world.invariant_errors())+" "+event.state+" "+job.reason)
	ColonyOpportunities.complete(world,event);ColonyOpportunities.finished_work(world,job)
	check.call("MINOR/carrier_reward_receipt_prevents_duplicate",world.total("cloth")==4 and world.trade_state.reputation.road_fellowship==23)
	roundtrip(check,"SAVE/completed_minor_receipt_roundtrip",world)
	for index in range(2000):
		world.tick+=1;world.path_requests=0;ColonyOpportunities.advance(world)
		if visitor.state=="Gone": break
	check.call("MINOR/visitor_walks_out_to_original_boundary",visitor.state=="Gone" and Vector2i(visitor.x,visitor.y)==visitor.entry)

static func harvest(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var event: Dictionary = ColonyOpportunities.offer(world,"surplus_harvest");accept(world,event)
	var job: Dictionary = world.find(world.jobs,event.jobs[0]);var found: bool = false
	for index in range(2500):
		world.step()
		if world.stacks.any(func(s:Dictionary)->bool:return s.location=="carry" and s.job==job.id): found=true;break
	check.call("MINOR/harvest_payment_is_carried_in_visible_stacks",found and world.total("wood")==44 and world.total("grain")==0)
	roundtrip(check,"SAVE/minor_payment_mid_carry_roundtrip",world)
	world._release(job,false)
	var reserved: int = world.stacks.reduce(func(n:int,s:Dictionary)->int:return n+s.reservations.get(job.id,0),0)+world._escrow_count(job.id,"wood")
	check.call("MINOR/interruption_retains_exact_payment_claim",reserved==20 and event.state=="Accepted" and world.invariant_errors().is_empty(),str(reserved)+" "+str(world.invariant_errors()))
	finish(world,event)
	check.call("MINOR/harvest_exact_twenty_for_sixteen_once",event.state=="Complete" and world.total("wood")==24 and world.total("grain")==16 and world.ledger.traded_out.get("wood",0)==20 and world.ledger.traded_in.get("grain",0)==16 and world.invariant_errors().is_empty(),event.state+" "+job.reason)
	world=ColonyTests.world();event=ColonyOpportunities.offer(world,"surplus_harvest");accept(world,event);job=world.find(world.jobs,event.jobs[0]);found=false
	for index in range(2500):
		world.step()
		if world.stacks.any(func(s:Dictionary)->bool:return s.location=="carry" and s.job==job.id): found=true;break
	world.queue_command("cancel",{"target":job.id});world.step()
	check.call("MINOR/player_cancel_returns_carried_payment_without_penalty",found and event.state=="Failed" and world.total("wood")==44 and world.total("grain")==0 and world.trade_state.reputation.orchard_kin==20 and world.stacks.all(func(s:Dictionary)->bool:return not s.reservations.has(job.id)) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	roundtrip(check,"SAVE/canceled_minor_roundtrip",world)
	world=ColonyTests.world();event=ColonyOpportunities.offer(world,"surplus_harvest")
	for stack in world.stacks:
		if stack.item=="wood": world._record("consumed","wood",stack.count);stack.count=0
	var next: int = world.next_id
	check.call("MINOR/unfunded_accept_is_atomic",ColonyOpportunities.command(world,{"target":event.id,"accept":true}).contains("Payment") and event.state=="Offered" and event.jobs.is_empty() and world.next_id==next)

static func observation(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var desk: Dictionary = world._structure("research_desk",Vector2i(72,64),0)
	world.social_state.pairs[ColonySocial.key(1,2)].score=40
	var event: Dictionary = ColonyOpportunities.offer(world,"shared_observation");accept(world,event)
	var first: Dictionary = world.find(world.jobs,event.jobs[0]);var second: Dictionary = world.find(world.jobs,event.jobs[1])
	var insight: int = world.production_state.insight
	var first_xp: int = world.citizens[0].xp.Study;var second_xp: int = world.citizens[1].xp.Study
	check.call("MINOR/observation_pins_two_friends_and_real_desk",event.people==[1,2] and event.station==desk.id and first.order==1 and second.order==2 and first.required==20000 and second.required==20000)
	check.call("MINOR/third_person_cannot_substitute_for_friend",not ColonyOpportunities.reserve(world,first,world.citizens[2]))
	var partial: bool = false
	for index in range(3000):
		world.step()
		if event.completed.size()==1:
			partial=true
			check.call("MINOR/one_scholar_does_not_release_insight",world.production_state.insight==insight and event.state=="Accepted")
			roundtrip(check,"SAVE/one_friend_observation_roundtrip",world)
			break
	check.call("MINOR/first_friend_performs_real_study",partial)
	finish(world,event)
	check.call("MINOR/two_twenty_WU_studies_give_exact_insight_and_XP",event.state=="Complete" and world.production_state.insight==insight+100 and world.citizens[0].xp.Study==first_xp+20000 and world.citizens[1].xp.Study==second_xp+20000 and first.work==20000 and second.work==20000,event.state+" "+first.reason+" "+second.reason)
	ColonyOpportunities.complete(world,event)
	check.call("MINOR/observation_insight_cannot_repeat",world.production_state.insight==insight+100)
	roundtrip(check,"SAVE/completed_observation_roundtrip",world)

static func storytelling(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var table: Dictionary = world._structure("table",Vector2i(72,66),0)
	var event: Dictionary = ColonyOpportunities.offer(world,"traveling_storyteller");accept(world,event)
	var visitor: Dictionary = world.find(world.opportunity_state.visitors,event.visitor)
	var waiting_seen: bool = false
	for index in range(2500):
		world.step()
		if event.state=="Hosted" and event.host_until==0: waiting_seen=true
		if event.host_until>0: break
	check.call("MINOR/host_timer_waits_for_physical_table_arrival",waiting_seen and visitor.state=="Hosting" and event.host_until==world.tick+1800 and world.ledger.consumed.get("meal",0)==2 and event.station==table.id)
	roundtrip(check,"SAVE/hosted_storyteller_roundtrip",world)
	var person: Dictionary = world.citizens[0]
	world._release(world.find(world.jobs,person.job),false)
	person.x=visitor.x;person.y=visitor.y
	var leisure: Dictionary = world._job("leisure","","",person.id,Vector2i(person.x,person.y),0)
	leisure.state="Working";leisure.worker=person.id;person.job=leisure.id
	for index in range(100): world.tick+=1;world.path_requests=0;ColonyOpportunities.advance(world)
	leisure.state="Moving";world.tick+=1;ColonyOpportunities.advance(world);leisure.state="Working"
	for index in range(149): world.tick+=1;world.path_requests=0;ColonyOpportunities.advance(world)
	check.call("MINOR/story_requires_consecutive_half_hour_with_visitor",person.story_memory_until==0 and event.attendance[person.id]==149)
	world.tick+=1;ColonyOpportunities.advance(world)
	check.call("MINOR/story_memory_has_exact_one_day_expiry",person.story_memory_until==world.tick+7200 and event.attendance[person.id]==150)
	var memory_until: int = person.story_memory_until
	for index in range(151): world.tick+=1;world.path_requests=0;ColonyOpportunities.advance(world)
	check.call("MINOR/continued_story_does_not_stack_or_refresh_reward",person.story_memory_until==memory_until)
	world.tick=event.host_until-1;ColonyOpportunities.advance(world)
	check.call("MINOR/host_is_active_until_six_hours_elapsed",event.state=="Hosted")
	world.tick+=1;ColonyOpportunities.advance(world)
	check.call("MINOR/host_completes_at_exact_six_hour_boundary",event.state=="Complete" and visitor.state=="Leaving")

static func scheduling(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();world.tick=24000
	ColonyOpportunities.advance(world)
	check.call("MINOR/day_four_eight_am_first_offer",world.opportunity_state.offers.size()==1 and world.opportunity_state.offers[0].created==24000)
	var event: Dictionary = world.opportunity_state.offers[0]
	ColonyOpportunities.cancel(world,event,"Declined");ColonyOpportunities.advance(world)
	check.call("MINOR/no_second_offer_same_day_even_after_decline",world.opportunity_state.offers.size()==1)
	check.call("MINOR/eight_day_repeat_cooldown",world.opportunity_state.after[event.definition]==81600 and ColonyOpportunities.offer(world,event.definition).is_empty())
	world=ColonyTests.world();event=ColonyOpportunities.offer(world,"stranded_carrier")
	var before: Dictionary = world.trade_state.reputation.duplicate()
	accept(world,event);world.tick=event.deadline;ColonyOpportunities.advance(world)
	check.call("MINOR/deadline_returns_unconsumed_payment_without_penalty",event.state=="Failed" and world.total("wood")==44 and world.trade_state.reputation==before and world.stacks.all(func(s:Dictionary)->bool:return s.reservations.is_empty()))
	world=ColonyTests.world();event=ColonyOpportunities.offer(world,"stranded_carrier");world.tick=event.deadline
	check.call("MINOR/late_accept_cannot_race_expiry",ColonyOpportunities.command(world,{"target":event.id,"accept":true}).contains("deadline") and event.state=="Expired" and event.jobs.is_empty())
	world=ColonyTests.world();world.citizens[0].departure_until=50000;world.tick=24000;ColonyOpportunities.advance(world)
	check.call("MINOR/critical_choice_blocks_minor_offer",world.opportunity_state.offers.is_empty())
	world=ColonyTests.world()
	for index in range(8): world.defense_state.enemies.append({"state":"Downed"})
	event=ColonyOpportunities.offer(world,"stranded_carrier")
	var visitor: Dictionary = world.find(world.opportunity_state.visitors,event.visitor)
	check.call("MINOR/eight_visitors_delay_boundary_entry",visitor.state=="Waiting" and ColonyOpportunities.visitor_count(world)==8)
	world.defense_state.enemies[0].state="Gone";ColonyOpportunities.advance(world)
	check.call("MINOR/visitor_enters_only_after_capacity_frees",visitor.state=="Entering" and ColonyOpportunities.visitor_count(world)==8)
	world=ColonyTests.world();ColonyTrade.schedule(world,"orchard_kin").state="Entering"
	check.call("MINOR/approaching_merchant_excludes_surplus_offer",not ColonyOpportunities.eligible(world,"surplus_harvest"))

static func validation(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var event: Dictionary = ColonyOpportunities.offer(world,"stranded_carrier")
	var original: Dictionary = world.opportunity_state.duplicate(true)
	var malformed: Dictionary = original.duplicate(true);malformed.visitors[0].id="bad"
	check.call("SAVE/minor_rejects_bad_visitor_id_without_crash",not ColonyOpportunities.validate(malformed,world.citizens,world.definitions,world.tick))
	malformed=original.duplicate(true);malformed.visitors[0].route=[Vector2i(-1,2)]
	check.call("SAVE/minor_rejects_out_of_map_route",not ColonyOpportunities.validate(malformed,world.citizens,world.definitions,world.tick))
	malformed=original.duplicate(true);malformed.offers[0].receipt=event.id
	check.call("SAVE/minor_rejects_receipt_without_completion",not ColonyOpportunities.validate(malformed,world.citizens,world.definitions,world.tick))
	malformed=original.duplicate(true);malformed.offers[0].completed=[1,1]
	check.call("SAVE/minor_rejects_duplicate_contributions",not ColonyOpportunities.validate(malformed,world.citizens,world.definitions,world.tick))
	malformed=original.duplicate(true);malformed.after.stranded_carrier=0
	check.call("SAVE/minor_rejects_erased_cooldown",not ColonyOpportunities.validate(malformed,world.citizens,world.definitions,world.tick))
	accept(world,event)
	var job: Dictionary = world.find(world.jobs,event.jobs[0]);job.inputs.wood=1
	check.call("SAVE/minor_rejects_cheaper_payment_job",not ColonyOpportunities.valid_job(world.payload(),job,world.definitions))

static func edges(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var event: Dictionary = ColonyOpportunities.offer(world,"stranded_carrier")
	world.step()
	var visitor: Dictionary = world.find(world.opportunity_state.visitors,event.visitor)
	check.call("MINOR/visitor_has_interpolated_movement_edge",visitor.progress>0 and not visitor.route.is_empty())
	ColonyOpportunities.cancel(world,event,"Declined")
	check.call("MINOR/decline_preserves_edge_to_avoid_teleport",visitor.progress>0 and not visitor.route.is_empty())
	roundtrip(check,"SAVE/declined_visitor_mid_edge_roundtrip",world)
	world=ColonyTests.world();event=ColonyOpportunities.offer(world,"surplus_harvest");accept(world,event)
	var job: Dictionary = world.find(world.jobs,event.jobs[0]);var found: bool = false
	for index in range(3000):
		world.step()
		if world._escrow_count(job.id,"wood")==8: found=true;break
	check.call("MINOR/cart_relocation_fixture_has_partial_escrow",found)
	var wagon: Dictionary = ColonyTrade.cart(world);wagon.x+=1
	ColonyOpportunities.ready_complete(world,job)
	finish(world,event)
	check.call("MINOR/moved_cart_requires_redelivery_and_one_receipt",event.state=="Complete" and world.total("wood")==24 and world.total("grain")==16 and world.stacks.filter(func(s:Dictionary)->bool:return s.item=="grain" and s.count>0).all(func(s:Dictionary)->bool:return s.x==wagon.x and s.y==wagon.y) and world.invariant_errors().is_empty(),event.state+" "+job.reason+" "+str(world.invariant_errors()))
	world=ColonyTests.world();event=ColonyOpportunities.offer(world,"stranded_carrier");accept(world,event);job=world.find(world.jobs,event.jobs[0]);found=false
	for index in range(3000):
		world.step()
		if job.state=="Working": found=true;break
	check.call("MINOR/deadline_fixture_has_real_work_and_payment",found and world._escrow_count(job.id,"wood")==8)
	world.tick=event.deadline-1;job.work=job.required-1;ColonyWeather.initialize(world);world.step()
	check.call("MINOR/expiry_beats_same_tick_work_commit",event.state=="Failed" and world.total("cloth")==0 and world.total("wood")==44 and world.trade_state.reputation.road_fellowship==20 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();var table: Dictionary = world._structure("table",Vector2i(72,66),0);event=ColonyOpportunities.offer(world,"traveling_storyteller");accept(world,event)
	for index in range(3000):
		world.step()
		if event.host_until>0: break
	visitor=world.find(world.opportunity_state.visitors,event.visitor)
	var person: Dictionary = world.citizens[0];world._release(world.find(world.jobs,person.job),false)
	var other_table: Dictionary = world._structure("table",Vector2i(82,66),0)
	person.x=other_table.x-1;person.y=other_table.y
	var leisure: Dictionary = world._job("leisure","","",person.id,Vector2i(person.x,person.y),0);leisure.state="Working";leisure.worker=person.id;person.job=leisure.id
	for index in range(151): world.tick+=1;world.path_requests=0;ColonyOpportunities.advance(world)
	check.call("MINOR/remote_table_leisure_cannot_receive_story",person.story_memory_until==0 and event.attendance.get(person.id,0)==0)
	person.x=visitor.x;person.y=visitor.y
	for index in range(100): world.tick+=1;ColonyOpportunities.advance(world)
	person.away=true;world.tick+=1;ColonyOpportunities.advance(world);person.away=false
	check.call("MINOR/leaving_home_resets_incomplete_story_session",event.attendance.get(person.id,0)==0)
	table.health=0;world.navigation_dirty=true;world.tick+=1;ColonyOpportunities.advance(world)
	check.call("MINOR/table_lost_after_meal_delivery_ends_without_hidden_penalty",event.state=="Failed" and world.ledger.consumed.get("meal",0)==2 and world.trade_state.reputation=={"orchard_kin":20,"riverward":20,"road_fellowship":20})
