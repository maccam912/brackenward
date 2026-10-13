class_name ColonyDefense
extends RefCounted
const FOOD: Array = ["meal","travel_ration","grain","vegetable","berry"]
const GOODS: Array = ["iron","medicine","forged_toolkit","cloth","wood"]

static func initial_state(seed: int, version: int, site: String) -> Dictionary:
	return {"rng":ParkMiller.derive(seed,version,site,"raids"),"raids":[],"enemies":[],"alert_serial":0,"shelter":false,"open_passage":false}

static func citizen_defaults() -> Dictionary:
	return {"drafted":false,"rally":Vector2i(66,63),"focus":0,"stand_fast":false}

static func active(world: ColonyWorld) -> Dictionary:
	for raid in world.defense_state.raids:
		if raid.state!="Resolved": return raid
	return {}

static func enemy_active(enemy: Dictionary) -> bool:
	return enemy.state=="Active" and enemy.health>10

static func passable(world: ColonyWorld, point: Vector2i) -> bool:
	return world.walkable(point) and (world.defense_state.open_passage or not world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition in ["door","reinforced_gate"] and world.footprint(s).has(point)))

static func boundary(world: ColonyWorld) -> Array[Vector2i]:
	var wagon: Dictionary = ColonyTrade.cart(world);var start: Vector2i = Vector2i(wagon.x,wagon.y)
	var queue: Array[Vector2i] = [start];var distance: Dictionary = {start:0};var cursor: int = 0;var result: Array[Vector2i] = []
	while cursor<queue.size():
		var point: Vector2i = queue[cursor];cursor+=1
		if (point.x in [0,127] or point.y in [0,127]) and distance[point]>=30 and not world.roofed(point) and not world.domestic_state.pens.any(func(p:Dictionary)->bool:return p.tiles.has(point)): result.append(point)
		for delta in ColonyNavigation.NEIGHBORS:
			var next: Vector2i = point+delta
			if not distance.has(next) and passable(world,next) and world.can_step(point,next): distance[next]=distance[point]+1;queue.append(next)
	result.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return a.y*128+a.x<b.y*128+b.x)
	return result

static func party(budget: int) -> Array:
	var result: Array = []
	if budget<3:
		for index in range(budget): result.append("hungry_thief")
	else:
		result.append("road_raider");budget-=3
		if budget>=3: result.append("bow_raider");budget-=3
		while budget>0 and result.size()<6: result.append("hungry_thief");budget-=1
	return result

static func announce(world: ColonyWorld, budget: int) -> Dictionary:
	var kinds: Array = party(budget);var entries: Array = boundary(world)
	var rng: ParkMiller = ParkMiller.new(world.defense_state.rng)
	var entry: Vector2i = entries[rng.next()%entries.size()] if not entries.is_empty() else Vector2i.ZERO;world.defense_state.rng=rng.state
	var wagon: Dictionary = ColonyTrade.cart(world)
	var meeting: Vector2i = Vector2i(wagon.x,wagon.y)
	var route: Array = ColonyNavigation.path(entry,meeting,world.walkable,world.can_step)
	if route.size()>10: meeting=route[route.size()-10]
	var raid: Dictionary = {"id":world._id(),"state":"Announced","budget":budget,"party":kinds,"entry":entry,"meeting":meeting,"route_blocked":entries.is_empty(),"due":world.tick+7200,"arrival":0,"actors":[],"pay_job":0,"payment_deadline":0,"grace_until":0,"loot_units":0,"reason":"Announced one day ahead; exact party and supply price are fixed","acknowledged":false}
	world.defense_state.raids.append(raid)
	ColonyTrade.fact(world,"raid_warning","Road party announced for twenty-four hours from now: "+str(kinds)+". Supplies cost %d barter value; each member seeks four units, and the raid lasts at most six hours after arrival." % (budget*8))
	return raid

static func enemy_template() -> Dictionary:
	return {"id":0,"raid":0,"definition":"hungry_thief","x":0,"y":0,"health":40,"state":"Active","route":[],"goal":[],"progress":0,"move_rem":0,"cooldown":0,"attacking":0,"last_attacker":0,"target_stack":0,"target_wall":0,"loot":[],"recovery_at":0,"treated":false}

