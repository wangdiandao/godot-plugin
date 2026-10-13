# Rename and move without flattening scene contracts

## Select the editable boundary

| Scene kind | Owned edit | Required control |
|---|---|---|
| Newly authored scene | Children, owners and named connections | Save/reload actual behavior |
| Instanced subscene | Outer instance properties and deliberate overrides | Retain get_node_instance and untouched source hash |
| Inherited variant | Variant overrides | Retain get_base_scene_state and untouched base |
| Imported subtree | Wrapper or explicit import/extracted policy | Reimport preserves authored data |

## Modify a node name or parent

1. Inventory consumers before renaming: exported NodePaths, onready/get_node callers, animation track roots/subnames, persistent connections, unique-name access and external scenes. Keep a list of the original and intended paths.
2. Determine whether the changed path is owned by the current scene. Do not rewrite paths inside the source of an instance when the requested change is only an outer name.
3. Change the node and update each owned consumer using the appropriate root-relative path. Moving a node also changes transforms: preserve the requested local or global pose deliberately.
4. Validate all targets before playback or invocation. Missing required targets should reject the refactor, not turn every callback into an optional null guard.
5. Pack/save only the intended authored structure. Preserve subscene scene_file_path and internal owners; setting every descendant owner to the wrapper flattens its intended boundary.
6. Fresh-load, inspect SceneState instance/base references and execute the connected method/animation. Compare source bytes and unrelated internal properties.

The [refactor fixture](../assets/examples/refactor/project.godot) renames an instanced Module to Actor, reproduces an exported-path failure, updates the exported target plus animation track, saves and invokes the persistent button connection after reload. It verifies the animation midpoint, original subscene hash and a separate inherited variant's base state. Copy the whole directory and run example.gd using native.md. Outputs: wrapper.tscn, result.json and log.

This fixture does not implement a universal NodePath migration tool. Its two known consumers establish the recipe; real changes must search the complete requested dependency scope, including script literals and saved data.

## Diagnose persistence or refactor failures

| Symptom | Ordered observations | Repair | Retest |
|---|---|---|---|
| Child missing after save | Parent/owner chain → pack result → SceneState | Assign only intended persisted owner | Fresh node presence plus excluded preview |
| Button stops after rename | Persistent target/method → exported path → actual callable | Update owned connection/path contract | Invoke on reloaded instance |
| Animation stops | Player root → track target/subname → property type | Rewrite intended track only | Sample at two times after reload |
| Instance becomes duplicated content | scene_file_path → ownership → SceneState instance | Preserve external scene reference and owners | Source hash and instance resource retained |
| Inherited edits affect base | Edited destination → base state → saved overrides | Restore base and apply variant-only edit | Base bytes unchanged; variant behavior changed |

Restore node names and their dependent paths as one task-owned change when verification fails. If a user concurrently edits the same references, retain both versions and resolve the contract before saving. Never reset the whole repository or recreate the scene to hide a broken path.

Sources: [PackedScene](https://docs.godotengine.org/en/4.7/classes/class_packedscene.html), [SceneState](https://docs.godotengine.org/en/4.7/classes/class_scenestate.html), [Node ownership](https://docs.godotengine.org/en/4.7/classes/class_node.html), [scene format](https://docs.godotengine.org/en/4.7/engine_details/file_formats/tscn.html).
