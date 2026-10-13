# Native Multiplayer: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Develop an authoritative module

Choose server-authoritative ENet for a native realtime client/server game when UDP is supported. Web cannot use ordinary ENet UDP; select the documented WebSocket/WebRTC topology and required signaling/servers instead. Local success does not prove firewall/NAT traversal or public deployment. Create_server/create_client return Error: check immediately, then connect lifecycle signals before assigning the peer. Send only after connected_to_server; connection_failed and server_disconnected must cancel pending state and restore the offline UI.

Define an intention schema with bounded integer IDs, finite vectors, sequence/session identifiers and a gameplay command. Do not accept client-authored final position, damage or ownership as authoritative facts. Inside an any_peer RPC, derive the sender from `multiplayer.get_remote_sender_id()` while still in the call, check a current peer/session, map its owned entity on the server, enforce range and state, deduplicate sequence, and consume a bounded time-window budget before expensive work. If using call_local on a host, handle the local sender context explicitly rather than assuming a remote ID. Avoid asynchronous work that reads remote_sender_id after yielding; capture the sender first.

RPC declarations and node paths must match peers. Godot 4.7.2 defaults are authority/call_remote/**reliable**/channel0 in both GDScript and C#; explicitly specify transfer modes when designing bandwidth policy. Channels separate ordered streams, and default channel0 maintains separate transfer-mode streams. Reliable inventory/events differ from frequent snapshots; use unreliable_ordered only when stale same-stream updates should be discarded and payload size/ordering behavior is understood. SceneReplicationConfig ALWAYS uses unreliable ongoing replication, ON_CHANGE reliable changes: these are not RPC defaults.

Create replicated nodes with deterministic names and assign authority before they enter their replicated lifecycle. MultiplayerSpawner's custom spawn_function returns the node to be added; do not manually add it twice. Set spawn_path/root_path relative to their actual owners, construct Synchronizer config before returning, and distinguish spawn payload from a later replicated property. RPC commands can race missing nodes: use stable controller paths, handshake readiness and queue only bounded pending work until the entity exists. Authority assignment is not itself replicated by every API; initialize it consistently on all peers.

## Modify/reconnect an existing game

Inventory RPC declarations, replicated properties, authority propagation and UI lifecycle first. Change server/client protocol together; include a version/session handshake when mixed clients can connect. Clear peer-owned state, pending commands, rate budgets and connection callbacks on disconnect. Never persist ENet peer IDs as account IDs. A fresh connection can have a fresh peer ID: bind it through authenticated session identity and use a new server epoch to reject delayed old commands. Server player ownership and actual authentication are distinct; the sample's constant epoch is only a fixture.

The bundled example sets server_relay=false, starts two clients, spawns an actor and verifies the later position99 update. Each sends an out-of-bounds request, wrong owner, accepted request and over-budget duplicate. The server checks nine total rejections across three peers and confirms three disconnects. After the first two clients leave, the parent starts a fresh client on the same server; the retained actor is late-spawned and synchronized again. This validates late reconnect and peer cleanup, not Internet reliability or identity authentication.

Run the ordinary example command with a 30-second outer timeout and loopback access. Every child log must show passed with exit0 and no engine errors; inspect server peer/rejection/disconnect counts, not only the parent result. Test expired epochs, duplicates and malformed data in an additional fixture before shipping a production protocol. Reject a failed network setup as environment/transport failure rather than pretending a scene-only test covers networking.

## Diagnose and retest

