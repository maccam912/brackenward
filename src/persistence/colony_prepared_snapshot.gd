class_name ColonyPreparedSnapshot
extends RefCounted
## In-memory preparation only. No disk writes or live-world mutation.
var payload: Dictionary = {}
var text: String = ""
var digest: String = ""
var validated: bool = false

static func prepare(captured: Dictionary, catalog: Dictionary) -> Dictionary:
	if not captured.is_read_only():return {"error":"Snapshot preparation needs an owned immutable capture"}
	if captured.get("content_hash")!=catalog.get("content_hash"):return {"error":"Snapshot preparation catalog differs from immutable capture"}
	if not captured.get("session_id") is String or not captured.get("generator_version") is int:return {"error":"Invalid snapshot identity metadata"}
	var result: ColonyPreparedSnapshot=ColonyPreparedSnapshot.new()
	result.payload=captured;result.text=JSON.stringify(ColonyState.pack(captured),"",true);result.digest=result.text.sha256_text()
	# Check the exact normal envelope bound, then release its temporary escaped
	# text/bytes before parsing the payload. Nothing external supplied this header.
	var identity: ColonyWorld=ColonyWorld.new(catalog)
	identity.session_id=captured.session_id;identity.generator_version=captured.generator_version
	var bytes: PackedByteArray=ColonyCodec.wrap_payload(identity,result.text)
	if bytes.is_empty() or bytes.size()>ColonyCodec.MAX_BYTES:return {"error":"Colony snapshot is empty or exceeds 64 MiB"}
	bytes=PackedByteArray();identity=null
	var parser: JSON=JSON.new()
	if parser.parse(result.text)!=OK:return {"error":"Malformed simulation payload"}
	var data: Variant=_unpack_owned_json(parser.data)
	parser=null
	if not data is Dictionary:return {"error":"Invalid integer, coordinate or state encoding"}
	var verified: Dictionary=ColonyCodec.restore(data)
	if not verified.has("world") or verified.world.payload()!=captured:return {"error":"Snapshot preparation failed full validation: "+str(verified.get("error","state mismatch"))}
	result.validated=true
	return {"snapshot":result}

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
