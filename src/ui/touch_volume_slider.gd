class_name TouchVolumeSlider
extends HSlider
## Touch commits a tap on release or locks a horizontal drag. Vertical swipes
## belong to the sheet and cannot change volume on the initial press.
var pointer: int = -1
var start: Vector2 = Vector2.ZERO
var horizontal: bool = false
var initial_value: float = 0.0
var swallow_mouse_release: bool = false

func _init() -> void:
	scrollable=false

func _point_visible(point: Vector2) -> bool:
	if not get_global_rect().has_point(point): return false
	var ancestor: Node = get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer and not ancestor.get_global_rect().has_point(point): return false
		ancestor=ancestor.get_parent()
	return true

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not editable: return
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==-1 and (pointer>=0 or swallow_mouse_release or _point_visible(event.position)):
		if event is InputEventMouseButton and not event.pressed: swallow_mouse_release=false
		get_viewport().set_input_as_handled();return
	if event is InputEventScreenTouch:
		if event.pressed:
			if pointer<0: swallow_mouse_release=false
			if pointer>=0 and event.index!=pointer: _cancel_touch();return
			if pointer<0 and _point_visible(event.position):
				pointer=event.index;start=event.position;initial_value=value;horizontal=false;swallow_mouse_release=false
				_forward_scroll(event);get_viewport().set_input_as_handled()
		elif event.index==pointer:
			grab_focus()
			if not horizontal: drag_started.emit()
			_set_from_point(event.position)
			drag_ended.emit(not is_equal_approx(initial_value,value))
			pointer=-1;horizontal=false;swallow_mouse_release=true
			_forward_scroll(event);get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==pointer:
		var delta: Vector2 = (event.position-start)/get_global_transform().get_scale()
		if not horizontal and delta.length()>8:
			if absf(delta.y)>=absf(delta.x): _cancel_touch();_forward_scroll(event);get_viewport().set_input_as_handled();return
			horizontal=true;grab_focus();drag_started.emit()
		if horizontal:
			_set_from_point(event.position)
			get_viewport().set_input_as_handled()

func _forward_scroll(event: InputEvent) -> void:
	var ancestor: Node = get_parent()
	while ancestor!=null:
		if ancestor is TouchScrollContainer: ancestor._input(event);return
		ancestor=ancestor.get_parent()

func _set_from_point(point: Vector2) -> void:
	var local: Vector2 = get_global_transform().affine_inverse()*point
	var half: float = get_theme_icon("grabber").get_width()*0.5
	var ratio: float = clampf((local.x-half)/maxf(1.0,size.x-2*half),0.0,1.0)
	if is_layout_rtl(): ratio=1.0-ratio
	value=lerpf(min_value,max_value,ratio)

func _cancel_touch() -> void:
	if pointer<0: return
	if horizontal: drag_ended.emit(not is_equal_approx(initial_value,value))
	pointer=-1;horizontal=false;swallow_mouse_release=true

func _notification(what: int) -> void:
	if what in [Control.NOTIFICATION_SCROLL_BEGIN,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_RESIZED,NOTIFICATION_VISIBILITY_CHANGED]: _cancel_touch()
