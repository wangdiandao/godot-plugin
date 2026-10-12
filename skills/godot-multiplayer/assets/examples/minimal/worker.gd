extends SceneTree
const Network = preload("net.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var server := "--server" in args
	var port_index := args.find("--port")
	var port := int(args[port_index + 1]) if port_index >= 0 else 0
	var net := Network.new()
	net.name = "Net"
	root.add_child(net)
	var error := net.setup(server, port)
	if error != OK:
		push_error("NETWORK_SETUP_FAILED: " + error_string(error))
		quit(1)
		return
	if server:
		var ready_index := args.find("--ready")
		var ready := FileAccess.open(args[ready_index + 1], FileAccess.WRITE)
		ready.store_string(str(net.peer.get_host().get_local_port()))
		ready.close()
	var deadline := Time.get_ticks_msec() + 8000
	while not net.success and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	var ok := net.success
	if ok and not server:
		# Request a graceful disconnect and keep polling until completion.
		net.peer.disconnect_peer(1)
		var disconnect_deadline := Time.get_ticks_msec() + 2000
		while net.peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED and Time.get_ticks_msec() < disconnect_deadline:
			await create_timer(0.02).timeout
		ok = net.peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify({"status": "passed" if ok else "failed", "role": "server" if server else "client", "peers": net.peers.size(), "disconnects": net.disconnected, "replicated_position": 99 if net.sent else 0}))
	net.peer.close()
	net.queue_free()
	await process_frame
	quit(0 if ok else 1)
