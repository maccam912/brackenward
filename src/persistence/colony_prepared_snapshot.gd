class_name ColonyPreparedSnapshot
extends RefCounted
## In-memory preparation only. No disk writes or live-world mutation.
var payload: Dictionary = {}
var text: String = ""
var digest: String = ""
var validated: bool = false

static func prepare(captured: Dictionary, catalog: Dictionary) -> Dictionary:
	if not captured.is_read_only(): return {"error":"Snapshot preparation needs an owned immutable capture"}
	var frozen: ColonyWorld = ColonyWorld.new(catalog)
	for field in captured:
		if field in ["content","content_hash"]: continue
		if captured[field] is Array: frozen.get(field).assign(captured[field])
		else: frozen.set(field,captured[field])
	var result: ColonyPreparedSnapshot = ColonyPreparedSnapshot.new()
	result.payload=captured
	result.text=JSON.stringify(ColonyState.pack(captured),"",true)
	result.digest=result.text.sha256_text()
	var verified: Dictionary = ColonyCodec.decode(ColonyCodec.wrap_payload(frozen,result.text))
	if not verified.has("world") or verified.world.payload()!=captured: return {"error":"Snapshot preparation failed full validation: "+str(verified.get("error","state mismatch"))}
	result.validated=true
	return {"snapshot":result}

func matches(world: ColonyWorld) -> bool:
	return validated and payload.is_read_only() and digest==text.sha256_text() and payload.session_id==world.session_id and payload.content_hash==world.definitions.content_hash and payload.schema_revision==world.schema_revision and payload.generator_version==world.generator_version and payload.tick<=world.tick
