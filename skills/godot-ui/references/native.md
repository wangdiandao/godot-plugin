# UI and Localization: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [Control](https://docs.godotengine.org/en/4.7/classes/class_control.html)
- [Container](https://docs.godotengine.org/en/4.7/classes/class_container.html)
- [Theme](https://docs.godotengine.org/en/4.7/classes/class_theme.html)
- [Translation](https://docs.godotengine.org/en/4.7/classes/class_translation.html)
- [TranslationServer](https://docs.godotengine.org/en/4.7/classes/class_translationserver.html)
- [Input](https://docs.godotengine.org/en/4.7/classes/class_input.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Use Containers for flow layouts and Control anchors for edge positioning; do not combine Container layout with manually positioned children.
2. Put shared styles in a Theme and use theme overrides for local exceptions; configure minimum sizes, focus paths, mouse_filter, and processing while paused.
3. Use Translation/TranslationServer and tr for translation; provide fonts with actual glyph coverage for languages such as Chinese and check redistribution licenses.
4. Verify event paths through Input.parse_input_event or Viewport input; actually check keyboard focus, button clicks, and different resolutions.

## Saving and Validation

Save UI scenes, Themes, translation resources, and required project settings; runtime language switching does not imply persistent settings.
The example creates containers, buttons, a theme, and a translation, verifying layout and language lookup; game tests start gameplay through input events.

## Common Pitfalls and Recovery

- Directly emitting pressed only verifies the callback, not whether a user can click the button.
- Input.action_press does not call _input; use parse_input_event for event tests.

For unresponsive clicks, check occlusion, mouse_filter, and paused processing first. For overflowing text, check container constraints and font coverage rather than simply reducing font size.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Layout, Input, and Fonts

Create the root layer with Control/CanvasLayer, then express layouts with MarginContainer, VBoxContainer, HBoxContainer, and GridContainer. Containers manage child offsets/size; do not compete by manually positioning them every frame. Express constraints through anchors, size_flags, and custom_minimum_size. Capture images at least at the target window size and a narrower aspect ratio to check clipping, focus, and reading order.

Test button activation by calling `grab_focus()` and sending press and release events with `Input.parse_input_event(InputEventAction)` or InputEventKey. `pressed.emit()` checks only the callback, not actual input dispatch. Check focus neighbors, mouse filtering, and process_mode while paused separately.

Theme resources manage colors, fonts, and StyleBoxes. Use Translation.add_message and TranslationServer.add_translation/set_locale for English/Chinese switching; verify fonts separately with `Font.has_char(codepoint)`. OS.get_system_fonts/get_system_font_path can discover local fonts, but do not redistribute system fonts with the game without permission; use appropriately licensed project fonts for cross-platform releases. Built-in fonts or passing translation assertions without a GUI do not prove Chinese text renders without missing glyphs.

References: [Control](https://docs.godotengine.org/en/4.7/classes/class_control.html), [Internationalization](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html).
