class_name ColonyEnvironment
extends RefCounted
## Presentation-only chunks, pooled buildings, room roofs and full-bright cues.
const FLOORS: Array[String] = ["wood_floor","stone_path","bridge"]
const GLOW: Texture2D = preload("res://assets/exported/environment/warm_glow.png")
var view: Node
var world: ColonyWorld
var props: Dictionary = {}
var resource_rows: Dictionary = {}
var ground_chunks: Dictionary = {}
var resource_index: Dictionary = {}
var indexed_resources: Array = []
var indexed_count: int = -1
var resource_groups_valid: bool = false
var resource_signature: PackedInt64Array = PackedInt64Array()
var resource_breaks: Array[int] = []
var last_tick: int = -1
var last_chunks: Rect2i = Rect2i()
var ground_root: Node2D
var static_water: TileMapLayer
var animated_water: TileMapLayer
var roof_layer: Node2D
var feedback_layer: Node2D
var warm_layer: Node2D
var tint: Color = Color.WHITE
var selected_bounds: Rect2 = Rect2()
var revealed_rooms: Dictionary = {}
var roof_tiles: Dictionary = {}
var visual_clock: float = 0.0
var active_jobs: Array = []
var escrow: Dictionary = {}
var heat_points: Array[Vector2] = []
var weather_clock: float = 0.0
var station_outputs: Dictionary = {}

func _init(owner: Node) -> void:
	view=owner;world=view.world
	var tiles: TileSet = TileSet.new();tiles.tile_size=Vector2i(16,16)
	var atlas: TileSetAtlasSource = TileSetAtlasSource.new();atlas.texture=EnvironmentArt.ATLAS;atlas.texture_region_size=Vector2i(16,16);atlas.separation=Vector2i(2,2)
	for index in range(17):
		if index!=10: atlas.create_tile(Vector2i(index,0))
	atlas.set_tile_animation_columns(Vector2i(9,0),2);atlas.set_tile_animation_frames_count(Vector2i(9,0),2)
	atlas.set_tile_animation_frame_duration(Vector2i(9,0),0,0.8);atlas.set_tile_animation_frame_duration(Vector2i(9,0),1,0.8)
	tiles.add_source(atlas,0)
	var still: TileSetAtlasSource = TileSetAtlasSource.new();still.texture=EnvironmentArt.ATLAS;still.texture_region_size=Vector2i(16,16);still.margins=Vector2i(162,0);still.create_tile(Vector2i.ZERO);tiles.add_source(still,1)
	view.terrain.tile_set=tiles
	static_water=TileMapLayer.new();static_water.tile_set=tiles;view.ground.add_child(static_water)
	animated_water=TileMapLayer.new();animated_water.tile_set=tiles;view.ground.add_child(animated_water)
	ground_root=Node2D.new();ground_root.name="GroundChunks";view.ground.add_child(ground_root)
	warm_layer=Node2D.new();view.ground.add_child(warm_layer);warm_layer.draw.connect(_draw_warmth)
	var additive: CanvasItemMaterial = CanvasItemMaterial.new();additive.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD;warm_layer.material=additive
	roof_layer=Node2D.new();roof_layer.name="RoomRoofs";view.add_child(roof_layer);roof_layer.draw.connect(_draw_roofs)
	feedback_layer=Node2D.new();feedback_layer.name="MapCues";view.add_child(feedback_layer);feedback_layer.draw.connect(_draw_feedback)

