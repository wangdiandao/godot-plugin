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
	var geometry := NavigationMeshSourceGeometryData3D.new()
	# Godot's source geometry API expects clockwise winding viewed from above.
	geometry.add_faces(PackedVector3Array([Vector3(-10, 0, -10), Vector3(10, 0, 10), Vector3(-10, 0, 10), Vector3(-10, 0, -10), Vector3(10, 0, -10), Vector3(10, 0, 10)]), Transform3D.IDENTITY)
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.5
	NavigationServer3D.bake_from_source_geometry_data(mesh, geometry)
	expect(mesh.get_polygon_count() > 0, "cpu_navigation_bake")
	var path := output.path_join("navigation.tres")
	expect(ResourceSaver.save(mesh, path) == OK, "save_navigation")
	var loaded := ResourceLoader.load(path, "NavigationMesh", ResourceLoader.CACHE_MODE_IGNORE) as NavigationMesh
	expect(loaded != null and loaded.get_polygon_count() == mesh.get_polygon_count(), "navigation_roundtrip")
	var map := NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(map, true)
	NavigationServer3D.map_set_cell_size(map, mesh.cell_size)
	NavigationServer3D.map_set_cell_height(map, mesh.cell_height)
	var region := NavigationServer3D.region_create()
	NavigationServer3D.region_set_map(region, map)
	NavigationServer3D.region_set_navigation_mesh(region, mesh)
	# Navigation updates are asynchronous; wait for a real map iteration.
	for i in range(120):
		await physics_frame
		if NavigationServer3D.region_get_iteration_id(region) > 0 and NavigationServer3D.map_get_closest_point_owner(map, Vector3.ZERO).is_valid():
			break
	var route := NavigationServer3D.map_get_path(map, Vector3(-5, 0, 0), Vector3(5, 0, 0), true)
	print("Navigation path: ", route)
	expect(route.size() >= 2 and route[0].distance_to(route[-1]) > 9.0, "path_crosses_baked_region")
	NavigationServer3D.free_rid(region)
	NavigationServer3D.free_rid(map)
	finish()
