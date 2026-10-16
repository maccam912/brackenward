class_name Content7Migration
extends RefCounted

static func audit() -> Dictionary:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/content7-work/preservation.json"))
	var passed: bool = manifest.content=="colony-v7" and manifest.schema==23 and manifest.source_commit=="f338b94f83285ac6501e04b0dd9fe12370256779" and manifest.catalog_hash==ColonyCatalog.load_data("res://data/catalogs/colony_v7.json").content_hash and manifest.producer_sha256==FileAccess.get_sha256("res://tools/record_content7_work_fixture.gd")
	var rows: Array = []
	for entry in manifest.snapshots:
		var row: Dictionary = Content3Migration.snapshot(entry);rows.append(row);passed=passed and row.passed
	for path in manifest.delta: passed=passed and FileAccess.get_sha256("res://tests/fixtures/"+path)==manifest.delta[path]
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://tests/fixtures/content7-work/delta-base.brackenward")
	var header: Dictionary = JSON.parse_string(bytes.get_string_from_utf8())
	var base: Dictionary = ColonyCodec.decode(bytes)
	var journal: Dictionary = ColonyJournal.read(FileAccess.get_file_as_bytes("res://tests/fixtures/content7-work/delta.frames"))
	var final: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/content7-work/delta-final.brackenward"))
	var recovered: Dictionary = ColonyJournal.replay(base.world,journal.records,header.sha256,journal.digests,ColonyJournal.snapshot_base(header)) if base.has("world") and not journal.has("error") else {}
	var exact: bool = recovered.has("world") and final.has("world") and recovered.world.tick==2400 and recovered.world.canonical_hash()==final.world.canonical_hash()
	return {"passed":passed and rows.size()==3 and exact,"rows":rows,"delta_fold_preserved":exact,"scope":"Frozen v7 loaded-haul and 600-tick journal acknowledgements preserve every field and original byte; hunger checkpoints apply only to future ticks."}
