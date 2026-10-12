---
name: godot-scenes
description: "Create or modify Godot scenes, nodes, and resources, including instances, inheritance, persistent signals, resource references, and integrity after saving."
---

# Scenes and Resources

## Purpose and Scope

Structural scene and resource operations. Prefer minimal text diffs for existing scenes with complex inheritance; do not indiscriminately expand them.

## Prerequisite Checks

Inspect existing scenes, external resources, instance relationships, node ownership, and signals; load only after import completes.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Edit .tscn/.tres directly for simple property changes; create complex new resources through official Node and Resource APIs.
2. Call add_child first, then assign the correct owner to new nodes that must persist; preserve internal ownership boundaries in existing child scenes.
3. Use named methods and CONNECT_PERSIST for signals that must be saved; call PackedScene.pack and ResourceSaver.save and check Error.
4. Reload saved results with CACHE_MODE_IGNORE and inspect nodes, properties, connections, and dependencies with SceneState; instantiate for validation when necessary.

## File Changes, Saving, and Recovery

Preserve UIDs, ext_resource entries, instances, and inheritance information. Do not recursively assign the outer root as owner of an entire instance tree; do not fabricate import caches.
For missing nodes, check owner first; for missing signals, check persistence flags. Restore only this operation's files after save failure, and stop overwriting when the user has made concurrent changes.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example saves nested nodes and persistent signals and verifies them after reload. Regression tests also cover instance preservation, inheritance overrides, and unwritable targets.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
