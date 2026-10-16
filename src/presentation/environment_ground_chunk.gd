class_name EnvironmentGroundChunk
extends Node2D
## Cached floor/crop/supply draw commands. No Node per crop or stack.
var commands: Array = []
var renderer: Node

func set_commands(next: Array) -> void:
	if commands==next: return
	commands=next;queue_redraw()

func _draw() -> void:
	var started: int = Time.get_ticks_usec()
	for command in commands:
		if command[0] in ["zone","stockpile","stockpile_edge","flood_edge","floodwater"]:
			draw_rect(command[1],command[2])
			if command[0]=="floodwater":
				var point: Vector2=command[1].position
				var ripple: Color=Color(0.76,0.88,0.87,0.40)
				draw_line(point+Vector2(3,5),point+Vector2(8,5),ripple,0.5)
				draw_line(point+Vector2(9,12),point+Vector2(13,12),ripple,0.5)
			if command[0]=="zone":draw_rect(command[1],Color(0.15,0.23,0.23,0.3),false,0.5)
		else:
			var rectangle: Rect2 = EnvironmentArt.rectangle(command[0])
			draw_texture_rect_region(EnvironmentArt.ATLAS,command[1],rectangle,command[2])
	if renderer!=null: renderer.account_draw(Time.get_ticks_usec()-started)
