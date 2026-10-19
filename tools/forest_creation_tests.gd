class_name ForestCreationTests
extends RefCounted

class ReferenceWorld extends "res://tools/profile_campaign.gd".ProfileWorld:
	func _profile(stage: String, action: Callable) -> void:
		if stage=="ColonyNature.create_jobs": ForestCreationReference.create_jobs(self)
		else: action.call()

static func fixture() -> ColonyWorld:
	var world: ColonyWorld=ColonyTests.world()
	var prototype: Dictionary=world.resources[0].duplicate(true)
	world.resources.clear();world.nature_state=ColonyNature.initial_state(world.tick)
	var tiles: Array[Vector2i]=[]
	for index in range(120):
		var resource: Dictionary=prototype.duplicate(true)
		resource.id=world._id();resource.x=40+index%30;resource.y=30+index/30
		resource.remaining=8 if index%4==0 else 0;resource.regrow_at=0
		world.resources.append(resource);tiles.append(Vector2i(resource.x,resource.y))
	ColonyNature.command(world,"forest",{"tiles":tiles.slice(0,60),"value":50})
	ColonyNature.command(world,"forest",{"tiles":tiles.slice(60),"value":75})
	for index in range(1200):
		var ended: Dictionary=world._job("plant_tree","Growing","Field",world.resources[index%120].id,tiles[index%120],4000)
		ended.state="Canceled";ended.queue_state=""
	# Match the phone report's large pending-work pressure, including overflow
	# into Queued state, without discarding any old job records.
	for index in range(400):
		var build: Dictionary=world._job("build","Building","Build",0,Vector2i(80+index%20,index/20),world.definitions.buildings.wood_wall.work_milli)
		build.definition="wood_wall";build.inputs=world.definitions.buildings.wood_wall.materials.duplicate()
	for index in [1,2,3]:
		var job: Dictionary=world._job("clear_stump" if index==2 else "plant_tree","Growing","Field",world.resources[index].id,tiles[index],4000)
		job.state=["Ready","Blocked","Queued"][index-1];job.queue_state="Ready" if index==3 else ""
		if index==2: job.retry=world.tick+50
	world.nature_state.trees[world.resources[5].id]={"planted":true,"age":20,"cleared":false}
	world.nature_state.trees[world.resources[6].id]={"planted":false,"age":0,"cleared":true}
	world._structure("wood_floor",tiles[7],0)
	world._command({"kind":"stockpile","args":{"tiles":[tiles[9]]}})
	world.navigation_dirty=true;world.record_indexes.clear();world.reset_job_queries()
	world.work_budget.reset();world.work_budget.reconcile(world)
	return world

static func clone(world: ColonyWorld, reference: bool=false) -> ColonyWorld:
	var result: ColonyWorld=ReferenceWorld.new(world.definitions) if reference else ColonyWorld.new(world.definitions)
	for field in world.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=world.get(field)
		result.set(field,value.duplicate(true) if value is Array or value is Dictionary else value)
	result.navigation_dirty=true;result.rooms_dirty=true;result.reachability_dirty=true
	return result

static func run(check: Callable) -> void:
	var world: ColonyWorld=fixture();var original: ColonyWorld=clone(world,true)
	var setup: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("FOREST/large_pending_work_fixture_passes_normal_save_validation",setup.has("world") and setup.world.payload()==world.payload(),str(setup.get("error","")))
	var before: String=world.canonical_hash()
	ColonyNature.create_jobs(world);ForestCreationReference.create_jobs(original)
	check.call("FOREST/creation_matches_original_history_queued_stumps_zones_and_obstacles",world.payload()==original.payload() and world.canonical_hash()!=before and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var once: String=world.canonical_hash()
	ColonyNature.create_jobs(world);ForestCreationReference.create_jobs(original)
	check.call("FOREST/repeated_pass_keeps_pending_work_and_exact_id_order",world.payload()==original.payload() and world.canonical_hash()==once)
	world.jobs=world.jobs.duplicate(true);original.jobs=original.jobs.duplicate(true)
	var exact: bool=true
	for index in range(500):
		if index==200:
			for state in [world,original]:
				state.queue_command("forest_policy",{"target":state.nature_state.forests[0].id,"value":100,"enabled":false})
		world.step();original.step()
		if index in [0,49,199,200,499]: exact=exact and world.payload()==original.payload()
	check.call("FOREST/complete_future_ticks_and_policy_changes_match_original",exact and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	if decoded.has("world"):
		world=decoded.world;original=clone(world,true)
		for index in range(100): world.step();original.step()
	check.call("FOREST/reload_continuation_preserves_original_full_state",decoded.has("world") and world.payload()==original.payload(),str(decoded.get("error","")))
