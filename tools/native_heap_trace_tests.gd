class_name NativeHeapTraceTests
extends RefCounted

static func run(check: Callable) -> void:
	var trace: NativeHeapTrace=NativeHeapTrace.new();trace.reset(1000)
	var calls: Array=[0];var source: Dictionary={"tick":42,"nested":{"busy":true}}
	var producer: Callable=func()->Dictionary:calls[0]+=1;return source
	for bytes in [1000,900,1100,1050,1200]:trace.observe(bytes,producer)
	var report: Dictionary=trace.report()
	check.call("HEAPTRACE/context_is_only_collected_for_real_new_highwater",calls[0]==2 and report.valid_frame_samples==5 and report.highwater_changes==2 and report.max_bytes==1200 and report.peak_growth_bytes==200 and report.events.size()==2)
	source.nested.busy=false;source.tick=99
	report.events[0].context.nested.busy=false;report.peak_context.tick=123
	report=trace.report()
	check.call("HEAPTRACE/observations_and_reports_own_private_context_without_world_aliases",report.events[0].context.nested.busy and report.peak_context.tick==42 and source.tick==99 and not source.nested.busy)
	for index in range(100):trace.observe(1300+index)
	report=trace.report()
	check.call("HEAPTRACE/highwater_history_is_bounded_and_retains_actual_maximum",report.events.size()==32 and report.event_limit==32 and report.highwater_changes==102 and report.max_bytes==1399 and report.events[0].heap_bytes==1368 and report.events[-1].heap_bytes==1399)
	trace.reset(0);trace.observe(0,producer);trace.observe(-1,producer);report=trace.report()
	check.call("HEAPTRACE/unavailable_memory_never_becomes_zero_growth_or_context",report.baseline_bytes==null and report.max_bytes==null and report.peak_growth_bytes==null and report.valid_frame_samples==0 and report.unavailable_frame_samples==2 and report.events.is_empty() and calls[0]==2)
	trace.observe(500);report=trace.report();trace.reset(2000);var reset: Dictionary=trace.report()
	check.call("HEAPTRACE/unknown_baseline_and_reset_keep_measurement_scope_exact",report.max_bytes==500 and report.peak_growth_bytes==null and reset.baseline_bytes==2000 and reset.max_bytes==2000 and reset.peak_growth_bytes==0 and reset.valid_frame_samples==0 and reset.unavailable_frame_samples==0 and reset.highwater_changes==0 and reset.events.is_empty())
