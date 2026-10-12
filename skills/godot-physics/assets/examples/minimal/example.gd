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
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(200, 20)
	floor_shape.shape = rectangle
	floor_body.position = Vector2(0, 100)
	floor_body.add_child(floor_shape)
	root.add_child(floor_body)
	var actor := CharacterBody2D.new()
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10
	collision.shape = circle
	actor.add_child(collision)
	root.add_child(actor)
	for i in range(100):
		await physics_frame
		actor.velocity = Vector2(0, 200)
		actor.move_and_slide()
	expect(actor.is_on_floor(), "character_lands_on_floor")
	expect(absf(actor.position.y - 80.0) < 1.0, "collision_prevents_penetration")
	actor.queue_free()
	floor_body.queue_free()
	await process_frame
	finish()
