class_name ColonySnapshotEnvelope
extends RefCounted
## The normal envelope, without a second complete escaped UTF-32 string.
## External decoding and the independent ColonyCodec encoder stay unchanged.
const CHARS: int=4096

static func wrap(world: ColonyWorld, payload: String, snapshot_name: String="", sequence: int=0, timestamp: String="") -> PackedByteArray:
	var header: String=JSON.stringify({"format":ColonyCodec.FORMAT,"version":ColonyCodec.VERSION,"content":ColonyWorld.CONTENT_VERSION,
		"content_hash":world.definitions.content_hash,"snapshot_name":snapshot_name,"engine":"4.7.2.ed1daf0bf","generator_version":world.generator_version,"campaign_id":world.session_id,"sequence":str(sequence),"timestamp":Time.get_datetime_string_from_system(true) if timestamp.is_empty() else timestamp,"payload":"","sha256":payload.sha256_text()},"",true)
	var marker: String="\"payload\":\"\"";var at: int=header.find(marker)
	if at<0:return PackedByteArray()
	var bytes: PackedByteArray=header.left(at+marker.length()-1).to_utf8_buffer()
	for start in range(0,payload.length(),CHARS):
		# Godot strings index Unicode code points, so boundaries never split UTF-8.
		# Each native JSON string includes two surrounding quotes; keep the body.
		var part: PackedByteArray=JSON.stringify(payload.substr(start,CHARS)).to_utf8_buffer()
		bytes.append_array(part.slice(1,part.size()-1));part=PackedByteArray()
		if bytes.size()>ColonyCodec.MAX_BYTES:return PackedByteArray()
	bytes.append_array(header.substr(at+marker.length()-1).to_utf8_buffer())
	return bytes if bytes.size()<=ColonyCodec.MAX_BYTES else PackedByteArray()

static func hash_payload(payload: PackedByteArray) -> String:
	var context: HashingContext=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(payload)
	return context.finish().hex_encode()

static func wrap_bytes(world: ColonyWorld, payload: PackedByteArray, snapshot_name: String="", sequence: int=0, timestamp: String="") -> PackedByteArray:
	if payload.size()>ColonyCodec.MAX_BYTES:return PackedByteArray()
	var header: String=JSON.stringify({"format":ColonyCodec.FORMAT,"version":ColonyCodec.VERSION,"content":ColonyWorld.CONTENT_VERSION,
		"content_hash":world.definitions.content_hash,"snapshot_name":snapshot_name,"engine":"4.7.2.ed1daf0bf","generator_version":world.generator_version,"campaign_id":world.session_id,"sequence":str(sequence),"timestamp":Time.get_datetime_string_from_system(true) if timestamp.is_empty() else timestamp,"payload":"","sha256":hash_payload(payload)},"",true)
	var marker: String="\"payload\":\"\"";var at: int=header.find(marker)
	if at<0:return PackedByteArray()
	var bytes: PackedByteArray=header.left(at+marker.length()-1).to_utf8_buffer();var start: int=0
	while start<payload.size():
		var end: int=mini(start+CHARS,payload.size())
		# Bound bytes as well as code points; keep every multibyte scalar intact.
		while end<payload.size() and end>start and (payload[end]&192)==128:end-=1
		if end<=start:return PackedByteArray()
		var fragment: PackedByteArray=payload.slice(start,end)
		var text: String=fragment.get_string_from_utf8()
		if text.to_utf8_buffer()!=fragment:return PackedByteArray()
		var part: PackedByteArray=JSON.stringify(text).to_utf8_buffer();text="";fragment=PackedByteArray()
		bytes.append_array(part.slice(1,part.size()-1));part=PackedByteArray();start=end
		if bytes.size()>ColonyCodec.MAX_BYTES:return PackedByteArray()
	bytes.append_array(header.substr(at+marker.length()-1).to_utf8_buffer())
	return bytes if bytes.size()<=ColonyCodec.MAX_BYTES else PackedByteArray()
