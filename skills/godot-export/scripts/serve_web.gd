extends SceneTree
## Temporary loopback-only server for flat Godot Web export artifacts.

class Host extends RefCounted:
	const CHUNK := 65536
	const HEADER_LIMIT := 8192
	var listener := TCPServer.new()
	var directory: String
	var port: int
	var clients: Array[Dictionary] = []
	var responses: Dictionary = {}
	var allowed: Array[String] = []

	func start(export_root: String, requested_port: int) -> Error:
		if listener.is_listening() or not clients.is_empty():
			return ERR_ALREADY_IN_USE
		allowed.clear()
		directory = export_root.replace("\\", "/").simplify_path()
		if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory) or requested_port < 0 or requested_port > 65535:
			return ERR_INVALID_PARAMETER
		var parent := DirAccess.open(directory.get_base_dir())
		if parent == null or parent.is_link(directory.get_file()):
			return ERR_INVALID_PARAMETER
		var files := DirAccess.open(directory)
		for name: String in files.get_files():
			if not name.begins_with(".") and name.get_extension() in ["html", "js", "wasm", "pck", "png", "svg", "ico", "json", "webmanifest"] and not files.is_link(name):
				allowed.append(name)
		if "index.html" not in allowed:
			return ERR_FILE_NOT_FOUND
		var error := listener.listen(requested_port, "127.0.0.1")
		if error == OK:
			port = listener.get_local_port()
		return error

	func stop() -> void:
		listener.stop()
		for client: Dictionary in clients:
			client.peer.disconnect_from_host()
			client.file = null
		clients.clear()

	func tick() -> void:
		while listener.is_connection_available():
			var peer := listener.take_connection()
			if clients.size() >= 16:
				peer.disconnect_from_host()
				continue
			clients.append({"peer": peer, "request": PackedByteArray(), "buffer": PackedByteArray(), "offset": 0, "file": null, "responding": false, "deadline": Time.get_ticks_msec() + 10000})
		for index in range(clients.size() - 1, -1, -1):
			var client := clients[index]
			var peer: StreamPeerTCP = client.peer
			peer.poll()
			var done := Time.get_ticks_msec() >= int(client.deadline) or peer.get_status() != StreamPeerTCP.STATUS_CONNECTED
			if not done and not client.responding:
				var available := peer.get_available_bytes()
				if available > 0:
					var packet := peer.get_partial_data(mini(available, HEADER_LIMIT + 1))
					if packet[0] != OK:
						done = true
					else:
						client.request.append_array(packet[1])
						if client.request.size() > HEADER_LIMIT:
							respond(client, 431, "Request Header Fields Too Large")
						elif client.request.get_string_from_ascii().contains("\r\n\r\n"):
							prepare(client)
			if not done and client.responding:
				if int(client.offset) >= client.buffer.size():
					if client.file != null and client.file.get_position() < client.file.get_length():
						client.buffer = client.file.get_buffer(CHUNK)
						client.offset = 0
					else:
						done = true
				if not done:
					var sent := peer.put_partial_data(client.buffer.slice(int(client.offset)))
					if sent[0] != OK:
						done = true
					else:
						client.offset += int(sent[1])
			if done:
				peer.disconnect_from_host()
				client.file = null
				clients.remove_at(index)

	func prepare(client: Dictionary) -> void:
		var lines: PackedStringArray = client.request.get_string_from_ascii().split("\r\n")
		var first: PackedStringArray = lines[0].split(" ", false)
		if first.size() != 3 or first[2] not in ["HTTP/1.0", "HTTP/1.1"]:
			respond(client, 400, "Bad Request")
			return
		var host_header := ""
		for line: String in lines:
			if line.to_lower().begins_with("host:"):
				if not host_header.is_empty():
					respond(client, 400, "Bad Request")
					return
				host_header = line.substr(5).strip_edges().to_lower()
		if host_header not in ["127.0.0.1:" + str(port), "localhost:" + str(port)]:
			respond(client, 403, "Forbidden")
			return
		if first[0] not in ["GET", "HEAD"]:
			respond(client, 405, "Method Not Allowed")
			return
		# Flat artifact names only. Reject percent escapes before decoding: the
		# verified baseline does not decode lower-case hex escapes consistently.
		var target: String = first[1].get_slice("?", 0)
		if target.contains("%"):
			respond(client, 403, "Forbidden")
			return
		if not target.begins_with("/"):
			respond(client, 400, "Bad Request")
			return
		var name: String = target.substr(1)
		if name.is_empty():
			name = "index.html"
		if name.contains("/") or name.contains("\\") or name.contains("%") or not name.is_valid_filename() or name.begins_with("."):
			respond(client, 403, "Forbidden")
			return
		var files := DirAccess.open(directory)
		if name not in allowed or files.is_link(name):
			respond(client, 404, "Not Found")
			return
		var file := FileAccess.open(directory.path_join(name), FileAccess.READ)
		if file == null:
			respond(client, 404, "Not Found")
			return
		var types := {"html": "text/html; charset=utf-8", "js": "text/javascript", "wasm": "application/wasm", "pck": "application/octet-stream", "png": "image/png", "svg": "image/svg+xml", "ico": "image/x-icon", "json": "application/json", "webmanifest": "application/manifest+json"}
		respond(client, 200, "OK", file.get_length(), types.get(name.get_extension(), "application/octet-stream"))
		if first[0] == "GET":
			client.file = file

	func respond(client: Dictionary, code: int, reason: String, length: int = 0, content_type: String = "text/plain") -> void:
		responses[str(code)] = int(responses.get(str(code), 0)) + 1
		var header := "HTTP/1.1 %d %s\r\nContent-Length: %d\r\nContent-Type: %s\r\nConnection: close\r\nCache-Control: no-store\r\nCross-Origin-Opener-Policy: same-origin\r\nCross-Origin-Embedder-Policy: require-corp\r\nCross-Origin-Resource-Policy: same-origin\r\nX-Content-Type-Options: nosniff\r\n\r\n" % [code, reason, length, content_type]
		client.buffer = header.to_utf8_buffer()
		client.offset = 0
		client.responding = true

