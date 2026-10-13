extends SceneTree
var children: Array[int] = []
var output: String
func _initialize() -> void:
	call_deferred("_run")
func launch(arguments: PackedStringArray, label: String) -> int:
	var flags: PackedStringArray = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", ProjectSettings.globalize_path("res://worker.gd"), "--log-file", output.path_join(label + ".log"), "--"]
	flags.append_array(arguments)
	var pid := OS.create_process(OS.get_executable_path(), flags, false)
	if pid > 0:
		children.append(pid)
	return pid
func cleanup() -> void:
	for pid: int in children:
		if OS.is_process_running(pid):
			OS.kill(pid)
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--out")
	output = args[index + 1] if index >= 0 and index + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/multiplayer")
	output = output.replace("\\", "/")
	DirAccess.make_dir_recursive_absolute(output)
	var ready_path := output.path_join("port-" + str(OS.get_process_id()) + ".txt")
	var server_pid := launch(["--server", "--ready", ready_path], "server")
	var deadline := Time.get_ticks_msec() + 4000
	while not FileAccess.file_exists(ready_path) and Time.get_ticks_msec() < deadline and server_pid > 0 and OS.is_process_running(server_pid):
		await create_timer(0.02).timeout
	if not FileAccess.file_exists(ready_path):
		cleanup()
		push_error("SERVER_NOT_READY")
		quit(1)
		return
	var port := FileAccess.get_file_as_string(ready_path)
	launch(["--port", port], "client1")
	launch(["--port", port], "client2")
	deadline = Time.get_ticks_msec() + 10000
	# First two clients finish, then reconnect a fresh process to the same server.
	for pid: int in children.slice(1):
		while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
			await create_timer(0.02).timeout
	launch(["--port", port], "client3")
	deadline = Time.get_ticks_msec() + 10000
	for pid: int in children:
		while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
			await create_timer(0.02).timeout
	var checks: Array = []
	var ok := children.size() == 4
	var labels := ["server", "client1", "client2", "client3"]
	for i in range(children.size()):
		var log_text := FileAccess.get_file_as_string(output.path_join(labels[i] + ".log"))
		var passed := not OS.is_process_running(children[i]) and OS.get_process_exit_code(children[i]) == 0 and not log_text.contains("ERROR:") and log_text.contains('"status":"passed"')
		checks.append({"name": labels[i], "passed": passed, "log": output.path_join(labels[i] + ".log")})
		ok = ok and passed
	cleanup()
	var result := {"schema_version": 1, "status": "passed" if ok else "failed", "engine": Engine.get_version_info(), "checks": checks, "scope": "loopback: server + 2 clients + reconnect, authoritative bounds/ownership/budget rejection, spawn, property replication, RPC, disconnect"}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	quit(0 if ok else 1)
