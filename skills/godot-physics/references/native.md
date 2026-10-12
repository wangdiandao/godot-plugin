# Physics and Interaction: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [CharacterBody2D](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html)
- [CharacterBody3D](https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html)
- [Area2D](https://docs.godotengine.org/en/4.7/classes/class_area2d.html)
- [PhysicsRayQueryParameters3D](https://docs.godotengine.org/en/4.7/classes/class_physicsrayqueryparameters3d.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Use CharacterBody velocity and move_and_slide in _physics_process for characters; use forces, impulses, or official integration callbacks for RigidBody.
2. Configure both objects' layer/mask and the Area's monitoring; check shape nodes, transforms, and enabled states individually.
3. Schedule physics queries at a safe point in physics processing and use PhysicsRayQueryParameters; defer structural changes in interaction callbacks when necessary.
4. Test rest, movement, edges, collisions, and triggers with tolerances and state assertions; do not assume physics is identical frame by frame across platforms.

## Saving and Validation

Update movement scripts and shape scenes together; do not write runtime velocity or test input back into authored scenes.
The example creates a floor and body in a physics world and verifies resting height or contact after actual simulation steps; game tests cover movement input and interaction.

## Common Pitfalls and Recovery

- CharacterBody.velocity uses units per second; do not multiply it by delta before passing it to move_and_slide.
- A server query immediately after adding a node may run before synchronization.

For tunneling, check speed, size, backend support, and continuous detection first. For missing triggers, check filtering on both objects and whether enough physics steps have elapsed.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Movement and Query Conventions

CharacterBody2D/3D velocity uses units per second. Update gravity with `velocity += gravity * delta` inside `_physics_process(delta)`, and do not multiply velocity by delta again when calling `move_and_slide()`. `is_on_floor()` reflects collisions after the latest movement. Use forces/impulses or `_integrate_forces()` for RigidBody; continuously writing transform directly conflicts with the solver.

Area body_entered and area_entered refer to different types. Check monitoring, monitorable, collision layers, masks, shape enabled state, and the physics space. Defer shape/monitoring changes inside collision callbacks. Layer numbers map to bitmasks: mask=3 does not select only layer 3.

In physics frames, cast rays with `get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, mask))`; use the corresponding 3D types for 3D. Set exclude to filter out the querying object. If the result is an empty Dictionary, check coordinate spaces and masks, then collision resources, rather than weakening assertions first.

Acceptance must at least cover resting on the floor, continuous movement, boundaries/obstacles, repeated triggers, and restart. Test fast-moving bodies at actual speeds/time steps; enabling CCD alone does not prove all tunneling is solved.
