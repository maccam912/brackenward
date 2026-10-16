extends SceneTree
## Native building gallery from a disposable fixture, never a player campaign.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size=Vector2i(1100,900)
	var world: ColonyWorld=ColonyTests.world()
	world.structures.clear();world.resources.clear();world.citizens.clear();world.stacks.clear()
	world.tick=3600
	var index: int=0
	for kind in world.definitions.buildings:
		world._structure(kind,Vector2i(40+(index%7)*6,40+(index/7)*6),0)
		index+=1
	var view: WorldView=WorldView.new()
	root.add_child(view);view.size=Vector2(1100,900);view.setup(world);view.set_process(false)
	view.tile_size=24;view.quality="Battery";view.reduced_motion=true
	view.center_camera(Vector2(59,54));view._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/workshop-native.png")
	var beacon: Dictionary=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="beacon")[0]
	world.charter_state.ceremony={"state":"Complete","end":world.tick-100};world.tick+=1
	view.tile_size=64;view.center_camera(Vector2(beacon.x+1.5,beacon.y+1.5));view._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/beacon-lit.png")
	var rotations: ColonyWorld=ColonyTests.world()
	rotations.structures.clear();rotations.resources.clear();rotations.citizens.clear();rotations.stacks.clear();rotations.tick=3600
	var kinds: Array[String]=["workbench","loom","herbal_bench","research_desk"]
	for row in range(kinds.size()):
		for turn in range(4):rotations._structure(kinds[row],Vector2i(40+turn*7,40+row*7),turn)
	var baseline: String=rotations.canonical_hash()
	view.world=rotations;view.refresh_terrain();view.tile_size=32;view.center_camera(Vector2(51.5,51.5));view._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/craft-rotations-native.png")
	if rotations.canonical_hash()!=baseline:push_error("Craft gallery mutated world");quit(1);return
	view.queue_free();await process_frame
	print("VISUAL_WORKSHOP_REVIEW_COMPLETE");quit()
