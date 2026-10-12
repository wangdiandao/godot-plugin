extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[args.find("--out") + 1]
	var checks: Array = []
	var base_hash := FileAccess.get_sha256("res://base.tscn")
	var original := load("res://instance.tscn") as PackedScene
	var world := original.instantiate()
	(world.get_node("Child") as Node2D).position = Vector2(50, 60)
	var packed := PackedScene.new()
	checks.append(packed.pack(world) == OK)
	var saved := output.path_join("instance.tscn")
	checks.append(ResourceSaver.save(packed, saved) == OK)
	world.free()
	var reloaded := ResourceLoader.load(saved, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	checks.append(reloaded.get_state().get_node_instance(1) != null)
	var instance := reloaded.instantiate()
	checks.append((instance.get_node("Child/Part") as Node2D).position == Vector2(5, 6))
	checks.append((instance.get_node("Child") as Node2D).position == Vector2(50, 60))
	instance.free()
	# A minimal text change retains the inherited base scene state.
	var text := FileAccess.get_file_as_string("res://inherited.tscn").replace("Vector2(30, 40)", "Vector2(70, 80)")
	var path := output.path_join("inherited.tscn")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	var inherited := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	checks.append(inherited.get_state().get_base_scene_state() != null)
	var variant := inherited.instantiate() as Node2D
	checks.append(variant.position == Vector2(70, 80))
	checks.append((variant.get_node("Part") as Node2D).position == Vector2(9, 8))
	variant.free()
	checks.append(FileAccess.get_sha256("res://base.tscn") == base_hash)
	var ok := not checks.has(false)
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify({"status": "passed" if ok else "failed", "checks": checks, "scope": "instance references, inherited state, local override, untouched base"}))
	quit(0 if ok else 1)
