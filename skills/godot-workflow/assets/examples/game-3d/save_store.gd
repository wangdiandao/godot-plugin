extends RefCounted
## Single-writer example: fingerprints detect intervening edits, not atomic locks.
var path: String
var status := "not_loaded"
var fingerprint := ""

func whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

func read_file(target: String) -> Dictionary:
	if not FileAccess.file_exists(target):
		return {"status": "missing"}
	var file := FileAccess.open(target, FileAccess.READ)
	if file == null:
		return {"status": "io_error"}
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK:
		return {"status": "corrupt"}
	var data: Variant = parser.data
	if not data is Dictionary or not whole(data.get("version"), 1, 9007199254740991):
		return {"status": "invalid"}
	if data.version > 1:
		return {"status": "unsupported"}
	if not whole(data.get("best"), 0, 3):
		return {"status": "invalid"}
	return {"status": "ok", "best": int(data.best)}

func load_path(target: String) -> Dictionary:
	path = target
	var result := read_file(path)
	status = result.status
	fingerprint = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	return result

func commit(best: int) -> String:
	if status not in ["missing", "ok"]:
		return "write_blocked:" + status
	if best < 0 or best > 3:
		return "invalid"
	var current := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	if current != fingerprint:
		status = "conflict"
		return status
	var stage := path + ".tmp-" + str(OS.get_process_id()) + "-" + str(Time.get_ticks_usec())
	var file := FileAccess.open(stage, FileAccess.WRITE)
	if file == null:
		return "write_failed"
	file.store_string(JSON.stringify({"version": 1, "best": best}))
	file.flush()
	var error := file.get_error()
	file.close()
	var staged := read_file(stage)
	if error != OK or staged.status != "ok" or staged.best != best:
		return "stage_invalid"
	# Recheck after staging. A single owner is still required across this sequence.
	current = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	if current != fingerprint:
		status = "conflict"
		return status
	var backup := path + ".bak"
	if FileAccess.file_exists(backup):
		return "backup_conflict"
	var had_save := FileAccess.file_exists(path)
	if had_save and read_file(path).status != "ok":
		status = "target_invalid"
		return status
	if had_save and DirAccess.rename_absolute(path, backup) != OK:
		return "backup_failed"
	if DirAccess.rename_absolute(stage, path) != OK:
		if had_save and not FileAccess.file_exists(path):
			if DirAccess.rename_absolute(backup, path) != OK:
				status = "recovery_required"
		return "commit_failed:" + status
	var readback := read_file(path)
	if readback.status != "ok" or readback.best != best:
		status = "recovery_required"
		return status
	status = "ok"
	fingerprint = FileAccess.get_sha256(path)
	if had_save and DirAccess.remove_absolute(backup) != OK:
		return "backup_cleanup_failed"
	return "ok"
