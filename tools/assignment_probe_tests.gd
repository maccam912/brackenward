class_name AssignmentProbeTests
extends RefCounted
const Reference = preload("res://tools/assignment_probe_reference.gd")

static func treatment(rows: Array, target: int) -> bool:
	return rows.any(func(j:Dictionary)->bool:return j.kind=="treat" and j.target==target and j.state not in ["Complete","Canceled"])

static func emergency(world: ColonyWorld, rows: Array) -> bool:
	return rows.any(func(j:Dictionary)->bool:return j.emergency and j.worker==0 and j.state not in ["Complete","Canceled"] and world.tick>=j.retry)

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();world.in_tick=true
	var exact: bool=true
	for state in ["Ready","Blocked","Fetching","Delivering","Moving","Working","Queued","Complete","Canceled"]:
		for kind in ["treat","enemy_treat","gather"]:
			for target in [1,2]:
				var rows: Array=[{"kind":kind,"target":target,"state":state}]
				exact=exact and world._has_treatment(rows,1)==treatment(rows,1)
	check.call("ASSIGN/treatment_probe_preserves_all_states_kinds_and_target_predicates",exact)
	exact=true
	for state in ["Ready","Blocked","Fetching","Delivering","Moving","Working","Queued","Complete","Canceled"]:
		for urgent in [false,true]:
			for worker in [0,1,2]:
				for retry in [world.tick-1,world.tick,world.tick+1]:
					var rows: Array=[{"emergency":urgent,"worker":worker,"state":state,"retry":retry}]
					exact=exact and world._has_emergency(rows)==emergency(world,rows)
	check.call("ASSIGN/emergency_probe_preserves_worker_retry_boundary_and_terminal_predicates",exact)
	var job: Dictionary={"kind":"treat","target":1,"state":"Ready","emergency":true,"worker":0,"retry":world.tick}
	var rows: Array=[job];exact=world._has_treatment(rows,1) and world._has_emergency(rows)
	job.state="Complete";exact=exact and not world._has_treatment(rows,1) and not world._has_emergency(rows)
	job.state="Blocked";job.worker=1;job.target=2
	exact=exact and not world._has_treatment(rows,1) and not world._has_emergency(rows)
	rows.append(job.duplicate());rows[1].target=1;rows[1].worker=0;rows[1].retry=world.tick+1
	exact=exact and world._has_treatment(rows,1) and not world._has_emergency(rows)
	world.tick+=1;exact=exact and world._has_emergency(rows);rows=rows.duplicate(true);rows.reverse()
	exact=exact and world._has_treatment(rows,1)==treatment(rows,1) and world._has_emergency(rows)==emergency(world,rows)
	rows.clear();exact=exact and not world._has_treatment(rows,1) and not world._has_emergency(rows)
	check.call("ASSIGN/probes_read_live_records_same_tick_appends_replacements_and_retry_time",exact)
	exact=true
	for trusted in [false,true]:
		world.in_tick=trusted
		# Sparse tails make short circuit observable without overriding product code.
		rows=[{"kind":"gather"},{"kind":"treat","target":2},{"kind":"treat","target":1,"state":"Canceled"},{"kind":"treat","target":1,"state":"Ready"},{}]
		var before: String=JSON.stringify(rows,"",false);var canonical: String=world.canonical_hash()
		exact=exact and world._has_treatment(rows,1) and treatment(rows,1) and JSON.stringify(rows,"",false)==before
		rows=[{"emergency":false},{"emergency":true,"worker":1},{"emergency":true,"worker":0,"state":"Complete"},{"emergency":true,"worker":0,"state":"Ready","retry":world.tick},{}]
		before=JSON.stringify(rows,"",false)
		exact=exact and world._has_emergency(rows) and emergency(world,rows) and JSON.stringify(rows,"",false)==before and world.canonical_hash()==canonical
	check.call("ASSIGN/probes_keep_short_circuit_order_outside_callbacks_and_never_mutate_state",exact)

	var future: Dictionary=future_twins()
	check.call("ASSIGN/full_original_search_keeps_real_treatment_and_fire_future_exact_after_reload",future.passed,JSON.stringify(future))

static func clone(source: ColonyWorld) -> ColonyWorld:
	var result: ColonyWorld=Reference.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]:continue
		var value: Variant=source.get(field)
		if value is Array:result.get(field).assign(value.duplicate(true))
		elif value is Dictionary:result.set(field,value.duplicate(true))
		else:result.set(field,value)
	result.reset_job_queries();result.reset_stack_queries();result.reset_resource_queries();result.record_indexes.clear()
	result.navigation_dirty=true;result.rooms_dirty=true;result.reachability_dirty=true
	return result

static func future_twins() -> Dictionary:
	for scenario in ["treatment","fire"]:
		var world: ColonyWorld=ColonyTests.world()
		if scenario=="treatment":
			world.citizens[1].health=70
			if ColonyCare.command(world,"treat_now",{"target":2,"citizen":1})!="accepted":return {"passed":false,"stage":"request","scenario":scenario}
		else:
			world._structure("well",Vector2i(74,64),0)
			var wall: Dictionary=world._structure("wood_wall",Vector2i(74,54),0)
			ColonyFire.ignite(world,"structure",wall.id)
			for person in world.citizens:person.preferences.Care=0
		var prior: ColonyWorld=clone(world)
		var observed: bool=false
		for index in range(700):
			world.step();prior.step()
			if scenario=="treatment":observed=observed or world.citizens[1].activity=="Resting for treatment"
			else:observed=observed or world.jobs.any(func(j:Dictionary)->bool:return j.kind=="extinguish" and j.worker>0)
			if JSON.stringify(ColonyState.pack(world.payload()),"",false)!=JSON.stringify(ColonyState.pack(prior.payload()),"",false):
				var fields: Array=[]
				for field in world.payload():
					if JSON.stringify(ColonyState.pack(world.payload()[field]),"",false)!=JSON.stringify(ColonyState.pack(prior.payload()[field]),"",false):fields.append(field)
				return {"passed":false,"stage":"state","scenario":scenario,"index":index,"fields":fields,"canonical_equal":world.canonical_hash()==prior.canonical_hash()}
			if index==89:
				# Reload both twins at the same boundary. The codec sorts dictionary
				# keys; compare unsorted state before and after that shared operation.
				var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
				var decoded_prior: Dictionary=ColonyCodec.decode(ColonyCodec.encode(prior))
				if not decoded.has("world") or not decoded_prior.has("world"):return {"passed":false,"stage":"decode","scenario":scenario}
				if decoded.world.canonical_hash()!=world.canonical_hash() or decoded_prior.world.canonical_hash()!=prior.canonical_hash():return {"passed":false,"stage":"roundtrip","scenario":scenario}
				world=decoded.world;prior=clone(decoded_prior.world)
				if JSON.stringify(ColonyState.pack(world.payload()),"",false)!=JSON.stringify(ColonyState.pack(prior.payload()),"",false):return {"passed":false,"stage":"reloaded_state","scenario":scenario}
		if not observed or not world.invariant_errors().is_empty() or not prior.invariant_errors().is_empty():return {"passed":false,"stage":"observed_invariants","scenario":scenario,"observed":observed,"current_errors":world.invariant_errors(),"prior_errors":prior.invariant_errors()}
		var kind: String="treat" if scenario=="treatment" else "extinguish"
		if not world.jobs.any(func(j:Dictionary)->bool:return j.kind==kind and j.state=="Complete"):return {"passed":false,"stage":"completion","scenario":scenario,"jobs":world.jobs}
	return {"passed":true}
