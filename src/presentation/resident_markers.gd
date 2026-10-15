class_name ResidentMarkers
extends Control
## Read-only overview portraits. The map keeps handling their 48-unit hit targets.
const FACE: float=24.0
const SIZE: float=32.0
const MERGE_DISTANCE: float=28.0
const MERGE_EXTENT: float=64.0
const ZOOM_LIMIT: float=16.0

class Marker extends Control:
	var renderer: WorldView
	var face: TextureRect
	var count: Label
	var cues: Node2D
	var ids: Array[int]=[]
	var selected: bool=false
	var contrast: bool=false
	var needs_care: bool=false
	var base_style: StyleBoxFlat
	var stack_style: StyleBoxFlat
	var selected_style: StyleBoxFlat
	func _init(owner: WorldView) -> void:
		renderer=owner
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		base_style=_box(Color("F3E8CC"),Color("302D2B"),2)
		stack_style=_box(Color("F3E8CC"),Color("302D2B"),1)
		selected_style=_box(Color.TRANSPARENT,Color("E9BA67"),3)
		custom_minimum_size=Vector2.ONE*SIZE;size=custom_minimum_size
		face=CitizenArt.portrait(ColonyAppearance.defaults(1),int(FACE));add_child(face)
		face.position=Vector2.ONE*4;face.size=Vector2.ONE*FACE
		cues=Node2D.new();add_child(cues);cues.draw.connect(_draw_cues)
		count=Label.new();count.mouse_filter=Control.MOUSE_FILTER_IGNORE
		count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;count.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		count.add_theme_font_size_override("font_size",12)
		count.add_theme_color_override("font_color",Color("F3E8CC"))
		count.add_theme_color_override("font_outline_color",Color.BLACK);count.add_theme_constant_override("outline_size",3)
		count.position=Vector2(20,-6);count.size=Vector2(18,18);add_child(count)
	func apply(appearance: Dictionary, members: Array[int], chosen: bool, high_contrast: bool, care: bool) -> void:
		CitizenArt.update_portrait(face,appearance)
		var changed: bool=selected!=chosen or contrast!=high_contrast or needs_care!=care or ids.size()!=members.size()
		if ids.size()!=members.size():
			count.visible=members.size()>1;count.text=str(members.size()) if count.visible else ""
		ids.assign(members);selected=chosen;contrast=high_contrast
		needs_care=care;selected_style.border_color=Color.BLACK if contrast else Color("E9BA67")
		if changed: queue_redraw();cues.queue_redraw()
	func _draw() -> void:
		var started: int=Time.get_ticks_usec()
		if ids.size()>1:
			draw_style_box(stack_style,Rect2(Vector2(-3,3),Vector2.ONE*SIZE))
		draw_style_box(base_style,Rect2(Vector2.ZERO,Vector2.ONE*SIZE))
		if selected:
			draw_style_box(selected_style,Rect2(Vector2(-2,-2),Vector2.ONE*(SIZE+4)))
		renderer.account_draw(Time.get_ticks_usec()-started)
	func _draw_cues() -> void:
		var started: int=Time.get_ticks_usec()
		if ids.size()>1: cues.draw_circle(Vector2(29,3),10,Color("302D2B"))
		if needs_care:
			cues.draw_circle(Vector2(4,28),7,Color("A54D48"))
			cues.draw_rect(Rect2(Vector2(0,26),Vector2(8,4)),Color("F3E8CC"))
			cues.draw_rect(Rect2(Vector2(2,24),Vector2(4,8)),Color("F3E8CC"))
		renderer.account_draw(Time.get_ticks_usec()-started)
	func _box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
		var box: StyleBoxFlat=StyleBoxFlat.new();box.bg_color=fill;box.border_color=border
		box.set_border_width_all(width);box.set_corner_radius_all(6)
		return box

var view: WorldView
var markers: Array[Marker]=[]
var points: Dictionary={}
var groups: Array=[]

func _init(owner: WorldView) -> void:
	view=owner;mouse_filter=Control.MOUSE_FILTER_IGNORE

func refresh() -> void:
	visible=view.world is ColonyWorld and view.tile_size<ZOOM_LIMIT
	points.clear();groups.clear()
	if not visible:
		for marker in markers: marker.hide()
		return
	var people: Array=view.world.citizens.filter(func(p:Dictionary)->bool:return view.resident_visible(p))
	people.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.id<b.id)
	# Connected nearby portraits share a visible pin. Stable IDs fix all ties;
	# the pin's displayed center is also every member's map selection point.
	for person in people:
		var point: Vector2=view.tile_to_screen(view.citizen_point(person))
		var joined: Array=[]
		var group: Dictionary={"people":[person],"positions":[point],"bounds":Rect2(point,Vector2.ZERO)}
		for index in range(groups.size()):
			if not groups[index].positions.any(func(p:Vector2)->bool:return p.distance_to(point)<MERGE_DISTANCE): continue
			var bounds: Rect2=group.bounds.merge(groups[index].bounds)
			if maxf(bounds.size.x,bounds.size.y)>MERGE_EXTENT: continue
			joined.append(index);group.bounds=bounds
			group.people.append_array(groups[index].people);group.positions.append_array(groups[index].positions)
		for index in range(joined.size()-1,-1,-1): groups.remove_at(joined[index])
		group.people.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.id<b.id)
		groups.append(group)
	groups.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.people[0].id<b.people[0].id)
	while markers.size()<groups.size():
		var marker: Marker=Marker.new(view);add_child(marker);markers.append(marker)
	for index in range(markers.size()):
		var marker: Marker=markers[index]
		if index>=groups.size(): marker.hide();continue
		var group: Dictionary=groups[index];var center: Vector2=Vector2.ZERO
		for point in group.positions: center+=point
		center/=group.positions.size();group.center=center
		var ids: Array[int]=[];var portrait: Dictionary=group.people[0];var care: bool=false
		for person in group.people:
			ids.append(person.id);points[person.id]=center
			care=care or person.downed or person.carrying_patient>0
			if person.id==view.selected_id: portrait=person
		marker.position=center-Vector2.ONE*SIZE*0.5
		marker.visible=Rect2(Vector2.ZERO,view.size).grow(SIZE).has_point(center)
		marker.apply(portrait.appearance,ids,ids.has(view.selected_id),view.high_contrast,care)
		if marker.selected and marker.get_index()!=get_child_count()-1: move_child(marker,get_child_count()-1)
