extends SceneTree
const Common = preload("common.gd")

func _initialize() -> void:
	var args: Dictionary = Common.arguments()
	var result: Dictionary = Common.report("inspect_environment")
	result.executable = OS.get_executable_path()
	result.project = ProjectSettings.globalize_path("res://")
	result.editor_mode = Engine.is_editor_hint()
	result.user_data = OS.get_user_data_dir()
	Common.check(result, "arguments", not args.has("_error"), args.get("_error", ""))
	var probes: Dictionary = {"LightmapGI": ["bake"], "VoxelGI": ["bake"], "TileMapLayer": ["set_cell", "set_cells_terrain_connect"], "NavigationServer3D": ["parse_source_geometry_data", "bake_from_source_geometry_data"], "EditorFileSystem": ["reimport_files"], "OS": ["get_process_exit_code", "add_logger"]}
	result.api = {}
	for class_name_key: String in probes:
		var entry: Dictionary = {"exists": ClassDB.class_exists(class_name_key), "methods": {}}
		for method: String in probes[class_name_key]:
			entry.methods[method] = ClassDB.class_has_method(class_name_key, method)
		result.api[class_name_key] = entry
	if args.has("class"):
		var target: String = str(args["class"])
		if ClassDB.class_exists(target):
			result.selected_class = {"name": target, "methods": ClassDB.class_get_method_list(target), "properties": ClassDB.class_get_property_list(target), "signals": ClassDB.class_get_signal_list(target)}
		else:
			result.status = "unsupported"
			result.reason = "Class is not registered in this binary: " + target
	Common.finish(self, result, str(args.get("report", "")))
