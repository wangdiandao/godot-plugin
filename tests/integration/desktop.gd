extends SceneTree
const Common = preload("../../shared/scripts/common.gd")
var result: Dictionary
var output: String
var plugin_root: String
var templates: String
var sequence := 0

func _initialize() -> void:
	call_deferred("_run")

func copy_tree(source: String, destination: String) -> Error:
	var dir := DirAccess.open(source)
	if dir == null:
		return ERR_FILE_NOT_FOUND
	var error := DirAccess.make_dir_recursive_absolute(destination)
	if error != OK:
		return error
	for name: String in dir.get_files():
		if not dir.is_link(name):
			error = DirAccess.copy_absolute(source.path_join(name), destination.path_join(name))
			if error != OK:
				return error
	for name: String in dir.get_directories():
		if not name.begins_with(".") and not dir.is_link(name):
			error = copy_tree(source.path_join(name), destination.path_join(name))
			if error != OK:
				return error
	return OK

func execute(label: String, executable: String, flags: PackedStringArray, required_report: bool = false, timeout: int = 60, expected_error: String = "") -> Dictionary:
	sequence += 1
	var log_path := output.path_join("%02d-%s.log" % [sequence, label])
	# Engine arguments must precede user arguments after --.
	var split := flags.find("--")
	if split < 0:
		flags.append_array(["--log-file", log_path])
	else:
		flags.insert(split, log_path)
		flags.insert(split, "--log-file")
	var pid := OS.create_process(executable, flags, false)
	var deadline := Time.get_ticks_msec() + timeout * 1000
	var timed_out := false
	while pid > 0 and OS.is_process_running(pid):
		if Time.get_ticks_msec() >= deadline:
			timed_out = true
			OS.kill(pid)
			break
		await create_timer(0.05).timeout
	var log_text := FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
	var report := Common.read_result(log_text)
	var errors := Common.log_errors(log_text)
	var exit_code := OS.get_process_exit_code(pid) if pid > 0 else -1
	var passed: bool = not timed_out and exit_code == 0 and errors.is_empty() and (not required_report or report.get("status") == "passed")
	if not expected_error.is_empty():
		passed = not timed_out and exit_code != 0 and log_text.contains(expected_error)
	var detail := {"log": log_path, "exit_code": exit_code, "timed_out": timed_out, "errors": errors, "reported": report, "passed": passed}
	Common.check(result, label, passed, detail)
	return detail

func _run() -> void:
	result = Common.report("desktop_integration")
	var args := Common.arguments()
	if not args.has_all(["plugin", "templates", "out"]):
		Common.check(result, "arguments", false, "--plugin DIR --templates DIR --out NEW_DIR")
		Common.finish(self, result)
		return
	plugin_root = Common.absolute(str(args.plugin))
	templates = Common.absolute(str(args.templates))
	output = Common.absolute(str(args.out))
	if DirAccess.dir_exists_absolute(output):
		Common.check(result, "fresh_output_required", false, output)
		Common.finish(self, result)
		return
	DirAccess.make_dir_recursive_absolute(output)
	for dimension: String in ["2d", "3d"]:
		var project := output.path_join("中文 空格 " + dimension)
		var source := plugin_root.path_join("skills/godot-workflow/assets/examples/game-" + dimension)
		Common.check(result, dimension + "_clean_copy", copy_tree(source, project) == OK)
		var build := project.path_join(".godot-plugin/build")
		DirAccess.make_dir_recursive_absolute(build)
		var preset := ConfigFile.new()
		preset.set_value("preset.0", "name", "Windows Desktop")
		preset.set_value("preset.0", "platform", "Windows Desktop")
		preset.set_value("preset.0", "runnable", true)
		preset.set_value("preset.0", "export_filter", "all_resources")
		preset.set_value("preset.0", "include_filter", "")
		preset.set_value("preset.0", "exclude_filter", ".godot-plugin/*")
		preset.set_value("preset.0.options", "custom_template/release", templates.path_join("windows_release_x86_64.exe"))
		preset.set_value("preset.0.options", "custom_template/debug", templates.path_join("windows_debug_x86_64.exe"))
		preset.set_value("preset.0.options", "binary_format/architecture", "x86_64")
		preset.set_value("preset.0.options", "codesign/enable", false)
		preset.set_value("preset.0.options", "application/modify_resources", false)
		Common.check(result, dimension + "_preset_saved", preset.save(project.path_join("export_presets.cfg")) == OK)
		var imported := await execute(dimension + "_import", OS.get_executable_path(), ["--headless", "--path", project, "--import"])
		if not imported.passed:
			continue
		await execute(dimension + "_inspect", OS.get_executable_path(), ["--headless", "--path", project, "--script", plugin_root.path_join("shared/scripts/inspect_project.gd"), "--", "--report", build.path_join("inspection.json")], true)
		await execute(dimension + "_game", OS.get_executable_path(), ["--path", project, "--", "--self-test", "--out", build.path_join("source-test")], true)
		var executable := build.path_join("game.exe")
		var exported := await execute(dimension + "_export", OS.get_executable_path(), ["--headless", "--path", project, "--export-release", "Windows Desktop", executable], false, 90)
		Common.check(result, dimension + "_binary_exists", FileAccess.file_exists(executable) and FileAccess.file_exists(build.path_join("game.pck")))
		if exported.passed:
			await execute(dimension + "_exported_game", executable, ["--", "--self-test", "--out", build.path_join("export-test")], true)
		# Native Web export is tested as a build, not as browser runtime proof.
		if dimension == "2d":
			preset.set_value("preset.1", "name", "Web")
			preset.set_value("preset.1", "platform", "Web")
			preset.set_value("preset.1", "export_filter", "all_resources")
			preset.set_value("preset.1", "include_filter", "")
			preset.set_value("preset.1", "exclude_filter", ".godot-plugin/*")
			preset.set_value("preset.1.options", "custom_template/release", templates.path_join("web_nothreads_release.zip"))
			preset.set_value("preset.1.options", "variant/thread_support", false)
			preset.save(project.path_join("export_presets.cfg"))
			DirAccess.make_dir_recursive_absolute(build.path_join("web"))
			await execute("web_export", OS.get_executable_path(), ["--headless", "--path", project, "--export-release", "Web", build.path_join("web/index.html")], false, 90)
			for extension: String in ["html", "js", "wasm", "pck"]:
				Common.check(result, "web_artifact_" + extension, FileAccess.file_exists(build.path_join("web/index." + extension)))
	result.artifacts.append(output)
	Common.finish(self, result, output.path_join("report.json"))
