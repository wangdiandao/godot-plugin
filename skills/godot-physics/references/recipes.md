# Controllers, collision and query diagnosis

Use [native.md](native.md) for test commands. Choose CharacterBody for controlled characters, RigidBody for solver-driven objects, StaticBody for static geometry and Area for overlap sensing. Record dimensions, units, tick rate and physics backend with results.

## Develop: a character and an interaction zone

Keep movement in one `_physics_process` owner. CharacterBody velocity is in units per second; gravity integration uses delta, while `move_and_slide()` consumes velocity without another delta multiplication:

```gdscript
func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta
    velocity.x = Input.get_axis("left", "right") * speed
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = -jump_speed
    move_and_slide()
```

This is a 2D positive-down example; in 3D gravity and horizontal components must follow the configured up vector/world convention. Inspect floor/wall/ceiling state after movement, test slope limits and floor snap, and decide how moving-platform velocity carries into departure. Input callbacks choose intent; they should not run a second movement step.

Configure body collision layers and scanning masks separately. Layer 3 corresponds to `1 << 2`, while integer mask 3 scans layers 1 and 2. An Area's `monitoring` governs its sensing; `monitorable` governs detection by other Areas. Use body signals for PhysicsBody and area signals for Area. Defer shape and monitoring changes triggered inside physics callbacks.

The minimal fixture runs a real floor contact, units-per-second movement, a floor ray, a wrong-mask ray and one Area enter/exit pair. Preserve tolerance-based contact assertions across platforms; this Windows 2D result does not establish Jolt 3D, CCD or slope behavior.

## Modify: a collision filter or rigid-body behavior

For a filter change, capture the original layer/mask, alter one participant, and retest both wanted and unwanted contacts. Run queries from a physics-safe context with world-space endpoints and RID exclusions. An empty ray result is a normal no-hit case, not an engine failure; do not dereference `collider` without checking.

For RigidBody, apply a one-time impulse for an impact and forces for ongoing acceleration; a constant force persists until explicitly removed. Use `_integrate_forces(state)` for controlled state edits. Force/impulse offsets are measured from body origin in global axes; they are not absolute world target points. Repeated direct transform writes fight the solver. Contact monitoring requires both monitoring and a sufficient `max_contacts_reported`; contact points are not unique-body counts.

For fast objects, first reproduce at the actual speed/timestep. Consider ray/sweep movement, shape size, supported CCD mode and backend limits. Keep a negative collision test so enabling a feature cannot silently create unwanted contacts.

## Diagnose and retest

| Symptom | Check | Cause | Repair | Retest |
|---|---|---|---|---|
| Character moves slowly | Velocity assignment and delta use | Velocity multiplied by delta twice | Integrate acceleration only | Measured distance at fixed physics rate |
| Trigger does not fire | Signal type, monitoring, filters, shapes, space | Wrong type/filter or no shape | Correct one verified cause | Enter, exit, repeat and excluded-layer tests |
| Ray misses visible mesh | Collision exists, query mask, world endpoints | Mesh is visual only or coordinates differ | Add correct shape/filter/query transform | Expected hit RID/position plus no-hit case |
| Body tunnels | Speed, timestep, thickness, CCD support | Discrete sampling misses contact | Appropriate CCD/sweep/geometry change | Worst-speed impact, angled approach and repeated runs |
| Body stops responding | Sleeping, freeze, force clearing, process state | State disables integration | Restore intended simulation state | Rest-to-force transition and sleep/wake behavior |

Sources: [Physics introduction](https://docs.godotengine.org/en/4.7/tutorials/physics/physics_introduction.html), [CharacterBody2D](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html), [RigidBody3D](https://docs.godotengine.org/en/4.7/classes/class_rigidbody3d.html), [CharacterBody source](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/scene/2d/physics/character_body_2d.cpp).
