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

const Module = preload("res://module.gd")
const Component = preload("res://component.gd")
const Service = preload("res://service.gd")
func _run() -> void:
	var world := Module.new()
	world.name = "Module"
	var observer := Component.new()
	observer.name = "Observer"
	world.add_child(observer)
	observer.owner = world
	world.intent.connect(world.on_intent, CONNECT_PERSIST)
	var missing := Component.new()
	expect(not missing.configure(null), "missing_dependency_rejected")
	missing.free()
	root.add_child(world)
	expect(world.child_ready_seen, "dependency_configured_before_child_ready")
	expect(not world.request(-1) and world.dependency.value == 0, "invalid_command_preserves_state")
	world.intent.emit(2)
	expect(observer.observed == 2 and observer.notifications == 1, "intent_command_fact_delivery")
	expect(observer.configure(world.dependency), "repeat_configure")
	world.intent.emit(1)
	expect(observer.notifications == 2 and observer.observed == 3, "connection_idempotent")
	var replacement := Service.new()
	expect(observer.configure(replacement), "replacement_dependency_accepted")
	world.dependency.changed.emit(99)
	expect(observer.observed == 0 and world.dependency.changed.get_connections().is_empty(), "old_dependency_disconnected")
	replacement.command(2)
	expect(observer.observed == 2, "replacement_dependency_delivers")
	observer.configure(world.dependency)
	var packed := PackedScene.new()
	expect(packed.pack(world) == OK, "module_pack")
	var path := output.path_join("module.tscn")
	expect(ResourceSaver.save(packed, path) == OK, "module_save")
	var retained := world.dependency
	world.free()
	expect(retained.changed.get_connections().is_empty(), "teardown_disconnects_service")
	var loaded := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	expect(loaded != null and loaded.get_state().get_connection_count() == 1, "saved_signal_reloaded")
	if loaded != null:
		var restored := loaded.instantiate()
		expect(restored.get_node("Observer").observed == 3, "exported_component_state_saved")
		root.add_child(restored)
		expect(restored.get_node("Observer").observed == 0, "fresh_service_initial_state_bound")
		restored.intent.emit(2)
		expect(restored.get_node("Observer").observed == 2, "reloaded_intent_executes")
		restored.free()
	finish()
