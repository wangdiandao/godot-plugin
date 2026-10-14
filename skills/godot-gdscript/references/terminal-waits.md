# Terminal asynchronous outcomes

## Develop or repair a bounded wait

An object being freed or a Tween being killed is not a normal completion. Checking validity after await cannot help when that await never resumes. Keep the completion ticket in an owner that survives the disposable operation, cache its terminal status, and settle exactly once with completed/cancelled/timeout/failed. Check cached status before connecting/waiting so synchronous completion cannot be missed. Do not manually emit the engine's finished signal to disguise cancellation.

Connect completion and tree-exit/cancel events before work starts. Route replacement and explicit cancellation through the owner, disconnect old callbacks, kill owned animation/work where appropriate, and settle the ticket. A bounded timeout is a fallback for externally killed work or missing events; it does not itself abort an HTTP request or worker. Teardown must abort/join that work separately. UI commitment still requires the generation/weak-target checks in [async lifecycle recipes](tasks.md).

For multiple parameterless signals, validate the set before connecting, define empty-set success, connect before triggering events, and use one request owner per batch or reject reentry. A one-shot connection prevents repeat delivery but does not settle an outer wait when an emitter disappears. Retain weak publisher references and the exact callable for disconnect; use a cancellation or timeout policy. Parameter-bearing signals need an explicit adapter matching their payload, not an assumed universal callback.

## Run and diagnose

Copy the complete example directory to a fresh workspace, create OUT, then run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Use absolute paths. Inspect the exit code, full error log and named `GODOT_PLUGIN_RESULT:` assertions together. Outputs belong to OUT; do not run fixtures against a player's real saves.

Use the [terminal-waits project](../assets/examples/terminal-waits/project.godot). It validates normal completion, cached synchronous completion, nested caller cleanup after cancellation, external Tween kill timeout, node exit, all-signals completion, empty/duplicate inputs, rejected reentry and lost-emitter timeout with subscription cleanup. The fixture has no indefinitely waiting raw coroutine; the reported community failure is represented by a bounded owned operation rather than intentionally leaking waiters.

If a wait stalls: inspect the awaited emitter/function lifetime, whether its completion actually occurs, then the ticket's cancellation wiring and timeout. If an old result writes into a replacement screen, inspect request generation separately. Preserve the original symptom; do not turn every missing required dependency into a silent null skip.

Sources: [Tween](https://docs.godotengine.org/en/4.7/classes/class_tween.html), [Signal](https://docs.godotengine.org/en/4.7/classes/class_signal.html), [SceneTree timers](https://docs.godotengine.org/en/4.7/classes/class_scenetree.html). Community cases: [Godot issue #120998](https://github.com/godotengine/godot/issues/120998) (4.7 stable, 2026-07), [nested Tween cancellation](https://forum.godotengine.org/t/coroutines-hangs-on-tween-finished-if-tween-kill-is-called/131958) (4.5.1, 2026-01), [multi-signal aggregation](https://shaggydev.com/2025/06/12/godot-awaiting-signals/) (2025-06). These are use-case evidence, not a claim that every report is an engine defect.

Version evidence: [Godot 4.7.2 source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). Recheck the actual target binary. Community discussions supply use cases; official contracts and runtime checks determine supported behavior.
