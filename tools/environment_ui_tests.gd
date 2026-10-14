class_name EnvironmentUITests
extends RefCounted

static func pixel_luminance(color: Color) -> float:
	var linear: Color = color.srgb_to_linear()
	return 0.2126*linear.r+0.7152*linear.g+0.0722*linear.b

static func screenshot(tree: SceneTree) -> Image:
	await tree.process_frame;await tree.process_frame;await RenderingServer.frame_post_draw
	return tree.root.get_texture().get_image()

static func run(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree = previous.get_tree()
	var processing: bool = previous.is_processing();var visible: bool = previous.visible;var old_view_process: bool = previous.view.is_processing();var original_size: Vector2i = tree.root.size
	previous.set_process(false);previous.view.set_process(false);previous.hide();tree.root.size=Vector2i(960,600)
	var world: ColonyWorld = ColonyTests.world()
	for x in range(53,59): world._structure("wood_wall",Vector2i(x,45),0);world._structure("door" if x==55 else "wood_wall",Vector2i(x,50),0)
	for y in range(46,50): world._structure("wood_wall",Vector2i(53,y),0);world._structure("wood_wall",Vector2i(58,y),0)
	var person: Dictionary = world.citizens[0];person.x=55;person.y=47;person.edge_x=55;person.edge_y=47
	var trees: Array = world.resources.filter(func(r:Dictionary)->bool:return r.definition=="tree")
	check.call("ART/UI_environment_fixture_has_two_actual_tree_records",trees.size()>=2)
	if trees.size()<2: previous.visible=visible;previous.set_process(processing);previous.view.set_process(old_view_process);return
	trees[0].x=62;trees[0].y=44;trees[1].x=63;trees[1].y=44
	var view: WorldView = WorldView.new();view.theme=previous.theme;tree.root.add_child(view);view.size=Vector2(960,600);view.setup(world);view.set_process(false);view.tile_size=48;view.center_camera(Vector2(56,47));view._process(0)
	var baseline: String = world.canonical_hash();var environment: ColonyEnvironment = view.environment
	check.call("ART/UI_resources_batch_multiple_trees_into_one_visible_chunk_row",environment.resource_rows.values().any(func(row:EnvironmentResourceRow)->bool:return row.records.size()>=2))
	check.call("ART/UI_buildings_share_one_depth_layer_with_people_and_resource_rows",environment.props.size()==world.structures.filter(func(s:Dictionary)->bool:return s.definition not in ColonyEnvironment.FLOORS).size() and environment.props.values().all(func(prop:EnvironmentProp)->bool:return prop.get_parent()==view.actor_layer))
	var room: int = world.room_tiles[Vector2i(55,47)]
	check.call("ART/UI_roof_is_normally_present_over_a_real_enclosed_room",room>=0 and not environment.revealed_rooms.has(room) and not view.rooms_overlay)
	view.selected_id=person.id;view._process(0)
	check.call("ART/UI_selecting_an_occupant_reveals_its_actual_room",environment.revealed_rooms.has(room))
	view.selected_id=0;view.rooms_overlay=true;view._process(0)
	check.call("ART/UI_rooms_overlay_reveals_without_any_selected_citizen",view.rooms_overlay and environment.revealed_rooms.is_empty())
	if DisplayServer.get_name()!="headless": (await screenshot(tree)).save_png("res://reports/environment-room-cutaway.png")
	view.rooms_overlay=false
	var hearth: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	hearth.fuel=0;world.tick+=1;view._process(0)
	check.call("ART/UI_cold_hearth_has_no_false_flame",environment.props[hearth.id].flame==null or not environment.props[hearth.id].flame.visible)
	hearth.fuel=4;world.tick+=1;view._process(0)
	check.call("ART/UI_real_fuel_enables_flame_and_a_bounded_warm_sprite",environment.props[hearth.id].flame.visible and environment.heat_points.size()==1)
	view.quality="Battery";view._process(0)
	check.call("ART/UI_battery_uses_static_water_and_keeps_the_actual_fire_state",environment.static_water.visible and not environment.animated_water.visible and environment.props[hearth.id].flame.visible)
	view.quality="Balanced";view.reduced_motion=false;view._process(0)
	check.call("ART/UI_balanced_uses_two_frame_water_without_world_changes",not environment.static_water.visible and environment.animated_water.visible)
	view.reduced_motion=true;view._process(1)
	check.call("ART/UI_reduced_motion_stops_decorative_water_and_animation_clocks",environment.static_water.visible and not environment.animated_water.visible and environment.visual_clock==0 and environment.weather_clock==0)
	view.reduced_motion=false
	world.tick=3600;view._process(0)
	if DisplayServer.get_name()!="headless":
		var point: Vector2i = Vector2i(view.tile_to_screen(Vector2(60.2,44.2)))
		var day: Color = (await screenshot(tree)).get_pixelv(point)
		world.tick=7200;view._process(0)
		var night: Image = await screenshot(tree)
		var ratio: float = pixel_luminance(night.get_pixelv(point))/pixel_luminance(day)
		check.call("ART/UI_actual_night_ground_keeps_at_least_70_percent_day_luminance",ratio>=0.7,str(ratio))
		night.save_png("res://reports/environment-night.png")
	var second: Dictionary = world.citizens[1];second.x=62;second.y=43;second.edge_x=62;second.edge_y=43
	world.tick=3600;view._process(0)
	view.selected_id=second.id;view._process(0)
	check.call("ART/UI_selected_actor_bounds_reach_overlapping_tree_batches",environment.selected_bounds.has_area() and environment.resource_rows.values().all(func(row:EnvironmentResourceRow)->bool:return row.selected_bounds==environment.selected_bounds))
	if DisplayServer.get_name()!="headless": (await screenshot(tree)).save_png("res://reports/environment-tree-fade.png")
	baseline=world.canonical_hash()
	for index in range(10): view._process(0.016)
	check.call("ART/UI_repeated_environment_rendering_preserves_every_saved_field",world.canonical_hash()==baseline)
	var count: int = environment.resource_rows.size()
	view.center_camera(Vector2(110,110));view._process(0)
	await tree.process_frame;await tree.process_frame
	check.call("ART/UI_camera_releases_chunks_outside_the_visible_area",environment.resource_rows.size()<count)
	view.center_camera(Vector2(56,47));view._process(0)
	check.call("ART/UI_camera_return_restores_batched_resource_views",environment.resource_rows.size()==count)
	var replacement: ColonyWorld = ColonyTests.world()
	view.world=replacement;view.refresh_terrain();view.center_camera(Vector2(68,63));view._process(0)
	check.call("ART/UI_explicit_campaign_refresh_releases_every_old_resource_world_reference",not environment.resource_rows.is_empty() and environment.resource_rows.values().all(func(row:EnvironmentResourceRow)->bool:return row.world==replacement) and environment.props.values().all(func(prop:EnvironmentProp)->bool:return prop.world==replacement))
	await carrying(view,check)
	view.queue_free();await tree.process_frame;await tree.process_frame
	tree.root.size=original_size;previous.visible=visible;previous.set_process(processing);previous.view.set_process(old_view_process)

static func carrying(view: WorldView, check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	world.queue_command("build",{"definition":"wood_wall","x":74,"y":62,"rotation":0})
	var carrier: Dictionary = {}
	for tick in range(600):
		world.step()
		for stack in world.nonempty_stacks():
			if stack.location!="carry": continue
			var person: Dictionary = world.find(world.citizens,stack.owner)
			if not person.is_empty() and person.progress>0 and Vector2i(person.edge_x,person.edge_y)!=Vector2i(person.x,person.y): carrier=person;break
		if not carrier.is_empty(): break
	check.call("ART/UI_carry_pose_fixture_uses_real_fetched_goods_in_motion",not carrier.is_empty() and world.invariant_errors().is_empty())
	if carrier.is_empty(): return
	var canonical: String = world.canonical_hash()
	view.world=world;view._process(0)
	var actor: CitizenSprite = view.actors.filter(func(a:Sprite2D)->bool:return a.get_meta("world_id")==carrier.id)[0]
	check.call("ART/UI_actual_carried_inventory_selects_the_carry_animation",actor.pose=="carry" and world.canonical_hash()==canonical)
