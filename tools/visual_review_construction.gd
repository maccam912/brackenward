extends SceneTree
## Native acknowledged construction plans from a disposable colony.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size=Vector2i(1100,600)
	var world: ColonyWorld=ColonyTests.world();world.resources.clear();world.tick=3600
	for id in world.definitions.research:world.researched.append(id)
	var kinds: Array[String]=["wood_wall","bed","workbench","loom","barn","beacon"]
	for index in range(kinds.size()):world.queue_command("build",{"definition":kinds[index],"x":42+index*6,"y":52,"rotation":0})
	world.step()
	var baseline: String=world.canonical_hash()
	var view: WorldView=WorldView.new();root.add_child(view);view.size=Vector2(1100,600);view.setup(world);view.set_process(false)
	view.tile_size=28;view.quality="Battery";view.reduced_motion=true;view.center_camera(Vector2(58,53));view._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/construction-plans.png")
	# The comparison removes only new ghost commands, preserving every cue.
	for chunk in view.environment.ground_chunks.values():
		chunk.set_commands(chunk.commands.filter(func(c:Array)->bool:return not (str(c[0]).begins_with("building/") and c[2].a<0.5)))
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/construction-without-ghosts.png")
	if world.canonical_hash()!=baseline:push_error("Construction gallery mutated world");quit(1);return
	print("VISUAL_CONSTRUCTION_REVIEW_COMPLETE jobs=%d state_unchanged=true" % world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.kind=="build").size())
	view.queue_free();await process_frame;quit()