static func arrive(world: ColonyWorld, raid: Dictionary) -> void:
	if ColonyOpportunities.visitor_count(world)+raid.party.size()>8:
		raid.due=world.tick+7200;raid.reason="Visitor capacity: road party waits twenty-four hours for a safe boundary arrival";return
	if not world.director_state.major.is_empty() and world.director_state.major.target==raid.id and not ColonyDirector.start_allowed(world,world.tick):
		raid.due=world.tick+7200;raid.reason="Extreme-weather or recovery spacing reserved: party waits twenty-four hours";return
	var entries: Array = boundary(world)
	if raid.route_blocked and not entries.is_empty():
		var rng: ParkMiller = ParkMiller.new(world.defense_state.rng);raid.entry=entries[rng.next()%entries.size()];world.defense_state.rng=rng.state;raid.route_blocked=false
	if not entries.has(raid.entry):
		raid.due=world.tick+7200;raid.route_blocked=true;raid.reason="Route blocked: arrival postponed twenty-four hours; announced party unchanged"
		ColonyTrade.fact(world,"raid_route_blocked",raid.reason);return
	raid.arrival=world.tick
	for kind in raid.party:
		var enemy: Dictionary = enemy_template();enemy.id=world._id();enemy.raid=raid.id;enemy.definition=kind;enemy.health=world.definitions.enemies[kind].health;enemy.x=raid.entry.x;enemy.y=raid.entry.y
		world.defense_state.enemies.append(enemy);raid.actors.append(enemy.id)
	if raid.state=="Announced": raid.state="Active"
	raid.reason="Party arrived through the announced boundary. Defend, shelter, open passage, offer supplies, or stand down."
	world.defense_state.alert_serial+=1;world.danger_cache_tick=-1
	ColonyTrade.fact(world,"raid_arrived",raid.reason)

static func retarget(enemy: Dictionary) -> void:
	# Finish an already-started edge before routing toward a changed objective.
	if enemy.progress>0 and not enemy.route.is_empty(): enemy.route.resize(1)
	else: enemy.route.clear();enemy.progress=0
	enemy.goal.clear()

static func move(world: ColonyWorld, enemy: Dictionary, goal: Vector2i) -> bool:
	if enemy.progress==0 and Vector2i(enemy.x,enemy.y)==goal: return true
	if enemy.progress==0:
		if enemy.goal!=[goal.x,goal.y] or enemy.route.is_empty():
			if world.path_requests>=4: return false
			world.path_requests+=1
			enemy.route=ColonyNavigation.path(Vector2i(enemy.x,enemy.y),goal,func(p:Vector2i)->bool:return passable(world,p),world.can_step);enemy.goal=[goal.x,goal.y]
		if enemy.route.is_empty(): return false
		if not passable(world,enemy.route[0]): enemy.route.clear();enemy.goal.clear();return false
	enemy.move_rem+=12000000/(world.tile_move_cost(enemy.route[0])*12)
	enemy.progress+=enemy.move_rem/120;enemy.move_rem%=120
	if enemy.progress>=10000:
		enemy.progress=0;var p: Vector2i = enemy.route.pop_front();enemy.x=p.x;enemy.y=p.y
	return enemy.progress==0 and Vector2i(enemy.x,enemy.y)==goal

static func stock_rank(world: ColonyWorld, enemy: Dictionary, stack: Dictionary) -> int:
	var preference: Array = FOOD if world.definitions.enemies[enemy.definition].objective=="food" else GOODS
	var index: int = preference.find(stack.item)
	if index>=0: return index
	if preference==FOOD and (world.definitions.items[stack.item].fullness>0 or not world.definitions.items[stack.item].tags.is_empty()): return 100
	return 100 if preference==GOODS and world.definitions.items[stack.item].barter_value>0 else -1

static func choose_goods(world: ColonyWorld, enemy: Dictionary) -> Dictionary:

	var candidates: Array = []
	var start: Vector2i = Vector2i(enemy.x,enemy.y)
	var queue: Array[Vector2i] = [start];var distance: Dictionary = {start:0};var cursor: int = 0
	while cursor<queue.size():
		var point: Vector2i = queue[cursor];cursor+=1
		for delta in ColonyNavigation.NEIGHBORS:
			var next: Vector2i = point+delta
			if not distance.has(next) and passable(world,next) and world.can_step(point,next): distance[next]=distance[point]+1;queue.append(next)
	for stack in world.stacks:
		if stack.count<=0 or stack.location not in ["ground","store","output"] or not ColonyFire.usable(world,stack): continue
		var rank: int = stock_rank(world,enemy,stack);var point: Vector2i = Vector2i(stack.x,stack.y)
		if rank>=0 and distance.has(point): candidates.append({"stack":stack,"rank":rank,"distance":distance[point]})
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.rank<b.rank if a.rank!=b.rank else (a.distance<b.distance if a.distance!=b.distance else a.stack.id<b.stack.id))
	return {} if candidates.is_empty() else candidates[0].stack

