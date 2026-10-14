class_name ColonyAppearance
extends RefCounted
## Cosmetic choices consume no simulation RNG, resources, time or entity IDs.
const OPTIONS: Dictionary = {"body":8,"skin":6,"hair":8,"hair_color":8,"coat":8,"scarf":8}

static func defaults(id: int) -> Dictionary:
	return {"body":posmod(id-1,8),"skin":posmod(id*5+1,6),"hair":posmod(id*3+1,8),"hair_color":posmod(id*5+2,8),"coat":posmod(id*3,8),"scarf":posmod(id*7+1,8)}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or not ColonyCodec._keys(value,OPTIONS.keys()): return false
	for key in OPTIONS:
		if not value[key] is int or value[key]<0 or value[key]>=OPTIONS[key]: return false
	return true

static func command(world: ColonyWorld, args: Dictionary) -> String:
	if not ColonyCodec._keys(args,["target","appearance"]) or not args.target is int or not valid(args.appearance): return "invalid_appearance"
	var person: Dictionary = world.find(world.citizens,args.target)
	if person.is_empty() or person.death_recorded or person.departed: return "resident_unavailable"
	person.appearance=args.appearance.duplicate(true)
	return "accepted"
