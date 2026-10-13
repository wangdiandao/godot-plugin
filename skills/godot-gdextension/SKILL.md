---
name: godot-gdextension
description: Build, integrate, modify, and diagnose native Godot GDExtension libraries, public bindings and platform loading; use for native extension code rather than engine-source modules.
---

# Native GDExtension Development

## Purpose and Scope

Create separately distributable native behavior with public GDExtension/godot-cpp interfaces. Engine modules and custom rendering/physics backends need a separate source-build scope; reading those interfaces does not establish a complete backend implementation.

## Prerequisite Checks

Record engine/API revision, godot-cpp commit, platform/architecture, real_t precision and compiler ABI. Discover SCons or supported CMake plus Python binding generator; extra tools apply only to native tasks. Read [native.md](references/native.md) and [execution](../../shared/references/execution.md). No imaginary 4.7 godot-cpp branch: verify available revisions and target the oldest API actually needed.

## Workflow and Key Decisions

1. Define a small public interface and choose Node versus Resource/RefCounted lifetime. Bind methods, getters/setters and Variant-compatible signals at scene initialization.
2. Build debug and release configurations independently; CMake Debug symbols and Godot template_debug features are different settings.
3. Configure .gdextension entry symbol and specific-before-generic feature paths. Keep dependent libraries explicit and paths movable.
4. Import an isolated host, confirm class registration, call methods/signals, assert failure bounds and uncached serialized readback. Follow the explicit 4.7.2 recipe bootstrap boundary in the reference; a nonzero cold import is a failure even with a clean textual log. DLL existence alone is insufficient.

## File Changes, Saving, and Recovery

Preserve existing native build flags and API JSON provenance. Close task-owned Godot processes before replacing a locked DLL; do not kill unrelated editors. Keep build products and downloaded bindings outside source/release packs. Pair resource ownership and callbacks; do not free borrowed RIDs. Capture exact loader/compiler errors before changing version bounds.

## Acceptance and Delivery

Require compilation, real engine loading and public API behavior. The resource recipe tests a clamped property, signal and save/readback after build; without its compiled library it reports unavailable. Rebuild and run every shipped architecture/precision/target; missing foreign platform checks remain untested. Package movement must preserve relative library/dependency references.

## On-Demand References and Examples

- [Native build/load/dependency recipes and diagnosis](references/native.md).
- [Resource binding project](assets/examples/minimal/project.godot), CMakeLists.txt, native.cpp and extension template.
- [Evidence](../../shared/references/evidence.md), [recovery](../../shared/references/recovery.md).
