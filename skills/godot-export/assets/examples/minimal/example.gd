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
	# This minimal case checks configuration. Integration tests build and launch binaries.
	finish()
