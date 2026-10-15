class_name LegacyPreparedSnapshot
extends RefCounted
## Exact String-backed record fields and matcher retained from 1270652.
var payload: Dictionary = {}
var text: String = ""
var digest: String = ""
var validated: bool = false

func matches(world: ColonyWorld) -> bool:
	return validated and payload.is_read_only() and digest==text.sha256_text() and payload.session_id==world.session_id and payload.content_hash==world.definitions.content_hash and payload.schema_revision==world.schema_revision and payload.generator_version==world.generator_version and payload.tick<=world.tick
