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

func _run() -> void:
	var definition := ItemDefinition.new()
	var a := Inventory.new()
	var b := Inventory.new()
	a.definitions = {definition.id: definition}
	b.definitions = a.definitions
	var hud := Hud.new()
	root.add_child(hud)
	hud.bind_inventory(a)
	expect(hud.text == "HP 10 / Potions 0", "hud_reads_initial_state")
	expect(a.add("potion", 2) and a.use("potion") and a.health == 15 and a.counts.potion == 1, "pickup_stack_use_updates_rules")
	expect(hud.text == "HP 15 / Potions 1" and b.counts.is_empty() and definition.heal == 5, "independent_runtime_state_shared_definition")
	var before := a.snapshot()
	expect(not a.add("potion", 3) and not a.add("unknown", 1) and not a.add("potion", -1) and a.snapshot() == before, "invalid_commands_preserve_state")
	var path := output.path_join("inventory.json")
	expect(a.save(path) == "saved", "staged_inventory_commit")
	expect(b.restore(JSON.parse_string(FileAccess.get_file_as_string(path))) == "loaded" and b.snapshot() == a.snapshot(), "json_roundtrip_stable_ids_not_resource_objects")
	var future := '{"version":99,"health":19,"items":{"potion":1}}'
	var future_path := output.path_join("future.json")
	var file := FileAccess.open(future_path, FileAccess.WRITE)
	if file != null:
		file.store_string(future)
		file.close()
		var fingerprint := FileAccess.get_sha256(future_path)
		expect(b.restore(JSON.parse_string(future)) == "unsupported_or_invalid" and a.save(future_path) == "protected" and FileAccess.get_sha256(future_path) == fingerprint, "future_save_preserved_against_commit")
	else:
		expect(false, "future_save_open")
	for invalid: Variant in [null, [], {"version":1,"health":10.5,"items":{}}, {"version":1,"health":20,"items":{"missing":1}}, {"version":1,"health":20,"items":{"potion":4}}]:
		before = b.snapshot()
		expect(b.restore(invalid) != "loaded" and b.snapshot() == before, "invalid_snapshot_rejected_atomically")
	hud.bind_inventory(b)
	var text := hud.text
	a.changed.emit()
	expect(hud.text == text and a.get_signal_connection_list("changed").is_empty(), "old_inventory_disconnected")
	for i in range(3):
		b.restore({"version":1,"health":10,"items":{}})
		b.add("potion", 1)
		b.use("potion")
		expect(hud.text == "HP 15 / Potions 0", "repeat_reset_and_use")
	hud.free()
	expect(b.get_signal_connection_list("changed").is_empty(), "hud_teardown_disconnects")
	finish()
