# Projects and Configuration: Native Operations Reference

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
- [InputMap](https://docs.godotengine.org/en/4.7/classes/class_inputmap.html)
- [InputEventKey](https://docs.godotengine.org/en/4.7/classes/class_inputeventkey.html)
- [ConfigFile](https://docs.godotengine.org/en/4.7/classes/class_configfile.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Discover the engine in order: user-specified path, known workspace installations, PATH, and common system installation locations. Prefer the console wrapper on Windows and the executable inside the app bundle on macOS.
2. For a new project, create a minimal project.godot and choose a main scene. Default to Compatibility for 2D; choose a 3D renderer based on target devices and actual capabilities. Preserve existing project settings.
3. Persist input actions as InputEvent resources under ProjectSettings input/*; runtime InputMap changes are not saved automatically.
4. After editing project settings, run --headless --path PROJECT --import. Perform version migration on a copy and check official migration notes and breaking changes.

## Saving and Validation

Use minimal diffs for project configuration. ProjectSettings.save() normalizes the file, so use it only for controlled new projects or when a complete save is explicitly needed; preserve existing feature tags.
The new project must import successfully; input mappings must survive save and reload; the main scene and Autoloads must load. Tests must not change global editor settings for the user's project.

## Common Pitfalls and Recovery

- --quit-after counts main loop iterations, not seconds.
- Unknown CLI flags may be ignored; check the local --help first.

For missing main scenes, check paths and UIDs; for missing type caches, run native import first. Do not resolve errors by deleting Autoloads or silently upgrading the engine.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Configuration Operations

`project.godot` uses ConfigFile format. A new project must at least set `config_version=5`, application/config/name, application/run/main_scene, and an explicit rendering/renderer/rendering_method. Compatibility must satisfy the requirements; do not silently discard requested effects because hardware lacks Forward+ support.

The following **snippet** belongs inside a SceneTree execution function; run it in an isolated copy of the target project:

```gdscript
var event := InputEventKey.new()
event.physical_keycode = KEY_SPACE
ProjectSettings.set_setting("input/jump", {"deadzone": 0.2, "events": [event]})
ProjectSettings.set_setting("autoload/Session", "*res://session.gd")
var error := ProjectSettings.save()
```

Before saving, confirm that `session.gd` exists and extends Node; `*` enables that Autoload. InputMap is runtime state, and `add_action()` alone does not persist project configuration. Restart after saving to verify that the Autoload is created exactly once and receives input. `ProjectSettings.save_custom(path)` can generate isolated output; still check its Error.

When taking over a project, identify the source version of `.godot`, plugin dependencies, C#, and GDExtension first. This plugin does not automatically convert C# into code runnable by the standard distribution. Before upgrading, isolate a copy of source files and preserve UIDs; never perform irreversible migration on the user's only copy. See the [upgrade guide](https://docs.godotengine.org/en/4.7/tutorials/migrating/index.html) for version migration.
