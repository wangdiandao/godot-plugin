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

For inventory IDs, command validation and protected snapshots, read the [task recipe](references/inventory.md).

1. Choose authored Resource, independent ConfigFile settings or a strict versioned player-save schema.
2. Classify missing, corrupt, invalid, future-version and I/O failures before selecting recovery; preserve future data.
3. Migrate in memory, validate staged bytes and compare the existing fingerprint before commit.
4. For shared Resources, select duplication semantics explicitly and mutate two instances to verify independence.

## File Changes, Saving, and Recovery

Preserve original bytes, schema and validated backup. Never replace unsupported or corrupt progress with defaults; failed staging/conflict must leave the target unchanged. Use [persistence](../../shared/references/persistence.md) for disk readback and [recovery](../../shared/references/recovery.md) for task-owned restoration.

## Acceptance and Delivery

Assert migrated values, strict schema rejection, saved readback, backup recovery and unchanged target on failed/conflicting writes. Report crash and cross-process durability separately. Inspect engine logs, exit status and the structured result together. Report exact commands, versions, changed files and untested environments; historical results are not this run's evidence.

## On-Demand References and Examples

- [Task recipes, decisions and diagnosis](references/native.md): load only the section needed for the current task.
- [Isolated native example](assets/examples/minimal/project.godot): copy the whole directory, run `example.gd` with an explicit output directory as documented in the reference.
- [Evidence conventions](../../shared/references/evidence.md) and [capability index](../../docs/capabilities.json): use when updating delivery evidence.
