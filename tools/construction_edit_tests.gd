class_name ConstructionEditTests
extends RefCounted

static func run(check: Callable) -> void:
	var outline: Array=ColonyConstruction.paint_tiles(Vector2i(74,54),Vector2i(78,58),true,false)
	check.call("BUILD/outline_has_sixteen_unique_cells_and_empty_three_by_three_center",outline.size()==16 and not outline.has(Vector2i(75,55)) and outline==ColonyConstruction.paint_tiles(Vector2i(78,58),Vector2i(74,54),true,false))
	check.call("BUILD/outline_degenerate_tap_and_line_have_no_duplicate_corners",ColonyConstruction.paint_tiles(Vector2i(74,54),Vector2i(74,54),true,false).size()==1 and ColonyConstruction.paint_tiles(Vector2i(74,54),Vector2i(78,54),true,false).size()==5)
	for kind in ["wood_wall","stone_wall","palisade"]:
		var world: ColonyWorld=ColonyTests.world();world.researched.append("masonry")
		var wall: Dictionary=world._structure(kind,Vector2i(74,54),0)
		var before: int=world.total("wood")
		var command: int=world.queue_command("build_area",{"definition":"door","tiles":[Vector2i(74,54)]});world.step()
		var doors: Array=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build" and j.definition=="door")
		check.call("BUILD/door_on_built_%s_queues_real_demolition" % kind,world.receipts[command]=="accepted" and doors.size()==1 and wall.health>0 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="demolish" and j.target==wall.id))
		var door: Dictionary=doors[0]
		if kind=="wood_wall":
			for field in ["wall","demolition"]:
				var malformed: Dictionary=world.payload().duplicate(true)
				for saved in malformed.jobs:
					if saved.id==door.id: saved.memo[field]=99999999
				check.call("SAVE/rejects_broken_door_dependency_"+field,ColonyCodec.restore(malformed).has("error"))
		var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
		check.call("SAVE/door_replacement_dependency_roundtrips_"+kind,decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
		if not decoded.has("world"): continue
		var twin: ColonyWorld=decoded.world;var demolition_tick: int=0;var door_tick: int=0
		for index in range(1800):
			world.step();twin.step()
			if wall.health==0 and demolition_tick==0: demolition_tick=world.tick
			if door.state=="Complete": door_tick=world.tick;break
		check.call("BUILD/demolition_precedes_door_and_real_materials_consumed_"+kind,demolition_tick>0 and door_tick>demolition_tick and world.total("wood")==before+world.definitions.buildings[kind].materials.get("wood",0)/2-world.definitions.buildings.door.materials.wood and world.structures.any(func(s:Dictionary)->bool:return s.definition=="door" and s.x==74 and s.y==54 and s.health>0) and world.invariant_errors().is_empty(),str([demolition_tick,door_tick,door,world.invariant_errors()]))
		check.call("SAVE/replacement_future_matches_loaded_pending_dependency_"+kind,world.canonical_hash()==twin.canonical_hash())
	var world: ColonyWorld=ColonyTests.world()
	var wall: Dictionary=NeedsPriorityTests.working_wall(world);var work: int=wall.work
	var before: int=world.total("wood")
	world.queue_command("build",{"definition":"door","x":wall.x,"y":wall.y,"rotation":0});world.step()
	check.call("BUILD/planned_in_progress_wall_is_canceled_with_helpers_and_materials_retained",wall.state=="Canceled" and work>0 and world.total("wood")==before and world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build_helper" and j.order==wall.id).all(func(j:Dictionary)->bool:return j.state=="Canceled") and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="build" and j.definition=="door") and world.invariant_errors().is_empty())
	world=ColonyTests.world();wall=world._structure("wood_wall",Vector2i(74,54),0)
	world.queue_command("build",{"definition":"door","x":74,"y":54,"rotation":0});world.step()
	var door: Dictionary=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build" and j.definition=="door")[0]
	world.queue_command("cancel",{"target":door.id});world.step()
	check.call("BUILD/cancel_replacement_cancels_its_demolition_and_keeps_wall",door.state=="Canceled" and wall.health>0 and world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="demolish").all(func(j:Dictionary)->bool:return j.state=="Canceled") and world.invariant_errors().is_empty())
	world=ColonyTests.world();wall=world._structure("wood_wall",Vector2i(74,54),0)
	world.queue_command("build",{"definition":"door","x":74,"y":54,"rotation":0});world.step()
	var demolition: Dictionary=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="demolish")[0]
	world.queue_command("cancel",{"target":demolition.id});world.step()
	check.call("BUILD/cancel_child_demolition_also_cancels_dependent_door",wall.health>0 and world.jobs.all(func(j:Dictionary)->bool:return j.kind not in ["build","demolish"] or j.state=="Canceled") and world.invariant_errors().is_empty())
	world=ColonyTests.world();wall=world._structure("wood_wall",Vector2i(74,54),0)
	world._command({"kind":"demolish","args":{"target":wall.id}})
	demolition=world.jobs[-1]
	world._command({"kind":"build","args":{"definition":"door","x":74,"y":54,"rotation":0}})
	door=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build")[0]
	world._release(door,true)
	check.call("BUILD/cancel_door_keeps_demolition_ordered_separately",demolition.state=="Ready" and world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="demolish").size()==1)
	world=ColonyTests.world();wall=world._structure("wood_wall",Vector2i(74,54),0)
	world._command({"kind":"build","args":{"definition":"door","x":74,"y":54,"rotation":0}})
	door=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build")[0]
	ColonyMaintenance.destroy(world,wall)
	for index in range(1000):
		world.step()
		if door.state=="Complete": break
	check.call("BUILD/external_wall_destruction_still_allows_pending_door_to_finish",door.state=="Complete" and world.invariant_errors().is_empty(),str(door))
	world=ColonyTests.world();world._structure("table",Vector2i(74,54),0)
	check.call("BUILD/door_never_replaces_furniture",not world.placement_error("door",Vector2i(74,54),0).is_empty())
