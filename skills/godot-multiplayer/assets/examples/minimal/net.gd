extends Node
var peer := ENetMultiplayerPeer.new()
var spawner: MultiplayerSpawner
var actors: Node
var server: bool
var peers: Dictionary = {}
var disconnected: int = 0
var sent: bool = false
var success: bool = false

func setup(is_server: bool, port: int) -> Error:
	server = is_server
	actors = Node.new()
	actors.name = "Actors"
	add_child(actors)
	spawner = MultiplayerSpawner.new()
	spawner.name = "Spawner"
	add_child(spawner)
	spawner.spawn_path = NodePath("../Actors")
	spawner.spawn_function = _spawn_actor
	multiplayer.peer_connected.connect(_connected)
	multiplayer.peer_disconnected.connect(_disconnected)
	if server:
		peer.set_bind_ip("127.0.0.1")
	var error := peer.create_server(port, 2) if server else peer.create_client("127.0.0.1", port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
	return error

func _spawn_actor(_data: Variant) -> Node:
	var actor := Node2D.new()
	actor.name = "Actor"
	actor.position = Vector2(42, 7)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.root_path = NodePath("..")
	var config := SceneReplicationConfig.new()
	config.add_property(NodePath(".:position"))
	config.property_set_replication_mode(NodePath(".:position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	sync.replication_config = config
	actor.add_child(sync)
	return actor

func _connected(_id: int) -> void:
	if server and multiplayer.get_peers().size() == 2:
		spawner.spawn(null)
		# Observe a later property update, not just the spawn payload.
		await get_tree().create_timer(0.2).timeout
		(actors.get_node("Actor") as Node2D).position = Vector2(99, 7)

func _process(_delta: float) -> void:
	if not server and not sent and actors.has_node("Actor"):
		if (actors.get_node("Actor") as Node2D).position.is_equal_approx(Vector2(99, 7)):
			sent = true
			confirm_state.rpc_id(1, 99)

@rpc("any_peer", "call_remote", "reliable")
func confirm_state(value: int) -> void:
	if not server:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender > 1 and sender in multiplayer.get_peers() and value == 99:
		peers[sender] = value
		if peers.size() == 2:
			# Stop replication before asking clients to disconnect.
			var sync := actors.get_node("Actor/Sync")
			sync.queue_free()
			await get_tree().process_frame
			# Release clients one at a time so disconnect relay cannot target
			# another client that has closed but has not been polled yet.
			acknowledge.rpc_id(int(peers.keys()[0]), value)

@rpc("authority", "call_remote", "reliable")
func acknowledge(value: int) -> void:
	success = not server and value == 99 and sent

func _disconnected(id: int) -> void:
	if server and peers.has(id):
		disconnected += 1
		if disconnected == 1 and peers.size() == 2:
			for other: int in peers:
				if other != id:
					acknowledge.rpc_id(other, 99)
		success = peers.size() == 2 and disconnected == 2
