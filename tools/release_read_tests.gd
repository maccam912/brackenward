class_name ReleaseReadTests
extends RefCounted
## Complete defdc91 release oracle; preserves the original full-history loop.
class OriginalWorld extends ColonyWorld:
	func _release(job: Dictionary, cancel: bool) -> void:
		if job.is_empty() or job.state in ["Complete","Canceled"]:
			return
		work_budget.mark_dirty()
		cancel=cancel or job.kind in PERSONAL_JOBS
		if cancel and job.kind=="trade":
			var exchange: Dictionary = find(trade_state.exchanges,job.target)
			if not exchange.is_empty() and exchange.state=="Packing": exchange.state="Canceled"
		if job.kind=="move_furniture": ColonyMaintenance.release_move(self,job,cancel)
		if cancel and job.kind == "build": ColonyConstruction.cancel_helpers(self,job)
		if job.kind == "hunt": danger_cache_tick = -1
		if cancel and job.kind == "hunt":
			for escort in jobs:
				if escort.kind == "escort_hunt" and escort.order == job.id and escort.state not in ["Complete","Canceled"]: _release(escort,true)
		if job.kind == "lead_animal":
			var animal: Dictionary = find(domestic_state.animals,job.target)
			if not animal.is_empty(): animal.handler = 0
		ColonyFire.released(self,job)
		ColonyCare.released(self,job)
		for stack in stacks:
			if cancel or job.kind not in RELEASE_KEEPS_RESERVATIONS: stack.reservations.erase(job.id)
			if (stack.location == "carry" and stack.job == job.id) or (cancel and stack.location == "escrow" and stack.owner == job.id):
				stack.location = "ground"
				if stack.owner > 0 and not find(citizens, stack.owner).is_empty():
					var carrier: Dictionary = find(citizens, stack.owner)
					stack.x = carrier.x
					stack.y = carrier.y
				stack.owner = 0
				stack.job = 0
				if not cancel and job.kind in RELEASE_KEEPS_RESERVATIONS and stack.count>0: stack.reservations[job.id]=stack.count
		if job.worker > 0:
			var citizen: Dictionary = find(citizens, job.worker)
			citizen.job = 0
			citizen.route.clear()
			citizen.route_goal.clear()
		job.worker = 0
		job.state = "Canceled" if cancel else "Ready"
		if job.kind in ["minor_work","minor_study"]: ColonyOpportunities.released(self,job,cancel)
		if cancel:
			for citizen in citizens:
				if citizen.pinned_job == job.id:
					citizen.pinned_job = 0
			job.work = 0
			job.pending_xp.clear()
			job.rate_remainders.clear()

static func clone(source: ColonyWorld, original: bool=false) -> ColonyWorld:
	var result: ColonyWorld=OriginalWorld.new(source.definitions) if original else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]:continue
		var value: Variant=source.get(field)
		if value is Array:result.get(field).assign(value.duplicate(true))
		elif value is Dictionary:result.set(field,value.duplicate(true))
		else:result.set(field,value)
	result.reset_job_queries();result.reset_stack_queries();result.reset_resource_queries();result.record_indexes.clear()
	result.navigation_dirty=true;result.rooms_dirty=true;result.reachability_dirty=true
	return result

static func same(current: ColonyWorld, prior: ColonyWorld) -> bool:
	return JSON.stringify(ColonyState.pack(current.payload()),"",false)==JSON.stringify(ColonyState.pack(prior.payload()),"",false)

static func run(check: Callable) -> void:
	var exact: bool=true;var cases: int=0
	for kind in ["gather","haul","build","craft","eat","sleep","trade","expedition_pack","raid_pay","supper_reserve"]:
		for cancel in [false,true]:
			var current: ColonyWorld=ColonyTests.world()
			var job: Dictionary=current._job(kind,"Building","Construction",0,Vector2i(90,80),8000)
			var other: Dictionary=current._job("gather","Gathering","Field",0,Vector2i(91,80),8000)
			job.worker=1;job.state="Working";current.citizens[0].job=job.id
			current.citizens[0].route=[Vector2i(63,64)];current.citizens[0].route_goal=[Vector2i(64,64)]
			for location in ["ground","carry","escrow"]:
				for quantity in [0,4]:
					var row: Dictionary=current._make_stack("wood",quantity,location,job.id if location=="escrow" else (1 if location=="carry" else 0),Vector2i(75,76),true)
					row.job=job.id if location=="carry" else 0
					row.reservations[job.id]=mini(2,quantity);row.reservations[other.id]=mini(1,quantity)
			var prior: ColonyWorld=clone(current,true);var id: int=job.id
			current._release(job,cancel);prior._release(prior.find(prior.jobs,id),cancel)
			exact=exact and same(current,prior);cases+=1
	check.call("RELEASE/full_original_matches_twenty_kind_cancel_cases_including_zero_history_and_foreign_reservations",exact and cases==20)
	var current: ColonyWorld=ColonyTests.world()
	var job: Dictionary=current._job("gather","Gathering","Field",0,Vector2i(90,80),8000)
	job.worker=1;current.citizens[0].job=job.id
	var empty: Dictionary=current._make_stack("wood",0,"carry",1,Vector2i(75,76),false);empty.job=job.id;empty.reservations[job.id]=0
	current._release(job,true)
	check.call("RELEASE/depleted_historical_carry_still_releases_owner_job_position_and_zero_reservation",empty.location=="ground" and empty.owner==0 and empty.job==0 and empty.x==current.citizens[0].x and empty.y==current.citizens[0].y and empty.reservations.is_empty())
	current=ColonyTests.world();job=current._job("build","Building","Construction",0,Vector2i(90,80),8000)
	var helper: Dictionary=current._job("build_helper","Building","Construction",0,Vector2i(90,80),8000);helper.order=job.id;helper.worker=2;current.citizens[1].job=helper.id
	empty=current._make_stack("wood",0,"carry",2,Vector2i(75,76),false);empty.job=helper.id;empty.reservations[job.id]=0;empty.reservations[helper.id]=0
	var prior: ColonyWorld=clone(current,true);var id: int=job.id
	current._release(job,true);prior._release(prior.find(prior.jobs,id),true)
	check.call("RELEASE/recursive_real_helper_cancellation_keeps_all_history_and_callback_order",same(current,prior) and helper.state=="Canceled" and empty.owner==0 and empty.job==0 and empty.reservations.is_empty())
	current=ColonyTests.world();prior=clone(current,true)
	var target: int=current.resources.filter(func(r:Dictionary)->bool:return r.definition=="tree")[0].id
	current.queue_command("gather",{"target":target});prior.queue_command("gather",{"target":target})
	for tick in range(1200):current.step();prior.step()
	var loaded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(current))
	exact=same(current,prior) and current.invariant_errors().is_empty() and loaded.has("world")
	if loaded.has("world"):
		# The existing encoder sorts String keys. Keep strict unsorted equality
		# for in-memory twins, and compare every value across serialization.
		exact=exact and loaded.world.payload()==current.payload()
		for tick in range(120):loaded.world.step();prior.step()
		exact=exact and loaded.world.payload()==prior.payload() and loaded.world.invariant_errors().is_empty()
	check.call("RELEASE/complete_ordinary_future_and_reload_match_full_original",exact)
