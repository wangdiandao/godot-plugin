# Scenes and Resources: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [PackedScene](https://docs.godotengine.org/en/4.7/classes/class_packedscene.html)
- [SceneState](https://docs.godotengine.org/en/4.7/classes/class_scenestate.html)
- [ResourceSaver](https://docs.godotengine.org/en/4.7/classes/class_resourcesaver.html)
- [ResourceLoader](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html)
- [Node](https://docs.godotengine.org/en/4.7/classes/class_node.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Edit .tscn/.tres directly for simple property changes; create complex new resources through official Node and Resource APIs.
2. Call add_child first, then assign the correct owner to new nodes that must persist; preserve internal ownership boundaries in existing child scenes.
3. Use named methods and CONNECT_PERSIST for signals that must be saved; call PackedScene.pack and ResourceSaver.save and check Error.
4. Reload saved results with CACHE_MODE_IGNORE and inspect nodes, properties, connections, and dependencies with SceneState; instantiate for validation when necessary.

## Saving and Validation

Preserve UIDs, ext_resource entries, instances, and inheritance information. Do not recursively assign the outer root as owner of an entire instance tree; do not fabricate import caches.
The example saves nested nodes and persistent signals and verifies them after reload. Regression tests also cover instance preservation, inheritance overrides, and unwritable targets.

## Common Pitfalls and Recovery

- ResourceSaver does not guarantee persistence of newly generated UIDs at runtime; use native editor import to establish metadata when necessary.
- Expanding and repacking scene instances can lose editable inheritance relationships.

For missing nodes, check owner first; for missing signals, check persistence flags. Restore only this operation's files after save failure, and stop overwriting when the user has made concurrent changes.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## What to Check After Saving

`PackedScene.pack(root) -> Error` packs root and the nodes it owns; `ResourceSaver.save(resource, path, flags=0) -> Error` writes the file. The owner must be an ancestor: call add_child before setting owner. Ordinary `Signal.connect(callable)` connections exist at runtime; use `Object.CONNECT_PERSIST` and reconstructible named methods for connections that must be saved.

After reloading, inspect structure with `SceneState.get_node_count()`, `get_node_path()`, `get_node_instance()`, `get_base_scene_state()`, and connection lists; then instantiate to verify key properties and actual signal execution. Engine resource caches can hide disk errors: use `ResourceLoader.CACHE_MODE_IGNORE` for readback and a fresh process to validate the complete dependency graph when external dependencies change.

Preserve `instance=ExtResource(...)` when changing an existing instance property, and preserve base state in inherited scenes. The example proves creation and signals; the source test `scene-inheritance` separately verifies instance persistence, local inheritance overrides, and an unchanged base. Do not "fix" missing nodes by assigning the outer owner to every internal instance node.

Write complex changes to temporary `.tscn/.tres` files in the same directory. After successful reload validation, verify that the original file's hash still matches its pre-operation value, then commit the replacement. Keep targets, temporary files, and backups within the current project; save resources before updating references for cross-file changes. Preserve diagnostic files if replacement fails; do not delete originals to retry.
