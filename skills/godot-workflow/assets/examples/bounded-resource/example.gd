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

const Module = preload("module.gd")
func _run() -> void:
	var module = Module.new()
	root.add_child(module)
	module.reset()
	expect(module.charges == 2 and module.hud.text == "Charges: 2", "initial_state_rendered_without_signal")
	module.button.pressed.emit()
	module.button.pressed.emit()
	expect(module.charges == 0 and module.accepted == 2 and module.hud.text == "Charges: 0", "commands_update_rule_and_hud")
	module.button.pressed.emit()
	expect(module.rejected == 1 and module.accepted == 2 and module.charges == 0, "exhausted_command_cannot_emit_success")
	var old_publisher = module.service
	for i in range(3):
		module.reset()
		module.button.pressed.emit()
		expect(module.charges == 1 and module.accepted == 1 and module.hud.text == "Charges: 1", "restart_without_duplicate_effect_"+str(i))
	expect(old_publisher.changed.get_connections().is_empty(), "restart_detaches_old_publisher")
	old_publisher.changed.emit(999)
	expect(module.hud.text == "Charges: 1", "late_old_event_cannot_change_hud")
	module.queue_free()
	await process_frame
	expect(old_publisher.changed.get_connections().is_empty(), "teardown_keeps_old_service_detached")
	finish()
