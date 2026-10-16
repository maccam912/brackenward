class_name FarmRecoveryTests
extends RefCounted

static func run(check: Callable) -> void:
	plots(check)
	recovery(check)
	var path: String="res://tests/fixtures/content11/campaign-replay-7200.brackenward"
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(path)
	var old: Dictionary=ColonyState.unpack(JSON.parse_string(JSON.parse_string(bytes.get_string_from_utf8()).payload))
	var loaded: Dictionary=ColonyCodec.decode(bytes)
	check.call("FARM/v11_acknowledged_fields_preserved_except_content_headers",loaded.has("world") and SchemaCompatibility.normalize(loaded.world,old)==old,str(loaded.get("error","")))
	old.content_hash="0".repeat(64)
	check.call("FARM/v11_migration_rejects_unknown_catalog_hash",ColonyCodec.restore(old).get("error","").begins_with("Unknown released v11 catalog"))

static func plots(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	var tiles: Array[Vector2i]=[Vector2i(74,54),Vector2i(75,54),Vector2i(74,55),Vector2i(75,55)]
	world.queue_command("field",{"crop":"barley","tiles":tiles});world.step()
	check.call("FARM/barley_stays_locked_before_farming",world.fields.is_empty() and world.receipts[1].contains("Farming"))
	world.researched.append("farming")
	world.queue_command("field",{"crop":"barley","tiles":tiles});world.step()
	var first: Dictionary=world.fields[0]
	ColonyAgriculture.create_jobs(world)
	var owned: Dictionary=world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.target==first.id)[0]
	check.call("FARM/researched_barley_creates_real_growing_work",world.fields.size()==4 and owned.kind=="prepare" and world.invariant_errors().is_empty())
	var worker: Dictionary=world.citizens[0]
	var reserved: bool=world._reserve(owned,worker)
	if reserved: worker.job=owned.id
	check.call("FARM/plot_removal_fixture_has_real_assigned_worker",reserved and owned.worker==worker.id and worker.job==owned.id)
	world.queue_command("field",{"crop":"flax","tiles":[Vector2i(76,54)]})
	world.queue_command("field",{"crop":"barley","tiles":[Vector2i(76,56)]})
	world.step()
	check.call("FARM/plot_excludes_other_crops_and_diagonal_neighbors",ColonyAgriculture.plot(world,first).size()==4)
	world.queue_command("clear_field_plot",{"target":first.id})
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("FARM/pending_whole_plot_removal_roundtrips",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	var twin: ColonyWorld=decoded.world
	world.step();twin.step()
	check.call("FARM/whole_plot_cancels_all_workers_and_keeps_other_fields",world.fields.size()==2 and world.fields.all(func(f:Dictionary)->bool:return f.x==76) and owned.state=="Canceled" and owned.worker==0 and worker.job!=owned.id and world.ledger.produced.get("grain",0)==0 and not world.jobs.any(func(j:Dictionary)->bool:return j.state not in ["Complete","Canceled"] and tiles.has(Vector2i(j.x,j.y)) and j.kind in ["prepare","sow","harvest"]) and world.invariant_errors().is_empty() and world.canonical_hash()==twin.canonical_hash(),str(world.invariant_errors()))
	var single: Dictionary=world.fields[0]
	world.queue_command("clear_field",{"target":single.id});world.step()
	check.call("FARM/single_tile_removal_still_available",world.fields.size()==1 and world.fields[0].crop=="barley")
	world.queue_command("clear_field_plot",{"target":first.id});world.step()
	check.call("FARM/repeated_plot_removal_reports_missing_target",world.receipts[world.next_command_id-1]=="missing_field" and world.invariant_errors().is_empty())

static func recovery(check: Callable) -> void:
	for fullness: int in [0,200]:
		var world: ColonyWorld=ColonyTests.world()
		NeedsPriorityTests.remove_food(world)
		var person: Dictionary=world.citizens[0]
		person.fullness=fullness;person.health=40;person.rest=900;person.preferences.Gathering=3
		for other: Dictionary in world.citizens:
			if other.id!=person.id:
				other.preferences.Gathering=0;other.preferences.Cooking=0;other.preferences.Hauling=0
		world._assign(person)
		check.call("HUNGER/injured_without_food_work_rests_%d" % fullness,world.find(world.jobs,person.job).get("kind")=="recover")
		var berry: Dictionary=world.resources.filter(func(r:Dictionary)->bool:return r.definition=="berry_bush")[0]
		world.queue_command("gather",{"target":berry.id})
		for index in range(60):
			world.step()
			if world.find(world.jobs,person.job).get("kind")=="gather": break
		var gather: Dictionary=world.find(world.jobs,person.job)
		check.call("HUNGER/injured_recovery_yields_to_new_berry_order_%d" % fullness,gather.get("kind")=="gather" and gather.target==berry.id,str([person.activity,gather]))
		var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
		assert(decoded.has("world"),str(decoded.get("error","")))
		var twin: ColonyWorld=decoded.world
		for index in range(1600):
			world.step();twin.step()
			if world.ledger.consumed.get("berry",0)>0: break
		check.call("HUNGER/injured_hungry_resident_gathers_and_eats_real_food_%d" % fullness,world.ledger.produced.get("berry",0)>0 and world.ledger.consumed.get("berry",0)>0 and person.fullness>0 and gather.state=="Complete" and world.canonical_hash()==twin.canonical_hash() and world.invariant_errors().is_empty(),str([person.activity,person.fullness,person.health,gather.state,world.invariant_errors()]))
	var world: ColonyWorld=ColonyTests.world();var person: Dictionary=world.citizens[0]
	var fed: Dictionary=world._job("gather","Gathering","Field",world.resources[0].id,Vector2i(50,54),16000)
	var hungry: Dictionary=world._job("gather","Gathering","Field",world.resources[0].id,Vector2i(50,54),16000)
	var fed_work: int=0;var hungry_work: int=0
	for index in range(100): fed_work+=world._rate(person,fed)
	person.fullness=0
	for index in range(100): hungry_work+=world._rate(person,hungry)
	check.call("HUNGER/zero_fullness_work_is_exactly_half_speed_and_eating_is_full_speed",hungry_work*2==fed_work and hungry_work>0 and world._rate(person,{"kind":"eat"})==100)
	for health: int in [100,40]:
		var fed_world: ColonyWorld=ColonyTests.world();var hungry_world: ColonyWorld=ColonyTests.world()
		var a: Dictionary=fed_world.citizens[0];var b: Dictionary=hungry_world.citizens[0]
		a.health=health;b.health=health;b.fullness=0
		fed_world._walk(a,Vector2i(a.x+1,a.y));hungry_world._walk(b,Vector2i(b.x+1,b.y))
		check.call("HUNGER/zero_fullness_walk_is_half_speed_with_injury_%d" % health,b.progress>0 and b.progress*2==a.progress,str([a.progress,b.progress]))