func refresh_terrain() -> void:
	if world!=view.world: _reset_world();return
	view.terrain.clear();static_water.clear();animated_water.clear()
	for y in range(128):
		for x in range(128):
			var point: Vector2i = Vector2i(x,y)
			var water: bool = world.terrain_state.elevation[y*128+x]==0 if world.generator_version>0 else PrototypeWorld.is_water(point)
			if water:
				static_water.set_cell(point,1,Vector2i.ZERO);animated_water.set_cell(point,0,Vector2i(9,0));continue
			var pattern: int = x*374761393+y*668265263+(world.seed%65536)*2654435761
			pattern=((pattern^(pattern>>13))&0x7fffffff)*1274126177
			pattern=pattern^(pattern>>16)
			var variant: int = posmod(pattern,2)
			if posmod(pattern>>4,29)==0: variant=2
			var cell: int = variant
			if world.soil_fertility(point)==750: cell=3+(x+y)%3
			elif world.soil_fertility(point)==1250: cell=6+(x+y)%3
			var path: bool = world.terrain_state.paths.has(point) if world.generator_version>0 else x==66 or y in [63,64]
			if path: cell=11+(x+y)%3
			view.terrain.set_cell(point,0,Vector2i(cell,0))
	last_tick=-1;indexed_count=-1

func _reset_world() -> void:
	for collection in [props,resource_rows,ground_chunks]:
		for node in collection.values(): node.queue_free()
		collection.clear()
	world=view.world;resource_index.clear();indexed_resources=[];indexed_count=-1;last_tick=-1;last_chunks=Rect2i();revealed_rooms.clear();roof_tiles.clear()
	view.extra_order_changed=true;refresh_terrain()

func visible_chunks() -> Rect2i:
	var extent: Vector2 = view.size/(view.tile_size*2.0)+Vector2.ONE*3
	var center: Vector2 = view.camera_center()
	var start: Vector2i = Vector2i(floori((center.x-extent.x)/16),floori((center.y-extent.y)/16)).clamp(Vector2i.ZERO,Vector2i(7,7))
	var end: Vector2i = Vector2i(floori((center.x+extent.x)/16),floori((center.y+extent.y)/16)).clamp(Vector2i.ZERO,Vector2i(7,7))
	return Rect2i(start,end-start+Vector2i.ONE)

func update(delta: float) -> void:
	if world!=view.world: _reset_world()
	if indexed_count!=world.resources.size() or not is_same(indexed_resources,world.resources): _index_resources()
	visual_clock=0.0 if view.reduced_motion else fmod(visual_clock+delta*minf(4.0*view.simulation_speed,10.0),120.0)
	weather_clock=0.0 if view.reduced_motion else weather_clock+maxf(0.0,delta)
	tint=EnvironmentArt.night_color(world.tick)
	view.terrain.modulate=tint;static_water.modulate=tint;animated_water.modulate=tint
	static_water.visible=view.quality=="Battery" or view.reduced_motion;animated_water.visible=not static_water.visible
	selected_bounds=Rect2()
	for actor in view.actors:
		if actor.get_meta("world_id",0)==view.selected_id and actor.visible: selected_bounds=Rect2(actor.position+actor.get_rect().position,actor.get_rect().size);break
	var chunks: Rect2i = visible_chunks()
	var changed: bool = last_tick!=world.tick or last_chunks!=chunks
	if changed:
		active_jobs=world.unfinished_jobs();_refresh_props();_refresh_resources(chunks);_refresh_ground(chunks)
		last_tick=world.tick;last_chunks=chunks
	_update_rooms()
	for row in resource_rows.values():
		if row.tint!=tint or row.selected_bounds!=selected_bounds:
			row.tint=tint;row.selected_bounds=selected_bounds;row.queue_redraw()
	_update_props()
	for actor in view.actors: actor.self_modulate=tint
	for actor in view.extra_actors.values(): actor.self_modulate=tint
	warm_layer.queue_redraw();roof_layer.queue_redraw();feedback_layer.queue_redraw()

func _index_resources() -> void:
	resource_groups_valid=false
	resource_index.clear();indexed_resources=world.resources;indexed_count=world.resources.size()
	for resource in world.resources:
		var key: Vector2i = Vector2i(resource.x/16,resource.y/16)
		if not resource_index.has(key): resource_index[key]=[]
		resource_index[key].append(resource)
	last_tick=-1

