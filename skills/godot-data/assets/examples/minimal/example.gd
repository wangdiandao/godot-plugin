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

func migrate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var version: int = int(value.get("version", 1))
	if version == 1 and value.get("score") is float or version == 1 and value.get("score") is int:
		return {"version": 2, "progress": {"score": int(value.score)}}
	if version == 2 and value.get("progress") is Dictionary:
		return value
	return {}
func _run() -> void:
	var path := output.path_join("save.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "score": 7}))
	file.close()
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var current := migrate(loaded)
	expect(current.get("progress", {}).get("score") == 7, "save_version_migration")
	expect(migrate({"version": 99}).is_empty(), "future_version_rejected")
	expect(migrate([1, 2]).is_empty(), "invalid_shape_rejected")
	var parser := JSON.new()
	expect(parser.parse("{broken") != OK, "corruption_detected")
	finish()
