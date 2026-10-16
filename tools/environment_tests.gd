class_name EnvironmentTests
extends RefCounted

static func run(check: Callable) -> void:
	seasons(check)
	var image: Image = EnvironmentArt.ATLAS.get_image()
	var regions: Dictionary = EnvironmentArt.rectangles()
	var valid: bool = regions.size()==300
	for semantic in regions:
		var rectangle: Rect2 = EnvironmentArt.rectangle(semantic)
		valid=valid and Rect2(Vector2.ZERO,image.get_size()).encloses(rectangle) and not image.get_region(Rect2i(rectangle)).is_invisible()
	check.call("ART/environment_300_semantic_regions_are_nonempty_and_in_bounds",valid)
	var world: ColonyWorld = ColonyTests.world()
	valid=true
	for definition in world.definitions.buildings.values():
		for rotation in range(4):
			var footprint: Vector2 = Vector2(definition.width,definition.height) if rotation%2==0 else Vector2(definition.height,definition.width)
			valid=valid and EnvironmentArt.rectangle("building/%s/%d" % [definition.id,rotation]).size==footprint*16+Vector2(0,12)
	check.call("ART/all_34_building_rotations_match_catalog_footprints",valid)
	for definition in world.definitions.crops.values():
		var hashes: Dictionary = {}
		for stage in range(5): hashes[image.get_region(Rect2i(EnvironmentArt.rectangle("crop/%s/%d" % [definition.id,stage]))).get_data().hex_encode().sha256_text()]=true
		check.call("ART/crop_%s_has_five_distinct_shapes" % definition.id,hashes.size()==5)
	check.call("ART/supply_pile_heights_cover_small_medium_full_stacks",[1,16,17,33,34,50].map(func(n:int)->int:return EnvironmentArt.pile_tier(n,50))==[0,0,1,1,2,2])
	var field: Dictionary = {"planted":false,"ripe_tick":0,"growth":0}
	var stages: Array[int] = [EnvironmentArt.crop_stage(field,{"growth":1000})]
	field.planted=true
	for growth in [0,150,400]: field.growth=growth;stages.append(EnvironmentArt.crop_stage(field,{"growth":1000}))
	field.ripe_tick=1;stages.append(EnvironmentArt.crop_stage(field,{"growth":1000}))
	check.call("ART/farm_visuals_follow_real_planting_growth_and_readiness",stages==[0,1,2,3,4])
	check.call("ART/night_is_visibly_cool_dawn_remains_readable_and_midday_is_untinted",EnvironmentArt.night_color(7200).r>=0.60 and EnvironmentArt.night_color(7200).b>EnvironmentArt.night_color(7200).r and EnvironmentArt.night_color(3600)==Color.WHITE and EnvironmentArt.night_color(1800).r>EnvironmentArt.night_color(7200).r)
	var sources: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/environment_sources.json"))
	check.call("ART/tiny_town_exact_cc0_license_is_retained",FileAccess.get_sha256("res://assets/licenses/kenney_tiny_town.txt")==sources.license_sha256 and sources.components.size()==19)

static func seasons(check: Callable) -> void:
	var exact: bool=true
	for season in range(4):
		for variant in range(3):
			var semantic: String=EnvironmentArt.tree_semantic(variant,season*8*7200+3600)
			exact=exact and EnvironmentArt.rectangle(semantic).size==Vector2(32,40)
			if variant==0 or season<2:exact=exact and semantic=="resource/tree/%d" % variant
			else:exact=exact and semantic=="resource/tree_%s/%d" % ["autumn" if season==2 else "winter",variant]
	check.call("ART/seasonal_broadleaf_shapes_preserve_evergreens_and_foot_anchors",exact)
