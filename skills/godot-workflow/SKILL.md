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

1. Define the observable task and run the relevant baseline before editing.
2. Build one vertical slice with a runnable main scene before adding breadth. Route only the next needed domain. Keep rules, presentation and persistence boundaries clear, and use observable checkpoints to locate cross-system regressions.
3. Read the matching development, modification or diagnosis recipe in [native.md](references/native.md), implement a minimal reviewable change and run the relevant behavioral case.
4. Follow callers across the changed contract and verify persistence when files or serialized state change.

## File Changes, Saving, and Recovery

Preserve user changes, scene identities and unrelated settings. Record the pre-change content/hash before replacing existing files. Reload the saved state rather than using only the modified in-memory object. Follow [persistence](../../shared/references/persistence.md) and [recovery](../../shared/references/recovery.md) for conflicts or failed writes; stop repeating the same fix after two evidence-based attempts.

## Acceptance and Delivery

Demonstrate the requested player loop and reload/restart behavior. Visual, audio and export acceptance require their actual environments; headless state checks prove only state. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
