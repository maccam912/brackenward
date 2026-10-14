class_name GuestSprite
extends CitizenSprite
var record: Dictionary = {}
var role: String = "visitor"
var hostile: bool = false
var health_fraction: float = 1.0

func animate_guest(world: ColonyWorld, delta: float, speed: int, reduced_motion: bool) -> void:
	position=AnimalSprite.route_point(record)*16.0
	var moving: bool = not record.route.is_empty() and record.progress>0
	if moving:
		var direction: Vector2i = record.route[0]-Vector2i(record.x,record.y)
		facing=1 if direction.x>0 else (3 if direction.x<0 else (0 if direction.y>0 else 2))
	var appearance: Dictionary = choices if not choices.is_empty() else ColonyAppearance.defaults(record.id)
	var state: String = "walk" if moving else "idle"
	hostile=false;weapon="";task_skill="";health_fraction=1.0
	if role=="enemy":
		var definition: Dictionary = world.definitions.enemies[record.definition]
		weapon=definition.weapon;hostile=ColonyDefense.enemy_active(record)
		health_fraction=float(record.health)/definition.health
		if record.state=="Downed": state="downed"
		elif hostile and not moving and record.cooldown>world.tick: state="shoot" if weapon=="bow" else "melee"
		if last_health>=0 and record.health<last_health: hurt_remaining=0.35
		last_health=record.health
		if state!="downed" and hurt_remaining>0: state="hurt";hurt_remaining=maxf(0.0,hurt_remaining-delta)
	set_visual(appearance,state,delta,speed,reduced_motion)
	equipment_layer.queue_redraw()

func _draw_equipment() -> void:
	super._draw_equipment()
	var ink: Color = Color("263C3B")
	var cream: Color = Color("F3E8CC")
	if role=="enemy":
		if pose!="downed":
			equipment_layer.draw_rect(Rect2(-5,-20,10,2),Color("716D88"))
			equipment_layer.draw_line(Vector2(4,-20),Vector2(7,-17),Color("716D88"),2)
			if pose not in ["melee","shoot"]:
				if weapon=="bow": equipment_layer.draw_arc(Vector2(6,-8),5,-PI*0.5,PI*0.5,6,Color("B96C50"),2)
				elif weapon=="spear":
					equipment_layer.draw_line(Vector2(6,-2),Vector2(7,-20),ink,1)
					equipment_layer.draw_line(Vector2(7,-20),Vector2(7,-23),cream,2)
				else: equipment_layer.draw_line(Vector2(6,-2),Vector2(8,-11),Color("B96C50"),3)
		# The marker changes shape as well as color when the person stops
		# being an active threat.
		if hostile:
			equipment_layer.draw_polyline(PackedVector2Array([Vector2(0,-29),Vector2(3,-26),Vector2(0,-23),Vector2(-3,-26),Vector2(0,-29)]),cream,1)
			equipment_layer.draw_line(Vector2(0,-28),Vector2(0,-25),ink,1)
		else:
			equipment_layer.draw_line(Vector2(-3,-25),Vector2(3,-25),cream,2)
			equipment_layer.draw_line(Vector2(0,-28),Vector2(0,-22),cream,2)
		equipment_layer.draw_rect(Rect2(-5,2,10,2),ink)
		equipment_layer.draw_rect(Rect2(-5,2,10*health_fraction,2),Color("77915A"))
	elif role=="merchant":
		equipment_layer.draw_rect(Rect2(-6,-22,12,2),Color("E9BA67"))
		equipment_layer.draw_rect(Rect2(-4,-25,8,4),Color("E9BA67"))
		equipment_layer.draw_rect(Rect2(-8,-7,4,5),Color("B96C50"))
	else:
		equipment_layer.draw_line(Vector2(-7,-16),Vector2(-7,0),Color("B96C50"),2)
		equipment_layer.draw_rect(Rect2(-8,-17,4,3),cream)
