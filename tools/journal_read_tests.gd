class_name JournalReadTests
extends RefCounted

static func same(a: Dictionary, b: Dictionary) -> bool:
	return JSON.stringify(ColonyState.pack(a),"",false)==JSON.stringify(ColonyState.pack(b),"",false)

static func compare(bytes: PackedByteArray, sequence: int=1) -> bool:
	var unchanged: PackedByteArray=bytes.duplicate()
	var original: Dictionary=JournalReadReference.read(bytes,sequence)
	return same(original,ColonyJournal._read_owned(bytes,sequence)) and same(original,ColonyJournal.read(bytes,sequence)) and bytes==unchanged

static func structured() -> Dictionary:
	var rows: Array=[]
	for index in range(512):rows.append({"id":index+1,"owner":3,"name":"literal {speed}","age":index,"tags":["food","grain"],"memo":{"tick":1800,"values":[true,false,index]},"point":Vector2i(index%128,index/128)})
	return {"rows":rows,"integer_map":{1:"first",2:[Vector2i(3,4)]},"unicode":"caf\u00e9","empty":[]}

static func run(check: Callable) -> void:
	var exact: bool=true
	for path in ["tests/fixtures/content5-delta.frames","tests/fixtures/content4-delta.frames","tests/fixtures/content3-delta.frames","tests/fixtures/schema21-delta.frames","tests/fixtures/content6/delta.frames"]:
		exact=exact and compare(FileAccess.get_file_as_bytes("res://"+path))
	var source: Dictionary=structured()
	var bytes: PackedByteArray=ColonyJournal.frame({"sequence":"1","kind":"tick","tick":1800,"state":source})
	exact=exact and compare(bytes) and compare(PackedByteArray())
	check.call("JOURNAL/owned_readback_matches_complete_126407a_reader_for_five_immutable_and_large_structured_frames",exact)
	var cases: Array=[bytes.slice(0,3),bytes.slice(0,bytes.size()-1)]
	var bad: PackedByteArray=bytes.duplicate();bad[-1]=bad[-1]^1;cases.append(bad)
	for length in [0,ColonyJournal.MAX_RECORD+1]:
		bad=PackedByteArray();bad.resize(4);bad.encode_u32(0,length);cases.append(bad)
	for record in [{"sequence":"2","kind":"tick","tick":1800},{"sequence":"1","kind":"other","tick":1800},{"sequence":"1","kind":"tick","tick":"01"},{"sequence":"1","kind":"tick","tick":1800,"state":{"bad":null}},{"sequence":"1","kind":"tick","tick":1800,"state":{"bad":{"$map":[["1",true],["1",false]]}}},{"sequence":"1","kind":"tick","tick":1800,"state":{"bad":{"$tile":[128,0]}}},{"sequence":"1","kind":"tick","tick":1800,"delta":{"version":1,"base_tick":1800,"campaign_id":"x","parent":"z".repeat(64),"patch":{}}}]:cases.append(ColonyJournal.frame(record))
	exact=compare(bytes,0) and compare(bytes,-1)
	for value: PackedByteArray in cases:exact=exact and compare(value)
	check.call("JOURNAL/owned_readback_preserves_corruption_torn_tail_sequence_map_tile_and_header_rejections",exact)
	var decoded: Dictionary=ColonyJournal._read_owned(bytes);var public: Dictionary=ColonyJournal.read(bytes)
	var value: Dictionary=decoded.records[0].state
	exact=value.integer_map.keys()[0] is int and value.integer_map[2][0] is Vector2i and value.rows[0].id is int and value.rows[0].name=="literal {speed}" and value.unicode==source.unicode
	value.rows[0].memo.values.append("changed");value.integer_map[1]="changed"
	check.call("JOURNAL/owned_results_keep_types_unicode_order_and_private_containers_without_input_aliases",exact and public.records[0].state==source and source.rows[0].memo.values.size()==3 and source.integer_map[1]=="first" and compare(bytes))
	var world: ColonyWorld=ColonyTests.world();var initial: PackedByteArray=ColonyCodec.encode(world)
	var base: Dictionary=world.payload().duplicate(true);var parent: String=world.canonical_hash()
	world.queue_command("food_policy",{"enabled":true});world.step()
	bytes=ColonyJournal.frame({"sequence":"1","kind":"tick","tick":world.tick,"delta":{"version":1,"base_tick":base.tick,"campaign_id":world.session_id,"parent":parent,"patch":ColonyDelta.make(base,world.payload())}})
	decoded=ColonyJournal._read_owned(bytes)
	var replayed: Dictionary=ColonyJournal.replay(ColonyCodec.decode(initial).world,decoded.records,parent,decoded.digests,base)
	exact=replayed.has("world") and replayed.world.payload()==world.payload() and compare(bytes)
	if replayed.has("world"):
		for tick in range(120):replayed.world.step();world.step()
		exact=exact and replayed.world.payload()==world.payload() and world.invariant_errors().is_empty()
	check.call("JOURNAL/owned_verification_keeps_complete_delta_replay_and_future_world_exact",exact)