| Symptom | Check | Cause | Fix | Retest |
|---|---|---|---|---|
| Connected but RPC missing | Matching full NodePath, declaration/checksum and authority | Different scene names/configuration or command before spawn | Deterministic paths and ready handshake | Two separate clients execute intended method |
| Client can mutate another actor | Sender-derived server ownership and bounds | any_peer mistaken for validation | Validate command against server session/entity table | Invalid owner rejected with state unchanged |
| Spawn duplicated or late join stale | spawn_function, payload versus later properties | Added returned node twice or missed replication setup | Return initialized node once; configure before entry | Late reconnect observes spawn and subsequent update |
| Flood stalls server | Packet size/count, rate budget and expensive queries | Unlimited accepted command work | Cap schema and time-window budget before work | Burst rejected while valid commands still complete |
| Reconnect retains old input | Epoch, sequence and peer-owned queues | Old session state survived disconnect | Clear state and issue fresh session | Replay old command rejected |
| Port connection fails | Return Error, bind address, transport support | Port occupied/firewall/platform mismatch | Use available loopback test port; deploy suitable transport | Actual connection/lifecycle signals and cleanup |

Sources: [high-level multiplayer](https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html), [Spawner](https://docs.godotengine.org/en/4.7/classes/class_multiplayerspawner.html), [Synchronizer](https://docs.godotengine.org/en/4.7/classes/class_multiplayersynchronizer.html), [RPC default registration](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/modules/gdscript/gdscript_parser.cpp#L187). Never infer backend authentication or encryption from localhost ENet success.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [ENetMultiplayerPeer](https://docs.godotengine.org/en/4.7/classes/class_enetmultiplayerpeer.html)
- [MultiplayerAPI](https://docs.godotengine.org/en/4.7/classes/class_multiplayerapi.html)
- [MultiplayerSpawner](https://docs.godotengine.org/en/4.7/classes/class_multiplayerspawner.html)
- [MultiplayerSynchronizer](https://docs.godotengine.org/en/4.7/classes/class_multiplayersynchronizer.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Configure MultiplayerAPI with native peers such as ENetMultiplayerPeer; send data only after receiving connection signals.
2. Explicitly specify authority/any_peer, call_local/call_remote, and transfer mode for RPC methods; validate senders and game rules on the server.
3. Express scene spawning and property replication with MultiplayerSpawner/Synchronizer, with explicit paths and authority assignments.
4. Start a server and two independent clients; verify round trips, authoritative state, disconnects, and shutdown, preserving logs and PIDs for each process.

## Saving and Validation

Save only network configuration and scene synchronization descriptions, not session peer IDs; do not promote a fixed test port to the default for every deployment.
The bundled example runs a server, two initial clients and a late reconnect client; it checks authoritative rejection, state synchronization and disconnect cleanup. It does not claim public-network validation.

## Common Pitfalls and Recovery

- RPC paths and signatures must match; a successful local call does not prove network RPC correctness.
- Client-reported scores or positions are not authoritative server facts.

Distinguish occupied ports, configuration issues, path mismatches, and timeouts when connections fail; allow at most two diagnostic retries and clean up all child processes created by this operation.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Three-Process Example Contract

The parent script binds only to 127.0.0.1. The server uses `create_server(0, 2)` for a system-assigned port and writes `get_host().get_local_port()` to a readiness file; both clients read that port. Every process creates `/root/Net` with matching RPC signatures. The example's MultiplayerSpawner uses a custom spawn_function, and MultiplayerSynchronizer replicates `.:position` through SceneReplicationConfig.

The server first creates an object at position42, then updates it to99. Clients submit reliable channel1 requests only after observing99; the server checks sender, current connection, ownership, epoch, bounds and request budget. It rejects invalid requests and accepts only matching server state. After stopping the synchronizer, it releases initial clients sequentially, then reattaches synchronization for a late reconnect. All three clients disconnect gracefully while polling. The parent checks four logs and exit codes; the server requires three distinct accepted peers, nine rejections and three disconnects. Timeout cleanup terminates only owned PIDs.

This verifies local ENet spawning, property replication, RPC, and shutdown, not NAT traversal, public-network packet loss, authentication, or production anti-cheat. Game rules should determine server authority; do not let arbitrary clients change authority, spawn arbitrary nodes, or execute incoming resources. Report blocked when platform network permissions or network policy are insufficient.
