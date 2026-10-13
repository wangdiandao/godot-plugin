extends SceneTree
var observed: Array = []
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	var output := args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
	output = output.replace("\\", "/")
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		quit(1)
		return
	var checks: Array = []
	var available := ClassDB.class_exists("NativeRecipe")
	if available:
		var value: Resource = ClassDB.instantiate("NativeRecipe")
		value.connect("score_changed", func(score: int): observed.append(score))
		checks.append({"name": "native_method", "status": "passed" if value.call("add", 12) == 12 else "failed"})
		value.call("add", 2147483647)
		value.set("score", -4)
		checks.append({"name": "signal_and_bounds", "status": "passed" if observed == [12, 100, 0] else "failed"})
		for boundary: Array in [[2147483648, 100], [4294967296, 100], [9223372036854775807, 100], [-2147483649, 0], [-9223372036854775807 - 1, 0]]:
			value.set("score", 50)
			checks.append({"name": "wide_add_" + str(boundary[0]), "status": "passed" if value.call("add", boundary[0]) == boundary[1] and value.get("score") == boundary[1] else "failed"})
		for boundary: Array in [[4294967296, 100], [9223372036854775807, 100], [-2147483649, 0], [-9223372036854775807 - 1, 0]]:
			value.set("score", boundary[0])
			checks.append({"name": "wide_set_" + str(boundary[0]), "status": "passed" if value.get("score") == boundary[1] else "failed"})
		value.set("score", 42)
		var path := output.path_join("native.tres")
		checks.append({"name": "save", "status": "passed" if ResourceSaver.save(value, path) == OK else "failed"})
		var reloaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		checks.append({"name": "uncached_readback", "status": "passed" if reloaded != null and reloaded != value and reloaded.get("score") == 42 else "failed"})
	else:
		checks.append({"name": "compiled_library_required", "status": "unavailable"})
	var ok := available
	for item: Dictionary in checks:
		ok = ok and item.status == "passed"
	var result := {"schema_version": 1, "status": "passed" if ok else ("blocked" if not available else "failed"), "engine": Engine.get_version_info(), "checks": checks}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	quit(0 if ok else (2 if not available else 1))