static func steal(world: ColonyWorld, enemy: Dictionary, stack: Dictionary) -> void:
	var carried: int = 0
	for load in enemy.loot: carried+=load.count
	var count: int = mini(4-carried,stack.count)
	if count<=0: return
	enemy.loot.append({"item":stack.item,"count":count,"age":stack.age,"age_rem":stack.age_rem,"tags":stack.tags.duplicate()})
	stack.count-=count;stack.reservations.clear();world._record("looted",stack.item,count)
	var raid: Dictionary = world.find(world.defense_state.raids,enemy.raid);raid.loot_units+=count
	ColonyTrade.fact(world,"raid_theft","The road party took %d %s from actual stock; worn equipment and expedition cargo remain unavailable." % [count,stack.item])
	if carried+count==4: enemy.state="Retreating";retarget(enemy)

static func drop_loot(world: ColonyWorld, enemy: Dictionary) -> void:
	for load in enemy.loot:
		var stack: Dictionary = world._make_stack(load.item,load.count,"ground",0,Vector2i(enemy.x,enemy.y),false)
		stack.age=load.age;stack.age_rem=load.age_rem;stack.tags=load.tags.duplicate();world._record("recovered",load.item,load.count)
	enemy.loot.clear()

static func hurt(world: ColonyWorld, enemy: Dictionary, damage: int, attacker: int) -> void:
	if enemy.state in ["Downed","Leaving","Gone"]: return
	enemy.health=maxi(1,enemy.health-damage);enemy.last_attacker=attacker
	if enemy.health<=10:
		enemy.state="Downed";enemy.recovery_at=world.tick+3600;enemy.progress=0;enemy.route.clear();enemy.goal.clear();drop_loot(world,enemy)
		ColonyTrade.fact(world,"enemy_downed","A road attacker is downed, stable and neutral. They cannot be attacked again, recover to twenty-five after twelve hours, and may receive voluntary care for three Road reputation once.")
	elif enemy.health*10<=world.definitions.enemies[enemy.definition].health*3:
		enemy.state="Retreating";retarget(enemy)
	world.danger_cache_tick=-1

static func retreat(world: ColonyWorld, raid: Dictionary, reason: String) -> void:
	raid.state="Retreating";raid.reason=reason;raid.acknowledged=true
	for id in raid.actors:
		var enemy: Dictionary = world.find(world.defense_state.enemies,id)
		if enemy.state=="Active": enemy.state="Retreating";retarget(enemy)
	world.danger_cache_tick=-1
	ColonyTrade.fact(world,"raid_retreat",reason)

