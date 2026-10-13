extends SceneTree
const Common = preload("../../shared/scripts/common.gd")
const ServerScript = preload("../../skills/godot-export/scripts/serve_web.gd")
var host = ServerScript.Host.new()
var result: Dictionary
var output: String

func _initialize() -> void:
	call_deferred("_run")

func request(target: String, method: String = "GET", authority: String = "", extra: String = "") -> Dictionary:
	var peer := StreamPeerTCP.new()
	var error := peer.connect_to_host("127.0.0.1", host.port)
	if error != OK:
		return {"error": error}
	var end := Time.get_ticks_msec() + 4000
	while peer.get_status() == StreamPeerTCP.STATUS_CONNECTING and Time.get_ticks_msec() < end:
		peer.poll()
		host.tick()
		await process_frame
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return {"error": ERR_TIMEOUT}
	var wire := (method + " " + target + " HTTP/1.1\r\nHost: " + ("127.0.0.1:" + str(host.port) if authority.is_empty() else authority) + "\r\n" + extra + "\r\n").to_utf8_buffer()
	var offset := 0
	var response := PackedByteArray()
	while Time.get_ticks_msec() < end:
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			break
		if offset < wire.size():
			var sent := peer.put_partial_data(wire.slice(offset))
			if sent[0] != OK:
				break
			offset += int(sent[1])
		host.tick()
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			break
		var available := peer.get_available_bytes()
		if available > 0:
			var packet := peer.get_partial_data(available)
			if packet[0] != OK:
				break
			response.append_array(packet[1])
		await process_frame
	peer.disconnect_from_host()
	var marker := response.get_string_from_ascii().find("\r\n\r\n")
	if marker < 0:
		return {"error": ERR_INVALID_DATA}
	var header := response.slice(0, marker).get_string_from_ascii()
	return {"code": int(header.get_slice(" ", 1)), "headers": header, "body": response.slice(marker + 4)}

func _run() -> void:
	result = Common.report("native_web_server")
	var args := Common.arguments()
	if not args.has("out"):
		Common.check(result, "explicit_output", false)
		Common.finish(self, result)
		return
	output = Common.absolute(str(args.out)).replace("\\", "/")
	var export_root := output.path_join("export")
	Common.check(result, "fixture_directory", DirAccess.make_dir_recursive_absolute(export_root) == OK)
	var index := FileAccess.open(export_root.path_join("index.html"), FileAccess.WRITE)
	index.store_string("<title>Native Web Fixture</title>")
	index.close()
	var bytes := PackedByteArray()
	bytes.resize(131073)
	for i in range(bytes.size()):
		bytes[i] = i % 251
	var binary := FileAccess.open(export_root.path_join("game.wasm"), FileAccess.WRITE)
	binary.store_buffer(bytes)
	binary.close()
	var secret := FileAccess.open(output.path_join("outside.json"), FileAccess.WRITE)
	secret.store_string("outside-root sentinel")
	secret.close()
	var error: Error = host.start(export_root, 0)
	Common.check(result, "loopback_server_listens_on_allocated_port", error == OK and host.port > 0)
	if error != OK:
		Common.finish(self, result, output.path_join("result.json"))
		return
	var page := await request("/")
	Common.check(result, "index_served", page.get("code") == 200 and page.get("body", PackedByteArray()).get_string_from_utf8() == "<title>Native Web Fixture</title>")
	var headers: String = page.get("headers", "")
	Common.check(result, "isolation_mime_and_no_cache_headers", headers.contains("Content-Type: text/html") and headers.contains("Cross-Origin-Opener-Policy: same-origin") and headers.contains("Cross-Origin-Embedder-Policy: require-corp") and headers.contains("Cache-Control: no-store"))
	var wasm := await request("/game.wasm?cache=ignored")
	Common.check(result, "binary_stream_preserves_all_bytes", wasm.get("code") == 200 and wasm.get("body") == bytes and str(wasm.get("headers", "")).contains("Content-Type: application/wasm"))
	var head := await request("/game.wasm", "HEAD")
	Common.check(result, "head_has_length_without_body", head.get("code") == 200 and head.get("body", PackedByteArray()).is_empty() and str(head.get("headers", "")).contains("Content-Length: " + str(bytes.size())))
	for target: String in ["/../outside.json", "/%2e%2e%2foutside.json", "/%252e%252e%252foutside.json", "/%2e%2e%5coutside.json"]:
		var blocked := await request(target)
		Common.check(result, "path_escape_rejected_" + str(result.checks.size()), blocked.get("code") == 403 and blocked.get("body", PackedByteArray()).is_empty(), {"target": target, "decoded": target.uri_decode(), "code": blocked.get("code")})
	var missing := await request("/missing.js")
	Common.check(result, "missing_artifact_is_404", missing.get("code") == 404)
	var foreign := await request("/", "GET", "foreign.example")
	Common.check(result, "foreign_host_rejected", foreign.get("code") == 403)
	var post := await request("/", "POST")
	Common.check(result, "write_method_rejected", post.get("code") == 405)
	var oversized := await request("/", "GET", "", "X-Large: " + "x".repeat(8300) + "\r\n")
	Common.check(result, "oversized_header_rejected", oversized.get("code") == 431)
	var after := await request("/")
	Common.check(result, "normal_requests_work_after_rejections", after.get("code") == 200)
	host.stop()
	Common.check(result, "listener_and_clients_stopped", not host.listener.is_listening() and host.clients.is_empty())
	var missing_host = ServerScript.Host.new()
	Common.check(result, "missing_export_root_rejected", missing_host.start(output.path_join("absent"), 0) == ERR_INVALID_PARAMETER and not missing_host.listener.is_listening())
	var child_output := output.path_join("lifetime")
	Common.check(result, "lifetime_output_created", DirAccess.make_dir_recursive_absolute(child_output) == OK)
	var log_path := child_output.path_join("engine.log")
	var server_script: Script = ServerScript
	var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", server_script.resource_path, "--log-file", log_path, "--", "--root", export_root, "--out", child_output, "--port", "0", "--seconds", "1"], false)
	var end := Time.get_ticks_msec() + 5000
	while pid > 0 and OS.is_process_running(pid) and Time.get_ticks_msec() < end:
		await create_timer(0.02).timeout
	var timed_out := pid > 0 and OS.is_process_running(pid)
	if timed_out:
		OS.kill(pid)
	var child_log := FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
	var child_report := Common.read_result(child_log)
	Common.check(result, "cli_server_exits_after_bounded_lifetime", pid > 0 and not timed_out and OS.get_process_exit_code(pid) == 0 and Common.log_errors(child_log).is_empty() and child_report.get("status") == "passed", {"log": log_path, "report": child_report, "timed_out": timed_out})
	Common.check(result, "cli_result_persisted", FileAccess.file_exists(child_output.path_join("result.json")))
	Common.finish(self, result, output.path_join("result.json"))
