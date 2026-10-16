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
	var bank_count: int=environment.bank_rectangles.size()
	check.call("ART/UI_river_banks_have_visible_cached_geometry",bank_count>0)
	var banks_inside_water: bool=true
	for entry in environment.bank_rectangles:
		var rectangle: Rect2=entry[0]
		var cell: Vector2i=Vector2i((rectangle.position+rectangle.size*0.5)/16.0)
		banks_inside_water=banks_inside_water and PrototypeWorld.is_water(cell)
	check.call("ART/UI_river_bank_art_stays_inside_logical_water",banks_inside_water)
	view.refresh_terrain();view._process(0)
	check.call("ART/UI_river_bank_rebuild_is_idempotent_and_preserves_saved_state",environment.bank_rectangles.size()==bank_count and world.canonical_hash()==baseline)
	check.call("ART/UI_resources_batch_multiple_trees_into_one_visible_chunk_row",environment.resource_rows.values().any(func(row:EnvironmentResourceRow)->bool:return row.records.size()>=2))
	check.call("ART/UI_buildings_share_one_depth_layer_with_people_and_resource_rows",environment.props.size()==world.structures.filter(func(s:Dictionary)->bool:return s.definition not in ColonyEnvironment.FLOORS).size() and environment.props.values().all(func(prop:EnvironmentProp)->bool:return prop.get_parent()==view.actor_layer))
	var room: int = world.room_tiles[Vector2i(55,47)]
	check.call("ART/UI_enclosed_room_keeps_shelter_without_a_roof_overlay",room>=0 and not view.rooms_overlay and world.roofed(Vector2i(55,47)))
	var top_wall: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.x==54 and s.y==45)[0]
	var corner: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.x==53 and s.y==45)[0]
	check.call("ART/UI_wall_straights_and_corners_connect_to_actual_neighbors",environment.props[top_wall.id].wall_mask==10 and environment.props[corner.id].wall_mask==6 and environment.props[top_wall.id].wall_visual.visible)
	var interior_pixel: Color
	if DisplayServer.get_name()!="headless":
		var actual: Image = await screenshot(tree)
		interior_pixel=actual.get_pixelv(Vector2i(view.tile_to_screen(Vector2(55.5,48.5))))
		var seam: Vector2i = Vector2i(view.tile_to_screen(Vector2(55,45.25)))
		check.call("ART/UI_adjacent_wall_cap_pixels_have_no_seam",actual.get_pixelv(seam)==actual.get_pixelv(seam+Vector2i.LEFT) and actual.get_pixelv(seam)==actual.get_pixelv(seam+Vector2i.RIGHT))
		actual.save_png("res://reports/feedback-open-rooms-connected-walls.png")
	view.selected_id=person.id;view._process(0)
	check.call("ART/UI_selecting_an_occupant_reveals_its_actual_room",environment.revealed_rooms.has(room))
	view.selected_id=0;view.rooms_overlay=true;view._process(0)
	check.call("ART/UI_rooms_overlay_reveals_without_any_selected_citizen",view.rooms_overlay and environment.revealed_rooms.is_empty())
	if DisplayServer.get_name()!="headless":
		var outlined: Image = await screenshot(tree)
		check.call("ART/UI_room_outline_never_fills_or_hides_the_interior",outlined.get_pixelv(Vector2i(view.tile_to_screen(Vector2(55.5,48.5))))==interior_pixel)
		outlined.save_png("res://reports/environment-room-cutaway.png")
	view.rooms_overlay=false
	var branch: Dictionary = world._structure("stone_wall",Vector2i(54,44),0)
	world.tick+=1;view._process(0)
	check.call("ART/UI_mixed_material_T_junction_updates_after_construction",environment.props[top_wall.id].wall_mask==11)
	branch.health=0;world.tick+=1;view._process(0)
	check.call("ART/UI_destroyed_wall_disconnects_and_leaves_a_gap",environment.props[top_wall.id].wall_mask==10 and (environment.props[branch.id].wall_visual==null or not environment.props[branch.id].wall_visual.visible))
	var hearth: Dictionary = world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	view.center_camera(Vector2(hearth.x+1,hearth.y+1))
	hearth.fuel=0;world.tick+=1;view._process(0)
	check.call("ART/UI_cold_hearth_has_no_false_flame",environment.props[hearth.id].flame==null or not environment.props[hearth.id].flame.visible)
	hearth.fuel=4;world.tick+=1;view._process(0)
	check.call("ART/UI_real_fuel_enables_flame_and_a_bounded_warm_sprite",environment.props[hearth.id].flame.visible and environment.heat_points.size()==1)
	var hearth_health: int=hearth.health
	hearth.health=0;world.tick+=1;view._process(0)
	check.call("ART/UI_destroyed_hearth_with_leftover_fuel_has_no_false_flame_or_glow",not environment.props[hearth.id].flame.visible and environment.heat_points.is_empty())
	hearth.health=hearth_health;world.tick+=1;view._process(0)
	view.quality="Battery";view._process(0)
	check.call("ART/UI_battery_uses_static_water_and_keeps_the_actual_fire_state",environment.static_water.visible and not environment.animated_water.visible and environment.props[hearth.id].flame.visible)
	view.quality="Balanced";view.reduced_motion=false;view._process(0)
	check.call("ART/UI_balanced_uses_two_frame_water_without_world_changes",not environment.static_water.visible and environment.animated_water.visible)
	view.reduced_motion=true;view._process(1)
	check.call("ART/UI_reduced_motion_stops_decorative_water_and_animation_clocks",environment.static_water.visible and not environment.animated_water.visible and environment.visual_clock==0 and environment.weather_clock==0)
	view.reduced_motion=false
	view.center_camera(Vector2(56,47))
	world.tick=3600;view._process(0)
	if DisplayServer.get_name()!="headless":
		var point: Vector2i = Vector2i(view.tile_to_screen(Vector2(60.2,44.2)))
		var day: Color = (await screenshot(tree)).get_pixelv(point)
		world.tick=7200;view._process(0)
		var night: Image = await screenshot(tree)
		var ratio: float = pixel_luminance(night.get_pixelv(point))/pixel_luminance(day)
		check.call("ART/UI_actual_night_ground_is_readable_and_visibly_darker_than_day",ratio>=0.30 and ratio<=0.65,str(ratio))
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
	terrain_edges(view,check)
	seasonal_landscape(view,check)
	offscreen_props(view,check)
	beacon_flame(view,check)
	await renewable_resources(view,check)
	await weather_atmosphere(view,check)
	view.queue_free();await tree.process_frame;await tree.process_frame
	tree.root.size=original_size;previous.visible=visible;previous.set_process(processing);previous.view.set_process(old_view_process)

