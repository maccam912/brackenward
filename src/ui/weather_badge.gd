class_name WeatherBadge
extends Control
## Static, original weather symbols. Text remains the authoritative description.
var kind: String
var thermometer: StyleBoxFlat

func _init(weather: String) -> void:
	thermometer=_thermometer()
	kind=weather;name="WeatherBadge_"+weather
	custom_minimum_size=Vector2(48,48)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	size_flags_vertical=Control.SIZE_SHRINK_CENTER

func _draw() -> void:
	var cream: Color=Color("F3E8CC");var water: Color=Color("87B7C3")
	var sun: Color=Color("E9BA67");var shadow: Color=Color("A4ADA4")
	if kind in ["clear","drought"]:
		var center: Vector2=Vector2(24,20 if kind=="drought" else 24)
		draw_circle(center,8,sun)
		for index in range(8):
			var ray: Vector2=Vector2.from_angle(index*TAU/8)
			draw_line(center+ray*12,center+ray*16,sun,2)
		if kind=="drought":
			draw_line(Vector2(8,40),Vector2(40,40),shadow,2)
			draw_polyline(PackedVector2Array([Vector2(21,36),Vector2(26,40),Vector2(23,44)]),sun,2)
		return
	if kind=="cold_snap":
		draw_style_box(thermometer,Rect2(10,5,9,28))
		draw_circle(Vector2(14.5,35),6,cream)
		draw_line(Vector2(14.5,19),Vector2(14.5,34),water,3)
		draw_circle(Vector2(14.5,35),3,water)
		_snowflake(Vector2(33,21),8,water)
		return
	# Stepped cloud silhouette complements the game's pixel art.
	var cloud: PackedVector2Array=PackedVector2Array([Vector2(6,24),Vector2(6,16),Vector2(12,16),Vector2(12,11),Vector2(18,11),Vector2(18,7),Vector2(29,7),Vector2(29,12),Vector2(36,12),Vector2(36,17),Vector2(42,17),Vector2(42,24)])
	draw_colored_polygon(cloud,shadow)
	draw_line(Vector2(9,25),Vector2(39,25),cream,2)
	match kind:
		"rain":
			for x in [13,24,35]:draw_line(Vector2(x,30),Vector2(x-3,38),water,2)
		"snow":
			for x in [13,33]:_snowflake(Vector2(x,35),5,cream)
		"fog":
			for row in range(3):draw_line(Vector2(7+row%2*5,31+row*6),Vector2(39-row%2*4,31+row*6),shadow,2)
		"flood":
			for y in [33,41]:
				draw_polyline(PackedVector2Array([Vector2(5,y),Vector2(11,y-3),Vector2(17,y),Vector2(23,y-3),Vector2(29,y),Vector2(35,y-3),Vector2(41,y)]),water,2)

func _snowflake(center: Vector2, radius: float, color: Color) -> void:
	for index in range(3):
		var ray: Vector2=Vector2.from_angle(index*PI/3)*radius
		draw_line(center-ray,center+ray,color,2)

func _thermometer() -> StyleBoxFlat:
	var box: StyleBoxFlat=StyleBoxFlat.new()
	box.bg_color=Color("263C3B");box.border_color=Color("F3E8CC")
	box.set_border_width_all(2);box.set_corner_radius_all(4)
	return box
