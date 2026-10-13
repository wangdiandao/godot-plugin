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
	expect(ClassDB.class_exists("TileMapLayer"), "tilemaplayer_available")
	expect(ClassDB.class_has_method("ResourceSaver", "save"), "resource_save_is_public")
	expect(ClassDB.class_has_method("NavigationServer3D", "bake_from_source_geometry_data"), "navigation_bake_is_public")
	expect(not ClassDB.class_has_method("LightmapGI", "bake"), "lightmap_bake_not_bound_in_baseline")
	var file := FileAccess.open(output.path_join("api.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(ClassDB.class_get_method_list("PackedScene"), "	"))
	file.close()
	var parent := Node.new()
	parent.name = "Contract"
	var saved := Node.new()
	saved.name = "Owned"
	parent.add_child(saved)
	saved.owner = parent
	var omitted := Node.new()
	omitted.name = "Unowned"
	parent.add_child(omitted)
	var packed := PackedScene.new()
	expect(packed.pack(parent) == OK, "pack_invocation")
	var scene_path := output.path_join("contract.tscn")
	expect(ResourceSaver.save(packed, scene_path) == OK, "save_invocation")
	var loaded := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	expect(loaded != null and loaded.get_state().get_node_count() == 2, "api_saved_behavior")
	if loaded != null:
		var instance := loaded.instantiate()
		expect(instance.has_node("Owned") and not instance.has_node("Unowned"), "api_ownership_failure_condition")
		instance.free()
	parent.free()
	finish()
