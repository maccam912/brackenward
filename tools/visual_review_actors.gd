extends SceneTree
## Original sprite/equipment pose gallery; no simulation or campaign is opened.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size=Vector2i(1000,900)
	var background: ColorRect=ColorRect.new();background.color=Color("A6B878");background.size=Vector2(1000,900);root.add_child(background)
	var entries: Array=[["Gathering","work",""],["Build","work",""],["Cooking","work",""],["Farming","plant",""],["Guard","melee","spear"],["Guard","shoot","bow"]]
	for row in range(entries.size()):
		var caption: Label=Label.new();caption.text=entries[row][0]+" / "+entries[row][1];caption.position=Vector2(12,50+row*140);caption.modulate=Color("263C3B");root.add_child(caption)
		for facing in range(4):
			var actor: CitizenSprite=CitizenSprite.new();root.add_child(actor)
			actor.position=Vector2(300+facing*190,130+row*140);actor.scale=Vector2.ONE*4
			actor.facing=facing;actor.task_skill=entries[row][0];actor.weapon=entries[row][2]
			actor.set_visual(ColonyAppearance.defaults(1),entries[row][1],0,0,true);actor.equipment_layer.queue_redraw()
	for facing in range(4):
		var caption: Label=Label.new();caption.text=["South","East","North","West"][facing];caption.position=Vector2(280+facing*190,4);caption.modulate=Color("263C3B");root.add_child(caption)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var output: String=args[0] if not args.is_empty() else "reports/visual-polish/actors-native.png"
	root.get_texture().get_image().save_png(output)
	print("VISUAL_ACTOR_REVIEW_COMPLETE poses=24");quit()
