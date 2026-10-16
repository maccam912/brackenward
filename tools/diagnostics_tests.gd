class_name DiagnosticsTests
extends RefCounted

class MemoryBridge extends RefCounted:
	var value: int=123456
	var calls: int=0
	func getProcessPssKiB() -> int:
		calls+=1;return value

static func run(check: Callable) -> void:
	tick_observation(check)
	process_memory_sample(check)
	frame_pacing_buckets(check)
	var data: FrameDiagnostics = FrameDiagnostics.new()
	data.frame(1000,1800,1);data.frame(51000,1801,1);data.frame(551001,1802,1)
	var report: Dictionary = data.report({"build":"fixture"})
	var row: Dictionary = report.timings[0]
	check.call("PERF/real_frame_gaps_keep_exact_counts_maxima_and_strict_50ms_boundary",row.count==2 and row.max_ms==500.001 and row.over_50ms==1 and report.slow_events.size()==1)
	check.call("PERF/percentiles_are_labeled_bounded_histogram_upper_values",row.p95_bucket_upper_ms==1000.0 and row.p99_bucket_upper_ms==1000.0 and row.buckets.reduce(func(a:int,b:int)->int:return a+b,0)==2)
	data.record("session",25000);data.speed=4;data.record("session",9000)
	report=data.report({})
	check.call("PERF/paused_1x_2x_4x_timings_remain_separate",report.timings.filter(func(e:Dictionary)->bool:return e.stage=="session").map(func(e:Dictionary)->int:return e.speed)==[1,4])
	data.speed=1;data.record("session",1000001)
	check.call("PERF/overflow_quantiles_never_claim_a_false_upper_bound",data.report({}).timings.filter(func(e:Dictionary)->bool:return e.stage=="session" and e.speed==1)[0].p95_bucket_upper_ms==null)
	data.break_frame_clock();data.frame(9000000000,1900,0)
	check.call("PERF/background_clock_gap_is_excluded",data.samples["frame_gap:1"].count==2 and not data.samples.has("frame_gap:0"))
	data.foreground=false;data.record("session",999999);data.foreground=true
	check.call("PERF/background_callbacks_do_not_pollute_foreground_timings",not data.samples.has("session:0"))
	data.record("/private/unrelated/path",42);data.record("session",-1);data.speed=3;data.record("session",42)
	check.call("PERF/unknown_stage_and_invalid_duration_speed_are_ignored",data.samples.size()==3)
	data.reset();data.speed=2
	for stage in FrameDiagnostics.STAGES:
		for speed in FrameDiagnostics.SPEEDS:
			data.speed=speed
			for index in range(100): data.record(stage,50001+index)
	data.count("storage_alerts");data.count("arbitrary string")
	report=data.report({"build":"fixture","model":"device"})
	check.call("PERF/long_session_bounds_all_histograms_and_latest_slow_events",data.samples.size()==91 and data.slow_events.size()==32 and report.timings.size()==91 and report.timings.all(func(e:Dictionary)->bool:return e.count==100 and e.buckets.size()==14))
	check.call("PERF/full_bounded_report_fits_64kib_export_limit",JSON.stringify(report,"\t",true).to_utf8_buffer().size()<FrameDiagnostics.MAX_EXPORT_BYTES)
	check.call("PERF/counters_use_only_named_codes",report.counters.storage_alerts==1 and report.counters.quiet_sleep_limits==0 and report.counters.size()==5)
	report.slow_events.clear();report.metadata.model="changed";report.timings[0].buckets.clear()
	check.call("PERF/preview_owns_its_data_without_mutating_collection",data.slow_events.size()==32 and data.samples.values()[0].buckets.size()==14)
	data.reset()
	check.call("PERF/reset_discards_only_measurements",data.samples.is_empty() and data.slow_events.is_empty() and data.previous_frame_us==0 and data.counters.values().all(func(n:int)->bool:return n==0))
	data.tick=1901;data.speed=0;data.record("map_draw_commands",60000,1900,4)
	check.call("PERF/deferred_draw_totals_keep_their_original_tick_and_speed",data.slow_events[0].tick=="1900" and data.slow_events[0].speed==4 and data.tick==1901 and data.speed==0)

