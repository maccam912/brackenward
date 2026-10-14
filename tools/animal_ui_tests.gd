class_name AnimalUITests
extends RefCounted

class SelectionProbe extends GameSession:
	var chosen: Dictionary = {}
	func _select_map_object(candidate: Dictionary) -> void:
		chosen=candidate

static func run(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree = previous.get_tree()
	var previous_processing: bool = previous.is_processing();var previous_visible: bool = previous.visible
	var original_size: Vector2i = tree.root.size
	previous.set_process(false);previous.hide();tree.root.size=Vector2i(960,600)
	var world: ColonyWorld = DomesticTests.setup()
	for kind in ["hare","deer","boar","marsh_goose"]: ColonyWildlife.spawn(world,kind,Vector2i(73,66))
	var pen: Dictionary = world.domestic_state.pens[0]
	var hen: Dictionary = ColonyDomestic.acquire(world,"hen",pen.id,Vector2i(66,63)).animal
	var goat: Dictionary = ColonyDomestic.acquire(world,"pack_goat",pen.id,Vector2i(66,63)).animal
	var merchant: Dictionary = TradeTests.merchant(world)
	var offer: Dictionary = ColonyOpportunities.offer(world,"stranded_carrier")
	var raid: Dictionary = DefenseTests.raid(world,6)
	var view: WorldView = WorldView.new();tree.root.add_child(view);view.size=Vector2(960,600);view.setup(world);view.set_process(false)
	view.tile_size=48;view.center_camera(Vector2(60,49));view._process(0)
	var expected: int = world.wildlife_state.animals.size()+2+2+world.opportunity_state.visitors.size()+world.defense_state.enemies.size()
	check.call("ART/UI_every_live_animal_and_visitor_has_one_pooled_sprite",view.extra_actors.size()==expected and not offer.is_empty() and not raid.is_empty())
	var pool: Dictionary = view.extra_actors.duplicate()
	for index in range(10): view._process(0.016)
	check.call("ART/UI_render_frames_reuse_existing_nodes",view.extra_actors==pool)
	var keys: Array = view.extra_actors.keys();var column: int = 0
	for key in keys:
		var actor: Sprite2D = view.extra_actors[key]
		if actor.role=="carcass": continue
		actor.record.x=53+(column%10)*2;actor.record.y=46+(column/10)*3
		if actor.record.has("route"): actor.record.route=[];actor.record.progress=0
		column+=1
	hen.juvenile_until=world.tick+100;world.tick+=1;view._process(0)
	check.call("ART/UI_juvenile_appearance_does_not_change_logical_tile",view.extra_actors["domestic:%d" % hen.id].scale==Vector2.ONE*0.7 and view.extra_actors["domestic:%d" % goat.id].scale==Vector2.ONE)
	var canonical: String = world.canonical_hash()
	for index in range(20): view._process(0.016)
	check.call("ART/UI_repeated_rendering_does_not_change_simulation_or_rng",world.canonical_hash()==canonical)
	var ordered: Array = view.actor_layer.get_children().map(func(n:Node)->int:return n.get_meta("world_id"))
	var sorted: Array = ordered.duplicate();sorted.sort()
	check.call("ART/UI_equal_y_ties_use_stable_global_id_order",ordered==sorted)
	var first: AnimalSprite = view.extra_actors["wild:%d" % world.wildlife_state.animals[0].id]
	check.call("ART/UI_nearest_filtered_shared_texture_renders_visible_animal",first.visible and first.texture==AnimalArt.ATLAS and first.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST)
	await tree.process_frame;await tree.process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var with_animal: Image = tree.root.get_texture().get_image()
		with_animal.save_png("res://reports/animal-visitors-960x600.png")
		var sample: Rect2i = Rect2i(view.tile_to_screen(first.position/16.0)-Vector2(36,72),Vector2(72,72))
		first.hide();await tree.process_frame;await RenderingServer.frame_post_draw
		var without_animal: Image = tree.root.get_texture().get_image()
		check.call("ART/UI_actual_animal_pixels_remain_visible_over_terrain",with_animal.get_region(sample).get_data()!=without_animal.get_region(sample).get_data())
		first.show()
	# Tap the visible body near the end of an edge, outside the old tile's
	# selection radius. Keep the real WorldView gesture and map hit test.
	first.record.x=90;first.record.y=90;first.record.route=[Vector2i(91,90)];first.record.progress=9000
	world.tick+=1;view.tile_size=64;view.center_camera(Vector2(90.5,90.5));view._process(0)
	var probe: SelectionProbe = SelectionProbe.new();probe.view=view;probe.world=world
	view.intent.connect(probe._map_intent)
	var tap: Vector2 = view.tile_to_screen(first.position/16.0+Vector2(0,-0.35))
	await AudioUITests.touch(tree,tap,true);await AudioUITests.touch(tree,tap,false)
	check.call("ART/UI_touch_selects_visible_moving_animal_beyond_its_previous_tile",probe.chosen.get("kind")=="wildlife" and probe.chosen.get("object",{}).get("id")==first.record.id)
	view.intent.disconnect(probe._map_intent);probe.free()
	merchant.state="Gone";world.tick+=1;view._process(0)
	check.call("ART/UI_departed_merchant_and_cosmetic_pack_leave_no_ghost",not view.extra_actors.has("merchant:%d" % merchant.id) and not view.extra_actors.has("pack:%d" % merchant.id))
	var victim: Dictionary = world.wildlife_state.animals[0]
	victim.health=0
	var carcass: Dictionary = {"id":world._id(),"animal":victim.id,"definition":victim.definition,"x":victim.x,"y":victim.y,"expires":world.tick+14400,"done":false,"spoiled":false}
	world.wildlife_state.carcasses.append(carcass);world.tick+=1;view._process(0)
	check.call("ART/UI_unbutchered_carcass_replaces_live_animal_once",not view.extra_actors.has("wild:%d" % victim.id) and view.extra_actors["carcass:%d" % carcass.id].pose=="downed")
	carcass.done=true;world.tick+=1;view._process(0)
	check.call("ART/UI_finished_carcass_releases_its_sprite",not view.extra_actors.has("carcass:%d" % carcass.id))
	var replacement: ColonyWorld = ColonyTests.world();ColonyWildlife.spawn(replacement,"marsh_goose",Vector2i(73,66));view.world=replacement;view._process(0)
	check.call("ART/UI_campaign_switch_discards_old_guest_and_animal_references",view.extra_actors.size()==1 and view.extra_actors.values().all(func(n:Node)->bool:return n.role=="wildlife" and n.kind=="marsh_goose"))
	view.queue_free();await tree.process_frame;await tree.process_frame
	tree.root.size=original_size;previous.visible=previous_visible;previous.set_process(previous_processing)
