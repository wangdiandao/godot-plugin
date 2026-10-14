---
name: godot-architecture
description: "Design or refactor Godot module boundaries, component composition, lifecycle wiring, scene contracts, signals and Autoload services; diagnose dependency and state coupling."
---

# Modular Game Architecture

## Purpose and Scope

Enemy action selection belongs to godot-ai; this skill owns module structure and coupling. Build the smallest architecture that supports the requested iteration and testing. Use workflow for complete game delivery and scenes for serialization mechanics.

## Prerequisite Checks

Map current scene roots, shared Resources, Autoloads, signal flows, ownership and module dependencies; identify the concrete pain before restructuring. Read [execution conventions](../../shared/references/execution.md) before launching an unfamiliar engine. Research uses the fixed 4.7 documentation snapshot; bundled native validation uses 4.7.2 standard builds. Verify the user's actual binary rather than assuming these match.

## Workflow and Key Decisions

1. Map the concrete coupling: readiness ordering, shared runtime state, command validation, event delivery or teardown.
2. Choose Node/Resource/RefCounted from lifetime and authored-state needs; wire required dependencies from a composition root.
3. For refactors, retain node/export contracts while moving one responsibility; exercise both isolated and original callers.
4. On service replacement or tree exit, detach the old publisher and cancel owned work; count notifications across reentry.

## File Changes, Saving, and Recovery

Preserve exported fields and node paths while moving responsibilities. Restore wiring on a failed refactor; disconnect replaced services and invalidate pending work before teardown. Use [persistence](../../shared/references/persistence.md) for disk readback and [recovery](../../shared/references/recovery.md) for task-owned restoration.

## Acceptance and Delivery

Run the module independently with supplied dependencies, exercise UI intent through validated state, reload its saved scene and test missing dependencies plus teardown. A folder layout is not behavioral evidence. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
