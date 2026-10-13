---
name: godot-performance
description: "Measure and fix Godot CPU, GPU, memory, loading, and frame pacing bottlenecks using repeatable benchmarks and behavior-preserving changes. Use rendering/UI/audio skills for feature creation."
---

# Performance Measurement and Optimization

## Purpose and Scope

Locate the dominant cost, change an evidenced cause and compare equivalent workloads. Includes profiler-led diagnosis and game-facing optimization; native engine redesign is a research boundary unless explicitly requested with its toolchain.

## Prerequisite Checks

Record engine/build, hardware, OS, active driver/renderer, scene, viewport/resolution, quality, VSync/FPS cap, physics rate and background load. Classify steady frame cost, spikes, startup and memory growth. Separate editor overhead from exported-build behavior and cold caches from warmed execution.

Baseline: Godot 4.7 documentation and locally verified Godot 4.7.2. Read [execution conventions](../../shared/references/execution.md) before the first engine launch; confirm the actual project version.

## Workflow and Key Decisions

1. Reproduce the reported metric and establish a baseline with fixed workload and acceptance budget.
2. Read the relevant CPU/GPU/memory/stall recipe in native.md. Use script timings for script work, rendering timings/profilers for render work and memory monitors/resource lifecycle for memory.
3. Form one testable hypothesis. Keep behavior and visual quality constraints explicit; avoid optimizations that merely drop work or move costs outside the measured scope.
4. Compare alternating before/after samples after warmup, retaining raw data, p50/p95 and environment. Run behavioral equivalence and failure guards before adopting the change.
5. Retest the project and target hardware; report no demonstrated improvement when differences overlap noise. Route the concrete feature change to its domain skill.

## File Changes, Saving, and Recovery

Keep benchmark output separate from project resources. Record prior code/configuration and restore the relevant patch if behavior regresses or improvement is absent. Retain cold/warm and debug/release results separately; do not clear user caches to manufacture a clean result. Use [recovery conventions](../../shared/references/recovery.md) when a failure needs restoration.

## Acceptance and Delivery

The isolated benchmark builds 512 actors and compares radius queries with identical results, 12 warmup pairs and 31 alternating sample pairs. It records raw CPU timings and static-memory observations; speedup is not required to pass equivalence. GPU, frame pacing and target-device optimization need their own real-render evidence. Deliver changed files, exact commands/version/mode, assertions, artifacts, failures and explicit untested scope. Logs and exit codes must agree with reports.

## On-Demand References and Examples

Read [measurement recipes and diagnostics](references/native.md) and run the [repeatable benchmark](assets/examples/minimal/project.godot). Follow [execution](../../shared/references/execution.md) and [evidence](../../shared/references/evidence.md) conventions. No Context7 or profiler addon is a runtime dependency.
