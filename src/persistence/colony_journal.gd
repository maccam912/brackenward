class_name ColonyJournal
extends RefCounted
## Length + exact UTF-8 JSON + SHA256. A torn final frame is ignored, not replayed.
const MAX_RECORD: int = 2 * 1024 * 1024
const MAX_JOURNAL: int = 64 * 1024 * 1024

static func frame(record: Dictionary) -> PackedByteArray:
	var payload: PackedByteArray = JSON.stringify(ColonyState.pack(record), "", true).to_utf8_buffer()
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, payload.size())
	bytes.append_array(payload)
	bytes.append_array(_hash(payload))
	return bytes

static func _hash(bytes: PackedByteArray) -> PackedByteArray:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish()

static func read(bytes: PackedByteArray, first_sequence: int = 1) -> Dictionary:
	if first_sequence<1: return {"error":"Invalid initial journal sequence"}
	if bytes.size() > MAX_JOURNAL:
		return {"error": "Journal exceeds recovery bound"}
	var records: Array[Dictionary] = []
	var digests: Array[String] = []
	var offset: int = 0
	var sequence: int = first_sequence
	while offset < bytes.size():
		if bytes.size() - offset < 4:
			return {"records": records, "digests":digests, "torn_tail": true}
		var length: int = bytes.decode_u32(offset)
		if length == 0 or length > MAX_RECORD:
			return {"error": "Invalid journal frame length"}
		if offset + 4 + length + 32 > bytes.size():
			return {"records": records, "digests":digests, "torn_tail": true}
		var payload: PackedByteArray = bytes.slice(offset + 4, offset + 4 + length)
		var digest: PackedByteArray = bytes.slice(offset + 4 + length, offset + 4 + length + 32)
		if _hash(payload) != digest:
			return {"error": "Journal checksum failed before the end; original evidence retained"}
		var parser: JSON = JSON.new()
		if parser.parse(payload.get_string_from_utf8()) != OK:
			return {"error": "Malformed journal record"}
		var value: Variant = ColonyState.unpack(parser.data)
		if not value is Dictionary or value.get("sequence", "") != str(sequence) or value.get("kind", "") not in ["command", "tick"] or not value.get("tick") is int:
			return {"error": "Journal sequence/schema mismatch"}
		if value.kind == "command" and (value.size() != 4 or not value.get("command") is Dictionary):
			return {"error": "Invalid journal command"}
		if value.kind == "tick":
			if value.has("delta"):
				if not ColonyCodec._keys(value,["sequence","kind","tick","delta"]) or not _delta_header(value.delta,value.tick): return {"error":"Invalid delta checkpoint marker"}
			elif value.size() != (4 if value.has("state") else 3) or (value.has("state") and not value.state is Dictionary):
				return {"error": "Invalid complete-tick marker"}
		records.append(value)
		digests.append(digest.hex_encode())
		sequence += 1
		offset += 4 + length + 32
	return {"records": records, "digests":digests, "torn_tail": false}

static func _digest_valid(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for index in range(value.length()):
		if not "0123456789abcdef".contains(value.substr(index,1)): return false
	return true

static func _delta_header(value: Variant, tick: int) -> bool:
	return value is Dictionary and ColonyCodec._keys(value,["version","base_tick","campaign_id","parent","patch"]) and value.version==1 and value.version is int and value.base_tick is int and value.base_tick>=1800 and value.base_tick<=tick and value.campaign_id is String and not value.campaign_id.is_empty() and value.campaign_id.length()<=80 and _digest_valid(value.parent) and value.patch is Dictionary

static func replay(world: RefCounted, records: Array[Dictionary], initial_hash: String = "", digests: Array = []) -> Dictionary:
	if not digests.is_empty() and (digests.size()!=records.size() or not digests.all(_digest_valid)): return {"error":"Invalid journal digest evidence"}
	var final_tick: int = world.tick
	var previous_tick: int = world.tick
	var commands: Dictionary = {}
	var final_state: Dictionary = {}
	var parent: String = initial_hash
	var cursor: int = 0
	for record in records:
		if record.tick < previous_tick or record.tick < world.tick or record.tick - world.tick > 72000:
			return {"error": "Journal tick order/range mismatch"}
		previous_tick = record.tick
		if record.kind == "command":
			if not commands.has(record.tick):
				commands[record.tick] = []
			commands[record.tick].append(record.command)
		else:
			final_tick = record.tick
			if record.has("state"):
				if record.state.get("tick") != final_tick or record.state.get("session_id") != world.session_id:
					return {"error":"Journal checkpoint identity/tick mismatch"}
				final_state = record.state.duplicate(true)
			elif record.has("delta"):
				if not world is ColonyWorld or not _delta_header(record.delta,record.tick): return {"error":"Unsupported delta recovery marker"}
				if final_state.is_empty(): final_state=world.payload().duplicate(true)
				if parent.is_empty(): parent=world.canonical_hash()
				if record.delta.parent!=parent or record.delta.base_tick!=final_state.tick or record.delta.campaign_id!=world.session_id: return {"error":"Delta checkpoint parent, tick or campaign mismatch"}
				# This state is owned by recovery; patching it cannot change the
				# loaded snapshot, earlier parsed frames or the caller's world.
				var rebuilt: Dictionary = ColonyDelta._apply(final_state,record.delta.patch,0)
				if rebuilt.has("error") or not rebuilt.get("value") is Dictionary: return {"error":"Invalid delta checkpoint: "+str(rebuilt.get("error","root type"))}
				final_state=rebuilt.value
				if final_state.get("tick")!=final_tick or final_state.get("session_id")!=world.session_id: return {"error":"Delta checkpoint did not restore its declared identity/tick"}
		if record.kind=="tick": parent=digests[cursor] if not digests.is_empty() else JSON.stringify(ColonyState.pack(record),"",true).sha256_text()
		cursor+=1
	if not final_state.is_empty():
		if final_state.tick != final_tick:
			return {"error":"A later complete-tick marker is missing its recovery state"}
		var checkpoint: Dictionary = ColonyCodec.restore(final_state)
		if checkpoint.has("error"): return checkpoint
		return {"world":checkpoint.world,"recovered_tick":final_tick}
	while world.tick < final_tick:
		for command: Dictionary in commands.get(world.tick + 1, []):
			# Validate command structure through the same snapshot validator before use.
			world.pending_commands.append(command)
			if command.get("id") is int:
				world.next_command_id = maxi(world.next_command_id, command.id + 1)
		if commands.has(world.tick + 1):
			var validation: Dictionary = M1Codec.decode(M1Codec.encode(world)) if world is M1World else (M2Codec.decode(M2Codec.encode(world)) if world is M2World else ColonyCodec.decode(ColonyCodec.encode(world)))
			if validation.has("error"):
				return {"error": validation.error}
		world.step()
		var errors: Array[String] = world.invariant_errors()
		if not errors.is_empty():
			return {"error": "Replay invariant failed: " + str(errors)}
	return {"world": world, "recovered_tick": final_tick}
