class_name ColonyJournalEncoding
extends RefCounted
## Private writer encoding only. Native packing is bounded to 256 array/map rows;
## the normal journal reader still verifies every actual serialized byte.
const BLOCK: int=256
var bytes: PackedByteArray=PackedByteArray()
var error: String=""

static func encode(record: Dictionary) -> Dictionary:
	var writer: ColonyJournalEncoding=ColonyJournalEncoding.new()
	writer.write(record,"",0)
	return {"bytes":writer.bytes} if writer.error.is_empty() else {"error":writer.error}

func bounded() -> bool:
	if bytes.size()>ColonyCodec.MAX_BYTES:error="Journal encoding exceeds the snapshot size bound"
	return error.is_empty()

func write(value: Variant, field: String, depth: int) -> void:
	if depth>32:error="Journal encoding exceeds state depth bound";return
	if value is Dictionary:
		var keys: Array=value.keys()
		if not keys.is_empty() and keys[0] is int:
			if not keys.all(func(key:Variant)->bool:return key is int):error="Mixed integer map keys";return
			keys.sort();bytes.append_array('{"$map":['.to_utf8_buffer())
			for start in range(0,keys.size(),BLOCK):
				if start>0:bytes.append(44)
				var pairs: Array=[]
				for index in range(start,mini(start+BLOCK,keys.size())):pairs.append([str(keys[index]),ColonyState.pack(value[keys[index]])])
				var part: PackedByteArray=JSON.stringify(pairs,"",true).to_utf8_buffer();pairs=[]
				bytes.append_array(part.slice(1,part.size()-1));part=PackedByteArray()
				if not bounded():return
			bytes.append_array(']}'.to_utf8_buffer())
		else:
			if not keys.all(func(key:Variant)->bool:return key is String):error="Unsupported dictionary keys";return
			keys.sort();bytes.append(123);var first: bool=true
			for key: String in keys:
				if not first:bytes.append(44)
				first=false;bytes.append_array(JSON.stringify(key).to_utf8_buffer());bytes.append(58)
				write(value[key],key,depth+1)
				if not bounded():return
			bytes.append(125)
	elif value is Array:
		bytes.append(91)
		for start in range(0,value.size(),BLOCK):
			if start>0:bytes.append(44)
			var packed: Variant=ColonyState.pack(value.slice(start,mini(start+BLOCK,value.size())),field)
			var part: PackedByteArray=JSON.stringify(packed,"",true).to_utf8_buffer();packed=null
			bytes.append_array(part.slice(1,part.size()-1));part=PackedByteArray()
			if not bounded():return
		bytes.append(93)
	else:bytes.append_array(JSON.stringify(ColonyState.pack(value,field),"",true).to_utf8_buffer())
	bounded()
