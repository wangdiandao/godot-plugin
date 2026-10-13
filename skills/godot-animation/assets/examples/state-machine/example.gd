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

func clip(value: float) -> Animation:
	var animation := Animation.new()
	animation.length = 1
	animation.loop_mode = Animation.LOOP_LINEAR
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath("Actor:position:x"))
	animation.track_insert_key(track, 0, value)
	animation.track_insert_key(track, 1, value)
	return animation
func _run() -> void:
	var stage := Node2D.new()
	var actor := Node2D.new()
	actor.name = "Actor"
	stage.add_child(actor)
	actor.owner = stage
	var player := AnimationPlayer.new()
	player.name = "Player"
	stage.add_child(player)
	player.owner = stage
	var library := AnimationLibrary.new()
	for name: String in ["idle", "move", "action"]:
		library.add_animation(name, clip({"idle":0.0,"move":10.0,"action":20.0}[name]))
	player.add_animation_library("", library)
	var graph := AnimationNodeStateMachine.new()
	for name: String in ["idle", "move", "action"]:
		var node := AnimationNodeAnimation.new()
		node.animation = name
		graph.add_node(name, node)
	for pair: Array in [["idle","move"],["move","action"],["action","idle"]]:
		var transition := AnimationNodeStateMachineTransition.new()
		transition.xfade_time = 0.2
		graph.add_transition(pair[0],pair[1],transition)
	var tree := AnimationTree.new()
	tree.name = "Tree"
	tree.anim_player = NodePath("../Player")
	tree.tree_root = graph
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	stage.add_child(tree)
	tree.owner = stage
	root.add_child(stage)
	tree.active = true
	var playback = tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	playback.start("idle")
	tree.advance(0)
	tree.advance(0.05)
	expect(absf(actor.position.x) < 0.01, "idle_pose_applied")
	playback.travel("move")
	tree.advance(0)
	tree.advance(0.1)
	expect(actor.position.x > 0 and actor.position.x < 10, "transition_blends_actual_property")
	tree.advance(0.3)
	expect(absf(actor.position.x - 10) < 0.01, "move_pose_applied")
	playback.travel("action")
	tree.advance(0)
	tree.advance(0.05)
	playback.travel("idle")
	for i in range(16):
		tree.advance(0.05)
	expect(absf(actor.position.x) < 0.01, "interrupted_action_returns_to_idle")
	tree.active = false
	var wrong := library.get_animation("move").track_get_path(0)
	library.get_animation("move").track_set_path(0, NodePath("Missing:position:x"))
	expect(not stage.has_node("Missing"), "bad_track_target_detected_before_playback")
	library.get_animation("move").track_set_path(0, wrong)
	var packed := PackedScene.new()
	expect(packed.pack(stage) == OK, "state_machine_pack")
	var path := output.path_join("locomotion.tscn")
	expect(ResourceSaver.save(packed, path) == OK, "state_machine_save")
	var loaded := ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if loaded != null:
		var restored := loaded.instantiate()
		root.add_child(restored)
		var restored_tree := restored.get_node("Tree") as AnimationTree
		restored_tree.active = true
		var state = restored_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		state.start("move")
		restored_tree.advance(0)
		restored_tree.advance(0.3)
		expect(absf((restored.get_node("Actor") as Node2D).position.x - 10) < 0.01, "saved_graph_replays_repaired_clip")
		restored.queue_free()
	else:
		expect(false, "state_machine_reload")
	stage.queue_free()
	await process_frame
	finish()
