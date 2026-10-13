extends SceneTree
var checks: Array = []
var observed: Array = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	output = args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
	output = output.replace("\\", "/")
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		quit(1)
		return
	call_deferred("_run")
func check(value: bool, label: String) -> void:
	checks.append({"name": label, "status": "passed" if value else "failed"})
func done(status: String, code: int) -> void:
	var result := {"schema_version": 1, "status": status, "engine": Engine.get_version_info(), "checks": checks}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	quit(code)
func _run() -> void:
	if not ClassDB.class_exists("CSharpScript"):
		checks.append({"name": "dotnet_engine_required", "status": "unavailable"})
		done("blocked", 2)
		return
	var script := load("res://ExampleResource.cs") as Script
	if script == null or not script.can_instantiate():
		check(false, "managed_build_required")
		done("failed", 1)
		return
	var resource: Resource = script.new()
	resource.connect("ScoreChanged", func(value: int): observed.append(value))
	check(resource.call("Add", 12) == 12, "managed_method")
	check(resource.call("Add", 2147483647) == 100, "upper_bound_without_overflow")
	resource.set("Score", -4)
	check(resource.get("Score") == 0 and observed == [12, 100, 0], "generated_signal_and_bounds")
	for boundary: Array in [[2147483648, 100], [4294967296, 100], [9223372036854775807, 100], [-2147483649, 0], [-9223372036854775807 - 1, 0]]:
		resource.set("Score", 50)
		check(resource.call("Add", boundary[0]) == boundary[1] and resource.get("Score") == boundary[1], "wide_add_" + str(boundary[0]))
	for boundary: Array in [[4294967296, 100], [9223372036854775807, 100], [-2147483649, 0], [-9223372036854775807 - 1, 0]]:
		resource.set("Score", boundary[0])
		check(resource.get("Score") == boundary[1], "wide_set_" + str(boundary[0]))
	resource.set("Score", 42)
	var path := output.path_join("managed.tres")
	check(ResourceSaver.save(resource, path) == OK, "save")
	var restored := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	check(restored != null and restored.get("Score") == 42 and restored != resource, "uncached_readback")
	var ok := true
	for item: Dictionary in checks:
		ok = ok and item.status == "passed"
	done("passed" if ok else "failed", 0 if ok else 1)
