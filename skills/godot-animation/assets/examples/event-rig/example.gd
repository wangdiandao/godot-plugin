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
	var stage := Node3D.new()
	stage.name = "Actor"
	stage.set_script(load("res://actor.gd"))
	var skeleton := Skeleton3D.new()
	skeleton.name = "Rig"
	skeleton.add_bone("hand")
	stage.add_child(skeleton)
	skeleton.owner = stage
	var socket := BoneAttachment3D.new()
	socket.name = "Socket"
	socket.bone_name = "hand"
	skeleton.add_child(socket)
	socket.owner = stage
	var player := AnimationPlayer.new()
	player.name = "Player"
	player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	stage.add_child(player)
	player.owner = stage
	var clip := Animation.new()
	clip.length = 1
	var bone := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(bone,NodePath("Rig:hand"))
	clip.position_track_insert_key(bone,0,Vector3.ZERO)
	clip.position_track_insert_key(bone,1,Vector3(2,0,0))
	var event := clip.add_track(Animation.TYPE_METHOD)
	clip.track_set_path(event,NodePath("."))
	clip.track_insert_key(event,0.25,{"method":&"mark_event","args":[]})
	var library := AnimationLibrary.new()
	library.add_animation("action",clip)
	player.add_animation_library("",library)
	root.add_child(stage)
	player.play("action")
	player.advance(0)
	player.advance(0.4)
	expect(stage.events == 1 and absf(skeleton.get_bone_pose_position(0).x-0.8)<0.01,"bone_track_and_method_event")
	player.pause()
	for i in range(3):
		await process_frame
	expect(absf(socket.position.x-0.8)<0.01,"animated_bone_socket_follows")
	player.stop()
	stage.events = 0
	player.play("action")
	player.advance(0)
	player.advance(0.1)
	player.stop()
	expect(stage.events == 0,"interruption_before_event_does_not_fire")
	player.play("action")
	player.advance(0)
	player.advance(0.5)
	player.pause()
	expect(stage.events == 1,"restarted_action_fires_once")
	var packed := PackedScene.new()
	expect(packed.pack(stage)==OK,"rig_event_pack")
	var path := output.path_join("rig.tscn")
	expect(ResourceSaver.save(packed,path)==OK,"rig_event_save")
	var saved := ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if saved != null:
		var restored := saved.instantiate()
		root.add_child(restored)
		restored.events = 0
		var runner := restored.get_node("Player") as AnimationPlayer
		runner.stop()
		runner.play("action")
		runner.advance(0)
		runner.advance(0.5)
		runner.pause()
		expect(restored.events==1 and absf((restored.get_node("Rig") as Skeleton3D).get_bone_pose_position(0).x-1)<0.01,"reloaded_rig_and_event_execute")
		restored.queue_free()
	else:
		expect(false,"rig_event_reload")
	stage.queue_free()
	await process_frame
	finish()
