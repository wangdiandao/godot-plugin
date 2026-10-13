# 3D controllers, rigid bodies and fast interactions

Keep [recipes.md](recipes.md)'s ordered trigger diagnosis. This reference handles movement/solver failures beyond the existing 2D fixture.

## Develop a 3D controller

1. Record backend, physics rate, up direction, character dimensions and world units. Put a CollisionShape3D under CharacterBody3D and author a StaticBody3D floor; meshes alone cannot collide.
2. In one `_physics_process(delta)`, integrate gravity with delta, assign horizontal velocity in units/second and call move_and_slide once. Inspect floor/wall/ceiling after motion.
3. Choose floor_max_angle, floor_snap_length, floor_stop_on_slope and constant-speed policy from actual slopes. Do not continually snap while jumping. Compare requested velocity to get_real_velocity on slopes.
4. Moving platforms need their own layer policy and departure-velocity decision. Test standing, stepping off, jumping and teleport reset; no universal platform fix follows from a flat-floor pass.
5. Save the authored controller/shape; omit transient test input and runtime velocity. Run original input plus a deterministic motion replay after reload.

Copy [body-3d](../assets/examples/body-3d/project.godot) and run example.gd using native.md. It verifies real floor landing, measured horizontal distance, a wrong-mask ray and repaired hit, explicit rigid-body wake/impulse, and a still-excluded layer. Outputs: result.json and log. It records the actual engine; its additional slope-ascent and repeated thin-wall point-sweep checks establish those selected cases; CCD/backend parity requires the conditions below, not extrapolation from this floor.

## Modify rigid-body interactions

Use an impulse once for an impact; apply force over time for sustained acceleration. Record mass and units so an acceleration expectation is not confused with a velocity change. Constant forces persist until removed. For custom integration, use `_integrate_forces(state)` rather than writing transforms each render frame.

When a settled body stops responding, inspect sleeping, freeze, process mode and applied force before changing input or collision geometry. Explicitly wake for an intentional interaction and observe real displacement. For contact callbacks, check contact_monitor and max_contacts_reported; contact-point count is not a count of distinct objects.

Preserve collision filters and shape dimensions while changing the force policy. Repeat impact after rest and after scene reload. A callback alone does not establish physical impulse direction or stable stacking.

## Fast-projectile diagnosis and repair

1. Reproduce the maximum speed, thin target, oblique angle and actual physics tick rate. Record previous/new position and expected collision layer.
2. Verify backend-supported continuous detection and body type. Enable CCD only when supported and retest; it is not a universal guarantee.
3. For a point projectile, raycast from previous to proposed global position. For finite width, use a shape sweep and interpret its safe/unsafe fractions; a center ray can miss a grazing hit.
4. Exclude the shooter's RID and use the intended target mask. Clamp the projectile at the first verified contact, apply the gameplay effect once and defer structural changes from physics callbacks.
5. Retain a wrong-mask miss, no-hit movement and repeated worst-speed impacts. Test a moving target separately: sweeping against a snapshot is not continuous relative-motion proof.

## Fault branches

| Symptom | Ordered observations | Repair and acceptance |
|---|---|---|
| Slow controller | Assigned velocity → delta multiplication → competing writer | Correct units; measured distance at two physics rates |
| Slides while idle | Floor state → slope angle → snap/stop settings → dimensions | Adjust intended floor policy; idle, ascent, descent and jump |
| Impulse ignored | Freeze → sleeping → force magnitude → callback schedule | Wake/restore intended state; actual displacement after rest |
| Mesh visible but ray misses | Shape/world → endpoints → mask/exclude → sync | Fix one observed cause; expected RID and excluded target |
| Fast projectile tunnels | Speed/timestep → geometry thickness → backend CCD → sweep | Verified contact once at worst speed and oblique angle |

Use tolerances and bounded waits, preserve the failed motion trace, and restore task-owned filters when a hypothesis fails. Do not enable all layers as the final repair.

Sources: [CharacterBody3D](https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html), [RigidBody3D](https://docs.godotengine.org/en/4.7/classes/class_rigidbody3d.html), [shape queries](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate3d.html), [Jolt limitations](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html).
