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


class Dialogue extends Control:
	signal completed
	var data: Dictionary = {}
	var current := ""
	var label := RichTextLabel.new()
	var choices := VBoxContainer.new()
	var chosen := false
	var finishes := 0
	var generation := 0
	func _ready() -> void:
		label.size = Vector2(300, 80)
		add_child(label)
		choices.position = Vector2(0, 80)
		add_child(choices)
		hide()
	func start(graph: Variant, id: String) -> bool:
		# Validate the whole graph before replacing a live conversation.
		if not graph is Dictionary or not graph.has(id):
			return false
		for key: Variant in graph:
			var entry: Variant = graph[key]
			if not key is String or not entry is Dictionary or not entry.get("text") is String or not entry.get("choices", []) is Array:
				return false
			if entry.has("next") and (not entry.next is String or not graph.has(entry.next)):
				return false
			for option: Variant in entry.get("choices", []):
				if not option is Dictionary or not option.get("text") is String or not option.get("next") is String or not graph.has(option.next):
					return false
		data = graph.duplicate(true)
		show()
		present(id)
		return true
	func present(id: String) -> void:
		generation += 1
		current = id
		chosen = false
		label.text = data[id].text
		label.visible_characters = 0
		for child in choices.get_children():
			choices.remove_child(child)
			child.queue_free()
	func reveal_tick() -> void:
		if visible:
			label.visible_characters = mini(label.get_total_character_count(), label.visible_characters + 1)
	func reveal_all() -> void:
		label.visible_characters = -1
		if not choices.get_children().is_empty():
			return
		for option: Dictionary in data[current].get("choices", []):
			var button := Button.new()
			button.text = option.text
			button.pressed.connect(choose.bind(option.next, generation))
			choices.add_child(button)
		if choices.get_child_count() > 0:
			choices.get_child(0).call_deferred("grab_focus")
	func choose(id: String, ticket: int) -> void:
		if chosen or not visible or ticket != generation:
			return
		var allowed := false
		for option: Dictionary in data[current].get("choices", []):
			allowed = allowed or option.next == id
		if not allowed:
			return
		chosen = true
		present(id)
	func advance() -> void:
		if not visible:
			return
		if label.visible_characters != -1:
			reveal_all()
		elif choices.get_child_count() == 0:
			if data[current].has("next"):
				present(data[current].next)
			else:
				close(true)
	func close(success: bool = false) -> void:
		if not visible:
			return
		hide()
		generation += 1
		for child in choices.get_children():
			choices.remove_child(child)
			child.queue_free()
		if success:
			finishes += 1
			completed.emit()

func _run() -> void:
	root.size = Vector2i(320, 180)
	var dialogue := Dialogue.new()
	root.add_child(dialogue)
	var graph := {"start":{"text":"Hello traveller", "choices":[{"text":"Accept", "next":"reward"}, {"text":"Leave", "next":"bye"}]}, "reward":{"text":"Quest accepted"}, "bye":{"text":"Goodbye"}}
	expect(dialogue.start(graph, "start"), "valid_branch_graph_opens")
	dialogue.reveal_tick()
	expect(dialogue.label.visible_characters == 1, "typewriter_progress")
	dialogue.advance()
	await process_frame
	expect(dialogue.choices.get_child_count() == 2 and dialogue.choices.get_child(0).has_focus(), "skip_reveals_choices_and_keyboard_focus")
	var old_generation := dialogue.generation
	dialogue.choose("missing", dialogue.generation)
	expect(dialogue.current == "start", "invalid_choice_cannot_change_line")
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	Input.parse_input_event(press)
	press = InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = false
	Input.parse_input_event(press)
	await process_frame
	expect(dialogue.current == "reward", "keyboard_activation_selects_branch")
	dialogue.choose("bye", old_generation)
	expect(dialogue.current == "reward", "old_choice_callback_cannot_change_new_line")
	dialogue.advance()
	dialogue.advance()
	dialogue.advance()
	expect(not dialogue.visible and dialogue.finishes == 1, "completion_exactly_once")
	var invalid := graph.duplicate(true)
	invalid.start.choices[0].next = "missing"
	expect(not dialogue.start(invalid, "start") and not dialogue.visible, "dangling_branch_rejected")
	expect(not dialogue.start([], "start"), "invalid_graph_shape_rejected")
	for i in range(3):
		var completed_before := dialogue.finishes
		dialogue.start(graph, "start")
		dialogue.reveal_tick()
		dialogue.close()
		dialogue.reveal_tick()
		expect(not dialogue.visible and dialogue.label.visible_characters == 1 and dialogue.finishes == completed_before, "closed_dialogue_cannot_advance_or_complete")
		dialogue.start(graph, "bye")
		dialogue.advance()
		dialogue.advance()
	expect(dialogue.finishes == 4, "reopen_preserves_single_completion_per_run")
	dialogue.free()
	await process_frame
	finish()
