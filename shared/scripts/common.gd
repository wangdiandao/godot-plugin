extends RefCounted
## Internal helpers. No project autoload or editor plugin is installed.

class ErrorCollector extends Logger:
	var events: Array[Dictionary] = []
	var guard: Mutex = Mutex.new()
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		guard.lock()
		events.append({"function": function, "file": file, "line": line, "message": rationale if not rationale.is_empty() else code, "type": error_type})
		guard.unlock()
	func snapshot() -> Array[Dictionary]:
		guard.lock()
		var copy: Array[Dictionary] = events.duplicate(true)
		guard.unlock()
		return copy

static func arguments() -> Dictionary:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var result: Dictionary = {}
	var i: int = 0
	while i < args.size():
		if not args[i].begins_with("--"):
			result["_error"] = "Expected --key value: " + args[i]
			return result
		var key: String = args[i].trim_prefix("--")
		if i + 1 < args.size() and not args[i + 1].begins_with("--"):
			result[key] = args[i + 1]
			i += 2
		else:
			result[key] = true
			i += 1
	return result

static func absolute(path: String, base: String = "") -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path).simplify_path()
	if path.is_absolute_path():
		return path.simplify_path()
	return (base if not base.is_empty() else ProjectSettings.globalize_path("res://")).path_join(path).simplify_path()

static func report(operation: String) -> Dictionary:
	return {"schema_version": 1, "operation": operation, "created_at_utc": Time.get_datetime_string_from_system(true, true), "engine_version": Engine.get_version_info(), "platform": OS.get_name(), "display_driver": DisplayServer.get_name(), "status": "passed", "checks": [], "artifacts": [], "errors": []}

static func check(result: Dictionary, name: String, ok: bool, detail: Variant = "") -> void:
	result.checks.append({"name": name, "passed": ok, "detail": detail})
	if not ok:
		result.status = "failed"

static func finish(tree: SceneTree, result: Dictionary, output: String = "", collector: ErrorCollector = null) -> void:
	if collector != null:
		OS.remove_logger(collector)
		result.errors = collector.snapshot()
		for event: Dictionary in result.errors:
			if event.type != Logger.ERROR_TYPE_WARNING:
				result.status = "failed"
	if not output.is_empty():
		var path: String = absolute(output)
		var err: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		if err == OK:
			var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(JSON.stringify(result, "\t") + "\n")
				file.flush()
				err = file.get_error()
			else:
				err = FileAccess.get_open_error()
		if err != OK:
			check(result, "write_report", false, error_string(err))
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	var status: String = result.status
	tree.quit(0 if status == "passed" else (2 if status in ["blocked", "unsupported"] else 1))

static func collect_files(directory: String, suffixes: PackedStringArray, output: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		return
	for name: String in dir.get_directories():
		if name.begins_with(".") or name in ["node_modules", "dist", "artifacts"] or dir.is_link(name):
			continue
		collect_files(directory.path_join(name), suffixes, output)
	for name: String in dir.get_files():
		if name.get_extension() in suffixes and not dir.is_link(name):
			output.append(directory.path_join(name))

static func read_result(log_text: String) -> Dictionary:
	var result: Dictionary = {}
	for line: String in log_text.split("\n"):
		var index: int = line.find("GODOT_PLUGIN_RESULT:")
		if index >= 0:
			var parsed: Variant = JSON.parse_string(line.substr(index + 20))
			if parsed is Dictionary:
				result = parsed
	return result

static func log_errors(log_text: String) -> Array[String]:
	var errors: Array[String] = []
	for line: String in log_text.split("\n"):
		var clean := line.strip_edges()
		# A result JSON can quote a negative test's error. Match actual log records.
		if clean.begins_with("ERROR:") or clean.begins_with("SCRIPT ERROR:") or clean.begins_with("SHADER ERROR:") or clean.begins_with("USER ERROR:"):
			errors.append(clean)
	return errors
