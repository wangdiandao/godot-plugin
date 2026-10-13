---
name: godot-rendering
description: "Build, modify, and diagnose Godot rendering, materials, shaders, lights, particles, Viewports, and HDR presentation. Use godot-performance for measured bottleneck optimization."
---

# Rendering, Materials, and HDR

## Purpose and Scope

Deliver the requested appearance and renderer fallback. Covers game-facing rendering APIs; engine CPU allocator and Polygon2D internals are research examples, not script operations.

## Prerequisite Checks

Inspect engine/build, active renderer and driver, target platform, imported meshes/textures, material ownership, WorldEnvironment and Viewport configuration. Capture the symptom on the real render path. HDR additionally needs a supported OS/display/driver and physical HDR display; headless runs cannot validate appearance.

Baseline: Godot 4.7 documentation and locally verified Godot 4.7.2. Read [execution conventions](../../shared/references/execution.md) before the first engine launch; confirm the actual project version.

## Workflow and Key Decisions

1. Choose renderer from target capability and required effects; verify effective method/driver after fallback.
2. Read the relevant material/shader, lighting/particles, Viewport or HDR recipe in native.md. Preserve artistic intent while changing one relevant setting or resource.
3. Use shared materials for common appearance; duplicate only for instance exceptions or use supported instance uniforms. Check normal/tangent data, color encoding and transparent-pass behavior.
4. Build an isolated scene that reproduces the desired effect and failure. Apply changes to the requested project, save resources and reload without cache before testing actual pixels.
5. Diagnose artifacts by renderer, geometry, material, depth, lighting and presentation stage; measure costs with godot-performance when optimization is requested.

## File Changes, Saving, and Recovery

Record existing material/scene/resource references before edits. Keep imported source assets authoritative and persist editable overrides separately. Check ResourceSaver errors and cache-ignored readback; shared-resource mutations affect all users. Restore the prior material/settings if the retest fails; retain failed captures for diagnosis. Use [recovery conventions](../../shared/references/recovery.md) when a failure needs restoration.

## Acceptance and Delivery

Require material/parameter readback and rendered evidence at target resolution/backend. The minimal example verifies saved shader parameters, independent material modification and actual changed GPU pixels. Report HDR, stereo, target-device and visual checks as untested until exercised; a screenshot is not HDR calibration. Deliver changed files, exact commands/version/mode, assertions, artifacts, failures and explicit untested scope. Logs and exit codes must agree with reports.

## On-Demand References and Examples

Read [native recipes and diagnostics](references/native.md) for the selected rendering task. Run the [shader example](assets/examples/minimal/project.godot) for actual GPU pixels or the [3D resource example](assets/examples/materials/project.godot) for scene/material readback; use the matching script and explicit output directory. For source contracts and visual limits, use [evidence standards](../../shared/references/evidence.md).
