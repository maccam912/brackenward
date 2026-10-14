class_name AnimalSprite
extends Sprite2D
var kind: String = "hare"
var role: String = "wildlife"
var record: Dictionary = {}
var facing: int = 0
var pose: String = "idle"
var clock: float = 0.0
var animation_frame: int = 0
var previous_feed: int = -999
var eat_until: int = 0

func _init() -> void:
	texture=AnimalArt.ATLAS;region_enabled=true;offset=Vector2(0,-12)
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

static func route_point(record: Dictionary) -> Vector2:
	var point: Vector2 = Vector2(record.x+0.5,record.y+0.5)
	if not record.get("route",[]).is_empty(): point+=Vector2(record.route[0]-Vector2i(record.x,record.y))*float(record.progress)/10000.0
	return point

static func movement_for(world: ColonyWorld, record: Dictionary, role: String) -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	if not record.get("route",[]).is_empty() and record.progress>0: direction=Vector2(record.route[0]-Vector2i(record.x,record.y))
	if role=="domestic" and record.handler>0:
		var handler: Dictionary = world.find(world.citizens,record.handler)
		if not handler.is_empty() and handler.progress>0 and absi(handler.x-record.x)+absi(handler.y-record.y)<=2:
			direction=Vector2(handler.edge_x-handler.x,handler.edge_y-handler.y)
	return direction

static func point_for(world: ColonyWorld, record: Dictionary, role: String) -> Vector2:
	var point: Vector2 = route_point(record)
	if role=="domestic" and record.handler>0:
		var handler: Dictionary = world.find(world.citizens,record.handler)
		if not handler.is_empty(): point+=movement_for(world,record,role)*float(handler.progress)/10000.0
	if role=="pack": point+=Vector2(-0.55,0.25)
	return point

func animate(world: ColonyWorld, delta: float, speed: int, reduced_motion: bool) -> void:
	var direction: Vector2 = movement_for(world,record,role)
	position=point_for(world,record,role)*16.0
	if direction!=Vector2.ZERO: facing=1 if direction.x>0 else (3 if direction.x<0 else (0 if direction.y>0 else 2))
	var feed: int = record.get("crop_day",record.get("last_fed",-1))
	if previous_feed!=-999 and feed>=0 and feed!=previous_feed: eat_until=world.tick+10
	previous_feed=feed
	var next_pose: String = "idle"
	if role=="carcass" or record.get("health",1)<=0: next_pose="downed"
	elif direction!=Vector2.ZERO: next_pose="charge" if kind=="boar" and record.attacker>0 else "walk"
	elif world.tick<eat_until: next_pose="eat"
	if next_pose!=pose: pose=next_pose;clock=0.0
	var fps: float = 6.0 if pose in ["walk","charge"] else (4.0 if pose=="eat" else 1.0)
	clock=0.0 if reduced_motion else fmod(clock+delta*minf(fps*speed,10.0),120.0)
	animation_frame=int(clock)%int(AnimalArt.kinds()[kind].states[pose].frames)
	region_rect=AnimalArt.frame_rect(kind,pose,facing,animation_frame)
	scale=Vector2.ONE*(0.7 if role=="domestic" and record.juvenile_until>world.tick else 1.0)