static func tick_observation(check: Callable) -> void:
	var exact: bool=true
	for speed in [1,2,4]:
		var plain: ColonyWorld=ColonyTests.world();var observed: ColonyWorld=ColonyCodec.decode(ColonyCodec.encode(plain)).world
		var reference: SimRunner=SimRunner.new(plain);var runner: SimRunner=SimRunner.new(observed)
		var data: FrameDiagnostics=FrameDiagnostics.new();var clock: Array=[1000];var ticks: Array=[]
		runner.frame_clock=func()->int:clock[0]+=17;return clock[0]
		runner.tick_observer=func(elapsed:int,tick:int,at_speed:int)->void:data.record("simulation_tick",elapsed,tick,at_speed);ticks.append(tick)
		reference.set_speed(speed);runner.set_speed(speed)
		var expected: int=reference.advance_frame(0.05);var actual: int=runner.advance_frame(0.05)
		var row: Dictionary=data.samples.get("simulation_tick:%d" % speed,{})
		exact=exact and actual==expected and actual==speed*2 and ticks==range(1801,1801+actual) and row.get("count")==actual and row.get("sum_us")==actual*17 and observed.payload()==plain.payload() and runner.speed==reference.speed and runner.accumulator==reference.accumulator
	check.call("PERF/tick_observer_counts_each_completed_tick_without_changing_state_speed_or_backlog",exact)
	var runner: SimRunner=SimRunner.new(ColonyTests.world());var calls: Array=[0]
	runner.tick_observer=func(_elapsed:int,_tick:int,_speed:int)->void:calls[0]+=1
	runner.set_speed(1)
	check.call("PERF/missing_presentation_clock_does_not_fabricate_zero_tick_timings",runner.advance_frame(0.05)==2 and calls[0]==0)

static func process_memory_sample(check: Callable) -> void:
	var game: GameSession=GameSession.new();var bridge: MemoryBridge=MemoryBridge.new()
	var before: String=game.world.canonical_hash();var sample: Dictionary=game._android_pss_metadata(bridge)
	var exact: bool=bridge.calls==1 and sample.android_process_pss_bytes==123456*1024 and sample.android_pss_query_us>=0
	bridge.value=-1;var absent: Dictionary=game._android_pss_metadata(bridge)
	var unavailable: Dictionary=game._android_pss_metadata(null)
	check.call("PERF/explicit_process_memory_sample_uses_exact_byte_units_and_distinguishes_unavailable",exact and bridge.calls==2 and absent.android_process_pss_bytes==null and unavailable.android_process_pss_bytes==null and unavailable.android_pss_query_us==null and game.world.canonical_hash()==before)
	game.free()

static func frame_pacing_buckets(check: Callable) -> void:
	var data: FrameDiagnostics=FrameDiagnostics.new();data.speed=4
	for value in [33334,33335,34000,34001,36000,36001,40000,40001]:data.record("frame_gap",value)
	var row: Dictionary=data.report({}).timings[0]
	check.call("PERF/30fps_bucket_boundaries_are_inclusive_and_exact",row.buckets==[0,0,0,0,1,2,2,2,1,0,0,0,0,0] and row.count==8 and row.max_ms==40.001)
	data.reset()
	for index in range(100):data.record("frame_gap",33400)
	row=data.report({}).timings[0]
	check.call("PERF/ordinary_30fps_jitter_does_not_report_a_50ms_upper_bound",row.p95_bucket_upper_ms==34.0 and row.p99_bucket_upper_ms==34.0 and row.over_50ms==0 and data.slow_events.is_empty())
	data.reset();data.record("frame_gap",35000)
	var early: Dictionary=data.report({}).timings[0]
	data.reset();data.record("frame_gap",38000)
	var late: Dictionary=data.report({}).timings[0]
	check.call("PERF/modest_frame_pacing_delays_remain_distinguishable",early.p95_bucket_upper_ms==36.0 and late.p95_bucket_upper_ms==40.0)
	data.reset();data.record("frame_gap",50000);data.record("frame_gap",50001)
	row=data.report({}).timings[0]
	check.call("PERF/finer_pacing_buckets_keep_the_strict_slow_event_threshold",row.over_50ms==1 and data.slow_events.size()==1 and data.slow_events[0].duration_ms==50.001)
