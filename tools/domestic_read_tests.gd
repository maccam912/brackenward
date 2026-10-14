class_name DomesticReadTests
extends RefCounted
## Original 445f183 domestic creation, before sharing per-call reads.
static func full_create_jobs(world: ColonyWorld) -> void:
	for pen in world.domestic_state.pens:
		var info: Dictionary = ColonyDomestic.status(world,pen)
		for animal in ColonyDomestic.occupants(world,pen.id):
			if info.barns.has(animal.barn): continue
			for barn in info.barns:
				if world.domestic_state.animals.filter(func(a:Dictionary)->bool:return a.health>0 and a.barn==barn).size()<6: animal.barn=barn;break
		if not info.error.is_empty(): pen.reason=info.error
		for barn_id in info.barns:
			var residents: Array = ColonyDomestic.occupants(world,pen.id).filter(func(a:Dictionary)->bool:return a.barn==barn_id and not a.away)
			var daily: int = 0
			for animal in residents: daily += ColonyDomestic.demand(world,animal,world.tick/7200+1)
			var shortage: int = mini(24,daily*2)-ColonyDomestic.feed_count(world,barn_id)
			if shortage<=0 or world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="stock_feed" and j.target==barn_id and j.state not in ["Complete","Canceled"]): continue
			var candidates: Array = world.nonempty_stacks().filter(func(s:Dictionary)->bool:return ColonyDomestic.feed_item(world,s.item) and s.count>world._reserved(s) and s.location in ["ground","store","output"] and world.accessible(Vector2i(s.x,s.y)))
			candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.age>b.age if a.age!=b.age else a.id<b.id)
			if candidates.is_empty(): pen.reason="No grain or vegetables available for barn feed";continue
			var source: Dictionary = candidates[0]
			var barn: Dictionary = world.find(world.structures,barn_id)
			var job: Dictionary = world._job("stock_feed","Animals","Field",barn_id,Vector2i(barn.x,barn.y),0)
			job.inputs={source.item:mini(8,mini(shortage,source.count-world._reserved(source)))}
	for animal in world.domestic_state.animals:
		if animal.health<=0 or animal.away or animal.pending==0 or world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind in ["collect_animal","slaughter","lead_animal"] and j.target==animal.id and j.state not in ["Complete","Canceled"]): continue
		var job: Dictionary = world._job("collect_animal","Animals","Field",animal.id,Vector2i(animal.x,animal.y),4000)
		job.definition=animal.definition


class OriginalWorld extends ColonyWorld:
	func _create_domestic_jobs() -> void:
		DomesticReadTests.full_create_jobs(self)

static func clone(source: ColonyWorld, original: bool) -> ColonyWorld:
	var result: ColonyWorld=OriginalWorld.new(source.definitions) if original else ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	return result

static func create(fast: ColonyWorld, original: ColonyWorld) -> bool:
	ColonyDomestic.create_jobs(fast);full_create_jobs(original)
	return fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty()