static func advance(world: ColonyWorld) -> void:
	var raid: Dictionary = active(world)
	if not raid.is_empty():
		if raid.arrival==0 and world.tick>=raid.due: arrive(world,raid)
		if raid.state=="Payment" and (world.tick>=raid.payment_deadline or world.find(world.jobs,raid.pay_job).get("state")=="Canceled"):
			var job: Dictionary = world.find(world.jobs,raid.pay_job);world._release(job,true)
			raid.state="Grace";raid.grace_until=world.tick+300;raid.reason="Supplies did not arrive: one further hour before hostility can resume; an elapsed six-hour raid limit instead sends the party home";world.defense_state.alert_serial+=1
		if raid.state=="Grace" and world.tick>=raid.grace_until: raid.state="Active" if raid.arrival>0 else "Announced"
		if raid.state=="Active":
			var stopped: int = raid.actors.filter(func(id:int)->bool:return world.find(world.defense_state.enemies,id).state in ["Downed","Retreating","Leaving","Gone"]).size()
			if stopped*2>=raid.party.size() or raid.loot_units>=raid.party.size()*4 or world.tick>=raid.arrival+1800: retreat(world,raid,"Road party retreats: half stopped, theft quota met, or the six-hour limit reached")
	for enemy in world.defense_state.enemies:
		if enemy.state=="Gone": continue
		var parent: Dictionary = world.find(world.defense_state.raids,enemy.raid)
		if enemy.state=="Downed":
			if world.tick>=enemy.recovery_at: enemy.health=maxi(25,enemy.health);enemy.state="Leaving"
			else: continue
		if enemy.state in ["Retreating","Leaving"]:
			if move(world,enemy,parent.entry): enemy.state="Gone"
			continue
		if parent.state in ["Payment","Grace"]: continue
		if parent.state!="Active": continue
		var stack: Dictionary = world.find(world.stacks,enemy.target_stack)
		if stack.is_empty() or stack.count==0 or not ColonyFire.usable(world,stack) or world.tick%60==0:
			stack=choose_goods(world,enemy);enemy.target_stack=stack.get("id",0)
		if not stack.is_empty():
			enemy.target_wall=0
			if move(world,enemy,Vector2i(stack.x,stack.y)): steal(world,enemy,stack)
		else:
			var barriers: Array = world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition in ["wood_wall","stone_wall","palisade","door","reinforced_gate"])
			barriers.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
				var aa: int = absi(a.x-enemy.x)+absi(a.y-enemy.y);var bb: int = absi(b.x-enemy.x)+absi(b.y-enemy.y)
				return aa<bb if aa!=bb else a.id<b.id)
			enemy.target_wall=barriers[0].id if not barriers.is_empty() else 0
			if enemy.target_wall>0:
				var wall: Dictionary = world.find(world.structures,enemy.target_wall)
				var positions: Array = world._perimeter(world.footprint(wall)).filter(func(p:Vector2i)->bool:return passable(world,p))
				positions.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return absi(a.x-enemy.x)+absi(a.y-enemy.y)<absi(b.x-enemy.x)+absi(b.y-enemy.y))
				if not positions.is_empty(): move(world,enemy,positions[0])
	if not raid.is_empty() and raid.state=="Retreating" and not raid.actors.any(func(id:int)->bool:return world.find(world.defense_state.enemies,id).state in ["Active","Retreating"]):
		raid.state="Resolved";raid.acknowledged=true;world.defense_state.shelter=false
		for person in world.citizens:
			person.stand_fast=false
			if person.defense_incident==raid.id:
				ColonyCombat.award_guard_xp(world,person,10);person.defense_incident=0
		ColonyTrade.fact(world,"raid_resolved","The active raid ended. Downed neutral visitors remain stable and leave after recovery.")
	world.danger_cache_tick=-1

static func assign(world: ColonyWorld, person: Dictionary) -> bool:
	if not person.drafted: return false
	if person.health<=40 and not person.stand_fast:
		person.drafted=false;ColonyDanger.escape(world,person);return false
	var job: Dictionary = world._job("defend","","",person.id,person.rally,0);job.worker=person.id;job.state="Moving";person.job=job.id
	return true

static func defend_work(world: ColonyWorld, person: Dictionary, job: Dictionary) -> void:
	if not person.drafted or person.downed: world._release(job,true);return
	if person.health<=40 and not person.stand_fast: person.drafted=false;world._release(job,true);ColonyDanger.escape(world,person);return
	var raid: Dictionary = active(world)
	if not raid.is_empty() and raid.arrival>0 and raid.state=="Active": person.defense_incident=raid.id
	person.activity="Defending the rally" if absi(person.x-person.rally.x)+absi(person.y-person.rally.y)<=2 else "Moving to defend"
	if absi(person.x-person.rally.x)+absi(person.y-person.rally.y)>2: world._walk(person,person.rally)
	else: job.state="Working"

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	if kind in ["draft","undraft"]:
		if not args.citizens is Array or args.citizens.is_empty() or args.citizens.size()>20 or not ColonyRegion.distinct(args.citizens): return "Select a squad"
		var people: Array = []
		for id in args.citizens:
			var person: Dictionary = world.find(world.citizens,id)
			if person.is_empty() or person.away or person.death_recorded or person.departed or person.downed: return "Select mobile home residents"
			people.append(person)
		if kind=="draft" and (not ColonyWorld.inside(args.rally) or not world.walkable(args.rally)): return "Choose a passable rally tile"
		for person in people:
			world._release(world.find(world.jobs,person.job),false);person.drafted=kind=="draft"
			if person.drafted: person.rally=args.rally;person.stand_fast=args.stand_fast;person.focus=0
		return "accepted"
	if kind=="focus":
		var enemy: Dictionary = world.find(world.defense_state.enemies,args.target)
		if enemy.is_empty() or enemy.state in ["Downed","Leaving","Gone"]: return "Choose an active or retreating hostile"
		for id in args.citizens:
			var person: Dictionary = world.find(world.citizens,id)
			if not person.is_empty() and person.drafted: person.focus=enemy.id
		return "accepted"
	if kind=="shelter":
		world.defense_state.shelter=args.enabled
		for person in ColonyRegion.home(world):
			if not person.drafted: world._release(world.find(world.jobs,person.job),false)
		return "accepted"
	if kind=="open_passage": world.defense_state.open_passage=args.enabled;return "accepted"
	if kind=="stand_down":
		world.defense_state.shelter=false
		for person in world.citizens:
			person.drafted=false;person.stand_fast=false
			if world.find(world.jobs,person.job).get("kind")=="defend": world._release(world.find(world.jobs,person.job),true)
		return "accepted"
	if kind=="raid_ack":
		var raid: Dictionary = active(world)
		if not raid.is_empty(): raid.acknowledged=true
		return "accepted"
	if kind=="raid_offer": return offer(world,args)
	if kind=="enemy_treat": return treat(world,args)
	return "Unknown defense command"