static func terrain_edges(view: WorldView, check: Callable) -> void:
	for site in ["meadow_reach","pine_shelf","reed_bend"]:
		var world: ColonyWorld=ColonyTests.world()
		ColonyGeneration.configure(world,104729,site)
		var baseline: String=world.canonical_hash()
		view.world=world;view.refresh_terrain();view._process(0)
		var environment: ColonyEnvironment=view.environment
		var valid: bool=not environment.path_rectangles.is_empty() and not environment.bank_rectangles.is_empty()
		for entry in environment.path_rectangles:
			var rectangle: Rect2=entry[0]
			var cell: Vector2i=Vector2i(rectangle.get_center()/16.0)
			valid=valid and world.terrain_state.paths.has(cell) and world.terrain_state.elevation[cell.y*128+cell.x]!=0 and Rect2(Vector2(cell)*16,Vector2.ONE*16).encloses(rectangle)
		for entry in environment.bank_rectangles:
			var rectangle: Rect2=entry[0]
			var cell: Vector2i=Vector2i(rectangle.get_center()/16.0)
			valid=valid and world.terrain_state.elevation[cell.y*128+cell.x]==0 and Rect2(Vector2(cell)*16,Vector2.ONE*16).encloses(rectangle)
		check.call("ART/UI_%s_terrain_edges_stay_inside_their_actual_cells_without_saved_changes" % site,valid and world.canonical_hash()==baseline)
		var paths: Array=environment.path_rectangles.duplicate(true)
		var banks: Array=environment.bank_rectangles.duplicate(true)
		view.refresh_terrain();view._process(0)
		check.call("ART/UI_%s_terrain_edge_rebuild_is_exact" % site,paths==environment.path_rectangles and banks==environment.bank_rectangles and world.canonical_hash()==baseline)

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

