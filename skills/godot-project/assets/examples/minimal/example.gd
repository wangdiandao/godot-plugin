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
	var action := InputEventKey.new()
	action.physical_keycode = KEY_SPACE
	var config := ConfigFile.new()
	config.set_value("", "config_version", 5)
	config.set_value("application", "config/name", "Generated Project")
	config.set_value("application", "run/main_scene", "res://main.tscn")
	config.set_value("rendering", "renderer/rendering_method", "gl_compatibility")
	config.set_value("input", "jump", {"deadzone": 0.2, "events": [action]})
	config.set_value("autoload", "Session", "*res://session.gd")
	var path := output.path_join("project.godot")
	expect(config.save(path) == OK, "save_project_configuration")
	var loaded := ConfigFile.new()
	expect(loaded.load(path) == OK, "reload_configuration")
	var saved_action: Dictionary = loaded.get_value("input", "jump")
	expect(saved_action.events[0].physical_keycode == KEY_SPACE, "input_event_roundtrip")
	InputMap.add_action("example_jump")
	InputMap.action_add_event("example_jump", action)
	expect(InputMap.action_has_event("example_jump", action), "runtime_input_map")
	InputMap.erase_action("example_jump")
	var session_file := FileAccess.open(output.path_join("session.gd"), FileAccess.WRITE)
	session_file.store_string("extends Node\nvar initialized: bool = false\nfunc _ready() -> void:\n\tinitialized = true\n")
	session_file.close()
	var main_script := FileAccess.open(output.path_join("main.gd"), FileAccess.WRITE)
	main_script.store_string("extends Node\nfunc _ready() -> void:\n\tvar session := get_node_or_null(\"/root/Session\")\n\tvar ok: bool = session != null and session.initialized and InputMap.has_action(\"jump\") and not InputMap.has_action(\"example_jump\")\n\tvar file := FileAccess.open(\"res://bootstrap.json\", FileAccess.WRITE)\n\tfile.store_string(JSON.stringify({\"passed\": ok, \"autoload_ready\": session != null and session.initialized}))\n\tfile.close()\n\tget_tree().quit(0 if ok else 1)\n")
	main_script.close()
	var scene_file := FileAccess.open(output.path_join("main.tscn"), FileAccess.WRITE)
	scene_file.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://main.gd" id="1"]\n[node name="Main" type="Node"]\nscript = ExtResource("1")\n')
	scene_file.close()
	var captured: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", output, "--quit-after", "20", "--log-file", output.path_join("bootstrap-engine.log")], captured, true)
	expect(code == 0, "generated_project_launch")
	var bootstrap: Variant = JSON.parse_string(FileAccess.get_file_as_string(output.path_join("bootstrap.json")))
	expect(bootstrap is Dictionary and bootstrap.get("passed", false), "autoload_and_persistent_input_live")
	expect(not InputMap.has_action("example_jump"), "runtime_probe_action_removed")
	finish()