static func offer(world: ColonyWorld, args: Dictionary) -> String:
	var raid: Dictionary = world.find(world.defense_state.raids,args.target)
	if raid.is_empty() or raid.state in ["Retreating","Resolved","Payment"]: return "Raid is already returning, ended, or awaiting payment"
	if not ColonyTrade.quantities(args.pay,world.definitions.items.keys()) or args.pay.is_empty(): return "Choose exact supplies"
	var value: int = 0
	for item in args.pay: value+=world.definitions.items[item].barter_value*args.pay[item]
	if value<raid.budget*8: return "Supplies need %d more barter value" % (raid.budget*8-value)
	var job: Dictionary = world._job("raid_pay","Hauling","",raid.id,raid.meeting,0);job.inputs=args.pay.duplicate();job.priority=3
	if not ColonyTrade.reserve_payment(world,job): world._release(job,true);return "Supplies not accessible or reserved"
	raid.state="Payment";raid.pay_job=job.id;raid.payment_deadline=world.tick+1800;raid.reason="Workers are delivering supplies at the marked meeting tile; no attacks for six hours";raid.acknowledged=true;world.danger_cache_tick=-1
	return "accepted"

static func pay_complete(world: ColonyWorld, job: Dictionary) -> void:
	var raid: Dictionary = world.find(world.defense_state.raids,job.target)
	retreat(world,raid,"The quoted supplies arrived physically. The raid leaves peacefully without increasing future budgets.")

static func treat(world: ColonyWorld, args: Dictionary) -> String:
	var enemy: Dictionary = world.find(world.defense_state.enemies,args.target)
	if enemy.is_empty() or enemy.state!="Downed": return "Choose a neutral downed visitor"
	if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="enemy_treat" and j.target==enemy.id and j.state not in ["Complete","Canceled"]): return "Treatment already assigned"
	var item: String = "medicine" if world.available("medicine")>0 else ("herb" if world.available("herb")>0 else "")
	var job: Dictionary = world._job("enemy_treat","Care","Care",enemy.id,Vector2i(enemy.x,enemy.y),10000 if item=="medicine" else (16000 if item=="herb" else 24000))
	job.definition=item;job.inputs={} if item.is_empty() else {item:1}
	return "accepted"

static func treatment_complete(world: ColonyWorld, job: Dictionary) -> void:
	var enemy: Dictionary = world.find(world.defense_state.enemies,job.target)
	enemy.health=mini(world.definitions.enemies[enemy.definition].health,enemy.health+(20 if job.definition=="medicine" else (10 if job.definition=="herb" else 0)))
	if not enemy.treated: enemy.treated=true;world.trade_state.reputation.road_fellowship=mini(100,world.trade_state.reputation.road_fellowship+3)
	if enemy.health>=25: enemy.state="Leaving"
	ColonyTrade.fact(world,"enemy_treated","A neutral downed road visitor received voluntary treatment; Road reputation gained three once for this person in this incident.",job.id)

