# Complete Game Development: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [ProjectSettings](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)
- [SceneTree](https://docs.godotengine.org/en/4.7/classes/class_scenetree.html)
- [Input](https://docs.godotengine.org/en/4.7/classes/class_input.html)
- [PackedScene](https://docs.godotengine.org/en/4.7/classes/class_packedscene.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Extract the core loop, input scheme, win/loss conditions, and observable acceptance criteria from the request; choose simple playable defaults when nonessential preferences are missing.
2. Deliver a minimal playable slice first, then load project, scene, gameplay, UI, audio, and other domain skills as needed; do not load all skills at once.
3. Keep a runnable main scene at every stage and connect systems with native resources and signals; complete the core loop before expanding levels and presentation.
4. Validate interaction, saving, visuals, and exports; map actual behavior, screenshots, and logs to each requirement.

## Saving and Validation

Modify project files and domain resources incrementally in existing projects; do not recreate the whole project to fit an example. Examples are validation material, not restrictions on game genres.
Build the bundled 2D and 3D examples from empty directories. They must support starting, moving, interacting, completing objectives, restarting, saving, and restoring state, then export and launch successfully.

## Common Pitfalls and Recovery

- A startup smoke test alone cannot prove that a game is playable.
- Each domain has its own acceptance criteria; the number of generated files does not measure completion.

For regressions across systems, return to the latest runnable state and preserve the current diff for diagnosis; allow at most two evidence-based recovery rounds for the same failure.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## From Requirements to Delivery

Translate natural-language requirements into observable acceptance criteria first: startup screen, player input, win/loss conditions, restart, sound triggers, data persistence, target resolutions, and delivery platforms. Use replaceable procedural assets when style details are missing; ask only about missing requirements that change scope. Deliver a short playable flow before expanding content.

At each stage, record only concrete inputs/outputs: project directory, changes, commands, result JSON, and prerequisites for the next step. Do not equate "scene generated" with "gameplay runnable". Load relevant domain skills during implementation; before delivery, run parsing, import, behavior, real rendering, and post-export launch checks together.

The bundled `../assets/examples/game-2d/` and `game-3d/` are complete small games with menus, collision-based collection, victory, restart, native PCM sound effects, and versioned JSON saves. Inputs are arrow keys, Enter/Space, and R. Run normally with `GODOT --path GAME`; run automated acceptance with `GODOT --path GAME --log-file OUT/game.log -- --self-test --out OUT`. The latter writes to OUT instead of real player saves. The final two collectibles use test teleportation; the first is triggered through actual input and physics movement. Do not describe this test as a manual playthrough.

In the source delivery, `tests/integration/desktop.gd` runs import, Windows export, exported self-tests, and Web builds from clean copies. Examples in the install package do not depend on this test directory.
