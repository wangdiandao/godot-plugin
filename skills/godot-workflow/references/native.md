# Complete Game Development: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Develop a complete vertical slice

Translate the request into observable player actions: start, move, interact, complete/fail, restart and persist/restore when requested. Choose minimal gameplay defaults for noncritical omissions and keep the user's genre/platform. Record acceptance per action before building systems. A headless scene graph with a Player node is not a playable game.

Keep the main scene runnable. First implement input→movement→objective→win/loss→restart; then connect HUD, sound and presentation. Route to project, scenes, physics/navigation, UI/rendering, data or export only as that work becomes necessary. Use architecture when contracts or coupled lifetimes become the actual problem. Let gameplay own rules and expose state; presentation sends commands and observes completed facts.

Use an isolated checkpoint to prove state transitions, then exercise the actual game. Bundled `game-2d/` and `game-3d/` projects demonstrate playable loops; read their scripts and automated controls before running. They are genre-neutral starter examples, not a requirement to reproduce their art or mechanics. Use screenshots for visual acceptance and actual playback for audio. Export only when the requested platform/toolchain is available, then run the exported application.

Copy either whole game directory to GAME and create a fresh OUT, then run `GODOT --headless --path GAME --log-file OUT/engine.log -- --self-test --out OUT`. This asserts start, movement/collision, win, save/readback and keyboard restart; remove `--headless` to also capture the viewport. Headless audio stream configuration does not establish audible output. A restart key handled in `_input()` takes precedence over a focused menu; choose `_unhandled_input()` instead when UI should consume the command. Synthetic input must traverse subsequent frames before testing the result.

## Modify a feature across systems

Record the current loop and known defects. Follow the requested change through input, authoritative state, presentation and persistence. For example, adding a limited jump resource needs command validation, HUD initialization, save migration if persistent and restart reset if transient. Test both exhausted and available states, load old saves, and verify repeated restart does not retain old signal subscribers.

Ship a minimal coherent slice per checkpoint rather than leaving several disconnected systems half-built. Save/reload authored scenes/resources and inspect actual user flow after each cross-system change. Do not claim a specialist's fixture proves the game's integration: rerun the original main scene and caller paths.

## Diagnose a broken loop

| Symptom | Check → cause → fix → retest |
|---|---|
| Input logged but objective unchanged | Trace command result and state → rejected/missing rule transition → repair boundary → valid/invalid action and HUD response. |
| Restart duplicates scoring/audio | Count persistent listeners and old nodes → teardown omission → disconnect/remove old world → three restarts and effect counts. |
| Saved checkpoint lacks gameplay | Inspect owner/storage fields → only hierarchy saved → serialize requested state explicitly → mutate then restore actual values. |
| Headless passes but game unusable | Inspect renderer/input/audio environment → state tests omit presentation → test real window/device → visual and interaction evidence. |
| Specialist fixture passes, game fails | Follow integration paths/version/settings → contract differs → adapt fixture to real callers → run complete original loop. |

The minimal fixture is a persistence checkpoint; it must not be reported as complete gameplay validation. Headless, visual, hearing, export and natural-language host routing are separate evidence categories. Sources: [first 2D game](https://docs.godotengine.org/en/4.7/getting_started/first_2d_game/index.html), [first 3D game](https://docs.godotengine.org/en/4.7/getting_started/first_3d_game/index.html), [best practices](https://docs.godotengine.org/en/4.7/tutorials/best_practices/index.html).

Version evidence: [fixed documentation snapshot](https://github.com/godotengine/godot-docs/tree/9adca4c1c72917bfe1b7be3108abed5ce26696a6) and [tested engine source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). API links use the 4.7 version branch; recheck the actual target engine.
