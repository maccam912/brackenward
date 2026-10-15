class_name JournalSelectionTests
extends RefCounted
## Retained complete-reader reference from a230331; only names are qualified.

static func original_read(bytes: PackedByteArray, first_sequence: int = 1) -> Dictionary:
	if first_sequence<1: return {"error":"Invalid initial journal sequence"}
	if bytes.size() > ColonyJournal.MAX_JOURNAL:
		return {"error": "Journal exceeds recovery bound"}
	var records: Array[Dictionary] = []
	var digests: Array[String] = []
	var offset: int = 0
	var sequence: int = first_sequence
	while offset < bytes.size():
		if bytes.size() - offset < 4:
			return {"records": records, "digests":digests, "torn_tail": true}
		var length: int = bytes.decode_u32(offset)
		if length == 0 or length > ColonyJournal.MAX_RECORD:
			return {"error": "Invalid journal frame length"}
		if offset + 4 + length + 32 > bytes.size():
			return {"records": records, "digests":digests, "torn_tail": true}
		var payload: PackedByteArray = bytes.slice(offset + 4, offset + 4 + length)
		var digest: PackedByteArray = bytes.slice(offset + 4 + length, offset + 4 + length + 32)
		if ColonyJournal._hash(payload) != digest:
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
				if not ColonyCodec._keys(value,["sequence","kind","tick","delta"]) or not ColonyJournal._delta_header(value.delta,value.tick): return {"error":"Invalid delta checkpoint marker"}
			elif value.size() != (4 if value.has("state") else 3) or (value.has("state") and not value.state is Dictionary):
				return {"error": "Invalid complete-tick marker"}
		records.append(value)
		digests.append(digest.hex_encode())
		sequence += 1
		offset += 4 + length + 32
	return {"records": records, "digests":digests, "torn_tail": false}

static func records() -> Array[Dictionary]:
	return [
		{"sequence":"1","kind":"tick","tick":1800,"state":{"tick":1800,"note":"legacy state"}},
		{"sequence":"2","kind":"command","tick":1801,"command":{"id":1,"session":"selection-test","kind":"build","args":{"definition":"door","x":70,"y":70,"rotation":0}}},
		{"sequence":"3","kind":"tick","tick":1801,"delta":{"version":1,"base_tick":1800,"campaign_id":"selection-test","parent":"a".repeat(64),"patch":{"map":{"tick":{"set_int":"1801"}},"erase":{}}}},
		{"sequence":"4","kind":"command","tick":1802,"command":{"id":2,"session":"selection-test","kind":"shelter","args":{"enabled":true}}},
		{"sequence":"5","kind":"tick","tick":1802},
		{"sequence":"6","kind":"tick","tick":1803,"state":{"tick":1803,"note":"last state"}}
	]

static func bytes_for(input: Array[Dictionary]) -> PackedByteArray:
	var result: PackedByteArray=PackedByteArray()
	for record in input:result.append_array(ColonyJournal.frame(record))
	return result

static func selection_agrees(bytes: PackedByteArray, tick: int) -> bool:
	var old: Dictionary=original_read(bytes);var selected: Dictionary=ColonyJournal.commands_after(bytes,tick)
	if old.has("error"):return selected==old
	return not selected.has("error") and selected.commands==old.records.filter(func(r:Dictionary)->bool:return r.kind=="command" and r.tick>tick) and selected.total_records==old.records.size() and selected.torn_tail==old.torn_tail

static func raw_frame(payload: String) -> PackedByteArray:
	var data: PackedByteArray=payload.to_utf8_buffer();var frame: PackedByteArray=PackedByteArray();frame.resize(4);frame.encode_u32(0,data.size());frame.append_array(data);frame.append_array(ColonyJournal._hash(data));return frame

