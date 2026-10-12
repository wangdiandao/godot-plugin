---
name: godot-export
description: "Prepare official Godot export templates and presets, build target-platform artifacts, and verify build results and platform prerequisites."
---

# Builds and Exports

## Purpose and Scope

Local builds and artifact validation. Assess store publication, signing accounts, and external platform SDK requirements separately.

## Prerequisite Checks

Confirm the engine version, target OS/architecture, renderer, and matching templates; inspect existing export_presets.cfg and confidential credentials.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Use prepare_templates.gd to download official release templates or accept a verified local TPZ, then extract the required templates into the specified directory.
2. Create or update existing export presets; point custom template paths to matching-version files and verify options against the current platform API.
3. Run native import first, then --headless --export-debug or --export-release; create the output directory beforehand and match the preset name exactly.
4. Inspect export logs, executables, and data packs, and launch the native target. Record Web packaging success separately from browser runtime validation.

## File Changes, Saving, and Recovery

Modify only the target preset and preserve others; do not write credentials into public examples or validation logs. Package template caches, test reports, and source code separately.
Prepare missing templates automatically; report blocked for missing SDKs, signing, or host platform requirements. Running the project in the editor is not a substitute for a failed executable export.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

Export both example games for Windows and launch their self-tests; build Web packages and record browser validation status. Reject failed template verification before extraction.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
