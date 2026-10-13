class_name DefenseTests
extends RefCounted

static func raid(world: ColonyWorld, budget: int = 2) -> Dictionary:
	var result: Dictionary = ColonyDefense.announce(world,budget)
	result.due=world.tick;ColonyDefense.arrive(world,result)
	return result

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	check.call("RAID/budgets_have_exact_composition_and_cap",ColonyDefense.party(2)==["hungry_thief","hungry_thief"] and ColonyDefense.party(5)==["road_raider","hungry_thief","hungry_thief"] and ColonyDefense.party(10)==["road_raider","bow_raider","hungry_thief","hungry_thief","hungry_thief","hungry_thief"])
	var visit: Dictionary = ColonyDefense.announce(world,2)
	check.call("RAID/fixed_party_warning_and_reachable_boundary",visit.due==world.tick+7200 and visit.party.size()==2 and (visit.entry.x in [0,127] or visit.entry.y in [0,127]) and ColonyNavigation.path(visit.entry,Vector2i(66,63),world.walkable,world.can_step).size()>=30 and world.defense_state.enemies.is_empty())
	var saved: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/announced_party_route_and_stream_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	visit.due=world.tick;ColonyDefense.arrive(world,visit)
	check.call("RAID/arrival_is_one_boundary_party_and_one_pause",visit.arrival==world.tick and visit.actors.size()==2 and world.defense_state.alert_serial==1 and world.defense_state.enemies.all(func(e:Dictionary)->bool:return Vector2i(e.x,e.y)==visit.entry))
	world.queue_command("draft",{"citizens":[2,3],"rally":Vector2i(70,65),"stand_fast":false});world.step()
	check.call("DEFEND/draft_is_authoritative_and_returns_to_work_on_undraft",world.citizens[1].drafted and world.citizens[2].drafted and world.citizens[1].rally==Vector2i(70,65))
	world.queue_command("undraft",{"citizens":[2,3]});world.step()
	check.call("DEFEND/undraft_releases_guard_tasks",not world.citizens[1].drafted and not world.citizens[2].drafted)
	var enemy: Dictionary = world.defense_state.enemies[0]
	enemy.x=70;enemy.y=65;enemy.goal.clear();enemy.route.clear();enemy.progress=0
	var person: Dictionary = world.citizens[1];person.x=69;person.y=65;person.edge_x=69;person.edge_y=65;person.drafted=true;person.equipment.weapon="spear";person.rally=Vector2i(69,65)
	var person_health: int = person.health;var enemy_health: int = enemy.health
	ColonyCombat.resolve(world)
	check.call("COMBAT/simultaneous_citizen_and_hostile_attacks",enemy.health==enemy_health-10 and person.health==person_health-5)
	var cooldown: int = person.attack_ready
	person.x=50;person.y=50;person.edge_x=50;person.edge_y=50;person.attack_ready=world.tick;enemy.cooldown=world.tick
	ColonyCombat.resolve(world)
	check.call("COMBAT/out_of_range_does_not_spend_cooldown",person.attack_ready==world.tick and enemy.cooldown==world.tick and cooldown>world.tick)
	person.health=40;person.drafted=true;person.stand_fast=false
	check.call("DEFEND/default_retreat_at_forty",not ColonyDefense.assign(world,person) and not person.drafted)
	person.drafted=true;person.stand_fast=true
	check.call("DEFEND/explicit_stand_fast_keeps_mobile_guard",ColonyDefense.assign(world,person) and person.drafted)
	world._release(world.find(world.jobs,person.job),true);person.drafted=false
	world=ColonyTests.world();visit=raid(world);enemy=world.defense_state.enemies[0];enemy.x=66;enemy.y=63
	var stack: Dictionary = world.stacks.filter(func(s:Dictionary)->bool:return s.item=="meal")[0];var meals: int = world.total("meal")
	ColonyDefense.steal(world,enemy,stack)
	check.call("RAID/four_actual_food_units_are_looted_once",enemy.loot[0].count==4 and world.total("meal")==meals-4 and world.ledger.looted.meal==4 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	ColonyDefense.hurt(world,enemy,999,3)
	check.call("RAID/downed_enemy_is_stable_neutral_at_one_and_drops_loot",enemy.health==1 and enemy.state=="Downed" and enemy.loot.is_empty() and world.total("meal")==meals and world.ledger.recovered.meal==4)
	var health_before: int = enemy.health;ColonyDefense.hurt(world,enemy,10,3)
	check.call("RAID/no_executions_or_repeat_drops",enemy.health==health_before and world.ledger.recovered.meal==4)
	world.queue_command("enemy_treat",{"target":enemy.id});world.step()
	for index in range(900):
		world.step()
		if enemy.treated: break
	check.call("RAID/voluntary_care_gives_three_reputation_once",enemy.treated and world.trade_state.reputation.road_fellowship==23 and world.ledger.consumed.get("herb",0)==1)
	if enemy.state=="Downed":
		ColonyDefense.treatment_complete(world,world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="enemy_treat")[0])
	check.call("RAID/repeated_treatment_cannot_farm_reputation",world.trade_state.reputation.road_fellowship==23)
	enemy.recovery_at=world.tick;ColonyDefense.advance(world)
	check.call("RAID/untreated_or_partly_treated_enemy_recovers_to_twenty_five",enemy.health>=25 and enemy.state in ["Leaving","Gone"])
	saved=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/loot_recovery_and_neutral_treatment_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	world=ColonyTests.world();visit=raid(world);visit.meeting=Vector2i(74,65)
	var offered: String = ColonyDefense.offer(world,{"target":visit.id,"pay":{"wood":16}})
	check.call("RAID/exact_eight_times_budget_offer_reserves_and_stops_attacks",offered=="accepted" and visit.state=="Payment" and world.total("wood")==44 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	saved=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/accepted_supplies_and_grace_timer_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	for index in range(900):
		world.step()
		if visit.state in ["Retreating","Resolved"]: break
	check.call("RAID/supplies_are_physically_delivered_then_party_leaves",visit.state in ["Retreating","Resolved"] and world.ledger.traded_out.get("wood",0)==16 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="raid_pay" and j.state=="Complete") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	check.call("RAID/retreat_cannot_be_restarted_by_an_offer",ColonyDefense.offer(world,{"target":visit.id,"pay":{"wood":16}}).contains("returning"))
	world=ColonyTests.world();visit=raid(world);ColonyDefense.offer(world,{"target":visit.id,"pay":{"wood":16}})
	visit.payment_deadline=world.tick;ColonyDefense.advance(world)
	check.call("RAID/failed_delivery_warns_one_hour_before_hostility",visit.state=="Grace" and visit.grace_until==world.tick+300)
	world.tick=visit.grace_until;ColonyDefense.advance(world)
	check.call("RAID/grace_expiry_restores_announced_hostility",visit.state in ["Active","Retreating"])
	world=ColonyTests.world();visit=raid(world);world.tick=visit.arrival+1800;ColonyWeather.initialize(world);ColonyDefense.advance(world)
	check.call("RAID/siege_never_exceeds_six_hours",visit.state in ["Retreating","Resolved"])
	world=ColonyTests.world();visit=raid(world,6)
	ColonyDefense.hurt(world,world.defense_state.enemies[0],999,2);ColonyDefense.advance(world)
	check.call("RAID/half_stopped_forces_whole_party_retreat",visit.state in ["Retreating","Resolved"] and world.defense_state.enemies[0].state=="Downed")
