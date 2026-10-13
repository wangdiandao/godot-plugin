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

1. Define the observable task and run the relevant baseline before editing.
2. Research one concept at a time with Context7 when available, then inspect fixed official sources. Check public ClassDB binding, argument/property types, editor/runtime restriction and a real behavioral call. Separate existence, invocation and correct result.
3. Read the matching development, modification or diagnosis recipe in [native.md](references/native.md), implement a minimal reviewable change and run the relevant behavioral case.
4. Follow callers across the changed contract and verify persistence when files or serialized state change.

## File Changes, Saving, and Recovery

Preserve user changes, scene identities and unrelated settings. Record the pre-change content/hash before replacing existing files. Reload the saved state rather than using only the modified in-memory object. Follow [persistence](../../shared/references/persistence.md) and [recovery](../../shared/references/recovery.md) for conflicts or failed writes; stop repeating the same fix after two evidence-based attempts.

## Acceptance and Delivery

Deliver the verified signature, source and minimal behavioral evidence, or the exact unsupported boundary and native alternative. Do not equate internal C++ methods with script APIs. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
