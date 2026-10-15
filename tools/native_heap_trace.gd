class_name NativeHeapTrace
extends RefCounted
## Diagnostic-only frame-boundary process heap observations; no world/file access.
const LIMIT: int=32
var baseline_bytes: int=0
var maximum_bytes: int=0
var valid_frames: int=0
var unavailable_frames: int=0
var highwater_changes: int=0
var peak_context: Dictionary={}
var events: Array[Dictionary]=[]

func reset(baseline: int) -> void:
	baseline_bytes=maxi(0,baseline);maximum_bytes=baseline_bytes
	valid_frames=0;unavailable_frames=0;highwater_changes=0;peak_context={};events=[]

func observe(heap_bytes: int, context: Callable=Callable()) -> void:
	if heap_bytes<=0:unavailable_frames+=1;return
	valid_frames+=1
	if heap_bytes<=maximum_bytes:return
	maximum_bytes=heap_bytes;highwater_changes+=1
	peak_context=context.call().duplicate(true) if context.is_valid() else {}
	events.append({"heap_bytes":heap_bytes,"context":peak_context})
	if events.size()>LIMIT:events.pop_front()

func report() -> Dictionary:
	return {"format":"brackenward-native-frame-heap","version":1,"scope":"Diagnostic frame-boundary process heap; concurrent workers/global allocator overlap. Ownership flags describe retained work,not allocation causation; bounded collector allocations are included. Separate from the unchanged periodic-sample20MiB proxy and physical Android/PSS certification.","baseline_bytes":baseline_bytes if baseline_bytes>0 else null,"max_bytes":maximum_bytes if maximum_bytes>0 else null,"peak_growth_bytes":maximum_bytes-baseline_bytes if baseline_bytes>0 else null,"valid_frame_samples":valid_frames,"unavailable_frame_samples":unavailable_frames,"highwater_changes":highwater_changes,"event_limit":LIMIT,"events":events.duplicate(true),"peak_context":peak_context.duplicate(true)}