static func attacks(world: ColonyWorld) -> Array:
	var result: Array = []
	for person in ColonyCombat.ordered_actors(world.citizens):
		if not person.drafted or person.away or person.downed or person.death_recorded or person.departed or (person.health<=40 and not person.stand_fast) or world.tick<person.attack_ready: continue
		var targets: Array = world.defense_state.enemies.filter(func(e:Dictionary)->bool:
			var distance: int = ColonyWildlife.distance(person,e);var weapon: Dictionary = ColonyCombat.weapon(person,distance,world.weather)
			var raid: Dictionary = world.find(world.defense_state.raids,e.raid)
			return raid.get("state","") not in ["Payment","Grace","Resolved"] and e.state in ["Active","Retreating"] and e.health>10 and distance<=weapon.range and ColonyCombat.line_of_sight(world,Vector2i(person.x,person.y),Vector2i(e.x,e.y)))
		targets.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			if (a.id==person.focus)!=(b.id==person.focus): return a.id==person.focus
			if (a.attacking==person.id)!=(b.attacking==person.id): return a.attacking==person.id
			var aa: int = ColonyWildlife.distance(person,a);var bb: int = ColonyWildlife.distance(person,b)
			return aa<bb if aa!=bb else a.id<b.id)
		if targets.is_empty(): continue
		var enemy: Dictionary = targets[0];var weapon: Dictionary = ColonyCombat.weapon(person,ColonyWildlife.distance(person,enemy),world.weather)
		person.attack_ready=world.tick+weapon.cooldown
		result.append({"kind":"enemy","target":enemy.id,"source":person.id,"damage":maxi(1,weapon.damage-world.definitions.enemies[enemy.definition].armor)})
	for enemy in ColonyCombat.ordered_actors(world.defense_state.enemies):
		if not enemy_active(enemy) or world.tick<enemy.cooldown: continue
		var raid: Dictionary = world.find(world.defense_state.raids,enemy.raid)
		if raid.state!="Active": continue
		var definition: Dictionary = world.definitions.enemies[enemy.definition]
		var maximum: int = (4 if world.weather=="fog" else 6) if definition.weapon=="bow" else 1
		var objective: Dictionary = world.find(world.stacks,enemy.target_stack)
		var candidates: Array = world.citizens.filter(func(c:Dictionary)->bool:return not c.away and not c.downed and not c.death_recorded and not c.departed and (c.drafted or c.id==enemy.last_attacker) and ColonyWildlife.distance(c,enemy)<=maximum and (objective.is_empty() or ColonyWildlife.distance(c,objective)<=12) and ColonyCombat.line_of_sight(world,Vector2i(enemy.x,enemy.y),Vector2i(c.x,c.y)))
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			var aa: int = ColonyWildlife.distance(enemy,a);var bb: int = ColonyWildlife.distance(enemy,b)
			return aa<bb if aa!=bb else a.id<b.id)
		enemy.attacking=0
		if not candidates.is_empty():
			var person: Dictionary = candidates[0];var close: bool = definition.weapon=="bow" and ColonyWildlife.distance(enemy,person)<=1
			enemy.cooldown=world.tick+(25 if close else definition.cooldown);enemy.attacking=person.id
			result.append({"kind":"citizen","target":person.id,"source":enemy.id,"damage":maxi(1,(5 if close else definition.damage)-(2 if person.equipment.vest=="vest" else 0))})
		elif enemy.target_wall>0:
			var wall: Dictionary = world.find(world.structures,enemy.target_wall)
			if wall.get("health",0)>0 and world.footprint(wall).any(func(p:Vector2i)->bool:return absi(p.x-enemy.x)+absi(p.y-enemy.y)<=maximum):
				enemy.cooldown=world.tick+definition.cooldown
				result.append({"kind":"structure","target":wall.id,"source":enemy.id,"damage":definition.damage})
	return result

