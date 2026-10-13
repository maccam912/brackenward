class_name ChronicleTests
extends RefCounted

static func emit(world: ColonyWorld, kind: String, text: String, actor: int = 0, details: Dictionary = {}) -> int:
	return ColonyChronicle.emit(world,{"tick":world.tick,"actor":actor,"job":0,"kind":kind,"text":text},details)

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var injury: int = emit(world,"boar_injury","Oren was injured by a boar.",2,{"location":[74,66]})
	var rescued: int = emit(world,"rescue","Mira carried Oren to safety.",1,{"participants":[1,2],"causes":[injury],"location":[66,64],"changes":{"meal":-1}})
	var record: Dictionary = ColonyChronicle.fact(world.chronicle_state,rescued)
	check.call("STORY/rich_fact_captures_exact_evidence",record.id==rescued and record.tick==1800 and record.participants==[1,2] and record.names=={1:"Mira",2:"Oren"} and record.causes==[injury] and record.location==[66,64] and record.changes=={"meal":-1} and record.salience==60)
	var independent: int = emit(world,"rescue","Tavi carried Sela to safety.",3,{"participants":[3,4]})
	check.call("STORY13/no_causality_inferred_from_nearby_boar_injury",ColonyChronicle.fact(world.chronicle_state,independent).causes.is_empty() and ColonyChronicle.fact(world.chronicle_state,independent).chain==independent and not ColonyChronicle.fact(world.chronicle_state,independent).text.contains("boar"))
	check.call("STORY/legacy_five_field_view_remains_compatible",world.facts[-1]=={"tick":1800,"actor":3,"job":0,"kind":"rescue","text":"Tavi carried Sela to safety."})
	check.call("STORY/names_require_trimmed_basic_latin_and_length",ColonyChronicle.command(world,"rename",{"target":1,"text":"  Juniper  "})=="accepted" and world.citizens[0].name=="Juniper" and ColonyChronicle.command(world,"rename",{"target":1,"text":"Caf\u00e9"}).contains("Basic Latin"))
	names(check,world,rescued)
	journal(check)
	retention(check)
	validation(check)
	producers(check)
	memory_producers(check)

static func names(check: Callable, world: ColonyWorld, historical: int) -> void:
	check.call("STORY/name_snapshot_survives_rename",ColonyChronicle.fact(world.chronicle_state,historical).names[1]=="Mira" and ColonyChronicle.fact(world.chronicle_state,historical).text=="Mira carried Oren to safety.")
	check.call("STORY/rejects_blank_long_and_control_character_names",ColonyChronicle.command(world,"rename",{"target":1,"text":" "})!="accepted" and ColonyChronicle.command(world,"rename",{"target":1,"text":"a".repeat(33)})!="accepted" and ColonyChronicle.command(world,"rename",{"target":1,"text":"A\tB"})!="accepted")
	var cart: Dictionary = ColonyTrade.cart(world)
	check.call("STORY/building_and_settlement_names_are_cosmetic",ColonyChronicle.command(world,"rename",{"target":cart.id,"text":"Old Wayhouse"})=="accepted" and ColonyChronicle.display_name(world,cart.id)=="Old Wayhouse" and cart.definition=="supply_cart" and ColonyChronicle.command(world,"rename",{"target":0,"text":"Fernhaven"})=="accepted" and world.chronicle_state.settlement=="Fernhaven")
	var id: int = world.queue_command("pin_moment",{"text":"First harvest"});world.step();world.queue_command("pin_moment",{"text":"First harvest"},id);world.step()
	check.call("STORY/pin_moment_command_is_once_and_preserved",world.receipts[id]=="accepted" and world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="pin_moment" and f.preserved).size()==1)
	check.call("STORY/pin_empty_allowed_and_limit_explained",ColonyChronicle.command(world,"pin_moment",{"text":""})=="accepted" and ColonyChronicle.command(world,"pin_moment",{"text":"x".repeat(257)}).contains("256"))
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/chronicle_names_evidence_pins_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))

