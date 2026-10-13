extends SceneTree

# Explicit workaround for the tested 4.7.2 first-scan exposed-class crash.
# Run only in a task-created copy; preserve all existing discovery entries.
func _initialize() -> void:
	var version := Engine.get_version_info()
	if not OS.get_cmdline_user_args().has("--allow-recipe-bootstrap") or ProjectSettings.get_setting("application/config/name") != "Godot Native Resource Recipe" or version.major != 4 or version.minor != 7 or version.patch != 2:
		push_error("Bootstrap requires --allow-recipe-bootstrap, the isolated recipe project, and tested Godot 4.7.2.")
		quit(1)
		return
	var manifest := "res://recipe.gdextension"
	if not FileAccess.file_exists(manifest):
		push_error("Activate the compiled extension manifest before bootstrap.")
		quit(1)
		return
	# Validate the actual library in a non-editor process before writing discovery.
	if not GDExtensionManager.is_extension_loaded(manifest):
		var loaded := GDExtensionManager.load_extension(ProjectSettings.globalize_path(manifest))
		if loaded != GDExtensionManager.LOAD_STATUS_OK and loaded != GDExtensionManager.LOAD_STATUS_ALREADY_LOADED:
			push_error("Native library did not load; preserve the discovery list and diagnose the loader first.")
			quit(1)
			return
	if not ClassDB.class_exists("NativeRecipe"):
		push_error("The loaded library did not register the recipe class.")
		quit(1)
		return
	var data_dir := "res://.godot" if ProjectSettings.get_setting("application/config/use_hidden_project_data_directory", true) else "res://godot"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(data_dir)) != OK:
		quit(1)
		return
	var path := data_dir.path_join("extension_list.cfg")
	var previous := ""
	if FileAccess.file_exists(path):
		var reader := FileAccess.open(path, FileAccess.READ)
		if reader == null:
			quit(1)
			return
		previous = reader.get_as_text()
		reader.close()
	var present := false
	for line: String in previous.split("\n"):
		present = present or line.strip_edges() == manifest
	var expected := previous
	if not present:
		var writer := FileAccess.open(path, FileAccess.WRITE)
		if writer == null:
			quit(1)
			return
		expected = previous + ("\n" if not previous.is_empty() and not previous.ends_with("\n") else "") + manifest + "\n"
		writer.store_string(expected)
		writer.flush()
		var write_error := writer.get_error()
		writer.close()
		if write_error != OK:
			quit(1)
			return
	var readback := FileAccess.open(path, FileAccess.READ)
	if readback == null:
		quit(1)
		return
	var matches := readback.get_as_text() == expected
	readback.close()
	if not matches:
		push_error("Discovery list readback differs; do not continue to import.")
		quit(1)
		return
	print("GODOT_NATIVE_BOOTSTRAP:preserved_existing_entries=" + str(present) + "; next_process_must_import_and_test")
	quit(0)
