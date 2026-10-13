extends SceneTree
var checks: Array = []
var output: String
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

func whole(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum
func migrate(value: Variant) -> Dictionary:
	if not value is Dictionary or not whole(value.get("version"), 1, 2):
		return {}
	if int(value.version) == 1:
		if not whole(value.get("score"), 0, 1000000):
			return {}
		return {"version": 2, "progress": {"score": int(value.score)}}
	if not value.get("progress") is Dictionary or not whole(value.progress.get("score"), 0, 1000000):
		return {}
	return {"version": 2, "progress": {"score": int(value.progress.score)}}
func read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": "missing"}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"status": "io_error"}
	var parser := JSON.new()
	var error := parser.parse(f.get_as_text())
	f.close()
	if error != OK:
		return {"status": "corrupt", "line": parser.get_error_line()}
	var raw: Variant = parser.data
	if raw is Dictionary and whole(raw.get("version"), 3, 9007199254740991):
		return {"status": "unsupported"}
	var valid := migrate(raw)
	return {"status": "invalid"} if valid.is_empty() else {"status": "ok", "data": valid}
func commit(path: String, data: Dictionary, expected_hash: String) -> String:
	if migrate(data).is_empty():
		return "invalid"
	var stage := path + ".tmp-" + str(Time.get_ticks_usec())
	var file := FileAccess.open(stage, FileAccess.WRITE)
	if file == null:
		return "write_failed"
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if read_save(stage).status != "ok":
		return "stage_invalid"
	var existing := FileAccess.file_exists(path)
	var actual := FileAccess.get_sha256(path) if existing else ""
	if actual != expected_hash:
		return "conflict"
	var backup := path + ".bak"
	if existing:
		if read_save(path).status != "ok":
			return "target_invalid"
		if DirAccess.copy_absolute(path, backup) != OK or read_save(backup).status != "ok":
			return "backup_failed"
	if DirAccess.rename_absolute(stage, path) != OK:
		return "rename_failed"
	return "ok" if read_save(path).status == "ok" else "readback_failed"
func recover(path: String) -> Dictionary:
	var current := read_save(path)
	if current.status == "ok" or current.status == "unsupported":
		return current
	var backup := read_save(path + ".bak")
	if backup.status == "ok":
		return {"status": "recovered", "data": backup.data, "original_status": current.status}
	return {"status": "recovery_required", "original_status": current.status}
func put(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true
func _run() -> void:
	var path := output.path_join("save.json")
	expect(read_save(path).status == "missing", "missing_distinguished")
	expect(put(path, JSON.stringify({"version": 1, "score": 7})), "legacy_fixture_written")
	var current := read_save(path)
	expect(current.status == "ok" and current.data.progress.score == 7, "save_version_migration")
	expect(commit(path, current.data, FileAccess.get_sha256(path)) == "ok", "migration_commit")
	expect(read_save(path).data.version == 2, "saved_version_readback")
	for invalid: Variant in [{"version": 2, "progress": {}}, {"version": 1.5, "score": 3}, {"version": 1, "score": 3.5}, {"version": 1, "score": -1}, {"version": 1, "score": NAN}, [1, 2]]:
		expect(migrate(invalid).is_empty(), "invalid_schema_rejected_" + str(checks.size()))
	expect(migrate({"version": 99}).is_empty(), "future_version_rejected")
	var expected_hash := FileAccess.get_sha256(path)
	expect(put(path, JSON.stringify({"version": 2, "progress": {"score": 11}})), "concurrent_change_fixture")
	var changed_hash := FileAccess.get_sha256(path)
	expect(commit(path, current.data, expected_hash) == "conflict", "concurrent_write_detected")
	expect(FileAccess.get_sha256(path) == changed_hash, "conflict_target_preserved")
	expect(commit(path, {"version": 2, "progress": {"score": 19}}, changed_hash) == "ok", "valid_commit_backed_up")
	expect(read_save(path).data.progress.score == 19 and read_save(path + ".bak").data.progress.score == 11, "target_backup_readback")
	expect(put(path, "{broken"), "corruption_fixture_written")
	var corruption_hash := FileAccess.get_sha256(path)
	expect(read_save(path).status == "corrupt", "corruption_detected")
	var restored := recover(path)
	expect(restored.status == "recovered" and restored.data.progress.score == 11, "validated_backup_recovery")
	expect(FileAccess.get_sha256(path) == corruption_hash, "corrupt_original_preserved")
	expect(put(path, JSON.stringify({"version": 99, "new_data": "keep"})), "future_fixture_written")
	var future_hash := FileAccess.get_sha256(path)
	expect(recover(path).status == "unsupported" and FileAccess.get_sha256(path) == future_hash, "future_save_preserved")
	expect(put(path, JSON.stringify({"version": 1000001})), "large_future_fixture_written")
	var large_future_hash := FileAccess.get_sha256(path)
	expect(recover(path).status == "unsupported" and FileAccess.get_sha256(path) == large_future_hash, "large_future_save_preserved")
	var blocked := output.path_join("missing-parent").path_join("save.json")
	expect(commit(blocked, current.data, "") == "write_failed", "write_failure_detected")
	expect(not FileAccess.file_exists(blocked), "write_failure_no_target")
	expect(put(path + ".bak", "null") and put(path, "{broken"), "both_invalid_fixture")
	expect(recover(path).status == "recovery_required", "invalid_backup_not_used")
	finish()
