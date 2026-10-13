class_name ColonyTrade
extends RefCounted
const COMMUNITIES: Array = ["orchard_kin","riverward","road_fellowship"]
const ANIMALS: Dictionary = {"hen":12,"pack_goat":30}

static func initial_state(seed: int, version: int, site: String) -> Dictionary:
	return {"rng":ParkMiller.derive(seed,version,site,"merchants"),"next_visit":31200,"visit_index":0,"announced":false,"reputation":{"orchard_kin":20,"riverward":20,"road_fellowship":20},"delivery_after":{"orchard_kin":0,"riverward":0,"road_fellowship":0},"merchants":[],"exchanges":[]}

static func cart(world: ColonyWorld) -> Dictionary:
	return world.structures.filter(func(s:Dictionary)->bool:return s.definition=="supply_cart")[0]

static func fact(world: ColonyWorld, kind: String, text: String, job: int = 0) -> void:
	world.facts.append({"tick":world.tick,"actor":0,"job":job,"kind":kind,"text":text})

static func schedule(world: ColonyWorld, community: String) -> Dictionary:
	var merchant: Dictionary = {"id":world._id(),"community":community,"state":"Waiting","stock":world.definitions.communities[community].stock.duplicate(),"x":0,"y":0,"entry":Vector2i.ZERO,"route":[],"goal":[],"progress":0,"move_rem":0,"deadline":0,"note":"Waiting for a safe boundary route"}
	world.trade_state.merchants.append(merchant)
	return merchant

static func move(world: ColonyWorld, actor: Dictionary, goal: Vector2i) -> bool:
	if actor.progress==0 and Vector2i(actor.x,actor.y)==goal: return true
	if actor.progress==0:
		if actor.goal!=[goal.x,goal.y] or actor.route.is_empty():
			if world.path_requests>=4: return false
			world.path_requests+=1
			actor.route=ColonyNavigation.path(Vector2i(actor.x,actor.y),goal,func(p:Vector2i)->bool:return world.walkable(p) and ColonyDanger.safe(world,p),world.can_step)
			actor.goal=[goal.x,goal.y]
		if actor.route.is_empty(): actor.note="Route blocked: clear a safe walking path";return false
		if not world.walkable(actor.route[0]) or not ColonyDanger.safe(world,actor.route[0]): actor.route.clear();actor.goal.clear();return false
	actor.move_rem+=1200000/world.tile_move_cost(actor.route[0])
	actor.progress+=actor.move_rem/120;actor.move_rem%=120
	if actor.progress>=10000:
		actor.progress=0;var point: Vector2i = actor.route.pop_front();actor.x=point.x;actor.y=point.y
	return actor.progress==0 and Vector2i(actor.x,actor.y)==goal

static func advance(world: ColonyWorld) -> void:
	var state: Dictionary = world.trade_state
	if not state.announced and world.tick>=state.next_visit-7200:
		state.announced=true
		fact(world,"merchant_notice",COMMUNITIES[state.visit_index%3].capitalize()+" merchant expected tomorrow at 08:00, with guaranteed stock. A blocked route delays the visit without deleting it.")
	if world.tick>=state.next_visit:
		schedule(world,COMMUNITIES[state.visit_index%3]);state.visit_index+=1;state.next_visit+=28800;state.announced=false
	var active: bool = false
	for merchant in state.merchants:
		if merchant.state=="Gone": continue
		if merchant.state=="Waiting":
			if active: continue
			var entries: Array[Vector2i] = ColonyPopulation.boundary(world)
			if entries.is_empty() or not ColonyDanger.safe(world,Vector2i(cart(world).x,cart(world).y)):
				merchant.note="Route blocked or dangerous: waiting at the boundary; stay timer has not started";continue
			var rng: ParkMiller = ParkMiller.new(state.rng);var entry: Vector2i = entries[rng.next()%entries.size()];state.rng=rng.state
			merchant.entry=entry;merchant.x=entry.x;merchant.y=entry.y;merchant.state="Entering";merchant.note="Walking to the cart"
		active=true
		if merchant.state=="Entering":
			if move(world,merchant,Vector2i(cart(world).x,cart(world).y)):
				merchant.state="Trading";merchant.deadline=world.tick+7200;merchant.note="Trades release goods only after payment reaches the cart"
				fact(world,"merchant_arrived",merchant.community.capitalize()+" merchant reached the cart and stays for 24 game hours.")
		elif merchant.state=="Trading":
			move(world,merchant,Vector2i(cart(world).x,cart(world).y))
			if world.tick>=merchant.deadline:
				for exchange in state.exchanges:
					if exchange.merchant==merchant.id and not exchange.delivery and exchange.state=="Packing": cancel(world,exchange)
				merchant.state="Leaving";merchant.route.clear();merchant.goal.clear();merchant.note="Returning to the road"
		elif merchant.state=="Leaving" and move(world,merchant,merchant.entry): merchant.state="Gone"

