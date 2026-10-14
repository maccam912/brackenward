class_name EnvironmentArt
extends RefCounted
const ATLAS: Texture2D = preload("res://assets/exported/environment/woodland.png")
static var layout: Dictionary = {}

static func rectangles() -> Dictionary:
	if layout.is_empty(): layout=JSON.parse_string(FileAccess.get_file_as_string("res://data/environment_art.json")).rectangles
	return layout

static func rectangle(semantic: String) -> Rect2:
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
	# A >=0.87 channel multiplier keeps linear luminance above 70% even in
	# the LDR canvas. Essential overlays use a separate untinted layer.
	return Color(lerpf(0.87,1.0,daylight),lerpf(0.90,1.0,daylight),lerpf(0.95,1.0,daylight))
