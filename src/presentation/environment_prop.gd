class_name EnvironmentProp
extends Sprite2D
## One view per interactive building. Floor/path tiles are batched separately.
const FONT: Font = preload("res://assets/exported/fonts/kenney_mini.ttf")
var record: Dictionary = {}
var world: ColonyWorld
var renderer: Node
var roof: Sprite2D
var flame: Sprite2D
var decorations: Node2D
var output_pile: Sprite2D
var semantic: String = ""

func _init() -> void:
	texture=EnvironmentArt.ATLAS;region_enabled=true
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func sync(state: ColonyWorld, structure: Dictionary, tint: Color, reveal_roof: bool, obstruction: bool, burning: bool, fire_frame: int, cart_motion: Vector2 = Vector2.ZERO, output_item: String = "", output_tier: int = 0) -> void:
	world=state;record=structure
	var definition: Dictionary = world.definitions.buildings[structure.definition]
	var footprint_size: Vector2 = Vector2(definition.width,definition.height) if structure.rotation%2==0 else Vector2(definition.height,definition.width)
	var anchor: Vector2 = Vector2(structure.x+footprint_size.x*0.5,structure.y+footprint_size.y)+cart_motion
	position=anchor*16.0
	var next: String = "building/%s/%d" % [structure.definition,structure.rotation]
	if structure.health<=0: next="resource/stone_node/0"
	if next!=semantic:
		semantic=next;region_rect=EnvironmentArt.rectangle(semantic);offset=Vector2(0,-region_rect.size.y*0.5)
	self_modulate=tint*Color(1,1,1,0.4 if obstruction else 1.0)
	if structure.definition=="barn" and structure.health>0:
		if roof==null: roof=_sprite()
		roof.visible=true;roof.region_rect=EnvironmentArt.rectangle("roof/barn/%d" % structure.rotation);roof.offset=Vector2(0,-roof.region_rect.size.y*0.5)
		roof.self_modulate=tint*Color(1,1,1,0.2 if reveal_roof else 1.0)
	elif roof!=null: roof.hide()
	if burning and structure.health>0:
		if flame==null: flame=_sprite()
		flame.visible=true;flame.region_rect=EnvironmentArt.rectangle("effect/flame/%d" % fire_frame);flame.offset=Vector2(0,-12);flame.position=Vector2(0,-8)
	elif flame!=null: flame.hide()
	if not output_item.is_empty() and structure.health>0:
		if output_pile==null: output_pile=_sprite();move_child(output_pile,0)
		output_pile.visible=true;output_pile.region_rect=EnvironmentArt.rectangle("item/%s/%d" % [output_item,output_tier])
		output_pile.offset=Vector2(0,-12);output_pile.position=Vector2(region_rect.size.x*0.5-8,-10);output_pile.scale=Vector2.ONE*0.75
		output_pile.self_modulate=tint*Color(1,1,1,0.4 if obstruction else 1.0)
	elif output_pile!=null: output_pile.hide()
	if structure.definition=="supply_cart" and structure.health>0:
		if decorations==null:
			decorations=Node2D.new();add_child(decorations);decorations.draw.connect(_draw_decorations)
		decorations.show();decorations.queue_redraw()
	elif decorations!=null: decorations.hide()

func _sprite() -> Sprite2D:
	var result: Sprite2D = Sprite2D.new();result.texture=EnvironmentArt.ATLAS;result.region_enabled=true
	result.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(result);return result

func _draw_decorations() -> void:
	var started: int = Time.get_ticks_usec()
	var rewards: Array = world.charter_state.appearances
	if rewards.has("provision"):
		decorations.draw_rect(Rect2(-18,-34,36,34),Color("716D88"),false,1)
		for point in [Vector2(-16,-30),Vector2(16,-30),Vector2(-16,-3),Vector2(16,-3)]: decorations.draw_circle(point,2,Color("E9BA67"))
	if rewards.has("shelter"):
		decorations.draw_line(Vector2(-12,-26),Vector2(-12,-49),Color("263C3B"),1)
		decorations.draw_rect(Rect2(-12,-49,36,10),Color("F3E8CC"))
		var title: String = ColonyChronicle.display_name(world,0)
		if title.length()>16: title=title.left(13)+"..."
		decorations.draw_string(FONT,Vector2(-10,-41),title,HORIZONTAL_ALIGNMENT_LEFT,32,7,Color("263C3B"))
	if rewards.has("connection"):
		decorations.draw_rect(Rect2(-7,-20,14,8),Color("F3E8CC"))
		decorations.draw_line(Vector2(-5,-14),Vector2(5,-18),Color("5F98AC"),1)
		for point in [Vector2(-5,-14),Vector2(5,-18)]: decorations.draw_circle(point,1,Color("375749"))
	if rewards.has("refuge"):
		decorations.draw_rect(Rect2(9,-8,9,8),Color("77915A"))
		decorations.draw_colored_polygon(PackedVector2Array([Vector2(10,-4),Vector2(13,-7),Vector2(16,-4)]),Color("F3E8CC"))
		decorations.draw_rect(Rect2(12,-4,3,3),Color("F3E8CC"))
	if renderer!=null: renderer.account_draw(Time.get_ticks_usec()-started)
