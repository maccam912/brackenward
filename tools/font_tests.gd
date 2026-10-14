class_name FontTests
extends RefCounted

static func run(check: Callable) -> void:
	var body: FontFile = ColonyFonts.body()
	var heading: FontFile = ColonyFonts.heading()
	check.call("FONT/no_system_or_unreviewed_fallback",not body.allow_system_fallback and body.fallbacks.is_empty() and not heading.allow_system_fallback and heading.fallbacks==[body])
	var covered: bool = true
	for code in range(32,127): covered=covered and body.has_char(code) and (heading.has_char(code) or body.has_char(code))
	check.call("FONT/complete_basic_latin_uses_only_approved_faces",covered)
	var original: String = "Communal supper scheduled for 18:00\u201320:00."
	var saved: String = original
	check.call("FONT/legacy_punctuation_changes_display_only",not body.has_char(0x2013) and ColonyFonts.display(original)=="Communal supper scheduled for 18:00-20:00." and original==saved and ColonyFonts.warning(original).is_empty())
	check.call("FONT/supported_body_characters_remain_exact",ColonyFonts.display("-5 °C · 8×6 … Café")=="-5 °C · 8×6 … Café")
	check.call("FONT/unavailable_imported_characters_have_readable_recovery",ColonyFonts.display("Old \u4e00\u4e8c")=="Old ??" and ColonyFonts.warning("Old \u4e00\u4e8c").contains("original text is kept"))
	check.call("FONT/layout_whitespace_is_preserved",ColonyFonts.display("First\nSecond\tThird")=="First\nSecond\tThird")
	var world: ColonyWorld = CharterTests.supper_world()
	var command: int = world.queue_command("start_supper",{});world.step()
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	var before: String = world.canonical_hash()
	var facts: Array = world.chronicle_state.facts.filter(func(f:Dictionary)->bool:return f.kind=="supper_scheduled")
	var text: String = "" if facts.is_empty() else facts[0].text
	check.call("FONT/real_supper_fact_save_remains_exact_after_display",world.receipts.get(command)=="accepted" and decoded.has("world") and decoded.world.canonical_hash()==before and text.contains("\u2013") and ColonyFonts.display(text).contains("18:00-20:00") and world.canonical_hash()==before and facts[0].text==text)
