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
	var restored := ResourceLoader.load(output.path_join("motion.tres"), "AnimationLibrary", ResourceLoader.CACHE_MODE_IGNORE) as AnimationLibrary
	expect(restored != null and restored.has_animation("move"), "reload_animation_library")
	if restored != null and restored.has_animation("move"):
		var clip := restored.get_animation("move")
		expect(is_equal_approx(clip.length, 1.0) and clip.get_track_count() == 1, "saved_duration_and_tracks")
		expect(clip.track_get_path(0) == NodePath("Target:position") and clip.track_get_key_count(0) == 2, "saved_path_and_keys")
		player.stop()
		player.remove_animation_library("")
		expect(player.add_animation_library("", restored) == OK, "bind_reloaded_library")
		target.position = Vector2.ZERO
		player.play("move")
		player.advance(0.75)
		expect(is_equal_approx(target.position.x, 75.0), "reloaded_track_evaluates")
	stage.queue_free()
	await process_frame
	finish()
