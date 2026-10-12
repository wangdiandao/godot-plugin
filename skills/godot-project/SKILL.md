---
name: godot-project
description: "Create, take over, or migrate Godot projects, discover the engine, and configure project settings, input maps, Autoloads, and directory structure."
---

# Projects and Configuration

## Purpose and Scope

Project initialization, project settings, and version migration. Do not turn ordinary feature work into a full-project migration.

## Prerequisite Checks

Read project.godot, the main scene, Autoloads, and existing version evidence; confirm the actual binary with --version and --help.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Discover the engine in order: user-specified path, known workspace installations, PATH, and common system installation locations. Prefer the console wrapper on Windows and the executable inside the app bundle on macOS.
2. For a new project, create a minimal project.godot and choose a main scene. Default to Compatibility for 2D; choose a 3D renderer based on target devices and actual capabilities. Preserve existing project settings.
3. Persist input actions as InputEvent resources under ProjectSettings input/*; runtime InputMap changes are not saved automatically.
4. After editing project settings, run --headless --path PROJECT --import. Perform version migration on a copy and check official migration notes and breaking changes.

## File Changes, Saving, and Recovery

Use minimal diffs for project configuration. ProjectSettings.save() normalizes the file, so use it only for controlled new projects or when a complete save is explicitly needed; preserve existing feature tags.
For missing main scenes, check paths and UIDs; for missing type caches, run native import first. Do not resolve errors by deleting Autoloads or silently upgrading the engine.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The new project must import successfully; input mappings must survive save and reload; the main scene and Autoloads must load. Tests must not change global editor settings for the user's project.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
