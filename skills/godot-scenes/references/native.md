# Scenes and Resources: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Develop and save a reusable scene

Choose a root that owns the module's public interface. Add children with stable descriptive names; configure paths and exported values before entering the tree when ready callbacks need them. Set each persisted descendant's `owner` to the scene root only after adding it under a valid ancestor. Parentage controls runtime hierarchy; owner controls inclusion in PackedScene. Leave temporary previews/helpers unowned when they should not save.

Use a named method target with `CONNECT_PERSIST` for a connection that must survive serialization. Runtime-only connections can be made during initialization; keep them separate from saved wiring to avoid duplicate effects on reload. Pack, check its Error, save to an explicit path, then reload with `CACHE_MODE_IGNORE` to avoid validating only an in-memory root. Instantiate the saved scene and invoke the connected action. Inspect SceneState node/connection counts when diagnosing missing content, but also test the actual resulting behavior.

## Modify instances and resource ownership

Inspect whether the source is imported, inherited or an editable instance. Make overrides on the intended instance rather than flattening the hierarchy. Preserve external resource references and inherited identities. For runtime per-instance data choose an explicit duplicate or `resource_local_to_scene` before instantiation. A built-in resource is still shared between instances unless scene-local duplication applies.

`duplicate(true)` recursively copies collections and internal resources in the tested 4.7.2 policy, while externally saved subresources remain shared. `duplicate_deep(DEEP_DUPLICATE_ALL)` copies external data too but retains script definitions. Alias preservation matters: two references to the same nested object should remain two references to the same cloned object when deep copying. See the data resource fixture for actual assertions; do not replace these rules with the vague instruction “deep copy everything”.

Changing `resource_local_to_scene` after an instance already exists does not retroactively separate its existing resource. Save authored modifications, reload and compare a pair of instances. `CACHE_MODE_IGNORE` ignores the root cache without automatically ignoring every external dependency; use deeper cache modes only when the target verification requires them.

## Diagnose scene persistence

| Symptom | Check → cause → fix → retest |
|---|---|
| Child disappears after reload | Compare owner chain and packed SceneState → unowned transient child → assign valid root owner → save, fresh load, inspect node. |
| Connected button does nothing after reload | Inspect persistent connection and method target → runtime/lambda connection not serialized → named persistent method or explicit runtime setup → emit on reloaded instance. |
| Two instances share mutable material/data | Compare resource identity and local flag timing → shared definition → scene-local or deliberate copy → mutate one, inspect other. |
| Save appears to ignore changes | Check path/cache and Error result → wrong target or cached root → explicit save and uncached reload → inspect value from new object. |
| NodePath breaks after refactor | Search callers/tracks/exported references → moved node contract → preserve name or update all dependent paths → original scene and isolated instance. |

Sources: [PackedScene](https://docs.godotengine.org/en/4.7/classes/class_packedscene.html), [Resource](https://docs.godotengine.org/en/4.7/classes/class_resource.html), [ResourceLoader](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html).

Version evidence: [fixed documentation snapshot](https://github.com/godotengine/godot-docs/tree/9adca4c1c72917bfe1b7be3108abed5ce26696a6) and [tested engine source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). API links use the 4.7 version branch; recheck the actual target engine.
