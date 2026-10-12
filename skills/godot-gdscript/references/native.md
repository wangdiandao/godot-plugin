# GDScript Implementation: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [GDScript](https://docs.godotengine.org/en/4.7/classes/class_gdscript.html)
- [Signal](https://docs.godotengine.org/en/4.7/classes/class_signal.html)
- [Resource](https://docs.godotengine.org/en/4.7/classes/class_resource.html)
- [Object](https://docs.godotengine.org/en/4.7/classes/class_object.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Express interfaces with explicit types; do not change everything to Variant to suppress warnings. Give null branches for resource and node references meaningful behavior.
2. Use signals for events and wait for the appropriate nodes or signals for deferred initialization; decide whether mutable shared Resource data needs an independent copy.
3. Before refactoring, inspect script paths, NodePaths, signal method names, and serialized properties in scenes; preserve public contracts or migrate callers together.
4. Check individual files with --check-only --script, then execute real call paths covering await completion, disconnection, and object freeing.

## Saving and Validation

Preserve script .uid files and external resource references. Node scripts cannot serve as --script entry points; test wrappers should extend SceneTree.
Verify at least one signal's arguments and call count, one asynchronous completion path, and reloaded values of persisted resources.

## Common Pitfalls and Recovery

- --check-only does not execute _ready or prove correct behavior.
- Runtime lambda connections are not portable persistent scene connections.

For circular dependencies, adjust data/behavior boundaries first; for type cache issues, import first; for suspended awaits, add lifecycle and timeout checks.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Authoring and Checking

Use clear node responsibilities, typed parameters, and named signals; expose design parameters through `@export`. Persistable custom data resources should extend Resource in separate `.gd` files; do not define types that must survive across processes only as inner classes in temporary scripts. Run native import for new `class_name` dependencies to generate the class cache before checking consumers.

`await signal` suspends the current function until that signal fires; do not expect successful completion if the object is freed or the signal stops firing. Add timeout/cancellation states for tests and external I/O, and check `is_instance_valid()` in callbacks. Check for existing connections before connecting; use `CONNECT_ONE_SHOT` for one-time waits when appropriate.

`--check-only --script res://file.gd` checks parsing; afterward, instantiate dependent scenes and execute the relevant branches. Simply checking `load(script) != null` does not guarantee a valid script; inspect the logs as well. Explicitly type variables when inference encounters Dictionary.get/Variant expressions to avoid "Cannot infer the type" errors. Do not disable warnings-as-errors to hide new problems.

References: [GDScript basics](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_basics.html), [Static typing](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html).
