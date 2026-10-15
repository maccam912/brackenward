class_name JournalFrameTests
extends RefCounted

static func compare(record: Dictionary) -> bool:
	var before: String=JSON.stringify(ColonyState.pack(record),"",false)
	var original: PackedByteArray=JournalReadReference.frame(record)
	return original==ColonyJournal._frame_bounded(record) and original==ColonyJournal.frame(record) and before==JSON.stringify(ColonyState.pack(record),"",false)

static func run(check: Callable) -> void:
	var exact: bool=true
	for path in ["tests/fixtures/content5-delta.frames","tests/fixtures/content4-delta.frames","tests/fixtures/content3-delta.frames","tests/fixtures/schema21-delta.frames","tests/fixtures/content6/delta.frames"]:
		var bytes: PackedByteArray=FileAccess.get_file_as_bytes("res://"+path);var unchanged: PackedByteArray=bytes.duplicate()
		var decoded: Dictionary=JournalReadReference.read(bytes)
		exact=exact and not decoded.has("error")
		for record: Dictionary in decoded.get("records",[]):exact=compare(record) and exact
		exact=exact and bytes==unchanged
	check.call("JOURNAL/bounded_frame_matches_independent_native_encoder_for_every_record_in_five_immutable_journals",exact)
	exact=true
	for count in [0,1,255,256,257,512,513]:
		var rows: Array=[];var map: Dictionary={};var ticks: Array=[]
		for index in range(count):
			var row: Dictionary={"id":index+1,"text":"quote \" slash \\ newline\n {speed}","unicode":"caf\u00e9","point":Vector2i(index%128,index/128),"memo":{"b":false,"a":true},"empty":[]}
			rows.append(row);map[count-index]=row;ticks.append(index)
		var record: Dictionary={"sequence":"1","kind":"tick","tick":1800,"state":{"rows":rows,"integer_map":map,"tick":ticks,"empty_map":{},"literal":{"$map":[["1","x"]]},"signed":-7,"big":9223372036854775807}}
		var mutable: Dictionary=record.duplicate(true);ColonyCapture._freeze(record)
		exact=compare(record) and compare(mutable) and exact
	check.call("JOURNAL/bounded_array_integer_map_chunks_preserve_sorting_ids_tags_unicode_escaping_and_frozen_inputs",exact)
	var nested: Dictionary={"leaf":true}
	for depth in range(36):nested={"child":nested}
	var deep: Dictionary={"sequence":"1","kind":"tick","tick":1800,"state":nested}
	var original: PackedByteArray=JournalReadReference.frame(deep);var bounded: PackedByteArray=ColonyJournal._frame_bounded(deep)
	check.call("JOURNAL/deep_encoder_fallback_preserves_original_bytes_and_reader_rejection",ColonyJournalEncoding.encode(deep).has("error") and compare(deep) and original==bounded and JournalReadTests.same(ColonyJournal.read(original),ColonyJournal.read(bounded)) and ColonyJournal.read(bounded).has("error"))
