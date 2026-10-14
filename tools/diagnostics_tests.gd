class_name DiagnosticsTests
extends RefCounted

static func run(check: Callable) -> void:
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
		for speed in [0,1,2,4]:
			data.speed=speed
			for index in range(100): data.record(stage,50001+index)
	data.count("storage_alerts");data.count("arbitrary string")
	report=data.report({"build":"fixture","model":"device"})
	check.call("PERF/long_session_bounds_all_histograms_and_latest_slow_events",data.samples.size()==40 and data.slow_events.size()==32 and report.timings.size()==40 and report.timings.all(func(e:Dictionary)->bool:return e.count==100 and e.buckets.size()==11))
	check.call("PERF/full_bounded_report_fits_64kib_export_limit",JSON.stringify(report,"\t",true).to_utf8_buffer().size()<FrameDiagnostics.MAX_EXPORT_BYTES)
	check.call("PERF/counters_use_only_named_codes",report.counters.storage_alerts==1 and report.counters.size()==4)
	report.slow_events.clear();report.metadata.model="changed";report.timings[0].buckets.clear()
	check.call("PERF/preview_owns_its_data_without_mutating_collection",data.slow_events.size()==32 and data.samples.values()[0].buckets.size()==11)
	data.reset()
	check.call("PERF/reset_discards_only_measurements",data.samples.is_empty() and data.slow_events.is_empty() and data.previous_frame_us==0 and data.counters.values().all(func(n:int)->bool:return n==0))
	data.tick=1901;data.speed=0;data.record("map_draw_commands",60000,1900,4)
	check.call("PERF/deferred_draw_totals_keep_their_original_tick_and_speed",data.slow_events[0].tick=="1900" and data.slow_events[0].speed==4 and data.tick==1901 and data.speed==0)
