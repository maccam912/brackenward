extends SceneTree
## Native quantity-tier gallery from disposable inventory, never a player save.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size=Vector2i(1100,780)
	var world: ColonyWorld=ColonyTests.world()
	world.structures.clear();world.resources.clear();world.citizens.clear();world.stacks.clear();world.stores.clear()
	world.tick=3600
	var index: int=0
	for item in world.definitions.items:
		var limit: int=world.definitions.items[item].stack_limit
		for tier in range(3):
			world._make_stack(item,[1,maxi(1,int(limit*0.5)),limit][tier],"ground",0,Vector2i(40+(index%7)*4+tier,40+(index/7)*6),true)
		index+=1
	var baseline: String=world.canonical_hash()
	var view: WorldView=WorldView.new();root.add_child(view);view.size=Vector2(1100,780);view.setup(world);view.set_process(false)
	view.tile_size=28;view.quality="Battery";view.reduced_motion=true;view.center_camera(Vector2(53.5,49.5));view._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/visual-polish/supplies-native.png")
	if world.canonical_hash()!=baseline:push_error("Supply gallery mutated world");quit(1);return
	view.queue_free();await process_frame
	print("VISUAL_SUPPLIES_REVIEW_COMPLETE stacks=84 state_unchanged=true");quit()
