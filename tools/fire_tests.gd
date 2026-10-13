class_name FireTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var wall: Dictionary = world._structure("wood_wall",Vector2i(80,80),0)
	var fire: Dictionary = ColonyFire.ignite(world,"structure",wall.id)
	var health: int = wall.health
	for index in range(10): world.tick+=1;ColonyFire.advance(world)
	check.call("FIRE/two_hp_per_simulated_second",wall.health==health-2 and world.fire_state.alert_serial==1)
	world.weather="rain";health=wall.health
	for index in range(10): world.tick+=1;ColonyFire.advance(world)
	check.call("FIRE/rain_halves_damage_exactly",wall.health==health-1)
	world=ColonyTests.world()
	wall=world._structure("wood_wall",Vector2i(80,80),0)
	var east: Dictionary = world._structure("wood_wall",Vector2i(81,80),0)
	var north: Dictionary = world._structure("wood_wall",Vector2i(80,79),0)
	fire=ColonyFire.ignite(world,"structure",wall.id)
	for index in range(299): world.tick+=1;ColonyFire.advance(world)
	check.call("FIRE/no_spread_before_thirty_seconds",ColonyFire.active(world).size()==1)
	world.tick+=1;ColonyFire.advance(world)
	check.call("FIRE/north_before_east_and_one_shared_pause",ColonyFire.burning(world,"structure",north.id) and not ColonyFire.burning(world,"structure",east.id) and world.fire_state.alert_serial==1)
	var saved: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/fire_roots_timers_and_damage_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	world=ColonyTests.world();world.weather="rain";ColonyWeather.initialize(world)
	wall=world._structure("wood_wall",Vector2i(80,80),0);north=world._structure("wood_wall",Vector2i(80,79),0);fire=ColonyFire.ignite(world,"structure",wall.id)
	for index in range(599): world.tick+=1;ColonyFire.advance(world)
	check.call("FIRE/rain_doubles_spread_interval",ColonyFire.active(world).size()==1)
	world.tick+=1;ColonyFire.advance(world)
	check.call("FIRE/rain_spreads_at_sixty_seconds",ColonyFire.burning(world,"structure",north.id))
	world=ColonyTests.world()
	var fuel: Dictionary = world._make_stack("wood",4,"ground",0,Vector2i(80,80),true)
	ColonyFire.ignite(world,"stack",fuel.id)
	for index in range(40): world.tick+=1;ColonyFire.advance(world)
	check.call("FIRE/ground_fuel_lost_once_per_second_and_conserved",fuel.count==0 and world.ledger.lost.wood==4 and ColonyFire.active(world).is_empty() and world.invariant_errors().is_empty())
	var food: Dictionary = world._make_stack("meal",4,"ground",0,Vector2i(80,80),true)
	check.call("FIRE/food_and_indestructible_cart_cannot_ignite",ColonyFire.ignite(world,"stack",food.id).is_empty() and ColonyFire.ignite(world,"structure",ColonyTrade.cart(world).id).is_empty())
	world=ColonyTests.world()
	var rack: Dictionary = world._structure("rack",Vector2i(80,80),0);rack.health=2
	world.stores.append({"id":rack.id,"tiles":[Vector2i(80,80)],"capacity":80,"priority":2,"filters":world.definitions.items.keys()})
	food=world._make_stack("meal",4,"store",rack.id,Vector2i(80,80),true);food.age=123;food.age_rem=2
	ColonyFire.ignite(world,"structure",rack.id)
	for index in range(10): world.tick+=1;ColonyFire.advance(world)
	check.call("FIRE/destroyed_store_drops_food_with_age_retained",rack.health==0 and food.location=="ground" and food.count==4 and food.age==123 and food.age_rem==2 and not world.stores.any(func(s:Dictionary)->bool:return s.id==rack.id) and world.fire_state.destroyed[-1].target==rack.id and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();wall=world._structure("wood_wall",Vector2i(80,80),0);fire=ColonyFire.ignite(world,"structure",wall.id)
	check.call("FIRE/danger_zone_and_safe_water_access",not ColonyDanger.safe(world,Vector2i(80,80)) and not ColonyFire.water(world,Vector2i(66,65)).is_empty())
	world=ColonyTests.world();world._structure("well",Vector2i(74,64),0)
	wall=world._structure("wood_wall",Vector2i(74,54),0);fire=ColonyFire.ignite(world,"structure",wall.id)
	for index in range(450):
		world.step()
		if fire.done: break
	check.call("FIRE/care_fetches_carries_and_extinguishes",fire.done and fire.work==8000 and wall.health>0 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="extinguish" and j.state=="Complete") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	check.call("FIRE/water_is_not_an_inventory_commodity",not world.stacks.any(func(s:Dictionary)->bool:return s.item=="water"))
	saved=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/completed_fire_and_emergency_job_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	world=ColonyTests.world();world._structure("well",Vector2i(74,64),0);wall=world._structure("wood_wall",Vector2i(74,54),0);fire=ColonyFire.ignite(world,"structure",wall.id)
	for index in range(350):
		world.step()
		if fire.work>0: break
	var job: Dictionary = world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="extinguish")[0];var progress: int = fire.work
	world._release(job,false)
	check.call("FIRE/interruption_discards_water_and_retains_partial_effort",progress>0 and fire.work==progress and job.work==progress and job.memo.phase=="water" and job.memo.water_work==0)
	saved=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/interrupted_water_and_partial_fire_roundtrip",saved.has("world") and saved.world.canonical_hash()==world.canonical_hash(),str(saved.get("error","")))
	for index in range(350):
		world.step()
		if fire.done: break
	check.call("FIRE/resumes_without_double_counting_eight_wu",fire.done and fire.pending_xp.values().reduce(func(n:int,v:int)->int:return n+v,0)==8000)
	world=ColonyTests.world();world._structure("well",Vector2i(74,64),0);wall=world._structure("wood_wall",Vector2i(74,54),0);fire=ColonyFire.ignite(world,"structure",wall.id)
	for person in world.citizens: person.preferences.Care=0
	for index in range(450):
		world.step()
		if fire.done: break
	check.call("FIRE/emergency_overrides_off_without_changing_preference",fire.done and fire.work==8000 and world.citizens.all(func(c:Dictionary)->bool:return c.preferences.Care==0))
	world=ColonyTests.world();var person: Dictionary = world.citizens[1]
	var tree: Dictionary = world.resources.filter(func(r:Dictionary)->bool:return r.definition=="tree" and r.remaining>0)[0]
	person.x=tree.x+1;person.y=tree.y;person.edge_x=person.x;person.edge_y=person.y;person.health=21
	var gather: Dictionary = world._job("gather","Gathering","Field",tree.id,Vector2i(tree.x,tree.y),16000)
	gather.worker=person.id;gather.state="Working";gather.work=15900;gather.pending_xp[person.id]=15900;person.job=gather.id
	var boar: Dictionary = ColonyWildlife.spawn(world,"boar",Vector2i(person.x,person.y))
	boar.x=person.x;boar.y=person.y;boar.route.clear();boar.progress=0;boar.attacker=person.id;boar.origin=Vector2i(boar.x,boar.y);boar.cooldown=0
	var before: int = world.ledger.produced.wood
	world.step()
	check.call("COMBAT/injury_resolves_before_completed_work_transaction",person.downed and tree.remaining==8 and world.ledger.produced.wood==before and gather.state!="Complete",str([person.health,tree.remaining,gather.state]))
	check.call("COMBAT/fog_reduces_bow_range_two",ColonyCombat.weapon(world.citizens[2],3,"fog").range==4 and ColonyCombat.weapon(world.citizens[2],3).range==6)
	world=ColonyTests.world();var raid: Dictionary = DefenseTests.raid(world)
	person=world.citizens[1];person.x=70;person.y=65;person.health=21;person.drafted=true;person.stand_fast=true
	var enemy: Dictionary = world.defense_state.enemies[0];enemy.x=71;enemy.y=65
	fuel=world._make_stack("wood",20,"ground",0,Vector2i(70,65),true);ColonyFire.ignite(world,"stack",fuel.id)
	ColonyCombat.resolve(world)
	check.call("COMBAT/fire_and_attacks_resolve_together_after_attack_selection",person.health==14 and person.downed and enemy.health==36 and fuel.count==19 and person.guard_xp_today==2)
	check.call("COMBAT/combined_fire_downing_emits_one_incident",world.facts.filter(func(f:Dictionary)->bool:return f.kind=="downed" and f.actor==person.id).size()==1)
	world.tick+=10;person.health=1;person.stabilized=true;enemy.cooldown=world.tick+25
	ColonyCombat.resolve(world)
	check.call("COMBAT/fire_can_harm_a_downed_resident_without_attack_execution",person.death_recorded and enemy.health==36 and world.facts.any(func(f:Dictionary)->bool:return f.kind=="fire_injury" and f.actor==person.id))