func _refresh_props() -> void:
	var wanted: Dictionary = {}
	var walls: Dictionary = {}
	for structure in world.structures:
		if structure.health>0 and structure.definition in ["wood_wall","stone_wall","palisade","fence","door","pen_gate"]: walls[Vector2i(structure.x,structure.y)]=true
	for structure in world.structures:
		if structure.definition in FLOORS and structure.health>0: continue
		wanted[structure.id]=true
		if not props.has(structure.id):
			var prop: EnvironmentProp = EnvironmentProp.new();prop.name="Building_%d" % structure.id;prop.record=structure;prop.renderer=view
			prop.set_meta("world_id",structure.id);prop.set_meta("role","building")
			view.actor_layer.add_child(prop);props[structure.id]=prop;view.extra_order_changed=true
		props[structure.id].record=structure
		var mask: int = 0
		for index in range(4):
			if walls.has(Vector2i(structure.x,structure.y)+[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT][index]): mask|=1<<index
		props[structure.id].wall_mask=mask
	for id in props.keys():
		if not wanted.has(id): props[id].queue_free();props.erase(id);view.extra_order_changed=true

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
	# Live records still redraw every changed tick. Membership, locations and
	# depth partitions usually stay fixed, so avoid their sort/group allocations.
	# Index refresh/world adoption invalidates this even for equal replacement IDs.
	var signature: PackedInt64Array=PackedInt64Array()
	for resource in ordered:
		signature.append(resource.id);signature.append(resource.x);signature.append(resource.y)
	if resource_groups_valid and signature==resource_signature and breaks==resource_breaks:
		for row in resource_rows.values():
			row.tint=tint;row.selected_bounds=selected_bounds;row.queue_redraw()
		return
	resource_signature=signature;resource_breaks=breaks;resource_groups_valid=true
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

func _push(commands: Dictionary, point: Vector2i, semantic: String, destination: Rect2, color: Color) -> void:
	var key: Vector2i = Vector2i(point.x/16,point.y/16)
	if not commands.has(key): return
	destination.position-=Vector2(key)*256.0
	commands[key].append([semantic,destination,color])

func _refresh_ground(chunks: Rect2i) -> void:
	var commands: Dictionary = {}
	for y in range(chunks.position.y,chunks.end.y):
		for x in range(chunks.position.x,chunks.end.x): commands[Vector2i(x,y)]=[]
	for store in world.stores:
		for point in store.tiles: _push(commands,point,"zone",Rect2(Vector2(point)*16,Vector2.ONE*16),Color(0.4,0.5,0.5,0.12))
	for pen in world.domestic_state.pens:
		for point in pen.tiles: _push(commands,point,"zone",Rect2(Vector2(point)*16,Vector2.ONE*16),Color(0.7,0.7,0.45,0.12))
	for structure in world.structures:
		if structure.health<=0 or structure.definition not in FLOORS: continue
		var point: Vector2i = Vector2i(structure.x,structure.y)
		var semantic: String = "building/%s/%d" % [structure.definition,structure.rotation]
		var rectangle: Rect2 = EnvironmentArt.rectangle(semantic)
		_push(commands,point,semantic,Rect2(Vector2(point)*16-Vector2(0,12),rectangle.size),tint)
	for field in world.fields:
		var point: Vector2i = Vector2i(field.x,field.y)
		var semantic: String = "crop/%s/%d" % [field.crop,EnvironmentArt.crop_stage(field,world.definitions.crops[field.crop])]
		_push(commands,point,semantic,Rect2(Vector2(point)*16,Vector2.ONE*16),tint*Color(1,1,1,1.0 if field.prepared else 0.25))
	var carts: Dictionary = {}
	for structure in world.structures:
		if structure.definition=="supply_cart": carts[structure.id]=true
	var piles: Dictionary = {};var outputs: Dictionary = {};escrow.clear();station_outputs.clear()
	for stack in world.nonempty_stacks():
		if stack.location=="escrow": escrow[stack.owner]=escrow.get(stack.owner,0)+stack.count
		if stack.location=="carry" or (stack.location=="store" and carts.has(stack.owner)): continue
		if stack.location=="output" and props.has(stack.owner) and props[stack.owner].record.health>0:
			if not outputs.has(stack.owner): outputs[stack.owner]={}
			outputs[stack.owner][stack.item]=outputs[stack.owner].get(stack.item,0)+stack.count;continue
		if stack.location=="expedition_cargo" and world.find(world.region_state.trips,stack.owner).get("state") not in ["Preparing","Ready","Unloading"]: continue
		var point: Vector2i = Vector2i(stack.x,stack.y)
		if not piles.has(point): piles[point]={}
		piles[point][stack.item]=piles[point].get(stack.item,0)+stack.count
	for owner in outputs:
		var items: Array = outputs[owner].keys()
		items.sort_custom(func(a:String,b:String)->bool:return outputs[owner][a]>outputs[owner][b] if outputs[owner][a]!=outputs[owner][b] else a<b)
		var item: String = items[0]
		station_outputs[owner]=[item,EnvironmentArt.pile_tier(outputs[owner][item],world.definitions.items[item].stack_limit)]
	for point in piles:
		var items: Array = piles[point].keys();items.sort()
		for index in range(mini(4,items.size())):
			var item: String = items[index]
			var tier: int = EnvironmentArt.pile_tier(piles[point][item],world.definitions.items[item].stack_limit)
			var destination: Vector2 = Vector2(point)*16+Vector2(index%2*3, -8-index/2*3)
			_push(commands,point,"item/%s/%d" % [item,tier],Rect2(destination,Vector2(16,24)),tint)
	for key in commands:
		if not ground_chunks.has(key):
			var chunk: EnvironmentGroundChunk = EnvironmentGroundChunk.new();chunk.position=Vector2(key)*256;chunk.renderer=view
			ground_root.add_child(chunk);ground_chunks[key]=chunk
		ground_chunks[key].set_commands(commands[key])
	for key in ground_chunks.keys():
		if not commands.has(key): ground_chunks[key].queue_free();ground_chunks.erase(key)