static func run(check: Callable) -> void:
	var input: Array[Dictionary]=records();var bytes: PackedByteArray=bytes_for(input)
	var exact: bool=true
	for tick in [1800,1801,1802,1803,999999]:exact=exact and selection_agrees(bytes,tick)
	check.call("SAVE/rotation_command_selection_keeps_strict_after_tick_and_original_order",exact)
	var selected: Dictionary=ColonyJournal.commands_after(bytes,1801)
	check.call("SAVE/rotation_selection_counts_every_validated_frame_without_retaining_tick_trees",selected.commands.size()==1 and selected.total_records==6 and not selected.has("records") and not selected.has("digests") and selected.commands[0].command.id==2)
	check.call("SAVE/rotation_selection_preserves_original_complete_reader_shape_and_bytes",ColonyJournal.read(bytes)==original_read(bytes) and bytes==bytes_for(input))
	var digest: String=bytes.hex_encode().sha256_text();selected.commands[0].command.args.enabled=false
	check.call("SAVE/rotation_selection_owns_commands_without_mutating_input_or_other_reads",input[3].command.args.enabled and ColonyJournal.read(bytes)==original_read(bytes) and bytes.hex_encode().sha256_text()==digest)
	check.call("SAVE/rotation_selection_rejects_invalid_filter_tick_and_retains_empty_journal",ColonyJournal.commands_after(bytes,1799).has("error") and selection_agrees(PackedByteArray(),1800) and ColonyJournal.commands_after(PackedByteArray(),1800).total_records==0)
	var offset: int=0;exact=true
	for record in input:
		var frame: PackedByteArray=ColonyJournal.frame(record)
		for cut in [0,1,3,4,frame.size()-1,frame.size()]:
			var prefix: PackedByteArray=bytes.slice(0,offset+cut)
			exact=exact and ColonyJournal.read(prefix)==original_read(prefix) and selection_agrees(prefix,1801)
		offset+=frame.size()
	check.call("SAVE/rotation_selection_preserves_torn_prefix_at_every_frame_boundary",exact)
	var corrupted: PackedByteArray=bytes.duplicate();corrupted[12]^=1
	check.call("SAVE/rotation_selection_checks_checksum_of_unselected_tick_frames",ColonyJournal.commands_after(corrupted,999999).has("error") and selection_agrees(corrupted,999999) and ColonyJournal.read(corrupted)==original_read(corrupted))
	exact=true
	var invalid: Array[Dictionary]=[
		{"sequence":"2","kind":"tick","tick":1800},
		{"sequence":"1","kind":"unknown","tick":1800},
		{"sequence":"1","kind":"tick","tick":"not a tick"},
		{"sequence":"1","kind":"tick","tick":1800,"state":"not a state"},
		{"sequence":"1","kind":"tick","tick":1800,"extra":true},
		{"sequence":"1","kind":"tick","tick":1800,"delta":{"version":1,"base_tick":1801,"campaign_id":"selection-test","parent":"a".repeat(64),"patch":{}}},
		{"sequence":"1","kind":"tick","tick":1800,"delta":{"version":1,"base_tick":1800,"campaign_id":"","parent":"a".repeat(64),"patch":{}}},
		{"sequence":"1","kind":"tick","tick":1800,"state":{"duplicate":{"$map":[["1","one"],["1","two"]]}}}
	]
	for bad in invalid:
		var frame: PackedByteArray=ColonyJournal.frame(bad)
		exact=exact and ColonyJournal.commands_after(frame,999999).has("error") and selection_agrees(frame,999999) and ColonyJournal.read(frame)==original_read(frame)
	check.call("SAVE/rotation_selection_validates_unselected_sequence_schema_delta_and_value_encoding",exact)
	var malformed: PackedByteArray=raw_frame("{");var zero: PackedByteArray=PackedByteArray([0,0,0,0]);var wide: PackedByteArray=zero.duplicate();wide.encode_u32(0,ColonyJournal.MAX_RECORD+1)
	exact=true
	for bad in [malformed,zero,wide]:exact=exact and ColonyJournal.commands_after(bad,999999).has("error") and selection_agrees(bad,999999) and ColonyJournal.read(bad)==original_read(bad)
	check.call("SAVE/rotation_selection_rejects_malformed_json_and_invalid_frame_lengths",exact)
	var deep: Dictionary={"value":true}
	for index in range(34):deep={"nested":deep}
	var nested: PackedByteArray=ColonyJournal.frame({"sequence":"1","kind":"tick","tick":1800,"state":deep})
	check.call("SAVE/rotation_selection_keeps_original_json_depth_rejection",ColonyJournal.commands_after(nested,999999).has("error") and selection_agrees(nested,999999))
	var later: PackedByteArray=ColonyJournal.frame({"sequence":"7","kind":"tick","tick":1800})
	check.call("SAVE/rotation_selection_cannot_accept_a_tail_as_a_whole_journal",ColonyJournal.read(later,7)==original_read(later,7) and ColonyJournal.commands_after(later,1800).has("error") and ColonyJournal.read(bytes,0)==original_read(bytes,0))
	immutable_corpus(check)

static func immutable_corpus(check: Callable) -> void:
	var exact: bool=true;var count: int=0
	for name in DirAccess.get_files_at("res://tests/fixtures"):
		if not name.ends_with(".frames"):continue
		count+=1;var path: String="res://tests/fixtures/"+name;var sha: String=FileAccess.get_sha256(path);var bytes: PackedByteArray=FileAccess.get_file_as_bytes(path)
		exact=exact and not original_read(bytes).has("error") and ColonyJournal.read(bytes)==original_read(bytes)
		for tick in [1800,7200,72000]:exact=exact and selection_agrees(bytes,tick)
		exact=exact and FileAccess.get_sha256(path)==sha
	check.call("SAVE/rotation_selection_preserves_all_four_immutable_historical_journals",exact and count==4)
