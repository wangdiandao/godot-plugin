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
	root.add_child(world)
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 1, 4)
	world.add_child(camera)
	camera.owner = world
	camera.current = true
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	world.add_child(light)
	light.owner = world
	light.rotation_degrees = Vector3(-45, -20, 0)
	light.shadow_enabled = true
	var mesh := MeshInstance3D.new()
	mesh.name = "Box"
	mesh.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.6, 0.8)
	material.roughness = 0.7
	mesh.material_override = material
	world.add_child(mesh)
	mesh.owner = world
	var particles := CPUParticles3D.new()
	particles.name = "Burst"
	particles.amount = 16
	particles.lifetime = 0.2
	particles.one_shot = true
	particles.emitting = false
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 2.0
	particles.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	particles.mesh = QuadMesh.new()
	var particle_material := StandardMaterial3D.new()
	particle_material.vertex_color_use_as_albedo = true
	particle_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	particle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particles.material_override = particle_material
	world.add_child(particles)
	particles.owner = world
	var packed := PackedScene.new()
	expect(packed.pack(world) == OK, "material_scene_packed")
	var path := output.path_join("material_scene.tscn")
	expect(ResourceSaver.save(packed, path) == OK, "material_scene_saved")
	var saved := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if saved == null:
		expect(false, "material_scene_readback")
		world.queue_free()
		await process_frame
		finish()
		return
	var restored := saved.instantiate() as Node3D
	root.add_child(restored)
	var saved_mesh := restored.get_node("Box") as MeshInstance3D
	var saved_material := saved_mesh.material_override as StandardMaterial3D
	expect(saved_material != null and is_equal_approx(saved_material.roughness, 0.7), "material_property_readback")
	expect((restored.get_node("Sun") as DirectionalLight3D).shadow_enabled, "light_shadow_readback")
	var saved_particles := restored.get_node("Burst") as CPUParticles3D
	var saved_particle_material := saved_particles.material_override as StandardMaterial3D
	expect(saved_particles.amount == 16 and saved_particles.one_shot and saved_particle_material.vertex_color_use_as_albedo, "particle_draw_and_process_contract")
	var local := saved_material.duplicate() as StandardMaterial3D
	local.albedo_color = Color(1, 0, 0)
	saved_mesh.material_override = local
	expect(saved_material.albedo_color.is_equal_approx(Color(0.3, 0.6, 0.8)), "local_edit_does_not_mutate_original")
	saved_particle_material.vertex_color_use_as_albedo = false
	expect(not saved_particle_material.vertex_color_use_as_albedo, "missing_color_consumption_detectable")
	saved_particle_material.vertex_color_use_as_albedo = true
	expect(saved_particle_material.vertex_color_use_as_albedo, "color_consumption_repaired")
	var resaved := PackedScene.new()
	expect(resaved.pack(restored) == OK and ResourceSaver.save(resaved, output.path_join("modified_scene.tscn")) == OK, "modified_scene_saved")
	var loaded_modified := ResourceLoader.load(output.path_join("modified_scene.tscn"), "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if loaded_modified:
		var readback := loaded_modified.instantiate()
		var readback_material := (readback.get_node("Box") as MeshInstance3D).material_override as StandardMaterial3D
		expect(readback_material.albedo_color.is_equal_approx(Color(1, 0, 0)), "modified_scene_color_readback")
		readback.free()
	else:
		expect(false, "modified_scene_color_readback")
	world.queue_free()
	restored.queue_free()
	await process_frame
	finish()