static func seasonal_landscape(view: WorldView, check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	ColonyGeneration.configure(world,104729,"meadow_reach")
	view.world=world;view.refresh_terrain();view.center_camera(Vector2(64,64));view._process(0)
	var ground: Vector2i=Vector2i.ZERO
	for point in view.terrain.get_used_cells():
		if view.terrain.get_cell_atlas_coords(point).x<9:ground=point;break
	var summer_tile: Vector2i=view.terrain.get_cell_atlas_coords(ground)
	for season in [2,3,0]:
		world.tick=season*8*7200+3600
		var baseline: String=world.canonical_hash()
		view._process(0)
		var source: int=view.terrain.get_cell_source_id(ground)
		var exact: bool=source==summer_tile.x+2 if season==3 else source==0 and view.terrain.get_cell_atlas_coords(ground)==summer_tile
		var water_count: int=view.environment.static_water.get_used_cells().size()
		for point in world.terrain_state.paths:
			if world.terrain_state.elevation[point.y*128+point.x]!=0:exact=exact and view.terrain.get_cell_source_id(point)==0
		check.call("ART/UI_season_%d_changes_only_grass_presentation_and_keeps_paths_water_state" % season,exact and water_count>0 and world.canonical_hash()==baseline)

static func offscreen_props(view: WorldView, check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();world.tick=3600
	var hearth: Dictionary=world._structure("hearth",Vector2i(110,110),0);hearth.fuel=0
	view.world=world;view.refresh_terrain();view.center_camera(Vector2(64,64));view._process(0)
	var prop: EnvironmentProp=view.environment.props[hearth.id]
	check.call("ART/UI_offscreen_building_keeps_live_record_without_visible_sync",not prop.visible and prop.world==world and prop.record==hearth and prop.semantic.is_empty())
	hearth.fuel=4;world.tick+=1
	var baseline: String=world.canonical_hash()
	view.center_camera(Vector2(110,110));view._process(0)
	check.call("ART/UI_camera_return_synchronizes_current_fuel_and_same_building_node",prop.visible and prop.flame!=null and prop.flame.visible and prop==view.environment.props[hearth.id] and world.canonical_hash()==baseline)
	var original_quality: String=view.quality;var original_motion: bool=view.reduced_motion;var original_speed: int=view.simulation_speed
	view.quality="Balanced";view.reduced_motion=false;view.simulation_speed=1
	view.environment.visual_clock=0;view._process(0)
	var first_frame: Rect2=prop.flame.region_rect
	view._process(0.3)
	check.call("ART/UI_flame_frame_advances_without_a_simulation_tick",prop.flame.region_rect!=first_frame and world.canonical_hash()==baseline)
	view.quality=original_quality;view.reduced_motion=original_motion;view.simulation_speed=original_speed
	view.center_camera(Vector2(64,64));view._process(0)
	var original_zoom: float=view.tile_size
	view.tile_size=2;view._process(0)
	check.call("ART/UI_zoom_change_resynchronizes_offscreen_props_without_a_tick",prop.visible and prop.flame.visible)
	view.tile_size=original_zoom;view._process(0)
	hearth.health=0;world.tick+=1;view._process(0)
	baseline=world.canonical_hash()
	view.center_camera(Vector2(110,110));view._process(0)
	check.call("ART/UI_camera_return_shows_offscreen_destruction_without_stale_fire",prop.visible and prop.semantic=="resource/stone_node/0" and not prop.flame.visible and world.canonical_hash()==baseline)

static func beacon_flame(view: WorldView, check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();world.tick=3600
	var beacon: Dictionary=world._structure("beacon",Vector2i(62,62),0)
	view.world=world;view.refresh_terrain();view.center_camera(Vector2(63,63));view._process(0)
	var prop: EnvironmentProp=view.environment.props[beacon.id]
	check.call("ART/UI_unlit_beacon_does_not_invent_ceremony_fire",prop.flame==null or not prop.flame.visible)
	for state in ["Active","Complete"]:
		world.charter_state.ceremony={"state":state,"end":world.tick};world.tick+=1
		var baseline: String=world.canonical_hash();view._process(0)
		check.call("ART/UI_%s_beacon_fire_is_anchored_at_the_raised_basket" % state,prop.flame!=null and prop.flame.visible and prop.flame.position==Vector2(0,-46) and world.canonical_hash()==baseline)
	beacon.health=0;world.tick+=1;view._process(0)
	check.call("ART/UI_destroyed_beacon_hides_its_ceremony_fire",not prop.flame.visible)

static func renewable_resources(view: WorldView, check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();world.tick=3600
	world.resources.clear();world.structures.clear();world.citizens.clear();world.stacks.clear();world.stores.clear()
	for kind in ["berry_bush","herb_patch","mushroom_patch","stone_node"]:
		world.resources.append({"id":world._id(),"definition":kind,"x":48+world.resources.size()*4,"y":52,"remaining":world.definitions.resources[kind].yield_count,"regrow_at":0})
	view.world=world;view.refresh_terrain();view.tile_size=48;view.center_camera(Vector2(54,52));view._process(0)
	var ready: Image
	var region: Rect2i=Rect2i(Vector2i(view.tile_to_screen(Vector2(47.5,51.5))),Vector2i(14*48,72))
	if DisplayServer.get_name()!="headless":
		ready=(await screenshot(view.get_tree())).get_region(region)
		ready.save_png("res://reports/regrowth-ready.png")
	for resource in world.resources:
		resource.remaining=0;resource.regrow_at=3602 if resource.definition!="stone_node" else 0
	world.resource_query_dirty=true;world.tick=3601
	var baseline: String=world.canonical_hash();view._process(0)
	var visible: Array=[]
	for row in view.environment.resource_rows.values():
		for resource in row.records:visible.append(resource.definition)
	visible.sort()
	check.call("ART/UI_harvested_renewables_remain_visible_but_exhausted_stone_disappears",visible==["berry_bush","herb_patch","mushroom_patch"] and world.canonical_hash()==baseline)
	if DisplayServer.get_name()!="headless":
		var depleted: Image=(await screenshot(view.get_tree())).get_region(region)
		depleted.save_png("res://reports/regrowth-depleted.png")
		var changed: bool=true
		for index in range(3):
			var crop: Rect2i=Rect2i(index*4*48,0,72,72)
			changed=changed and ready.get_region(crop).get_data()!=depleted.get_region(crop).get_data()
		check.call("ART/UI_native_harvested_shapes_differ_from_ready_fruit_flowers_and_caps",changed)
	world.tick=3602;ColonyAgriculture.advance(world)
	baseline=world.canonical_hash();view._process(0)
	check.call("ART/UI_actual_regrowth_restores_ready_resource_art_without_render_mutation",world.resources.slice(0,3).all(func(r:Dictionary)->bool:return r.remaining>0 and r.regrow_at==0 and not EnvironmentArt.resource_semantic(world,r).contains("depleted")) and world.resources[3].remaining==0 and world.canonical_hash()==baseline)
	if DisplayServer.get_name()!="headless":
		var restored: Image=(await screenshot(view.get_tree())).get_region(region)
		# Exclude the finite stone, which correctly stays exhausted.
		check.call("ART/UI_regrown_resource_pixels_exactly_match_original_ready_pixels",ready.get_region(Rect2i(0,0,12*48,72)).get_data()==restored.get_region(Rect2i(0,0,12*48,72)).get_data())

static func weather_atmosphere(view: WorldView, check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();world.tick=3600;world.weather="clear"
	view.world=world;view.refresh_terrain();view.tile_size=24;view.center_camera(Vector2(64,64))
	view.quality="Battery";view.reduced_motion=false;view._process(0)
	var clear_pixels: PackedByteArray
	if DisplayServer.get_name()!="headless":clear_pixels=(await screenshot(view.get_tree())).get_data()
	for weather in ["rain","fog","snow","cold_snap","drought","flood"]:
		world.weather=weather;world.tick+=1
		var baseline: String=world.canonical_hash()
		view.quality="Battery";view.reduced_motion=false;view._process(0)
		var battery_pixels: PackedByteArray
		if DisplayServer.get_name()!="headless":battery_pixels=(await screenshot(view.get_tree())).get_data()
		view.quality="Balanced";view.reduced_motion=true;view._process(0)
		check.call("ART/UI_%s_static_weather_never_advances_saved_world" % weather,world.canonical_hash()==baseline)
		if DisplayServer.get_name()!="headless":
			var reduced_pixels: PackedByteArray=(await screenshot(view.get_tree())).get_data()
			check.call("ART/UI_%s_atmosphere_visible_and_identical_in_battery_and_reduced_motion" % weather,battery_pixels!=clear_pixels and battery_pixels==reduced_pixels)
	world.weather="clear";world.tick=3600;view.quality="Battery";view.reduced_motion=false;view._process(0)
	if DisplayServer.get_name()!="headless":
		check.call("ART/UI_clear_weather_restores_original_native_pixels",(await screenshot(view.get_tree())).get_data()==clear_pixels)
