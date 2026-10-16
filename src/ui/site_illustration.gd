class_name SiteIllustration
extends Control
## Decorative site vignette, deliberately independent of map generation and seed.
var site_index: int=0:
	set(value):
		site_index=clampi(value,0,2);queue_redraw()

func _init() -> void:
	custom_minimum_size=Vector2(0,144)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents=true
	resized.connect(queue_redraw)

func tile(semantic: String, point: Vector2, dimensions: Vector2=Vector2.ZERO) -> void:
	var region: Rect2=EnvironmentArt.rectangle(semantic)
	draw_texture_rect_region(EnvironmentArt.ATLAS,Rect2(point,region.size if dimensions==Vector2.ZERO else dimensions),region)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(2,2))
	var width: float=size.x/2
	var ground: String=["grass","poor","rich"][site_index]
	for y in range(5):
		for x in range(ceili(width/16)):
			tile("ground/%s/%d" % [ground,1 if (x*7+y*3)%11==0 else 0],Vector2(x*16,y*16))
	# A narrow stream in the meadow/shelf; a broad bend among rich river soil.
	var river_width: float=32 if site_index==2 else 16
	for y in range(5):
		var river_x: float=floorf(width*0.72/16)*16+([0,0,-16,-16,0][y] if site_index==2 else 0)
		for dx in range(0,int(river_width),16): tile("ground/water/0",Vector2(river_x+dx,y*16))
		draw_rect(Rect2(river_x,y*16,2,16),Color("78927C"))
		draw_rect(Rect2(river_x+river_width-2,y*16,2,16),Color("78927C"))
	var positions: Array=[Vector2(0.13,44),Vector2(0.34,40),Vector2(0.50,63),Vector2(0.90,46)]
	if site_index==1: positions.append_array([Vector2(0.23,65),Vector2(0.42,68),Vector2(0.60,42),Vector2(0.96,70)])
	positions.sort_custom(func(a:Vector2,b:Vector2)->bool:return a.y<b.y)
	for i in range(positions.size()):
		var point: Vector2=positions[i]
		var semantic: String="resource/tree/%d" % (0 if site_index==1 else i%3)
		var region: Rect2=EnvironmentArt.rectangle(semantic)
		tile(semantic,Vector2(floorf(point.x*width)-region.size.x/2,point.y-region.size.y))
	var deposit: String="clay_bank" if site_index==2 else "stone_node"
	var region: Rect2=EnvironmentArt.rectangle("resource/%s/0" % deposit)
	tile("resource/%s/0" % deposit,Vector2(width*0.59-region.size.x/2,69-region.size.y))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(Vector2.ZERO,size),Color("829858"),false,2)