func _update_rooms() -> void:
	world.roofed(Vector2i(64,64));roof_tiles=world.room_tiles;revealed_rooms.clear()
	for person in world.citizens:
		if person.id==view.selected_id:
			var point: Vector2i = Vector2i(person.x,person.y)
			if roof_tiles.has(point): revealed_rooms[roof_tiles[point]]=true
	for point in view.inspected_tiles:
		if roof_tiles.has(point): revealed_rooms[roof_tiles[point]]=true
	for actor in view.extra_actors.values():
		if actor.record.id!=view.inspected_object: continue
		var point: Vector2i = Vector2i(actor.position/16.0)
		if roof_tiles.has(point): revealed_rooms[roof_tiles[point]]=true
		selected_bounds=Rect2(actor.position+actor.get_rect().position,actor.get_rect().size)

func _update_props() -> void:
	var hot: Dictionary = {};var moving: Dictionary = {}
	heat_points.clear()
	for job in active_jobs:
		if job.state=="Working" and job.kind in ["cook","craft"]: hot[job.target]=true
		if job.kind=="cart_move" and job.worker>0 and job.state=="Working" and job.memo.phase=="push":
			var worker: Dictionary = world.find(world.citizens,job.worker)
			moving[job.target]=Vector2(worker.edge_x-worker.x,worker.edge_y-worker.y)*float(worker.progress)/10000.0
	var frame: int = 0 if view.quality=="Battery" or view.reduced_motion else int(visual_clock)%2
	for prop in props.values():
		var structure: Dictionary = prop.record
		var reveal: bool = view.rooms_overlay or revealed_rooms.has(-structure.id)
		var burning: bool = structure.definition=="hearth" and structure.fuel>0
		if structure.definition in ["charcoal_kiln","brick_kiln","smelter","smithy"] and hot.has(structure.id): burning=true
		if structure.definition=="beacon" and world.charter_state.ceremony.get("state") in ["Active","Complete"]: burning=true
		var inside: bool = false
		if selected_bounds.has_area():
			var definition: Dictionary = world.definitions.buildings[structure.definition]
			var footprint: Vector2 = Vector2(definition.width,definition.height) if structure.rotation%2==0 else Vector2(definition.height,definition.width)
			inside=Rect2(Vector2(structure.x,structure.y)*16,footprint*16).has_point(selected_bounds.get_center()+Vector2(0,10))
		var output_item: String = "";var output_tier: int = 0
		if station_outputs.has(structure.id): output_item=station_outputs[structure.id][0];output_tier=station_outputs[structure.id][1]
		prop.sync(world,structure,tint,reveal,inside,burning,frame,moving.get(structure.id,Vector2.ZERO),output_item,output_tier)
		if burning and structure.definition=="hearth": heat_points.append(Vector2(structure.x+1,structure.y+1)*16)
		prop.visible=Rect2(Vector2.ZERO,view.size).grow(view.tile_size*6).has_point(view.tile_to_screen(prop.position/16.0))
	for fire in ColonyFire.active(world):
		for point in ColonyFire.footprint(world,fire): heat_points.append((Vector2(point)+Vector2.ONE*0.5)*16)

