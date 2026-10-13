extends SceneTree
var checks: Array = []
var output: String
var entered := 0
var exited := 0
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
	var space := actor.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(Vector2(0, 50), Vector2(0, 130), 1)
	query.exclude = [actor.get_rid()]
	var hit := space.intersect_ray(query)
	expect(not hit.is_empty() and hit.get("collider") == floor_body, "ray_hits_expected_floor")
	query.collision_mask = 2
	expect(space.intersect_ray(query).is_empty(), "ray_wrong_mask_has_no_hit")
	var trigger := Area2D.new()
	trigger.position = Vector2(30, 80)
	trigger.collision_layer = 4
	trigger.collision_mask = 1
	var trigger_shape := CollisionShape2D.new()
	var radius := CircleShape2D.new()
	radius.radius = 15
	trigger_shape.shape = radius
	trigger.add_child(trigger_shape)
	trigger.body_entered.connect(func(body: Node2D):
		if body == actor:
			entered += 1)
	trigger.body_exited.connect(func(body: Node2D):
		if body == actor:
			exited += 1)
	root.add_child(trigger)
	var initial_x := actor.position.x
	for i in range(60):
		await physics_frame
		actor.velocity = Vector2(60, 200)
		actor.move_and_slide()
	expect(absf(actor.position.x - initial_x - 60.0) < 1.0, "velocity_is_units_per_second")
	expect(actor.is_on_floor(), "horizontal_movement_retains_floor")
	for i in range(3):
		await physics_frame
	expect(entered == 1 and exited == 1, "trigger_enter_and_exit_once")
	# Reproduce a broken mask, repair only that mask, then repeat the interaction.
	trigger.collision_mask = 8
	actor.position = trigger.position
	for i in range(4):
		await physics_frame
	expect(entered == 1 and not trigger.get_overlapping_bodies().has(actor), "trigger_wrong_mask_reproduced")
	# Leave under the broken filter before repairing: repairing an overlapping
	# pair can itself generate entry and exit callbacks during synchronization.
	actor.position = Vector2(70, 80)
	for i in range(4):
		await physics_frame
	trigger.collision_mask = actor.collision_layer
	for i in range(4):
		await physics_frame
	actor.position = trigger.position
	for i in range(4):
		await physics_frame
	expect(entered == 2 and trigger.get_overlapping_bodies().has(actor), "trigger_mask_repair_detects_actor")
	actor.position = Vector2(70, 80)
	for i in range(4):
		await physics_frame
	expect(exited == 2, "repaired_trigger_exit")
	for cycle in range(2):
		actor.position = trigger.position
		for i in range(4):
			await physics_frame
		actor.position = Vector2(70, 80)
		for i in range(4):
			await physics_frame
	expect(entered == 4 and exited == 4, "repaired_trigger_repeats_without_duplicate_callbacks")
	var excluded_body := StaticBody2D.new()
	excluded_body.collision_layer = 8
	excluded_body.collision_mask = 0
	excluded_body.position = trigger.position
	var excluded_shape := CollisionShape2D.new()
	excluded_shape.shape = circle.duplicate()
	excluded_body.add_child(excluded_shape)
	root.add_child(excluded_body)
	for i in range(4):
		await physics_frame
	expect(not trigger.get_overlapping_bodies().has(excluded_body), "trigger_repair_preserves_excluded_layer")
	expect(trigger.collision_layer == 4 and actor.collision_layer == 1, "trigger_repair_preserves_other_filters")
	excluded_body.queue_free()
	trigger.queue_free()
	actor.queue_free()
	floor_body.queue_free()
	await process_frame
	finish()
