# Audio Systems: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [AudioServer](https://docs.godotengine.org/en/4.7/classes/class_audioserver.html)
- [AudioBusLayout](https://docs.godotengine.org/en/4.7/classes/class_audiobuslayout.html)
- [AudioStreamWAV](https://docs.godotengine.org/en/4.7/classes/class_audiostreamwav.html)
- [AudioStreamPlayer](https://docs.godotengine.org/en/4.7/classes/class_audiostreamplayer.html)
- [AudioEffectCapture](https://docs.godotengine.org/en/4.7/classes/class_audioeffectcapture.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Choose AudioStreamPlayer/2D/3D according to playback and spatial requirements; generate short sound effects natively with AudioStreamWAV when appropriate.
2. Manage named buses and effects through AudioServer, separating master volume from music/effects groups; verify that bus names are valid.
3. Persist bus layouts with generate_bus_layout and ResourceSaver when needed, and reference the layout as the project default.
4. Check playback start, stop, looping, muting, and routing; verify waveforms and levels with a real device or native audio capture.

## Saving and Validation

Save AudioBusLayout, stream resources, and volume settings; do not repeatedly add buses with the same name or modify all shared audio.
The example generates nonzero PCM, checks bus routing, and plays audio; it reloads the saved layout to confirm buses. Report subjective audio quality separately.

## Common Pitfalls and Recovery

- Do not confuse audio decibels with linear gain.
- AudioStreamGenerator needs continuous buffer filling; creating the resource alone does not produce sound.

For silence, check the player, bus, muting, and device first. The headless Dummy driver verifies only the logical path; do not claim to have heard audio.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Buses and Procedural Sound

Find buses with AudioServer.get_bus_index(name), using add_bus/set_bus_name only if absent. Verify names before assigning a player's bus; missing buses fall back, so play() alone does not prove correct routing. Add effects with add_bus_effect. AudioServer.generate_bus_layout() returns an AudioBusLayout that ResourceSaver.save can write as `.tres` for reference in project configuration.

AudioStreamWAV format, mix_rate, and stereo must match the PCM data. The example uses 22050 Hz, 16-bit mono signed PCM and writes samples with PackedByteArray.encode_s16; configure the complete stream before calling AudioStreamPlayer.play. Only continuous streams need AudioStreamGenerator/Playback buffers; do not reimplement ordinary file playback.

Headless/dummy audio verifies only data, routing, and playback state, not speaker output or perceived mix quality. Spatial audio also needs checks for listeners, attenuation, distance, and occlusion strategy. Snapshot existing buses before changing them and restore that layout after testing; do not persist debug buses in the user's defaults.
