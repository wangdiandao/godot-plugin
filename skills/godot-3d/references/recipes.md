# 3D scene construction and model maintenance

Use [native.md](native.md) for invocation. Establish metric scale, up axis, handedness, collision backend and renderer before changing a level. Use native primitives for greyboxing; external art production is a separate capability.

## Develop: an editable 3D room

1. Compose a Node3D root with mesh, collision, camera and lighting children. Keep a unit cube or meter marker for scale. A MeshInstance3D provides visuals; add CollisionShape3D to the appropriate physics body for physical contact.
2. Use BoxMesh/PlaneMesh for simple forms. For custom geometry, call SurfaceTool.begin, set normal/UV/color before each vertex, then generate missing normals/tangents when appropriate and commit. Clockwise triangles are front-facing. Tangents need valid normals and UVs. Save the committed ArrayMesh as a reusable resource.
3. Share mesh/material resources intentionally. Duplicate a resource before changing one object's dimensions or material. A scene-local resource must have `resource_local_to_scene` set before instantiation; changing that flag later does not retroactively isolate existing instances.
4. Choose the active Camera3D; inspect near/far planes, projection and visibility cull mask. Place WorldEnvironment and relevant lights deliberately. Include a fixed camera capture as appearance acceptance, alongside CPU checks for authored transforms and nodes.
5. Assign scene ownership for every authored child, save, and reload fresh. Assert geometry bounds, camera transform, light type, collision shapes and resource sharing policy. The minimal fixture verifies meshes, independent mesh edits, camera and light persistence; it does not render that particular authored room.

## Modify: reimportable character or environment

Import GLB/glTF into a source directory and instance it under a wrapper with gameplay bodies, sockets and controller scripts. Inspect generated node names, bone parents/rest transforms and AnimationPlayer paths before changing overrides. Reimport source art, then compare the wrapper's authored properties and child references. Externalized materials or animation libraries have a different update boundary from generated resources; decide which version is authoritative.

For a socket, use BoneAttachment3D on a verified bone, with a local offset. Bone indices can change after reimport; derive them from stable names and check `find_bone` failure. Pose and rest transforms are different contracts. SkeletonModifier3D processing order matters for IK, constraints and physics: test the final chain after all modifiers run, including reset and teleport.

For world-space transforms, `parent_transform * local_transform` composes the child. Use `affine_inverse()` for non-orthonormal bases, guarding singular transforms; `inverse()` expects an orthonormal basis. Nonuniform or negative scale can affect normals, winding and physics shapes. Prefer editing shape dimensions over scaling collision parents unevenly.

## Diagnose and retest

| Symptom | Check | Cause | Repair | Retest |
|---|---|---|---|---|
| Empty/black view | Current camera, direction, clipping, cull masks, exposure/light | View configuration or lighting | Correct the specific camera/light setting | Fixed viewpoint capture with visible reference geometry |
| Triangle invisible from intended side | Vertex winding and material cull mode | Backface winding | Correct geometry order | Normals/backface test in intended renderer |
| Editing one prop changes all props | Resource identity and local-to-scene setup | Shared mesh/material | Duplicate only the independent data | Two-instance mutation plus scene reload |
| Bone socket breaks after model update | Bone names, indices, skeleton path | Reimport changed mapping | Resolve stable names and attachment references | Animation poses, rest and teleport |
| Physics does not match model | Mesh bounds, authored shape and scale | Visual/collision mismatch | Rebuild appropriate primitive/convex/static shape | Contact and ray checks from multiple directions |

Sources: [SurfaceTool](https://docs.godotengine.org/en/4.7/classes/class_surfacetool.html), [3D transforms](https://docs.godotengine.org/en/4.7/tutorials/3d/using_transforms.html), [Skeleton modifiers](https://docs.godotengine.org/en/4.7/classes/class_skeletonmodifier3d.html), [Node3D binding](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/scene/3d/node_3d.cpp).
