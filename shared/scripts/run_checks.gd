extends SceneTree
const Common = preload("common.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: Dictionary = Common.arguments()
	var result: Dictionary = Common.report("run_checks")
	if args.has("_error") or not args.has("manifest"):
		Common.check(result, "arguments", false, "Required: --manifest PATH [--out DIR] [--case ID,ID]")
		Common.finish(self, result)
		return
	var manifest_path: String = Common.absolute(str(args.manifest))
	if not FileAccess.file_exists(manifest_path):
		Common.check(result, "manifest_exists", false, manifest_path)
		Common.finish(self, result)
		return
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary or not manifest.get("cases", null) is Array:
		Common.check(result, "manifest_schema", false)
		Common.finish(self, result)
		return
	var base: String = manifest_path.get_base_dir()
	var output: String = Common.absolute(str(args.get("out", ".godot-plugin/checks")))
	var run_dir: String = output.path_join(str(Time.get_unix_time_from_system()).replace(".", "-") + "-" + str(OS.get_process_id()))
	if DirAccess.make_dir_recursive_absolute(run_dir) != OK:
		Common.check(result, "output_directory", false, run_dir)
		Common.finish(self, result)
		return
	var selected: PackedStringArray = str(args.get("case", "")).split(",", false)
	var count: int = 0
	var seen: Array[String] = []
	for case_value: Variant in manifest.cases:
		if not case_value is Dictionary:
			Common.check(result, "case_schema", false)
			continue
		var item: Dictionary = case_value
		var case_id: String = str(item.get("id", ""))
		if not selected.is_empty() and case_id not in selected:
			continue
		count += 1
		if case_id in seen:
			Common.check(result, "unique_case_id", false, case_id)
			continue
		seen.append(case_id)
		if not case_id.is_valid_filename() or case_id.is_empty():
			Common.check(result, "case_id", false, case_id)
			continue
		var case_dir: String = run_dir.path_join(case_id)
		DirAccess.make_dir_recursive_absolute(case_dir)
		var log_path: String = case_dir.path_join("engine.log")
		var project_path := Common.absolute(str(item.get("project", ".")), base)
		if item.get("copy_project", false):
			var isolated_project := case_dir.path_join("project")
			var copy_error := copy_project(project_path, isolated_project)
			Common.check(result, case_id + ":isolated_project", copy_error == OK, copy_error)
			if copy_error != OK:
				continue
			project_path = isolated_project
		var child_args: PackedStringArray = ["--path", project_path, "--log-file", log_path]
		if item.get("headless", true):
			child_args.append("--headless")
		for flag: Variant in item.get("engine_args", []):
			child_args.append(str(flag).replace("{output}", case_dir))
		if item.has("script"):
			child_args.append_array(["--script", Common.absolute(str(item.script), base)])
		if item.has("args"):
			child_args.append("--")
			for value: Variant in item.args:
				child_args.append(str(value).replace("{output}", case_dir))
		var pid: int = OS.create_process(OS.get_executable_path(), child_args, false)
		var timed_out: bool = false
		var deadline: int = Time.get_ticks_msec() + int(float(item.get("timeout", 30)) * 1000)
		while pid > 0 and OS.is_process_running(pid):
			if Time.get_ticks_msec() >= deadline:
				timed_out = true
				OS.kill(pid)
				var kill_deadline := Time.get_ticks_msec() + 2000
				while OS.is_process_running(pid) and Time.get_ticks_msec() < kill_deadline:
					await create_timer(0.02).timeout
				break
			await create_timer(0.05).timeout
		var exit_code: int = OS.get_process_exit_code(pid) if pid > 0 else -1
		var log_text: String = FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
		var reported: Dictionary = Common.read_result(log_text)
		var errors: Array[String] = Common.log_errors(log_text)
		var actual: String = "failed"
		if timed_out:
			actual = "timeout"
		elif exit_code == 0 and errors.is_empty() and (reported.get("status") == "passed" or not item.get("require_report", true)):
			actual = "passed"
		elif exit_code == 2 and errors.is_empty() and reported.get("status") in ["blocked", "unsupported"]:
			actual = reported.status
		var expected: String = str(item.get("expect", "passed"))
		var matched: bool = actual == expected
		# A negative case must prove the intended failure, not an unrelated startup error.
		if expected == "failed":
			matched = matched and item.has("error_contains") and log_text.contains(str(item.error_contains))
		if item.has("contains"):
			matched = matched and log_text.contains(str(item.contains))
		if item.has("reported_status"):
			matched = matched and reported.get("status") == item.reported_status
		Common.check(result, case_id, matched, {"actual": actual, "expected": expected, "exit_code": exit_code, "timed_out": timed_out, "log": log_path, "errors": errors, "reported": reported})
	Common.check(result, "selected_cases_exist", count > 0)
	for requested: String in selected:
		Common.check(result, "selected:" + requested, requested in seen)
	result.artifacts.append(run_dir)
	Common.finish(self, result, run_dir.path_join("report.json"))

func copy_project(source: String, destination: String) -> Error:
	var directory := DirAccess.open(source)
	if directory == null:
		return ERR_FILE_NOT_FOUND
	var error := DirAccess.make_dir_recursive_absolute(destination)
	if error != OK:
		return error
	for name: String in directory.get_files():
		if directory.is_link(name):
			continue
		error = DirAccess.copy_absolute(source.path_join(name), destination.path_join(name))
		if error != OK:
			return error
	for name: String in directory.get_directories():
		if name in [".godot", ".godot-plugin", ".git", "bin", "obj", "build"] or directory.is_link(name):
			continue
		error = copy_project(source.path_join(name), destination.path_join(name))
		if error != OK:
			return error
	return OK
