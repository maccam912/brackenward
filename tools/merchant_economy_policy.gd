class_name MerchantEconomyPolicy
extends ColonyPolicy
## Ordinary commands only. Import cloth instead of growing/weaving it locally.
const CLOTH_TARGET: int = 16
const PURCHASE_SIZE: int = 8
const WOOD_RESERVE: int = 40

func _init() -> void:
	super("merchant_economy")

func plan(world: ColonyWorld) -> void:
	if last_policy==world.tick:return
	super.plan(world)
	_staff_gatherer(world)
	_buy_cloth(world)
	_deliver_cloaks(world)

func _staff_gatherer(world: ColonyWorld) -> void:
	var newcomers: Array=world.citizens.filter(func(c:Dictionary)->bool:return c.id>4 and not c.death_recorded and not c.departed)
	if newcomers.is_empty():return
	var person: Dictionary=newcomers[0]
	if person.preferences.Gathering!=3:issue(world,"preference",{"citizen":person.id,"category":"Gathering","value":3})
	if person.preferred!="Gathering" and person.preferences[person.preferred]>2:issue(world,"preference",{"citizen":person.id,"category":person.preferred,"value":2})

func _gather(world: ColonyWorld, definition: String, reserve: int, tasks: int, limit: int = 64) -> void:
	super._gather(world,definition,200 if definition=="tree" else reserve,4 if definition=="tree" else tasks,limit)

func _fields(world: ColonyWorld, crop: String, desired: int, roof: bool) -> void:
	if crop!="flax":super._fields(world,crop,desired,roof)

func _orders(world: ColonyWorld, residents: int) -> void:
	for station in world.structures:
		if station.health<=0:continue
		if station.definition=="hearth" and not world.production_state.orders.any(func(o:Dictionary)->bool:return o.station==station.id):
			issue(world,"recipe_order",{"target":station.id,"definition":"cook_meals","mode":"Maintain","value":maxi(8,residents*4),"priority":2,"filters":["grain","vegetable","berry","mushroom"]})
		if station.definition=="loom" and not world.production_state.orders.any(func(o:Dictionary)->bool:return o.station==station.id and o.recipe=="sew_cloak"):
			issue(world,"recipe_order",{"target":station.id,"definition":"sew_cloak","mode":"Maintain","value":4,"priority":2,"filters":[]})

func _buy_cloth(world: ColonyWorld) -> void:
	if world.pending_commands.any(func(c:Dictionary)->bool:return c.kind=="trade"):return
	var committed: int=0
	for exchange in world.trade_state.exchanges:
		if exchange.state in ["Packing","Complete"]:committed+=exchange.buy.get("cloth",0)
	if committed>=CLOTH_TARGET:return
	var merchant: Dictionary=ColonyTrade.active_merchant(world,"riverward")
	if merchant.is_empty() or world.trade_state.exchanges.any(func(e:Dictionary)->bool:return e.merchant==merchant.id and e.state in ["Packing","Complete"]):return
	var count: int=mini(PURCHASE_SIZE,CLOTH_TARGET-committed)
	if ColonyTrade.available(world,merchant,"cloth")<count:return
	var reputation: int=world.trade_state.reputation[merchant.community]
	var multiplier: int=1000 if reputation>=70 else (1100 if reputation>=40 else 1200)
	var cost: int=((world.definitions.items.cloth.barter_value*multiplier+999)/1000)*count
	if world.available("wood")<cost+WOOD_RESERVE:return
	var quote: Dictionary=ColonyTrade.preview(world,merchant,{"cloth":count},{"wood":cost},0)
	if quote.error.is_empty():issue(world,"trade",{"target":merchant.id,"buy":{"cloth":count},"pay":{"wood":cost},"pen":0,"delivery":false})

func _deliver_cloaks(world: ColonyWorld) -> void:
	if world.pending_commands.any(func(c:Dictionary)->bool:return c.kind=="trade") or world.available("cloak")<3:return
	if world.trade_state.exchanges.any(func(e:Dictionary)->bool:return e.delivery and e.community=="road_fellowship" and e.state in ["Packing","Complete"]):return
	var merchant: Dictionary=ColonyTrade.active_merchant(world,"road_fellowship")
	if merchant.is_empty():return
	var quote: Dictionary=ColonyTrade.preview(world,merchant,{}, {"cloak":3},0,true)
	if quote.error.is_empty():issue(world,"trade",{"target":merchant.id,"buy":{},"pay":{"cloak":3},"pen":0,"delivery":true})

static func metrics(world: ColonyWorld) -> Dictionary:
	var purchases: Array=world.trade_state.exchanges.filter(func(e:Dictionary)->bool:return e.state=="Complete" and not e.delivery and e.buy.get("cloth",0)>0)
	var merchants: Array=[]
	for exchange in purchases:
		if not merchants.has(exchange.merchant):merchants.append(exchange.merchant)
	return {"completed_purchases":purchases.map(func(e:Dictionary)->Dictionary:return {"merchant":e.merchant,"community":e.community,"buy":e.buy,"pay":e.pay,"receipt":e.receipt}),"distinct_merchants":merchants.size(),"cloth_imported":world.ledger.traded_in.get("cloth",0),"cloth_produced":world.ledger.produced.get("cloth",0),"cloth_consumed":world.ledger.consumed.get("cloth",0),"completed_sewing_jobs":world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="craft" and j.definition=="sew_cloak" and j.state=="Complete").size(),"completed_cloak_deliveries":world.trade_state.exchanges.filter(func(e:Dictionary)->bool:return e.state=="Complete" and e.delivery and e.community=="road_fellowship" and e.pay=={"cloak":3} and e.buy.is_empty() and e.receipt>0).size(),"road_reputation":world.trade_state.reputation.road_fellowship,"flax_fields":world.fields.filter(func(f:Dictionary)->bool:return f.crop=="flax").size()}

static func passes(world: ColonyWorld) -> bool:
	var result: Dictionary=metrics(world)
	return result.completed_purchases.size()==2 and result.distinct_merchants==2 and result.completed_purchases.all(func(e:Dictionary)->bool:return e.community=="riverward" and e.buy=={"cloth":8} and e.pay=={"wood":40} and e.receipt>0) and result.cloth_imported==16 and result.cloth_produced==0 and result.cloth_consumed>=6 and result.completed_sewing_jobs>=3 and result.completed_cloak_deliveries==1 and result.road_reputation>=30 and result.flax_fields==0 and world.citizens.size()==8 and world.citizens.all(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed) and FoodForecast.calculate(world).ticks>=7200
