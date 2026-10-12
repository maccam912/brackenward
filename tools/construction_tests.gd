class_name ConstructionTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	var pattern: Array[Dictionary] = ColonyConstruction.lodge(Vector2i(74,54))
	var wood: int = 0;var fiber: int = 0;var effort: int = 0
	for blueprint in pattern:
		var definition: Dictionary = world.definitions.buildings[blueprint.definition]
		wood += definition.materials.get("wood",0);fiber += definition.materials.get("fiber",0);effort += definition.work_milli
	check.call("BUILD/lodge_exact_twenty_eight_parts_w73_f8_206wu",pattern.size()==28 and wood==73 and fiber==8 and effort==206000)
	world.queue_command("build",{"definition":"barn","x":74,"y":54,"rotation":0});world.step()
	check.call("BUILD/research_gate_preserved",world.jobs.is_empty())
	world=ColonyTests.world()
	world.queue_command("build",{"definition":"table","x":74,"y":63,"rotation":0})
	var maximum: int = 0
	var distinct: bool = true
	for i in range(700):
		world.step()
		var workers: Array = world.jobs.filter(func(j:Dictionary)->bool:return j.kind in ["build","build_helper"] and j.worker>0)
		maximum=maxi(maximum,workers.size())
		if workers.size()==2: distinct=distinct and Vector2i(workers[0].work_x,workers[0].work_y)!=Vector2i(workers[1].work_x,workers[1].work_y)
		if world.structures.any(func(s:Dictionary)->bool:return s.definition=="table"): break
	var parent: Dictionary = world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build")[0]
	check.call("BUILD/two_workers_use_distinct_positions",maximum==2 and distinct)
	check.call("BUILD/shared_escrow_consumed_once",parent.state=="Complete" and world.ledger.consumed.get("wood",0)==8 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var xp: int = 0
	for value in parent.pending_xp.values(): xp += value
	check.call("BUILD/shared_xp_is_exact_completed_wu",xp==parent.required and parent.pending_xp.size()==2)
	check.call("BUILD/completion_clears_all_worker_ownership",world.citizens.all(func(c:Dictionary)->bool:return c.job==0 or world.find(world.jobs,c.job).worker==c.id) and world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build_helper").all(func(j:Dictionary)->bool:return j.state=="Complete"))
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/helper_completion_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world=ColonyTests.world();world.researched.append("husbandry")
	world.queue_command("build",{"definition":"barn","x":74,"y":54,"rotation":0})
	for i in range(1400):
		world.step()
		if world.jobs.any(func(j:Dictionary)->bool:return j.kind=="build_helper" and j.worker>0): break
	parent=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build")[0]
	var before: int = world.total("wood")
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/mid_shared_work_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world.queue_command("cancel",{"target":parent.id});world.step()
	check.call("BUILD/cancel_returns_escrow_and_both_workers",parent.state=="Canceled" and world.total("wood")==before and world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build_helper").all(func(j:Dictionary)->bool:return j.state=="Canceled") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world()
	world.researched.append("husbandry");world._structure("wood_wall",Vector2i(75,54),0)
	world.queue_command("build_area",{"definition":"fence","tiles":[Vector2i(74,54),Vector2i(75,54),Vector2i(76,54)]});world.step()
	check.call("BUILD/paint_submits_valid_cells_omits_blocked",world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build").size()==2 and world.receipts.values()[0].contains("blocked"))
	var repeat: int = world.queue_command("build_area",{"definition":"fence","tiles":[Vector2i(74,54),Vector2i(76,54)]});world.step()
	check.call("BUILD/repainting_does_not_duplicate_blueprints",world.jobs.size()==2 and world.receipts[repeat].contains("No valid"))
	world=ColonyTests.world();world._structure("wood_floor",Vector2i(74,54),0)
	check.call("BUILD/furniture_can_overlay_floor",world.placement_error("table",Vector2i(74,54),0).is_empty())
	world=ColonyTests.world();world._make_stack("wood",40,"store",world.stores[0].id,Vector2i(66,63),true)
	world.queue_command("lodge",{"x":74,"y":54});world.step()
	var group: Dictionary = world.construction_state.groups[0]
	var closing: Dictionary = world.find(world.jobs,group.closing)
	check.call("BUILD/lodge_closing_waits_for_beds_and_door",not ColonyConstruction.ready(world,closing) and closing.reason.contains("beds and door"))
	decoded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/lodge_group_pending_inputs_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	for i in range(10000):
		world.step()
		if group.members.all(func(id:int)->bool:return world.find(world.jobs,id).state=="Complete"): break
	check.call("BUILD/real_lodge_completes_roofed_four_beds",group.members.all(func(id:int)->bool:return world.find(world.jobs,id).state=="Complete") and world.citizens.all(func(c:Dictionary)->bool:return world.find(world.structures,c.bed).definition=="bed" and world.roofed(Vector2i(world.find(world.structures,c.bed).x,world.find(world.structures,c.bed).y))) and world.invariant_errors().is_empty(),str(world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="build" and j.state!="Complete").map(func(j:Dictionary)->Array:return [j.definition,j.x,j.y,j.state,j.work,j.reason]))+str(world.citizens.map(func(c:Dictionary)->Array:return [c.id,c.x,c.y,c.job,c.activity])))
	check.call("BUILD/real_lodge_conserves_exact_materials",world.ledger.consumed.get("wood",0)==73 and world.ledger.consumed.get("fiber",0)==8)
	world=ColonyTests.world();var old_count: int = world.jobs.size()
	world.queue_command("lodge",{"x":60,"y":58});world.step()
	check.call("BUILD/blocked_lodge_never_partially_submits",world.jobs.size()==old_count and world.construction_state.groups.is_empty())
	var old: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-care.brackenward"))
	check.call("SAVE/construction_migration_retains_care",old.has("world") and old.world.citizens[2].health==27 and old.world.construction_state.groups.is_empty())
	world=ColonyTests.world();world._structure("wood_wall",Vector2i(74,54),0)
	check.call("BUILD/floor_can_overlay_existing_solid_wall",world.placement_error("wood_floor",Vector2i(74,54),0).is_empty())
	world=ColonyTests.world();world.queue_command("build",{"definition":"wood_wall","x":76,"y":63,"rotation":0});world.step()
	var idle: Dictionary = world.citizens[3];idle.x=76;idle.y=63;idle.edge_x=76;idle.edge_y=63
	for i in range(600): world.step()
	check.call("BUILD/idle_citizen_steps_out_of_unfinished_wall",world.structures.any(func(s:Dictionary)->bool:return s.definition=="wood_wall" and s.x==76 and s.y==63) and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="step_aside" and j.state=="Complete") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();world._make_stack("wood",2,"ground",0,Vector2i(74,54),true);world._structure("wood_wall",Vector2i(74,54),0)
	world.queue_command("build",{"definition":"garden_bench","x":76,"y":54,"rotation":0})
	for i in range(600): world.step()
	check.call("BUILD/blocked_nearby_inputs_do_not_hide_accessible_stock",world.structures.any(func(s:Dictionary)->bool:return s.definition=="garden_bench") and world.ledger.consumed.get("wood",0)==6 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
