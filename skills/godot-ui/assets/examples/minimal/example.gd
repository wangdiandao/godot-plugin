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

var pressed: bool = false
func _on_pressed() -> void:
	pressed = true
func click_at(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.global_position = position
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.global_position = position
	event.pressed = false
	root.push_input(event, true)
	await process_frame
func _run() -> void:
	root.size = Vector2i(320, 180)
	var column := VBoxContainer.new()
	column.name = "Menu"
	column.size = Vector2(320, 180)
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["sans-serif"])
	theme.set_font("font", "Button", font)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_color("font_color", "Button", Color(0.2, 0.8, 0.4))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.2)
	style.content_margin_left = 12.0
	theme.set_stylebox("normal", "Button", style)
	var theme_path := output.path_join("menu_theme.tres")
	expect(ResourceSaver.save(theme, theme_path) == OK, "theme_saved")
	var loaded_theme := ResourceLoader.load(theme_path, "Theme", ResourceLoader.CACHE_MODE_IGNORE) as Theme
	expect(loaded_theme != null, "theme_cache_ignored_reload")
	column.theme = loaded_theme
	root.add_child(column)
	var title := Label.new()
	title.name = "Title"
	title.text = "READY"
	column.add_child(title)
	title.owner = column
	var button := Button.new()
	button.name = "Start"
	button.text = "Start"
	button.custom_minimum_size = Vector2(200, 48)
	column.add_child(button)
	button.owner = column
	expect(button.get_theme_font("font") is SystemFont, "inherited_font")
	expect(button.get_theme_font_size("font_size") == 18, "inherited_font_size")
	expect(button.get_theme_color("font_color").is_equal_approx(Color(0.2, 0.8, 0.4)), "inherited_theme_color")
	button.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
	var packed := PackedScene.new()
	expect(packed.pack(column) == OK, "menu_packed")
	var scene_path := output.path_join("menu.tscn")
	expect(ResourceSaver.save(packed, scene_path) == OK, "menu_saved")
	var loaded := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if loaded != null:
		var restored := loaded.instantiate() as VBoxContainer
		root.add_child(restored)
		var restored_button := restored.get_node("Start") as Button
		expect(restored_button.get_theme_color("font_color").is_equal_approx(Color(0.9, 0.3, 0.2)), "saved_local_override_effective")
		restored_button.remove_theme_color_override("font_color")
		expect(not restored_button.has_theme_color_override("font_color") and restored_button.get_theme_color("font_color").is_equal_approx(Color(0.2, 0.8, 0.4)), "override_removal_restores_inheritance")
		expect(is_equal_approx((restored_button.get_theme_stylebox("normal") as StyleBoxFlat).content_margin_left, 12.0), "saved_inherited_style")
		restored.queue_free()
	else:
		expect(false, "scene_cache_ignored_reload")
	button.pressed.connect(_on_pressed)
	button.grab_focus()
	for i in range(3):
		await process_frame
	var event := InputEventAction.new()
	event.action = "ui_accept"
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = "ui_accept"
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	expect(pressed, "focused_button_input_dispatch")
	expect(button.position.y >= title.size.y, "container_layout")
	var overlay := ColorRect.new()
	overlay.size = Vector2(320, 180)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)
	if DisplayServer.get_name() == "headless":
		root.notify_mouse_entered()
	pressed = false
	await click_at(button.get_global_rect().get_center())
	expect(not pressed, "overlay_stop_blocks_pointer_activation")
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await click_at(button.get_global_rect().get_center())
	expect(pressed, "overlay_ignore_repairs_pointer_activation")
	for cycle in range(2):
		pressed = false
		await click_at(button.get_global_rect().get_center())
		expect(pressed, "repaired_pointer_activation_repeats_" + str(cycle))
	expect(button.get_theme_color("font_color").is_equal_approx(Color(0.9, 0.3, 0.2)) and overlay.size == Vector2(320, 180), "pointer_repair_preserves_style_and_geometry")
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pressed = false
	await click_at(button.get_global_rect().get_center())
	expect(not pressed, "intentional_modal_blocking_remains_available")
	overlay.queue_free()
	var translation := Translation.new()
	translation.locale = "zh_CN"
	translation.add_message("READY", "\u51c6\u5907\u5b8c\u6210")
	TranslationServer.add_translation(translation)
	TranslationServer.set_locale("zh_CN")
	expect(TranslationServer.translate("READY") == "\u51c6\u5907\u5b8c\u6210", "translation_lookup")
	TranslationServer.remove_translation(translation)
	column.queue_free()
	await process_frame
	finish()
