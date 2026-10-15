class_name FoodCandidatesReference
extends ColonyWorld
## Complete 25cb2c0 food-selection oracle, retaining the whole inventory read.
func _food(citizen: Dictionary, releasing: Dictionary = {}) -> Dictionary:
	var edible: Array[Dictionary] = []
	var points: Dictionary = {}
	var release_id: int = releasing.get("id",0)
	var cancel: bool = releasing.get("kind","") in PERSONAL_JOBS
	var frees_reservations: bool = release_id>0 and (cancel or releasing.kind not in RELEASE_KEEPS_RESERVATIONS)
	for stack in (_work_inventory() if in_tick else nonempty_stacks()):
		if definitions.items[stack.item].fullness<=0 or (stack.item=="travel_ration" and not use_rations): continue
		var available_count: int = stack.count-_reserved(stack)
		if frees_reservations: available_count+=stack.reservations.get(release_id,0)
		var drops_carry: bool = release_id>0 and stack.location=="carry" and stack.job==release_id
		var drops_escrow: bool = release_id>0 and cancel and stack.location=="escrow" and stack.owner==release_id
		if drops_carry and not frees_reservations: available_count=0
		if available_count>0 and (stack.location in ["ground","store","output"] or drops_carry or drops_escrow) and ColonyFire.usable(self,stack):
			edible.append(stack)
			var carrier: Dictionary = find(citizens,stack.owner) if drops_carry or drops_escrow else {}
			points[stack.id]=Vector2i(carrier.x,carrier.y) if not carrier.is_empty() else Vector2i(stack.x,stack.y)
	edible.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.age != b.age:
			return a.age > b.age
		if a.tags.has(citizen.food_tag) != b.tags.has(citizen.food_tag):
			return a.tags.has(citizen.food_tag)
		return a.item < b.item or (a.item == b.item and a.id < b.id))
	var start: Vector2i = Vector2i(citizen.x,citizen.y)
	for stack in edible:
		var point: Vector2i = points[stack.id]
		if not accessible(point) or not ColonyDanger.safe(self,point): continue
		if point == start or not ColonyNavigation.path(start,point,func(p:Vector2i)->bool:return walkable(p) and ColonyDanger.safe(self,p),can_step).is_empty(): return stack
	return {}
