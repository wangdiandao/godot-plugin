---
name: godot-animation
description: "Create or adjust Godot frame and property animations, AnimationPlayer, AnimationTree, animation libraries, and skeletal animation playback."
---

# Animation Systems

## Purpose and Scope

Animation resources, playback, and blending. Gameplay code determines the game rules triggered by actions.

## Prerequisite Checks

Confirm node paths, AnimationPlayer root_node, resource sharing, and the target skeleton; list existing libraries before importing animations.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Create an AnimationLibrary and Animation, then add tracks of the correct type and NodePaths; verify paths against actual target properties or bones.
2. Configure length, looping, and keyframes, and reference animations by library/animation name; preserve unrelated tracks in existing resources.
3. Configure an AnimationTree state machine or blend space; let one system own playback state to avoid contention with AnimationPlayer.play.
4. Verify properties at key times through playback, advance, or seek; additionally check rest pose, bone mapping, and root motion for skeletal animation.

## File Changes, Saving, and Recovery

Save and reload animation libraries as resources; duplicate only shared animation portions that need independent changes so all instances are not modified together.
For animation that does not move, check track paths, active state, and processing mode first; for abrupt transitions, inspect RESET and the initial pose.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example inserts a position track, actually advances to its midpoint, and asserts the property change; it checks keyframes and duration after saving.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
