class_name ColonyChronicle
extends RefCounted
## Facts retain transaction evidence; narrative never guesses causes from proximity in time.
const ORDINARY_LIMIT: int = 2000
const PIN_LIMIT: int = 256
const PRESERVED: Array = ["death","depart","departure","friendship","request_accepted","request_fulfilled","request_failed","minor_accepted","raid_warning","raid_arrived","raid_resolved","major_resolved","overheat_warning","charter_stage","charter_complete","pin_moment"]
const SALIENCE: Dictionary = {"death":100,"charter_stage":100,"charter_complete":100,"depart":80,"departure":80,"friendship":80,"raid_resolved":80,"major_resolved":80,"rescue":60,"research_complete":60,"expedition_return":60,"request_offered":40,"request_accepted":40,"request_fulfilled":40,"request_failed":40,"first_building":40,"pin_moment":40}

static func initial_state(tick: int = 1800) -> Dictionary:
	return {"next_event_id":1,"facts":[],"archive":{},"journal":[],"last_journal_day":tick/7200-1,"names":{},"settlement":"Brackenward","links":{}}

static func _printable(value: Variant, maximum: int, allow_empty: bool = false) -> bool:
	if not value is String or value.length()>maximum or (value.is_empty() and not allow_empty): return false
	for index in range(value.length()):
		if value.unicode_at(index)<32 or value.unicode_at(index)>126: return false
	return true

static func display_name(world: ColonyWorld, id: int) -> String:
	if id==0: return world.chronicle_state.settlement
	var person: Dictionary = world.find(world.citizens,id)
	if not person.is_empty(): return person.name
	if world.chronicle_state.names.has(id): return world.chronicle_state.names[id]
	var building: Dictionary = world.find(world.structures,id)
	if not building.is_empty(): return building.definition.capitalize()
	for records in [world.domestic_state.animals,world.wildlife_state.animals,world.defense_state.enemies]:
		var actor: Dictionary = world.find(records,id)
		if not actor.is_empty(): return actor.get("name",actor.definition.capitalize())
	return "Object "+str(id)

static func fact(state: Dictionary, id: int) -> Dictionary:
	for record in state.facts:
		if record.id==id: return record
	return state.archive.get(id,{})

static func _capture(world: ColonyWorld, raw: Dictionary, details: Dictionary) -> Dictionary:
	var people: Array = details.get("participants",[raw.actor] if raw.actor>0 else []).duplicate()
	var names: Dictionary = {}
	for id in people: names[id]=display_name(world,id)
	names.merge(details.get("names",{}),true)
	var location: Array = details.get("location",[]).duplicate()
	if not details.has("location") and raw.actor>0:
		var actor: Dictionary = world.find(world.citizens,raw.actor)
		if actor.is_empty(): actor=world.find(world.structures,raw.actor)
		if not actor.is_empty() and not actor.get("away",false): location=[actor.x,actor.y]
	return {"participants":people,"names":names,"location":location,"changes":details.get("changes",{}).duplicate(),"causes":details.get("causes",[]).duplicate(),"salience":details.get("salience",SALIENCE.get(raw.kind,0))}

static func emit(world: ColonyWorld, raw: Dictionary, details: Dictionary = {}) -> int:
	var context: Dictionary = _capture(world,raw,details)
	var id: int = _append(world.chronicle_state,raw,context)
	# Compatibility view only. The authoritative rich ledger and retained chronicle are above.
	world.facts.append(raw.duplicate(true))
	while world.facts.size()>ORDINARY_LIMIT: world.facts.pop_front()
	return id

static func _append(state: Dictionary, raw: Dictionary, context: Dictionary) -> int:
	var causes: Array = []
	var roots: Array = []
	for id in context.causes:
		var source: Dictionary = fact(state,id)
		if not source.is_empty() and source.tick<=raw.tick and not causes.has(id):
			causes.append(id)
			if not roots.has(source.chain): roots.append(source.chain)
	causes.sort();roots.sort()
	var id: int = state.next_event_id;state.next_event_id+=1
	var chain: int = id if roots.is_empty() else roots[0]
	# An explicit multi-cause transaction joins those chains; calendar coincidence never does.
	if roots.size()>1:
		for previous in state.facts+state.archive.values():
			if roots.has(previous.chain): previous.chain=chain
	var record: Dictionary = {"id":id,"tick":raw.tick,"kind":raw.kind,"participants":context.participants,"location":context.location,"changes":context.changes,"causes":causes,"names":context.names,"text":raw.text,"salience":context.salience,"preserved":raw.kind in PRESERVED,"chain":chain}
	state.facts.append(record)
	_prune(state)
	return id

