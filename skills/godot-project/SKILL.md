---
name: godot-project
description: "Create, configure, take over or migrate Godot projects, including persistent input actions and Autoload registration."
---

# Projects and Configuration

## Purpose and Scope

Establish a runnable project and its configuration contract. Use architecture for module boundaries and export for platform packaging.

## Prerequisite Checks

Record the engine binary/version, renderer, main scene, Autoload paths, input actions and existing import failures. Read [execution conventions](../../shared/references/execution.md) before launching an unfamiliar engine. Research uses the fixed 4.7 documentation snapshot; bundled native validation uses 4.7.2 standard builds. Verify the user's actual binary rather than assuming these match.

## Workflow and Key Decisions

1. For a new project, select renderer, main scene, persisted inputs and Autoload order from the stated platform and loop.
2. For takeover, inspect the existing main scene/configuration and reproduce startup before changing one setting.
3. For startup failures, follow path/UID, parser, input registration and Autoload branches in native.md.
4. Import and launch a fresh process; distinguish runtime InputMap changes from persisted configuration.

## File Changes, Saving, and Recovery

Preserve unrelated settings, UID/import metadata and Autoload order. Review normalization diffs; restore only task edits when startup or persisted input regresses. Use [persistence](../../shared/references/persistence.md) for disk readback and [recovery](../../shared/references/recovery.md) for task-owned restoration.

## Acceptance and Delivery

A generated project must import, launch its real main scene, resolve Autoloads and reload persistent input configuration. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
