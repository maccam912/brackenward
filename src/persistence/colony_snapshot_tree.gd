class_name ColonySnapshotTree
extends RefCounted
## Bound nested string dictionaries/arrays, including large terrain habitat lists.
## Metadata is private to the encoder; the checker rereads every actual byte.
const BLOCK: int=256
var buffer: PackedByteArray=PackedByteArray()
var error: String=""

static func kind(value: Variant) -> String:
	if value is Array:return "array"
	if value is Dictionary and not value.has("$tile") and not value.has("$map") and value.keys().all(func(k:Variant)->bool:return k is String):return "dict"
	return "atom"

static func encode(captured: Dictionary) -> Dictionary:
	if not captured.keys().all(func(k:Variant)->bool:return k is String):return {"error":"Invalid snapshot field keys"}
	var writer: ColonySnapshotTree=ColonySnapshotTree.new()
	var tree: Dictionary=writer.write(captured,"",0)
	if not writer.error.is_empty():return {"error":writer.error}
	return {"bytes":writer.buffer,"tree":tree}

func bounded() -> bool:
	if buffer.size()>ColonyCodec.MAX_BYTES:error="Snapshot payload exceeds 64 MiB"
	return error.is_empty()

func write(value: Variant, field: String, depth: int) -> Dictionary:
	if depth>32:error="Snapshot encoding exceeds state depth bound";return {}
	var node: Dictionary={"kind":kind(value),"start":buffer.size()}
	if node.kind=="dict":
		buffer.append(123);node.fields=[]
		var keys: Array=value.keys();keys.sort()
		for key: String in keys:
			if not node.fields.is_empty():buffer.append(44)
			var entry: Dictionary={"key":key,"key_start":buffer.size()}
			buffer.append_array(JSON.stringify(key).to_utf8_buffer());entry.key_end=buffer.size();buffer.append(58)
			entry.node=write(value[key],key,depth+1)
			if not bounded():return {}
			node.fields.append(entry)
		buffer.append(125)
	elif node.kind=="array":
		buffer.append(91);node.blocks=[]
		for start in range(0,value.size(),BLOCK):
			if start>0:buffer.append(44)
			var packed: Variant=ColonyState.pack(value.slice(start,mini(start+BLOCK,value.size())),field)
			var part: PackedByteArray=JSON.stringify(packed,"",true).to_utf8_buffer();packed=null
			var offset: int=buffer.size();buffer.append_array(part.slice(1,part.size()-1));part=PackedByteArray()
			node.blocks.append([offset,buffer.size()])
			if not bounded():return {}
		buffer.append(93)
	else:
		var packed: Variant=ColonyState.pack(value,field)
		buffer.append_array(JSON.stringify(packed,"",true).to_utf8_buffer());packed=null
	node.end=buffer.size();bounded()
	return node

static func matches(bytes: PackedByteArray, tree: Dictionary, expected: Dictionary) -> Dictionary:
	if not expected.is_read_only():return {"error":"Snapshot comparison needs an owned immutable capture"}
	if bytes.is_empty() or bytes.size()>ColonyCodec.MAX_BYTES:return {"error":"Invalid owned snapshot payload"}
	var result: Dictionary=check_node(bytes,tree,expected,"",0,0)
	if result.has("error"):return result
	if result.cursor!=bytes.size():return {"error":"Snapshot has unconsumed trailing bytes"}
	return {"matched":true}

static func check_node(bytes: PackedByteArray, node: Dictionary, expected: Variant, field: String, depth: int, cursor: int) -> Dictionary:
	if depth>32:return {"error":"Snapshot comparison exceeds state depth bound"}
	if node.get("kind")!=kind(expected) or node.get("start")!=cursor or not node.get("end") is int or node.end<=cursor or node.end>bytes.size():return {"error":"Snapshot node shape or span differs"}
	if node.kind=="dict":
		if bytes[cursor]!=123 or not node.get("fields") is Array:return {"error":"Snapshot dictionary opener differs"}
		cursor+=1;var seen: Dictionary={};var previous: String=""
		for entry: Dictionary in node.fields:
			if not seen.is_empty():
				if cursor>=bytes.size() or bytes[cursor]!=44:return {"error":"Missing snapshot field separator"}
				cursor+=1
			if entry.key_start!=cursor or entry.key_end<=cursor or entry.key_end>=bytes.size():return {"error":"Snapshot key span differs"}
			var parser: JSON=JSON.new()
			if parser.parse(bytes.slice(cursor,entry.key_end).get_string_from_utf8())!=OK or not parser.data is String:return {"error":"Invalid snapshot field name"}
			var key: String=parser.data;parser=null
			if key!=entry.key or seen.has(key) or not expected.has(key) or (not seen.is_empty() and key<=previous) or bytes[entry.key_end]!=58:return {"error":"Snapshot key/order differs"}
			seen[key]=true;previous=key
			var child: Dictionary=check_node(bytes,entry.node,expected[key],key,depth+1,entry.key_end+1)
			if child.has("error"):return child
			cursor=child.cursor
		if seen.size()!=expected.size() or cursor>=bytes.size() or bytes[cursor]!=125:return {"error":"Snapshot dictionary coverage differs"}
		cursor+=1
	elif node.kind=="array":
		if bytes[cursor]!=91 or not node.get("blocks") is Array:return {"error":"Snapshot array opener differs"}
		cursor+=1;var consumed: int=0
		for index in range(node.blocks.size()):
			if index>0:
				if cursor>=bytes.size() or bytes[cursor]!=44:return {"error":"Missing snapshot block separator"}
				cursor+=1
			var span: Array=node.blocks[index]
			if span.size()!=2 or span[0]!=cursor or span[1]<=cursor or span[1]>bytes.size():return {"error":"Snapshot block span differs"}
			var part: String=bytes.slice(cursor,span[1]).get_string_from_utf8();var trimmed: String=part.strip_edges()
			if trimmed.is_empty() or trimmed.begins_with(",") or trimmed.ends_with(","):return {"error":"Empty or incomplete snapshot value block"}
			var parser: JSON=JSON.new()
			if parser.parse("["+part+"]")!=OK:return {"error":"Malformed snapshot array block"}
			part="";trimmed=""
			var value: Variant=ColonyPreparedSnapshot._unpack_owned_json(parser.data,field,depth);parser=null
			if not value is Array or value.is_empty() or value.size()>BLOCK or consumed+value.size()>expected.size() or value!=expected.slice(consumed,consumed+value.size()):return {"error":"Serialized snapshot array differs from validated capture"}
			consumed+=value.size();value=null;cursor=span[1]
		if consumed!=expected.size() or cursor>=bytes.size() or bytes[cursor]!=93:return {"error":"Snapshot array coverage differs"}
		cursor+=1
	else:
		var parser: JSON=JSON.new()
		if parser.parse(bytes.slice(cursor,node.end).get_string_from_utf8())!=OK:return {"error":"Malformed snapshot value"}
		var value: Variant=ColonyPreparedSnapshot._unpack_owned_json(parser.data,field,depth);parser=null
		if value==null or typeof(value)!=typeof(expected) or value!=expected:return {"error":"Serialized snapshot value differs from validated capture"}
		value=null;cursor=node.end
	if cursor!=node.end:return {"error":"Snapshot node coverage differs"}
	return {"cursor":cursor}