static func _prune(state: Dictionary) -> void:
	var ordinary: int = state.facts.reduce(func(n:int,f:Dictionary)->int:return n+(0 if f.preserved else 1),0)
	if ordinary<=ORDINARY_LIMIT: return
	var evicted: Dictionary = {}
	var retained: Array = []
	for record in state.facts:
		if not record.preserved and ordinary>ORDINARY_LIMIT:
			evicted[record.id]=record;ordinary-=1
		else: retained.append(record)
	state.facts=retained
	var references: Array = state.links.values().map(func(link:Dictionary)->int:return link.fact_id)
	for record in state.facts:
		references.append_array(record.causes)
		if record.chain!=record.id: references.append(record.chain)
	for entry in state.journal: references.append_array(entry.fact_ids)
	# A busy workday can produce 2,000 ordinary facts before 22:00. Keep its
	# consequential candidates as snapshots until the daily selection is committed.
	for record in evicted.values()+state.archive.values():
		if record.salience>0 and record.tick/7200>state.last_journal_day: references.append(record.id)
	var needed: Dictionary = {};var cursor: int = 0
	while cursor<references.size():
		var id: int = references[cursor];cursor+=1
		if needed.has(id): continue
		needed[id]=true
		var source: Dictionary = evicted.get(id,state.archive.get(id,{}))
		if not source.is_empty():
			references.append_array(source.causes)
			if source.chain!=source.id: references.append(source.chain)
	for id in evicted:
		if needed.has(id):
			var compact: Dictionary = evicted[id].duplicate(true)
			for field in ["participants","location","preserved"]: compact.erase(field)
			state.archive[id]=compact
	for id in state.archive.keys():
		if not needed.has(id): state.archive.erase(id)

static func _rank(a: Dictionary, b: Dictionary) -> bool:
	if a.salience!=b.salience: return a.salience>b.salience
	return a.tick<b.tick if a.tick!=b.tick else a.id<b.id

static func _select(records: Array, count: int) -> Array:
	var ranked: Array = records.filter(func(f:Dictionary)->bool:return f.salience>0)
	ranked.sort_custom(_rank)
	var result: Array = [];var chains: Dictionary = {}
	for record in ranked:
		if chains.has(record.chain): continue
		chains[record.chain]=true;result.append(record)
		if result.size()==count: break
	return result

static func advance(world: ColonyWorld) -> void:
	var state: Dictionary = world.chronicle_state;var day: int = world.tick/7200
	if world.tick%7200!=6600 or state.last_journal_day>=day: return
	var selected: Array = _select((state.facts+state.archive.values()).filter(func(f:Dictionary)->bool:return f.tick/7200==day and f.tick<=world.tick),3)
	state.journal.append({"day":day,"tick":world.tick,"fact_ids":selected.map(func(f:Dictionary)->int:return f.id)})
	state.last_journal_day=day

static func epilogue(world: ColonyWorld) -> Array:
	var selected: Array = _select(world.chronicle_state.facts+world.chronicle_state.archive.values(),8)
	selected.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.tick<b.tick if a.tick!=b.tick else a.id<b.id)
	return selected.duplicate(true)

static func highlights(world: ColonyWorld, actor: int) -> Array:
	return _select((world.chronicle_state.facts+world.chronicle_state.archive.values()).filter(func(f:Dictionary)->bool:return f.names.has(actor)),10).duplicate(true)

static func command(world: ColonyWorld, kind: String, args: Dictionary) -> String:
	if not args.get("text") is String: return "Enter text for this action"
	var text: String = args.text.strip_edges()
	if kind=="pin_moment":
		if not _printable(text,PIN_LIMIT,true): return "Moment text supports up to 256 printable Basic Latin characters"
		emit(world,{"tick":world.tick,"actor":0,"job":0,"kind":"pin_moment","text":"Pinned a moment"+(": "+text if not text.is_empty() else ".")})
		return "accepted"
	if kind!="rename": return "Unknown journal action"
	if not args.get("target") is int or args.target<0: return "Choose a citizen, building or settlement to name"
	if not _printable(text,32): return "Names require 1-32 printable Basic Latin characters after trimming"
	var id: int = args.target;var old: String = display_name(world,id)
	if id==0: world.chronicle_state.settlement=text
	else:
		var person: Dictionary = world.find(world.citizens,id)
		var building: Dictionary = world.find(world.structures,id)
		if person.is_empty() and building.is_empty(): return "Named citizen or building is no longer present"
		if not person.is_empty(): person.name=text
		else: world.chronicle_state.names[id]=text
	emit(world,{"tick":world.tick,"actor":id,"job":0,"kind":"renamed","text":old+" renamed to "+text+"."})
	return "accepted"

