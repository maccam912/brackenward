class_name ColonyGeneration
extends RefCounted
const VERSION: int = 1
const SITES: Dictionary = {
 "meadow_reach":{"weights":[15,65,20],"trees":22,"flood":4,"extra":"","extra_count":0},
 "pine_shelf":{"weights":[30,60,10],"trees":36,"flood":3,"extra":"stone_node","extra_count":4},
 "reed_bend":{"weights":[10,45,45],"trees":18,"flood":6,"extra":"clay_bank","extra_count":3}}
const COUNTS: Dictionary = {"berry_bush":10,"herb_patch":6,"mushroom_patch":6,"tree":30,"stone_node":4,"clay_bank":3,"iron_seam":3}
const WILDLIFE: Dictionary = {"hare":6,"deer":4,"boar":2,"marsh_goose":4}

static func empty_state() -> Dictionary:
 return {"elevation":[],"fertility":[],"paths":[],"bridges":[],"starter_field":[],"habitats":{},"transform":0,"attempt":0,"fallback":false,"diagnostics":[]}

static func configure(world: ColonyWorld, entered_seed: int, site: String) -> String:
 if not SITES.has(site) or entered_seed < 0 or entered_seed > 4294967295: return "Unknown site or invalid 32-bit seed"
 world.seed = entered_seed; world.site_id = site; world.generator_version = VERSION
 var failures: Array = []
 for attempt in range(33):
  var effective: int = entered_seed
  if attempt > 0:
   var digest: PackedByteArray = ("%d|attempt|%d" % [entered_seed,attempt]).sha256_buffer()
   effective = (int(digest[0])<<24)|(int(digest[1])<<16)|(int(digest[2])<<8)|int(digest[3])
  var generated: Dictionary = _generate(world,effective,site,attempt == 32)
  generated.state.attempt = attempt; generated.state.diagnostics = failures.duplicate()
  var errors: Array = validate_map(generated)
  if not errors.is_empty(): failures.append("Attempt %d: %s" % [attempt,", ".join(errors)]); continue
  world.terrain_state = generated.state
  world.resources.clear()
  for r in generated.resources:
   world.resources.append({"id":world._id(),"definition":r.definition,"x":r.point.x,"y":r.point.y,"remaining":world.definitions.resources[r.definition].yield_count,"regrow_at":0})
  var transform: int = generated.state.transform
  for person in world.citizens:
   var point: Vector2i = transformed(Vector2i(person.x,person.y),transform)
   person.x = point.x; person.y = point.y; person.edge_x = point.x; person.edge_y = point.y
  for structure in world.structures:
   var cells: Array = world.footprint(structure).map(func(p:Vector2i)->Vector2i:return transformed(p,transform))
   structure.x = cells.map(func(p:Vector2i)->int:return p.x).min()
   structure.y = cells.map(func(p:Vector2i)->int:return p.y).min()
  for bridge in generated.state.bridges: world._structure("bridge",bridge,0)
  for stack in world.stacks:
   var point: Vector2i = transformed(Vector2i(stack.x,stack.y),transform)
   stack.x = point.x; stack.y = point.y
  for store in world.stores: store.tiles = store.tiles.map(func(p:Vector2i)->Vector2i:return transformed(p,transform))
  world.record_indexes.clear(); world.navigation_dirty = true; world.rooms_dirty = true
  world.flood_cache.clear(); world.flood_cache_valid = false
  ColonyWeather.initialize(world)
  ColonyWildlife.initialize(world)
  world.population_state=ColonyPopulation.initial_state(world.seed,world.generator_version,world.site_id)
  return ""
 return "Map generation failed: authored fallback did not satisfy " + ", ".join(failures)

static func transformed(point: Vector2i, transform: int) -> Vector2i:
 return Vector2i(127-point.x if transform in [1,3] else point.x,127-point.y if transform in [2,3] else point.y)

static func _rng(seed: int, site: String, name: String) -> ParkMiller:
 return ParkMiller.new(ParkMiller.derive(seed,VERSION,site,name))

static func _shuffle(items: Array, rng: ParkMiller) -> void:
 for index in range(items.size()-1,0,-1):
  var other: int = rng.bounded(index+1)
  var value: Variant = items[index]; items[index] = items[other]; items[other] = value

