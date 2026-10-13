# Procedural meshes, rooms and stable bone sockets

## Build a visible, editable room

1. Establish units and up axis with a one-meter reference. Use Node3D composition with separate MeshInstance3D and physics bodies/shapes. Match collision dimensions rather than scaling collision parents nonuniformly.
2. For SurfaceTool, set UV/normal/color before each vertex. Generate normals after the triangle set and tangents after UV/normals. Check triangle winding and bounds before saving an ArrayMesh.
3. Assign editable materials and explicit sharing policy. Set a current Camera3D with known position/orientation, near/far and cull mask, then one light and WorldEnvironment.
4. Save authored owners, load the scene and query its collisions. For appearance, capture from the fixed camera after frame_post_draw and inspect visible reference geometry, normals and coverage. CPU readback does not prove pixels.

The [mesh-socket example](../assets/examples/mesh-socket/project.godot) creates a UV triangle with normals/tangents and a minimal original rig/socket. Run example.gd with native.md's isolated command. It saves room.tscn and verifies the socket before/reset/after reload. It is a rig/geometry contract check, not a complete rendered room or artist model.

## Add an item socket safely

1. Inspect the actual Skeleton3D path and stable bone name. Require find_bone to succeed before configuring BoneAttachment3D; do not guess a bone index from another model.
2. Put the attachment under the intended skeleton (or configure its external skeleton explicitly). Parent the item under the attachment and give it the intended local offset.
3. Decide who owns pose updates: animation, modifiers or code. Observe the socket after skeleton processing; an immediate read after a pose write may precede the update.
4. Reset the bone to rest, animate two known poses and teleport the actor. Compare world socket position against bone pose plus item offset.
5. Persist attachment and child owners. Reload, resolve the bone again and repeat motion. If reimport renames/reorders bones, re-resolve by name and report missing mapping without binding an unrelated index.

The fixture rejects a missing name before binding and tests a real BoneAttachment update. Retargeted humanoids, IK modifier ordering and artist-rest differences remain separate target-rig acceptance.

## Modify a reimportable model

Keep source GLB/glTF authoritative. Use a wrapper scene for collision/controller/gameplay sockets and deliberately externalized resources for stable manual materials. See godot-assets' import-repair fixture for changed source dimensions with unchanged wrapper/material bytes.

Before reimport, record mesh bounds, bone names/rest, animation track paths, extracted resource paths and wrapper hash. After reimport, compare changed geometry, unchanged authored nodes and every dependent path. Test animation and socket following again; a loaded mesh alone cannot certify the rig.

For hierarchy/transform edits, use parent * local composition and affine_inverse for a nonorthonormal nonsingular basis. Check mirrored winding and collision dimensions. On failure restore the task's model settings/overrides together, retaining updated artist source rather than overwriting it blindly.

## Ordered diagnosis

| Symptom | Checks | Repair and retest |
|---|---|---|
| Room invisible | Current camera → view direction/clip → cull layers → normals/material → light/exposure | One cause, fixed-view capture with unit marker |
| Normal map wrong | UV → normals → tangents → import semantic | Rebuild the missing basis; rotating light on target renderer |
| Socket drifts | Skeleton path/name → pose/rest → modifier order → local item offset | Resolve intended bone and timing; neutral/moving/reset/teleport |
| Source update breaks wrapper | Node/bone rename → authored/generated boundary → extracted references | Repair owned mapping; reimport twice with base hashes |
| Collision scale differs | Parent basis → shape dimensions → backend | Correct dimensions/uniform scale; ray/contact from multiple directions |

Sources: [SurfaceTool](https://docs.godotengine.org/en/4.7/classes/class_surfacetool.html), [Skeleton3D](https://docs.godotengine.org/en/4.7/classes/class_skeleton3d.html), [BoneAttachment3D](https://docs.godotengine.org/en/4.7/classes/class_boneattachment3d.html), [transforms](https://docs.godotengine.org/en/4.7/tutorials/3d/using_transforms.html).
