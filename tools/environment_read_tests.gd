class_name EnvironmentReadTests
extends RefCounted
## Complete resource refresh from 603c1d0, independent of membership reuse.
class OriginalEnvironment extends ColonyEnvironment:
	func _init(owner: Node) -> void: super(owner)
	func _refresh_resources(chunks: Rect2i) -> void:
		var breaks: Array[int] = []
		for actor in view.actors: breaks.append(actor.get_meta("world_id",0))
		for actor in view.extra_actors.values(): breaks.append(actor.get_meta("world_id",0))
		for id in props: breaks.append(id)
		breaks.sort()
		var groups: Dictionary = {}
		var ordered: Array = []
		for y in range(chunks.position.y,chunks.end.y):
			for x in range(chunks.position.x,chunks.end.x):
				for resource in resource_index.get(Vector2i(x,y),[]):
					if resource.remaining<=0 and resource.definition!="tree": continue
					ordered.append(resource)
		ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.y<b.y if a.y!=b.y else a.id<b.id)
		var previous: String = "";var group_key: String = ""
		for resource in ordered:
			var partition: int = breaks.bsearch(resource.id)
			var base: String = "%d_%d_%d_%d" % [resource.x/16,resource.y/16,resource.y,partition]
			if base!=previous: group_key=base+"_%d" % resource.id;groups[group_key]=[];previous=base
			groups[group_key].append(resource)
		for key in groups:
			var records: Array = groups[key];records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.id<b.id)
			if not resource_rows.has(key):
				var row: EnvironmentResourceRow = EnvironmentResourceRow.new();row.name="ResourceRow_"+key;row.world=world;row.renderer=view
				row.position=Vector2(0,(records[0].y+1)*16.0);row.set_meta("world_id",records[0].id);row.set_meta("role","resource")
				view.actor_layer.add_child(row);resource_rows[key]=row;view.extra_order_changed=true
			var row: EnvironmentResourceRow = resource_rows[key]
			if row.get_meta("world_id")!=records[0].id: row.set_meta("world_id",records[0].id);view.extra_order_changed=true
			row.records=records;row.tint=tint;row.selected_bounds=selected_bounds;row.queue_redraw()
		for key in resource_rows.keys():
			if not groups.has(key): resource_rows[key].queue_free();resource_rows.erase(key);view.extra_order_changed=true

class OriginalView extends WorldView:
	func _make_environment() -> ColonyEnvironment:
		return OriginalEnvironment.new(self)

static func make_view(tree: SceneTree, world: ColonyWorld, original: bool) -> WorldView:
	var viewport: SubViewport=SubViewport.new();viewport.size=Vector2i(480,320)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var view: WorldView=OriginalView.new() if original else WorldView.new()
	view.set_process(false);viewport.add_child(view)
	view.size=Vector2(480,320);view.setup(world);view.tile_size=2
	view.reduced_motion=true;view.quality="Battery";view.center_camera(Vector2(66,63))
	return view

static func rows(view: WorldView) -> Dictionary:
	var result: Dictionary={}
	# Compare directly to the replaced table, independently of simulation lookup
	# caches (ordinary world adoption clears those; this renderer test swaps one).
	var actual: Dictionary={}
	for current in view.world.resources: actual[current.id]=current
	for key in view.environment.resource_rows:
		var row: EnvironmentResourceRow=view.environment.resource_rows[key]
		var current_refs: bool=row.world==view.world
		for record in row.records: current_refs=current_refs and is_same(record,actual.get(record.id,{}))
		result[key]={"ids":row.records.map(func(r:Dictionary)->int:return r.id),"position":row.position,"world_id":row.get_meta("world_id"),"tint":row.tint,"selected":row.selected_bounds,"current_refs":current_refs}
	return result

static func compare(tree: SceneTree, fast: WorldView, original: WorldView, stage: String, check: Callable) -> void:
	var before: String=fast.world.canonical_hash()
	fast._process(0);original._process(0)
	await tree.process_frame;await tree.process_frame
	var a: Dictionary=rows(fast);var b: Dictionary=rows(original)
	check.call("ENV_READ/UI_%s_rows_depth_references_and_state_match" % stage,a==b and a.values().all(func(row:Dictionary)->bool:return row.current_refs) and before==fast.world.canonical_hash())
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var image_a: Image=fast.get_viewport().get_texture().get_image()
	var image_b: Image=original.get_viewport().get_texture().get_image()
	var pixels: bool=image_a.get_size()==Vector2i(480,320) and image_a.get_data()==image_b.get_data() and image_a.get_pixel(240,160).get_luminance()>0.01
	if not pixels:
		image_a.save_png("res://reports/environment-read-%s-fast.png" % stage)
		image_b.save_png("res://reports/environment-read-%s-original.png" % stage)
	check.call("ENV_READ/UI_%s_rendered_pixels_match_full_refresh" % stage,pixels)

static func run(previous: GameSession, check: Callable) -> void:
	var tree: SceneTree=previous.get_tree()
	var processing: bool=previous.is_processing();var view_processing: bool=previous.view.is_processing()
	previous.set_process(false);previous.view.set_process(false)
	var world: ColonyWorld=ColonyTests.world()
	var error: String=ColonyGeneration.configure(world,104729,"meadow_reach")
	check.call("ENV_READ/UI_generated_resource_fixture_is_valid",error.is_empty() and world.invariant_errors().is_empty())
	if not error.is_empty(): previous.set_process(processing);previous.view.set_process(view_processing);return
	var fast: WorldView=make_view(tree,world,false);var original: WorldView=make_view(tree,world,true)
	await compare(tree,fast,original,"initial_far",check)
	world.tick+=1
	await compare(tree,fast,original,"unchanged_membership_next_tick",check)
	fast.selected_id=1;original.selected_id=1
	await compare(tree,fast,original,"selection_without_tick",check)
	var resource: Dictionary=world.resources.filter(func(r:Dictionary)->bool:return r.definition!="tree")[0]
	resource.remaining=0;world.tick+=1
	await compare(tree,fast,original,"depleted_resource",check)
	var resource_tree: Dictionary=world.resources.filter(func(r:Dictionary)->bool:return r.definition=="tree")[0]
	resource_tree.remaining=0;world.nature_state.trees[resource_tree.id]={"planted":true,"age":40000,"cleared":false};world.navigation_dirty=true;world.tick+=1
	await compare(tree,fast,original,"live_sapling_stage",check)
	resource_tree.remaining=8;world.nature_state.trees[resource_tree.id]={"planted":false,"age":57600,"cleared":false};world.navigation_dirty=true;world.tick+=1
	await compare(tree,fast,original,"mature_tree_same_membership",check)
	world._structure("hearth",Vector2i(70,64),0);world.tick+=1
	await compare(tree,fast,original,"new_actor_depth_breakpoint",check)
	for view in [fast,original]: view.tile_size=16;view.center_camera(Vector2(10,10))
	await compare(tree,fast,original,"camera_chunk_change",check)
	for view in [fast,original]: view.tile_size=2;view.center_camera(Vector2(66,63))
	world.resources=world.resources.duplicate(true)
	await compare(tree,fast,original,"equal_id_replacement_records",check)
	world.tick=7200
	await compare(tree,fast,original,"night_tint_with_cached_membership",check)
	world=ColonyTests.world()
	for view in [fast,original]: view.world=world;view.refresh_terrain()
	await compare(tree,fast,original,"new_campaign_reused_ids",check)
	fast.get_parent().queue_free();original.get_parent().queue_free()
	await tree.process_frame;await tree.process_frame
	previous.set_process(processing);previous.view.set_process(view_processing)
