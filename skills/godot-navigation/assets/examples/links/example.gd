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

func region_at(from_x: float, to_x: float) -> NavigationRegion3D:
	var region := NavigationRegion3D.new()
	var mesh := NavigationMesh.new()
	mesh.vertices = PackedVector3Array([Vector3(from_x,0,-2),Vector3(to_x,0,-2),Vector3(to_x,0,2),Vector3(from_x,0,2)])
	mesh.add_polygon(PackedInt32Array([0,1,2,3]))
	region.navigation_mesh = mesh
	return region
func synchronized(map: RID, previous: int) -> bool:
	for i in range(120):
		await physics_frame
		if NavigationServer3D.map_get_iteration_id(map)>previous:
			return true
	return false
func reaches(map: RID, start: Vector3, target: Vector3) -> bool:
	var route := NavigationServer3D.map_get_path(map,start,target,true)
	return not route.is_empty() and route[-1].distance_to(target)<0.1
func _run() -> void:
	var left := region_at(-5,-1)
	var right := region_at(1,5)
	root.add_child(left)
	root.add_child(right)
	var map := left.get_navigation_map()
	expect(await synchronized(map,0),"link_fixture_map_ready")
	var start := Vector3(-3,0,0)
	var target := Vector3(3,0,0)
	expect(not reaches(map,start,target),"gap_has_no_arrival_before_link")
	var link := NavigationLink3D.new()
	link.start_position = Vector3(-1.5,0,0)
	link.end_position = Vector3(1.5,0,0)
	link.bidirectional = false
	var iteration := NavigationServer3D.map_get_iteration_id(map)
	root.add_child(link)
	expect(await synchronized(map,iteration),"added_link_synchronizes")
	expect(reaches(map,start,target),"one_way_link_connects_forward")
	expect(not reaches(map,target,start),"one_way_link_excludes_reverse")
	iteration = NavigationServer3D.map_get_iteration_id(map)
	link.enabled = false
	expect(await synchronized(map,iteration) and not reaches(map,start,target),"disabled_link_reproduces_gap")
	iteration = NavigationServer3D.map_get_iteration_id(map)
	link.enabled = true
	expect(await synchronized(map,iteration) and reaches(map,start,target),"link_repair_restores_forward_route")
	expect(not reaches(map,target,start),"link_repair_preserves_direction_policy")
	link.queue_free()
	left.queue_free()
	right.queue_free()
	await process_frame
	finish()