static func from_legacy(data: Dictionary) -> Dictionary:
	var state: Dictionary = initial_state(data.tick)
	# Earlier versions had no rename command. Preserve old text verbatim and capture known names.
	for raw in data.facts:
		var people: Array = [raw.actor] if raw.actor>0 else [];var names: Dictionary = {};var location: Array = []
		for person in data.citizens:
			if person.id==raw.actor: names[person.id]=person.name;break
		if raw.actor>0 and names.is_empty(): names[raw.actor]="Object "+str(raw.actor)
		_append(state,raw,{"participants":people,"names":names,"location":location,"changes":{},"causes":[],"salience":SALIENCE.get(raw.kind,0)})
	return state

static func _ids(value: Variant) -> bool:
	if not value is Array: return false
	var seen: Dictionary = {}
	for id in value:
		if not id is int or id<=0 or seen.has(id): return false
		seen[id]=true
	return true

static func _fact_valid(record: Variant, tick: int, definitions: Dictionary, compact: bool) -> bool:
	var keys: Array = ["id","tick","kind","changes","causes","names","text","salience","chain"]
	if not compact: keys.append_array(["participants","location","preserved"])
	if not record is Dictionary or not ColonyCodec._keys(record,keys): return false
	if not record.id is int or record.id<=0 or not record.tick is int or record.tick<1800 or record.tick>tick or not record.kind is String or record.kind.is_empty() or record.kind.length()>64 or not record.text is String or record.text.length()>8192 or not record.salience is int or record.salience not in [0,40,60,80,100] or not record.chain is int or record.chain<=0 or record.chain>record.id or not _ids(record.causes) or not record.names is Dictionary or not record.changes is Dictionary: return false
	if SALIENCE.has(record.kind) and record.salience!=SALIENCE[record.kind]: return false
	if compact and record.kind in PRESERVED: return false
	for id in record.names:
		if not id is int or id<=0 or not record.names[id] is String or record.names[id].is_empty() or record.names[id].length()>128: return false
	for item in record.changes:
		if not item is String or not definitions.items.has(item) or not record.changes[item] is int or absi(record.changes[item])>100000000: return false
	if not compact:
		if not _ids(record.participants) or not record.participants.all(func(id:int)->bool:return record.names.has(id)) or not record.location is Array or record.location.size() not in [0,2] or not record.location.all(func(n:Variant)->bool:return n is int and n>=0 and n<128) or not record.preserved is bool or record.preserved!=(record.kind in PRESERVED): return false
	return true

static func validate(state: Variant, tick: int, definitions: Dictionary) -> bool:
	if not state is Dictionary or not ColonyCodec._keys(state,["next_event_id","facts","archive","journal","last_journal_day","names","settlement","links"]) or not state.next_event_id is int or state.next_event_id<1 or not state.facts is Array or state.facts.size()>100000 or not state.archive is Dictionary or state.archive.size()>100000 or not state.journal is Array or state.journal.size()>100000 or not state.last_journal_day is int or state.last_journal_day< -1 or state.last_journal_day>tick/7200 or not state.names is Dictionary or not state.links is Dictionary or state.links.size()>100000 or not _printable(state.settlement,32): return false
	for id in state.names:
		if not id is int or id<=0 or not _printable(state.names[id],32): return false
	var records: Dictionary = {};var previous: int = 0;var ordinary: int = 0
	for record in state.facts:
		if not _fact_valid(record,tick,definitions,false) or record.id<=previous or record.id>=state.next_event_id: return false
		previous=record.id;records[record.id]=record
		if not record.preserved: ordinary+=1
	if ordinary>ORDINARY_LIMIT: return false
	for id in state.archive:
		var record: Variant = state.archive[id]
		if not id is int or not _fact_valid(record,tick,definitions,true) or record.id!=id or records.has(id) or id>=state.next_event_id: return false
		records[id]=record
	for name in state.links:
		var link: Variant = state.links[name]
		if not name is String or name.is_empty() or name.length()>128 or not link is Dictionary or not ColonyCodec._keys(link,["fact_id"]) or not link.fact_id is int or not records.has(link.fact_id): return false
	for record in records.values():
		if not records.has(record.chain): return false
		for cause in record.causes:
			if not records.has(cause) or cause>=record.id or records[cause].tick>record.tick or records[cause].chain!=record.chain: return false
	previous=-1
	for entry in state.journal:
		if not entry is Dictionary or not ColonyCodec._keys(entry,["day","tick","fact_ids"]) or not entry.day is int or entry.day<0 or entry.day<=previous or not entry.tick is int or entry.tick!=entry.day*7200+6600 or entry.tick>tick or not _ids(entry.fact_ids) or entry.fact_ids.size()>3: return false
		var chains: Dictionary = {}
		for id in entry.fact_ids:
			if not records.has(id) or records[id].tick/7200!=entry.day or records[id].tick>entry.tick or records[id].salience==0: return false
			# Later explicit events may merge chains that were distinct when this entry was written.
			chains[records[id].chain]=true
		previous=entry.day
	if not state.journal.is_empty() and state.last_journal_day!=state.journal[-1].day: return false
	return true

