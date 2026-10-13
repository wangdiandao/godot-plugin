extends SceneTree
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var width := float(args[0])
	var expected_mip := args[1] == "true"
	var texture := ResourceLoader.load("res://art.png") as Texture2D
	var model := ResourceLoader.load("res://model.gltf") as PackedScene
	if texture == null or model == null:
		quit(1)
		return
	var imported := model.instantiate()
	var meshes := imported.find_children("*","MeshInstance3D",true,false)
	var ok := texture.get_width() == 32 and texture.get_image().has_mipmaps() == expected_mip and meshes.size() == 1 and is_equal_approx(meshes[0].mesh.get_aabb().size.x,width)
	if args[2] == "create":
		var wrapper := Node3D.new()
		wrapper.name = "Wrapper"
		imported.name = "Model"
		wrapper.add_child(imported)
		imported.owner = wrapper
		var marker := Marker3D.new()
		marker.name = "GameplaySocket"
		marker.position.y = 3
		wrapper.add_child(marker)
		marker.owner = wrapper
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.CORAL
		ok = ok and ResourceSaver.save(material,"res://authored.tres") == OK
		var authored := MeshInstance3D.new()
		authored.name = "Authored"
		authored.mesh = BoxMesh.new()
		authored.material_override = ResourceLoader.load("res://authored.tres")
		wrapper.add_child(authored)
		authored.owner = wrapper
		var scene := PackedScene.new()
		ok = ok and scene.pack(wrapper) == OK and ResourceSaver.save(scene,"res://wrapper.tscn") == OK
		wrapper.free()
	else:
		imported.free()
		var scene := ResourceLoader.load("res://wrapper.tscn","PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		if scene == null:
			quit(1)
			return
		var wrapper := scene.instantiate()
		var changed := wrapper.get_node("Model").find_children("*","MeshInstance3D",true,false)
		ok = ok and changed.size() == 1 and is_equal_approx(changed[0].mesh.get_aabb().size.x,width) and wrapper.get_node("GameplaySocket").position.y == 3 and wrapper.get_node("Authored").material_override.resource_path == "res://authored.tres"
		wrapper.free()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify({"status":"passed" if ok else "failed"}))
	quit(0 if ok else 1)
