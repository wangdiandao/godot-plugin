---
name: godot-ai
description: "Build or diagnose Godot enemy decisions, target selection, perception-driven behavior, utility scoring and coordinated action planning. Use navigation for paths and avoidance, physics for movement and raycasts, and animation for playback."
---

# Game AI Decisions

## Purpose and Scope

Choose what a non-player actor should do from valid observations and game rules. Own decision states, target selection and planning; do not absorb player controllers, animation state machines or pathfinding. Complete game integration belongs to godot-workflow.

## Prerequisite Checks

Identify actor/target lifetimes, available observations, legal actions, reaction latency, deterministic replay needs and the authority that commits game state. Distinguish no target, hidden target and unreachable target. Read [execution conventions](../../shared/references/execution.md) before launching an unfamiliar engine. The researched baseline is Godot 4.7; native examples use 4.7.2.

## Workflow and Key Decisions

1. Specify observable scenarios and legal commands before choosing a decision model. A few exclusive behaviors fit an enum; independent behaviors may need separate state domains. Use utility scoring when choosing among competing legal actions.
2. Supply a perception snapshot; physics queries and navigation results have their own validity and update timing. Keep decision code independent from sensors so it can run on deterministic inputs.
3. Filter illegal actions before scoring, define stable tie-breaking and retain a safe fallback. Revalidate the selected target and command at commitment.
4. For expensive planning, snapshot input and split bounded work across frames. Invalidate the plan when its request or world revision changes; measure the target game's reaction latency.
5. Compare scenario outcomes before/after modifications; count state entries/exits and test lost targets, blocked sight, repeated decisions and superseded plans.

## File Changes, Saving, and Recovery

Preserve actor exports and scene paths while moving decisions behind a contract. Save authored configuration separately from runtime target references; session object IDs are not persistent identities. On exit, detach sensors and cancel pending plans. Restore the last working decision model if a change makes actions illegal or planning unresponsive. Follow [persistence](../../shared/references/persistence.md) and [recovery](../../shared/references/recovery.md).

## Acceptance and Delivery

Verify legal decisions for each scenario, fallback behavior and repeatable tie-breaking. A chosen chase action does not prove navigation arrival. The example validates decisions from supplied visibility and positions, state lifecycle, bounded planning and monitor cleanup; it does not prove raycast perception, moving enemies, team tactics or combat balance. Report actual commands, engine, platform and untested integration.

## On-Demand References and Examples

- Read [decision recipes and diagnostic paths](references/native.md) when creating, modifying or debugging AI.
- Copy the [minimal decision project](assets/examples/minimal/project.godot) for deterministic decision and cancellation checks.
- Use [evidence conventions](../../shared/references/evidence.md) and [capabilities](../../docs/capabilities.json) when recording actual results.
