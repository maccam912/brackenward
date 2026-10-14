class_name CitizenArt
extends RefCounted
const ATLAS: Texture2D = preload("res://assets/exported/citizens/adults.png")
const PORTRAITS: Texture2D = preload("res://assets/exported/citizens/portraits.png")
const PALETTE: Shader = preload("res://src/presentation/citizen_palette.gdshader")
const SKINS: Array[String] = ["F0C8A0","DEAE82","C98D66","AA704D","86533C","603B30"]
const HAIR: Array[String] = ["302D2B","4C3531","75533D","A06B43","D4AC64","B96C50","B5B4A7","E9DDC2"]
const CLOTH: Array[String] = ["716D88","B96C50","375749","5F98AC","77915A","D08336","81656E","8B7651"]
const LABELS: Dictionary = {"body":"Clothing","skin":"Skin","hair":"Hair","hair_color":"Hair color","coat":"Coat color","scarf":"Scarf color"}
const BODY_NAMES: Array[String] = ["Tunic","Long coat","Short coat","Apron","Wrap","Vest","Cloak","Tabard"]
const HAIR_NAMES: Array[String] = ["Swept crop","Bob","Curls","Top knot","Long","Ponytail","Close crop","Braid"]
static var layout: Dictionary = {}

static func animations() -> Dictionary:
	if layout.is_empty(): layout=JSON.parse_string(FileAccess.get_file_as_string("res://data/citizen_animation.json")).states
	return layout

static func frame_rect(appearance: Dictionary, state: String, direction: int, frame: int) -> Rect2:
	var animation: Dictionary = animations()[state]
	var index: int = int(animation.first)+posmod(direction,int(animation.directions))*int(animation.frames)+posmod(frame,int(animation.frames))
	return Rect2((appearance.body*11+index%11)*16,(appearance.hair*9+index/11)*24,16,24)

static func material_for(appearance: Dictionary) -> ShaderMaterial:
	var result: ShaderMaterial = ShaderMaterial.new();result.shader=PALETTE
	apply_palette(result,appearance)
	return result

static func apply_palette(material: ShaderMaterial, appearance: Dictionary) -> void:
	material.set_shader_parameter("skin",Color(SKINS[appearance.skin]))
	material.set_shader_parameter("hair",Color(HAIR[appearance.hair_color]))
	material.set_shader_parameter("coat",Color(CLOTH[appearance.coat]))
	material.set_shader_parameter("scarf",Color(CLOTH[appearance.scarf]))

static func portrait(appearance: Dictionary, display_size: int = 128) -> TextureRect:
	var result: TextureRect = TextureRect.new()
	var texture: AtlasTexture = AtlasTexture.new();texture.atlas=PORTRAITS;texture.region=Rect2(appearance.body*64,appearance.hair*64,64,64)
	result.texture=texture;result.material=material_for(appearance)
	result.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	result.custom_minimum_size=Vector2(display_size,display_size)
	result.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;result.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter=Control.MOUSE_FILTER_IGNORE
	result.set_meta("appearance",appearance.duplicate())
	return result

static func update_portrait(picture: TextureRect, appearance: Dictionary) -> void:
	if picture.get_meta("appearance",{})==appearance: return
	picture.texture.region=Rect2(appearance.body*64,appearance.hair*64,64,64)
	apply_palette(picture.material,appearance)
	picture.set_meta("appearance",appearance.duplicate())

static func label_for(key: String, value: int) -> String:
	if key=="body": return BODY_NAMES[value]
	if key=="hair": return HAIR_NAMES[value]
	return "%d / %d" % [value+1,ColonyAppearance.OPTIONS[key]]
