class_name CitizenSprite
extends Sprite2D
var facing: int = 0
var pose: String = "idle"
var clock: float = 0.0
var animation_frame: int = 0
var choices: Dictionary = {}
var task_kind: String = ""
var weapon: String = ""
var task_skill: String = ""
var equipment_layer: Node2D
var last_health: int = -1
var hurt_remaining: float = 0.0

func _init() -> void:
	texture=CitizenArt.ATLAS;region_enabled=true;offset=Vector2(0,-12)
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	equipment_layer=Node2D.new();add_child(equipment_layer);equipment_layer.draw.connect(_draw_equipment)

func reset_pose() -> void:
	facing=0;pose="idle";clock=0.0;animation_frame=0;last_health=-1;hurt_remaining=0.0;choices={}

static func state_for(world: ColonyWorld, person: Dictionary, cargo: bool) -> String:
	if person.downed: return "downed"
	var moving: bool = Vector2i(person.edge_x,person.edge_y)!=Vector2i(person.x,person.y) and person.progress>0
	if moving: return "carry" if cargo or person.carrying_patient>0 else "walk"
	var job: Dictionary = world.find(world.jobs,person.job)
	if world.charter_state.ceremony.get("state")=="Complete" and world.tick-world.charter_state.ceremony.end<60 and job.get("kind","") not in ["eat","sleep"]: return "cheer"
	if job.get("state")!="Working": return "idle"
	match job.kind:
		"sleep": return "sleep"
		"eat", "table_eat": return "eat"
		"leisure", "mediate", "visit": return "talk"
		"supper": return "talk" if job.amount==1 else "eat"
		"sow", "prepare", "harvest", "tend", "replant_tree": return "plant"
		"hunt", "guard", "defend": return "shoot" if person.equipment.weapon=="bow" else "melee"
	return "work"

func animate(world: ColonyWorld, person: Dictionary, delta: float, speed: int, cargo: bool, reduced_motion: bool = false) -> void:
	var appearance: Dictionary = person.appearance
	if choices!=appearance:
		choices=appearance.duplicate()
		if material==null: material=CitizenArt.material_for(appearance)
		else: CitizenArt.apply_palette(material,appearance)
	var movement: Vector2i = Vector2i(person.edge_x-person.x,person.edge_y-person.y)
	if movement!=Vector2i.ZERO:
		facing=1 if movement.x>0 else (3 if movement.x<0 else (0 if movement.y>0 else 2))
	var state: String = state_for(world,person,cargo)
	if last_health>=0 and person.health<last_health: hurt_remaining=0.35
	last_health=person.health
	if not person.downed and hurt_remaining>0:
		state="hurt";hurt_remaining=maxf(0.0,hurt_remaining-delta)
	if state!=pose: pose=state;clock=0.0
	var fps: float = 1.0 if pose in ["idle","sleep"] else (6.0 if pose in ["walk","carry"] else 4.0)
	clock=0.0 if reduced_motion else fmod(clock+delta*minf(fps*speed,10.0),120.0)
	animation_frame=int(clock)%int(CitizenArt.animations()[pose].frames)
	region_rect=CitizenArt.frame_rect(appearance,pose,facing,animation_frame)
	var job: Dictionary = world.find(world.jobs,person.job)
	task_kind=job.get("kind","");task_skill=job.get("skill","");weapon=person.equipment.weapon
	equipment_layer.queue_redraw()

func _draw_equipment() -> void:
	# Actual job and equipment determine these large, readable overlays. No
	# animation callback feeds the simulation or creates a tool/resource.
	if pose in ["sleep","downed"]: return
	var ink: Color = Color("263C3B")
	var cream: Color = Color("F3E8CC")
	if task_skill=="Cooking":
		equipment_layer.draw_rect(Rect2(-4,-22,8,3),cream);equipment_layer.draw_rect(Rect2(-5,-20,10,2),cream)
	elif task_skill=="Care":
		equipment_layer.draw_rect(Rect2(-4,-22,8,3),cream);equipment_layer.draw_line(Vector2(0,-23),Vector2(0,-19),Color("B96C50"),1)
	elif task_skill in ["Build","Craft"]:
		equipment_layer.draw_rect(Rect2(-5,-21,10,2),Color("E9BA67"));equipment_layer.draw_rect(Rect2(-3,-23,6,3),Color("E9BA67"))
	if pose in ["work","plant"]:
		var reach: float = [-1.0,-4.0,0.0][animation_frame%3]
		var hand: Vector2 = Vector2(6,-6+reach)
		equipment_layer.draw_line(hand,hand+Vector2(0,-6),ink,2)
		if task_skill in ["Gathering","Build","Craft"]:
			equipment_layer.draw_line(hand+Vector2(-2,-5),hand+Vector2(2,-5),cream,2)
		elif pose=="plant": equipment_layer.draw_rect(Rect2(hand+Vector2(-1,1),Vector2(3,3)),cream)
	elif pose=="melee" and weapon=="spear":
		var end: Vector2 = Vector2(8+animation_frame*2,-14)
		equipment_layer.draw_line(Vector2(4,-3),end,ink,2);equipment_layer.draw_line(end,end+Vector2(1,-3),cream,2)
	elif pose=="shoot" and weapon=="bow":
		equipment_layer.draw_arc(Vector2(5,-10),5,-PI*0.5,PI*0.5,6,Color("B96C50"),2)
		equipment_layer.draw_line(Vector2(5,-15),Vector2(5-animation_frame,-10),cream,1)
		equipment_layer.draw_line(Vector2(5-animation_frame,-10),Vector2(5,-5),cream,1)
