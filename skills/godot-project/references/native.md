# Projects and Configuration: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Develop a runnable project

Record `GODOT --version` and `--help`; inspect existing `project.godot` before writing. For a new project set `config_version=5`, a name, a real `run/main_scene`, renderer and explicit input actions. Pick Compatibility when its hardware reach and feature set fit; 3D does not automatically require Forward+ and 2D can require advanced rendering. Preserve the user's target and available GPU constraints.

Author the main scene and an Autoload script before registering their paths. Autoload values beginning `*` instantiate the singleton; ordering matters when one service depends on another. Keep registration names distinct from global script class names. Input dictionaries contain `deadzone` and `events` with real InputEvent resources. Decide logical `keycode` versus layout-independent `physical_keycode` for the requested controls; provide alternatives appropriate to controllers/touch through the input domain.

Import with `GODOT --headless --path PROJECT --import`, then launch the main scene. A ConfigFile round trip alone does not prove the application can start. The minimal fixture writes a complete generated project, input events and Session Autoload; launch that generated project to check the actual singleton and action map. Confirm the edited file on disk in a fresh engine process.

## Modify or migrate configuration

Capture existing configuration and user edits. Change only the settings required by the feature. Runtime `InputMap.add_action()` is useful for a session or a probe; persist `input/action` through project configuration when the action must survive restart. `ProjectSettings.save()` normalizes the file: review its whole diff and avoid casually rewriting an existing hand-maintained project.

For migration copy the whole source project, preserve `.uid`, importer settings and version evidence, and use official stepwise upgrade guidance. Import using the proposed engine, fix parse/API changes, then compare main-scene startup, Autoload order, physics settings, renderer output and export conditions. Only move the verified changes back after review. Do not use a successful import as proof that rendering, navigation or saved games are compatible.

## Diagnose startup/configuration

| Symptom | Check → cause → fix → retest |
|---|---|
| Main scene not found | Check literal path, UID mapping and file case → moved/missing reference → repair only that reference → fresh import and startup. |
| Action works only this run | Compare InputMap with saved input/* → runtime-only edit → persist InputEvent dictionaries → restart and inspect events. |
| Autoload absent | Check path, script base, `*`, name conflicts and startup log → invalid registration or parse failure → repair script/registration → main scene asserts service state. |
| Global class unknown | Inspect parser errors and import cache generation → script not registered or invalid → fix script then native import → load a caller in a fresh process. |
| Unexpected behavior after upgrade | Compare compatibility/project settings and bindings → changed default → explicitly choose intended setting → representative gameplay plus save reload. |

Sources: [ProjectSettings](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html), [InputMap](https://docs.godotengine.org/en/4.7/classes/class_inputmap.html), [CLI](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html), [upgrading](https://docs.godotengine.org/en/4.7/tutorials/migrating/index.html).

Version evidence: [fixed documentation snapshot](https://github.com/godotengine/godot-docs/tree/9adca4c1c72917bfe1b7be3108abed5ce26696a6) and [tested engine source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). API links use the 4.7 version branch; recheck the actual target engine.
