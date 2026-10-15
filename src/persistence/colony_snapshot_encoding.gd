class_name ColonySnapshotEncoding
extends RefCounted
## Private in-memory encoding. Every output byte is checked during owned decoding.
## External files always use ColonyCodec's normal complete-envelope decoder.
const BLOCK: int=256

static func prepare(captured: Dictionary, catalog: Dictionary) -> Dictionary:
	if not captured.is_read_only():return {"error":"Snapshot preparation needs an owned immutable capture"}
	if captured.get("content_hash")!=catalog.get("content_hash"):return {"error":"Snapshot preparation catalog differs from immutable capture"}
	if not captured.get("session_id") is String or not captured.get("generator_version") is int:return {"error":"Invalid snapshot identity metadata"}
	# Full validation can read the owned immutable capture directly. Proving
	# every serialized value equals this validated state avoids retaining a
	# second complete decoded world; external decoding is unchanged.
	var verified: Dictionary=ColonyCodec.restore(captured)
	if not verified.has("world") or verified.world.payload()!=captured:return {"error":"Snapshot preparation failed full validation: "+str(verified.get("error","state mismatch"))}
	verified={}
	var encoded: Dictionary=ColonySnapshotTree.encode(captured)
	if encoded.has("error"):return encoded
	var compared: Dictionary=ColonySnapshotTree.matches(encoded.bytes,encoded.tree,captured)
	if compared.has("error"):return compared
	encoded.tree={}
	var result: ColonyPreparedSnapshot=ColonyPreparedSnapshot.new()
	result.payload=captured;result.encoded_payload=encoded.bytes;encoded={}
	result.digest=ColonySnapshotEnvelope.hash_payload(result.encoded_payload)
	var identity: ColonyWorld=ColonyWorld.new(catalog)
	identity.session_id=captured.session_id;identity.generator_version=captured.generator_version
	var bytes: PackedByteArray=ColonySnapshotEnvelope.wrap_bytes(identity,result.encoded_payload)
	if bytes.is_empty() or bytes.size()>ColonyCodec.MAX_BYTES:return {"error":"Colony snapshot is empty or exceeds 64 MiB"}
	result.validated=true
	return {"snapshot":result}

static func encode(captured: Dictionary) -> Dictionary:
	var keys: Array=captured.keys()
	if not keys.all(func(k:Variant)->bool:return k is String):return {"error":"Invalid snapshot field keys"}
	keys.sort()
	var bytes: PackedByteArray=PackedByteArray([123]);var fields: Array=[]
	for key: String in keys:
		if not fields.is_empty():bytes.append(44)
		var field: Dictionary={"key":key,"key_start":bytes.size()}
		bytes.append_array(JSON.stringify(key).to_utf8_buffer());field.key_end=bytes.size();bytes.append(58)
		var value: Variant=captured[key]
		field.array=value is Array;field.blocks=[]
		if value is Array:
			bytes.append(91)
			for start in range(0,value.size(),BLOCK):
				if start>0:bytes.append(44)
				var packed: Variant=ColonyState.pack(value.slice(start,mini(start+BLOCK,value.size())),key)
				var part: PackedByteArray=JSON.stringify(packed,"",true).to_utf8_buffer();packed=null
				var offset: int=bytes.size();bytes.append_array(part.slice(1,part.size()-1))
				field.blocks.append([offset,bytes.size()])
				if bytes.size()>ColonyCodec.MAX_BYTES:return {"error":"Snapshot payload exceeds 64 MiB"}
			bytes.append(93)
		else:
			var packed: Variant=ColonyState.pack(value,key)
			var offset: int=bytes.size();bytes.append_array(JSON.stringify(packed,"",true).to_utf8_buffer());packed=null
			field.blocks.append([offset,bytes.size()])
		fields.append(field)
		if bytes.size()>ColonyCodec.MAX_BYTES:return {"error":"Snapshot payload exceeds 64 MiB"}
	bytes.append(125)
	return {"bytes":bytes,"fields":fields}

static func decode_owned(bytes: PackedByteArray, fields: Array) -> Dictionary:
	if bytes.size()<2 or bytes.size()>ColonyCodec.MAX_BYTES or bytes[0]!=123:return {"error":"Invalid owned snapshot payload"}
	var data: Dictionary={};var cursor: int=1;var previous: String=""
	for field: Dictionary in fields:
		if not data.is_empty():
			if cursor>=bytes.size() or bytes[cursor]!=44:return {"error":"Missing snapshot field separator"}
			cursor+=1
		if field.key_start!=cursor or field.key_end<=cursor or field.key_end>=bytes.size():return {"error":"Snapshot field span differs"}
		var key_parser: JSON=JSON.new()
		if key_parser.parse(bytes.slice(cursor,field.key_end).get_string_from_utf8())!=OK or not key_parser.data is String:return {"error":"Invalid snapshot field name"}
		var key: String=key_parser.data;key_parser=null
		if key!=field.key or data.has(key) or (not data.is_empty() and key<=previous) or bytes[field.key_end]!=58:return {"error":"Snapshot key/order differs"}
		previous=key;cursor=field.key_end+1
		if field.array:
			if cursor>=bytes.size() or bytes[cursor]!=91:return {"error":"Snapshot array opener differs"}
			cursor+=1;data[key]=[]
		elif field.blocks.size()!=1:return {"error":"Snapshot scalar needs one complete value"}
		for index in range(field.blocks.size()):
			if index>0:
				if not field.array or cursor>=bytes.size() or bytes[cursor]!=44:return {"error":"Missing snapshot block separator"}
				cursor+=1
			var span: Array=field.blocks[index]
			if span.size()!=2 or span[0]!=cursor or span[1]<=cursor or span[1]>bytes.size():return {"error":"Snapshot value span differs"}
			var part: String=bytes.slice(cursor,span[1]).get_string_from_utf8()
			if field.array:part="["+part+"]"
			var parser: JSON=JSON.new()
			if parser.parse(part)!=OK:return {"error":"Malformed owned snapshot value"}
			part=""
			# Root fields start at depth one, matching whole-payload decoding.
			var value: Variant=ColonyPreparedSnapshot._unpack_owned_json(parser.data,key,1);parser=null
			if value==null or (field.array and not value is Array):return {"error":"Invalid integer, coordinate or state encoding"}
			if field.array:data[key].append_array(value)
			else:data[key]=value
			value=null;cursor=span[1]
		if field.array:
			if cursor>=bytes.size() or bytes[cursor]!=93:return {"error":"Snapshot array closer differs"}
			cursor+=1
	if cursor!=bytes.size()-1 or bytes[cursor]!=125:return {"error":"Snapshot trailing bytes differ"}
	return {"data":data}
