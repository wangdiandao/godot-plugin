---
name: godot-api
description: "Verify Godot CLI options, classes, methods, properties, and version differences using matching-version official documentation, source code, and local API evidence."
---

# Official API Verification

## Purpose and Scope

Uncertain interfaces, version differences, capability research, and official source verification. Ordinary business logic does not require rereading complete documentation at every step.

## Prerequisite Checks

Obtain the actual engine version, build type, and target feature; prefer official class documentation pinned to that version.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Use inspect_environment.gd to query the target class's methods, properties, and signals; run native --dump-extension-api-with-docs when a complete cache is needed.
2. Read the relevant official documentation topic for the question. When Context7 is available, call resolve-library-id followed by query-docs; it is not a runtime dependency.
3. For editor capabilities, baking, and CLI lifecycle questions, inspect _bind_methods and call chains in the matching tag; do not treat internal C++ methods as script APIs.
4. Verify the target call with a minimal script; treat API existence, successful invocation, and correct behavior as separate evidence levels.

## File Changes, Saving, and Recovery

Output only the API summary needed for the task. Store full API dumps in the validation directory rather than duplicating them in every skill.
When versions differ, first switch to matching-version sources. If no public interface exists, report unsupported and assess existing native alternatives.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

Prove that required classes such as SceneTree exist, and confirm that LightmapGI.bake is unbound while VoxelGI.bake is bound; do not infer that the latter works on every GPU.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
