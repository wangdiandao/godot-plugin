---
name: godot-gdscript
description: "Implement, modify or diagnose GDScript gameplay and tool logic, typed interfaces, signals, asynchronous flow and script lifecycle."
---

# GDScript Implementation

## Purpose and Scope

Implement behavior in the existing scene and resource contracts. Use C# or GDExtension for their language-specific toolchains.

## Prerequisite Checks

Read callers, exported fields, signal wiring, process modes and warning policy; distinguish script construction from entry into SceneTree. Read [execution conventions](../../shared/references/execution.md) before launching an unfamiliar engine. Research uses the fixed 4.7 documentation snapshot; bundled native validation uses 4.7.2 standard builds. Verify the user's actual binary rather than assuming these match.

## Workflow and Key Decisions

For async cancellation, replacement and signal reentry, read [Async cancellation, replacement and signal reentry](references/tasks.md) and run the [async-lifecycle example](assets/examples/async-lifecycle/project.godot).

1. For new behavior, implement a typed command that validates before mutation and emits a completed fact.
2. For asynchronous work, read [async tasks](references/tasks.md) and use a request generation plus a weak target; cancel on exit or replacement.
3. For duplicate effects or recursion, inspect connection ownership and synchronous callbacks before changing gameplay rules.
4. Run the command and async-lifecycle fixtures, including superseded requests, detached targets and listener-triggered reentry.

## File Changes, Saving, and Recovery

Keep exported names and caller types stable. On failed async changes, restore the command contract and cancel owned generations; do not hide required dependencies behind unconditional null guards. Use [persistence](../../shared/references/persistence.md) for disk readback and [recovery](../../shared/references/recovery.md) for task-owned restoration.

## Acceptance and Delivery

Verify behavior, failure handling and cleanup, including a meaningful modification to the implementation; parser success alone is insufficient. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Async cancellation, replacement and signal reentry](references/tasks.md): complete task selection, ordered failures and fixture boundaries.

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
