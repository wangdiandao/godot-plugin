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

class Inbox extends Node:
	var value := 0
class Broker extends RefCounted:
	signal committed(value: int)
	var generation := 0
	var delivering := false
	func cancel() -> void:
		generation += 1
	func request(tree: SceneTree, target: Node, value: int, frames: int) -> void:
		generation += 1
		var ticket := generation
		var receiver: WeakRef = weakref(target)
		for i in range(frames):
			await tree.process_frame
		var live = receiver.get_ref()
		if ticket != generation or not is_instance_valid(live) or not live.is_inside_tree() or value < 0:
			return
		live.value = value
		committed.emit(value)
	func command(target: Inbox, value: int) -> bool:
		if delivering or value < 0:
			return false
		delivering = true
		target.value = value
		committed.emit(value)
		delivering = false
		return true
var notifications := 0
var rejected_reentry := false
func _run() -> void:
	var inbox := Inbox.new()
	root.add_child(inbox)
	var broker := Broker.new()
	var listener := func(value: int):
		notifications += 1
		if value == 5:
			rejected_reentry = not broker.command(inbox, 999)
	broker.committed.connect(listener)
	broker.request(self, inbox, 1, 4)
	broker.request(self, inbox, 2, 1)
	for i in range(6):
		await process_frame
	expect(inbox.value == 2 and notifications == 1, "superseded_request_cannot_commit")
	broker.request(self, inbox, 3, 2)
	broker.cancel()
	for i in range(4):
		await process_frame
	expect(inbox.value == 2 and notifications == 1, "explicit_cancel_preserves_state")
	broker.request(self, inbox, 4, 2)
	root.remove_child(inbox)
	for i in range(4):
		await process_frame
	expect(inbox.value == 2, "detached_receiver_cannot_commit")
	root.add_child(inbox)
	expect(broker.command(inbox, 5) and rejected_reentry and inbox.value == 5, "synchronous_reentry_rejected")
	broker.committed.disconnect(listener)
	broker.request(self, inbox, 8, 2)
	inbox.free()
	for i in range(4):
		await process_frame
	expect(notifications == 2, "freed_receiver_and_listener_cleanup")
	finish()
