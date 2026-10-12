---
name: godot-multiplayer
description: "Use Godot native multiplayer APIs to implement connections, RPCs, state synchronization, and object spawning, with local multiprocess validation."
---

# Native Multiplayer

## Purpose and Scope

Godot native multiplayer features. Local ENet connections do not automatically include public-network relays, account services, or matchmaking backends.

## Prerequisite Checks

Confirm transport, server authority scope, ports, and node paths; bind tests only to loopback addresses and temporary ports.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Configure MultiplayerAPI with native peers such as ENetMultiplayerPeer; send data only after receiving connection signals.
2. Explicitly specify authority/any_peer, call_local/call_remote, and transfer mode for RPC methods; validate senders and game rules on the server.
3. Express scene spawning and property replication with MultiplayerSpawner/Synchronizer, with explicit paths and authority assignments.
4. Start a server and two independent clients; verify round trips, authoritative state, disconnects, and shutdown, preserving logs and PIDs for each process.

## File Changes, Saving, and Recovery

Save only network configuration and scene synchronization descriptions, not session peer IDs; do not promote a fixed test port to the default for every deployment.
Distinguish occupied ports, configuration issues, path mismatches, and timeouts when connections fail; allow at most two diagnostic retries and clean up all child processes created by this operation.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The bundled example actually runs a server and two clients, checking RPC acknowledgments from two distinct peers and disconnect cleanup; it does not claim public-network validation.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
