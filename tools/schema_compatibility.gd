class_name SchemaCompatibility
extends RefCounted
## Audit only: compare every acknowledged gameplay field under an old header.
static func normalize(world: ColonyWorld, original: Dictionary, allow_declared_deferral: bool = false) -> Dictionary:
	if original.get("schema_revision") not in [20,21,22,23,24,25]: return {}
	var result: Dictionary = world.payload().duplicate(true)
	result.content=original.content;result.content_hash=original.content_hash;result.schema_revision=original.schema_revision
	if original.schema_revision<22:
		for person in result.citizens: person.erase("appearance")
	if original.schema_revision<24:
		for state in result.nature_state.trees.values():
			if state.get("cleared",true): return {}
			state.erase("cleared")
	if original.schema_revision<25:
		for person in result.citizens:
			if person.equipment.transport!="" or result.equipment_state[person.id].transport!={"replacements":true,"upgrades":false,"preferred":""}: return {}
			person.equipment.erase("transport");result.equipment_state[person.id].erase("transport")
	if original.schema_revision>=23: return result
	var original_jobs: Dictionary = {}
	if allow_declared_deferral:
		for job in original.jobs: original_jobs[job.id]=job
	for job in result.jobs:
		# Deferring an over-limit order is a deliberate rule upgrade and must
		# never be hidden by the unchanged-gameplay compatibility audit.
		if not job.queue_state.is_empty() or job.state=="Queued":
			var previous: Dictionary = original_jobs.get(job.id,{})
			if not allow_declared_deferral or job.state!="Queued" or job.worker!=0 or previous.get("worker")!=0 or previous.get("state")!=job.queue_state: return {}
			job.state=job.queue_state
		job.erase("queue_state")
	return result