static func active_merchant(world: ColonyWorld, community: String = "") -> Dictionary:
	for merchant in world.trade_state.merchants:
		if merchant.state=="Trading" and (community.is_empty() or merchant.community==community): return merchant
	return {}

static func available(world: ColonyWorld, merchant: Dictionary, item: String) -> int:
	var count: int = merchant.stock.get(item,0)
	for exchange in world.trade_state.exchanges:
		if exchange.merchant==merchant.id and exchange.state=="Packing": count-=exchange.buy.get(item,0)
	return count

static func accessible_goods(world: ColonyWorld) -> Dictionary:
	var result: Dictionary = {}
	for stack in world.stacks:
		if stack.location in ["ground","store","output"] and world.accessible(Vector2i(stack.x,stack.y)):
			result[stack.item]=result.get(stack.item,0)+stack.count-world._reserved(stack)
	return result

static func quantities(value: Variant, allowed: Array) -> bool:
	return value is Dictionary and value.size()<=32 and value.keys().all(func(item:Variant)->bool:return item is String and allowed.has(item) and value[item] is int and value[item]>0 and value[item]<=100000)

static func preview(world: ColonyWorld, merchant: Dictionary, buy: Dictionary, pay: Dictionary, pen: int, delivery: bool = false) -> Dictionary:
	if merchant.is_empty() or merchant.state!="Trading": return {"error":"No merchant is at the cart"}
	if not quantities(buy,merchant.stock.keys()) or not quantities(pay,world.definitions.items.keys()) or pay.is_empty() or (buy.is_empty() and not delivery): return {"error":"Choose exact goods to buy and offer"}
	if delivery and (not buy.is_empty() or pay!=world.definitions.communities[merchant.community].delivery): return {"error":"Delivery requires exactly the listed community request"}
	if delivery and (world.tick<world.trade_state.delivery_after[merchant.community] or world.trade_state.exchanges.any(func(e:Dictionary)->bool:return e.delivery and e.community==merchant.community and e.state=="Packing")): return {"error":"This delivery is cooling down or already accepted"}
	var goods: Dictionary = accessible_goods(world)
	for item in pay:
		if goods.get(item,0)<pay[item]: return {"error":"Missing %d accessible unreserved %s" % [pay[item]-goods.get(item,0),item]}
	var reputation: int = world.trade_state.reputation[merchant.community]
	var multiplier: int = 1000 if reputation>=70 else (1100 if reputation>=40 else 1200)
	var cost: int = 0;var offered: int = 0;var animal_count: int = 0
	for item in buy:
		if buy[item]>available(world,merchant,item): return {"error":"Merchant has only %d unreserved %s" % [available(world,merchant,item),item]}
		var base: int = ANIMALS.get(item,world.definitions.items.get(item,{}).get("barter_value",0))
		cost+=((base*multiplier+999)/1000)*buy[item]
		if ANIMALS.has(item): animal_count+=buy[item]
	for item in pay: offered+=world.definitions.items[item].barter_value*pay[item]
	if offered<cost: return {"error":"Offer is %d barter value short; price %d, offer %d" % [cost-offered,cost,offered],"cost":cost,"offered":offered}
	if animal_count>0:
		var error: String = ColonyDomestic.acquire_error(world,buy.keys().filter(func(i:String)->bool:return ANIMALS.has(i))[0],pen)
		if not error.is_empty(): return {"error":error}
		var reserved: int = 0;var reserved_pen: int = 0
		for exchange in world.trade_state.exchanges:
			if exchange.state!="Packing": continue
			for item in ANIMALS:
				reserved+=exchange.buy.get(item,0)
				if exchange.pen==pen: reserved_pen+=exchange.buy.get(item,0)
		var info: Dictionary = ColonyDomestic.status(world,world.find(world.domestic_state.pens,pen))
		if animal_count+reserved_pen+info.count>info.capacity or animal_count+reserved+world.domestic_state.animals.filter(func(a:Dictionary)->bool:return a.health>0).size()>12: return {"error":"Reserve enough pen tiles and barn slots for all purchased animals; domestic cap twelve"}
	return {"error":"","cost":cost,"offered":offered,"gift":offered-cost,"multiplier":multiplier}

