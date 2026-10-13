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
	var parent := Node2D.new()
	parent.name = "Root"
	var button := Button.new()
	button.name = "Hide"
	parent.add_child(button)
	button.owner = parent
	button.pressed.connect(parent.hide, CONNECT_PERSIST)
	var transient := Node.new()
	transient.name = "PreviewOnly"
	parent.add_child(transient)
	var packed := PackedScene.new()
	expect(packed.pack(parent) == OK, "pack_owned_nodes")
	var path := output.path_join("saved.tscn")
	expect(ResourceSaver.save(packed, path) == OK, "save_scene")
	parent.free()
	var loaded := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if loaded != null:
		expect(loaded.get_state().get_node_count() == 2, "owned_child_survives")
		expect(loaded.get_state().get_connection_count() == 1, "persistent_connection_survives")
		var instance := loaded.instantiate() as Node2D
		expect(not instance.has_node("PreviewOnly"), "unowned_child_excluded")
		(instance.get_node("Hide") as Button).pressed.emit()
		expect(not instance.visible, "reloaded_connection_executes")
		instance.free()
	else:
		expect(false, "scene_load")
	finish()
