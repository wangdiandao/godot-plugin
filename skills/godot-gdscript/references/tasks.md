# Commands, asynchronous requests and signal diagnosis

## Choose the task

| Request | Start here | Evidence |
|---|---|---|
| Add a gameplay rule | Typed command in native.md | Valid and invalid input leave the intended state |
| Loading result updates an old scene | Request ownership below | Superseded, detached and freed targets cannot commit |
| Action happens twice or recurses | Signal diagnosis below | One completed fact and bounded reentry |

## Develop a cancellable request owner

1. Keep request ownership outside the disposable view when completion must survive its lifetime. A RefCounted service may await a SceneTree supplied by the caller; the view is a weak reference, not a strong lifetime extension.
2. Increment a generation for every replacement or cancellation. Capture the generation before awaiting. After each completion, compare it before touching the target. This cancels application commitment; it does not cancel an HTTP request, thread or engine future automatically.
3. Resolve the weak target and require validity plus the appropriate active-scene/tree condition. An allocated node removed from the tree is still valid but may no longer be an eligible destination.
4. Validate the completed data before mutation, establish consistent state, then emit a completed fact. Treat network/JSON input as Variant until its type/range passes the command contract.
5. Pair cancellation with the owning view's `_exit_tree()`, destination replacement and user cancel action. If a worker owns external resources, separately cancel/join that worker before teardown.

The [async lifecycle project](../assets/examples/async-lifecycle/project.godot) contains a Broker and weak Inbox. Copy the whole directory and run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first and use absolute paths. The fixture commits the newer request while the older one completes later, cancels another, removes a live target, destroys another target and counts notifications. Outputs: result.json and the complete process log. It does not measure thread cancellation or network abort.

## Modify existing await code

Inventory each completion destination and every exit path before adding guards. Preserve exports and public signal payloads. Replace an unqualified late write with generation validation and a weak target. Keep required dependencies explicit: silently skipping every null access can conceal a setup bug.

Use controllable frame-delayed completion in the fixture to reproduce old/new ordering. Then apply the same ownership contract to the real loader and repeat scene exit while waiting. Test completion after replacement, cancellation and detachment separately; one normal await does not exercise those branches.

## Diagnose duplicate delivery and reentrancy

1. Count side effects at the command boundary and subscriber, not just signal connections.
2. Inspect persistent scene wiring, initialization wiring and reentry. An `is_connected()` guard avoids duplicate connections to the same callable but does not detach a replaced publisher.
3. Decide whether nested commands are legal. For a nonreentrant transaction, reject a nested command before mutation; release the guard after notification. For legal nested commands, define ordering and validate the state visible to each callback.
4. Retain the exact callable for captured lambdas and disconnect long-lived publishers when their receiver stops owning the subscription.
5. Repeat binding and tree removal/reentry; prove the old publisher cannot update the new view. The fixture's subscriber attempts command reentry and verifies no extra mutation.

| Observation | Next check | Repair | Retest |
|---|---|---|---|
| Old result overwrites new result | Captured generation versus current generation | Reject stale commitment | Deliberately complete old request last |
| Freed target access | Strong/weak destination and post-await validity | Resolve weak target after await | Destroy target before completion |
| Detached screen updates | Tree membership/active request | Cancel exit and require eligible target | Remove without freeing, complete, reattach |
| Signal recursion | State at emit and nested command policy | Consistent state plus explicit reentry rule | Subscriber calls command synchronously |
| Effects double on reentry | Persistent/runtime connections and old emitter | Pair subscription lifetime | Rebind twice and count accepted facts |

Sources: [await](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_basics.html), [WeakRef](https://docs.godotengine.org/en/4.7/classes/class_weakref.html), [Node lifecycle](https://docs.godotengine.org/en/4.7/classes/class_node.html), [Object connections](https://docs.godotengine.org/en/4.7/classes/class_object.html). Generation cancellation is application code, not an invented engine cancellation API.
