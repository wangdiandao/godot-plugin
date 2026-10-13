---
name: godot-scenes
description: "Create or modify Godot scene hierarchies, scene instances, node ownership and persistent connections; diagnose missing saved nodes or resource sharing."
---

# Scenes and Resource Persistence

## Purpose and Scope

Construct reusable scenes and persist their intended state. Use assets for source-art import and architecture for system dependency design.

## Prerequisite Checks

Inspect inherited and instantiated scene boundaries, node names/paths, owner values, external resources, connections and save destinations. Read [execution conventions](../../shared/references/execution.md) before launching an unfamiliar engine. Research uses the fixed 4.7 documentation snapshot; bundled native validation uses 4.7.2 standard builds. Verify the user's actual binary rather than assuming these match.

## Workflow and Key Decisions

For rename exported/animation paths without flattening instances, read [Rename exported/animation paths without flattening instances](references/refactoring.md) and run the [refactor example](assets/examples/refactor/project.godot).

1. Classify the target as a new scene, ordinary instance, inherited variant or imported generated subtree.
2. For new scenes, assign valid owners and persistent named connections; save and exercise the reloaded scene.
3. For a rename or move, read [scene refactoring](references/refactoring.md), inventory NodePaths/tracks/connections, then update only the owned references.
4. For missing saved nodes or shared state, inspect SceneState and resource identity; preserve the base and instance boundaries.

## File Changes, Saving, and Recovery

Keep base scenes, instance references and source hashes intact. A failed rename must restore dependent paths together; changing every owner or flattening the subtree is not recovery. Use [persistence](../../shared/references/persistence.md) for disk readback and [recovery](../../shared/references/recovery.md) for task-owned restoration.

## Acceptance and Delivery

Reload without reusing the root cache, inspect saved nodes and connections, instantiate and invoke the saved behavior; verify excluded transient nodes are absent. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Rename exported/animation paths without flattening instances](references/refactoring.md): complete task selection, ordered failures and fixture boundaries.

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