func _draw_warmth() -> void:
	var started: int = Time.get_ticks_usec();var shown: int = 0
	for point in heat_points:
		if not Rect2(Vector2.ZERO,view.size).grow(view.tile_size*2).has_point(view.tile_to_screen(point/16.0)): continue
		warm_layer.draw_texture_rect(GLOW,Rect2(point-Vector2.ONE*24,Vector2.ONE*48),false,Color(1,1,1,0.6));shown+=1
		if shown>=16: break
	view.account_draw(Time.get_ticks_usec()-started)

func _draw_roofs() -> void:
	if not view.rooms_overlay: return
	var started: int = Time.get_ticks_usec()
	for point in roof_tiles:
		var room: int = roof_tiles[point]
		if room<0: continue # Barn's own roof uses its dedicated atlas layer.
		var rectangle: Rect2 = Rect2(view.tile_to_screen(Vector2(point)),Vector2.ONE*view.tile_size)
		if not rectangle.intersects(Rect2(Vector2.ZERO,view.size)): continue
		var corners: Array[Vector2] = [rectangle.position,rectangle.position+Vector2(rectangle.size.x,0),rectangle.end,rectangle.position+Vector2(0,rectangle.size.y)]
		for index in range(4):
			if roof_tiles.get(point+[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT][index],-1)!=room:
				roof_layer.draw_line(corners[index],corners[(index+1)%4],Color("E9BA67"),2)
	view.account_draw(Time.get_ticks_usec()-started)

