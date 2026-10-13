---
name: godot-physics
description: "Implement or troubleshoot Godot 2D/3D character movement, collisions, triggers, raycasts, rigid bodies, and physics interactions."
---

# Physics and Interaction

## Purpose and Scope

Physics behavior and interaction. Do not attribute every visual misalignment to the physics engine.

## Prerequisite Checks

Confirm 2D/3D, physics backend, body types, collision layers/masks, shapes, and units; inspect existing character controllers.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Use CharacterBody velocity and move_and_slide in _physics_process for characters; use forces, impulses, or official integration callbacks for RigidBody.
2. Configure both objects' layer/mask and the Area's monitoring; check shape nodes, transforms, and enabled states individually.
3. Schedule physics queries at a safe point in physics processing and use PhysicsRayQueryParameters; defer structural changes in interaction callbacks when necessary.
4. Test rest, movement, edges, collisions, and triggers with tolerances and state assertions; do not assume physics is identical frame by frame across platforms.

## File Changes, Saving, and Recovery

Update movement scripts and shape scenes together; do not write runtime velocity or test input back into authored scenes.
For tunneling, check speed, size, backend support, and continuous detection first. For missing triggers, check filtering on both objects and whether enough physics steps have elapsed.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example creates a floor and body in a physics world and verifies resting height or contact after actual simulation steps; it also measures movement, verifies an expected ray hit and wrong-mask miss, and checks one trigger enter/exit pair.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [complete task recipes and diagnostic paths](references/recipes.md) for developing, modifying or repairing this domain; choose the recipe matching the requested behavior.

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
