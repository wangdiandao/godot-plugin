---
name: godot-data
description: "Implement Godot game data, user settings, save file reading and writing, save version migration, and malformed data handling."
---

# Data and Save Files

## Purpose and Scope

Save files, user settings, and data resources. Coordinate network synchronization rules with multiplayer.

## Prerequisite Checks

Confirm data structures, save scope, versions, and compatibility targets; use isolated test paths without overwriting existing player saves.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Prefer custom Resources for static game configuration, ConfigFile for user settings, and explicitly verifiable JSON or binary structures for player saves.
2. Save player data to user://; validate the top-level type, version, required fields, and numeric ranges when reading, and return distinct errors.
3. Write and flush a temporary file, validate the new data, then replace the target; preserve the original and diagnostic temporary file if a platform rename fails.
4. Write explicit migrations for existing versions and migrate in memory before saving; preserve unknown newer versions rather than overwriting them with defaults.

## File Changes, Saving, and Recovery

Separate user data from res:// configuration resources. Recovery applies only to this operation's writes; clearly report backups and conflicts with concurrent changes.
A missing file may initialize default state; preserve and report corrupt files rather than treating them as new players. Do not erase old saves when writing fails.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example round-trips a valid save and rejects corrupt JSON; tests cover old-version migration, unknown newer versions, and write failures.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