static func validate(data: Variant, citizens: Array, structures: Array, stacks: Array, definitions: Dictionary, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["rng","raids","enemies","alert_serial","shelter","open_passage"]) or not data.rng is int or data.rng<=0 or data.rng>=2147483647 or not data.raids is Array or not data.enemies is Array or not data.alert_serial is int or data.alert_serial<0 or not data.shelter is bool or not data.open_passage is bool: return false
	if not data.raids.all(func(r:Variant)->bool:return r is Dictionary and r.get("id") is int and r.get("state") is String) or not data.enemies.all(func(e:Variant)->bool:return e is Dictionary and e.get("id") is int and e.get("state") is String): return false
	if data.raids.filter(func(r:Dictionary)->bool:return r.state!="Resolved").size()>1 or data.enemies.filter(func(e:Dictionary)->bool:return e.state=="Active").size()>6: return false
	for raid in data.raids:
		if not raid is Dictionary or not ColonyCodec._keys(raid,["id","state","budget","party","entry","meeting","route_blocked","due","arrival","actors","pay_job","payment_deadline","grace_until","loot_units","reason","acknowledged"]) or not raid.id is int or raid.id<=0 or raid.state not in ["Announced","Active","Payment","Grace","Retreating","Resolved"] or not raid.budget is int or raid.budget<2 or raid.budget>10 or raid.party!=party(raid.budget) or not raid.entry is Vector2i or not raid.meeting is Vector2i or not raid.route_blocked is bool or not raid.reason is String or not raid.acknowledged is bool or not raid.actors is Array or not raid.actors.all(func(id:Variant)->bool:return id is int and data.enemies.any(func(e:Dictionary)->bool:return e.id==id and e.raid==raid.id)): return false
		for field in ["due","arrival","pay_job","payment_deadline","grace_until","loot_units"]:
			if not raid[field] is int or raid[field]<0: return false
		if raid.arrival>tick or raid.loot_units>raid.party.size()*4 or (raid.arrival>0 and raid.actors.size()!=raid.party.size()): return false
	for enemy in data.enemies:
		if not enemy is Dictionary or not ColonyCodec._record(enemy,enemy_template()) or not data.raids.any(func(r:Dictionary)->bool:return r.id==enemy.raid) or not definitions.enemies.has(enemy.definition) or not ColonyCodec._position(enemy) or enemy.health<1 or enemy.health>definitions.enemies[enemy.definition].health or enemy.state not in ["Active","Retreating","Downed","Leaving","Gone"] or enemy.progress<0 or enemy.progress>=10000 or enemy.move_rem<0 or enemy.move_rem>=120 or enemy.cooldown<0 or enemy.cooldown>tick+35 or enemy.recovery_at<0 or enemy.route.size()>16384 or not enemy.route.all(func(p:Variant)->bool:return p is Vector2i) or enemy.goal.size() not in [0,2] or not enemy.goal.all(func(n:Variant)->bool:return n is int and n>=0 and n<128) or not enemy.treated is bool: return false
		var units: int = 0
		for load in enemy.loot:
			if not load is Dictionary or not ColonyCodec._keys(load,["item","count","age","age_rem","tags"]) or not definitions.items.has(load.item) or not load.count is int or load.count<1 or not load.age is int or load.age<0 or not load.age_rem is int or load.age_rem<0 or load.age_rem>=4 or not load.tags is Array or not load.tags.all(func(t:Variant)->bool:return t in ColonyPopulation.FOODS): return false
			units+=load.count
		if units>4: return false
		if enemy.attacking>0 and not citizens.any(func(c:Dictionary)->bool:return c.id==enemy.attacking): return false
		if enemy.last_attacker>0 and not citizens.any(func(c:Dictionary)->bool:return c.id==enemy.last_attacker): return false
		if enemy.target_stack>0 and not stacks.any(func(s:Dictionary)->bool:return s.id==enemy.target_stack): return false
		if enemy.target_wall>0 and not structures.any(func(s:Dictionary)->bool:return s.id==enemy.target_wall): return false
	for person in citizens:
		if not person.drafted is bool or not person.rally is Vector2i or not person.focus is int or person.focus<0 or not person.stand_fast is bool: return false
		if person.focus>0 and not data.enemies.any(func(e:Dictionary)->bool:return e.id==person.focus): return false
	return true

static func shelter_assign(world: ColonyWorld, person: Dictionary) -> bool:
	if not world.defense_state.shelter or person.drafted: return false
	var wagon: Dictionary = ColonyTrade.cart(world);var goal: Vector2i = Vector2i(wagon.x,wagon.y)
	if not ColonyDanger.safe(world,goal):
		if ColonyDanger.escape(world,person): return true
		person.activity="Sheltering in the safest reachable place";return true
	if Vector2i(person.x,person.y)==goal: person.activity="Sheltering at the cart";return true
	var job: Dictionary = world._job("shelter","","",person.id,goal,0);job.worker=person.id;job.state="Moving";person.job=job.id
	return true
