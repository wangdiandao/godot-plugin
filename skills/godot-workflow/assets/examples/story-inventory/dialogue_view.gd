extends RefCounted
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
