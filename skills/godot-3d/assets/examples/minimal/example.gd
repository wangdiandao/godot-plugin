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
	var world := Node3D.new()
	world.name = "World"
	var mesh := MeshInstance3D.new()
	mesh.name = "Box"
	mesh.mesh = BoxMesh.new()
	world.add_child(mesh)
	mesh.owner = world
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 3, 5)
	camera.rotation_degrees.x = -30
	world.add_child(camera)
	camera.owner = world
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-45, -30, 0)
	world.add_child(light)
	light.owner = world
	# A sibling shares mesh data until an explicit independent edit.
	var sibling := MeshInstance3D.new()
	sibling.name = "IndependentBox"
	sibling.mesh = mesh.mesh.duplicate() as Mesh
	(sibling.mesh as BoxMesh).size = Vector3(2, 1, 1)
	sibling.position = Vector3(3, 0, 0)
	world.add_child(sibling)
	sibling.owner = world
	expect((mesh.mesh as BoxMesh).size == Vector3.ONE, "independent_mesh_edit_preserves_original")
	var scene := PackedScene.new()
	expect(scene.pack(world) == OK, "pack_mesh_and_camera")
	var path := output.path_join("world.tscn")
	expect(ResourceSaver.save(scene, path) == OK, "save_world")
	var loaded := (ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	expect((loaded.get_node("Box") as MeshInstance3D).mesh is BoxMesh, "native_mesh_roundtrip")
	expect((loaded.get_node("Camera") as Camera3D).position.z == 5, "camera_roundtrip")
	expect(loaded.get_node("Sun") is DirectionalLight3D, "light_roundtrip")
	expect((loaded.get_node("IndependentBox") as MeshInstance3D).mesh.get_aabb().size.x == 2, "independent_size_roundtrip")
	loaded.free()
	world.free()
	finish()
