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
	var config := ConfigFile.new()
	config.set_value("preset.0", "name", "Windows Desktop")
	config.set_value("preset.0", "platform", "Windows Desktop")
	config.set_value("preset.0", "runnable", true)
	config.set_value("preset.0", "export_filter", "all_resources")
	config.set_value("preset.0", "include_filter", "")
	config.set_value("preset.0", "exclude_filter", ".godot-plugin/*")
	config.set_value("preset.0", "export_path", "build/game.exe")
	config.set_value("preset.0.options", "binary_format/architecture", "x86_64")
	var path := output.path_join("export_presets.cfg")
	expect(config.save(path) == OK, "preset_serialization")
	var loaded := ConfigFile.new()
	expect(loaded.load(path) == OK, "preset_readback")
	expect(loaded.get_value("preset.0", "platform") == "Windows Desktop", "preset_platform")
	# Build is conditional: ordinary configuration work needs no export templates.
	var args := OS.get_cmdline_user_args()
	var index := args.find("--templates")
	if index >= 0 and index + 1 < args.size():
		await build_and_launch(args[index + 1], config)
	finish()

func write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true

func execute(label: String, executable: String, flags: PackedStringArray, report_path: String = "") -> bool:
	var pid := OS.create_process(executable, flags, false)
	if pid <= 0:
		return false
	var deadline := Time.get_ticks_msec() + 30000
	while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	if OS.is_process_running(pid):
		OS.kill(pid)
		return false
	var text := FileAccess.get_file_as_string(output.path_join(label + ".log"))
	return OS.get_process_exit_code(pid) == 0 and not text.contains("ERROR:") and (report_path.is_empty() or FileAccess.file_exists(report_path))

func build_and_launch(templates: String, config: ConfigFile) -> void:
	if OS.get_name() != "Windows":
		expect(false, "windows_host_required_for_launch")
		return
	var template := templates.path_join("windows_release_x86_64.exe")
	if not FileAccess.file_exists(template) or FileAccess.get_file_as_string(templates.path_join("version.txt")).strip_edges() != "4.7.2.stable":
		expect(false, "matching_template_required")
		return
	var project := output.path_join("export_project")
	DirAccess.make_dir_recursive_absolute(project)
	var main := "extends Node\nfunc _ready() -> void:\n\tvar args := OS.get_cmdline_user_args()\n\tvar i := args.find(\"--out\")\n\tif i < 0 or i + 1 >= args.size():\n\t\tget_tree().quit(1)\n\t\treturn\n\tvar file := FileAccess.open(args[i + 1].path_join(\"exported-result.json\"), FileAccess.WRITE)\n\tif file == null:\n\t\tget_tree().quit(1)\n\t\treturn\n\tfile.store_string(JSON.stringify({\"status\":\"passed\",\"engine\":Engine.get_version_info(),\"editor\":OS.has_feature(\"editor\")}))\n\tfile.close()\n\tget_tree().quit(0)\n"
	expect(write_text(project.path_join("main.gd"), main), "write_export_script")
	expect(write_text(project.path_join("main.tscn"), '[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://main.gd" id="1"]\n[node name="Main" type="Node"]\nscript=ExtResource("1")\n'), "write_export_scene")
	expect(write_text(project.path_join("project.godot"), 'config_version=5\n[application]\nconfig/name="Export Recipe"\nrun/main_scene="res://main.tscn"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'), "write_export_project")
	config.set_value("preset.0", "name", "Recipe Windows")
	config.set_value("preset.0.options", "custom_template/release", template)
	config.set_value("preset.0.options", "application/modify_resources", false)
	expect(config.save(project.path_join("export_presets.cfg")) == OK, "save_build_preset")
	var imported := await execute("import", OS.get_executable_path(), ["--headless", "--path", project, "--import", "--log-file", output.path_join("import.log")])
	expect(imported, "native_import")
	if not imported:
		return
	var executable := output.path_join("recipe.exe")
	var built := await execute("export", OS.get_executable_path(), ["--headless", "--path", project, "--export-release", "Recipe Windows", executable, "--log-file", output.path_join("export.log")])
	expect(built and FileAccess.file_exists(executable) and FileAccess.file_exists(output.path_join("recipe.pck")), "executable_and_pack")
	if not built:
		return
	var report_path := output.path_join("exported-result.json")
	expect(await execute("artifact", executable, ["--headless", "--log-file", output.path_join("artifact.log"), "--", "--out", output], report_path), "exported_launch")
	if FileAccess.file_exists(report_path):
		var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(report_path))
		expect(report is Dictionary and report.get("status") == "passed" and report.get("editor") == false, "artifact_is_export_template")
