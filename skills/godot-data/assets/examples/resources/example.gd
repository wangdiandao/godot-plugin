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

const Data = preload("res://probe_data.gd")
func _run() -> void:
	var external = Data.new()
	external.marker = 22
	expect(ResourceSaver.save(external, output.path_join("external.tres"), ResourceSaver.FLAG_CHANGE_PATH) == OK, "save external")
	external = ResourceLoader.load(output.path_join("external.tres"), "", ResourceLoader.CACHE_MODE_IGNORE)
	var source = Data.new()
	source.marker = 7
	source.child = Data.new()
	source.child.marker = 11
	source.external = external
	source.repeated.assign([source.child, source.child])
	source.values.assign([3, 5])
	var shallow = source.duplicate()
	var deep = source.duplicate(true)
	var all = source.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	print({"external_path": external.resource_path, "child_path": source.child.resource_path, "deep_child_same": deep.child == source.child, "deep_external_same": deep.external == source.external})
	expect(shallow.child == source.child and shallow.external == source.external, "shallow shares resources")
	expect(deep.child != source.child and deep.external == source.external, "deep internal/external policy")
	expect(deep.repeated[0] == deep.repeated[1] and deep.repeated[0] == deep.child, "deep preserves repeated alias")
	expect(all.external != source.external, "ALL copies external data")
	expect(all.get_script() == source.get_script(), "ALL shares script definition")
	deep.values[0] = 99
	expect(source.values[0] == 3, "deep collection independence")
	expect(ResourceSaver.save(source, output.path_join("saved.tres")) == OK, "save root")
	var loaded = ResourceLoader.load(output.path_join("saved.tres"), "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded == null:
		expect(false, "uncached roundtrip load")
		finish()
		return
	expect(loaded != source and loaded.marker == 7 and loaded.child.marker == 11, "uncached roundtrip state")
	source.marker = 999
	expect(loaded.marker == 7, "loaded independent source memory")
	var root = Node.new()
	var actor = MeshInstance3D.new()
	root.add_child(actor)
	actor.owner = root
	actor.mesh = BoxMesh.new()
	actor.mesh.resource_local_to_scene = true
	var scene = PackedScene.new()
	expect(scene.pack(root) == OK, "pack scene")
	var first = scene.instantiate()
	var second = scene.instantiate()
	var first_mesh = first.get_child(0).mesh
	var second_mesh = second.get_child(0).mesh
	first_mesh.size = Vector3(3, 4, 5)
	expect(first_mesh != second_mesh and second_mesh.size == Vector3.ONE, "scene-local independent mesh")
	expect(first_mesh.get_local_scene() == first, "scene-local owner root")
	first.free()
	second.free()
	root.free()
	finish()
