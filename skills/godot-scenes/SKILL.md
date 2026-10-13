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

1. Define the observable task and run the relevant baseline before editing.
2. Separate parentage from serialization ownership. Add children before assigning a valid ancestor owner. Choose external versus built-in resources and a duplication policy explicitly; avoid flattening imported or inherited scenes to make one edit.
3. Read the matching development, modification or diagnosis recipe in [native.md](references/native.md), implement a minimal reviewable change and run the relevant behavioral case.
4. Follow callers across the changed contract and verify persistence when files or serialized state change.

## File Changes, Saving, and Recovery

Preserve user changes, scene identities and unrelated settings. Record the pre-change content/hash before replacing existing files. Reload the saved state rather than using only the modified in-memory object. Follow [persistence](../../shared/references/persistence.md) and [recovery](../../shared/references/recovery.md) for conflicts or failed writes; stop repeating the same fix after two evidence-based attempts.

## Acceptance and Delivery

Reload without reusing the root cache, inspect saved nodes and connections, instantiate and invoke the saved behavior; verify excluded transient nodes are absent. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