func _draw_feedback() -> void:
	var started: int = Time.get_ticks_usec()
	_draw_weather()
	view._draw_feedback(feedback_layer)
	for source in ColonyDanger.sources(world):
		var center: Vector2 = view.tile_to_screen(Vector2(source)+Vector2.ONE*0.5);var radius: float = view.tile_size*8
		feedback_layer.draw_polyline(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0),center+Vector2(0,-radius)]),Color("E9BA67"),2)
	for job in active_jobs:
		if job.kind=="gather": view._draw_gather_mark(Vector2(job.x,job.y),Color("E9BA67"),feedback_layer)
		elif job.kind=="hunt":
			var animal: Dictionary = world.find(world.wildlife_state.animals,job.target)
			if not animal.is_empty() and animal.health>0: view._draw_gather_mark(AnimalSprite.route_point(animal)-Vector2.ONE*0.5,Color("E9BA67"),feedback_layer)
		elif job.kind=="build":
			for point in world.footprint(job):
				var rectangle: Rect2 = Rect2(view.tile_to_screen(Vector2(point)),Vector2.ONE*view.tile_size)
				if not rectangle.intersects(Rect2(Vector2.ZERO,view.size)): continue
				feedback_layer.draw_rect(rectangle,Color(0.91,0.73,0.4,0.16))
				for pair in [[rectangle.position,Vector2(rectangle.end.x,rectangle.position.y)],[Vector2(rectangle.end.x,rectangle.position.y),rectangle.end],[rectangle.end,Vector2(rectangle.position.x,rectangle.end.y)],[Vector2(rectangle.position.x,rectangle.end.y),rectangle.position]]:
					feedback_layer.draw_dashed_line(pair[0],pair[1],Color("E9BA67"),1.5,5)
			var top: Vector2 = view.tile_to_screen(Vector2(job.x,job.y))
			feedback_layer.draw_rect(Rect2(top,Vector2(view.tile_size,4)),Color("263C3B"))
			feedback_layer.draw_rect(Rect2(top,Vector2(view.tile_size*float(job.work)/job.required,4)),Color("F3E8CC"))
			if escrow.get(job.id,0)>0: feedback_layer.draw_rect(Rect2(top+Vector2(2,7),Vector2(7,6)),Color("B96C50"))
		elif job.kind=="move_furniture":
			for point in ColonyMaintenance.move_footprint(world,job): feedback_layer.draw_rect(Rect2(view.tile_to_screen(Vector2(point)),Vector2.ONE*view.tile_size).grow(-1),Color("E9BA67"),false,2)
	for field in world.fields:
		if field.id==view.inspected_object and field.ripe_tick>0:
			var point: Vector2 = view.tile_to_screen(Vector2(field.x+0.5,field.y+0.2))
			feedback_layer.draw_arc(point,5,PI,TAU,8,Color("F3E8CC"),2);feedback_layer.draw_rect(Rect2(point+Vector2(-5,0),Vector2(10,5)),Color("E9BA67"))
	var frame: int = 0 if view.quality=="Battery" or view.reduced_motion else int(visual_clock)%2
	for fire in ColonyFire.active(world):
		for tile in ColonyFire.footprint(world,fire):
			var point: Vector2 = view.tile_to_screen(Vector2(tile)+Vector2(0,1))
			var destination: Rect2 = Rect2(point-Vector2(0,view.tile_size*1.5),Vector2(view.tile_size,view.tile_size*1.5))
			if destination.intersects(Rect2(Vector2.ZERO,view.size)): feedback_layer.draw_texture_rect_region(EnvironmentArt.ATLAS,destination,EnvironmentArt.rectangle("effect/flame/%d" % frame))
	for enemy in world.defense_state.enemies:
		if enemy.state=="Gone": continue
		var point: Vector2 = view.tile_to_screen(AnimalSprite.route_point(enemy))-Vector2(0,view.tile_size*26.0/16.0)
		if not Rect2(Vector2.ZERO,view.size).grow(view.tile_size).has_point(point): continue
		var unit: float = view.tile_size/16.0
		if ColonyDefense.enemy_active(enemy):
			feedback_layer.draw_polyline(PackedVector2Array([point+Vector2(0,-3)*unit,point+Vector2(3,0)*unit,point+Vector2(0,3)*unit,point+Vector2(-3,0)*unit,point+Vector2(0,-3)*unit]),Color("F3E8CC"),unit)
		else:
			feedback_layer.draw_line(point+Vector2(-3,0)*unit,point+Vector2(3,0)*unit,Color("F3E8CC"),2*unit)
			feedback_layer.draw_line(point+Vector2(0,-3)*unit,point+Vector2(0,3)*unit,Color("F3E8CC"),2*unit)
	view.account_draw(Time.get_ticks_usec()-started)

func _draw_weather() -> void:
	if view.quality=="Battery" or view.reduced_motion or world.weather not in ["rain","flood","snow","cold_snap"]: return
	var snow: bool = world.weather in ["snow","cold_snap"]
	# Fixed low-discrepancy positions use a presentation clock, not world RNG.
	for index in range(48):
		var x: float = fposmod(index*0.61803398875*view.size.x+weather_clock*(8 if snow else -22),view.size.x)
		var y: float = fposmod(index*0.41421356237*view.size.y+weather_clock*(24 if snow else 150),view.size.y)
		if snow: feedback_layer.draw_circle(Vector2(x,y),1.0,Color(0.95,0.91,0.8,0.45))
		else: feedback_layer.draw_line(Vector2(x,y),Vector2(x+2,y-6),Color(0.65,0.8,0.85,0.3),1)
