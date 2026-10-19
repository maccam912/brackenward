class_name EnvironmentArt
extends RefCounted
const ATLAS: Texture2D = preload("res://assets/exported/environment/woodland.png")
const WHEELBARROW: Texture2D = preload("res://assets/exported/ui/wheelbarrow.svg")
const RENEWABLE_RESOURCES: Array[String]=["berry_bush","herb_patch","mushroom_patch"]
static var layout: Dictionary = {}

static func rectangles() -> Dictionary:
	if layout.is_empty(): layout=JSON.parse_string(FileAccess.get_file_as_string("res://data/environment_art.json")).rectangles
	return layout

static func texture_for(semantic: String) -> Texture2D:
	return WHEELBARROW if semantic.begins_with("item/wheelbarrow/") else ATLAS

static func rectangle(semantic: String) -> Rect2:
	if semantic.begins_with("item/wheelbarrow/"): return Rect2(0,0,16,24)
	var values: Array = rectangles()[semantic]
	return Rect2(values[0],values[1],values[2],values[3])

static func crop_stage(field: Dictionary, definition: Dictionary) -> int:
	if not field.planted: return 0
	if field.ripe_tick>0: return 4
	var fraction: float = float(field.growth)/definition.growth
	return 1 if fraction<0.15 else (2 if fraction<0.4 else 3)

static func pile_tier(count: int, limit: int) -> int:
	return clampi((count*3-1)/maxi(1,limit),0,2)

static func night_color(tick: int) -> Color:
	var hour: float = float(tick%7200)/300.0
	var daylight: float = clampf((hour-5.0)/2.0,0.0,1.0) if hour<12 else clampf((19.0-hour)/2.0,0.0,1.0)
	# A brief warm shoulder at dawn/dusk; endpoints retain readable cool nights
	# and untinted daylight. Essential cues stay outside this world modulation.
	var warmth: float=4.0*daylight*(1.0-daylight)
	return Color(minf(1.0,lerpf(0.60,1.0,daylight)+0.12*warmth),lerpf(0.68,1.0,daylight)+0.04*warmth,lerpf(0.84,1.0,daylight)-0.14*warmth)

static func day_phase(tick: int) -> String:
	var hour: int=posmod(tick,7200)/300
	if hour>=5 and hour<7: return "dawn"
	if hour>=7 and hour<17: return "day"
	if hour>=17 and hour<19: return "dusk"
	return "night"

static func tree_semantic(id: int, tick: int) -> String:
	var variant: int=posmod(id,3)
	var season: int=ColonyAgriculture.season(tick)
	if variant!=0 and season>=2:
		return "resource/tree_%s/%d" % ["autumn" if season==2 else "winter",variant]
	return "resource/tree/%d" % variant

static func resource_semantic(world: ColonyWorld, resource: Dictionary) -> String:
	var kind: String=resource.definition
	if resource.remaining<=0:
		if kind=="tree":
			var state: Dictionary=ColonyNature.tree(world,resource.id)
			if state.cleared:return ""
			kind="sapling" if state.planted else "stump"
		elif kind in RENEWABLE_RESOURCES:kind+="_depleted"
		else:return ""
	return tree_semantic(resource.id,world.tick) if kind=="tree" else "resource/%s/0" % kind

static func weather_color(weather: String) -> Color:
	# Subtle atmosphere remains visible when decorative particles are disabled.
	# Essential selections, warnings and labels render outside this world tint.
	match weather:
		"rain","flood":return Color(0.88,0.94,0.99)
		"snow","cold_snap":return Color(0.94,0.98,1.0)
		"drought":return Color(1.0,0.95,0.86)
		"fog":return Color(0.94,0.97,0.98)
	return Color.WHITE
