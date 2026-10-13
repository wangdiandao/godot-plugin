---
name: godot-3d
description: "Build Godot 3D content, including meshes, models, levels, Camera3D, and skeleton resource organization."
---

# 3D Worlds

## Purpose and Scope

3D scene construction, models, and cameras. Use rendering for visual effects and physics for movement and collision.

## Prerequisite Checks

Confirm metric scale, axes, camera view, and target GPU; inspect transforms and materials before working with imported models.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Build verifiable geometry with MeshInstance3D, PrimitiveMesh, or ArrayMesh. Reuse resources for runtime objects and duplicate them when independent parameters are needed.
2. Create physical shapes separately from visual meshes; do not assume a mesh participates in collisions by itself.
3. Configure an active Camera3D, lights, and WorldEnvironment; use the official glTF importer and preserve relationships between source models and externalized resources.
4. When a skeleton is needed, inspect bone names and local poses and ensure animation tracks match node paths; do not invent rig structure.

## File Changes, Saving, and Recovery

Save editable nodes and resources; put changes to imported models in wrapper scenes or explicit inheritance overrides rather than editing caches directly.
For a black screen, check the active camera, clipping planes, visibility layers, and position before lighting; for incorrect model scale, check import settings and parent transforms.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example generates and reloads a scene containing a camera, meshes, and lights; it verifies isolated mesh edits and saved dimensions. Appearance needs a separate real-rendering capture.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [complete task recipes and diagnostic paths](references/recipes.md) for developing, modifying or repairing this domain; choose the recipe matching the requested behavior.

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
