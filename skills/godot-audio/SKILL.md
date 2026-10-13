---
name: godot-audio
description: "Develop, modify, and diagnose Godot sound playback, import choices, audio bus routing, effects, volume controls, positional audio, recording, and platform playback conditions."
---

# Audio Assets, Playback, and Mixing

## Purpose and Scope

Implement audible game behavior and persistent mixing configuration. Asset licensing and source creation belong to the asset workflow; interactive music and animation events may require the animation skill.

## Prerequisite Checks

Inspect imported format/sample rate/channels, loop settings, player type/bus, bus send graph, effects, pause modes, actual audio driver/device and target platform. A Dummy driver or headless state test does not establish sound quality, latency or effect output.

Baseline: Godot 4.7 documentation and locally verified Godot 4.7.2. Read [execution conventions](../../shared/references/execution.md) before the first engine launch; confirm the actual project version.

## Workflow and Key Decisions

1. Choose WAV/PCM for short latency-sensitive effects versus compressed music/long ambience from measured memory and decoding needs. Use mono sources for positional audio where appropriate.
2. Follow the native.md recipe for player and bus creation, existing mix modification or silence/latency diagnosis. Resolve bus names before assigning players and route sends toward a bus to the left.
3. Implement volume, mute, voice limits and playback lifecycle using checked data; treat pause, stop, finished, looping and seeking as different behaviors.
4. Save bus layout and user preferences separately, reload without cache and verify player routing/effect identities. Keep original bus layout for rollback.
5. Audition the target device at intended loudness and repeat under load; check Web playback type, permissions and spatial listener behavior before claiming parity.

## File Changes, Saving, and Recovery

Do not overwrite source audio while changing importer options; reimport through the normal asset pipeline. Save checked AudioBusLayout and configuration resources. Changes to AudioServer are runtime state until saved; recover the original layout and stop task-owned players on failure. Use [recovery conventions](../../shared/references/recovery.md) when a failure needs restoration.

## Acceptance and Delivery

For missing routing, reject unresolved names without changing the previous route, repair the intended destination and repeat playback/completion while preserving mix settings. Follow the ordered routing diagnosis in native.md.

Require WAV/resource readback, effective bus routing and actual lifecycle assertions. The minimal example tests generated PCM, saved bus volume/send/limiter, mute/unmute, missing-bus detection and nonlooping completion. Report listening, clipping, device latency, microphone permissions and Web sample-effect behavior separately as untested unless exercised. Deliver changed files, exact commands/version/mode, assertions, artifacts, failures and explicit untested scope. Logs and exit codes must agree with reports.

## On-Demand References and Examples

Read [audio recipes and diagnostics](references/native.md) for the requested operation. Run the [isolated audio example](assets/examples/minimal/project.godot); use [evidence standards](../../shared/references/evidence.md) for device/listening acceptance.
