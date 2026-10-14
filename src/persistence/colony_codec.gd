class_name ColonyCodec
extends RefCounted
const FORMAT: String = "brackenward-development-colony"
const MAX_BYTES: int = 64 * 1024 * 1024
const VERSION: int = 5

static func encode(world: ColonyWorld, snapshot_name: String = "", sequence: int = 0) -> PackedByteArray:
	var payload: String = JSON.stringify(ColonyState.pack(world.payload()), "", true)
	return wrap_payload(world,payload,snapshot_name,sequence)

static func wrap_payload(world: ColonyWorld, payload: String, snapshot_name: String = "", sequence: int = 0) -> PackedByteArray:
	return JSON.stringify({"format": FORMAT, "version": VERSION, "content": ColonyWorld.CONTENT_VERSION,
		"content_hash":world.definitions.content_hash, "snapshot_name":snapshot_name, "engine": "4.7.2.ed1daf0bf", "generator_version":world.generator_version, "campaign_id":world.session_id, "sequence":str(sequence), "timestamp":Time.get_datetime_string_from_system(true), "payload": payload, "sha256": payload.sha256_text()}, "", true).to_utf8_buffer()

static func decode(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty() or bytes.size() > MAX_BYTES:
		return {"error": "Colony snapshot is empty or exceeds 64 MiB"}
	var parser: JSON = JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {"error": "Malformed colony snapshot"}
	var envelope: Dictionary = parser.data
	if (envelope.get("version") == 1 or envelope.get("version") == 2):
		var legacy: Dictionary = M2Codec.decode(bytes)
		if legacy.has("error"): return legacy
		return restore(ColonyMigrations.from_m2(legacy.world.payload(),ColonyCatalog.load_data().content_hash,ColonyCatalog.load_data().items.keys()),legacy.get("snapshot_name",""),true)
	var keys: Array = ["format","version","content","content_hash","snapshot_name","engine","generator_version","campaign_id","sequence","timestamp","payload","sha256"]
	if not _keys(envelope,keys) or envelope.format != FORMAT or (envelope.version!=3 and envelope.version!=4 and envelope.version!=VERSION) or (envelope.content != ColonyWorld.CONTENT_VERSION and envelope.content not in ["colony-v1","colony-v2","colony-v3","colony-v4","colony-v5"] and not (envelope.version == 3 and envelope.content == "m3-people-seasons-1")):
		return {"error":"Unsupported save version %s / content %s. This build supports envelope 5, content %s and earlier colony migration. Original files retained." % [str(envelope.get("version","?")).left(16),str(envelope.get("content","?")).left(64),ColonyWorld.CONTENT_VERSION]}
	if not envelope.generator_version is float or (envelope.generator_version != 0 and envelope.generator_version != 1) or not envelope.campaign_id is String or not envelope.sequence is String or not envelope.sequence.is_valid_int() or envelope.sequence.length() > 15 or envelope.sequence.begins_with("-") or not envelope.timestamp is String or envelope.timestamp.length() > 40:
		return {"error":"Invalid snapshot metadata"}
	if not envelope.payload is String or not envelope.sha256 is String or envelope.payload.sha256_text() != envelope.sha256:
		return {"error": "Snapshot checksum mismatch"}
	if not envelope.get("snapshot_name","") is String or envelope.get("snapshot_name","").length() > 64:
		return {"error":"Invalid snapshot name"}
	if parser.parse(envelope.payload) != OK:
		return {"error": "Malformed simulation payload"}
	var decoded: Variant = ColonyState.unpack(parser.data)
	if not decoded is Dictionary:
		return {"error": "Invalid integer, coordinate or state encoding"}
	var data: Dictionary = decoded
	if envelope.content_hash != data.get("content_hash") or data.get("session_id") != envelope.campaign_id or data.get("generator_version") != int(envelope.generator_version):
		return {"error":"Catalog or campaign identity mismatch; original save retained"}
	return restore(data,envelope.get("snapshot_name",""))

static func restore(data: Dictionary, snapshot_name: String = "", initialize_weather: bool = false) -> Dictionary:
	if data.get("schema_revision") is int and data.schema_revision > ColonyWorld.SCHEMA_REVISION:
		return {"error":"Campaign requires a newer build: schema revision %d (this build supports %d). Original files retained." % [data.schema_revision,ColonyWorld.SCHEMA_REVISION]}
	var world: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data())
	if data.get("content") == "m3-people-seasons-1":
		var previous: Dictionary = ColonyCatalog.load_data("res://data/catalogs/m3.json")
		if data.get("content_hash") != previous.content_hash: return {"error":"Unknown M3 catalog; original files retained"}
		data = ColonyMigrations.catalog_v1(data,world.definitions,previous.items.keys())
	if data.get("content") == "colony-v1":
		var previous: Dictionary = ColonyCatalog.load_data("res://data/catalogs/colony_v1.json")
		if data.get("content_hash") != previous.content_hash: return {"error":"Unknown released catalog; original files retained"}
		data = ColonyMigrations.catalog_v1(data,world.definitions,previous.items.keys())
	if data.get("content") in ["colony-v2","colony-v3","colony-v4","colony-v5"]:
		var previous_version: String = data.content
		var previous: Dictionary = ColonyCatalog.load_data("res://data/catalogs/%s.json" % previous_version.replace("-","_"))
		if data.get("content_hash") != previous.content_hash: return {"error":"Unknown released %s catalog; original files retained" % previous_version.trim_prefix("colony-")}
		# Definitions are identical. Change only the declared content header;
		# unlike older acquisition upgrades, preserve even user filter ordering.
		data=data.duplicate(true);data.content=ColonyWorld.CONTENT_VERSION;data.content_hash=world.definitions.content_hash
	if initialize_weather and data.get("weather_state") == {}:
		# Only pure legacy migration supplies the empty initial schedule.
		world.tick = data.tick
		world.seed = data.seed
		world.weather = data.weather
		ColonyWeather.initialize(world)
		data.weather_state = world.weather_state.duplicate(true)
	var introduce_wildlife: bool = data.get("schema_revision",0) is int and data.get("schema_revision",0)<9
	data = ColonyMigrations.upgrade_current(data,world)
	var error: String = _validate(data, world)
	if not error.is_empty():
		return {"error": error}
	for field in data:
		if field not in ["content","content_hash"]:
			if data[field] is Array:
				world.get(field).assign(data[field])
			else:
				world.set(field, data[field])
	world.record_indexes.clear()
	world.navigation_dirty=true;world.reachability_dirty=true;world.rooms_dirty=true
	world.reset_job_queries()
	world.reset_stack_queries()
	var errors: Array[String] = world.invariant_errors()
	if not errors.is_empty():
		return {"error": "Invalid colony invariants: " + str(errors)}
	if introduce_wildlife: ColonyWildlife.introduce_on_saved_map(world)
	return {"world":world,"snapshot_name":snapshot_name}

