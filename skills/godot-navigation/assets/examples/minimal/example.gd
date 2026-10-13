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
	# Exact shared edges isolate region connectivity from bake erosion.
	var joined_map := NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(joined_map, true)
	var left_mesh := rectangle_mesh(-10.0, 0.0)
	var right_mesh := rectangle_mesh(0.0, 10.0)
	var left := NavigationServer3D.region_create()
	var right := NavigationServer3D.region_create()
	NavigationServer3D.region_set_map(left, joined_map)
	NavigationServer3D.region_set_map(right, joined_map)
	NavigationServer3D.region_set_navigation_mesh(left, left_mesh)
	NavigationServer3D.region_set_navigation_mesh(right, right_mesh)
	NavigationServer3D.region_set_navigation_layers(left, 1)
	NavigationServer3D.region_set_navigation_layers(right, 2)
	for i in range(120):
		await physics_frame
		if NavigationServer3D.map_get_iteration_id(joined_map) > 0 and NavigationServer3D.map_get_closest_point_owner(joined_map, Vector3(-5, 0, 0)) == left and NavigationServer3D.map_get_closest_point_owner(joined_map, Vector3(5, 0, 0)) == right:
			break
	var start := Vector3(-5, 0, 0)
	var destination := Vector3(5, 0, 0)
	var connected := NavigationServer3D.map_get_path(joined_map, start, destination, true, 3)
	print("Cross-region path: ", connected)
	expect(connected.size() >= 2 and connected[-1].distance_to(destination) < 0.1, "path_crosses_two_regions")
	var excluded := NavigationServer3D.map_get_path(joined_map, start, destination, true, 1)
	expect(excluded.is_empty() or excluded[-1].distance_to(destination) > 1.0, "excluded_region_cannot_reach_target")
	var iteration := NavigationServer3D.map_get_iteration_id(joined_map)
	NavigationServer3D.region_set_enabled(right, false)
	for i in range(120):
		await physics_frame
		if NavigationServer3D.map_get_iteration_id(joined_map) != iteration and NavigationServer3D.map_get_closest_point_owner(joined_map, destination) != right:
			break
	var disconnected := NavigationServer3D.map_get_path(joined_map, start, destination, true, 3)
	expect(disconnected.is_empty() or disconnected[-1].distance_to(destination) > 1.0, "disabled_region_cannot_reach_target")
	NavigationServer3D.free_rid(left)
	NavigationServer3D.free_rid(right)
	NavigationServer3D.free_rid(joined_map)
	finish()

func rectangle_mesh(from_x: float, to_x: float) -> NavigationMesh:
	var result := NavigationMesh.new()
	result.vertices = PackedVector3Array([Vector3(from_x, 0, -5), Vector3(to_x, 0, -5), Vector3(to_x, 0, 5), Vector3(from_x, 0, 5)])
	result.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	return result
