---
name: godot-workflow
description: "Develop or iterate complete Godot games from natural-language requirements, coordinating implementation across systems, staged acceptance, and delivery; use for tasks spanning multiple development domains."
---

# Complete Game Development

## Purpose and Scope

New games, prototypes developed into deliverable games, and iteration across systems. Choose the specialist skill directly for isolated UI, collision, or shader changes.

## Prerequisite Checks

Confirm the project directory, game goals, and host platform; check the standard Godot editor distribution. Run baseline checks on existing projects and record known failures first.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Extract the core loop, input scheme, win/loss conditions, and observable acceptance criteria from the request; choose simple playable defaults when nonessential preferences are missing.
2. Deliver a minimal playable slice first, then load project, scene, gameplay, UI, audio, and other domain skills as needed; do not load all skills at once.
3. Keep a runnable main scene at every stage and connect systems with native resources and signals; complete the core loop before expanding levels and presentation.
4. Validate interaction, saving, visuals, and exports; map actual behavior, screenshots, and logs to each requirement.

## File Changes, Saving, and Recovery

Modify project files and domain resources incrementally in existing projects; do not recreate the whole project to fit an example. Examples are validation material, not restrictions on game genres.
For regressions across systems, return to the latest runnable state and preserve the current diff for diagnosis; allow at most two evidence-based recovery rounds for the same failure.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

Build the bundled 2D and 3D examples from empty directories. They must support starting, moving, interacting, completing objectives, restarting, saving, and restoring state, then export and launch successfully.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