static func _keys(record: Dictionary, keys: Array) -> bool:
	# Schema lists contain unique field names. Native membership avoids sorting
	# and stringifying both sides for every retained historical record, while
	# rejecting extra, missing and incorrectly typed field keys.
	return record.size()==keys.size() and record.has_all(keys)

static func _record(value: Variant, template: Dictionary) -> bool:
	if not value is Dictionary or not _keys(value, template.keys()):
		return false
	for key in template:
		if typeof(value[key]) != typeof(template[key]):
			return false
	return true

static func _validate(data: Dictionary, world: ColonyWorld) -> String:
	if not _record(data, world.payload()) or data.content != ColonyWorld.CONTENT_VERSION or data.content_hash != world.definitions.content_hash or data.tick < 1800 or data.seed < 0 or data.seed > 4294967295 or data.next_id > 1000000000 or data.next_command_id > 1000000000 or data.session_id.length() > 80 or data.schema_revision != ColonyWorld.SCHEMA_REVISION or data.generator_version not in [0,1] or not ColonyGeneration.SITES.has(data.site_id) or not ColonyWeather.validate(data.weather_state,data.tick):
		return "Invalid world header or unknown fields"
	# Job validators refer to the supper bank before the full cross-record charter check.
	if not ColonyCodec._keys(data.charter_state,ColonyCharter.initial_state().keys()) or not data.charter_state.supper is Dictionary: return "Invalid charter header"
	if not data.charter_state.supper.is_empty():
		var supper: Dictionary = data.charter_state.supper
		if not _keys(supper,["job","state","start","end","eligible","attended","eaten","slots","reason","completed_at"]) or not supper.job is int or not supper.state is String or not supper.eligible is Array or not supper.slots is Array: return "Invalid supper header"
		for slot in supper.slots:
			if not slot is Dictionary or not _keys(slot,["table","x","y","actor","job"]) or not slot.values().all(func(v:Variant)->bool:return v is int): return "Invalid supper slot"
	if not ColonyGeneration.validate_state(data.terrain_state,data.generator_version): return "Invalid generated map data"
	world.generator_version = data.generator_version; world.terrain_state = data.terrain_state
	if data.generator_version == 0 and data.site_id != "meadow_reach": return "Invalid legacy site"
	if (data.citizens.size()<4 or data.citizens.size()>100000) or data.fields.size() > 16384 or data.structures.size() > 16384 or data.resources.size() > 16384 or data.stacks.size() > 100000 or data.jobs.size() > 100000 or data.pending_commands.size() > 4096 or data.facts.size() > 100000:
		return "Invalid record counts"
	if not ColonyWeather.valid_geometry(world,data.weather_state): return "Forecast flood coverage does not match saved geography"
	if not data.researched.all(func(value:Variant)->bool:return value is String and value in ["woodcraft","storecraft","farming","herbalism","weaving","masonry","metalwork","trailcraft","husbandry","signalcraft","commonlife","valley_charter"]) or data.weather not in ["clear","rain","fog","snow","drought","flood","cold_snap"]:
		return "Unknown research/weather state"
	for table in [data.citizens,data.structures,data.resources,data.stacks,data.jobs,data.stores,data.fields]:
		if not table.all(func(r:Variant)->bool:return r is Dictionary and r.get("id") is int and r.id>0): return "Invalid entity reference schema"
	var citizen_ids: Array = []
	for citizen in data.citizens:
		if not ColonyAppearance.valid(citizen.get("appearance")): return "Invalid citizen appearance"
		if not _record(citizen, world.citizens[0]) or citizen.id<1 or citizen.name.length() > 64:
			return "Invalid citizen schema"
		citizen_ids.append(citizen.id)
		if not _keys(citizen.skills, ColonyWorld.SKILLS) or not _keys(citizen.xp, ColonyWorld.SKILLS) or not _keys(citizen.preferences, ColonyWorld.CATEGORIES) or not _keys(citizen.equipment, ["toolkit", "cloak", "weapon", "vest"]):
			return "Invalid skills/preferences/equipment"
		for skill in ColonyWorld.SKILLS:
			if not citizen.skills[skill] is int or citizen.skills[skill] < 0 or citizen.skills[skill] > 5 or not citizen.xp[skill] is int or citizen.xp[skill] < 0:
				return "Invalid skill values"
		for category in ColonyWorld.CATEGORIES:
			if not citizen.preferences[category] is int or citizen.preferences[category] not in [0, 1, 2, 3]:
				return "Invalid job preferences"
		for field in ColonySocial.citizen_defaults():
			if field == "private_leisure_day":
				if citizen[field] < -1 or citizen[field] > data.tick / 7200: return "Invalid private leisure day"
			elif citizen[field] < 0 or citizen[field] > data.tick+28800: return "Invalid personal memory/request counter"
		if citizen.request_cycle >= ColonySocial.REQUESTS.size(): return "Invalid personal request cycle"
		if citizen.progress < 0 or citizen.progress > 9999 or citizen.edge_x < 0 or citizen.edge_x >= 128 or citizen.edge_y < 0 or citizen.edge_y >= 128 or citizen.health < 0 or citizen.health > 100:
			return "Invalid citizen movement/health"
		if citizen.hunger_rem < 0 or citizen.hunger_rem >= 7200 or citizen.rest_rem < 0 or citizen.rest_rem >= 300 or citizen.move_base_rem < 0 or citizen.move_base_rem >= 120 or citizen.move_rem < 0 or citizen.move_rem >= 1000 or citizen.injury_rem < 0 or citizen.injury_rem >= 1000 or citizen.travel_credit < 0 or citizen.travel_credit >= 10000 or citizen.starving_ticks < 0:
			return "Invalid need/movement remainder"
		if citizen.route_goal.size() not in [0, 2] or citizen.traits.size() != 2:
			return "Invalid route goal or traits"
		for coordinate in citizen.route_goal:
			if not coordinate is int or coordinate < 0 or coordinate >= 128:
				return "Invalid route goal"
		if citizen.shift not in ["Normal","Night shift"] or citizen.pending_shift not in ["","Normal","Night shift"]:
			return "Unknown work shift"
		for trait_name in citizen.traits:
			if not trait_name is String or trait_name not in ["Kind", "Homebody", "Steady", "Sociable", "Outdoorsy", "Restless", "Curious", "Private"]:
				return "Unknown trait"
		if citizen.equipment.toolkit not in ["", "toolkit", "forged_toolkit"] or citizen.equipment.cloak not in ["", "cloak"] or citizen.equipment.weapon not in ["", "spear", "bow"]:
			return "Unknown equipment"
		if citizen.equipment.vest not in ["","vest"]: return "Unknown vest"
		for point in citizen.route:
			if not point is Vector2i:
				return "Invalid route"
	var sorted_ids: Array = citizen_ids.duplicate();sorted_ids.sort()
	if citizen_ids!=sorted_ids: return "Residents must be stored in ascending ID order"
	if data.citizens.filter(func(c:Dictionary)->bool:return not c.death_recorded and not c.departed).size()>20: return "Resident limit exceeded"
	if not [1,2,3,4].all(func(id:int)->bool:return citizen_ids.has(id)): return "Initial resident history missing"
	for event in data.opportunity_state.offers:
		if not event.jobs.all(func(id:int)->bool:return data.jobs.any(func(j:Dictionary)->bool:return j.id==id and j.target==event.id and j.kind in ["minor_work","minor_study"])): return "Missing minor opportunity work"
	if not ColonyCombat.validate(data.citizens,data.tick,data.defense_state.raids): return "Invalid Guard experience state"
	if not ColonyDefense.validate(data.defense_state,data.citizens,data.structures,data.stacks,world.definitions,data.tick): return "Invalid defense state"
	if not ColonyFire.validate(data.fire_state,data.structures,data.stacks,data.citizens,data.tick): return "Invalid fire state"
	if not ColonyOpportunities.validate(data.opportunity_state,data.citizens,world.definitions,data.tick): return "Invalid minor opportunity state"
	if not ColonyDirector.validate(data.director_state,data.tick,data.defense_state.raids,data.fire_state.fires,data.structures): return "Invalid director state"
	if not ColonyRegion.validate(data.region_state,data.citizens,world.definitions,data.tick): return "Invalid regional state"
	for trip in data.region_state.trips:
		if not trip.args.goats.all(func(id:Variant)->bool:return data.domestic_state.animals.any(func(a:Dictionary)->bool:return a.id==id and a.definition=="pack_goat")) or (trip.args.pen>0 and not data.domestic_state.pens.any(func(p:Dictionary)->bool:return p.id==trip.args.pen)): return "Missing expedition goat or pen"
	if not ColonyTrade.validate(data.trade_state,world.definitions,data.tick): return "Invalid trade state"
	if not ColonyPopulation.validate(data.population_state,data.citizens,data.tick): return "Invalid newcomer state"
	if not ColonyEquipment.validate(data.equipment_state,data.citizens): return "Invalid equipment policies"
	if not ColonyWildlife.validate(data.wildlife_state,world,data.tick): return "Invalid wildlife state"
	for citizen in data.citizens:
		if citizen.story_memory_until<0 or citizen.story_memory_until>data.tick+7200: return "Invalid traveling story memory"
		if citizen.attack_ready < 0 or citizen.attack_ready > data.tick+30: return "Invalid attack cooldown"
	if not ColonyProduction.validate(data.production_state,world.definitions,citizen_ids): return "Invalid production/research state"
	if not ColonyCare.validate(data.care_state,data.citizens,data.tick): return "Invalid injury/care state"
	if not ColonySocial.validate(data.social_state,data.citizens,data.tick): return "Invalid relationship/request state"
	for structure in data.structures:
		if not _record(structure, world.structures[0]) or (structure.definition != "supply_cart" and not world.definitions.buildings.has(structure.definition)) or structure.rotation not in [0, 1, 2, 3] or not _position(structure):
			return "Invalid structure"
		if structure.health<0 or structure.health>world.definitions.buildings[structure.definition].health or (structure.health==0 and structure.fuel>0): return "Invalid structure health/fuel state"
		if structure.fuel < 0 or structure.fuel > 8:
			return "Invalid hearth fuel"
		for point in world.footprint(structure):
			if not ColonyWorld.inside(point):
				return "Building footprint outside map"
	if not ColonyDomestic.validate(data.domestic_state,world,data.tick): return "Invalid livestock state"
	for animal in data.domestic_state.animals:
		if not data.structures.any(func(s:Dictionary)->bool:return s.id==animal.barn and s.definition=="barn") or (animal.handler>0 and not data.citizens.any(func(c:Dictionary)->bool:return c.id==animal.handler)): return "Invalid livestock shelter or handler"
	for order in data.production_state.orders:
		var station: Dictionary = {}
		for structure in data.structures:
			if structure.id == order.station: station = structure; break
		if station.is_empty() or station.definition != world.definitions.recipes[order.recipe].station:
			return "Production order has no matching workstation"
	for project in data.researched:
		if data.production_state.project == project or data.production_state.queue.has(project): return "Completed research cannot remain selected or queued"
	for resource in data.resources:
		if not _record(resource, world.resources[0]) or not world.definitions.resources.has(resource.definition) or not _position(resource) or resource.remaining < 0:
			return "Invalid resource"
		if resource.remaining > world.definitions.resources[resource.definition].yield_count:
			return "Invalid remaining yield"
	if not ColonyNature.validate(data.nature_state,data.resources,data.structures,data.tick): return "Invalid forestry/fishing state"
	for stack in data.stacks:
		if not _record(stack, world.stacks[0]) or not world.definitions.items.has(stack.item) or stack.count < 0 or stack.count > 100000 or not _position(stack) or stack.location not in ["ground", "store", "carry", "escrow", "output", "animal_feed", "move_bundle", "expedition_cargo"] or stack.age < 0:
			return "Invalid item stack"
		if stack.location == "animal_feed" and (not ColonyDomestic.feed_item(world,stack.item) or not data.structures.any(func(s:Dictionary)->bool:return s.id == stack.owner and s.definition == "barn")): return "Invalid barn feed ownership"
		for reservation in stack.reservations.values():
			if not reservation is int or reservation < 1:
				return "Invalid reservation"
	for bundle in data.stacks:
		if bundle.location=="move_bundle" and not data.jobs.any(func(j:Variant)->bool:return j is Dictionary and j.get("id")==bundle.owner and j.get("kind")=="move_furniture" and j.get("inputs") is Dictionary and j.inputs.has(bundle.item)): return "Invalid retained material bundle"
	for barn in data.structures:
		if barn.definition=="barn":
			var feed_units: int = 0
			var output_units: int = 0
			for stack in data.stacks:
				if stack.owner==barn.id and stack.location=="animal_feed": feed_units += stack.count
				if stack.owner==barn.id and stack.location=="output": output_units += stack.count
			if feed_units>24 or output_units>24: return "Barn buffer exceeds 24 units"
	var job_template: Dictionary = world._job("gather", "Gathering", "Field", world.resources[0].id, Vector2i(1, 1), 1000)
	for job in data.jobs:
		if not job.get("queue_state") is String or job.queue_state not in ["","Ready","Blocked","Fetching","Moving","Working","Delivering"] or (job.get("state")=="Queued" and (job.get("worker")!=0 or job.queue_state.is_empty())): return "Invalid queued work contract"
		if not _record(job, job_template) or job.kind not in ["gather", "haul", "cook", "build", "eat", "sleep", "prepare", "sow", "harvest", "replant", "leisure", "depart", "fuel", "mediate", "craft", "research", "rescue", "treat", "feed", "bury", "recover", "plant_tree", "clear_sapling", "fish", "hunt", "escort_hunt", "butcher", "escape", "stock_feed", "lead_animal", "collect_animal", "slaughter", "build_helper", "step_aside", "equip", "repair", "demolish", "move_furniture", "cart_move", "arrival", "trade", "expedition_pack", "expedition_meet", "expedition_walk", "extinguish", "defend", "shelter", "raid_pay", "enemy_treat", "minor_work", "minor_study", "supper", "supper_reserve"] or not _position(job) or job.work < 0 or job.work > job.required or job.worker < 0 or (job.worker>0 and not citizen_ids.has(job.worker)) or job.state not in ["Ready", "Blocked", "Queued", "Fetching", "Moving", "Working", "Delivering", "Complete", "Canceled"]:
			return "Invalid job"
		if job.priority not in [1,2,3] or job.created<0 or job.created>data.tick or job.retry<0: return "Invalid job scheduling metadata"
		if job.kind in ["minor_work","minor_study"] and not ColonyOpportunities.valid_job(data,job,world.definitions): return "Invalid opportunity work contract"
		if job.kind in ["supper","supper_reserve"] and not ColonyCharter.valid_job(data,job): return "Invalid communal supper task"
		if job.care_goal.size() not in [0,2] or not job.care_goal.all(func(n:Variant)->bool:return n is int and n >= 0 and n < 128): return "Invalid care destination"
		if job.emergency and job.kind not in ["rescue","treat","extinguish"]: return "Invalid emergency work type"
		if job.kind in ["treat","feed","rescue"] and not data.citizens.any(func(c:Dictionary)->bool:return c.id == job.target): return "Missing care patient"
		if job.kind == "bury" and not data.care_state.bodies.any(func(b:Dictionary)->bool:return b.id == job.target): return "Missing burial target"
		if job.kind == "rescue" and (job.care_goal.size() != 2 or job.definition not in ["pickup","carrying"] or job.required != 0 or not job.inputs.is_empty()): return "Invalid rescue contract"
		if job.kind == "treat" and (job.definition not in ["medicine","herb","stabilize"] or job.required != {"medicine":10000,"herb":16000,"stabilize":24000}.get(job.definition) or job.inputs != ({} if job.definition == "stabilize" else {job.definition:1})): return "Invalid treatment contract"
		if job.kind == "feed" and (job.required != 2000 or job.inputs.size() != 1 or not job.inputs.keys().all(func(item:Variant)->bool:return world.definitions.items.get(item,{}).get("fullness",0) > 0)): return "Invalid feeding contract"
		if job.kind == "bury" and job.required != 12000: return "Invalid burial contract"
		if job.kind in ["plant_tree","clear_sapling","fish"] and job.required != {"plant_tree":4000,"clear_sapling":2000,"fish":12000}[job.kind]: return "Invalid nature work contract"
		if job.kind in ["plant_tree","clear_sapling"] and not data.resources.any(func(r:Dictionary)->bool:return r.id == job.target and r.definition == "tree"): return "Missing tree work target"
		if job.kind == "fish" and not data.structures.any(func(s:Dictionary)->bool:return s.id == job.target and s.definition == "fishing_pier"): return "Missing fishing pier"
		if job.kind in ["hunt","escort_hunt"] and (job.required != 0 or not data.wildlife_state.animals.any(func(a:Dictionary)->bool:return a.id == job.target)): return "Invalid hunting target"
		if job.kind == "butcher" and (not world.definitions.animals.has(job.definition) or job.required != world.definitions.animals[job.definition].work_milli or not data.wildlife_state.carcasses.any(func(c:Dictionary)->bool:return c.id == job.target)): return "Invalid butchering contract"
		if job.kind in ["lead_animal","collect_animal","slaughter"] and not data.domestic_state.animals.any(func(a:Dictionary)->bool:return a.id == job.target): return "Missing domestic animal"
		if job.kind == "lead_animal" and (job.required != 0 or job.care_goal.size() != 2 or not job.inputs.is_empty()): return "Invalid animal leading contract"
		if job.kind in ["collect_animal","slaughter"] and (job.required != (4000 if job.kind == "collect_animal" else 10000) or not job.inputs.is_empty()): return "Invalid livestock work contract"
		if job.kind == "stock_feed" and (job.required != 0 or job.inputs.size() != 1 or not job.inputs.keys().all(func(item:Variant)->bool:return ColonyDomestic.feed_item(world,item)) or not data.structures.any(func(s:Dictionary)->bool:return s.id == job.target and s.definition == "barn")): return "Invalid barn feed task"
		if job.kind=="move_furniture" and (job.definition not in ColonyMaintenance.MOVABLE or job.care_goal.size()!=2 or not _keys(job.memo,["phase","cooking","health","user","store"]) or job.memo.phase not in ["dismantle","rebuild"] or not job.memo.cooking is bool or not job.memo.health is int or job.memo.health<1 or not job.memo.user is int or not job.memo.store is Dictionary or job.required!=world.definitions.buildings[job.definition].work_milli or job.inputs!=({} if job.memo.phase=="dismantle" else world.definitions.buildings[job.definition].materials)): return "Invalid furniture move"
		if job.kind=="move_furniture" and (not data.structures.any(func(s:Dictionary)->bool:return s.id==job.target and s.definition==job.definition) or job.memo.health>world.definitions.buildings[job.definition].health or (job.memo.user>0 and not data.citizens.any(func(c:Dictionary)->bool:return c.id==job.memo.user))): return "Missing moving furniture or assigned user"
		if job.kind=="move_furniture" and not job.memo.store.is_empty():
			if not _record(job.memo.store,world.stores[0]) or job.memo.store.id!=job.target or job.memo.store.capacity<1 or job.memo.store.capacity>100000 or job.memo.store.priority not in [1,2,3] or not job.memo.store.filters.all(func(item:Variant)->bool:return item is String and world.definitions.items.has(item)): return "Invalid retained furniture storage settings"
		if job.kind not in ["move_furniture","cart_move","extinguish","minor_study","supper"] and not job.memo.is_empty(): return "Unexpected work memo"
		if job.kind=="cart_move" and (job.required!=20000 or not job.inputs.is_empty() or job.care_goal.size()!=2 or not _keys(job.memo,["phase"]) or job.memo.phase not in ["prepare","push"] or (job.memo.phase=="push" and job.work!=job.required) or not data.structures.any(func(s:Dictionary)->bool:return s.id==job.target and s.definition=="supply_cart")): return "Invalid supply cart move"
		if job.kind in ["repair","demolish"] and (not world.definitions.buildings.has(job.definition) or not data.structures.any(func(s:Dictionary)->bool:return s.id==job.target and s.definition==job.definition)): return "Invalid maintenance target"
		if job.kind == "repair" and (job.amount<1 or job.amount>world.definitions.buildings[job.definition].health or job.required != job.amount*100 or job.inputs != {ColonyMaintenance.dominant(world.definitions.buildings[job.definition]):(job.amount+49)/50}): return "Invalid repair quantities"
		if job.kind == "demolish" and (job.required != ((world.definitions.buildings[job.definition].work_milli+1999)/2000)*1000 or not job.inputs.is_empty()): return "Invalid demolition work"
		if job.kind=="defend" and (job.required!=0 or not job.inputs.is_empty() or not citizen_ids.has(job.target)): return "Invalid rally assignment"
		if job.kind=="raid_pay" and (job.required!=0 or not data.defense_state.raids.any(func(r:Dictionary)->bool:return r.id==job.target and (r.pay_job==job.id or (job.state=="Canceled" and job.worker==0)))): return "Invalid raid supplies"
		if job.kind=="enemy_treat" and (not data.defense_state.enemies.any(func(e:Dictionary)->bool:return e.id==job.target) or job.definition not in ["","herb","medicine"] or job.required!=({"":24000,"herb":16000,"medicine":10000}[job.definition]) or job.inputs!=({} if job.definition.is_empty() else {job.definition:1})): return "Invalid neutral visitor treatment"
		if job.kind=="extinguish" and (job.required!=8000 or not job.inputs.is_empty() or not data.fire_state.fires.any(func(f:Dictionary)->bool:return f.id==job.target) or not _keys(job.memo,["phase","water_work","water_x","water_y"]) or job.memo.phase not in ["water","carry","apply"] or not job.memo.water_work is int or job.memo.water_work<0 or job.memo.water_work>2000 or not job.memo.water_x is int or not job.memo.water_y is int or not ColonyWorld.inside(Vector2i(job.memo.water_x,job.memo.water_y))): return "Invalid firefighting task"
		if job.kind=="expedition_pack" and (job.required!=0 or not data.region_state.trips.any(func(t:Dictionary)->bool:return t.id==job.target and t.pack_job==job.id and t.quote.inputs==job.inputs)): return "Invalid expedition packing job"
		if job.kind in ["expedition_meet","expedition_walk"] and (job.required!=0 or not job.inputs.is_empty() or not citizen_ids.has(job.target) or not data.region_state.trips.any(func(t:Dictionary)->bool:return t.id==job.order and t.args.party.has(job.target))): return "Invalid expedition walking job"
		if job.kind=="trade" and (job.required!=0 or not data.trade_state.exchanges.any(func(e:Dictionary)->bool:return e.id==job.target and e.job==job.id and e.pay==job.inputs)): return "Invalid trade delivery"
		if job.kind=="arrival" and (job.required!=0 or not job.inputs.is_empty() or not citizen_ids.has(job.target) or not data.population_state.offers.any(func(o:Dictionary)->bool:return o.id==job.order and o.actor==job.target)): return "Invalid newcomer arrival"
		if job.kind == "equip" and (job.required != 2000 or not ColonyEquipment.SLOTS.has(job.definition) or not data.citizens.any(func(c:Dictionary)->bool:return c.id==job.target) or job.inputs.size()>1 or not job.inputs.keys().all(func(item:Variant)->bool:return ColonyEquipment.SLOTS[job.definition].has(item) and job.inputs[item]==1)): return "Invalid equipment transaction"
		if job.kind == "build_helper" and (job.required != 0 or not job.inputs.is_empty() or not data.jobs.any(func(p:Dictionary)->bool:return p.id==job.order and p.kind=="build" and p.definition==job.definition)): return "Invalid construction helper"
		if job.kind == "build" and not world.definitions.buildings.has(job.definition):
			return "Unknown building definition"
		if job.kind == "build" and (job.inputs != world.definitions.buildings[job.definition].materials or job.required != world.definitions.buildings[job.definition].work_milli):
			return "Construction contract mismatch"
		if job.kind == "craft":
			if not world.definitions.recipes.has(job.definition): return "Unknown crafting recipe"
			var recipe: Dictionary = world.definitions.recipes[job.definition]
			if job.required != recipe.work_milli or job.output != recipe.outputs or job.order < 1: return "Invalid crafting contract"
			var order: Dictionary = {}
			for record in data.production_state.orders:
				if record.id == job.order: order = record; break
			if order.is_empty() or order.station != job.target or order.recipe != job.definition: return "Crafting job has no matching order"
			for item in recipe.materials:
				if job.inputs.get(item) != recipe.materials[item]: return "Invalid recipe material quantity"
			var food: int = 0
			for item in job.inputs:
				if recipe.alternatives.has(item): food += job.inputs[item]
				elif not recipe.materials.has(item): return "Unknown recipe ingredient"
			if food != recipe.food_count: return "Invalid alternative ingredient quantity"
		if job.kind == "research" and (not world.definitions.research.has(job.definition) or job.required != world.definitions.research[job.definition].points*1000): return "Invalid research contract"
		if job.kind == "mediate" and (not data.social_state.pairs.has(job.definition) or job.required != 12000): return "Invalid mediation contract"
		for worker in job.worker_days:
			if not worker is int or not citizen_ids.has(worker) or not job.worker_days[worker] is int or job.worker_days[worker] < 0 or job.worker_days[worker] > data.tick / 7200: return "Invalid contributor day"
		if job.kind == "eat" and (job.required != 2000 or job.inputs.size() != 1):
			return "Eating contract mismatch"
		if job.kind == "cook":
			var food_count: int = 0
			for item in job.inputs:
				if item in world.definitions.recipes.cook_meals.alternatives and job.inputs[item] is int:
					food_count += job.inputs[item]
			if job.required != 8000 or job.output != {"meal": 2} or job.inputs.get("wood", 0) != 1 or food_count != 4:
				return "Cooking contract mismatch"
		for item in job.inputs:
			if not world.definitions.items.has(item) or not job.inputs[item] is int or job.inputs[item] < 1 or job.inputs[item] > 1000:
				return "Invalid job inputs"
		for item in job.output:
			if not world.definitions.items.has(item) or not job.output[item] is int or job.output[item] < 1 or job.output[item] > 50:
				return "Invalid job outputs"
		for worker in job.rate_remainders:
			var remainders: Variant = job.rate_remainders[worker]
			if not worker is int or not citizen_ids.has(worker) or not remainders is Array or remainders.size() != 4:
				return "Invalid work remainders"
			for remainder in remainders:
				if not remainder is int or remainder < 0 or remainder >= 1000:
					return "Invalid work remainders"
		for worker in job.pending_xp:
			if not worker is int or not citizen_ids.has(worker) or not job.pending_xp[worker] is int or job.pending_xp[worker] < 0:
				return "Invalid pending XP"
	if not ColonyConstruction.validate(data.construction_state,data.jobs): return "Invalid construction group"
	for store in data.stores:
		if not _record(store, world.stores[0]) or store.capacity < 1 or store.capacity > 100000 or store.priority not in [1, 2, 3] or store.tiles.is_empty():
			return "Invalid storage"
		for point in store.tiles:
			if not point is Vector2i:
				return "Invalid stockpile tile"
		for item in store.filters:
			if not world.definitions.items.has(item):
				return "Unknown storage filter"
	for field in data.fields:
		var expected: Array = ["id", "crop", "x", "y", "prepared", "planted", "growth", "growth_rem", "ripe_tick", "yield_count", "fertility", "replant", "reason"]
		if not field is Dictionary or not _keys(field, expected) or not world.definitions.crops.has(field.get("crop", "")) or not _position(field):
			return "Invalid field schema"
		for key in ["id", "x", "y", "growth", "growth_rem", "ripe_tick", "yield_count", "fertility"]:
			if not field[key] is int or field[key] < 0:
				return "Invalid field values"
		if field.growth_rem >= 7200 or field.growth > world.definitions.crops[field.crop].growth or field.yield_count > world.definitions.crops[field.crop].yield_count or field.fertility not in [750,1000,1250]:
			return "Invalid crop growth"
		for key in ["prepared", "planted", "replant"]:
			if not field[key] is bool:
				return "Invalid field flags"
	if not _keys(data.ledger, ColonyMaintenance.LEDGER_BUCKETS):
		return "Invalid inventory ledger"
	for entries in data.ledger.values():
		if not entries is Dictionary:
			return "Invalid inventory ledger"
		for item in entries:
			if not world.definitions.items.has(item) or not entries[item] is int or entries[item] < 0:
				return "Invalid inventory ledger"
	for command in data.pending_commands:
		if not command is Dictionary or not _keys(command, ["id", "session", "kind", "args"]) or not command.id is int or command.id < 1 or not command.session is String or not command.kind is String or not command.args is Dictionary:
			return "Invalid pending command"
		# Preserve only commands generated by the concrete development UI.
		var schemas: Dictionary = {"citizen_appearance":["target","appearance"], "assign_bed":["citizen","target"], "pin_moment":["text"], "rename":["target","text"], "start_supper":[], "cancel_supper":[], "start_ceremony":[], "cancel_ceremony":[], "continue_settlement":[], "charter_appearance":["definition","enabled"],"minor_event":["target","accept"],"stockpile": ["tiles"], "build": ["definition", "x", "y", "rotation"], "gather": ["target"], "gather_area": ["definition", "tiles"], "cancel": ["target"], "preference": ["citizen", "category", "value"], "food_policy": ["enabled"], "field": ["tiles", "crop"], "schedule": ["citizen", "shift"], "priority": ["target", "value"], "clear_field": ["target"], "early_harvest": ["target"], "request_accept": ["target"], "request_decline": ["target"], "mediate": ["definition"], "draft":["citizens","rally","stand_fast"], "undraft":["citizens"], "focus":["citizens","target"], "shelter":["enabled"], "open_passage":["enabled"], "stand_down":[], "raid_ack":[], "raid_offer":["target","pay"], "enemy_treat":["target"], "expedition_prepare":["definition","party","goats","cargo","feed","pen","variant","pickup"], "expedition_depart":["target","unprepared"], "expedition_cancel":["target"], "expedition_recall":["target"], "expedition_choice":["target","definition"], "expedition_collect":["target","keep"], "trade": ["target","buy","pay","pen","delivery"], "trade_cancel": ["target"], "newcomer": ["target","accept"], "cart_move": ["target","x","y"], "move_furniture": ["target","x","y","rotation"], "repair": ["target"], "demolish": ["target"], "rebuild": ["target"], "equip": ["target","slot","item"], "equipment_policy": ["target","slot","replacements","upgrades"], "build_area": ["definition","tiles"], "lodge": ["x","y"], "pen": ["tiles"], "breeding": ["target","enabled"], "slaughter": ["target"], "hunt": ["target","solo","citizen"], "forest": ["tiles","value"], "forest_policy": ["target","value","enabled"], "replant_tree": ["target"], "clear_sapling": ["target"], "care_mode": ["mode"], "treat_now": ["target","citizen"], "burial": ["target","x","y"], "recipe_order": ["target","definition","mode","value","priority","filters"], "order_enabled": ["target","enabled"], "research_select": ["definition"], "research_queue": ["definition"], "station_enabled": ["target","enabled"], "stock_filter": ["target", "filters", "priority"], "pin": ["target", "citizen"]}
		if not schemas.has(command.kind) or not _keys(command.args, schemas[command.kind]):
			return "Unknown pending command arguments"
		for key in command.args:
			var value: Variant = command.args[key]
			if key=="appearance" and not ColonyAppearance.valid(value): return "Invalid pending appearance"
			if key in ["target", "citizen", "x", "y", "rotation", "value", "priority","pen","variant"] and not value is int:
				return "Invalid command quantity"
			if key in ["definition", "category", "crop", "shift", "mode", "slot", "item","feed","text"] and not value is String:
				return "Invalid command definition"
			if key in ["enabled","solo","replacements","upgrades","accept","delivery","pickup","unprepared","stand_fast"] and not value is bool:
				return "Invalid policy toggle"
			if key == "filters" and (not value is Array or not value.all(func(item: Variant)->bool:return item is String and world.definitions.items.has(item))):
				return "Invalid storage filter"
			if key in ["buy","pay","cargo","keep"] and not ColonyTrade.quantities(value,world.definitions.items.keys()+ColonyTrade.ANIMALS.keys()): return "Invalid trade quantities"
			if key=="citizens" and (not value is Array or value.size()>20 or not value.all(func(id:Variant)->bool:return id is int and citizen_ids.has(id))): return "Invalid squad selection"
			if key=="rally" and not value is Vector2i: return "Invalid rally tile"
			if key in ["party","goats"] and (not value is Array or value.size()>4 or not value.all(func(id:Variant)->bool:return id is int and id>0)): return "Invalid expedition party"
			if key == "tiles":
				if not value is Array or value.size() > 16384:
					return "Invalid command tiles"
				for point in value:
					if not point is Vector2i:
						return "Invalid command tiles"
	if not ColonyCharter.valid(data,world.definitions,data.tick,data.next_id): return "Invalid charter or supper state"
	if not ColonyChronicle.validate(data.chronicle_state,data.tick,world.definitions): return "Invalid chronicle state"
	for id in data.chronicle_state.names:
		if not data.structures.any(func(s:Dictionary)->bool:return s.id==id): return "Missing named building"
	for fact in data.facts:
		if not fact is Dictionary or not _keys(fact, ["tick", "actor", "job", "kind", "text"]) or not fact.tick is int or not fact.actor is int or not fact.job is int or not fact.text is String or not fact.kind is String:
			return "Invalid journal fact"
	return ""

static func _position(record: Dictionary) -> bool:
	return record.get("x") is int and record.get("y") is int and record.x >= 0 and record.y >= 0 and record.x < 128 and record.y < 128