static func reservation_plan(world: ColonyWorld, inputs: Dictionary, point: Vector2i) -> Dictionary:
	var requests: Array = []
	for item in inputs:
		var needed: int = inputs[item]
		var sources: Array = world.stacks.filter(func(s:Dictionary)->bool:return s.item==item and s.count>world._reserved(s) and s.location in ["ground","store","output"] and world.accessible(Vector2i(s.x,s.y)))
		sources.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return ColonyProduction.input_before(world,a,b,point))
		for stack in sources:
			var count: int = mini(needed,stack.count-world._reserved(stack));requests.append({"stack":stack.id,"count":count});needed-=count
			if needed==0: break
		if needed>0: return {"error":"Missing "+item}
	return {"error":"","requests":requests}

static func reserve_payment(world: ColonyWorld, job: Dictionary) -> bool:
	var plan: Dictionary = reservation_plan(world,job.inputs,Vector2i(job.x,job.y))
	if not plan.error.is_empty(): return false
	for request in plan.requests: world.find(world.stacks,request.stack).reservations[job.id]=request.count
	return true

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	if kind=="trade_cancel":
		var exchange: Dictionary = world.find(world.trade_state.exchanges,args.target)
		if exchange.is_empty() or exchange.state!="Packing": return "Payment already committed or exchange ended"
		cancel(world,exchange);return "accepted"
	var merchant: Dictionary = world.find(world.trade_state.merchants,args.target)
	var check: Dictionary = preview(world,merchant,args.buy,args.pay,args.pen,args.delivery)
	if not check.error.is_empty(): return check.error
	var exchange: Dictionary = {"id":world._id(),"merchant":merchant.id,"community":merchant.community,"state":"Packing","buy":args.buy.duplicate(),"pay":args.pay.duplicate(),"pen":args.pen,"delivery":args.delivery,"gift":check.gift,"job":0,"receipt":0}
	var wagon: Dictionary = cart(world)
	var job: Dictionary = world._job("trade","Hauling","",exchange.id,Vector2i(wagon.x,wagon.y),0)
	job.inputs=exchange.pay.duplicate();exchange.job=job.id
	if not reserve_payment(world,job): world._release(job,true);return "Payment changed: refresh preview"
	world.trade_state.exchanges.append(exchange)
	fact(world,"trade_accepted","Payment reserved for "+merchant.community.capitalize()+". Goods wait for physical delivery; surplus gift value %d gives no reputation." % check.gift,job.id)
	return "accepted"

static func cancel(world: ColonyWorld, exchange: Dictionary) -> void:
	world._release(world.find(world.jobs,exchange.job),true);exchange.state="Canceled"

static func ready(world: ColonyWorld, job: Dictionary) -> bool:
	var exchange: Dictionary = world.find(world.trade_state.exchanges,job.target)
	if exchange.is_empty() or exchange.state!="Packing": return false
	var merchant: Dictionary = active_merchant(world,exchange.community) if exchange.delivery else world.find(world.trade_state.merchants,exchange.merchant)
	if merchant.is_empty() or merchant.state!="Trading": return world._block(job,"Merchant not at cart: the accepted delivery waits for their next visit")
	for item in exchange.buy:
		if merchant.stock.get(item,0)<exchange.buy[item]: return world._block(job,"Merchant stock changed")
	var animal_count: int = 0
	for item in ANIMALS:
		animal_count+=exchange.buy.get(item,0)
		if exchange.buy.get(item,0)>0:
			var error: String = ColonyDomestic.acquire_error(world,item,exchange.pen)
			if not error.is_empty(): return world._block(job,error)
	if animal_count>0:
		var info: Dictionary = ColonyDomestic.status(world,world.find(world.domestic_state.pens,exchange.pen))
		if info.count+animal_count>info.capacity or world.domestic_state.animals.filter(func(a:Dictionary)->bool:return a.health>0).size()+animal_count>12: return world._block(job,"Animal shelter capacity changed before payment")
	var wagon: Dictionary = cart(world);job.x=wagon.x;job.y=wagon.y
	if Vector2i(merchant.x,merchant.y)!=Vector2i(wagon.x,wagon.y): return world._block(job,"Merchant is walking to the moved cart")
	for stack in world.stacks:
		if stack.location=="escrow" and stack.owner==job.id and Vector2i(stack.x,stack.y)!=Vector2i(wagon.x,wagon.y):
			stack.location="ground";stack.owner=0;stack.job=0
	if job.worker>0 and Vector2i(job.work_x,job.work_y)!=Vector2i(wagon.x,wagon.y): return world._block(job,"Cart moved: payment must be carried to its new location")
	return true

