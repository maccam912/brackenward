class_name CycleChoiceButton
extends Button
## Small, explicit choices without a platform popup. All choices remain 48 dp.
signal item_selected(index: int)
var items: Array[String] = []
var selected: int = 0:
	set(index):
		selected=index
		_update_text()

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
	item_selected.emit(index)

func _update_text() -> void:
	# A caller can set a choice before adding its items. Do not show a stale
	# first item or emit a user action while applying stored settings.
	text = items[selected]+"  >" if selected>=0 and selected<items.size() else ""
	tooltip_text = ColonyText.text("ui.choice.change_hint",{"choices":", ".join(items)}) if not items.is_empty() else ""
