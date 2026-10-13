---
name: godot-architecture
description: "Design or refactor Godot module boundaries, component composition, lifecycle wiring, scene contracts, signals and Autoload services; diagnose dependency and state coupling."
---

# Modular Game Architecture

## Purpose and Scope

Build the smallest architecture that supports the requested iteration and testing. Use workflow for complete game delivery and scenes for serialization mechanics.

## Prerequisite Checks

Map current scene roots, shared Resources, Autoloads, signal flows, ownership and module dependencies; identify the concrete pain before restructuring. Read [execution conventions](../../shared/references/execution.md) before launching an unfamiliar engine. Research uses the fixed 4.7 documentation snapshot; bundled native validation uses 4.7.2 standard builds. Verify the user's actual binary rather than assuming these match.

## Workflow and Key Decisions

1. Define the observable task and run the relevant baseline before editing.
2. Place reusable data/algorithms below gameplay systems and let content/UI depend on systems. Use direct typed calls for required commands, signals for completed facts and a composition root for dependency wiring. Make lifecycle and teardown explicit. Add a module only when its contract removes actual coupling.
3. Read the matching development, modification or diagnosis recipe in [native.md](references/native.md), implement a minimal reviewable change and run the relevant behavioral case.
4. Follow callers across the changed contract and verify persistence when files or serialized state change.

## File Changes, Saving, and Recovery

Preserve user changes, scene identities and unrelated settings. Record the pre-change content/hash before replacing existing files. Reload the saved state rather than using only the modified in-memory object. Follow [persistence](../../shared/references/persistence.md) and [recovery](../../shared/references/recovery.md) for conflicts or failed writes; stop repeating the same fix after two evidence-based attempts.

## Acceptance and Delivery

Run the module independently with supplied dependencies, exercise UI intent through validated state, reload its saved scene and test missing dependencies plus teardown. A folder layout is not behavioral evidence. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
