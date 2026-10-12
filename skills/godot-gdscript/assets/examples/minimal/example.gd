extends SceneTree
var checks: Array = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	output = args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("OUTPUT_DIRECTORY_FAILED")
		quit(1)
		return
	call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks.append({"name": label, "status": "passed" if value else "failed"})
func finish() -> void:
	var ok := not checks.is_empty()
	for item: Dictionary in checks:
		ok = ok and item.status == "passed"
	var result := {"schema_version": 1, "status": "passed" if ok else "failed", "engine": Engine.get_version_info(), "platform": OS.get_name(), "display": DisplayServer.get_name(), "checks": checks, "artifacts": [output]}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		push_error("REPORT_WRITE_FAILED")
		quit(1)
		return
	file.store_string(JSON.stringify(result, "	"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	quit(0 if ok else 1)

class Counter extends RefCounted:
	signal changed(value: int)
	var value: int = 0
	func increment() -> void:
		value += 1
		changed.emit(value)
var observed: int = 0
func _on_changed(value: int) -> void:
	observed = value
func _run() -> void:
	var counter := Counter.new()
	counter.changed.connect(_on_changed)
	counter.increment()
	expect(observed == 1, "typed_signal_delivered")
	await process_frame
	counter.increment()
	expect(counter.value == 2 and observed == 2, "async_continuation")
	expect(counter.changed.is_connected(_on_changed), "connection_not_duplicated")
	finish()
