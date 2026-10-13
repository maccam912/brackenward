class_name ColonyMigrations
extends RefCounted
## Pure forward migrations. M1 first advances through the frozen M2 migrator.
static func from_m2(data: Dictionary, content_hash: String, items: Array = []) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	result.content = ColonyWorld.CONTENT_VERSION
	result.content_hash = content_hash
	result["schema_revision"] = 1
	result["generator_version"] = 0
	result["site_id"] = "meadow_reach"
	result["weather_state"] = {}
	for citizen in result.citizens: citizen["move_base_rem"] = 0
	for store in result.stores:
		if store.filters.size() == 10 and not items.is_empty(): store.filters = items.duplicate()
	return result


static func catalog_v1(data: Dictionary, definitions: Dictionary, old_items: Array) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	result.content = ColonyWorld.CONTENT_VERSION
	result.content_hash = definitions.content_hash
	if not result.get("stores") is Array: return data
	for store in result.stores:
		if not store is Dictionary or not store.get("filters") is Array: return data
		if store.filters.size() == old_items.size() and old_items.all(func(item:Variant)->bool:return store.filters.has(item)):
			store.filters = definitions.items.keys()
	return result

static func upgrade_current(data: Dictionary, template: ColonyWorld) -> Dictionary:
	var result: Dictionary = data
	if result.get("schema_revision") == 1:
		var header: Dictionary = template.payload().duplicate()
		header.erase("social_state")
		header.erase("production_state")
		header.erase("care_state")
		header.erase("terrain_state")
		header.erase("nature_state")
		header.erase("wildlife_state")
		header.erase("domestic_state")
		header.erase("construction_state")
		header.erase("equipment_state")
		header.erase("population_state")
		header.erase("trade_state")
		header.erase("region_state")
		header.erase("fire_state")
		header.erase("defense_state")
		header.erase("director_state")
		header.erase("opportunity_state")
		header.erase("charter_state")
		header.erase("chronicle_state")
		if not ColonyCodec._record(result,header) or result.citizens.size() != 4: return data
		var citizen_template: Dictionary = template.citizens[0].duplicate()
		for key in ["story_memory_until","away","expedition","camp_sleeping"]+ColonyDefense.citizen_defaults().keys(): citizen_template.erase(key)
		for key in ColonySocial.citizen_defaults(): citizen_template.erase(key)
		for key in ColonyCare.citizen_defaults(): citizen_template.erase(key)
		for key in ColonyCombat.citizen_defaults(): citizen_template.erase(key)
		for citizen in result.citizens:
			if not ColonyCodec._record(citizen,citizen_template): return data
		result = result.duplicate(true)
		result.schema_revision = 2
		for citizen in result.citizens:
			for key in ColonySocial.citizen_defaults(): citizen[key] = ColonySocial.citizen_defaults()[key]
		for job in result.jobs:
			if not job is Dictionary: return data
			job["worker_days"] = {}
		result["social_state"] = ColonySocial.initial_state(result.citizens,result.tick)
	if result.get("schema_revision") == 2:
		if not result.get("citizens") is Array or not result.get("ledger") is Dictionary or not result.ledger.get("produced") is Dictionary: return data
		result = result.duplicate(true)
		for citizen in result.citizens:
			if not citizen is Dictionary or not citizen.get("equipment") is Dictionary: return data
			for item in citizen.equipment.values():
				if not item is String: return data
				if not item.is_empty(): result.ledger.produced[item] = result.ledger.produced.get(item,0)+1
			citizen.equipment["vest"] = ""
		result.schema_revision = 3
	if result.get("schema_revision") == 3:
		if not result.get("jobs") is Array: return data
		result = result.duplicate(true)
		result["production_state"] = ColonyProduction.initial_state()
		for job in result.jobs:
			if not job is Dictionary: return data
			job["order"] = 0
		result.schema_revision = 4
	if result.get("schema_revision") == 4:
		if not result.get("citizens") is Array or not result.get("jobs") is Array: return data
		result = result.duplicate(true)
		result["care_state"] = ColonyCare.initial_state()
		for citizen in result.citizens:
			if not citizen is Dictionary: return data
			citizen.merge(ColonyCare.citizen_defaults())
		for job in result.jobs:
			if not job is Dictionary: return data
			job["care_goal"] = []
			job["emergency"] = false
		result.schema_revision = 5
	if result.get("schema_revision") == 5:
		if not result.get("citizens") is Array: return data
		result = result.duplicate(true)
		var people: Array = result.citizens.duplicate()
		if not result.get("social_state") is Dictionary or not result.social_state.get("deaths") is Array: return data
		for death in result.social_state.deaths:
			if not death is Dictionary or not death.get("citizen") is Dictionary: return data
			people.append(death.citizen)
		for citizen in people:
			if not citizen is Dictionary or not citizen.get("recovery_rate") is int or not citizen.get("recovery_until") is int: return data
			if not citizen.has("recovery_windows"):
				citizen["recovery_windows"] = {}
				if citizen.recovery_until > 0: citizen.recovery_windows[{2:"stabilize",4:"herb",8:"medicine"}.get(citizen.recovery_rate,"stabilize")] = citizen.recovery_until
		result.schema_revision = 6
	if result.get("schema_revision") == 6:
		result = result.duplicate(true)
		result["terrain_state"] = ColonyGeneration.empty_state()
		result.schema_revision = 7
	if result.get("schema_revision") == 7:
		if not result.get("tick") is int: return data
		result = result.duplicate(true)
		result["nature_state"] = ColonyNature.initial_state(result.tick)
		result.schema_revision = 8
	if result.get("schema_revision") == 8:
		if not result.get("citizens") is Array: return data
		result = result.duplicate(true)
		result["wildlife_state"] = ColonyWildlife.initial_state()
		for citizen in result.citizens:
			if not citizen is Dictionary: return data
			citizen.merge(ColonyCombat.citizen_defaults())
		result.schema_revision = 9
	if result.get("schema_revision") == 9:
		result = result.duplicate(true)
		result["domestic_state"] = ColonyDomestic.initial_state()
		result.schema_revision = 10
	if result.get("schema_revision") == 10:
		result = result.duplicate(true)
		result["construction_state"] = ColonyConstruction.initial_state()
		result.schema_revision = 11
	if result.get("schema_revision") == 11:
		result = result.duplicate(true)
		result["equipment_state"] = ColonyEquipment.initial_state(result.get("citizens",[]))
		result.schema_revision = 12
	if result.get("schema_revision") == 12:
		if not result.get("jobs") is Array or not result.get("ledger") is Dictionary: return data
		result=result.duplicate(true)
		for bucket in ColonyMaintenance.LEDGER_BUCKETS:
			if not result.ledger.has(bucket): result.ledger[bucket]={}
		for job in result.jobs:
			if not job is Dictionary: return data
			job["amount"]=0
			job["memo"]={}
		result.schema_revision=13
	if result.get("schema_revision") == 13:
		result=result.duplicate(true)
		result["population_state"]=ColonyPopulation.initial_state(result.seed,result.generator_version,result.site_id)
		result.schema_revision=14
	if result.get("schema_revision")==14:
		result=result.duplicate(true)
		result["trade_state"]=ColonyTrade.initial_state(result.seed,result.generator_version,result.site_id)
		# Start the next scheduled visit after this existing campaign tick.
		while result.trade_state.next_visit<=result.tick:
			result.trade_state.next_visit+=28800;result.trade_state.visit_index+=1
		result.schema_revision=15
	if result.get("schema_revision")==15:
		result=result.duplicate(true)
		result["region_state"]=ColonyRegion.initial_state(result.seed,result.generator_version,result.site_id)
		for person in result.citizens: person.merge({"away":false,"expedition":0,"camp_sleeping":false})
		result.schema_revision=16
	if result.get("schema_revision")==16:
		result=result.duplicate(true)
		result["fire_state"]=ColonyFire.initial_state()
		result.schema_revision=17
	if result.get("schema_revision")==17:
		result=result.duplicate(true)
		result["director_state"]=ColonyDirector.initial_state(result.seed,result.generator_version,result.site_id)
		result["defense_state"]=ColonyDefense.initial_state(result.seed,result.generator_version,result.site_id)
		for person in result.citizens: person.merge(ColonyDefense.citizen_defaults())
		result.schema_revision=18
	if result.get("schema_revision")==18:
		result=result.duplicate(true)
		result["opportunity_state"]=ColonyOpportunities.initial_state(result.seed,result.generator_version,result.site_id)
		for person in result.citizens:
			person["story_memory_until"]=0
			person.merge(ColonyCombat.citizen_defaults())
		result.schema_revision=19
	if result.get("schema_revision")==19:
		if not result.get("tick") is int or not result.get("facts") is Array or not result.get("citizens") is Array: return data
		for fact in result.facts:
			if not fact is Dictionary or not ColonyCodec._keys(fact,["tick","actor","job","kind","text"]) or not fact.tick is int or not fact.actor is int or not fact.job is int or not fact.kind is String or not fact.text is String: return data
		for person in result.citizens:
			if not person is Dictionary or not person.get("id") is int or not person.get("name") is String or not person.get("x") is int or not person.get("y") is int: return data
		result=result.duplicate(true)
		result["charter_state"]=ColonyCharter.initial_state(result.tick)
		result["chronicle_state"]=ColonyChronicle.from_legacy(result)
		result.facts=result.facts.slice(maxi(0,result.facts.size()-ColonyChronicle.ORDINARY_LIMIT))
		result.schema_revision=20
	return result