static func remember(world: ColonyWorld, key: String, id: int) -> void:
	if id>0 and not fact(world.chronicle_state,id).is_empty(): world.chronicle_state.links[key]={"fact_id":id}

static func causes(world: ColonyWorld, key: String) -> Array:
	var id: int = world.chronicle_state.links.get(key,{}).get("fact_id",0)
	return [id] if id>0 and not fact(world.chronicle_state,id).is_empty() else []

static func has_ancestor(world: ColonyWorld, ids: Array, kind: String) -> bool:
	var pending: Array = ids.duplicate();var seen: Dictionary = {}
	while not pending.is_empty():
		var id: int = pending.pop_back()
		if seen.has(id): continue
		seen[id]=true
		var record: Dictionary = fact(world.chronicle_state,id)
		if record.is_empty(): continue
		if record.kind==kind: return true
		pending.append_array(record.causes)
	return false

static func active_memories(world: ColonyWorld, person: Dictionary) -> Array:
	var result: Array = []
	var request_success: int = person.fulfilled_request_until
	var request_failure: int = person.broken_promise_until
	_memory(world,result,"Fulfilled personal request",100,request_success,"request_success:"+str(person.id),0)
	_memory(world,result,"Broken accepted promise",-60,request_failure,"request_failure:"+str(person.id),0)
	if request_failure<=world.tick:
		var conflict: Dictionary = {}
		for pair in world.social_state.pairs.values():
			if person.id in [pair.a,pair.b] and pair.conflict_until>world.tick and pair.conflict_until>conflict.get("conflict_until",0): conflict=pair
		if not conflict.is_empty(): _memory(world,result,"Disagreement",-60,conflict.conflict_until,"conflict:"+ColonySocial.key(conflict.a,conflict.b),0)
	for death in world.social_state.deaths:
		if death.actor==person.id: continue
		var friend: bool = death.relationships.get(person.id,0)>=40
		var duration: int = 21600 if friend else 14400
		var expires: int = death.tick+duration
		if expires>world.tick: _memory(world,result,"Grief for "+death.name,-(180 if friend else 80)*(expires-world.tick)/duration,expires,"death:"+str(death.actor),0)
	if person.traits.has("Curious"):
		_memory(world,result,"A research discovery",60,world.production_state.discoveries.get(person.id,0),"discovery:"+str(person.id),0)
	_memory(world,result,"Communal supper",60,world.charter_state.supper_memories.get(person.id,0),"supper",0)
	_memory(world,result,"Shared a traveling story",40,person.story_memory_until,"story:"+str(person.id),0)
	_memory(world,result,"Slept in assigned bed",40 if person.traits.has("Restless") else 80,person.bed_memory_until,"sleep:"+str(person.id))
	_memory(world,result,"Completed leisure",60,person.leisure_memory_until,"leisure:"+str(person.id))
	_memory(world,result,"Quiet leisure" if person.traits.has("Private") else "Shared leisure with friend",40,person.friend_leisure_until,"friend_leisure:"+str(person.id))
	_memory(world,result,"Worked at preferred category",40,person.preferred_memory_until,"preferred_work:"+str(person.id))
	if not person.traits.has("Outdoorsy"): _memory(world,result,"Ate raw produce",-50,person.raw_memory_until,"raw_food:"+str(person.id))
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if a.priority!=b.priority: return a.priority<b.priority
		if absi(a.modifier)!=absi(b.modifier): return absi(a.modifier)>absi(b.modifier)
		return a.expires<b.expires if a.expires!=b.expires else a.text<b.text)
	for memory in result: memory.erase("priority")
	return result.slice(0,3)

static func _memory(world: ColonyWorld, output: Array, text: String, modifier: int, expires: int, key: String, priority: int = 1) -> void:
	if expires<=world.tick: return
	var links: Array = causes(world,key) if not key.is_empty() else []
	output.append({"text":text,"modifier":modifier,"expires":expires,"fact_id":0 if links.is_empty() else links[0],"priority":priority})
