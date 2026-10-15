class_name PreparationReadTests
extends RefCounted
## Retained 6f4dc91 body; only the record class alias preserves original String storage.
## Original method SHA-256 51b5a11baafa4db5a709858bc4463a091f27322a613314b65258039c85b4be3e
static func original(captured: Dictionary, catalog: Dictionary) -> Dictionary:
	if not captured.is_read_only(): return {"error":"Snapshot preparation needs an owned immutable capture"}
	var frozen: ColonyWorld = ColonyWorld.new(catalog)
	for field in captured:
		if field in ["content","content_hash"]: continue
		if captured[field] is Array: frozen.get(field).assign(captured[field])
		else: frozen.set(field,captured[field])
	frozen.reset_stack_queries()
	var result: LegacyPreparedSnapshot = LegacyPreparedSnapshot.new()
	result.payload=captured
	result.text=JSON.stringify(ColonyState.pack(captured),"",true)
	result.digest=result.text.sha256_text()
	var verified: Dictionary = ColonyCodec.decode(ColonyCodec.wrap_payload(frozen,result.text))
	if not verified.has("world") or verified.world.payload()!=captured: return {"error":"Snapshot preparation failed full validation: "+str(verified.get("error","state mismatch"))}
	result.validated=true
	return {"snapshot":result}


static func run(check: Callable) -> void:
	for world in [ColonyTests.world(),LargeColonyTests.population(20)]:
		var before: String=world.canonical_hash()
		var captured: Dictionary=ColonyCapture.new().capture(world,[])
		var baseline: Dictionary=original(captured,world.definitions)
		var current: Dictionary=ColonyPreparedSnapshot.prepare(captured,world.definitions)
		var exact: bool=baseline.has("snapshot") and current.has("snapshot") and baseline.snapshot.text==current.snapshot.text and baseline.snapshot.digest==current.snapshot.digest and baseline.snapshot.validated and current.snapshot.validated and is_same(current.snapshot.payload,captured)
		check.call("SAVE/preparation_owned_json_matches_full_original_%d_people" % world.citizens.size(),exact and before==world.canonical_hash())
		if exact:
			var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.wrap_payload(world,current.snapshot.text))
			check.call("SAVE/preparation_owned_json_still_passes_full_external_codec_%d_people" % world.citizens.size(),decoded.has("world") and decoded.world.canonical_hash()==before)
	var source: ColonyWorld=ColonyTests.world();var captured: Dictionary=ColonyCapture.new().capture(source,[])
	check.call("SAVE/preparation_owned_json_rejects_mutable_capture",ColonyPreparedSnapshot.prepare(source.payload(),source.definitions).has("error") and original(source.payload(),source.definitions).has("error"))
	var wrong_catalog: Dictionary=source.definitions.duplicate();wrong_catalog.content_hash="0".repeat(64)
	check.call("SAVE/preparation_owned_json_keeps_catalog_identity_validation",ColonyPreparedSnapshot.prepare(captured,wrong_catalog).has("error") and original(captured,wrong_catalog).has("error"))
	var missing_rejected: bool=true
	for field in ["session_id","generator_version"]:
		var missing: Dictionary=captured.duplicate(true);missing.erase(field);ColonyCapture._freeze(missing)
		missing_rejected=missing_rejected and ColonyPreparedSnapshot.prepare(missing,source.definitions).has("error") and original(missing,source.definitions).has("error")
	check.call("SAVE/preparation_owned_json_rejects_missing_identity_without_runtime_error",missing_rejected)
	var invalid: Dictionary=captured.duplicate(true);invalid.citizens[0].rest=-1;ColonyCapture._freeze(invalid)
	check.call("SAVE/preparation_owned_json_keeps_full_schema_rejection",ColonyPreparedSnapshot.prepare(invalid,source.definitions).has("error") and original(invalid,source.definitions).has("error"))
	var parsed: Dictionary={"id":"4","tiles":[{"$tile":[2.0,3.0]}],"nested":{"$map":[["9",{"tick":"9007199254740"}]]}}
	var expected: Variant=ColonyState.unpack(parsed)
	var actual: Variant=ColonyPreparedSnapshot._unpack_owned_json(parsed)
	check.call("SAVE/owned_json_reuses_parsed_containers_and_exact_map_coordinate_types",is_same(parsed,actual) and actual==expected and actual.nested.keys()==[9] and actual.tiles[0] is Vector2i)
	var unchanged: Dictionary=captured.duplicate(true)
	check.call("SAVE/owned_json_refuses_read_only_capture_without_mutation",ColonyPreparedSnapshot._unpack_owned_json(captured)==null and captured==unchanged)
	encoding_cases(check)
	saved_fixture_corpus(check)

