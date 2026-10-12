class_name CycleChoiceButton
extends Button
## Small, explicit choices without a platform popup. All choices remain 48 dp.
signal item_selected(index: int)
var items: Array[String] = []
var selected: int = 0

func _init() -> void:
	custom_minimum_size = Vector2(48,48)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_text = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	pressed.connect(func()->void:
		if not items.is_empty(): select((selected+1)%items.size()))

func add_item(value: String) -> void:
	items.append(value)
	_update_text()

func select(index: int) -> void:
	if index < 0 or index >= items.size(): return
	selected = index
	_update_text()
	item_selected.emit(index)

func _update_text() -> void:
	if items.is_empty(): return
	text = items[selected]+"  >"
	tooltip_text = "Tap to change: "+", ".join(items)
