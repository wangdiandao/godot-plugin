extends Control
const SAVE_PATH := "user://native_web_acceptance.cfg"
var count := 0
var restored_count := 0
var saves := 0
var failure := ""
var summary: Label
var startup_usec: int

func _ready() -> void:
	startup_usec = Time.get_ticks_usec()
	var save := ConfigFile.new()
	var error := save.load(SAVE_PATH)
	if error == OK:
		var stored: Variant = save.get_value("acceptance", "count", null)
		if stored is int and stored >= 0 and stored <= 1000000:
			count = stored
			restored_count = count
		else:
			failure = "invalid_saved_count"
	elif error != ERR_FILE_NOT_FOUND:
		failure = "save_load_failed:" + error_string(error)
	var column := VBoxContainer.new()
	column.position = Vector2(40, 32)
	column.size = Vector2(560, 296)
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	var title := Label.new()
	title.text = "Native Web acceptance"
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	summary = Label.new()
	column.add_child(summary)
	var button := Button.new()
	button.text = "Collect and save"
	button.custom_minimum_size = Vector2(260, 56)
	button.pressed.connect(collect)
	column.add_child(button)
	button.grab_focus()
	var help := Label.new()
	help.text = "Click or press Enter. Reload to verify the saved count."
	column.add_child(help)
	refresh()

func collect() -> void:
	if not failure.is_empty():
		return
	if count >= 1000000:
		failure = "count_limit_reached"
		refresh()
		return
	var candidate := count + 1
	var save := ConfigFile.new()
	save.set_value("acceptance", "count", candidate)
	var error := save.save(SAVE_PATH)
	var readback := ConfigFile.new()
	if error == OK and readback.load(SAVE_PATH) == OK and readback.get_value("acceptance", "count", -1) == candidate:
		count = candidate
		saves += 1
	else:
		failure = "save_readback_failed:" + error_string(error)
	refresh()

func refresh() -> void:
	var report := {"ready": true, "count": count, "restored_count": restored_count, "saves_this_session": saves, "persistent_storage_available": OS.is_userfs_persistent(), "error": failure, "engine": Engine.get_version_info().string, "platform": OS.get_name(), "ready_since_start_usec": Time.get_ticks_usec() - startup_usec}
	summary.text = "Count: %d | Restored: %d | Saves: %d\nPersistence available: %s\n%s" % [count, restored_count, saves, str(report.persistent_storage_available), "OK" if failure.is_empty() else failure]
	if OS.has_feature("web"):
		# Publish only this fixture's results. JSON encoding keeps data out of code.
		JavaScriptBridge.eval("window.godotAcceptance = " + JSON.stringify(report) + ";", true)
	print("GODOT_WEB_ACCEPTANCE:" + JSON.stringify(report))
