# Official API Verification: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Verify a new operation

State the exact operation, such as “save a PackedScene and invoke its persisted connection after reload”. Record the binary version/hash/build, execution mode and platform; distinguish the 4.7 documentation branch from a specific 4.7.2 distribution. Resolve Godot Engine through Context7 and query each concept separately when the connector is available. A network failure is a research limitation, not a runtime dependency; use the fixed official source available to the task and record the fallback.

Read the target class description, method signature, parameter units, default values, restrictions and linked tutorial. Inspect `_bind_methods` or module registration in the matching engine source; a C++ function without a public binding cannot be called simply because the source mentions it. Run the shared `inspect_environment.gd` for focused ClassDB evidence; `--dump-extension-api-with-docs` is useful for complete binding caches but is not behavioral verification. Check `--help` separately for CLI flags, which are not ClassDB methods.

Build a small call in the required editor/runtime context. Assert its returned result, changed state and saved readback when relevant. Add the failure condition that matters to the task, such as absent dependency or invalid input. The minimal fixture inspects public methods and proves PackedScene ownership exclusion and round-trip behavior. Existing negative LightmapGI.bake binding evidence establishes only that specific script interface boundary; it does not prove every bake alternative runs.

## Modify code across a version change

Compare the old/new signature, property/default and enum values against fixed source revisions. Search all callers and serialized names. Replace deprecated APIs with the matching public interface, preserve required compatibility switches consciously, then compile/import and run original behavior plus the relevant negative case. Avoid replacing an enum with a guessed integer or treating a renamed C# property as identical GDScript spelling.

For editor-only tools use an editor context and make tool scripts explicit. For language extensions check generated C# or godot-cpp binding names and toolchains through the respective skill. Native pointer APIs, backend internals or engine-source optimizations remain research boundaries unless the task includes their actual development environment.

## Diagnose API evidence conflicts

| Symptom | Check → cause → fix → retest |
|---|---|
| Documentation method absent | Compare versions/build and ClassDB → old snippet/internal method → match version or use supported path → minimal call in actual engine. |
| Method exists but call fails | Inspect arguments/context/RID lifetime → invalid setup → build required resource/context → check return and actual output. |
| Example uses old names | Compare declaration/binding and snippet → stale example → correct verified spelling → parse and execute in both requested languages. |
| Tool succeeds only in editor | Inspect editor-only flags → runtime lacks editor service → run authoring operation in editor and deliver saved result → load result in runtime. |
| Successful call produces wrong state | Check units, coordinate space, cache and defaults → semantic mismatch → assert explicit contract → rotated/transformed or reload fixture. |

## Fixed evidence sources

Documentation source snapshot: [godot-docs 9adca4c](https://github.com/godotengine/godot-docs/tree/9adca4c1c72917bfe1b7be3108abed5ce26696a6). Engine source tested here: [4.7.2 ed1daf0](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). Use [ClassDB](https://docs.godotengine.org/en/4.7/classes/class_classdb.html), [Object](https://docs.godotengine.org/en/4.7/classes/class_object.html) and [CLI](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html) for public interface context. Record any discrepancy instead of silently joining different versions.
