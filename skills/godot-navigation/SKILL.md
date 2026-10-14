---
name: godot-navigation
description: "Create or fix Godot navigation data, navigation baking, path queries, navigation agents, and avoidance behavior; use godot-ai for enemy target/action decisions."
---

# Navigation and Pathfinding

## Purpose and Scope

Paths and navigation generation. Enemy decisions and decision state machines belong to godot-ai, and avoidance does not automatically move characters.

## Prerequisite Checks

Confirm 2D/3D, geometry sources, agent radius, navigation layers, and target platform; bake from accessible source geometry.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

For TileMapLayer grid paths and dynamic blockers, read the [task recipe](references/grid.md).

For actual agent movement, patrol and avoidance callbacks, read [Actual agent movement, patrol and avoidance callbacks](references/movement.md) and run the [moving-agent example](assets/examples/moving-agent/project.godot).

1. Configure NavigationPolygon or NavigationMesh; prefer source geometry arrays or collision geometry so headless execution does not depend on reading GPU meshes.
2. Use NavigationServer parse_source_geometry_data and bake_from_source_geometry_data; parse scenes on the main thread and wait for asynchronous baking to complete.
3. Assign resources to navigation regions and wait for map synchronization before querying paths; keep map changes and agent movement aligned with physics frames.
4. The character controller still performs movement after avoidance callbacks produce safe_velocity; test unreachable targets, narrow entrances, and different navigation layers.

## File Changes, Saving, and Recovery

Save baked results as native resources and reload them to verify vertices/polygons; retain source geometry and parameters for rebuilding.
For empty paths, check map activation, region connections, layers, and synchronization first. For empty bakes, check geometry dimensions and agent_radius; do not blindly shrink the agent.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

For route repair, verify synchronization and final-point arrival twice while retaining an excluded-layer control. Keep graph-query evidence separate from actual controller/avoidance movement. Follow the ordered diagnostic branch in recipes.md.

The example builds navigation geometry from CPU vertices, bakes and saves it, then verifies nonempty polygons after reload; the two-region checks assert arrival at the target and reject excluded or disabled regions. Avoidance movement requires its own target-scene acceptance.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- [Directional link example](assets/examples/links/project.godot): disconnected, enabled, disabled and reverse-route controls.

- [Actual agent movement, patrol and avoidance callbacks](references/movement.md): complete task selection, ordered failures and fixture boundaries.

- Read [complete task recipes and diagnostic paths](references/recipes.md) for developing, modifying or repairing this domain; choose the recipe matching the requested behavior.

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
