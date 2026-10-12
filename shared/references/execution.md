# Native Execution Conventions

## Discovering and Selecting the Binary

Prefer the user-specified path, then an already verified engine for the task, then PATH and system installation locations. On Windows, use `Get-Command godot,godot4 -ErrorAction SilentlyContinue` and known installation directories; prefer `_console.exe` when provided to capture terminal output. On macOS, use `Godot.app/Contents/MacOS/Godot`; on Linux, use the installed binary directly. Do not require the user to configure PATH or silently replace their engine for convenience.

If the command is unavailable on Windows, first enumerate the current workspace and existing tool directories, then search for `*Godot*.exe` with bounded depth in Program Files, LocalAppData/Programs, and the user's Downloads/Desktop. Inspect uninstall registry entries or existing shortcut targets; do not execute unknown downloads. On macOS, check `/Applications` and `~/Applications` for Godot.app. On Linux, check `/usr/bin`, `/usr/local/bin`, `~/.local/bin`, and workspace Godot/AppImage files. Read candidate paths and verify with `--version`; do not scan entire disks without bounds. Portable installations in arbitrary locations cannot be guaranteed discoverable. If all candidates fail, report the searched locations and missing requirements.

Run `--version` and `--help` and record the actual version and editor/export-template type. New-feature examples use 4.7.2 as their baseline; check compatibility for older versions rather than promising support by changing documentation URLs alone.

Pass paths as separate arguments in every command. Do not construct shell commands by concatenating user strings. Scripts use native APIs internally and do not depend on Python, Node, or third-party libraries.

## Four Execution Modes

| Mode | Purpose | Actual limitations |
|---|---|---|
| Ordinary `--headless --script` | Resource generation, logic, physics, and checks | Scripts extend SceneTree/MainLoop; normal project Autoloads execute. |
| `--headless --import` | Native editor asset import | Requires an editor distribution; inspect complete logs and resource artifacts. |
| `--editor --script` | Access public editor singletons when necessary | Use @tool; verify startup, scanning, and shutdown separately. Probes in this version may report shutdown leaks; see the validation report. |
| Real window/rendering process | Shaders, GPU effects, screenshots, and visual acceptance | Do not add --headless; GPU and driver requirements must be met. |

Use the neutral project in the plugin's `shared/host/` when only inspecting data or downloading templates. Pass the target path explicitly when checking a target project; its Autoloads, Resource initialization, and tool scripts may execute, so running the engine is not a static read-only check.

## Command Templates

The names below represent absolute paths to resolve, not environment variables automatically provided by Godot. Create OUT first and always specify an explicit log path on the command line.

```text
GODOT --version
GODOT --help
GODOT --headless --path PROJECT --import --log-file OUT/import.log
GODOT --headless --path PROJECT --script SCRIPT --check-only --log-file OUT/parse.log
GODOT --headless --path PROJECT --script SCRIPT --log-file OUT/run.log -- --out OUT
GODOT --path PROJECT --script PLUGIN/shared/scripts/capture_scene.gd --log-file OUT/capture.log -- --scene res://main.tscn --out OUT/frame.png
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/run_checks.gd --log-file OUT/runner.log -- --manifest MANIFEST --out OUT
```

`--check-only` checks the specified script, not the entire project. `--import` waits for importing; ordinary `--editor --quit` is not an equivalent completion criterion. `--quit-after` counts iterations rather than wall-clock time. Unknown CLI flags may be silently ignored; prefer local --help.

## APIs and Context

Do not access editor singletons or scene nodes that are not yet initialized from `_init()`. Wait for lifecycle readiness through deferred calls and the relevant completion state, with wall-clock limits. Prefer SceneTree + ResourceLoader/ResourceSaver for ordinary resource operations; start the editor only for APIs that truly require it.

Capture Viewport images after `await RenderingServer.frame_post_draw`. Use action state for polled input and Input.parse_input_event when testing `_input`/GUI dispatch.

## Result Contract

Helper scripts emit `GODOT_PLUGIN_RESULT:` followed by JSON containing schema_version, operation, engine_version, platform, display_driver, status, checks, errors, and artifacts. Exit code 0 means the script's checks passed, 1 means failure, and 2 means the environment is blocked or unsupported. Failure to save an output file must also fail the operation.

Child reports cover execution after their checks are registered; the parent must also inspect startup/shutdown logs, exit codes, timeouts, and actual artifacts. Do not ignore outer-process errors because a child report says passed.

Sources: [CLI](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html), [MainLoop](https://docs.godotengine.org/en/4.7/classes/class_mainloop.html), [OS](https://docs.godotengine.org/en/4.7/classes/class_os.html), [Startup source](https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp).
