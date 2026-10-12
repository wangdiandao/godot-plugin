# Native Multiplayer: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

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
The bundled example actually runs a server and two clients, checking RPC acknowledgments from two distinct peers and disconnect cleanup; it does not claim public-network validation.

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

The server first creates an object at position 42, then updates it to 99. Both clients send a reliable RPC only after observing the replicated 99; the server checks remote_sender_id, the current peer list, and the value. After stopping the synchronizer, the server acknowledges one client, observes its disconnection, then acknowledges the other. Clients request orderly disconnection with disconnect_peer(1) and continue polling until completion. This avoids forwarding notifications to peers whose disconnections have not yet been processed when both clients force close simultaneously. The parent checks all three logs, exit codes, two distinct peers, and disconnect counts; on timeout, it terminates only its own PIDs.

This verifies local ENet spawning, property replication, RPC, and shutdown, not NAT traversal, public-network packet loss, authentication, or production anti-cheat. Game rules should determine server authority; do not let arbitrary clients change authority, spawn arbitrary nodes, or execute incoming resources. Report blocked when platform network permissions or network policy are insufficient.
