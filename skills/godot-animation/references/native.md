# Animation Systems: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [Animation](https://docs.godotengine.org/en/4.7/classes/class_animation.html)
- [AnimationLibrary](https://docs.godotengine.org/en/4.7/classes/class_animationlibrary.html)
- [AnimationPlayer](https://docs.godotengine.org/en/4.7/classes/class_animationplayer.html)
- [AnimationTree](https://docs.godotengine.org/en/4.7/classes/class_animationtree.html)
- [SpriteFrames](https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.


## Saving and Validation

Save and reload animation libraries as resources; duplicate only shared animation portions that need independent changes so all instances are not modified together.
The example inserts a position track, actually advances to its midpoint, and asserts the property change; it checks keyframes and duration after saving.

## Common Pitfalls and Recovery

- Seeing animation names in the editor does not prove that tracks target valid nodes.
- Method tracks have side effects; specify whether they should fire when testing seek.

For animation that does not move, check track paths, active state, and processing mode first; for abrupt transitions, inspect RESET and the initial pose.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Animation Data and Playback

Animation.length uses seconds. After `add_track(Animation.TYPE_VALUE)`, call `track_set_path(track, NodePath("Target:position"))` to set a node/property path relative to the animation root, then `track_insert_key(track, seconds, value)`. Put the Animation in an AnimationLibrary, then call `AnimationPlayer.add_animation_library(name, library)`. Named libraries use `library/clip`; the default unnamed library uses clip directly.

Point AnimationTree to an existing AnimationPlayer and set tree_root and active. For state machines, obtain AnimationNodeStateMachinePlayback through `parameters/playback`, then call `travel(state)`. Configure transition edges, blend parameters, and conditions in the graph; travel alone is insufficient without a valid state machine. Record RESET, initial pose, and root motion usage before changing the animation system.

The minimal example actually verifies property-track interpolation and library persistence. The state-machine and event-rig examples additionally verify selected blends and an original bone track/event. Retargeting and collision-aware root motion still require behavior tests on the target skeleton. Avoid having AnimationPlayer and AnimationTree actively drive the same property. `advance(delta)` supports explicit sampling but does not replace acceptance checks for coordinated behavior in actual physics frames.


## Task recipes

Use [recipes.md](recipes.md) for complete development, modification and diagnosis flows. Fixture assertions and visual/platform checks have separate acceptance scopes.

## Task-specific implementation

Read [State transitions, blends and interrupted actions](locomotion.md) before implementing that task. Its example directory is copied in full and its assertions do not replace target-device acceptance.
