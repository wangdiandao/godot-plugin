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
	stage.name = "Room"
	root.add_child(stage)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in [Vector3(-1, 0, -1), Vector3(1, 0, 1), Vector3(-1, 0, 1)]:
		tool.set_uv(Vector2(point.x, point.z))
		tool.add_vertex(point)
	tool.generate_normals()
	tool.generate_tangents()
	var mesh := tool.commit()
	expect(mesh != null and mesh.get_aabb().size.x == 2, "procedural_mesh_bounds")
	var arrays := mesh.surface_get_arrays(0)
	expect(arrays[Mesh.ARRAY_NORMAL].size() == 3 and arrays[Mesh.ARRAY_TANGENT].size() == 12, "normals_and_tangents_created")
	var visual := MeshInstance3D.new()
	visual.name = "Floor"
	visual.mesh = mesh
	stage.add_child(visual)
	visual.owner = stage
	var skeleton := Skeleton3D.new()
	skeleton.name = "Rig"
	skeleton.add_bone("hand")
	skeleton.set_bone_rest(0, Transform3D.IDENTITY)
	stage.add_child(skeleton)
	skeleton.owner = stage
	var socket := BoneAttachment3D.new()
	socket.name = "Socket"
	socket.bone_name = "hand"
	skeleton.add_child(socket)
	socket.owner = stage
	var marker := Marker3D.new()
	marker.name = "Item"
	marker.position = Vector3(0, 0.25, 0)
	socket.add_child(marker)
	marker.owner = stage
	skeleton.set_bone_pose_position(0, Vector3(2, 1, 0))
	for i in range(3):
		await process_frame
	expect(marker.global_position.is_equal_approx(Vector3(2, 1.25, 0)), "socket_follows_bone_pose")
	expect(skeleton.find_bone("missing") == -1, "missing_bone_detected_before_binding")
	skeleton.reset_bone_pose(0)
	for i in range(3):
		await process_frame
	expect(marker.global_position.is_equal_approx(Vector3(0, 0.25, 0)), "socket_reset_preserves_local_offset")
	var packed := PackedScene.new()
	expect(packed.pack(stage) == OK, "mesh_socket_pack")
	var path := output.path_join("room.tscn")
	expect(ResourceSaver.save(packed, path) == OK, "mesh_socket_save")
	var loaded := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if loaded != null:
		var restored := loaded.instantiate()
		root.add_child(restored)
		var rig := restored.get_node("Rig") as Skeleton3D
		rig.set_bone_pose_position(rig.find_bone("hand"), Vector3(3, 0, 0))
		for i in range(3):
			await process_frame
		expect((restored.get_node("Rig/Socket/Item") as Marker3D).global_position.is_equal_approx(Vector3(3, 0.25, 0)), "reloaded_socket_mapping_works")
		restored.queue_free()
	else:
		expect(false, "mesh_socket_reload")
	stage.queue_free()
	await process_frame
	finish()
