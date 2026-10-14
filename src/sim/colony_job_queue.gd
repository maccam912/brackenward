class_name ColonyJobQueue
extends RefCounted
## Disposable max heap of fixed scheduling scores for one resident's search.
var jobs: Array
var heap: Array[Vector3i] = []

func _init(candidates: Array, world: ColonyWorld, citizen: Dictionary) -> void:
	jobs=candidates
	for index in range(jobs.size()):
		var job: Dictionary = jobs[index]
		heap.append(Vector3i(world._job_rank(job,citizen),-job.id,index))
	for index in range(heap.size()/2-1,-1,-1): _down(index)

func pop() -> Dictionary:
	if heap.is_empty(): return {}
	var first: Vector3i = heap[0];var last: Vector3i = heap.pop_back()
	if not heap.is_empty(): heap[0]=last;_down(0)
	return jobs[first.z]

func _down(index: int) -> void:
	while index*2+1<heap.size():
		var child: int = index*2+1
		if child+1<heap.size() and _higher(heap[child+1],heap[child]): child+=1
		if not _higher(heap[child],heap[index]): return
		var temporary: Vector3i = heap[index];heap[index]=heap[child];heap[child]=temporary;index=child

func _higher(a: Vector3i, b: Vector3i) -> bool:
	return a.x>b.x if a.x!=b.x else a.y>b.y
