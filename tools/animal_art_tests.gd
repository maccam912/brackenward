class_name AnimalArtTests
extends RefCounted

static func run(check: Callable) -> void:
	var all_regions: Dictionary = {}
	var image: Image = AnimalArt.ATLAS.get_image()
	for kind in ["hare","deer","boar","marsh_goose","hen","pack_goat","merchant_pack"]:
		var valid: bool = true
		var states: Dictionary = AnimalArt.kinds()[kind].states
		for state in states:
			for direction in range(4):
				for frame in range(int(states[state].frames)):
					var rectangle: Rect2 = AnimalArt.frame_rect(kind,state,direction,frame)
					valid=valid and Rect2(Vector2.ZERO,image.get_size()).encloses(rectangle) and not all_regions.has(rectangle) and not image.get_region(Rect2i(rectangle)).is_invisible()
					all_regions[rectangle]=true
		check.call("ART/animal_%s_has_four_facing_nonempty_distinct_regions" % kind,valid and states.has_all(["idle","walk","eat","downed"]) and states.walk.frames==4 and states.eat.frames==2 and states.idle.frames==2 and states.downed.frames==1)
	check.call("ART/all_268_animal_frames_fit_one_shared_atlas",all_regions.size()==268 and AnimalArt.kinds().boar.states.charge.frames==4)
	for kind in AnimalArt.kinds():
		var adult: AtlasTexture=AnimalArt.portrait_texture(kind)
		var young: AtlasTexture=AnimalArt.portrait_texture(kind,true)
		var downed: AtlasTexture=AnimalArt.portrait_texture(kind,false,true)
		check.call("ART/animal_%s_portraits_use_real_map_frames_and_juvenile_scale" % kind,adult.atlas==AnimalArt.ATLAS and adult.region==AnimalArt.frame_rect(kind,"idle",1,0) and adult.margin==Rect2() and young.region==adult.region and is_equal_approx(24.0/(24+young.margin.size.x),0.7) and downed.region==AnimalArt.frame_rect(kind,"downed",1,0))
	var world: ColonyWorld = ColonyTests.world()
	ColonyWildlife.spawn(world,"hare",Vector2i(73,66));ColonyWildlife.spawn(world,"boar",Vector2i(74,66))
	var saved: Dictionary = world.payload().duplicate(true)
	var animal: Dictionary = world.wildlife_state.animals[0].duplicate(true)
	animal.route=[Vector2i(animal.x+1,animal.y)];animal.progress=5000
	var sprite: AnimalSprite = AnimalSprite.new();sprite.record=animal;sprite.kind=animal.definition
	sprite.animate(world,0.1,4,false)
	check.call("ART/animal_walk_uses_exact_authoritative_half_edge",sprite.position==Vector2(animal.x+1.0,animal.y+0.5)*16 and sprite.pose=="walk" and sprite.facing==1)
	check.call("ART/animal_walk_caps_accelerated_visuals_at_ten_fps",is_equal_approx(sprite.clock,1.0))
	var clock: float = sprite.clock;sprite.animate(world,1.0,0,false)
	check.call("ART/paused_animal_animation_does_not_accumulate_time",sprite.clock==clock)
	sprite.animate(world,1.0,4,true)
	check.call("ART/reduced_motion_keeps_first_pose_and_exact_position",sprite.animation_frame==0 and sprite.position==Vector2(animal.x+1.0,animal.y+0.5)*16)
	animal.route=[];animal.progress=0;sprite.previous_feed=-999;animal.crop_day=world.tick/7200;sprite.animate(world,0,1,false)
	check.call("ART/loading_an_already_fed_animal_does_not_replay_feeding",sprite.pose=="idle")
	animal.crop_day+=1;sprite.animate(world,0,1,false)
	check.call("ART/new_actual_feeding_change_shows_eating",sprite.pose=="eat")
	animal.health=0;sprite.animate(world,0,1,false)
	check.call("ART/dead_animal_uses_down_pose_without_new_meat_or_damage",sprite.pose=="downed" and world.payload()==saved)
	sprite.free()
	var boar: Dictionary = world.wildlife_state.animals.filter(func(a:Dictionary)->bool:return a.definition=="boar")[0].duplicate(true)
	boar.route=[Vector2i(boar.x,boar.y+1)];boar.progress=100;boar.attacker=1
	sprite=AnimalSprite.new();sprite.record=boar;sprite.kind="boar";sprite.animate(world,0,1,false)
	check.call("ART/wounded_boar_advance_has_a_distinct_charge_pose",sprite.pose=="charge")
	sprite.free()
	var guest: GuestSprite = GuestSprite.new();guest.role="enemy";guest.record=ColonyDefense.enemy_template()
	guest.record.id=999;guest.record.definition="bow_raider";guest.record.health=55;guest.record.x=60;guest.record.y=60;guest.record.route=[Vector2i(60,59)];guest.record.progress=2500
	guest.animate_guest(world,0.1,1,false)
	check.call("ART/hostile_reuses_adult_atlas_with_real_weapon_and_edge",guest.texture==CitizenArt.ATLAS and guest.weapon=="bow" and guest.pose=="walk" and guest.facing==2 and guest.position==Vector2(60.5,60.25)*16 and guest.hostile)
	guest.record.state="Downed";guest.record.route=[];guest.record.progress=0;guest.record.health=10;guest.animate_guest(world,0.1,1,false)
	check.call("ART/downed_hostile_is_visibly_neutral",guest.pose=="downed" and not guest.hostile and guest.health_fraction>0)
	guest.record.state="Leaving";guest.record.health=25;guest.animate_guest(world,0.5,1,false)
	check.call("ART/recovered_leaving_guest_never_regains_threat_marker",not guest.hostile and guest.pose!="downed")
	check.call("ART/animal_and_guest_presentation_preserve_every_world_field",world.payload()==saved)
	guest.free()
