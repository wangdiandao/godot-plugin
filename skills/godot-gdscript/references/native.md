# GDScript Implementation: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Develop a typed gameplay command

Identify scene-owned state and detached data first. Put frame callbacks on Node, authored configuration on Resource and a detached rules service on RefCounted. Export only data intended for Inspector/serialization. Required arguments in a Resource `_init()` can prevent duplication/loading; use default construction plus validated setup for serializable resources.

Give the command a typed return value or explicit result Dictionary. Validate all input before mutating state, then emit a typed signal with the completed value. Use direct calls for required commands; an unobserved signal cannot establish that an operation succeeded. Types are useful for internal contracts; incoming JSON/RPC values remain Variant until checked. `as` can return null rather than proving a cast is valid.

Connect signals once and test reentrancy: delivery is synchronous unless a deferred connection is chosen. Mutating subscribers can call back into the publisher. Keep state consistent before emit, or defer a callback when the operation requires a completed iteration. Do not connect a persistent scene signal to a lambda: lambda connections cannot serialize.

## Modify asynchronous or shared logic

Read callers and warning settings before changing a signature. Preserve exported names or migrate saved data. Distinguish Array/Dictionary reference sharing from packed-array getters on built-in properties, which return copies. Duplicate data when independent ownership is required and test two consumers.

After `await`, confirm a referenced object is valid and the operation still belongs to the active scene/request. A generation token is useful when a later request supersedes an earlier one. Coroutine completion must not reopen a closed screen or modify an unloaded level. For nodes leaving the tree, disconnect long-lived publishers and cancel owned work; do not simply suppress all errors with null guards that hide missing required setup.

Use `--headless --path PROJECT --import` for project parse/import checks, then run a deterministic script that exercises the command. The minimal case checks typed signal values, async continuation and connection ownership; add a project-specific cancellation fixture for real async operations.

## Diagnose script behavior

| Symptom | Check → cause → fix → retest |
|---|---|
| Invalid access after await | Check lifetime/request generation → scene freed or request superseded → verify validity and cancellation → exit scene while waiting. |
| Typed variable inferred from Variant warning | Inspect API return contract → unvalidated dynamic boundary → explicit Variant then validate/cast → malformed input plus normal input. |
| Resource duplication fails | Inspect required constructor args and STORAGE properties → object cannot be default constructed → default init plus configure → duplicate/save/reload. |
| Shared array changes elsewhere | Compare identity and property getter semantics → alias or copy mismatch → duplicate or reassign deliberately → mutate two owners. |
| Signal recursion or duplicate effects | Inspect synchronous callbacks and reentry → inconsistent state or repeated connect → establish state before emit/guard connection → count effects and reattach. |

Sources: [static typing](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html), [GDScript basics](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_basics.html), [Object connections](https://docs.godotengine.org/en/4.7/classes/class_object.html), [Node lifecycle](https://docs.godotengine.org/en/4.7/classes/class_node.html).

Version evidence: [fixed documentation snapshot](https://github.com/godotengine/godot-docs/tree/9adca4c1c72917bfe1b7be3108abed5ce26696a6) and [tested engine source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). API links use the 4.7 version branch; recheck the actual target engine.

## Task-specific implementation

Read [Async cancellation, replacement and signal reentry](tasks.md) before implementing that task. Its example directory is copied in full and its assertions do not replace target-device acceptance.
