extends SceneTree
var checks: Array[Dictionary] = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--out")
	if index < 0 or index + 1 >= args.size():
		push_error("OUTPUT_ARGUMENT_REQUIRED")
		quit(1)
		return
	output = args[index + 1].replace("\\", "/").simplify_path()
	if not output.is_absolute_path() or DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("OUTPUT_DIRECTORY_FAILED")
		quit(1)
		return
	call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks.append({"name": label, "status": "passed" if value else "failed"})
func finish() -> void:
	var passed := not checks.is_empty()
	for item: Dictionary in checks:
		passed = passed and item.status == "passed"
	var report := {"schema_version": 1, "status": "passed" if passed else "failed", "engine": Engine.get_version_info(), "platform": OS.get_name(), "display": DisplayServer.get_name(), "checks": checks, "artifacts": [output]}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		push_error("REPORT_WRITE_FAILED")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(report))
	quit(0 if passed else 1)


func capture(name: String) -> Image:
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	expect(image.save_png(output.path_join(name + ".png")) == OK, "capture_" + name)
	return image
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print('GODOT_PLUGIN_RESULT:{"status":"unsupported","reason":"real_rendering_required"}')
		quit(2)
		return
	root.size = Vector2i(320, 180)
	root.gui_embed_subwindows = true
	var rect := ColorRect.new()
	rect.size = Vector2(320, 180)
	var shader := load("res://portal.gdshader") as Shader
	var material := ShaderMaterial.new()
	material.shader = shader
	rect.material = material
	root.add_child(rect)
	material.set_shader_parameter("stage", 0)
	var image := await capture("distance")
	expect(image.get_pixel(160, 90).r < image.get_pixel(10, 10).r, "distance_stage_center_to_edge")
	material.set_shader_parameter("stage", 1)
	image = await capture("mask")
	expect(image.get_pixel(160, 90).r > 0.9 and image.get_pixel(10, 10).r < 0.1, "mask_stage_inside_outside")
	material.set_shader_parameter("stage", 2)
	material.set_shader_parameter("phase", 0.0)
	image = await capture("portal")
	var original := image.get_pixel(160, 90)
	material.set_shader_parameter("phase", 1.0)
	image = await capture("portal_modified")
	expect(absf(original.r - image.get_pixel(160, 90).r) > 0.05, "phase_changes_actual_portal_pixels")
	var save_path := output.path_join("portal_material.tres")
	expect(ResourceSaver.save(material, save_path) == OK, "portal_material_saved")
	var restored := ResourceLoader.load(save_path, "ShaderMaterial", ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	expect(restored != null and restored.get_shader_parameter("stage") == 2, "portal_material_uncached_readback")
	var popup := PopupPanel.new()
	popup.borderless = true
	popup.size = Vector2i(80, 60)
	popup.position = Vector2i(120, 60)
	var swatch := ColorRect.new()
	swatch.color = Color.RED
	swatch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.add_child(swatch)
	root.add_child(popup)
	popup.popup()
	var post := CanvasLayer.new()
	post.layer = 100
	root.add_child(post)
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	post.add_child(copy)
	var filter := ColorRect.new()
	filter.size = Vector2(320, 180)
	filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint := ShaderMaterial.new()
	tint.shader = load("res://post.gdshader") as Shader
	filter.material = tint
	post.add_child(filter)
	image = await capture("popup_excluded")
	expect(image.get_pixel(160, 90).r > 0.9, "negative_control_low_layer_misses_popup")
	post.layer = 1025
	image = await capture("popup_processed")
	var processed := image.get_pixel(160, 90)
	expect(processed.r < 0.05 and processed.g > 0.9 and processed.b > 0.9, "high_layer_processes_embedded_popup")
	popup.hide()
	image = await capture("popup_closed")
	expect(absf(image.get_pixel(160, 90).r - processed.r) > 0.1, "popup_close_restores_underlying_content")
	popup.free()
	post.free()
	rect.free()
	await process_frame
	finish()
