extends RefCounted
class ItemDefinition extends Resource:
	var id := "potion"
	var max_stack := 3
	var heal := 5
class Inventory extends RefCounted:
	signal changed
	var definitions: Dictionary = {}
	var counts: Dictionary = {}
	var health := 10
	var max_health := 20
	func add(id: String, amount: int) -> bool:
		if not definitions.has(id) or amount <= 0:
			return false
		var total := int(counts.get(id, 0)) + amount
		if total > definitions[id].max_stack:
			return false
		counts[id] = total
		changed.emit()
		return true
	func use(id: String) -> bool:
		if not definitions.has(id) or int(counts.get(id, 0)) <= 0 or health >= max_health:
			return false
		counts[id] -= 1
		health = mini(max_health, health + definitions[id].heal)
		changed.emit()
		return true
	func snapshot() -> Dictionary:
		return {"version": 1, "health": health, "items": counts.duplicate()}
	func save(path: String) -> String:
		if FileAccess.file_exists(path):
			var probe := Inventory.new()
			probe.definitions = definitions
			if probe.restore(JSON.parse_string(FileAccess.get_file_as_string(path))) != "loaded":
				return "protected"
		var original := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
		var staged := path + ".pending"
		var backup := path + ".backup"
		if FileAccess.file_exists(staged) or FileAccess.file_exists(backup):
			return "conflict"
		var file := FileAccess.open(staged, FileAccess.WRITE)
		if file == null:
			return "write_failed"
		file.store_string(JSON.stringify(snapshot()))
		file.flush()
		file.close()
		var verified := Inventory.new()
		verified.definitions = definitions
		if verified.restore(JSON.parse_string(FileAccess.get_file_as_string(staged))) != "loaded":
			return "verification_failed"
		var staged_hash := FileAccess.get_sha256(staged)
		var current := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
		if original != current:
			return "conflict"
		if original != "" and DirAccess.rename_absolute(path, backup) != OK:
			return "backup_failed"
		if DirAccess.rename_absolute(staged, path) != OK:
			if original != "" and not FileAccess.file_exists(path):
				if DirAccess.rename_absolute(backup, path) != OK:
					return "recovery_required"
			return "commit_failed"
		return "saved" if FileAccess.get_sha256(path) == staged_hash else "verification_failed"
	func restore(data: Variant) -> String:
		if not data is Dictionary or data.get("version") != 1:
			return "unsupported_or_invalid"
		if not data.get("items") is Dictionary or not valid_integer(data.get("health"), 0, max_health):
			return "invalid"
		for id: Variant in data.items:
			if not id is String or not definitions.has(id) or not valid_integer(data.items[id], 0, definitions[id].max_stack):
				return "invalid"
		# Commit only after every field passed; no partial restoration.
		var normalized: Dictionary = {}
		for id: String in data.items:
			normalized[id] = int(data.items[id])
		counts = normalized
		health = int(data.health)
		changed.emit()
		return "loaded"
	func valid_integer(value: Variant, low: int, high: int) -> bool:
		return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

class Hud extends Label:
	var inventory: Inventory
	var update_callback: Callable
	func bind_inventory(model: Inventory) -> void:
		if inventory != null and inventory.changed.is_connected(update_callback):
			inventory.changed.disconnect(update_callback)
		inventory = model
		update_callback = refresh
		inventory.changed.connect(update_callback)
		refresh()
	func refresh() -> void:
		text = "HP %d / Potions %d" % [inventory.health, inventory.counts.get("potion", 0)]
	func _exit_tree() -> void:
		if inventory != null and inventory.changed.is_connected(update_callback):
			inventory.changed.disconnect(update_callback)
