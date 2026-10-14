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



const Rules = preload("inventory_rules.gd")
const Views = preload("dialogue_view.gd")
class Session extends RefCounted:
	var inventory := Rules.Inventory.new()
	var claimed: Array[String] = []
	func _init() -> void:
		var reward := Rules.ItemDefinition.new()
		inventory.definitions = {"potion":reward}
	func claim(id: String) -> bool:
		if id != "herbs" or id in claimed or not inventory.add("potion", 1):
			return false
		claimed.append(id)
		return true
	func snapshot() -> Dictionary:
		return {"version":1,"inventory":inventory.snapshot(),"claimed":claimed.duplicate()}
	func restore(value: Variant) -> bool:
		if not value is Dictionary or value.get("version") != 1 or not value.get("claimed") is Array:
			return false
		var next: Array[String] = []
		for id: Variant in value.claimed:
			if not id is String or id != "herbs" or id in next:
				return false
			next.append(id)
		var probe := Rules.Inventory.new()
		probe.definitions = inventory.definitions
		if probe.restore(value.get("inventory")) != "loaded":
			return false
		inventory.restore(value.inventory)
		claimed = next
		return true

var reward_commands := 0
func complete(session: Session, dialogue: Views.Dialogue) -> void:
	if dialogue.current == "accept" and session.claim("herbs"):
		reward_commands += 1
func choose_and_finish(dialogue: Views.Dialogue) -> void:
	dialogue.advance()
	await process_frame
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = "ui_accept"
		event.pressed = pressed
		Input.parse_input_event(event)
	await process_frame
	dialogue.advance()
	dialogue.advance()
func _run() -> void:
	root.size = Vector2i(320, 180)
	var session := Session.new()
	var hud := Rules.Hud.new()
	root.add_child(hud)
	hud.bind_inventory(session.inventory)
	var dialogue := Views.Dialogue.new()
	root.add_child(dialogue)
	dialogue.completed.connect(complete.bind(session, dialogue))
	var graph := {"start":{"text":"Collect the herbs?", "choices":[{"text":"Accept", "next":"accept"},{"text":"Decline", "next":"decline"}]},"accept":{"text":"Here is one potion"},"decline":{"text":"Another time"}}
	dialogue.start(graph,"start")
	await choose_and_finish(dialogue)
	expect(reward_commands == 1 and session.inventory.counts.potion == 1 and hud.text == "HP 10 / Potions 1", "keyboard_dialogue_rule_reward_and_hud")
	dialogue.completed.emit()
	expect(reward_commands == 1 and session.inventory.counts.potion == 1, "duplicate_completion_cannot_duplicate_reward")
	var path := output.path_join("progress.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		expect(false,"progress_open")
	else:
		file.store_string(JSON.stringify(session.snapshot()))
		file.close()
		var restored := Session.new()
		expect(restored.restore(JSON.parse_string(FileAccess.get_file_as_string(path))), "combined_progress_reloaded")
		for i in range(3):
			dialogue.completed.disconnect(complete.bind(session, dialogue))
			session = restored
			hud.bind_inventory(session.inventory)
			dialogue.completed.connect(complete.bind(session, dialogue))
			dialogue.start(graph,"start")
			await choose_and_finish(dialogue)
			expect(reward_commands == 1 and session.inventory.counts.potion == 1, "restarted_conversation_preserves_claimed_reward")
		var snapshot := session.snapshot()
		expect(not session.restore({"version":1,"inventory":{"version":1,"health":20,"items":{}},"claimed":["unknown"]}) and session.snapshot() == snapshot, "invalid_quest_progress_rejected_without_partial_inventory_commit")
	hud.free()
	dialogue.free()
	await process_frame
	finish()
