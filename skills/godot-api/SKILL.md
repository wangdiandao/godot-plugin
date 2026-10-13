---
name: godot-api
description: "Verify uncertain Godot classes, bindings, CLI flags and version differences using fixed official documentation, source bindings and actual minimal calls."
---

# API and Version Verification

## Purpose and Scope

Resolve an interface question or unsupported operation. Ordinary business logic edits do not require exhaustive API dumps.

## Prerequisite Checks

Record documentation commit separately from actual engine/build/platform; state the precise operation and execution context being verified. Read [execution conventions](../../shared/references/execution.md) before launching an unfamiliar engine. Research uses the fixed 4.7 documentation snapshot; bundled native validation uses 4.7.2 standard builds. Verify the user's actual binary rather than assuming these match.

## Workflow and Key Decisions

1. Classify the question as CLI, script binding, editor-only operation or generated language binding; choose the corresponding evidence path in native.md.
2. State the exact version/context and verify existence, invocation and observable result independently.
3. For a version change, compare old/new signatures and search callers plus serialized property names before changing them.
4. Deliver the verified public signature and minimal call, or the unsupported boundary and a tested alternative.

## File Changes, Saving, and Recovery

If sources disagree, retain each version/context and reduce to a focused call; do not convert an internal C++ method into a script promise. Use [persistence](../../shared/references/persistence.md) for disk readback and [recovery](../../shared/references/recovery.md) for task-owned restoration.

## Acceptance and Delivery

Deliver the verified signature, source and minimal behavioral evidence, or the exact unsupported boundary and native alternative. Do not equate internal C++ methods with script APIs. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
