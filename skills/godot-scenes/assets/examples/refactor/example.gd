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

func _run() -> void:
	var source_hash := FileAccess.get_sha256("res://base.tscn")
	var wrapper := Node2D.new()
	wrapper.name = "Wrapper"
	wrapper.set_script(load("res://controller.gd"))
	var base := load("res://base.tscn") as PackedScene
	var module := base.instantiate()
	module.name = "Module"
	wrapper.add_child(module)
	module.owner = wrapper
	var button := Button.new()
	button.name = "Activate"
	wrapper.add_child(button)
	button.owner = wrapper
	button.pressed.connect(wrapper.activate, CONNECT_PERSIST)
	var player := AnimationPlayer.new()
	player.name = "Player"
	wrapper.add_child(player)
	player.owner = wrapper
	var clip := Animation.new()
	clip.length = 1
	var track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath("Module:position"))
	clip.track_insert_key(track, 0, Vector2.ZERO)
	clip.track_insert_key(track, 1, Vector2(100,0))
	var library := AnimationLibrary.new()
	library.add_animation("move",clip)
	player.add_animation_library("",library)
	wrapper.target_path = NodePath("Module")
	root.add_child(wrapper)
	module.name = "Actor"
	expect(not wrapper.has_node(wrapper.target_path), "rename_reproduces_stale_export_path")
	# Repair the two authored contracts; inherited internals and base stay intact.
	wrapper.target_path = NodePath("Actor")
	clip.track_set_path(track,NodePath("Actor:position"))
	var scene := PackedScene.new()
	expect(scene.pack(wrapper) == OK, "renamed_instance_pack")
	var path := output.path_join("wrapper.tscn")
	expect(ResourceSaver.save(scene,path) == OK, "renamed_instance_save")
	var saved := ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	expect(saved != null, "renamed_instance_reload")
	if saved != null:
		var retained_instance := false
		for i in range(saved.get_state().get_node_count()):
			retained_instance = retained_instance or saved.get_state().get_node_instance(i) != null
		expect(retained_instance, "refactor_preserves_scene_instance_reference")
		var restored := saved.instantiate()
		root.add_child(restored)
		expect(restored.has_node("Actor/Part") and restored.get_node("Actor/Part").position == Vector2(5,6), "base_internal_state_unchanged")
		(restored.get_node("Activate") as Button).pressed.emit()
		expect(restored.activations == 1 and not (restored.get_node("Actor") as Node2D).visible, "saved_connection_and_export_path_execute")
		var animator := restored.get_node("Player") as AnimationPlayer
		animator.play("move")
		animator.advance(0.5)
		expect(absf((restored.get_node("Actor") as Node2D).position.x - 50) < 0.01, "saved_animation_path_repaired")
		restored.queue_free()
	var variant := load("res://variant.tscn") as PackedScene
	expect(variant.get_state().get_base_scene_state() != null, "inherited_boundary_retained")
	var inherited := variant.instantiate() as Node2D
	expect(inherited.position == Vector2(20,30) and inherited.has_node("Part"), "inherited_override_and_child")
	inherited.free()
	expect(FileAccess.get_sha256("res://base.tscn") == source_hash, "source_base_bytes_preserved")
	wrapper.queue_free()
	await process_frame
	finish()
