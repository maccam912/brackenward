extends SceneTree
## Render the original trait source as an inspectable contact sheet.
func _initialize() -> void:
	var names: Array[String] = ["kind","homebody","steady","sociable","outdoorsy","restless","curious","private"]
	var sheet: Image = Image.create(512,64,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("263C3B"))
	for index in range(names.size()):
		var image: Image = Image.new()
		var source: String = FileAccess.get_file_as_string("res://assets/exported/ui/traits/%s.svg" % names[index])
		if image.load_svg_from_string(source)!=OK: quit(1);return
		sheet.blit_rect(image,Rect2i(0,0,64,64),Vector2i(index*64,0))
	var error: Error = sheet.save_png("res://assets/licenses/trait_preview.png")
	quit(0 if error==OK else 1)
