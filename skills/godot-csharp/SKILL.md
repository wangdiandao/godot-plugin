---
name: godot-csharp
description: Build, modify, and diagnose Godot C# gameplay scripts, resources, signals, and .NET projects; use when managed code or its build/debug pipeline is part of the task.
---

# Godot C# Development

## Purpose and Scope

Implement managed gameplay and resources with Godot's generated bindings. Use godot-editor-tools for editor UX and godot-export for delivery after the managed project builds. Engine Mono-module development is outside this execution workflow.

## Prerequisite Checks

Record the actual .NET Godot version, SDK architecture/version, csproj SDK/target framework and platform. A standard Godot executable cannot run C#; installed dotnet alone does not prove support. Preserve existing NuGet sources and global.json. Read [native.md](references/native.md) for build and binding checks and [execution](../../shared/references/execution.md) before launching.

## Workflow and Key Decisions

1. Inspect the existing scene/script contract and choose Node, Resource or plain managed data. Keep Godot classes partial and attached filenames/class names consistent.
2. Compile before exercising exports, signals or tools; generated bindings and diagnostics are part of the implementation. Use generated MethodName/SignalName identifiers for dynamic calls.
3. Separate managed values from Variant-compatible boundaries; copy, modify and reassign struct properties. Keep engine-object access on its permitted thread.
4. Test concrete state changes, signal lifetime and saved resource readback. Diagnose build errors before blaming editor caches; use a clean task copy for cache hypotheses.

## File Changes, Saving, and Recovery

Preserve csproj references, target framework, NuGet configuration and user IDE settings. Save source and rebuild; serialize only exported/storage properties and check actual uncached reload. Explicitly disconnect captured lambdas and custom event subscriptions when receiver lifetimes end. Retain build logs and failed artifacts; limit identical retries to two informed changes.

## Acceptance and Delivery

Require a successful managed build and a .NET Godot execution asserting behavior. The minimal example checks a C# Resource's clamped property, generated signal and saved/reloaded state; standard Godot reports unavailable rather than a compilation pass. Record platform exports separately: desktop supported, Android/iOS conditional, Godot 4 C# Web unavailable. Actual managed debugger attachment is a separate check.

## On-Demand References and Examples

- [Build, modification, diagnosis and platform recipes](references/native.md).
- [Runnable resource example](assets/examples/minimal/project.godot), including ExampleResource.cs and example.gd.
- [Evidence](../../shared/references/evidence.md) and [recovery](../../shared/references/recovery.md).
