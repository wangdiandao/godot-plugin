extends SceneTree

const ACTORS := 512
const WARMUP := 12
const SAMPLES := 31
const QUERIES_PER_SAMPLE := 40
const RADIUS := 30.0
var positions: Array[Vector3] = []
var checks: Array = []
var output: String
var benchmark: Dictionary = {}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--out")
	output = args[index + 1] if index >= 0 and index + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
	output = output.replace("\\", "/")
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("OUTPUT_DIRECTORY_FAILED")
		quit(1)
		return
	call_deferred("_run")

func expect(value: bool, label: String) -> void:
	checks.append({"name": label, "status": "passed" if value else "failed"})

func count_distance(origin: Vector3, radius: float) -> int:
	if not valid_query(origin, radius):
		return -1
	var count := 0
	for position in positions:
		if origin.distance_to(position) < radius:
			count += 1
	return count

func count_squared(origin: Vector3, radius: float) -> int:
	if not valid_query(origin, radius):
		return -1
	var count := 0
	var radius_squared := radius * radius
	for position in positions:
		if origin.distance_squared_to(position) < radius_squared:
			count += 1
	return count

func valid_query(origin: Vector3, radius: float) -> bool:
	return origin.is_finite() and is_finite(radius) and radius >= 0.0

func sample_query(query: Callable) -> Dictionary:
	var total := 0
	var start := Time.get_ticks_usec()
	for i in range(QUERIES_PER_SAMPLE):
		total += query.call(Vector3(i % 7, 0, i % 5), RADIUS)
	return {"usec_per_query": float(Time.get_ticks_usec() - start) / QUERIES_PER_SAMPLE, "checksum": total}

func summarize(samples: Array[float]) -> Dictionary:
	var ordered := samples.duplicate()
	ordered.sort()
	return {"p50_usec": ordered[ordered.size() / 2], "p95_usec": ordered[int(ceil(ordered.size() * 0.95)) - 1], "raw_usec_per_query": samples}

func _run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	for i in range(ACTORS):
		var actor := Node3D.new()
		actor.position = Vector3((i * 17) % 101 - 50, (i * 3) % 13 - 6, (i * 29) % 103 - 51)
		scene.add_child(actor)
		positions.append(actor.global_position)
	await process_frame
	expect(scene.get_child_count() == ACTORS, "fixed_scene_actor_count")
	expect(valid_query(Vector3.ZERO, RADIUS) and not valid_query(Vector3.INF, RADIUS) and not valid_query(Vector3.ZERO, -1.0), "invalid_query_guard")
	expect(count_distance(Vector3.ZERO, -1.0) == -1 and count_squared(Vector3.ZERO, -1.0) == -1 and count_squared(Vector3.INF, RADIUS) == -1, "invalid_calls_rejected")
	for radius in [0.0, 1.0, RADIUS, 100.0]:
		expect(count_distance(Vector3.ZERO, radius) == count_squared(Vector3.ZERO, radius), "equivalent_radius_" + str(radius))
	positions[0] = Vector3.ZERO
	expect(count_distance(Vector3.ZERO, 0.1) == count_squared(Vector3.ZERO, 0.1), "modified_data_equivalence")
	positions[0] = scene.get_child(0).global_position
	for i in range(WARMUP):
		sample_query(count_distance)
		sample_query(count_squared)
	var before: Array[float] = []
	var after: Array[float] = []
	var baseline_memory := Performance.get_monitor(Performance.MEMORY_STATIC)
	for i in range(SAMPLES):
		var baseline: Dictionary
		var candidate: Dictionary
		# Alternate ordering to reduce systematic temperature/scheduling bias.
		if i % 2 == 0:
			baseline = sample_query(count_distance)
			candidate = sample_query(count_squared)
		else:
			candidate = sample_query(count_squared)
			baseline = sample_query(count_distance)
		expect(baseline.checksum == candidate.checksum, "sample_equivalence_" + str(i))
		before.append(baseline.usec_per_query)
		after.append(candidate.usec_per_query)
		await process_frame
	benchmark = {"workload": "radius query over static 512-actor position snapshot", "actors": ACTORS, "warmup_pairs": WARMUP, "sample_pairs": SAMPLES, "queries_per_sample": QUERIES_PER_SAMPLE, "radius": RADIUS, "comparison": "distance_to versus distance_squared_to", "timing_scope": "CPU GDScript query only; excludes scene initialization, rendering and snapshot construction", "cpu": OS.get_processor_name(), "renderer": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_current_rendering_driver_name(), "memory_static_before_bytes": baseline_memory, "memory_static_after_bytes": Performance.get_monitor(Performance.MEMORY_STATIC), "before": summarize(before), "after": summarize(after), "gpu_timing": "not_measured", "improvement_is_required_for_pass": false}
	var report := {"schema_version": 1, "engine": Engine.get_version_info(), "platform": OS.get_name(), "display": DisplayServer.get_name(), "benchmark": benchmark, "checks": checks, "artifacts": [output.path_join("benchmark.json")]}
	var passed := true
	for check: Dictionary in checks:
		passed = passed and check.status == "passed"
	report.status = "passed" if passed else "failed"
	var file := FileAccess.open(output.path_join("benchmark.json"), FileAccess.WRITE)
	if file == null:
		push_error("REPORT_WRITE_FAILED")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	scene.queue_free()
	await process_frame
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(report))
	quit(0 if passed else 1)
