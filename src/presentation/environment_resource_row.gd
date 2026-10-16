class_name EnvironmentResourceRow
extends Node2D
## A visible chunk row and global-ID interval, rather than one Node per tree.
var world: ColonyWorld
var renderer: Node
var records: Array = []
var tint: Color = Color.WHITE
var selected_bounds: Rect2 = Rect2()

func _draw() -> void:
	var started: int = Time.get_ticks_usec()
	for resource in records:
		var kind: String = resource.definition
		if resource.remaining<=0:
			if kind!="tree": continue
			if ColonyNature.tree(world,resource.id).cleared: continue
			kind="sapling" if ColonyNature.tree(world,resource.id).planted else "stump"
		var rectangle: Rect2 = EnvironmentArt.rectangle("resource/%s/%d" % [kind,resource.id%3 if kind=="tree" else 0])
		var point: Vector2 = Vector2((resource.x+0.5)*16.0,0)
		var destination: Rect2 = Rect2(point-Vector2(rectangle.size.x*0.5,rectangle.size.y),rectangle.size)
		var color: Color = tint
		if kind=="tree" and selected_bounds.has_area() and Rect2(destination.position+position,destination.size).intersects(selected_bounds): color.a=0.4
		draw_texture_rect_region(EnvironmentArt.ATLAS,destination,rectangle,color)
	if renderer!=null: renderer.account_draw(Time.get_ticks_usec()-started)
