# Data and Save Files: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [FileAccess](https://docs.godotengine.org/en/4.7/classes/class_fileaccess.html)
- [DirAccess](https://docs.godotengine.org/en/4.7/classes/class_diraccess.html)
- [JSON](https://docs.godotengine.org/en/4.7/classes/class_json.html)
- [ConfigFile](https://docs.godotengine.org/en/4.7/classes/class_configfile.html)
- [Resource](https://docs.godotengine.org/en/4.7/classes/class_resource.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Prefer custom Resources for static game configuration, ConfigFile for user settings, and explicitly verifiable JSON or binary structures for player saves.
2. Save player data to user://; validate the top-level type, version, required fields, and numeric ranges when reading, and return distinct errors.
3. Write and flush a temporary file, validate the new data, then replace the target; preserve the original and diagnostic temporary file if a platform rename fails.
4. Write explicit migrations for existing versions and migrate in memory before saving; preserve unknown newer versions rather than overwriting them with defaults.

## Saving and Validation

Separate user data from res:// configuration resources. Recovery applies only to this operation's writes; clearly report backups and conflicts with concurrent changes.
The example round-trips a valid save and rejects corrupt JSON; tests cover old-version migration, unknown newer versions, and write failures.

## Common Pitfalls and Recovery

- JSON numbers may load as float; validate or convert them according to the data contract before use.
- ResourceLoader executes project script initialization; do not load arbitrary external save files as trusted Resources.

A missing file may initialize default state; preserve and report corrupt files rather than treating them as new players. Do not erase old saves when writing fails.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Save File Contract

Use user:// for writable runtime data and res:// for read-only game content. Include an explicit version in the file structure. JSON.parse_string returns Variant: validate Dictionary, required keys, types, and ranges before stepwise migration. Stop writing and preserve the original for unknown future versions; retain a copy of corrupt files instead of overwriting them with empty defaults.

Safe write order: construct valid data → create a unique temporary file in the same directory → flush/close → reparse and validate → compare the target's pre-change hash → back up the old file → commit with rename. On failure, restore only this operation's backup; if an external change altered the target, report the conflict and preserve both versions. A single rename does not make multiple files transactional; use an explicit commit record and recovery strategy.

ConfigFile suits settings and supports Godot Variants; JSON suits explicit basic-type interchange. Do not deserialize untrusted objects into executable resources with `str_to_var` or full-object deserialization. Local encryption does not make sensitive data an authoritative anti-cheat source.

The minimal example covers v1→v2 migration and malformed structures; complete games additionally verify writing and readback. These are small demonstrations; concurrent cross-process writes, large saves, and power-loss recovery require further tests for the specific format. Sources: [Saving games](https://docs.godotengine.org/en/4.7/tutorials/io/saving_games.html), [FileAccess](https://docs.godotengine.org/en/4.7/classes/class_fileaccess.html).
