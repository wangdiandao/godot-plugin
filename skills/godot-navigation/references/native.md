# Navigation and Pathfinding: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [NavigationServer3D](https://docs.godotengine.org/en/4.7/classes/class_navigationserver3d.html)
- [NavigationMesh](https://docs.godotengine.org/en/4.7/classes/class_navigationmesh.html)
- [NavigationMeshSourceGeometryData3D](https://docs.godotengine.org/en/4.7/classes/class_navigationmeshsourcegeometrydata3d.html)
- [NavigationAgent3D](https://docs.godotengine.org/en/4.7/classes/class_navigationagent3d.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.


## Saving and Validation

Save baked results as native resources and reload them to verify vertices/polygons; retain source geometry and parameters for rebuilding.
The example builds navigation geometry from CPU vertices, bakes and saves it, then verifies nonempty polygons after reload; integration scenes check path reachability.

## Common Pitfalls and Recovery

- The old region_bake_navigation_mesh API is deprecated; avoid it in new code.
- A reachable navigation path does not mean a physical character can traverse it.

For empty paths, check map activation, region connections, layers, and synchronization first. For empty bakes, check geometry dimensions and agent_radius; do not blindly shrink the agent.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Actual Requirements for Baking and Synchronization

Ordinary SceneTree/headless execution can supply CPU geometry through NavigationMeshSourceGeometryData3D.add_faces(faces, transform), with three vertices per triangle in Godot's clockwise order. Bake with `NavigationServer3D.bake_from_source_geometry_data(mesh, geometry)`; await the completion callback for asynchronous variants. `parse_source_geometry_data` must run on the main thread; prefer collision or CPU data in headless mode to avoid reading rendering meshes.

After assigning the mesh to the region, the map's cell_size/cell_height must match the baked mesh. Both regions and maps may update asynchronously in 4.7.2; waiting an arbitrary single frame is insufficient. The example waits until the region iteration is nonzero and the map can find the closest region before querying paths, with a frame limit. `map_force_update` is deprecated in the 4.7 documentation and is not recommended as a synchronization workaround.

Call NavigationAgent `get_next_path_position()` once per physics frame to update internal path state; calculate velocity from the returned point and pass it to character physics. With avoidance enabled, move using the safe velocity from velocity_computed. Avoidance does not create navigation meshes or replace collisions. Verify narrow passages using actual agent_radius and map traversal assertions.

Sources: [Source geometry winding](https://docs.godotengine.org/en/4.7/classes/class_navigationmeshsourcegeometrydata3d.html#class-navigationmeshsourcegeometrydata3d-method-add-faces), [NavigationServer3D](https://docs.godotengine.org/en/4.7/classes/class_navigationserver3d.html).


## Task recipes

Use [recipes.md](recipes.md) for complete development, modification and diagnosis flows. Fixture assertions and visual/platform checks have separate acceptance scopes.

## Task-specific implementation

Read [Actual agent movement, patrol and avoidance callbacks](movement.md) before implementing that task. Its example directory is copied in full and its assertions do not replace target-device acceptance.