var host := Host.new()
var output: String
var deadline: int

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var values: Dictionary = {}
	if args.size() % 2 != 0:
		push_error("WEB_SERVER_ARGUMENTS_REQUIRED")
		quit(1)
		return
	for index in range(0, args.size(), 2):
		values[args[index]] = args[index + 1]
	if not values.has_all(["--root", "--out"]) or not str(values.get("--port", "8080")).is_valid_int() or not str(values.get("--seconds", "300")).is_valid_int():
		push_error("WEB_SERVER_ARGUMENTS_REQUIRED")
		quit(1)
		return
	var seconds := int(values.get("--seconds", "300"))
	output = str(values["--out"]).replace("\\", "/").simplify_path()
	if seconds < 1 or seconds > 3600 or not output.is_absolute_path() or DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("WEB_SERVER_OUTPUT_OR_DURATION_INVALID")
		quit(1)
		return
	var error := host.start(str(values["--root"]), int(values.get("--port", "8080")))
	if error != OK:
		push_error("WEB_SERVER_START_FAILED: " + error_string(error))
		quit(1)
		return
	deadline = Time.get_ticks_msec() + seconds * 1000
	print("GODOT_WEB_SERVER_READY:" + JSON.stringify({"url": "http://127.0.0.1:" + str(host.port) + "/", "duration_seconds": seconds}))

func _process(_delta: float) -> bool:
	host.tick()
	if Time.get_ticks_msec() >= deadline:
		var responses := host.responses.duplicate()
		host.stop()
		var report := {"schema_version": 1, "status": "passed", "operation": "bounded_web_serving", "engine": Engine.get_version_info(), "checks": [{"name": "loopback_server_completed_bounded_lifetime", "status": "passed"}], "responses": responses, "limitations": ["HTTP serving alone does not prove browser gameplay, storage, audio or performance acceptance."]}
		var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
		if file == null:
			push_error("REPORT_WRITE_FAILED")
			quit(1)
			return true
		file.store_string(JSON.stringify(report, "\t") + "\n")
		file.close()
		print("GODOT_PLUGIN_RESULT:" + JSON.stringify(report))
		quit(0)
	return false