static func journal(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var injury: int = emit(world,"boar_injury","A witnessed injury.",2)
	world.tick+=1;var rescue: int = emit(world,"rescue","Mira carried Oren.",1,{"participants":[1,2],"causes":[injury]})
	world.tick+=1;var friendship: int = emit(world,"friendship","Mira and Oren became friends.",1,{"participants":[1,2],"causes":[rescue]})
	world.tick+=1;var death: int = emit(world,"death","A recorded death.",4)
	world.tick+=1;var charter: int = emit(world,"charter_stage","The shelter stage was completed.")
	for index in range(10): emit(world,"cook","A meal batch finished.")
	world.tick=6599;ColonyChronicle.advance(world)
	check.call("STORY/journal_does_not_compile_before_twenty_two",world.chronicle_state.journal.is_empty())
	world.tick=6600;ColonyChronicle.advance(world);ColonyChronicle.advance(world)
	check.call("STORY/daily_top_three_salience_ties_earliest_and_once",world.chronicle_state.journal.size()==1 and world.chronicle_state.journal[0].fact_ids==[death,charter,friendship])
	check.call("STORY/causal_chain_merges_rescue_and_friendship",ColonyChronicle.fact(world.chronicle_state,friendship).chain==injury and world.chronicle_state.journal[0].fact_ids.count(rescue)==0)
	for index in range(12):
		world.tick+=1;emit(world,"research_complete","Discovery "+str(index),1)
	var ending: Array = ColonyChronicle.epilogue(world)
	check.call("STORY/epilogue_eight_distinct_chains_in_chronological_order",ending.size()==8 and ending[0].id==friendship and ending[1].id==death and ending[2].id==charter and ending.map(func(f:Dictionary)->int:return f.chain).size()==8)
	check.call("STORY/citizen_historical_highlights_are_bounded",ColonyChronicle.highlights(world,1).size()==10)
	var other: int = emit(world,"fire_injury","A separate fire injury.",3)
	var joined: int = emit(world,"rescue","An explicitly shared rescue.",2,{"causes":[other,injury]})
	check.call("STORY/explicit_multiple_causes_join_existing_chains",ColonyChronicle.fact(world.chronicle_state,other).chain==injury and ColonyChronicle.fact(world.chronicle_state,joined).chain==injury and ColonyChronicle.validate(world.chronicle_state,world.tick,world.definitions))

static func retention(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var unreferenced: int = emit(world,"cook","A routine old meal.")
	var injury: int = emit(world,"boar_injury","Oren was injured.",2,{"changes":{"wood":-2}})
	var rescue: int = emit(world,"rescue","Mira carried Oren.",1,{"participants":[1,2],"causes":[injury]})
	var friendship: int = emit(world,"friendship","They became friends.",1,{"participants":[1,2],"causes":[rescue]})
	world.tick=6600;ColonyChronicle.advance(world)
	for index in range(2020): emit(world,"cook","Routine batch "+str(index))
	var state: Dictionary = world.chronicle_state
	check.call("STORY14/ring_keeps_last_two_thousand_ordinary_plus_preserved",state.facts.filter(func(f:Dictionary)->bool:return not f.preserved).size()==2000 and state.facts.any(func(f:Dictionary)->bool:return f.id==friendship and f.preserved) and world.facts.size()==2000)
	check.call("STORY14/evicted_causes_keep_compact_names_text_changes",state.archive.has(injury) and state.archive.has(rescue) and state.archive[injury].names[2]=="Oren" and state.archive[injury].changes=={"wood":-2} and state.archive[rescue].text=="Mira carried Oren." and not state.archive[rescue].has("participants"))
	check.call("STORY14/unreferenced_old_ordinary_facts_are_pruned",ColonyChronicle.fact(state,unreferenced).is_empty())
	check.call("STORY14/no_dangling_causal_or_journal_references",ColonyChronicle.validate(state,world.tick,world.definitions))
	world=ColonyTests.world();var source: int = emit(world,"research_complete","A discovery.",4)
	world.tick=6600;ColonyChronicle.advance(world)
	for index in range(2005): emit(world,"haul","An ordinary delivery.")
	check.call("STORY14/daily_entry_preserves_evicted_selected_fact",world.chronicle_state.archive.has(source) and world.chronicle_state.journal[0].fact_ids==[source] and ColonyChronicle.validate(world.chronicle_state,world.tick,world.definitions))
	world=ColonyTests.world();source=emit(world,"research_complete","A morning discovery.",4)
	for index in range(2010): emit(world,"haul","Delivery before the evening journal.")
	world.tick=6600;ColonyChronicle.advance(world)
	check.call("STORY14/busy_day_cannot_evict_journal_candidates_before_selection",world.chronicle_state.archive.has(source) and world.chronicle_state.journal[0].fact_ids==[source])
	ColonyWeather.initialize(world)
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/compacted_chronicle_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))

