extends Node
var peer := ENetMultiplayerPeer.new()
var spawner: MultiplayerSpawner
var actors: Node
var server: bool
var peers: Dictionary = {}
var disconnected: int = 0
var sent: bool = false
var success: bool = false
var budgets: Dictionary = {}
var rejected: int = 0
const SESSION_EPOCH := 7 # Fixture value; production uses a fresh server-issued epoch.

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
		(multiplayer as SceneMultiplayer).server_relay = false
	var error := peer.create_server(port, 2) if server else peer.create_client("127.0.0.1", port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
	return error

func _spawn_actor(_data: Variant) -> Node:
	var actor := Node2D.new()
	actor.name = "Actor"
	actor.position = Vector2(42, 7)
	actor.add_child(_make_sync())
	return actor

func _make_sync() -> MultiplayerSynchronizer:
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.root_path = NodePath("..")
	var config := SceneReplicationConfig.new()
	config.add_property(NodePath(".:position"))
	config.property_set_replication_mode(NodePath(".:position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	sync.replication_config = config
	return sync

func _connected(_id: int) -> void:
	if server and multiplayer.get_peers().size() == 2 and not actors.has_node("Actor"):
		spawner.spawn(null)
		# Observe a later property update, not just the spawn payload.
		await get_tree().create_timer(0.2).timeout
		(actors.get_node("Actor") as Node2D).position = Vector2(99, 7)

func _process(_delta: float) -> void:
	if not server and not sent and actors.has_node("Actor"):
		if (actors.get_node("Actor") as Node2D).position.is_equal_approx(Vector2(99, 7)):
			sent = true
			var owner_id := multiplayer.get_unique_id()
			confirm_state.rpc_id(1, -1, owner_id, SESSION_EPOCH)
			confirm_state.rpc_id(1, 99, owner_id + 1, SESSION_EPOCH)
			confirm_state.rpc_id(1, 99, owner_id, SESSION_EPOCH)
			confirm_state.rpc_id(1, 99, owner_id, SESSION_EPOCH) # Over budget.

@rpc("any_peer", "call_remote", "reliable", 1)
func confirm_state(value: int, owner_id: int, epoch: int) -> void:
	if not server:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 1 or sender not in multiplayer.get_peers():
		rejected += 1
		return
	budgets[sender] = int(budgets.get(sender, 0)) + 1
	if int(budgets[sender]) > 3 or owner_id != sender or epoch != SESSION_EPOCH or value < 0 or value > 100:
		rejected += 1
		return
	if value == 99 and (actors.get_node("Actor") as Node2D).position.x == 99:
		peers[sender] = value
		if peers.size() == 2:
			# Stop replication before asking clients to disconnect.
			var sync := actors.get_node("Actor/Sync")
			sync.queue_free()
			await get_tree().process_frame
			# Release clients one at a time so disconnect relay cannot target
			# another client that has closed but has not been polled yet.
			acknowledge.rpc_id(int(peers.keys()[0]), value)
		elif peers.size() == 3 and disconnected == 2:
			actors.get_node("Actor/Sync").queue_free()
			await get_tree().process_frame
			acknowledge.rpc_id(sender, value)

@rpc("authority", "call_remote", "reliable", 1)
func acknowledge(value: int) -> void:
	success = not server and value == 99 and sent

func _disconnected(id: int) -> void:
	if server and peers.has(id):
		disconnected += 1
		budgets.erase(id)
		if disconnected == 1 and peers.size() == 2:
			for other: int in peers:
				if other != id:
					acknowledge.rpc_id(other, 99)
		if disconnected == 2:
			actors.get_node("Actor").add_child(_make_sync())
		success = peers.size() == 3 and disconnected == 3 and rejected == 9
