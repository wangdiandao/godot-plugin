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

const Actor = preload("actor.gd")
func rectangle(from_x: float, to_x: float) -> NavigationMesh:
	var mesh := NavigationMesh.new()
	mesh.vertices = PackedVector3Array([Vector3(from_x, 0, -3), Vector3(to_x, 0, -3), Vector3(to_x, 0, 3), Vector3(from_x, 0, 3)])
	mesh.add_polygon(PackedInt32Array([0,1,2,3]))
	return mesh
func wait_map(map: RID) -> bool:
	for i in range(120):
		await physics_frame
		if NavigationServer3D.map_get_iteration_id(map) > 0:
			return true
	return false
func arrive(actor: CharacterBody3D, target: Vector3) -> bool:
	actor.set_goal(target)
	for i in range(300):
		await physics_frame
		if actor.global_position.distance_to(target) < 0.25:
			return true
	return false
func _run() -> void:
	var region := NavigationRegion3D.new()
	region.navigation_mesh = rectangle(-5, 5)
	root.add_child(region)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12, 1, 8)
	floor_shape.shape = box
	floor_body.position.y = -0.5
	floor_body.add_child(floor_shape)
	root.add_child(floor_body)
	var actor = Actor.new()
	actor.position = Vector3(-3, 0, 0)
	root.add_child(actor)
	expect(await wait_map(region.get_navigation_map()), "map_ready_before_movement")
	actor.agent.navigation_layers = 2
	actor.set_goal(Vector3(3, 0, 0))
	for i in range(12):
		await physics_frame
	expect(actor.position.x < -2.8 and not actor.agent.is_target_reachable(), "excluded_route_does_not_move_actor")
	actor.agent.navigation_layers = 1
	var blocker := StaticBody3D.new()
	var blocked_shape := CollisionShape3D.new()
	var blocked_box := BoxShape3D.new()
	blocked_box.size = Vector3(0.3, 2, 6)
	blocked_shape.shape = blocked_box
	blocker.position.y = 1
	blocker.add_child(blocked_shape)
	root.add_child(blocker)
	actor.set_goal(Vector3(3, 0, 0))
	for i in range(100):
		await physics_frame
	expect(actor.agent.is_target_reachable() and actor.position.x < 0 and actor.position.distance_to(Vector3(3, 0, 0)) > 1, "collision_blocks_graph_reachable_target")
	blocker.queue_free()
	for i in range(3):
		await physics_frame
	expect(await arrive(actor, Vector3(3, 0, 0)), "repaired_actor_actually_arrives")
	actor.agent.avoidance_enabled = true
	expect(await arrive(actor, Vector3(-3, 0, 0)), "avoidance_callback_moves_actor")
	expect(actor.safe_callbacks > 0 and not actor.double_move, "one_motion_application_per_physics_tick")
	expect(await arrive(actor, Vector3(2, 0, 0)), "patrol_second_destination")
	actor.set_goal(Vector3(50, 0, 0))
	for i in range(10):
		await physics_frame
	expect(not actor.agent.is_target_reachable(), "unreachable_target_classified")
	actor.queue_free()
	region.queue_free()
	floor_body.queue_free()
	await process_frame
	finish()
