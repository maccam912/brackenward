class_name FoodForecast
extends RefCounted
## Conservative continuous demand, using only accessible unreserved existing food.
static func expiry_ticks(world: ColonyWorld, stack: Dictionary) -> int:
	var shelf: int = world.definitions.items[stack.item].shelf_ticks
	if shelf == 0:
		return 2147483647
	var denominator: int = 1
	var store: Dictionary = world.find(world.structures,stack.owner) if stack.location == "store" else {}
	if not store.is_empty() and store.definition in ["granary","cellar"]:
		denominator = world.definitions.buildings[store.definition].age_denominator
	return maxi(0,((shelf-stack.age)*4-stack.age_rem+4/denominator-1)/(4/denominator))

static func calculate(world: ColonyWorld, resident_override: int = -1) -> Dictionary:
	var residents: int = world.citizens.filter(func(c: Dictionary)->bool:return not c.death_recorded and not c.departed).size()
	if resident_override>=0: residents=resident_override
	if residents == 0:
		return {"portions":0,"ticks":0,"label":"No residents at home"}
	var demand: int = residents * 1000
	var nutrition: int = 0
	var batches: Array[Dictionary] = []
	for stack in world.stacks:
		var definition: Dictionary = world.definitions.items[stack.item]
		if definition.fullness == 0 or stack.location not in ["ground","store","output"] or (stack.item == "travel_ration" and not world.use_rations) or not world.accessible(Vector2i(stack.x,stack.y)):
			continue
		var count: int = stack.count - world._reserved(stack)
		if count <= 0:
			continue
		var expiry: int = expiry_ticks(world,stack)
		nutrition += definition.fullness * count
		batches.append({"id":stack.id,"expiry":expiry*demand,"budget":definition.fullness*count*7200})
	batches.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.expiry < b.expiry or (a.expiry == b.expiry and a.id < b.id))
	var elapsed: int = 0
	for batch in batches:
		if elapsed >= batch.expiry:
			continue
		elapsed = mini(elapsed+batch.budget,batch.expiry)
	var ticks: int = elapsed / demand
	return {"portions":nutrition/500,"ticks":ticks,"label":"%d portions | %d days %02d:%02d stored runway" % [nutrition/500,ticks/7200,(ticks%7200)/300,((ticks/75)*15)%60]}
