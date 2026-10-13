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

1. Define the observable task and run the relevant baseline before editing.
2. Select the renderer by target hardware and required features, not dimension alone. Preserve existing choices unless the task requires a change. Persist input/* dictionaries and Autoload paths; runtime InputMap edits are session-only. Migrate an isolated copy before changing engine feature tags.
3. Read the matching development, modification or diagnosis recipe in [native.md](references/native.md), implement a minimal reviewable change and run the relevant behavioral case.
4. Follow callers across the changed contract and verify persistence when files or serialized state change.

## File Changes, Saving, and Recovery

Preserve user changes, scene identities and unrelated settings. Record the pre-change content/hash before replacing existing files. Reload the saved state rather than using only the modified in-memory object. Follow [persistence](../../shared/references/persistence.md) and [recovery](../../shared/references/recovery.md) for conflicts or failed writes; stop repeating the same fix after two evidence-based attempts.

## Acceptance and Delivery

A generated project must import, launch its real main scene, resolve Autoloads and reload persistent input configuration. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
