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
	if DisplayServer.get_name() == "headless":
		print('GODOT_PLUGIN_RESULT:{"status":"unsupported","reason":"real_rendering_required"}')
		quit(2)
		return
	root.size = Vector2i(320, 180)
	var rect := ColorRect.new()
	rect.size = Vector2(320, 180)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform vec4 tint : source_color = vec4(1.0); void fragment() { COLOR = tint; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint", Color(0.2, 0.6, 0.9))
	var material_path := output.path_join("canvas_material.tres")
	expect(ResourceSaver.save(material, material_path) == OK, "shader_material_saved")
	var restored := ResourceLoader.load(material_path, "ShaderMaterial", ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	expect(restored != null and (restored.get_shader_parameter("tint") as Color).is_equal_approx(Color(0.2, 0.6, 0.9)), "shader_uniform_saved_readback")
	if restored == null:
		finish()
		return
	rect.material = restored
	root.add_child(rect)
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var pixel := picture.get_pixel(160, 90)
	expect(absf(pixel.r - 0.2) < 0.02 and absf(pixel.g - 0.6) < 0.02 and absf(pixel.b - 0.9) < 0.02, "shader_pixel_matches")
	expect(picture.save_png(output.path_join("shader.png")) == OK, "gpu_readback_png")
	var instance_material := restored.duplicate() as ShaderMaterial
	instance_material.set_shader_parameter("tint", Color(0.8, 0.2, 0.1))
	expect((restored.get_shader_parameter("tint") as Color).is_equal_approx(Color(0.2, 0.6, 0.9)), "local_material_change_preserves_shared_original")
	rect.material = instance_material
	await process_frame
	await RenderingServer.frame_post_draw
	picture = root.get_texture().get_image()
	pixel = picture.get_pixel(160, 90)
	expect(absf(pixel.r - 0.8) < 0.02 and absf(pixel.g - 0.2) < 0.02 and absf(pixel.b - 0.1) < 0.02, "modified_uniform_changes_actual_pixels")
	expect(picture.save_png(output.path_join("modified_shader.png")) == OK, "modified_gpu_readback_png")
	rect.queue_free()
	await process_frame
	finish()