static func _generate(world: ColonyWorld, seed: int, site: String, fallback: bool) -> Dictionary:
 var state: Dictionary = empty_state()
 state.fallback = fallback
 state.elevation.resize(16384); state.elevation.fill(2)
 state.fertility.resize(16384); state.fertility.fill(1000)
 var ground: ParkMiller = _rng(seed,site,"ground")
 var spec: Dictionary = SITES[site]
 for cy in range(16):
  for cx in range(16):
   var draw: int = ground.bounded(100)
   var fertility: int = 750 if draw < spec.weights[0] else (1000 if draw < spec.weights[0]+spec.weights[1] else 1250)
   for y in range(cy*8,cy*8+8):
    for x in range(cx*8,cx*8+8): state.fertility[y*128+x] = 1000 if fallback else fertility
 var river: ParkMiller = _rng(seed,site,"river")
 var anchors: Array = []
 for index in range(9): anchors.append(33 if fallback else 28+river.bounded(13))
 for y in range(128):
  var center: int = (anchors[y/16]*(16-y%16)+anchors[y/16+1]*(y%16))/16
  var band: int = 4 if fallback else spec.flood
  for x in range(center-1-band,center+3+band): state.elevation[y*128+x] = 0 if x >= center-1 and x <= center+2 else 1
  for x in range(96,128): state.elevation[y*128+x] = 3 if x < 112 else 4
 if not fallback:
  var ridges: ParkMiller = _rng(seed,site,"ridges")
  for index in range(6):
   var center: Vector2i = Vector2i(84+ridges.bounded(27),12+ridges.bounded(104))
   var radius: int = 3+ridges.bounded(5)
   for y in range(maxi(0,center.y-radius),mini(128,center.y+radius+1)):
    for x in range(maxi(0,center.x-radius),mini(128,center.x+radius+1)):
     if absi(x-center.x)+absi(y-center.y) <= radius and state.elevation[y*128+x] == 2: state.elevation[y*128+x] = 3
 var reserved: Dictionary = {}
 for y in range(52,76):
  for x in range(56,84):
   reserved[Vector2i(x,y)] = true; state.elevation[y*128+x] = 2; state.fertility[y*128+x] = maxi(1000,state.fertility[y*128+x])
 for y in range(54,62):
  for x in range(74,82): state.fertility[y*128+x] = 1000; state.starter_field.append(Vector2i(x,y))
 var paths: Dictionary = {}
 for y in [63,64]:
  for x in range(128): paths[Vector2i(x,y)] = true
 for x in [66,67]:
  for y in range(128): paths[Vector2i(x,y)] = true
 for point in paths:
  state.paths.append(point); reserved[point] = true
  if state.elevation[point.y*128+point.x] == 0 and point.y == 63: state.bridges.append(point)
  for delta in ColonyNavigation.NEIGHBORS: reserved[point+delta] = true
 # Repair high transitions on the actual two-tile boundary trails.
 for y in [63,64]:
  for x in range(67,128):
   var index: int = y*128+x
   if state.elevation[index] > state.elevation[index-1]+1: state.elevation[index] = state.elevation[index-1]+1
 var result: Dictionary = {"state":state,"resources":[],"solid":{},"cart":Vector2i(66,63)}
 var distance: Dictionary = _reachable(result)
 var eligible: Array = []
 for y in range(128):
  for x in range(128):
   var point: Vector2i = Vector2i(x,y)
   if distance.get(point,10000) <= 24 and not reserved.has(point) and state.elevation[y*128+x] > 0: eligible.append(point)
 if fallback:
  eligible.sort_custom(func(a:Vector2i,b:Vector2i)->bool:
   var ar: int = maxi(absi(a.x-66),absi(a.y-63)); var br: int = maxi(absi(b.x-66),absi(b.y-63))
   return ar < br or (ar == br and a.y*128+a.x < b.y*128+b.x))
 else: _shuffle(eligible,_rng(seed,site,"resources"))
 var occupied: Dictionary = {}
 var work_tiles: Dictionary = {}
 for kind in COUNTS:
  for index in range(COUNTS[kind]):
   if not _place(result,eligible,kind,occupied,work_tiles,true): result["placement_failed"] = true
 if not spec.extra.is_empty():
  var extras: Array = distance.keys().filter(func(p:Vector2i)->bool:return distance[p] <= 40 and not reserved.has(p) and state.elevation[p.y*128+p.x] > 0)
  _shuffle(extras,_rng(seed,site,"extras"))
  for i in range(spec.extra_count):
   if not _place(result,extras,spec.extra,occupied,work_tiles,true): result["placement_failed"] = true
 var woodland: ParkMiller = _rng(seed,site,"woodland")
 if fallback:
  var extras: Array = []
  for y in range(128):
   for x in range(128):
    var p: Vector2i = Vector2i(x,y)
    if not reserved.has(p) and state.elevation[y*128+x] > 0: extras.append(p)
  extras.sort_custom(func(a:Vector2i,b:Vector2i)->bool:
   var ar: int = maxi(absi(a.x-66),absi(a.y-63)); var br: int = maxi(absi(b.x-66),absi(b.y-63))
   return ar < br or (ar == br and a.y*128+a.x < b.y*128+b.x))
  var added: int = 0
  for i in range(0,extras.size(),3):
   if _place(result,[extras[i]],"tree",occupied,work_tiles): added += 1
   if added >= 72: break
  for p in [Vector2i(101,24),Vector2i(104,27),Vector2i(100,31),Vector2i(105,34),Vector2i(102,91),Vector2i(105,94),Vector2i(100,98),Vector2i(104,101)]: _place(result,[p],"tree",occupied,work_tiles,true)
 else:
  for y in range(128):
   for x in range(128):
    var point: Vector2i = Vector2i(x,y)
    if reserved.has(point) or occupied.has(point) or work_tiles.has(point) or state.elevation[y*128+x] == 0: continue
    if woodland.bounded(100) < spec.trees: _place(result,[point],"tree",occupied,work_tiles)
  for cy in range(16):
   for cx in range(16):
    var candidates: Array = []
    for y in range(cy*8,cy*8+8):
     for x in range(cx*8,cx*8+8):
      var p: Vector2i = Vector2i(x,y)
      if not reserved.has(p) and distance.get(p,0) > 24 and state.elevation[y*128+x] > 0: candidates.append(p)
    _shuffle(candidates,woodland)
    _place(result,candidates,["berry_bush","herb_patch","mushroom_patch"][(cy*16+cx)%3],occupied,work_tiles)
  var upland: Array = distance.keys().filter(func(p:Vector2i)->bool:return state.elevation[p.y*128+p.x] >= 3 and not reserved.has(p))
  _shuffle(upland,_rng(seed,site,"deposits"))
  for kind in ["stone_node","clay_bank","iron_seam"]:
   for i in range(4 if kind == "stone_node" else 3): _place(result,upland,kind,occupied,work_tiles)
 distance = _reachable(result)
 var retained: Array = []
 for resource in result.resources:
  var reachable: bool = ColonyNavigation.NEIGHBORS.any(func(d:Vector2i)->bool:return distance.has(resource.point+d))
  if resource.guaranteed or reachable: retained.append(resource)
  else: result.solid.erase(resource.point)
 result.resources = retained
 distance = _reachable(result)
 var tree_tiles: Dictionary = {}
 for r in result.resources:
  if r.definition == "tree": tree_tiles[r.point] = true
 var spawn_used: Dictionary = {}
 for species in WILDLIFE:
  var habitats: Array = []
  for p in distance:
   if spawn_used.has(p) or occupied.has(p) or reserved.has(p) or distance[p] < (40 if species == "boar" else 30): continue
   var near_tree: bool = ColonyNavigation.NEIGHBORS.any(func(d:Vector2i)->bool:return tree_tiles.has(p+d))
   var near_water: bool = false
   for dx in range(-4,5):
    for dy in range(-4+absi(dx),5-absi(dx)):
     var tile: Vector2i = p+Vector2i(dx,dy)
     if ColonyWorld.inside(tile) and state.elevation[tile.y*128+tile.x] == 0: near_water = true
   if (species == "marsh_goose" and near_water) or (species == "boar" and near_tree and state.elevation[p.y*128+p.x] >= 3) or (species in ["hare","deer"] and near_tree and state.elevation[p.y*128+p.x] == 2): habitats.append(p)
  habitats.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return a.y*128+a.x < b.y*128+b.x)
  _shuffle(habitats,_rng(seed,site,"wildlife_"+species))
  state.habitats[species] = habitats.slice(0,WILDLIFE[species])
  for p in state.habitats[species]: spawn_used[p] = true
 var transform: int = _rng(seed,site,"transform").bounded(4)
 state.transform = transform
 var elevations: Array = state.elevation.duplicate(); var fertilities: Array = state.fertility.duplicate()
 for y in range(128):
  for x in range(128):
   var point: Vector2i = transformed(Vector2i(x,y),transform)
   state.elevation[point.y*128+point.x] = elevations[y*128+x]; state.fertility[point.y*128+point.x] = fertilities[y*128+x]
 for field in ["paths","bridges","starter_field"]: state[field] = state[field].map(func(p:Vector2i)->Vector2i:return transformed(p,transform))
 for species in state.habitats: state.habitats[species] = state.habitats[species].map(func(p:Vector2i)->Vector2i:return transformed(p,transform))
 result.solid.clear()
 for resource in result.resources:
  resource.point = transformed(resource.point,transform)
  if resource.definition in ["tree","stone_node","clay_bank","iron_seam"]: result.solid[resource.point] = true
 result.cart = transformed(result.cart,transform)
 return result

