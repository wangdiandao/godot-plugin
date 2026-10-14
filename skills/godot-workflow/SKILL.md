---
name: godot-workflow
description: "Build or iterate a complete Godot game or feature spanning systems, from observable gameplay requirements through runnable checkpoints and verified delivery."
---

# Complete Game Development

## Purpose and Scope

Coordinate multiple domains around a playable loop. Isolated changes belong to the relevant specialist.

## Prerequisite Checks

Inspect existing playable behavior, project/version evidence, platform constraints and baseline defects; identify start, interaction, objective, failure and restart criteria. Read [execution conventions](../../shared/references/execution.md) before launching an unfamiliar engine. Research uses the fixed 4.7 documentation snapshot; bundled native validation uses 4.7.2 standard builds. Verify the user's actual binary rather than assuming these match.

## Workflow and Key Decisions

For cross-system resource commands, hud and repeated restart, read [Cross-system resource commands, HUD and repeated restart](references/vertical-slice.md) and run the [bounded-resource example](assets/examples/bounded-resource/project.godot).

1. Write an action/checkpoint table covering input, rules, visible state, failure, restart and requested persistence.
2. Use the playable 2D/3D examples for full loops; the minimal example proves only scene persistence.
3. Read [vertical-slice recipes](references/vertical-slice.md) for a bounded-resource modification and failure/restart integration; pass concrete contracts to domain skills.
4. Run the original player loop after specialist checks, preserving unsupported/corrupt saves and reporting save failures visibly.

## File Changes, Saving, and Recovery

Save coherent runnable checkpoints. Keep authored scenes separate from player progress; display persistence failures and preserve blocked files while gameplay continues. Use [persistence](../../shared/references/persistence.md) for disk readback and [recovery](../../shared/references/recovery.md) for task-owned restoration.

## Acceptance and Delivery

Demonstrate the requested player loop and reload/restart behavior. Visual, audio and export acceptance require their actual environments; headless state checks prove only state. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Story/inventory integration](assets/examples/story-inventory/project.godot): keyboard dialogue, once-only reward, HUD and saved progress across repeated restart.

- [Cross-system resource commands, HUD and repeated restart](references/vertical-slice.md): complete task selection, ordered failures and fixture boundaries.

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Playable 2D game](assets/examples/game-2d/project.godot) and [playable 3D game](assets/examples/game-3d/project.godot): copy either complete project and run with `--self-test --out OUT`; remove headless for real pixels.
- [Isolated persistence-only example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
