class_name TouchScrollContainer
extends ScrollContainer
## Touch scrolling remains available when a finger starts on a Button. Godot
## 4.7's built-in scroll drag relies on emulated mouse events which a Button
## accepts; genuine touchscreen events are tracked here before GUI dispatch.
var pointer: int = -1
var start: Vector2 = Vector2.ZERO
var scroll_origin: int = 0
var horizontal_origin: int = 0
var dragging: bool = false
var suppress_mouse: bool = false
var horizontal_control: bool = false
var horizontal_locked: bool = false

func _init() -> void:
	# Keep the native emulated-mouse drag from starting in parallel with the
	# genuine touch gesture. Child buttons and scrollbars still receive input.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and get_global_rect().has_point(event.position):
		var direction: int = -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
		scroll_vertical += roundi(direction * maxf(48,get_v_scroll_bar().page / 8.0) * event.factor)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventPanGesture and get_global_rect().has_point(event.position):
		scroll_vertical += roundi(get_v_scroll_bar().page * event.delta.y / 8.0)
		if horizontal_scroll_mode!=SCROLL_MODE_DISABLED: scroll_horizontal+=roundi(get_h_scroll_bar().page*event.delta.x/8.0)
		get_viewport().set_input_as_handled()
		return
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == -1 and suppress_mouse:
		if event is InputEventMouseButton and not event.pressed:
			# Scroll-begin canceled the press attempt. Deliver release so the
			# viewport also clears its mouse capture before the next tap.
			suppress_mouse = false
			return
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if pointer < 0 and get_global_rect().has_point(event.position):
				pointer = event.index
				start = event.position
				scroll_origin = scroll_vertical
				horizontal_origin = scroll_horizontal
				dragging = false
				suppress_mouse = false
				horizontal_control=find_children("*","HSlider",true,false).any(func(slider:Node)->bool:return slider.is_visible_in_tree() and slider.get_global_rect().has_point(event.position))
				horizontal_locked=false
		elif event.index == pointer:
			if dragging:
				get_viewport().set_input_as_handled()
				propagate_notification(Control.NOTIFICATION_SCROLL_END)
			pointer = -1
			dragging = false
	elif event is InputEventScreenDrag and event.index == pointer:
		var delta: Vector2 = (event.position-start)/get_global_transform().get_scale()
		if horizontal_control and not dragging:
			if horizontal_locked: return
			if delta.length()>8 and absf(delta.x)>absf(delta.y): horizontal_locked=true;return
		if not dragging and (absf(delta.y)>8 or (horizontal_scroll_mode!=SCROLL_MODE_DISABLED and absf(delta.x)>8)):
			dragging = true
			suppress_mouse = true
			propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
		if dragging:
			scroll_vertical = scroll_origin-roundi(delta.y)
			if horizontal_scroll_mode!=SCROLL_MODE_DISABLED: scroll_horizontal=horizontal_origin-roundi(delta.x)
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_RESIZED,NOTIFICATION_VISIBILITY_CHANGED]:
		if dragging: propagate_notification(Control.NOTIFICATION_SCROLL_END)
		pointer = -1
		dragging = false
		suppress_mouse = false
		horizontal_control=false;horizontal_locked=false
