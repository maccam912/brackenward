class_name ResidentMarkerTests
extends RefCounted

static func all_ids(view: WorldView) -> Array[int]:
	var result: Array[int]=[]
	for group in view.resident_markers.groups:
		for person in group.people: result.append(person.id)
	result.sort();return result

static func twenty() -> ColonyWorld:
	var world: ColonyWorld=ColonyTests.world();var template: Dictionary=world.citizens[0]
	for index in range(16):
		var person: Dictionary=ColonyWorld.citizen_record(world._id(),"Marker %d" % (index+5),Vector2i(10+index%4*25,10+index/4*25),template.skills.duplicate(),template.xp.duplicate(),template.traits.duplicate(),template.preferred,template.preferences.duplicate(),template.food_tag,"")
		world.citizens.append(person);world._record("produced","toolkit",1);world._record("produced","cloak",1)
	world.social_state=ColonySocial.initial_state(world.citizens,world.tick)
	world.equipment_state=ColonyEquipment.initial_state(world.citizens)
	return world

static func run(game: GameSession, check: Callable) -> void:
	var tree: SceneTree=game.get_tree()
	game.cancel_placement();game.close_sheet();game.close_inspector();game._replace_world(ColonyTests.world());game._tutorial_dismiss()
	game.set_speed(0);game.view.follow_id=0;game.view.tile_size=2;game.view.center_camera(Vector2(66,63));game.view._process(0)
	var canonical: String=game.world.canonical_hash();var center: Vector2=game.view.camera_center()
	var overview: ResidentMarkers=game.view.resident_markers
	check.call("MARKER/UI_farthest_zoom_keeps_all_four_residents_in_one_readable_pin",overview.visible and overview.groups.size()==1 and all_ids(game.view)==[1,2,3,4] and overview.markers[0].visible and overview.markers[0].face.size==Vector2(24,24) and overview.markers[0].size==Vector2(32,32) and overview.markers[0].count.visible and overview.markers[0].count.text=="4")
	check.call("MARKER/UI_overview_does_not_advance_or_move_the_camera",game.world.canonical_hash()==canonical and game.runner.speed==0 and game.view.camera_center()==center and game.world.pending_commands.is_empty())
	await tree.process_frame;await tree.process_frame
	var point: Vector2=overview.groups[0].center
	var touch: InputEventScreenTouch=InputEventScreenTouch.new();touch.index=0;touch.position=game.view.get_global_transform()*point;touch.pressed=true
	tree.root.push_input(touch);touch.pressed=false;tree.root.push_input(touch)
	await tree.process_frame
	var names: Array=[]
	for child in game.sheet_body.get_children():
		if child is Button: names.append(child.text)
	check.call("MARKER/UI_real_touch_through_portraits_opens_complete_existing_chooser",game.sheet_route=="Select object" and names.slice(0,4)==game.world.citizens.map(func(p:Dictionary)->String:return p.name) and game.world.canonical_hash()==canonical)
	if game.sheet_route=="Select object":
		var choices: Array=game.sheet_body.get_children().filter(func(n:Node)->bool:return n is Button and n.text==game.world.citizens[2].name)
		if not choices.is_empty(): choices[0].pressed.emit()
	game.view._process(0)
	check.call("MARKER/UI_chooser_selects_actual_resident_and_uses_their_portrait",game.view.selected_id==3 and overview.markers[0].selected and overview.markers[0].face.get_meta("appearance")==game.world.citizens[2].appearance and game.world.canonical_hash()==canonical)
	var follow: Array=game.inspector.find_children("*","Button",true,false).filter(func(n:Node)->bool:return n.text==ColonyText.text("ui.action.follow"))
	if not follow.is_empty(): follow[0].pressed.emit()
	game.view._process(0)
	check.call("MARKER/UI_explicit_follow_from_overview_returns_to_readable_individual_zoom",not follow.is_empty() and game.view.follow_id==3 and game.view.tile_size==32 and not overview.visible and game.view.camera_tile.is_equal_approx(game.view.citizen_point(game.world.citizens[2])) and game.world.canonical_hash()==canonical and game.runner.speed==0)
	game.view.follow_id=0;game.view.tile_size=2;game.view.center_camera(center);game.view._process(0)
	var person: Dictionary=game.world.citizens[2]
	person.appearance=ColonyAppearance.defaults(33)
	var changed: String=game.world.canonical_hash();game.view._process(0)
	check.call("MARKER/UI_paused_cosmetic_changes_refresh_the_real_palette",overview.markers[0].face.get_meta("appearance")==person.appearance and overview.markers[0].face.material.get_shader_parameter("scarf")==Color(CitizenArt.CLOTH[person.appearance.scarf]) and game.world.canonical_hash()==changed and game.runner.speed==0)
	person.downed=true;game.view._process(0)
	check.call("MARKER/UI_downed_resident_retains_a_shape_based_care_cue",overview.markers[0].needs_care and all_ids(game.view).has(person.id))
	if DisplayServer.get_name()!="headless":
		await tree.process_frame;await tree.process_frame;await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("res://reports/resident-overview-care.png")
	person.downed=false;game.view.high_contrast=true;game.view._process(0)
	check.call("MARKER/UI_high_contrast_selected_pin_has_a_thick_black_outline",overview.markers[0].selected and overview.markers[0].selected_style.border_color==Color.BLACK and overview.markers[0].selected_style.border_width_left==3)
	game.view.high_contrast=false
	person=game.world.citizens[0];person.edge_x=person.x+1;person.edge_y=person.y;person.progress=5000
	changed=game.world.canonical_hash();game.view._process(0)
	var actual: Vector2=Vector2.ZERO
	var shown: Array=game.view.actors.filter(func(actor:Sprite2D)->bool:return actor.visible)
	for actor in shown: actual+=game.view.tile_to_screen(actor.position/16.0)
	actual/=shown.size()
	check.call("MARKER/UI_pin_follows_the_displayed_fractional_movement",shown.size()==4 and overview.groups[0].center.is_equal_approx(actual) and game.world.canonical_hash()==changed,str({"pin":overview.groups[0].center,"visible_actor_mean":actual,"visible_actors":shown.size(),"pooled_actors":game.view.actors.size()}))
	person.progress=0;person.edge_x=person.x
	for index in range(4):
		var citizen: Dictionary=game.world.citizens[index]
		citizen[["death_recorded","departed","carried_by","away"][index]]=1 if index==2 else true
	changed=game.world.canonical_hash();game.view._process(0)
	check.call("MARKER/UI_hidden_dead_departed_carried_and_offsite_people_have_no_pin_or_target",overview.groups.is_empty() and overview.points.is_empty() and overview.markers.all(func(m:ResidentMarkers.Marker)->bool:return not m.visible) and game.world.canonical_hash()==changed)
	game.close_inspector();game.close_sheet();game._replace_world(twenty());game.view.tile_size=2;game.view._process(0)
	check.call("MARKER/UI_twenty_resident_fixture_obeys_world_invariants",game.world.citizens.size()==20 and game.world.invariant_errors().is_empty())
	changed=game.world.canonical_hash()
	check.call("MARKER/UI_overview_represents_every_resident_with_a_bounded_pool",all_ids(game.view).size()==20 and overview.markers.size()<=20 and overview.groups.all(func(g:Dictionary)->bool:return maxf(g.bounds.size.x,g.bounds.size.y)<=ResidentMarkers.MERGE_EXTENT) and game.world.canonical_hash()==changed)
	var grown: int=overview.markers.size();game._replace_world(ColonyTests.world());game.view.tile_size=2;game.view._process(0)
	check.call("MARKER/UI_campaign_adoption_reuses_nodes_and_releases_old_member_records",all_ids(game.view)==[1,2,3,4] and overview.markers.size()==grown and overview.groups.all(func(g:Dictionary)->bool:return g.people.all(func(p:Dictionary)->bool:return game.world.citizens.any(func(current:Dictionary)->bool:return is_same(current,p)))))
	game.view.zoom_at(8.0,game.view.size*0.5);game.view._process(0)
	check.call("MARKER/UI_normal_zoom_restores_sprite_hit_positions_without_pins",game.view.tile_size==16 and not overview.visible and overview.points.is_empty() and game.view.resident_selection_point(game.world.citizens[0])==game.view.tile_to_screen(game.view.citizen_point(game.world.citizens[0])))
	game.show_sheet("People",ColonyText.sheet_key("People"))
	check.call("MARKER/UI_people_help_explains_group_counts_and_care_shapes",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("portrait pins") and n.text.contains("group size") and n.text.contains("cross")))
	game.close_inspector();game.close_sheet();game.view.tile_size=2;game.view.center_camera(Vector2(66,63));game.view._process(0)
	if DisplayServer.get_name()!="headless":
		await tree.process_frame;await tree.process_frame;await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("res://reports/resident-overview-far.png")
	var old_size: Vector2i=tree.root.size;var old_scale: float=game.text_scale
	for viewport in [Vector2i(390,844),Vector2i(640,360)]:
		tree.root.size=viewport;game.size=Vector2(viewport);game.text_scale=1.5;game._build_theme();game._layout()
		await tree.process_frame;await tree.process_frame
		game.view.center_camera(Vector2(66,63));game.view._process(0)
		var marker: ResidentMarkers.Marker=overview.markers[0]
		check.call("MARKER/UI_%dx%d_large_text_keeps_map_pin_clear_of_speed_controls" % [viewport.x,viewport.y],marker.visible and marker.face.size==Vector2(24,24) and not marker.get_global_rect().intersects(game.speeds.get_global_rect()) and game.world.pending_commands.is_empty())
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			tree.root.get_texture().get_image().save_png("res://reports/resident-overview-%dx%d-150.png" % [viewport.x,viewport.y])
	tree.root.size=old_size;game.size=Vector2(old_size);game.text_scale=old_scale;game._build_theme();game._layout()
	game.view.tile_size=32;game.view._update_transform()