static func _place(map: Dictionary, candidates: Array, kind: String, occupied: Dictionary, work_tiles: Dictionary, guaranteed: bool = false) -> bool:
 for point in candidates:
  if occupied.has(point) or work_tiles.has(point) or map.state.elevation[point.y*128+point.x] == 0: continue
  var work: Vector2i = Vector2i(-1,-1)
  for delta in ColonyNavigation.NEIGHBORS:
   var neighbor: Vector2i = point+delta
   if ColonyWorld.inside(neighbor) and not map.solid.has(neighbor) and map.state.elevation[neighbor.y*128+neighbor.x] > 0: work = neighbor; break
  if work.x < 0: continue
  occupied[point] = true
  map.resources.append({"definition":kind,"point":point,"guaranteed":guaranteed})
  work_tiles[work] = true
  for delta in ColonyNavigation.NEIGHBORS: work_tiles[work+delta] = true
  if kind in ["tree","stone_node","clay_bank","iron_seam"]: map.solid[point] = true
  return true
 return false

static func _reachable(map: Dictionary) -> Dictionary:
 var distances: Dictionary = {map.cart:0}
 var queue: Array = [map.cart]
 var cursor: int = 0
 var bridges: Dictionary = {}
 for p in map.state.bridges: bridges[p] = true
 while cursor < queue.size():
  var point: Vector2i = queue[cursor]; cursor += 1
  for delta in ColonyNavigation.NEIGHBORS:
   var p: Vector2i = point+delta
   if not ColonyWorld.inside(p) or distances.has(p) or map.solid.has(p): continue
   if map.state.elevation[p.y*128+p.x] == 0 and not bridges.has(p): continue
   if absi(map.state.elevation[p.y*128+p.x]-map.state.elevation[point.y*128+point.x]) > 1 and not bridges.has(p) and not bridges.has(point): continue
   distances[p] = distances[point]+1; queue.append(p)
 return distances

