extends SceneTree
const Common = preload("common.gd")
var collector := Common.ErrorCollector.new()

func _initialize() -> void:
	OS.add_logger(collector)
	call_deferred("_run")

func _run() -> void:
	var args: Dictionary = Common.arguments()
	var result: Dictionary = Common.report("inspect_project")
	var root_path: String = ProjectSettings.globalize_path("res://")
	Common.check(result, "project_exists", FileAccess.file_exists("res://project.godot"), root_path)
	Common.check(result, "arguments", not args.has("_error"), args.get("_error", ""))
	result.resources = []
	var files: Array[String] = []
	Common.collect_files("res://", ["tscn", "tres", "scn", "res", "gd"], files)
	files.sort()
	for path: String in files:
		var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		Common.check(result, "load:" + path, resource != null)
		if resource == null:
			continue
		var entry: Dictionary = {"path": path, "type": resource.get_class(), "dependencies": Array(ResourceLoader.get_dependencies(path))}
		if resource is PackedScene:
			var state: SceneState = resource.get_state()
			entry.nodes = []
			entry.connections = state.get_connection_count()
			for index: int in range(state.get_node_count()):
				entry.nodes.append({"path": str(state.get_node_path(index)), "type": str(state.get_node_type(index)), "properties": state.get_node_property_count(index)})
		result.resources.append(entry)
	Common.finish(self, result, str(args.get("report", "")), collector)
