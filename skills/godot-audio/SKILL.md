---
name: godot-audio
description: "Configure Godot audio playback, buses, effects, and spatial audio, generate basic procedural sound effects, and check playback behavior."
---

# Audio Systems

## Purpose and Scope

Audio resources, playback, mixing, and spatial settings. Audio callback tests are not equivalent to subjective listening acceptance.

## Prerequisite Checks

Confirm audio formats, looping needs, sample rates, bus routing, and target devices; preserve existing audio buses.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Choose AudioStreamPlayer/2D/3D according to playback and spatial requirements; generate short sound effects natively with AudioStreamWAV when appropriate.
2. Manage named buses and effects through AudioServer, separating master volume from music/effects groups; verify that bus names are valid.
3. Persist bus layouts with generate_bus_layout and ResourceSaver when needed, and reference the layout as the project default.
4. Check playback start, stop, looping, muting, and routing; verify waveforms and levels with a real device or native audio capture.

## File Changes, Saving, and Recovery

Save AudioBusLayout, stream resources, and volume settings; do not repeatedly add buses with the same name or modify all shared audio.
For silence, check the player, bus, muting, and device first. The headless Dummy driver verifies only the logical path; do not claim to have heard audio.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example generates nonzero PCM, checks bus routing, and plays audio; it reloads the saved layout to confirm buses. Report subjective audio quality separately.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
