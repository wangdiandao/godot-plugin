# 3D Worlds: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [Node3D](https://docs.godotengine.org/en/4.7/classes/class_node3d.html)
- [MeshInstance3D](https://docs.godotengine.org/en/4.7/classes/class_meshinstance3d.html)
- [BoxMesh](https://docs.godotengine.org/en/4.7/classes/class_boxmesh.html)
- [Camera3D](https://docs.godotengine.org/en/4.7/classes/class_camera3d.html)
- [Skeleton3D](https://docs.godotengine.org/en/4.7/classes/class_skeleton3d.html)
- [GLTFDocument](https://docs.godotengine.org/en/4.7/classes/class_gltfdocument.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Build verifiable geometry with MeshInstance3D, PrimitiveMesh, or ArrayMesh. Reuse resources for runtime objects and duplicate them when independent parameters are needed.
2. Create physical shapes separately from visual meshes; do not assume a mesh participates in collisions by itself.
3. Configure an active Camera3D, lights, and WorldEnvironment; use the official glTF importer and preserve relationships between source models and externalized resources.
4. When a skeleton is needed, inspect bone names and local poses and ensure animation tracks match node paths; do not invent rig structure.

## Saving and Validation

Save editable nodes and resources; put changes to imported models in wrapper scenes or explicit inheritance overrides rather than editing caches directly.
The example generates and reloads a scene containing a camera, meshes, and lights; real rendering checks object visibility and camera coverage.

## Common Pitfalls and Recovery

- Negative and nonuniform scaling affect normals and physics.
- Renderer and hardware requirements differ; headless execution cannot verify material appearance.

For a black screen, check the active camera, clipping planes, visibility layers, and position before lighting; for incorrect model scale, check import settings and parent transforms.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Native Modeling and Model Organization

Prefer built-in meshes such as BoxMesh, PlaneMesh, and SphereMesh for simple geometry. For custom triangle meshes, call SurfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES), set vertex attributes such as normal/UV before add_vertex, then commit to obtain an ArrayMesh; save it as `.tres` and reference it from MeshInstance3D. Verify winding, normals, and dimensions with real rendering. Configure collision shapes separately; a visible mesh does not establish valid collision.

After importing glTF/GLB, save the outer composed scene. Use inheritance/instance overrides for model-generated nodes, Skeleton3D, and animation tracks, preserving reimport boundaries. Check bone indices, parent relationships, and rest transforms before procedural skeleton changes; do not confuse pose with rest. Procedural/primitive geometry and animation are possible without external DCC tools, but arbitrary complex art models cannot be guaranteed automatically.

Runtime glTF import snippet (requires the module, file, and dependencies; not tested as a minimal example):
```gdscript
var document := GLTFDocument.new()
var state := GLTFState.new()
var error := document.append_from_file(source_path, state)
if error == OK:
    var imported := document.generate_scene(state)
    # After adding to a valid parent, save according to scene ownership rules.
```

References: [GLTFDocument](https://docs.godotengine.org/en/4.7/classes/class_gltfdocument.html), [SurfaceTool](https://docs.godotengine.org/en/4.7/classes/class_surfacetool.html).