static func run(check: Callable) -> void:
	var source: ColonyWorld=DomesticTests.setup();var pen: Dictionary=source.domestic_state.pens[0]
	for index in range(4):
		var acquired: Dictionary=ColonyDomestic.acquire(source,"hen" if index<3 else "pack_goat",pen.id,pen.tiles[index])
		if not acquired.has("animal"): check.call("DOM_READ/fixture_acquires_real_animals",false,str(acquired));return
		acquired.animal.pending=1
	var barn: int=source.domestic_state.animals[0].barn
	var oldest: Dictionary=source._make_stack("grain",24,"ground",0,Vector2i(70,65),true);oldest.age=1000
	var newer: Dictionary=source._make_stack("vegetable",24,"ground",0,Vector2i(71,65),true);newer.age=100
	source._make_stack("grain",2,"animal_feed",barn,Vector2i(75,53),true)
	for index in range(2000):
		var job: Dictionary=source._job("stock_feed" if index%2==0 else "collect_animal","Animals","Field",barn if index%2==0 else source.domestic_state.animals[0].id,Vector2i(75,53),0)
		job.state="Complete" if index%3==0 else "Canceled"
		if job.kind=="stock_feed": job.inputs={"grain":1}
		else: job.required=4000;job.work=4000 if job.state=="Complete" else 0;job.definition=source.domestic_state.animals[0].definition
		var old: Dictionary=source._make_stack("grain",0,"animal_feed",barn,Vector2i(75,53),false);old.age=123;old.age_rem=1
	var loaded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(source))
	check.call("DOM_READ/history_zero_stack_and_pending_production_fixture_is_valid",loaded.has("world"),str(loaded.get("error","")))
	if not loaded.has("world"): return
	var fast: ColonyWorld=clone(loaded.world,false);var original: ColonyWorld=clone(loaded.world,true)
	fast.in_tick=true;original.in_tick=true
	var first_exact: bool=create(fast,original)
	var feeds: Array=fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="stock_feed" and j.state not in ["Complete","Canceled"])
	check.call("DOM_READ/live_creation_matches_full_history_and_oldest_feed",first_exact and fast.jobs.back().kind=="collect_animal" and feeds.size()==1 and feeds[0].inputs=={"grain":8},str(fast.invariant_errors()))
	var next: int=fast.next_id
	check.call("DOM_READ/repeated_same_tick_creation_keeps_ids_and_buffers",create(fast,original) and fast.next_id==next)
	for world in [fast,original]:
		for job in world.jobs:
			if job.state not in ["Complete","Canceled"]: job.queue_state=job.state;job.state="Queued"
	check.call("DOM_READ/queued_feed_and_collection_prevent_duplicate_orders",create(fast,original) and fast.next_id==next)
	for world in [fast,original]:
		for job in world.jobs:
			if job.kind=="stock_feed" and job.state=="Queued": world._release(job,true)
	check.call("DOM_READ/canceled_same_tick_feed_is_recreated_once",create(fast,original) and fast.next_id==next+1)
	for world in [fast,original]:
		for job in world.jobs:
			if job.kind=="stock_feed" and job.state not in ["Complete","Canceled"]: world._release(job,true)
		for stack in world.stacks:
			if stack.location=="animal_feed" and stack.count>0: world._record("consumed",stack.item,stack.count);stack.count=0
		var depleted: Dictionary=world.find(world.stacks,oldest.id);world._record("consumed",depleted.item,depleted.count);depleted.count=0
	check.call("DOM_READ/next_call_observes_depleted_food_and_buffers",create(fast,original) and fast.jobs.back().inputs=={"vegetable":8})
	fast.in_tick=false;original.in_tick=false
	var saved: Dictionary=ColonyCodec.decode(ColonyCodec.encode(fast))
	check.call("DOM_READ/derived_indexes_preserve_all_saved_history_and_roundtrip",saved.has("world") and saved.world.canonical_hash()==fast.canonical_hash(),str(saved.get("error","")))
	full_ticks(loaded.world,check)
	shared_barns(check)

static func shared_barns(check: Callable) -> void:
	var fixture: Dictionary=StressFixture.make()
	if not fixture.has("world"): check.call("DOM_READ/two_barn_fixture_validates",false,str(fixture));return
	var source: ColonyWorld=fixture.world
	for stack in source.stacks:
		if stack.location=="animal_feed" and stack.count>0: source._record("consumed",stack.item,stack.count);stack.count=0
	for animal in source.domestic_state.animals: animal.pending=1
	source._make_stack("grain",16,"ground",0,Vector2i(source.citizens[0].x,source.citizens[0].y),true)
	var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
	fast.in_tick=true;original.in_tick=true
	var before: int=fast.next_id
	check.call("DOM_READ/two_barns_and_twelve_animals_keep_original_proposal_order_and_amounts",create(fast,original) and fast.next_id==before+14 and fast.jobs.filter(func(j:Dictionary)->bool:return j.kind=="stock_feed").all(func(j:Dictionary)->bool:return j.inputs=={"grain":8}),str(fast.invariant_errors()))
	check.call("DOM_READ/proposals_do_not_reserve_shared_feed_or_duplicate_on_repeat",create(fast,original) and fast.next_id==before+14 and fast.stacks.all(func(s:Dictionary)->bool:return s.reservations.is_empty()))

static func full_ticks(source: ColonyWorld, check: Callable) -> void:
	var fast: ColonyWorld=clone(source,false);var original: ColonyWorld=clone(source,true)
	for world in [fast,original]: world.queue_command("preference",{"citizen":1,"category":"Animals","value":3})
	var exact: bool=true
	for index in range(600):
		fast.step();original.step()
		if index%60==0: exact=fast.canonical_hash()==original.canonical_hash() and exact
	check.call("DOM_READ/full_feed_collection_ticks_match_original",exact and fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty(),str(fast.invariant_errors()))
	var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(fast))
	if not decoded.has("world"): check.call("DOM_READ/full_tick_save_continues",false,str(decoded));return
	fast=decoded.world
	for index in range(120): fast.step();original.step()
	check.call("DOM_READ/full_tick_save_continues",fast.canonical_hash()==original.canonical_hash() and fast.invariant_errors().is_empty())
	var empty: ColonyWorld=ColonyTests.world();var before: String=empty.canonical_hash();empty.in_tick=true;ColonyDomestic.create_jobs(empty)
	check.call("DOM_READ/no_animals_or_pens_adds_no_work_or_state",empty.canonical_hash()==before and empty.jobs.is_empty())
