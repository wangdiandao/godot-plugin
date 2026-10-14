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


const Decision = preload("decision.gd")
var pending_count := 0
func _run() -> void:
	var enemy := Node2D.new()
	root.add_child(enemy)
	var target := Node2D.new()
	target.position = Vector2(20, 0)
	root.add_child(target)
	var brain := Decision.new()
	expect(brain.choose(enemy, [], 1.0, true).action == "idle", "no_target_falls_back_to_idle")
	expect(brain.choose(enemy, [target], 1.0, true).action == "chase", "visible_distant_target_chased")
	target.position = Vector2(2, 0)
	expect(brain.choose(enemy, [target], 1.0, true).action == "attack", "visible_in_range_target_attacked")
	expect(brain.choose(enemy, [target], 0.1, true).action == "flee", "low_health_flee_outranks_attack")
	expect(brain.choose(enemy, [target], 1.0, false).action == "idle", "occluded_target_not_attacked")
	expect(brain.choose(enemy, [target], NAN, true).action == "invalid", "nonfinite_health_rejected")
	var second := Node2D.new()
	second.position = Vector2(-2, 0)
	root.add_child(second)
	var one: Dictionary = brain.choose(enemy, [target, second], 1.0, true)
	var two: Dictionary = brain.choose(enemy, [second, target], 1.0, true)
	expect(one.target_id == two.target_id, "target_tie_has_stable_identity_order")
	brain.commit("attack")
	expect(not brain.commit("attack") and brain.enters == 1 and brain.exits == 0, "repeated_state_does_not_reenter")
	for distance: float in [7.9, 8.1, 7.95, 8.05]:
		target.position.x = distance
		expect(brain.choose(enemy, [target], 1.0, true).action == "attack", "hysteresis_preserves_attack_at_entry_boundary")
	target.position.x = 9.1
	expect(brain.choose(enemy, [target], 1.0, true).action == "chase", "hysteresis_exits_at_outer_boundary")
	brain.commit("flee")
	expect(brain.enters == 2 and brain.exits == 1, "state_transition_pairs_exit_enter")
	var captured: WeakRef = weakref(target)
	target.free()
	expect(captured.get_ref() == null and brain.choose(enemy, [captured.get_ref()], 1.0, true).action == "idle", "lost_target_before_decision_falls_back")
	var pending_target := Node2D.new()
	root.add_child(pending_target)
	pending_target.queue_free()
	expect(brain.choose(enemy, [pending_target], 1.0, true).action == "idle", "queued_for_deletion_target_rejected")
	expect(brain.choose(null, [], 1.0, true).action == "invalid", "missing_actor_rejected")
	# Pure candidate work is batched. No worker touches the scene tree.
	var candidates: Array[Dictionary] = []
	for i in range(17):
		candidates.append({"id":i, "score":float(i % 5), "valid":i != 4})
	var expected: Dictionary = brain.best(candidates)
	var planner := Decision.Planner.new()
	planner.start(candidates, 7)
	candidates[0].score = 999.0
	var monitor_id := StringName("CommunityAI/Pending_" + str(OS.get_process_id()))
	Performance.add_custom_monitor(monitor_id, func(): return pending_count)
	var ticks := 0
	while not planner.done:
		var processed: int = planner.step(3, 7)
		pending_count = planner.candidates.size() - planner.index
		expect(processed <= 3, "bounded_candidates_per_tick")
		ticks += 1
		await process_frame
	expect(planner.result == expected and ticks == 6, "budgeted_plan_matches_serial_snapshot")
	expect(Performance.has_custom_monitor(monitor_id) and Performance.get_custom_monitor(monitor_id) == 0, "pending_monitor_reaches_zero")
	Performance.remove_custom_monitor(monitor_id)
	expect(not Performance.has_custom_monitor(monitor_id), "monitor_teardown")
	planner.start([{"id":1,"score":2.0,"valid":true}], 8)
	planner.step(3, 9)
	expect(planner.cancelled and planner.result.is_empty(), "stale_generation_cannot_commit_plan")
	planner.start([], 10)
	planner.step(3, 10)
	expect(planner.done and planner.result.is_empty(), "empty_plan_has_no_action")
	enemy.free()
	second.free()
	finish()
