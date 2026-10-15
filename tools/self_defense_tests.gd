class_name SelfDefenseTests
extends RefCounted

static func fixture(kind: String="hungry_thief", distance: int=1) -> Dictionary:
	var world: ColonyWorld=ColonyTests.world();var raid: Dictionary=DefenseTests.raid(world,2 if kind=="hungry_thief" else 6)
	var enemy: Dictionary=world.defense_state.enemies.filter(func(e:Dictionary)->bool:return e.definition==kind)[0]
	enemy.x=20;enemy.y=20
	var person: Dictionary=world.citizens[1];person.x=20+distance;person.y=20;person.edge_x=person.x;person.edge_y=person.y;person.drafted=true;person.route.clear();person.progress=0
	var stack: Dictionary=world.stacks.filter(func(s:Dictionary)->bool:return s.item=="meal")[0]
	enemy.target_stack=stack.id;enemy.last_attacker=person.id
	return {"world":world,"raid":raid,"enemy":enemy,"person":person,"stack":stack}

static func enemy_hits(f: Dictionary) -> Array:
	return ColonyDefense.attacks(f.world).filter(func(hit:Dictionary)->bool:return hit.kind=="citizen" and hit.source==f.enemy.id)

static func run(check: Callable) -> void:
	for mode in ["far_goods","near_goods","no_target"]:
		var f: Dictionary=fixture()
		if mode=="near_goods":f.stack.x=22;f.stack.y=20
		elif mode=="no_target":f.enemy.target_stack=0
		ColonyCombat.resolve(f.world)
		var restored: Dictionary=ColonyCodec.decode(ColonyCodec.encode(f.world))
		check.call("COMBAT/intercepted_raider_defends_simultaneously_"+mode,f.person.health==95 and f.enemy.health==36 and f.enemy.cooldown==1825 and f.enemy.attacking==f.person.id and f.enemy.x==20 and f.enemy.y==20 and f.enemy.progress==0 and f.world.invariant_errors().is_empty() and restored.has("world") and restored.world.canonical_hash()==f.world.canonical_hash())
	for row in [["hungry_thief",1,"clear",5,25],["hungry_thief",2,"clear",0,0],["road_raider",1,"clear",8,25],["bow_raider",1,"clear",5,25],["bow_raider",2,"clear",6,35],["bow_raider",6,"clear",6,35],["bow_raider",7,"clear",0,0],["bow_raider",4,"fog",6,35],["bow_raider",5,"fog",0,0]]:
		var f: Dictionary=fixture(row[0],row[1]);f.world.weather=row[2]
		var hits: Array=enemy_hits(f)
		check.call("COMBAT/far_goods_keeps_%s_range%d_%s" % [row[0],row[1],row[2]],(hits.is_empty() if row[3]==0 else hits.size()==1 and hits[0].damage==row[3]) and f.enemy.cooldown==(0 if row[4]==0 else f.world.tick+row[4]))
	var f: Dictionary=fixture();f.person.drafted=false
	var hits: Array=enemy_hits(f)
	check.call("COMBAT/undrafted_recent_attacker_can_be_counterattacked_in_range",hits.size()==1 and hits[0].target==f.person.id)
	f=fixture();f.person.drafted=false;f.enemy.last_attacker=0;hits=enemy_hits(f)
	check.call("COMBAT/uninvolved_civilian_is_not_a_target_outside_goods_area",hits.is_empty() and f.enemy.cooldown==0)
	f=fixture("bow_raider",4);f.world._structure("wood_wall",Vector2i(22,20),0);hits=enemy_hits(f)
	check.call("COMBAT/intercepted_bow_raider_keeps_wall_line_of_sight_and_cooldown",hits.is_empty() and f.enemy.cooldown==0)
	var exact: bool=true
	for state in ["Payment","Grace","Resolved","Retreating"]:
		f=fixture();f.raid.state=state;hits=enemy_hits(f)
		exact=exact and hits.is_empty() and f.enemy.cooldown==0
	check.call("COMBAT/interception_cannot_break_ceasefire_or_restart_retreat",exact)
	f=fixture();f.enemy.cooldown=f.world.tick+1;hits=enemy_hits(f)
	check.call("COMBAT/intercepted_hostile_waits_for_existing_cooldown",hits.is_empty() and f.enemy.cooldown==f.world.tick+1)
	f=fixture();f.enemy.state="Downed";f.enemy.health=1;hits=enemy_hits(f)
	check.call("COMBAT/downed_neutral_never_counterattacks",hits.is_empty() and f.enemy.cooldown==0)
	f=fixture();var other: Dictionary=f.world.citizens[2];other.x=20;other.y=21;other.edge_x=20;other.edge_y=21;other.drafted=true
	hits=enemy_hits(f)
	check.call("COMBAT/intercepted_enemy_keeps_nearest_then_id_target_order",hits.size()==1 and hits[0].target==f.person.id)
	f=fixture();f.person.x=20;f.person.y=5;f.person.edge_x=20;f.person.edge_y=5
	ColonyDefense.advance(f.world)
	check.call("COMBAT/self_defense_does_not_route_after_an_out_of_range_guard",f.enemy.goal==[f.stack.x,f.stack.y] and not f.enemy.route.is_empty() and f.enemy.route[-1]==Vector2i(f.stack.x,f.stack.y) and f.world.invariant_errors().is_empty(),str(f.world.invariant_errors()))
