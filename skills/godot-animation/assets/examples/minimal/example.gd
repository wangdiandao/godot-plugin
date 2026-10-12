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

func _run() -> void:
	var stage := Node2D.new()
	stage.name = "Stage"
	root.add_child(stage)
	var target := Node2D.new()
	target.name = "Target"
	stage.add_child(target)
	var player := AnimationPlayer.new()
	stage.add_child(player)
	var motion := Animation.new()
	motion.length = 1.0
	var track := motion.add_track(Animation.TYPE_VALUE)
	motion.track_set_path(track, NodePath("Target:position"))
	motion.track_insert_key(track, 0.0, Vector2.ZERO)
	motion.track_insert_key(track, 1.0, Vector2(100, 0))
	var library := AnimationLibrary.new()
	expect(library.add_animation("move", motion) == OK, "animation_library")
	expect(player.add_animation_library("", library) == OK, "player_library")
	player.play("move")
	player.advance(0.5)
	expect(is_equal_approx(target.position.x, 50.0), "animation_track_evaluates")
	expect(ResourceSaver.save(library, output.path_join("motion.tres")) == OK, "save_animation_library")
	stage.queue_free()
	await process_frame
	finish()
