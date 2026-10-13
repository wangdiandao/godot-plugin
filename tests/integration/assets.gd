extends "desktop.gd"

func _run() -> void:
	result = Common.report("asset_import_recovery")
	var args := Common.arguments()
	if not args.has_all(["plugin", "out"]):
		Common.check(result, "arguments", false, "--plugin DIR --out NEW_DIR")
		Common.finish(self, result)
		return
	plugin_root = Common.absolute(str(args.plugin))
	output = Common.absolute(str(args.out))
	if DirAccess.dir_exists_absolute(output):
		Common.check(result, "fresh_output_required", false)
		Common.finish(self, result)
		return
	var project := output.path_join("资源 导入")
	DirAccess.make_dir_recursive_absolute(project)
	var config := FileAccess.open(project.path_join("project.godot"), FileAccess.WRITE)
	config.store_string('config_version=5\n[application]\nconfig/name="Import Recovery Fixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
	config.close()
	var sentinel := FileAccess.open(project.path_join("keep.txt"), FileAccess.WRITE)
	sentinel.store_string("UNRELATED_CONTENT")
	sentinel.close()
	var hash_before := FileAccess.get_sha256(project.path_join("keep.txt"))
	var checker := FileAccess.open(project.path_join("check.gd"), FileAccess.WRITE)
	checker.store_string('extends SceneTree\nfunc _initialize() -> void:\n\tvar texture := load("res://art.png") as Texture2D\n\tvar width := int(OS.get_cmdline_user_args()[0])\n\tvar ok := texture != null and texture.get_width() == width\n\tprint("GODOT_PLUGIN_RESULT:" + JSON.stringify({"status": "passed" if ok else "failed", "width": texture.get_width() if texture != null else 0}))\n\tquit(0 if ok else 1)\n')
	checker.close()
	for width: int in [32, 64]:
		var image := Image.create(width, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color.CORAL)
		Common.check(result, "write_source_" + str(width), image.save_png(project.path_join("art.png")) == OK)
		await execute("import_" + str(width), OS.get_executable_path(), ["--headless", "--path", project, "--import"])
		await execute("texture_" + str(width), OS.get_executable_path(), ["--headless", "--path", project, "--script", project.path_join("check.gd"), "--", str(width)], true)
	Common.check(result, "native_import_metadata", FileAccess.file_exists(project.path_join("art.png.import")))
	# A missing source is detected before a repair; restore this one source, never clear all caches.
	var source_path := project.path_join("art.png")
	var source_copy := FileAccess.get_file_as_bytes(source_path)
	Common.check(result, "remove_owned_source", DirAccess.remove_absolute(source_path) == OK)
	Common.check(result, "missing_source_detected", not FileAccess.file_exists(source_path))
	var restored := FileAccess.open(source_path, FileAccess.WRITE)
	restored.store_buffer(source_copy)
	restored.close()
	await execute("repair_import", OS.get_executable_path(), ["--headless", "--path", project, "--import"])
	await execute("repaired_texture", OS.get_executable_path(), ["--headless", "--path", project, "--script", project.path_join("check.gd"), "--", "64"], true)
	# Exercise real model import/reimport with owned glTF CPU geometry.
	var model_checker := FileAccess.open(project.path_join("check_model.gd"), FileAccess.WRITE)
	model_checker.store_string('extends SceneTree\nfunc _initialize() -> void:\n\tvar scene := load("res://model.gltf") as PackedScene\n\tif scene == null:\n\t\tquit(1)\n\t\treturn\n\tvar instance := scene.instantiate()\n\tvar meshes := instance.find_children("*", "MeshInstance3D", true, false)\n\tvar expected := float(OS.get_cmdline_user_args()[0])\n\tvar ok := meshes.size() == 1 and is_equal_approx(meshes[0].mesh.get_aabb().size.x, expected)\n\tprint("GODOT_PLUGIN_RESULT:" + JSON.stringify({"status": "passed" if ok else "failed", "mesh_count": meshes.size()}))\n\tinstance.free()\n\tquit(0 if ok else 1)\n')
	model_checker.close()
	for width: float in [1.0, 2.0]:
		var positions := PackedFloat32Array([0, 0, 0, width, 0, 0, 0, 1, 0]).to_byte_array()
		var model := {"asset": {"version": "2.0"}, "buffers": [{"byteLength": positions.size(), "uri": "data:application/octet-stream;base64," + Marshalls.raw_to_base64(positions)}], "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": positions.size(), "target": 34962}], "accessors": [{"bufferView": 0, "componentType": 5126, "count": 3, "type": "VEC3", "min": [0, 0, 0], "max": [width, 1, 0]}], "meshes": [{"primitives": [{"attributes": {"POSITION": 0}}]}], "nodes": [{"mesh": 0, "name": "Triangle"}], "scenes": [{"nodes": [0]}], "scene": 0}
		var model_file := FileAccess.open(project.path_join("model.gltf"), FileAccess.WRITE)
		model_file.store_string(JSON.stringify(model))
		model_file.close()
		await execute("model_import_" + str(width), OS.get_executable_path(), ["--headless", "--path", project, "--import"])
		await execute("model_dimensions_" + str(width), OS.get_executable_path(), ["--headless", "--path", project, "--script", project.path_join("check_model.gd"), "--", str(width)], true)
	Common.check(result, "model_import_metadata", FileAccess.file_exists(project.path_join("model.gltf.import")))
	Common.check(result, "unrelated_file_preserved", FileAccess.get_sha256(project.path_join("keep.txt")) == hash_before)
	Common.finish(self, result, output.path_join("report.json"))
