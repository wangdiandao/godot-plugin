extends SceneTree
const Common = preload("common.gd")
var collector := Common.ErrorCollector.new()

func _initialize() -> void:
	OS.add_logger(collector)
	call_deferred("_run")

func _run() -> void:
	var args: Dictionary = Common.arguments()
	var result: Dictionary = Common.report("capture_scene")
	if DisplayServer.get_name() == "headless":
		result.status = "unsupported"
		result.reason = "Capture requires a real display/rendering driver; omit --headless."
		Common.finish(self, result, str(args.get("report", "")), collector)
		return
	if not args.has("scene") or not args.has("out"):
		Common.check(result, "arguments", false, "Required: --scene res://scene.tscn --out ABSOLUTE.png [--frames 5]")
		Common.finish(self, result, "", collector)
		return
	var scene: PackedScene = ResourceLoader.load(str(args.scene)) as PackedScene
	if scene == null:
		Common.check(result, "load_scene", false)
		Common.finish(self, result, "", collector)
		return
	var instance: Node = scene.instantiate()
	root.add_child(instance)
	current_scene = instance
	root.size = Vector2i(int(args.get("width", 960)), int(args.get("height", 540)))
	for frame: int in range(clampi(int(args.get("frames", 8)), 1, 600)):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	Common.check(result, "rendered_image", image != null and not image.is_empty())
	if image != null and not image.is_empty():
		var output: String = Common.absolute(str(args.out))
		DirAccess.make_dir_recursive_absolute(output.get_base_dir())
		var saved := image.save_png(output) == OK
		Common.check(result, "save_png", saved, output)
		if saved:
			var reloaded: Image = Image.load_from_file(output)
			Common.check(result, "reload_png", reloaded != null and reloaded.get_size() == image.get_size())
			result.artifacts.append(output)
	instance.queue_free()
	await process_frame
	Common.finish(self, result, str(args.get("report", "")), collector)