static func validation(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var id: int = emit(world,"death","A retained factual event.",1)
	var original: Dictionary = world.chronicle_state.duplicate(true);var bad: Dictionary = original.duplicate(true)
	bad.facts[0].causes=[id]
	check.call("SAVE/chronicle_rejects_self_causal_cycle",not ColonyChronicle.validate(bad,world.tick,world.definitions))
	bad=original.duplicate(true);bad.facts[0].causes=[999]
	check.call("SAVE/chronicle_rejects_missing_cause",not ColonyChronicle.validate(bad,world.tick,world.definitions))
	bad=original.duplicate(true);bad.facts[0].names={}
	check.call("SAVE/chronicle_requires_participant_name_snapshot",not ColonyChronicle.validate(bad,world.tick,world.definitions))
	bad=original.duplicate(true);bad.facts[0].preserved=false
	check.call("SAVE/chronicle_cannot_unpreserve_death",not ColonyChronicle.validate(bad,world.tick,world.definitions))
	bad=original.duplicate(true);bad.facts[0].location=[-1,0]
	check.call("SAVE/chronicle_rejects_invalid_location",not ColonyChronicle.validate(bad,world.tick,world.definitions))
	bad=original.duplicate(true);bad.facts[0].changes={"not_an_item":1}
	check.call("SAVE/chronicle_rejects_unknown_item_changes",not ColonyChronicle.validate(bad,world.tick,world.definitions))
	bad=original.duplicate(true);bad.facts[0].salience=0
	check.call("SAVE/chronicle_death_salience_is_fixed",not ColonyChronicle.validate(bad,world.tick,world.definitions))
	var migrated: Dictionary = ColonyChronicle.from_legacy(world.payload())
	check.call("SAVE/legacy_facts_migrate_deterministically_without_invented_causes",migrated==ColonyChronicle.from_legacy(world.payload()) and migrated.facts[0].text=="A retained factual event." and migrated.facts[0].causes.is_empty() and migrated.facts[0].location.is_empty() and ColonyChronicle.validate(migrated,world.tick,world.definitions))

static func producers(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var patient: Dictionary = world.citizens[1]
	patient.x=74;patient.y=66;patient.edge_x=74;patient.edge_y=66;patient.health=25
	var boar: Dictionary = ColonyWildlife.spawn(world,"boar",Vector2i(75,66));boar.health=60;boar.attacker=patient.id
	ColonyCombat.resolve(world)
	var injury: Dictionary = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="boar_injury")[0]
	var downed: Dictionary = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="downed")[0]
	check.call("STORY/real_combat_injury_precedes_and_causes_downing",patient.health==13 and downed.causes==[injury.id] and injury.participants==[patient.id,boar.id] and injury.location==[74,66])
	boar.health=0
	for person in world.citizens:
		for category in person.preferences: person.preferences[category]=0
	world.citizens[0].preferences.Care=3
	for index in range(1000):
		world.step()
		if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="rescue" and j.state=="Complete"): break
	var rescues: Array = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="rescue")
	var friendships: Array = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="friendship")
	check.call("STORY/physical_rescue_uses_exact_downing_chain_once",rescues.size()==1 and rescues[0].causes==[downed.id] and rescues[0].text.contains("after a boar injury") and rescues[0].participants==[1,2])
	check.call("STORY/first_friendship_links_completed_rescue",friendships.size()==1 and friendships[0].preserved and friendships[0].salience==80 and friendships[0].causes==[rescues[0].id])
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/real_injury_rescue_friendship_links_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world=ColonyTests.world();patient=world.citizens[1]
	emit(world,"boar_injury","A different old boar encounter.",3)
	ColonyCare.hurt(world,patient,90,true)
	for index in range(600):
		world.step()
		if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="rescue" and j.state=="Complete"): break
	rescues=world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="rescue")
	check.call("STORY13/real_rescue_without_boar_link_uses_short_factual_text",rescues.size()==1 and not rescues[0].text.contains("boar") and not ColonyChronicle.has_ancestor(world,rescues[0].causes,"boar_injury"))
	world=ColonyTests.world();patient=world.citizens[1]
	ColonyCare.hurt(world,patient,90,true)
	var treatment: Dictionary = world._job("treat","Care","Care",patient.id,Vector2i(patient.x,patient.y),16000)
	treatment.definition="herb";treatment.inputs={"herb":1};treatment.work=16000
	world._make_stack("herb",1,"escrow",treatment.id,Vector2i(patient.x,patient.y),true)
	world._finish(world.citizens[0],treatment)
	var treated: Array = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="treatment")
	check.call("STORY/treatment_evidence_matches_real_consumption_and_people",treated.size()==1 and treated[0].changes=={"herb":-1} and treated[0].participants==[1,2] and treated[0].location==[patient.x,patient.y] and world.ledger.consumed.herb==1)
	world=ColonyTests.world();ColonySocial._offer(world)
	var request: Dictionary = world.social_state.requests[0]
	ColonySocial.command(world,"request_accept",{"target":request.id})
	var accepted: Array = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="request_accepted")
	check.call("STORY/accepted_personal_promise_preserves_offer_cause",accepted.size()==1 and accepted[0].preserved and not accepted[0].causes.is_empty() and ColonyChronicle.fact(world.chronicle_state,accepted[0].causes[0]).kind=="request_offered")
	ColonySocial._resolve(world,request,false)
	var memory: Array = ColonyChronicle.active_memories(world,world.find(world.citizens,request.actor))
	check.call("STORY/request_memory_has_exact_penalty_expiry_and_fact",memory.any(func(m:Dictionary)->bool:return m.modifier== -60 and m.expires==world.tick+14400 and m.fact_id>0 and ColonyChronicle.fact(world.chronicle_state,m.fact_id).kind=="request_failed") and memory.size()<=3)
	world=ColonyTests.world();world.social_state.pairs["1:2"].score=50;ColonyCare.hurt(world,world.citizens[1],100,false)
	memory=ColonyChronicle.active_memories(world,world.citizens[0])
	check.call("STORY/grief_memory_points_to_recorded_death",memory.any(func(m:Dictionary)->bool:return m.modifier== -180 and m.expires==world.tick+21600 and m.fact_id>0 and ColonyChronicle.fact(world.chronicle_state,m.fact_id).kind=="death"))
	world=ColonyTests.world();ColonyProduction.finish_project(world,"storecraft")
	memory=ColonyChronicle.active_memories(world,world.citizens[3])
	check.call("STORY/discovery_memory_uses_explicit_producer_link",memory.any(func(m:Dictionary)->bool:return m.modifier==60 and m.expires==world.tick+14400 and m.fact_id>0 and ColonyChronicle.fact(world.chronicle_state,m.fact_id).kind=="research_complete"))
	var visitor: Dictionary = TradeTests.merchant(world);TradeTests.accept(world,visitor,{"meal":2},{"wood":8})
	var exchange: Dictionary = world.trade_state.exchanges[0];TradeTests.finish(world,exchange)
	var receipts: Array = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="trade_receipt")
	check.call("STORY/trade_receipt_matches_committed_net_goods_and_cart",receipts.size()==1 and receipts[0].changes=={"wood":-8,"meal":2} and receipts[0].location==[ColonyTrade.cart(world).x,ColonyTrade.cart(world).y] and receipts[0].participants.has(visitor.id) and ColonyChronicle.fact(world.chronicle_state,receipts[0].causes[0]).kind=="trade_accepted")
	var protected: int = emit(world,"health_loss","A pending injury.",1)
	ColonyChronicle.remember(world,"test_pending",protected)
	for index in range(2010): emit(world,"haul","A routine move.")
	check.call("STORY/persisted_transaction_links_protect_pending_causes",world.chronicle_state.archive.has(protected) and ColonyChronicle.causes(world,"test_pending")==[protected] and ColonyChronicle.validate(world.chronicle_state,world.tick,world.definitions))

