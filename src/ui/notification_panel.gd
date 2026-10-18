class_name NotificationPanel
extends PanelContainer

var game: GameSession
var research_button: Button
var research_label: Label
var updates_button: Button
var card: VBoxContainer
var message: Label

func build(session: GameSession) -> void:
	game=session
	name="Notifications"
	add_theme_stylebox_override("panel",game._box(Color("263C3B"),Color("A3BDB2")))
	var rows: VBoxContainer=VBoxContainer.new();add_child(rows)
	var summary: HBoxContainer=HBoxContainer.new();rows.add_child(summary)
	research_button=game.button("",game.show_research,summary);research_button.name="ResearchStatus"
	var margin: MarginContainer=MarginContainer.new();research_button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left=12;margin.offset_right=-12;margin.offset_top=4;margin.offset_bottom=-4
	margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	research_label=game.label("",margin);research_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	research_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	updates_button=game.button("",game.show_updates,summary);updates_button.name="ShowUpdates"
	updates_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var box: StyleBoxFlat=updates_button.get_theme_stylebox(state).duplicate()
		box.content_margin_left=32;updates_button.add_theme_stylebox_override(state,box)
	updates_button.draw.connect(func()->void:
		var center: Vector2=Vector2(18,updates_button.size.y*0.5)
		var ink: Color=Color("F8F3E7")
		updates_button.draw_arc(center,9,0,TAU,24,ink,2,true)
		updates_button.draw_circle(center+Vector2(0,-4),1.3,ink)
		updates_button.draw_line(center+Vector2(0,-1),center+Vector2(0,5),ink,2,true))
	card=VBoxContainer.new();rows.add_child(card)
	message=game.label("",card)
	var actions: HBoxContainer=HBoxContainer.new();card.add_child(actions)
	var view_button: Button=game.button(ColonyText.text("ui.action.research"),func()->void:
		game.notifications.dismiss();game._refresh_notifications();game.show_research(),actions)
	view_button.tooltip_text=ColonyText.text("ui.updates.view_research")
	game.button(ColonyText.text("ui.updates.dismiss"),func()->void:
		game.notifications.dismiss();game._refresh_notifications(),actions)
	resized.connect(func()->void:game._layout.call_deferred())

func refresh() -> void:
	var benches: Array[Dictionary]=[]
	if game.world is ColonyWorld: benches=ColonyNotifications.benches(game.world)
	research_button.visible=not benches.is_empty()
	if research_button.visible:
		var working: int=benches.filter(func(bench:Dictionary)->bool:return bench.state=="working").size()
		var heading: String=ColonyText.text("ui.research.status.idle")
		var representative: Dictionary=benches[0]
		for bench in benches:
			if bench.state in ["waiting","choose","finished"]: representative=bench;break
		var detail: String=game._research_bench_text(representative)
		if working>0:
			heading=ColonyText.text("ui.research.status.working",{"working":working,"total":benches.size()})
			detail=game._catalog_name(game.world.production_state.project) if not game.world.production_state.project.is_empty() else ColonyText.text("ui.research.status.shared")
		elif benches.any(func(bench:Dictionary)->bool:return bench.state=="traveling"):
			detail=ColonyText.text("ui.research.status.traveling")
		research_label.text=ColonyFonts.display(heading+"\n"+detail)
		research_button.tooltip_text=research_label.text
		research_button.custom_minimum_size.y=ceilf(64*game.text_scale)
	var unread: Array[Dictionary]=game.notifications.pending()
	updates_button.visible=not unread.is_empty()
	updates_button.text=str(unread.size())
	updates_button.tooltip_text=ColonyText.text("ui.updates.count",{"count":unread.size()})
	updates_button.custom_minimum_size.x=72
	message.text=ColonyFonts.display(game._research_completion_text(unread[0].project)) if not unread.is_empty() else ""
	card.visible=not unread.is_empty()

func place(top: float) -> void:
	visible=game.sheet==null and game.inspector==null and not game.placement.visible and (research_button.visible or updates_button.visible) and not game.awaiting_first_colony
	if not visible: return
	var width: float=minf(420,game.content.size.x-16)
	var compact: bool=game.content.size.y<500
	research_button.custom_minimum_size.y=48 if compact else ceilf(64*game.text_scale)
	research_label.max_lines_visible=1 if compact else 2
	research_label.text=research_button.tooltip_text.get_slice("\n",0) if compact else research_button.tooltip_text
	# Short landscape screens retain the compact count; the full list scrolls.
	card.visible=not game.notifications.pending().is_empty() and game.speeds.position.y-top>260*game.text_scale
	position=Vector2(game.content.size.x-width-8,top+8)
	size=Vector2(width,0)
	move_to_front()
