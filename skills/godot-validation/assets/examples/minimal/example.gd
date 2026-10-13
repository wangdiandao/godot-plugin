extends SceneTree
var checks: Array = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	output = args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
	output = output.replace("\\", "/")
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

func _run() -> void:
	# Deliberately broken children live only in the output fixture directory.
	var fixtures := output.path_join("fixtures")
	if DirAccess.make_dir_recursive_absolute(fixtures) != OK:
		expect(false, "fixture_directory")
		finish()
		return
	var cases := [
		{"id": "parse", "body": "extends SceneTree\nfunc _initialize() -> void:\n\tvar broken =\n", "match": "Parse Error", "timeout": false},
		{"id": "missing", "body": "extends SceneTree\nfunc _initialize() -> void:\n\tResourceLoader.load(\"res://missing-validation-resource-7.tres\")\n\tquit(0)\n", "match": "missing-validation-resource-7.tres", "timeout": false},
		{"id": "runtime", "body": "extends SceneTree\nfunc _initialize() -> void:\n\tcall_deferred(\"fail\")\nfunc fail() -> void:\n\tvar values: Array = []\n\tprint(values[3])\n", "match": "out of bounds", "timeout": true},
		{"id": "logged", "body": "extends SceneTree\nfunc _initialize() -> void:\n\tpush_error(\"EXPECTED_LOGGED_FAILURE_7\")\n\tquit(0)\n", "match": "EXPECTED_LOGGED_FAILURE_7", "timeout": false},
		{"id": "timeout", "body": "extends SceneTree\n", "match": "", "timeout": true},
		{"id": "unrelated", "body": "extends SceneTree\nfunc _initialize() -> void:\n\tpush_error(\"UNRELATED_FAULT_7\")\n\tquit(1)\n", "match": "EXPECTED_LOGGED_FAILURE_7", "timeout": false},
		{"id": "missing_report", "body": "extends SceneTree\nfunc _initialize() -> void:\n\tquit(0)\n", "match": "", "timeout": false}
	]
	for case: Dictionary in cases:
		var path := fixtures.path_join(str(case.id) + ".gd")
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			expect(false, "fixture_write_" + str(case.id))
			continue
		file.store_string(str(case.body))
		file.close()
		var log_path := output.path_join(str(case.id) + ".log")
		var flags: PackedStringArray = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", path, "--log-file", log_path]
		if case.id == "parse":
			flags.append("--check-only")
		var pid := OS.create_process(OS.get_executable_path(), flags, false)
		if pid <= 0:
			expect(false, "launch_" + str(case.id))
			continue
		var deadline := Time.get_ticks_msec() + 2500
		while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
			await create_timer(0.02).timeout
		var timed_out := OS.is_process_running(pid)
		if timed_out:
			OS.kill(pid)
			await create_timer(0.1).timeout
		var exit_code := OS.get_process_exit_code(pid)
		var text := FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
		var has_error := text.contains("ERROR:") or text.contains("SCRIPT ERROR:")
		var failed := timed_out or exit_code != 0 or has_error
		var intended := failed and not str(case.match).is_empty() and text.to_lower().contains(str(case.match).to_lower())
		if case.id == "unrelated":
			expect(failed and not intended and text.contains("UNRELATED_FAULT_7"), "reject_unrelated_failure")
		elif case.id == "missing_report":
			expect(not timed_out and exit_code == 0 and not has_error and not text.contains("GODOT_PLUGIN_RESULT:"), "missing_report_is_not_success")
		elif case.id == "timeout":
			expect(timed_out, "timeout_detected")
		else:
			expect(intended and timed_out == bool(case.timeout), "detect_" + str(case.id))
		checks.append({"name": "observation_" + str(case.id), "status": "passed", "exit_code": exit_code, "timed_out": timed_out, "error_match": intended, "log": log_path})
	finish()
