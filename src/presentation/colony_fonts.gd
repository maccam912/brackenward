class_name ColonyFonts
extends RefCounted
## Approved font chain and presentation-only recovery for historical text.
static var body_font: FontFile = preload("res://assets/exported/fonts/kenney_mini.ttf")
static var heading_font: FontFile = preload("res://assets/exported/fonts/kenney_bold.ttf")
static var configured: bool = false

static func configure() -> void:
	if configured: return
	body_font.allow_system_fallback=false;body_font.fallbacks=[]
	heading_font.allow_system_fallback=false;heading_font.fallbacks=[body_font]
	configured=true

static func body() -> FontFile:
	configure();return body_font

static func heading() -> FontFile:
	configure();return heading_font

static func display(text: String) -> String:
	configure()
	# Older facts/save errors contain this punctuation. Keep their saved bytes;
	# only their displayed form uses the supported Basic Latin equivalent.
	var result: String = text.replace("\u2013","-")
	if result.to_utf8_buffer().size()==result.length(): return result
	for index in range(result.length()):
		var code: int = result.unicode_at(index)
		if code>126 and not body_font.has_char(code): result=result.replace(String.chr(code),"?")
	return result

static func warning(text: String) -> String:
	return "Some characters cannot be displayed with the installed fonts. The original text is kept in the save." if display(text)!=text.replace("\u2013","-") else ""
