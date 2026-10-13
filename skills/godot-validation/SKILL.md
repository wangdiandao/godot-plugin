---
name: godot-validation
description: "Check and diagnose Godot project parsing, importing, runtime, interaction, visual, and performance issues, and establish repeatable validation workflows."
---

# Validation and Diagnostics

## Purpose and Scope

Behavior testing and diagnostics. Match check levels to actual changes; do not unconditionally run every test for small edits.

## Prerequisite Checks

Record engine version, platform, renderer, current failures, and target behavior; give all tests timeouts and isolated output locations.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Reproduce the intended failure in a bounded fixture and establish an observable success/failure contract. Select parsing, import, uncached resource reload, behavior and visual checks; --check-only covers only the specified script.
2. Run cases.json with run_checks.gd; child processes emit explicit results, while the parent also checks logs and exit codes.
3. Verify events with Input.parse_input_event and polled input through action state; assert observable state instead of passing after a fixed delay.
4. Match negative cases to their intended cause and required artifacts/state; an unrelated error is a failed negative test. Classify timeout and missing report separately. Inspect startup/shutdown logs even when the script or engine exits 0.

## File Changes, Saving, and Recovery

Keep tests and reports in .godot-plugin or the specified output directory, outside release packages. Terminate only processes started by the current test.
Timeouts, missing results, and error logs are failures. Rerun affected cases after recovery and preserve the original failure evidence.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example actually launches isolated parse-error, missing-resource, runtime-error, logged-error/exit-0, timeout, missing-report and unrelated-fault children. It asserts the expected diagnostic and rejects an unrelated fault; negative-case success means detection, never success of the faulty operation. Visual, audio and performance acceptance require their corresponding environments and measurement conditions.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
