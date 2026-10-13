@tool
extends Node
var checks: Array = []
func _ready() -> void:
	call_deferred("_run")
func check(value: bool, label: String) -> void:
	checks.append({"name": label, "status": "passed" if value else "failed"})
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	var output := args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
	output = output.replace("\\", "/")
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		get_tree().quit(1)
		return
	if not Engine.is_editor_hint():
		print("GODOT_PLUGIN_RESULT:" + JSON.stringify({"status": "blocked", "reason": "editor_mode_required"}))
		get_tree().quit(2)
		return
	# Wait for initial editor scanning rather than assuming a fixed sleep proves readiness.
	var fs := EditorInterface.get_resource_filesystem()
	var deadline := Time.get_ticks_msec() + 15000
	while fs.is_scanning() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(not fs.is_scanning(), "editor_scan_complete")
	EditorInterface.open_scene_from_path("res://fixture.tscn")
	deadline = Time.get_ticks_msec() + 5000
	while (EditorInterface.get_edited_scene_root() == null or EditorInterface.get_edited_scene_root().scene_file_path != "res://fixture.tscn") and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var scene := EditorInterface.get_edited_scene_root()
	if scene == null or scene.scene_file_path != "res://fixture.tscn":
		push_error("EDITED_SCENE_MISSING")
		get_tree().quit(1)
		return
	EditorInterface.set_plugin_enabled("recipe", false)
	await get_tree().process_frame
	for cycle in range(2):
		EditorInterface.set_plugin_enabled("recipe", true)
		await get_tree().process_frame
		var plugins := get_tree().get_nodes_in_group("recipe_editor_plugin")
		check(plugins.size() == 1, "one_plugin_" + str(cycle))
		if plugins.size() != 1:
			break
		var plugin: EditorPlugin = plugins[0]
		var dock: EditorDock = plugin.get("dock")
		check(is_instance_valid(dock), "registered_dock_" + str(cycle))
		if cycle == 0:
			plugin.call("add_marker", scene)
			check(scene.has_node("RecipeMarker") and scene.get_node("RecipeMarker").owner == scene, "do_and_owner")
			var manager := plugin.get_undo_redo()
			var history := manager.get_history_undo_redo(manager.get_object_history_id(scene))
			check(history.undo() and not scene.has_node("RecipeMarker"), "undo")
			check(history.redo() and scene.has_node("RecipeMarker"), "redo")
			EditorInterface.save_scene_as("res://saved_recipe.tscn", false)
			var saved := ResourceLoader.load("res://saved_recipe.tscn", "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
			var readback := saved.instantiate() if saved != null else null
			check(readback != null and readback.has_node("RecipeMarker"), "saved_readback")
			if readback != null:
				readback.free()
		EditorInterface.set_plugin_enabled("recipe", false)
		deadline = Time.get_ticks_msec() + 2000
		while (not get_tree().get_nodes_in_group("recipe_editor_plugin").is_empty() or is_instance_valid(dock)) and Time.get_ticks_msec() < deadline:
			await get_tree().create_timer(0.02).timeout
		check(get_tree().get_nodes_in_group("recipe_editor_plugin").is_empty() and not is_instance_valid(dock), "disable_cleanup_" + str(cycle))
	var ok := not checks.is_empty()
	for item: Dictionary in checks:
		ok = ok and item.status == "passed"
	var result := {"schema_version": 1, "status": "passed" if ok else "failed", "engine": Engine.get_version_info(), "checks": checks, "visual_ux": "untested"}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	get_tree().quit(0 if ok else 1)
