---
name: godot-assets
description: "Import, reimport, or generate images, fonts, audio, and models for Godot, configure import parameters, and verify that resources load."
---

# Asset Import

## Purpose and Scope

Source assets, import parameters, and procedural resource generation. Complex external asset authoring is outside native import capabilities.

## Prerequisite Checks

Confirm source formats, licensing sources, target platform, and renderer; prefer formats Godot supports directly, such as PNG/SVG/WAV/glTF.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Place source assets in the project directory and run native --import to create real .import configuration before changing verified params fields.
2. Invoke native reimport; do not edit .godot/imported directly. Respect editor lifecycle requirements when EditorFileSystem is needed.
3. Generate task-appropriate basic assets with Image, GradientTexture, ArrayMesh, or AudioStreamWAV; do not require image or DCC tools unnecessarily.
4. Load imported resources with ResourceLoader.load using source paths, then check resource types, dimensions, or audio parameters.

## File Changes, Saving, and Recovery

Commit source files, .import settings, and .uid files, not .godot caches. Keep stable external resource paths and avoid unintended recompression or source file overwrites.
Distinguish corrupt source files, unsupported formats, and missing requirements when imports fail. Reimport affected resources first, at most twice; do not delete the entire project cache.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example generates a PNG and verifies image reload; integration tests invoke actual import and check texture loading, reimport after parameter changes, and missing source files.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [complete task recipes and diagnostic paths](references/recipes.md) for developing, modifying or repairing this domain; choose the recipe matching the requested behavior.

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
