class_name AnimalArt
extends RefCounted
const ATLAS: Texture2D = preload("res://assets/exported/animals/woodland.png")
static var layout: Dictionary = {}

static func kinds() -> Dictionary:
	if layout.is_empty(): layout=JSON.parse_string(FileAccess.get_file_as_string("res://data/animal_animation.json")).kinds
	return layout

static func frame_rect(kind: String, pose: String, facing: int, frame: int) -> Rect2:
	var block: Dictionary = kinds()[kind]
	var animation: Dictionary = block.states[pose]
	var index: int = int(animation.first)+posmod(facing,4)*int(animation.frames)+posmod(frame,int(animation.frames))
	return Rect2((index%16)*24,(int(block.block_row)*4+index/16)*24,24,24)
