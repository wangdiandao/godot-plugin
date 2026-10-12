extends SceneTree
var checks: Array = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	output = args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
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
func _run() -> void:
	var column := VBoxContainer.new()
	column.size = Vector2(320, 180)
	root.add_child(column)
	var title := Label.new()
	title.text = "READY"
	column.add_child(title)
	var button := Button.new()
	button.text = "Start"
	button.custom_minimum_size = Vector2(200, 48)
	column.add_child(button)
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
