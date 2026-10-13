# Data and Save Files: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Develop strict versioned saves

Write runtime player data beneath `user://`; keep source-authored definitions in `res://`. Define required fields, types, finite/integral numeric ranges and a schema version. JSON numbers may parse as float: accept a score only when finite, integral and within its supported bound before casting. A valid JSON value can still be the wrong schema; distinguish parse error, invalid shape, unsupported version, missing file and read/write failure.

Implement ordered migration functions v1→v2→v3, validate each output and migrate in memory. Never overwrite a future-version save with defaults. Preserve corruption evidence and try a known valid backup only after it passes the same schema checks; identify recovery to the player/caller so it cannot silently erase progress. If both fail, return an explicit recovery-required result.

The minimal case exercises old-version migration, fractional/negative/NaN and future schema rejection, staged write/readback, deliberate corruption, validated backup recovery, write failure and pre-commit conflict detection. It writes only to OUT. It models a single writer and does not claim power-loss atomicity or a process-safe lock.

## Modify the save schema or commit sequence

Capture the original content/hash. Construct new valid data, write a unique same-directory temporary file, flush/close and reparse it. Before committing compare the target against the expected original hash; abort on changed content. Preserve the old target as a validated backup, then rename staged data into place and verify readback. Check every rename result. If commit fails, restore only when the target is still absent/owned by this operation; preserve both versions if another writer intervened. Hash checking alone is not an atomic cross-process compare-and-swap: use one save owner or a platform-tested locking design.

Do not interpret `flush()` as a guarantee covering directory metadata, multiple files or every hardware failure. For multiple related files use a documented commit record or a single envelope and test interrupted transitions. Use ConfigFile for independent settings when its Variant format is appropriate. Avoid full-object deserialization for untrusted saves.

## Authored Resource recipe

Define default-constructible exported Resource fields, instantiate/load trusted definitions, and select shallow/internal/all duplication according to mutable ownership. The `resources/` fixture covers external versus internal duplication, repeated alias preservation, collection independence, saved readback and scene-local meshes; copy that whole directory and run its `example.gd` using the invocation above. This is a current runtime rerun of the researched behavior, not merely a reference to an old probe.

Normalize Windows external Resource save paths to forward slashes before saving: backslashes can survive into a text resource reference and be interpreted incorrectly on reload. The portable fixture normalizes OUT and fails explicitly when the saved root cannot load.

## Diagnose data faults

| Symptom | Check → cause → fix → retest |
|---|---|
| Save parses but progress is invalid | Validate fields/number bounds → malformed schema or truncation → reject before migration → fractional, negative and missing-field fixtures. |
| Future save reset to defaults | Inspect version dispatch → unsupported version collapsed into missing → preserve file and report unsupported → compare bytes before/after load. |
| Corrupt target with valid backup | Validate both independently → interrupted/corrupt target → recover explicitly from backup → verify recovered score and preserve corrupt evidence. |
| Target changes during save | Compare expected fingerprint before commit → external/concurrent write → abort preserving both → inject changed target before commit. |
| Mutable config leaks between actors | Inspect Resource identities → external shared data → move runtime state or choose duplication mode → mutate one clone and reload disk definition. |

Sources: [saving games](https://docs.godotengine.org/en/4.7/tutorials/io/saving_games.html), [JSON](https://docs.godotengine.org/en/4.7/classes/class_json.html), [FileAccess](https://docs.godotengine.org/en/4.7/classes/class_fileaccess.html), [DirAccess](https://docs.godotengine.org/en/4.7/classes/class_diraccess.html), [Resource](https://docs.godotengine.org/en/4.7/classes/class_resource.html).

Version evidence: [fixed documentation snapshot](https://github.com/godotengine/godot-docs/tree/9adca4c1c72917bfe1b7be3108abed5ce26696a6) and [tested engine source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). API links use the 4.7 version branch; recheck the actual target engine.
