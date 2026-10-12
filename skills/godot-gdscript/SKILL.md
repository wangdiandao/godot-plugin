---
name: godot-gdscript
description: "Write or refactor GDScript, including types, signals, asynchronous flows, resource classes, and code organization; prefer the corresponding domain skill for specific game systems."
---

# GDScript Implementation

## Purpose and Scope

Script design, types, signals, asynchronous execution, and refactoring. Let the corresponding domain skill lead specific UI, navigation, and similar tasks.

## Prerequisite Checks

Inspect callers, node lifecycles, exported properties, and serialized dependencies; verify class_name after the first import.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Express interfaces with explicit types; do not change everything to Variant to suppress warnings. Give null branches for resource and node references meaningful behavior.
2. Use signals for events and wait for the appropriate nodes or signals for deferred initialization; decide whether mutable shared Resource data needs an independent copy.
3. Before refactoring, inspect script paths, NodePaths, signal method names, and serialized properties in scenes; preserve public contracts or migrate callers together.
4. Check individual files with --check-only --script, then execute real call paths covering await completion, disconnection, and object freeing.

## File Changes, Saving, and Recovery

Preserve script .uid files and external resource references. Node scripts cannot serve as --script entry points; test wrappers should extend SceneTree.
For circular dependencies, adjust data/behavior boundaries first; for type cache issues, import first; for suspended awaits, add lifecycle and timeout checks.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

Verify at least one signal's arguments and call count, one asynchronous completion path, and reloaded values of persisted resources.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
