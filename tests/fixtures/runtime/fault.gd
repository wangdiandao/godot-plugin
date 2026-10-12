extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[args.find("--mode") + 1]
	match mode:
		"runtime":
			push_error("INJECTED_RUNTIME_ERROR")
			print('GODOT_PLUGIN_RESULT:{"status":"passed"}')
			quit(0)
		"missing-report":
			print("MISSING_REPORT")
			quit(0)
		"timeout":
			print("BEFORE_TIMEOUT")
		"missing-resource":
			var resource := ResourceLoader.load("res://missing-source.tres")
			print("MISSING_SOURCE_DETECTED: ", resource == null)
			quit(1)
		"broken-reference":
			var scene := ResourceLoader.load("res://broken-reference.tscn")
			print("BROKEN_REFERENCE_DETECTED: ", scene == null)
			quit(1)
		"save-failure":
			var output := args[args.find("--out") + 1]
			var protected_path := output.path_join("unrelated.txt")
			var file := FileAccess.open(protected_path, FileAccess.WRITE)
			file.store_string("PRESERVE_ME")
			file.close()
			var before := FileAccess.get_sha256(protected_path)
			var error := ResourceSaver.save(Gradient.new(), output.path_join("missing-parent/resource.tres"))
			var preserved := FileAccess.get_sha256(protected_path) == before
			print("INJECTED_SAVE_FAILURE: ", error_string(error))
			print("GODOT_PLUGIN_RESULT:" + JSON.stringify({"status": "passed" if error != OK and preserved else "failed", "checks": [{"name": "unrelated_file_preserved", "passed": preserved}, {"name": "save_error_detected", "passed": error != OK}]}))
			quit(0 if error != OK and preserved else 1)
		_:
			quit(1)
