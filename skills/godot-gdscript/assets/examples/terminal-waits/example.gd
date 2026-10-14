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


# The ticket survives the disposable animation owner. Completion is cached.
class Ticket extends RefCounted:
	signal settled
	var status := "pending"
	func settle(value: String) -> void:
		if status != "pending":
			return
		status = value
		settled.emit()
	func wait(tree: SceneTree, seconds: float) -> String:
		if status == "pending":
			var timer := tree.create_timer(seconds)
			var expire := func(): settle("timeout")
			timer.timeout.connect(expire)
			await settled
			if timer.timeout.is_connected(expire):
				timer.timeout.disconnect(expire)
		return status

class AnimationJob extends RefCounted:
	var ticket := Ticket.new()
	var tween: Tween
	var target: WeakRef
	var completed: Callable
	var exiting: Callable
	func start(node: Node, duration: float) -> void:
		target = weakref(node)
		tween = node.create_tween()
		tween.tween_interval(duration)
		completed = func(): stop("completed")
		exiting = func(): stop("cancelled")
		tween.finished.connect(completed)
		node.tree_exiting.connect(exiting)
	func stop(reason: String) -> void:
		if tween != null and tween.is_valid():
			if tween.finished.is_connected(completed):
				tween.finished.disconnect(completed)
			if reason != "completed":
				tween.kill()
		var node = target.get_ref() if target != null else null
		if is_instance_valid(node) and node.tree_exiting.is_connected(exiting):
			node.tree_exiting.disconnect(exiting)
		ticket.settle(reason)

class Emitter extends RefCounted:
	signal done
class SignalBatch extends RefCounted:
	var ticket := Ticket.new()
	var subscriptions: Array[Dictionary] = []
	var remaining := 0
	var started := false
	func begin(signals: Array[Signal]) -> bool:
		if started:
			return false
		started = true
		var seen: Array[Signal] = []
		for sig: Signal in signals:
			if sig in seen:
				ticket.settle("invalid")
				return false
			seen.append(sig)
		remaining = signals.size()
		for sig: Signal in signals:
			var callback := func():
				remaining -= 1
				if remaining == 0:
					ticket.settle("completed")
			sig.connect(callback, CONNECT_ONE_SHOT)
			subscriptions.append({"owner": weakref(sig.get_object()), "name": sig.get_name(), "callback": callback})
		if remaining == 0:
			ticket.settle("completed")
		return true
	func wait(tree: SceneTree, seconds: float) -> String:
		var result := await ticket.wait(tree, seconds)
		for entry: Dictionary in subscriptions:
			var owner = entry.owner.get_ref()
			if is_instance_valid(owner) and owner.is_connected(entry.name, entry.callback):
				owner.disconnect(entry.name, entry.callback)
		subscriptions.clear()
		return result

var nested_status := "pending"
var cleanup_count := 0
func outer_wait(ticket: Ticket) -> void:
	nested_status = await ticket.wait(self, 0.08)
	cleanup_count += 1
func _run() -> void:
	var node := Node.new()
	root.add_child(node)
	var normal := AnimationJob.new()
	normal.start(node, 0.01)
	expect(await normal.ticket.wait(self, 0.3) == "completed", "normal_tween_completion")
	normal.stop("cancelled")
	expect(normal.ticket.status == "completed", "terminal_result_is_exactly_once")
	var cached := Ticket.new()
	cached.settle("completed")
	expect(await cached.wait(self, 0.01) == "completed", "synchronous_completion_cannot_be_missed")
	var cancelled := AnimationJob.new()
	cancelled.start(node, 1.0)
	outer_wait(cancelled.ticket)
	cancelled.stop("cancelled")
	await process_frame
	expect(nested_status == "cancelled" and cleanup_count == 1, "nested_caller_cleanup_after_explicit_cancel")
	var killed := AnimationJob.new()
	killed.start(node, 1.0)
	killed.tween.kill()
	expect(await killed.ticket.wait(self, 0.02) == "timeout", "external_kill_has_bounded_terminal_wait")
	killed.stop("cancelled")
	var freed := AnimationJob.new()
	freed.start(node, 1.0)
	node.free()
	expect(await freed.ticket.wait(self, 0.05) == "cancelled", "tree_exit_cancels_before_target_disappears")
	var a := Emitter.new()
	var b := Emitter.new()
	var batch := SignalBatch.new()
	expect(batch.begin([a.done, b.done]), "batch_accepts_distinct_signals")
	a.done.emit()
	expect(batch.ticket.status == "pending", "all_waits_for_every_event")
	b.done.emit()
	expect(await batch.wait(self, 0.05) == "completed", "all_completes_before_wait_registration")
	expect(not batch.begin([]), "batch_reentry_rejected")
	var empty := SignalBatch.new()
	empty.begin([])
	expect(await empty.wait(self, 0.05) == "completed", "empty_batch_completes")
	var duplicate := SignalBatch.new()
	expect(not duplicate.begin([a.done, a.done]), "duplicate_signal_rejected")
	var lost := SignalBatch.new()
	lost.begin([a.done, b.done])
	a.done.emit()
	b = null
	expect(await lost.wait(self, 0.02) == "timeout" and a.get_signal_connection_list("done").is_empty(), "lost_emitter_timeout_and_subscription_cleanup")
	finish()