static func complete(world: ColonyWorld, job: Dictionary) -> void:
	var exchange: Dictionary = world.find(world.trade_state.exchanges,job.target)
	var merchant: Dictionary = active_merchant(world,exchange.community) if exchange.delivery else world.find(world.trade_state.merchants,exchange.merchant)
	var wagon: Dictionary = cart(world);var point: Vector2i = Vector2i(wagon.x,wagon.y)
	for item in exchange.buy:
		merchant.stock[item]-=exchange.buy[item]
		if ANIMALS.has(item):
			for index in range(exchange.buy[item]): ColonyDomestic.acquire(world,item,exchange.pen,point)
		else:
			world._make_stack(item,exchange.buy[item],"ground",0,point,false);world._record("traded_in",item,exchange.buy[item])
	if exchange.delivery:
		world.trade_state.reputation[exchange.community]=mini(100,world.trade_state.reputation[exchange.community]+10)
		world.trade_state.delivery_after[exchange.community]=world.tick+57600
	exchange.state="Complete";exchange.receipt=world.tick
	fact(world,"trade_receipt",exchange.community.capitalize()+" received the listed payment at the cart. "+("Delivery earned +10 reputation; next delivery in eight days." if exchange.delivery else "Purchased goods are released here. Surplus gift %d; trade changes no reputation." % exchange.gift),job.id)

static func validate(data: Variant, definitions: Dictionary, tick: int) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,["rng","next_visit","visit_index","announced","reputation","delivery_after","merchants","exchanges"]) or not data.rng is int or data.rng<=0 or data.rng>=2147483647 or not data.next_visit is int or data.next_visit<31200 or not data.visit_index is int or data.visit_index<0 or data.next_visit!=31200+data.visit_index*28800 or not data.announced is bool or not data.merchants is Array or not data.exchanges is Array: return false
	for field in ["reputation","delivery_after"]:
		if not data[field] is Dictionary or not ColonyCodec._keys(data[field],COMMUNITIES): return false
		for value in data[field].values():
			if not value is int or (field=="reputation" and (value< -50 or value>100)) or (field=="delivery_after" and value<0): return false
	for merchant in data.merchants:
		if not merchant is Dictionary or not ColonyCodec._keys(merchant,["id","community","state","stock","x","y","entry","route","goal","progress","move_rem","deadline","note"]) or not merchant.id is int or merchant.id<=0 or merchant.community not in COMMUNITIES or merchant.state not in ["Waiting","Entering","Trading","Leaving","Gone"] or not ColonyCodec._position(merchant) or not merchant.entry is Vector2i or not merchant.route is Array or not merchant.route.all(func(p:Variant)->bool:return p is Vector2i) or not merchant.goal is Array or merchant.goal.size() not in [0,2] or not merchant.goal.all(func(n:Variant)->bool:return n is int and n>=0 and n<128) or not merchant.progress is int or merchant.progress<0 or merchant.progress>=10000 or not merchant.move_rem is int or merchant.move_rem<0 or merchant.move_rem>=120 or not merchant.deadline is int or merchant.deadline<0 or not merchant.note is String or not merchant.stock is Dictionary or not ColonyCodec._keys(merchant.stock,definitions.communities[merchant.community].stock.keys()): return false
		for item in merchant.stock:
			if not merchant.stock[item] is int or merchant.stock[item]<0 or merchant.stock[item]>definitions.communities[merchant.community].stock[item]: return false
	if data.merchants.filter(func(m:Dictionary)->bool:return m.state in ["Entering","Trading","Leaving"]).size()>1: return false
	for exchange in data.exchanges:
		if not exchange is Dictionary or not ColonyCodec._keys(exchange,["id","merchant","community","state","buy","pay","pen","delivery","gift","job","receipt"]) or not exchange.id is int or exchange.id<=0 or not exchange.merchant is int or not data.merchants.any(func(m:Dictionary)->bool:return m.id==exchange.merchant and m.community==exchange.community) or exchange.state not in ["Packing","Complete","Canceled"] or not quantities(exchange.buy,definitions.communities[exchange.community].stock.keys()) or not quantities(exchange.pay,definitions.items.keys()) or exchange.pay.is_empty() or not exchange.pen is int or exchange.pen<0 or not exchange.delivery is bool or not exchange.gift is int or exchange.gift<0 or not exchange.job is int or exchange.job<=0 or not exchange.receipt is int or exchange.receipt<0 or exchange.receipt>tick or (exchange.state=="Complete")!=(exchange.receipt>0): return false
		if exchange.delivery and (not exchange.buy.is_empty() or exchange.pay!=definitions.communities[exchange.community].delivery): return false
	return true
