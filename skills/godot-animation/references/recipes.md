# Playback, AnimationTree and root-motion recipes

Use [native.md](native.md) for invocation. Animation may change properties, blend poses or extract movement. Keep gameplay authority explicit and choose one active writer for each animated property.

## Develop: a persisted property animation

Create a clip with a seconds-based length and typed tracks. Set paths relative to AnimationPlayer's root_node; validate nodes, subnames and property types. Insert keys at intended times and choose interpolation/update mode appropriate to continuous values or discrete events. Put clips in an AnimationLibrary; a named library is played as `library/clip`, while the empty library uses `clip`.

Evaluate known times through real playback/advance. Save the library, load with CACHE_MODE_IGNORE, inspect duration, paths and key values, then bind the loaded library to another playback evaluation. The minimal fixture verifies the midpoint before save and the three-quarter position after readback. Verify method/audio tracks in their actual event context: a property interpolation test cannot establish event delivery.

## Modify: add a locomotion state machine

1. Inventory existing clips, RESET tracks, node paths and skeleton rest pose. Duplicate only a shared resource requiring an independent change.
2. Point AnimationTree.anim_player to the player. Construct an AnimationNodeStateMachine with idle/move/action nodes and transitions, or an AnimationNodeBlendSpace1D/2D for continuous speed/direction. BlendSpace2D points must cover the intended input domain and triangles; looping clips need phase synchronization where appropriate.
3. Obtain `parameters/playback` as AnimationNodeStateMachinePlayback; initialize the intended state, then `travel` through configured transitions. Set BlendSpace parameters from controller state. Do not call AnimationPlayer.play concurrently for tracks owned by the active tree.
4. Define RESET/default values for partial tracks and compare transitions at zero speed, maximum speed, reversals and interruption. Test root pose and event firing, not merely the current state name.
5. Save the scene plus libraries, reload in a fresh process and replay the transition sequence. Imported clips belong to the reimport boundary; preserve manual edits as deliberately externalized libraries or separate authored data.

## Develop: extracted root motion

Select a valid TYPE_POSITION_3D/rotation/scale track for root_motion_track. The tree extracts its motion instead of also applying it to the target. Sample the tree in the same physics schedule as the controller. `get_root_motion_position()` is a displacement for that advance; transform from animation-local into controller/world orientation and divide by physics delta when assigning CharacterBody velocity. Apply movement once through collision-aware motion.

The [root-motion fixture](../assets/examples/root-motion/project.godot) creates a 2 m/s clip, advances 0.25 seconds, asserts a 0.5 m delta and unchanged target position, then applies the delta once. It verifies CPU extraction without a skeleton. A rig-specific test must also cover rotation accumulation, looping, blending, collisions and retargeting. Accumulator getters are absolute accumulated state, not interchangeable with per-step deltas.

## Diagnose and retest

| Symptom | Check | Cause | Repair | Retest |
|---|---|---|---|---|
| Clip exists but node stays still | root_node, track path/type, active processing | Invalid target or competing writer | Correct target/ownership | Actual property at two sampled times |
| Transition snaps | RESET, missing tracks, rest pose, blend duration | Undefined prior/default value | Define intended base pose and blend | Enter from each relevant state |
| Character moves twice as far | Extracted versus applied root motion | Track and controller both move it | Extract and apply once | Known clip displacement and physical position |
| Foot sliding after retarget | Bone mapping/rest/scale/phase | Clip and target pose disagree | Verified mapping and synchronized blend | Walk cycle on target rig with fixed speed |
| Saved edits vanish | Library ownership/import boundary/cache | Generated data or stale cache | Externalize intentional edits and fresh reload | Reimport and replay saved clip |

Sources: [AnimationTree](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html), [AnimationMixer root motion](https://docs.godotengine.org/en/4.7/classes/class_animationmixer.html), [AnimationLibrary](https://docs.godotengine.org/en/4.7/classes/class_animationlibrary.html), [AnimationMixer binding](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/scene/animation/animation_mixer.cpp).
