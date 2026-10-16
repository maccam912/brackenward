class_name ResidentNeeds
extends VBoxContainer
## Exact, static needs display for a paused resident details card.

func _init(person: Dictionary) -> void:
	name="ResidentNeeds"
	add_theme_constant_override("separation",6)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var track: StyleBoxFlat=StyleBoxFlat.new()
	track.bg_color=Color("1E302F");track.set_corner_radius_all(2)
	var fill: StyleBoxFlat=StyleBoxFlat.new()
	fill.bg_color=Color("A6B878");fill.set_corner_radius_all(2)
	for entry in [["fullness","ui.needs.food",1000],["rest","ui.needs.rest",1000],["health","ui.needs.health",100],["morale","ui.needs.morale",1000]]:
		var row: VBoxContainer=VBoxContainer.new();row.add_theme_constant_override("separation",2)
		row.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(row)
		var caption: Label=Label.new()
		caption.text=ColonyText.text(entry[1],{"value":person[entry[0]],"maximum":entry[2]})
		caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(caption)
		var meter: ProgressBar=ProgressBar.new()
		meter.name=entry[0];meter.max_value=entry[2];meter.value=person[entry[0]]
		meter.show_percentage=false;meter.custom_minimum_size.y=6
		meter.mouse_filter=Control.MOUSE_FILTER_IGNORE
		meter.add_theme_stylebox_override("background",track);meter.add_theme_stylebox_override("fill",fill)
		row.add_child(meter)
