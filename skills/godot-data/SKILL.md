---
name: godot-data
description: "Implement or modify Godot configuration Resources, user settings and versioned player saves; diagnose sharing, migration, corruption and write failures."
---

# Data and Save Recovery

## Purpose and Scope

Persist explicit data contracts and recover identifiable valid state. Use multiplayer for authoritative network state; local saves do not establish server authority.

## Prerequisite Checks

Identify trusted authored resources versus untrusted basic save data, current/old schemas, writable user:// path, backup policy and concurrent writers. Read [execution conventions](../../shared/references/execution.md) before launching an unfamiliar engine. Research uses the fixed 4.7 documentation snapshot; bundled native validation uses 4.7.2 standard builds. Verify the user's actual binary rather than assuming these match.

## Workflow and Key Decisions

1. Define the observable task and run the relevant baseline before editing.
2. Choose Resource for authored data, ConfigFile for Variant settings and versioned JSON or a specified binary format for player saves. Validate before migration; distinguish missing, corrupt, unsupported future and I/O failure. Validate a temporary write before committing and preserve conflict evidence.
3. Read the matching development, modification or diagnosis recipe in [native.md](references/native.md), implement a minimal reviewable change and run the relevant behavioral case.
4. Follow callers across the changed contract and verify persistence when files or serialized state change.

## File Changes, Saving, and Recovery

Preserve user changes, scene identities and unrelated settings. Record the pre-change content/hash before replacing existing files. Reload the saved state rather than using only the modified in-memory object. Follow [persistence](../../shared/references/persistence.md) and [recovery](../../shared/references/recovery.md) for conflicts or failed writes; stop repeating the same fix after two evidence-based attempts.

## Acceptance and Delivery

Assert migrated values, strict schema rejection, saved readback, backup recovery and unchanged target on failed/conflicting writes. Report crash and cross-process durability separately. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
