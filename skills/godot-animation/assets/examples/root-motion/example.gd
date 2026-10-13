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
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	var actor := Node3D.new()
	actor.name = "Actor"
	stage.add_child(actor)
	var player := AnimationPlayer.new()
	player.name = "Player"
	stage.add_child(player)
	var move := Animation.new()
	move.length = 1.0
	var track := move.add_track(Animation.TYPE_POSITION_3D)
	move.track_set_path(track, NodePath("Actor:position"))
	move.position_track_insert_key(track, 0.0, Vector3.ZERO)
	move.position_track_insert_key(track, 1.0, Vector3(2, 0, 0))
	var library := AnimationLibrary.new()
	library.add_animation("move", move)
	player.add_animation_library("", library)
	var tree := AnimationTree.new()
	tree.name = "Tree"
	tree.anim_player = NodePath("../Player")
	tree.root_motion_track = NodePath("Actor:position")
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var clip := AnimationNodeAnimation.new()
	clip.animation = "move"
	tree.tree_root = clip
	stage.add_child(tree)
	tree.active = true
	tree.advance(0.0)
	tree.advance(0.25)
	var motion := tree.get_root_motion_position()
	expect(motion.is_equal_approx(Vector3(0.5, 0, 0)), "root_motion_delta")
	expect(actor.position.is_zero_approx(), "extracted_motion_does_not_double_move_actor")
	actor.position += motion
	expect(actor.position.is_equal_approx(Vector3(0.5, 0, 0)), "controller_applies_motion_once")
	tree.active = false
	tree.advance(0.25)
	expect(actor.position.is_equal_approx(Vector3(0.5, 0, 0)), "inactive_tree_leaves_actor")
	stage.queue_free()
	await process_frame
	finish()
