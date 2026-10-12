---
name: godot-rendering
description: "Implement or troubleshoot Godot shaders, material effects, lighting, environments, particles, post-processing, and rendering performance."
---

# Rendering and Effects

## Purpose and Scope

Visual rendering, material shaders, and effect optimization. Keep GPU capabilities and renderer differences explicit in conclusions.

## Prerequisite Checks

Inspect rendering_method, the actual rendering device, target platform, and required effects; headless execution cannot establish visual correctness.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Choose native materials or ShaderMaterial; do not reimplement a complete shading model when built-in materials suffice.
2. Configure lights, environment, and particle resources; identify support requirements for Compatibility/Mobile/Forward+.
3. Render an object using the shader in a real rendering mode, capturing logs and frame images; inspect the visual result even when compilation reports no errors.
4. Before optimizing, record comparable scenes, resolutions, and metrics; do not draw GPU performance conclusions from headless FPS.

## File Changes, Saving, and Recovery

Save materials, shaders, and environment resources separately; inspect usage before changing shared materials. Write screenshots and measurements to a hidden validation directory.
Locate shader errors in compilation logs and retest; report GPU limitations instead of silently removing requested effects.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example shader renders in a real window, reads back the image, and verifies known colors; headless execution must return unsupported.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
