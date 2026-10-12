class_name TradeTests
extends RefCounted

static func merchant(world: ColonyWorld, community: String = "orchard_kin") -> Dictionary:
	var result: Dictionary = ColonyTrade.schedule(world,community)
	var wagon: Dictionary = ColonyTrade.cart(world)
	result.state="Trading";result.x=wagon.x;result.y=wagon.y;result.deadline=world.tick+7200
	return result

static func accept(world: ColonyWorld, visitor: Dictionary, buy: Dictionary, pay: Dictionary, pen: int = 0, delivery: bool = false) -> int:
	var id: int = world.queue_command("trade",{"target":visitor.id,"buy":buy,"pay":pay,"pen":pen,"delivery":delivery});world.step();return id

static func finish(world: ColonyWorld, exchange: Dictionary) -> void:
	for index in range(1500):
		world.step()
		if exchange.state=="Complete": break

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var visitor: Dictionary = merchant(world)
	var quote: Dictionary = ColonyTrade.preview(world,visitor,{"meal":5},{"wood":20},0)
	check.call("TRADE/per_unit_ceiling_price_and_no_credit",quote.error.is_empty() and quote.cost==20 and quote.offered==20 and quote.gift==0)
	world.trade_state.reputation.orchard_kin=40
	check.call("TRADE/friendly_price_uses_1100_and_rounds_each_unit",ColonyTrade.preview(world,visitor,{"herb":2},{"wood":6},0).cost==6)
	world.trade_state.reputation.orchard_kin=70
	check.call("TRADE/trusted_price_is_base",ColonyTrade.preview(world,visitor,{"meal":5},{"wood":20},0).cost==15 and ColonyTrade.preview(world,visitor,{"meal":5},{"wood":20},0).gift==5)
	world.trade_state.reputation.orchard_kin=20
	var command: int = accept(world,visitor,{"meal":5},{"wood":19})
	check.call("TRADE/short_offer_changes_nothing",world.receipts[command].contains("short") and world.trade_state.exchanges.is_empty() and world.total("wood")==44 and visitor.stock.meal==30)
	command=accept(world,visitor,{"meal":5},{"wood":20})
	var exchange: Dictionary = world.trade_state.exchanges[0]
	check.call("TRADE/accept_atomically_reserves_real_payment",world.receipts[command]=="accepted" and world.stacks.filter(func(s:Dictionary)->bool:return s.reservations.has(exchange.job)).reduce(func(n:int,s:Dictionary)->int:return n+s.reservations[exchange.job],0)==20 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	check.call("TRADE/no_goods_release_before_payment",world.total("meal")==24 and visitor.stock.meal==30 and exchange.state=="Packing")
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/reserved_trade_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	finish(world,exchange)
	check.call("TRADE/physical_delivery_commits_once",exchange.state=="Complete" and world.total("meal")==29 and visitor.stock.meal==25 and world.ledger.traded_in.meal==5 and world.ledger.traded_out.wood==20 and world.trade_state.reputation.orchard_kin==20 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	command=world.queue_command("trade_cancel",{"target":exchange.id});world.step()
	check.call("TRADE/committed_exchange_is_final",world.receipts[command].contains("committed") and exchange.state=="Complete" and world.ledger.traded_in.meal==5)
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/immutable_trade_receipt_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world=ColonyTests.world();visitor=merchant(world);accept(world,visitor,{"meal":5},{"wood":20});exchange=world.trade_state.exchanges[0]
	world.queue_command("trade_cancel",{"target":exchange.id});world.step()
	check.call("TRADE/cancel_before_commit_returns_all_reservations",exchange.state=="Canceled" and world.total("wood")==44 and world.total("meal")==24 and world.stacks.all(func(s:Dictionary)->bool:return not s.reservations.has(exchange.job)) and world.invariant_errors().is_empty())
	world=ColonyTests.world();visitor=merchant(world);accept(world,visitor,{"meal":5},{"wood":20});exchange=world.trade_state.exchanges[0]
	for index in range(300):
		world.step()
		if world.stacks.any(func(s:Dictionary)->bool:return s.location=="carry" and s.job==exchange.job): break
	var interrupted: Dictionary = world.find(world.jobs,exchange.job)
	world._release(interrupted,false)
	check.call("TRADE/self_care_interrupt_preserves_payment_reservations",world.stacks.filter(func(s:Dictionary)->bool:return s.reservations.has(exchange.job)).reduce(func(n:int,s:Dictionary)->int:return n+s.reservations[exchange.job],0)+world._escrow_count(exchange.job,"wood")==20 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	finish(world,exchange)
	check.call("TRADE/interrupted_physical_payment_can_resume_once",exchange.state=="Complete" and world.ledger.traded_out.wood==20 and world.ledger.traded_in.meal==5)
	world=ColonyTests.world();visitor=merchant(world)
	world._make_stack("wood",200,"store",ColonyTrade.cart(world).id,Vector2i(66,63),true)
	accept(world,visitor,{"meal":30},{"wood":120})
	command=accept(world,visitor,{"meal":1},{"wood":4})
	check.call("TRADE/reserved_merchant_stock_cannot_be_oversold",world.receipts[command].contains("only 0") and world.trade_state.exchanges.size()==1 and visitor.stock.meal==30)
	world=ColonyTests.world();visitor=merchant(world);accept(world,visitor,{"meal":5},{"wood":20});exchange=world.trade_state.exchanges[0]
	visitor.deadline=world.tick;ColonyTrade.advance(world)
	check.call("TRADE/departing_merchant_cancels_unpaid_purchase",visitor.state=="Leaving" and exchange.state=="Canceled" and world.total("wood")==44 and world.total("meal")==24)
	world=ColonyTests.world();visitor=merchant(world)
	world._make_stack("travel_ration",4,"store",ColonyTrade.cart(world).id,Vector2i(66,63),true)
	accept(world,visitor,{}, {"travel_ration":12},0,true);exchange=world.trade_state.exchanges[0];finish(world,exchange)
	check.call("TRADE/community_delivery_earns_ten_without_goods",exchange.state=="Complete" and world.trade_state.reputation.orchard_kin==30 and world.ledger.traded_out.travel_ration==12 and world.trade_state.delivery_after.orchard_kin==world.tick+57600)
	world._make_stack("travel_ration",12,"store",ColonyTrade.cart(world).id,Vector2i(66,63),true)
	check.call("TRADE/delivery_eight_day_cooldown_is_visible",ColonyTrade.preview(world,visitor,{}, {"travel_ration":12},0,true).error.contains("cooling"))
	world=ColonyTests.world();visitor=merchant(world)
	world._make_stack("travel_ration",4,"store",ColonyTrade.cart(world).id,Vector2i(66,63),true)
	accept(world,visitor,{}, {"travel_ration":12},0,true);exchange=world.trade_state.exchanges[0]
	visitor.deadline=world.tick;ColonyTrade.advance(world)
	check.call("TRADE/accepted_delivery_has_no_hidden_deadline",exchange.state=="Packing" and visitor.state=="Leaving")
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/waiting_delivery_after_merchant_departure",decoded.has("world"),str(decoded.get("error","")))
	world=DomesticTests.setup();visitor=merchant(world);var pen: Dictionary = world.domestic_state.pens[0]
	accept(world,visitor,{"hen":2},{"wood":30},pen.id);exchange=world.trade_state.exchanges[0];finish(world,exchange)
	check.call("TRADE/purchased_hens_arrive_at_cart_then_need_handlers",exchange.state=="Complete" and visitor.stock.hen==0 and world.domestic_state.animals.size()==2 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="lead_animal") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();visitor=merchant(world)
	check.call("TRADE/animal_purchase_requires_husbandry",ColonyTrade.preview(world,visitor,{"hen":1},{"wood":15},0).error.contains("Husbandry"))
	world=DomesticTests.setup();visitor=merchant(world);pen=world.domestic_state.pens[0]
	for index in range(5): ColonyDomestic.acquire(world,"hen",pen.id,pen.tiles[0])
	check.call("TRADE/all_animals_require_capacity_atomically",ColonyTrade.preview(world,visitor,{"hen":2},{"wood":30},pen.id).error.contains("all purchased"))
	world=ColonyTests.world();world.tick=24000;ColonyTrade.advance(world)
	check.call("TRADE/day_four_announcement_before_day_five_visit",world.trade_state.announced and world.trade_state.merchants.is_empty() and world.facts[-1].kind=="merchant_notice")
	world.tick=31200;ColonyWeather.initialize(world);ColonyTrade.advance(world);visitor=world.trade_state.merchants[0]
	check.call("TRADE/visitor_enters_from_reachable_boundary",visitor.state=="Entering" and visitor.deadline==0 and (visitor.entry.x in [0,127] or visitor.entry.y in [0,127]))
	for index in range(2500):
		world.tick+=1;world.path_requests=0;ColonyTrade.advance(world)
		if visitor.state=="Trading": break
	check.call("TRADE/stay_timer_starts_on_physical_arrival",visitor.state=="Trading" and visitor.deadline==world.tick+7200 and Vector2i(visitor.x,visitor.y)==Vector2i(66,63))
	world.tick=60000;ColonyWeather.initialize(world);ColonyTrade.advance(world)
	check.call("TRADE/later_visits_queue_without_deleting_inventory",world.trade_state.merchants.size()==2 and world.trade_state.merchants[1].state=="Waiting" and world.trade_state.merchants[1].community=="riverward" and visitor.stock.meal==30)
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/queued_merchants_and_motion_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
