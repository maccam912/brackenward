extends SceneTree
## Paired CPU diagnosis; the former selector remains an independent comparator.

func _initialize() -> void:
	call_deferred("run")

func former(world: ColonyWorld, candidates: Array, origin: Vector2i, needed: int) -> Array:
	if needed<=0: return []
	if needed>16:
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return ColonyProduction.input_before(world,a,b,origin))
		return candidates
	var result: Array = [];var remaining: Array = candidates.duplicate()
	while needed>0 and not remaining.is_empty():
		var best: int = 0
		for index in range(1,remaining.size()):
			if ColonyProduction.input_before(world,remaining[index],remaining[best],origin): best=index
		var stack: Dictionary = remaining[best];remaining.remove_at(best);result.append(stack)
		needed-=maxi(0,stack.count-world._reserved(stack))
	return result

func run() -> void:
	var fixture: Dictionary = StressFixture.make()
	if not fixture.has("world"): printerr(fixture);quit(2);return
	var world: ColonyWorld = fixture.world
	var choices: Array = world.nonempty_stacks()
	var origin: Vector2i = Vector2i(68,72);var before: String = world.canonical_hash()
	var rows: Array = [];var exact: bool = true
	for needed in [1,4,16,40]:
		var old_us: int = 0;var current_us: int = 0
		for round in range(85):
			# Alternate ordering and discard warmup to reduce first-call bias.
			for old in [round%2==0,round%2!=0]:
				var input: Array = choices.duplicate();var start: int = Time.get_ticks_usec()
				var selected: Array = former(world,input,origin,needed) if old else ColonyProduction.first_inputs(world,input,origin,needed)
				var duration: int = Time.get_ticks_usec()-start
				if round>=5:
					if old: old_us+=duration
					else: current_us+=duration
				if not old and round==0: exact=exact and selected==former(world,choices.duplicate(),origin,needed)
		rows.append({"needed":needed,"calls_per_selector":80,"former_us":old_us,"current_us":current_us})
	var result: Dictionary = {"scope":"Paired selector CPU microbenchmark on the same 1,000-stack synthetic fixture; not whole-game or physical-device certification","source_version":ProjectSettings.get_setting("application/config/version"),"candidates":choices.size(),"canonical_unchanged":world.canonical_hash()==before,"exact_selection":exact,"rows":rows}
	print(JSON.stringify(result,"\t",true))
	quit(0 if exact and result.canonical_unchanged else 1)
