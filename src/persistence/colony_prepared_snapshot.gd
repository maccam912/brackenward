class_name ColonyPreparedSnapshot
extends RefCounted
## In-memory preparation only. No disk writes or live-world mutation.
var payload: Dictionary = {}
var text: String = ""
var digest: String = ""
var validated: bool = false

static func prepare(captured: Dictionary, catalog: Dictionary) -> Dictionary:
	return ColonySnapshotEncoding.prepare(captured,catalog)

## Consumes fresh JSON.parse data only; never pass captures, world state or aliases.
static func _unpack_owned_json(value: Variant, field: String="", depth: int=0) -> Variant:
	if depth>32:return null
	if value is Dictionary:
		if value.is_read_only():return null
		if value.has("$tile"):return ColonyState.unpack(value,field,depth)
		if value.has("$map"):
			if value.size()!=1 or not value["$map"] is Array:return null
			var pairs: Array=value["$map"];value.clear()
			for pair in pairs:
				if not pair is Array or pair.size()!=2:return null
				var key: Variant=ColonyState.unpack(pair[0],"id",depth+1)
				var item: Variant=_unpack_owned_json(pair[1],"",depth+1)
				if key==null or item==null or value.has(key):return null
				value[key]=item
			return value
		for key in value:
			var item: Variant=_unpack_owned_json(value[key],key,depth+1)
			if item==null:return null
			value[key]=item
		return value
	if value is Array:
		if value.is_read_only():return null
		for index in range(value.size()):
			var item: Variant=_unpack_owned_json(value[index],field,depth+1)
			if item==null:return null
			value[index]=item
		return value
	return ColonyState.unpack(value,field,depth)

func matches(world: ColonyWorld) -> bool:
	return validated and payload.is_read_only() and digest==text.sha256_text() and payload.session_id==world.session_id and payload.content_hash==world.definitions.content_hash and payload.schema_revision==world.schema_revision and payload.generator_version==world.generator_version and payload.tick<=world.tick