static func encoding_cases(check: Callable) -> void:
	var valid: Array=[true,false,0,1,-1,9007199254740991,"plain",[],{},[1,{"id":"42","tile":{"$tile":[127,0]}}],{"$map":[["1",false],["2",[]]]}]
	var invalid: Array=[null,1.5,9007199254740992.0,{"id":""},{"id":"01"},{"id":"-1"},{"id":"+1"},{"id":"1234567890123456"},{"$tile":[-1,0]},{"$tile":[128,0]},{"$tile":[0,0],"extra":1},{"$tile":[0]},{"$map":{}},{"$map":[["1",true],["1",false]]},{"$map":[["1",null]]},{"$map":[["1"]]},{"nested":[null]}]
	var deep: Variant="leaf"
	for depth in range(34):
		deep=[deep]
		(valid if depth<=31 else invalid).append(deep)
	var all_valid: bool=true;var all_invalid: bool=true
	for value in valid:
		var expected: Variant=ColonyState.unpack(value)
		var actual: Variant=ColonyPreparedSnapshot._unpack_owned_json(value.duplicate(true) if value is Dictionary or value is Array else value)
		all_valid=all_valid and actual==expected and actual!=null
	for value in invalid:
		var expected: Variant=ColonyState.unpack(value)
		var actual: Variant=ColonyPreparedSnapshot._unpack_owned_json(value.duplicate(true) if value is Dictionary or value is Array else value)
		all_invalid=all_invalid and expected==null and actual==null
	check.call("SAVE/owned_json_matches_original_scalar_map_tile_and_depth_boundaries",all_valid and all_invalid)
	var random: ParkMiller=ParkMiller.new(104729);var exact: bool=true
	for index in range(400):
		var value: Dictionary={"id":random.next(),"tick":random.next(),"name":"literal {id} %d" % index,"unicode":"Sun ☀ 雨\n\"quoted\" \\ literal {tick}","empty":{},"list":[],"tiles":[Vector2i(random.next()%128,random.next()%128)]}
		value["maps"]={index+1:{"worker":random.next(),"value":random.next()%1000,"flags":[true,false]},index+401:[]}
		for count in range(index%7): value.list.append({"id":random.next(),"amount":random.next()%128,"xy":Vector2i(random.next()%128,random.next()%128)})
		var packed: String=JSON.stringify(ColonyState.pack(value),"",true)
		var baseline: Variant=ColonyState.unpack(JSON.parse_string(packed))
		var current: Variant=ColonyPreparedSnapshot._unpack_owned_json(JSON.parse_string(packed))
		exact=exact and baseline==value and current==baseline
	check.call("SAVE/owned_json_four_hundred_representations_match_independent_decoder",exact)

static func saved_fixture_corpus(check: Callable) -> void:
	var names: PackedStringArray=DirAccess.get_files_at("res://tests/fixtures")
	names.sort();var count: int=0;var failed: Array[String]=[]
	for name in names:
		if not name.ends_with(".brackenward"):continue
		count+=1
		var path: String="res://tests/fixtures/"+name
		var bytes: PackedByteArray=FileAccess.get_file_as_bytes(path);var input_hash: String=FileAccess.get_sha256(path)
		var loaded: Dictionary=ColonyCodec.decode(bytes)
		if not loaded.has("world"):failed.append(name+": load");continue
		var world: ColonyWorld=loaded.world;var before: String=world.canonical_hash()
		var captured: Dictionary=ColonyCapture.new().capture(world,[])
		var old: Dictionary=original(captured,world.definitions)
		var current: Dictionary=ColonyPreparedSnapshot.prepare(captured,world.definitions)
		if not old.has("snapshot") or not current.has("snapshot"):failed.append(name+": prepare");continue
		if old.snapshot.text!=current.snapshot.text or current.snapshot.digest!=before or world.canonical_hash()!=before or input_hash!=FileAccess.get_sha256(path):failed.append(name+": equality or input changed")
	check.call("SAVE/owned_preparation_matches_original_for_thirty_two_immutable_save_fixtures",count==32 and failed.is_empty(),str(failed))
