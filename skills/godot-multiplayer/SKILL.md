---
name: godot-multiplayer
description: "Use Godot native multiplayer APIs to implement connections, RPCs, state synchronization, and object spawning, with local multiprocess validation."
---

# Native Multiplayer

## Purpose and Scope

Godot native multiplayer features. Local ENet connections do not automatically include public-network relays, account services, or matchmaking backends.

## Prerequisite Checks

Confirm topology, transport/platform constraints, server ownership rules, connection/session state and replicated node paths. Bind local tests only to loopback and a temporary port; Internet delivery requires its own NAT/relay/TLS and device evidence.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Configure MultiplayerAPI with native peers such as ENetMultiplayerPeer; send data only after receiving connection signals.
2. Send bounded intentions to the authority, derive sender from get_remote_sender_id, validate ownership/session/rate/game state, then publish accepted state. An any_peer annotation grants call permission; it is not validation.
3. Set names, paths and multiplayer authority before spawning/replication begins. Separate spawn initial state, reliable changed state and frequent transform streams; transfer channels do not make unbounded payloads safe.
4. Run independent server/client processes and failure requests. Assert spawn, later property changes, rejection without mutation, disconnect cleanup and a late reconnect on the same server. Preserve all child logs and exit codes.

## File Changes, Saving, and Recovery

Save only network configuration and scene synchronization descriptions, not session peer IDs; do not promote a fixed test port to the default for every deployment.
Distinguish occupied ports, configuration issues, path mismatches, and timeouts when connections fail; allow at most two diagnostic retries and clean up all child processes created by this operation.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The bundled example runs one server, two clients and a reconnect client. It checks spawn, later state replication, three distinct peer confirmations, nine bounds/ownership/budget rejections and three graceful disconnects. Its constant fixture epoch and fixed request budget illustrate guards; production uses a server-issued session epoch and time-based rate policy. Public-network loss, hostile transport and deployment remain separate checks.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