static func validate_map(map: Dictionary) -> Array:
 var errors: Array = []
 var reachable: Dictionary = _reachable(map)
 if map.get("placement_failed",false): errors.append("guaranteed resource placement")
 if reachable.keys().filter(func(p:Vector2i)->bool:return map.state.elevation[p.y*128+p.x] >= 2).size() < 1024: errors.append("safe buildable ground")
 for field in map.state.starter_field:
  if not reachable.has(field) or map.state.elevation[field.y*128+field.x] != 2 or map.state.fertility[field.y*128+field.x] < 1000: errors.append("protected starter field"); break
 for resource in map.resources:
  if not ColonyNavigation.NEIGHBORS.any(func(d:Vector2i)->bool:return reachable.has(resource.point+d)): errors.append("unreachable resource"); break
 var food: int = 0
 for resource in map.resources:
  if resource.definition == "berry_bush": food += 4
  elif resource.definition == "mushroom_patch": food += 3
 if food < 40: errors.append("starting wild food")
 for species in WILDLIFE:
  if map.state.habitats[species].size() != WILDLIFE[species]: errors.append("missing "+species+" habitat")
  for p in map.state.habitats[species]:
   if reachable.get(p,0) < (40 if species == "boar" else 30): errors.append("unsafe "+species+" habitat"); break
 var water: bool = false
 for p in reachable:
  for d in ColonyNavigation.NEIGHBORS:
   var n: Vector2i = p+d
   if ColonyWorld.inside(n) and map.state.elevation[n.y*128+n.x] == 0: water = true
 if not water: errors.append("river water access")
 if not reachable.keys().any(func(p:Vector2i)->bool:return p.x in [0,127] or p.y in [0,127]): errors.append("boundary route")
 return errors

static func validate_state(state: Variant, version: int) -> bool:
 if not state is Dictionary or not ColonyCodec._keys(state,empty_state().keys()): return false
 for field in ["elevation","fertility","paths","bridges","starter_field","diagnostics"]:
  if not state[field] is Array: return false
 if not state.transform is int or state.transform not in [0,1,2,3] or not state.attempt is int or state.attempt < 0 or state.attempt > 32 or not state.fallback is bool or not state.habitats is Dictionary: return false
 if version == 0: return state == empty_state()
 if version != VERSION or state.elevation.size() != 16384 or state.fertility.size() != 16384 or state.starter_field.size() != 64 or state.paths.size() > 16384 or state.bridges.size() > 16384: return false
 if not state.elevation.all(func(n:Variant)->bool:return n is int and n >= 0 and n <= 4) or not state.fertility.all(func(n:Variant)->bool:return n is int and n in [750,1000,1250]): return false
 for field in ["paths","bridges","starter_field"]:
  if not state[field].all(func(p:Variant)->bool:return p is Vector2i): return false
 if not ColonyCodec._keys(state.habitats,WILDLIFE.keys()): return false
 for species in state.habitats:
  if not state.habitats[species] is Array or state.habitats[species].size() != WILDLIFE[species] or not state.habitats[species].all(func(p:Variant)->bool:return p is Vector2i): return false
 return state.diagnostics.size() <= 32 and state.diagnostics.all(func(s:Variant)->bool:return s is String and s.length() <= 256)