static func memory_producers(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var person: Dictionary = world.citizens[0]
	var bed: Dictionary = world._structure("bed",Vector2i(person.x,person.y),0)
	person.bed=bed.id;bed.user=person.id
	var sleep: Dictionary = world._job("sleep","","",bed.id,Vector2i(person.x,person.y),0)
	sleep.worker=person.id;sleep.state="Working";person.job=sleep.id;person.bed_sleep_ticks=1199
	ColonyLiving.advance(world)
	var memory: Array = ColonyChronicle.active_memories(world,person)
	check.call("STORY/assigned_bed_memory_links_completed_sleep",memory.any(func(m:Dictionary)->bool:return m.modifier==80 and m.expires==world.tick+7200 and m.fact_id>0 and ColonyChronicle.fact(world.chronicle_state,m.fact_id).kind=="rested_in_bed"))
	for index in range(5): world.tick+=1;ColonyLiving.advance(world)
	check.call("STORY/bed_memory_refresh_does_not_duplicate_event",world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="rested_in_bed").size()==1)
	person.leisure_ticks=450
	ColonyLiving.advance(world);ColonyLiving.advance(world)
	memory=ColonyChronicle.active_memories(world,person)
	check.call("STORY/daily_leisure_memory_links_one_threshold_event",world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="leisure_completed").size()==1 and memory.any(func(m:Dictionary)->bool:return m.text=="Completed leisure" and m.modifier==60 and m.fact_id>0))
	world=SocialTests.leisure_fixture();world.social_state.pairs["1:2"].score=40
	SocialTests.advance(world,150)
	memory=ColonyChronicle.active_memories(world,world.citizens[0])
	check.call("STORY/shared_friend_memory_links_actual_conversation",memory.any(func(m:Dictionary)->bool:return m.modifier==40 and m.fact_id>0 and ColonyChronicle.fact(world.chronicle_state,m.fact_id).kind=="shared_leisure"))
	memory=ColonyChronicle.active_memories(world,world.citizens[3])
	check.call("STORY/private_memory_links_actual_quiet_leisure",memory.any(func(m:Dictionary)->bool:return m.modifier==40 and m.fact_id>0 and ColonyChronicle.fact(world.chronicle_state,m.fact_id).kind=="quiet_leisure"))
	SocialTests.advance(world,150)
	check.call("STORY/private_memory_is_once_per_daily_period",world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="quiet_leisure").size()==1)
	world=ColonyTests.world();person=world.citizens[0]
	var pair: Dictionary = world.social_state.pairs["1:2"]
	pair.score=-40;pair.conflict_clock=1199
	world.room_tiles={Vector2i(74,69):1,Vector2i(75,69):1};world.rooms_dirty=false
	for index in range(2):
		var actor: Dictionary = world.citizens[index]
		actor.x=74+index;actor.y=69
		var job: Dictionary = world._job("build","Building","Build",0,Vector2i(actor.x,actor.y),100000)
		job.worker=actor.id;job.state="Working";actor.job=job.id
	ColonySocial._disagreement(world,pair)
	memory=ColonyChronicle.active_memories(world,person)
	check.call("STORY/conflict_memory_links_both_participants",memory.any(func(m:Dictionary)->bool:return m.modifier== -60 and m.expires==world.tick+14400 and m.fact_id>0 and ColonyChronicle.fact(world.chronicle_state,m.fact_id).participants==[1,2]))
	person.broken_promise_until=world.tick+7200
	memory=ColonyChronicle.active_memories(world,person)
	check.call("STORY/conflict_and_promise_memory_do_not_duplicate_penalty",memory.filter(func(m:Dictionary)->bool:return m.modifier== -60).size()==1)
	world=ColonyTests.world();person=world.citizens[1]
	var feed: Dictionary = world._job("feed","Care","Care",person.id,Vector2i(person.x,person.y),4000)
	feed.inputs={"berry":1};feed.work=4000
	world._make_stack("berry",1,"escrow",feed.id,Vector2i(person.x,person.y),true)
	world._finish(world.citizens[0],feed)
	memory=ColonyChronicle.active_memories(world,person)
	check.call("STORY/fed_raw_food_memory_links_consumed_item",memory.any(func(m:Dictionary)->bool:return m.modifier== -50 and m.expires==world.tick+1800 and m.fact_id>0 and ColonyChronicle.fact(world.chronicle_state,m.fact_id).kind=="patient_fed" and ColonyChronicle.fact(world.chronicle_state,m.fact_id).changes=={"berry":-1}))
