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

class Walker extends CharacterBody3D:
	var speed := 0.0
	func _physics_process(delta: float) -> void:
		velocity.x = speed
		velocity.y -= 9.8 * delta
		move_and_slide()
func shape(body: Node3D, size: Vector3) -> void:
	var node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	node.shape = box
	body.add_child(node)
func _run() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.position.y = -0.5
	shape(floor_body, Vector3(20, 1, 20))
	root.add_child(floor_body)
	var walker := Walker.new()
	shape(walker, Vector3.ONE)
	walker.position.y = 2
	root.add_child(walker)
	for i in range(90):
		await physics_frame
	expect(walker.is_on_floor() and absf(walker.position.y - 0.5) < 0.08, "character3d_lands")
	var begin := walker.position.x
	walker.speed = 2
	for i in range(60):
		await physics_frame
	walker.speed = 0
	expect(absf(walker.position.x - begin - 2) < 0.12, "character3d_units_per_second")
	var query := PhysicsRayQueryParameters3D.create(Vector3(5, 3, 0), Vector3(5, -2, 0), 2)
	var space := walker.get_world_3d().direct_space_state
	expect(space.intersect_ray(query).is_empty(), "wrong_ray_mask_reproduced")
	query.collision_mask = 1
	var hit := space.intersect_ray(query)
	expect(not hit.is_empty() and hit.collider == floor_body, "ray_filter_repaired")
	var rigid := RigidBody3D.new()
	rigid.gravity_scale = 0
	rigid.position = Vector3(-5, 3, 0)
	shape(rigid, Vector3.ONE)
	root.add_child(rigid)
	for i in range(4):
		await physics_frame
	rigid.sleeping = true
	for i in range(3):
		await physics_frame
	var resting := rigid.position
	rigid.sleeping = false
	rigid.apply_central_impulse(Vector3(2, 0, 0))
	for i in range(20):
		await physics_frame
	expect(rigid.position.x > resting.x + 0.2 and not rigid.sleeping, "rigid3d_wake_and_impulse")
	expect(space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(5, 3, 0), Vector3(5, -2, 0), 4)).is_empty(), "repair_keeps_excluded_layer")
	var slope := StaticBody3D.new()
	slope.position.x = 30
	slope.rotation.z = deg_to_rad(20)
	shape(slope, Vector3(8,0.5,6))
	root.add_child(slope)
	var climber := Walker.new()
	climber.position = Vector3(30,3,0)
	climber.floor_snap_length = 0.3
	shape(climber,Vector3.ONE)
	root.add_child(climber)
	for i in range(100):
		await physics_frame
	var slope_start := climber.position
	expect(climber.is_on_floor(), "slope_classified_as_floor")
	climber.speed = 1
	for i in range(60):
		await physics_frame
	climber.speed = 0
	expect(climber.is_on_floor() and climber.position.y > slope_start.y + 0.1, "slope_ascent_preserves_contact")
	var wall := StaticBody3D.new()
	wall.position = Vector3(0,1,5)
	wall.collision_layer = 8
	shape(wall,Vector3(0.05,3,2))
	root.add_child(wall)
	for i in range(4):
		await physics_frame
	for i in range(3):
		var sweep := PhysicsRayQueryParameters3D.create(Vector3(-5,1,5),Vector3(5,1,5),8)
		var impact := space.intersect_ray(sweep)
		expect(not impact.is_empty() and impact.collider == wall and absf(impact.position.x) < 0.04, "fast_point_sweep_thin_wall_"+str(i))
		sweep.collision_mask = 16
		expect(space.intersect_ray(sweep).is_empty(), "fast_sweep_excluded_mask_"+str(i))
	climber.queue_free()
	slope.queue_free()
	wall.queue_free()
	rigid.queue_free()
	walker.queue_free()
	floor_body.queue_free()
	await process_frame
	finish()
