# Locomotion graphs, interruption and skeletal events

## Select an implementation

| Task | Recipe/example | Observable result |
|---|---|---|
| Animate one property | recipes.md and minimal | Sampled values before/after save |
| Idle/move/action with interruption | state-machine example below | Actual blended property and replayed graph |
| Collision-aware root motion | recipes.md root-motion | Extract once; controller applies once |
| Rig/event problem | Checks below | Bone pose/event counts on the actual rig |

## Develop and persist idle/move/action

1. Inventory the existing animation root, libraries and property/bone paths. Use one active writer for each property; do not mix AnimationPlayer.play with an active tree owning the same track.
2. Define idle/move/action clips and base values. For partial tracks, decide RESET/default policy rather than inheriting an accidental pose from whichever clip played last.
3. Add AnimationNodeAnimation nodes to an AnimationNodeStateMachine. Add directed transitions, crossfade duration and switch mode explicitly. Start the playback state before travel. Travel without a connecting path can teleport, so a returned state name cannot prove a blend occurred.
4. Drive movement parameters from authoritative controller state. For continuous speed/direction use BlendSpace1D/2D with points covering the input domain; phase synchronization and speed matching need the target walk cycle.
5. Sample actual properties during and after transition. Interrupt action back to locomotion and verify pose plus event policy. An action's gameplay cost belongs in a validated gameplay command, not in an arbitrary animation callback.
6. Save graph, libraries and actor scene, load a fresh instance and replay the sequence. Preserve imported clips by externalizing intended edits rather than modifying generated caches.

The [state-machine fixture](../assets/examples/state-machine/project.godot) runs manual AnimationTree sampling, verifies an intermediate blend, final move pose, action interruption and saved graph replay. It also detects and repairs an invalid track target before playback. Run example.gd using native.md's command. Outputs: locomotion.tscn, result.json and log. Its scalar property test does not certify a particular skeleton or foot placement.

The [event-rig fixture](../assets/examples/event-rig/project.godot) creates an original one-bone rig, evaluates a bone-position track and immediate method event, interrupts before the event, restarts and replays after saved reload. It proves those named mechanics, not humanoid retargeting or deferred-event cancellation.

## Modify a rig or event track

Record bone names, parent hierarchy and rest transforms before retargeting. Equal names alone do not establish compatible rests. Track paths resolve against animation root and bone subnames; verify every target before playback. Distinguish a pose offset from replacing a rest transform. Test a neutral pose, full gait, root rotation, teleport and reset on the actual rig.

For a method track, use TYPE_METHOD and a dictionary key containing `method` and `args`. Choose immediate versus deferred callback intentionally. Count callbacks during actual advance/playback, interruption and repeated cycles. Do not infer event counts from seek-based property sampling. A queued deferred callback may outlive the action that requested it; validate the current gameplay action token before applying damage or spending a resource.

For a bone socket, use the mesh-socket recipe in godot-3d. Root-motion translation/rotation is local animation data: transform into the controller's orientation and apply through collision-aware motion, once. When changing rig scale or loop policy, compare clip displacement to measured actor movement; retain wall contact as a negative control.

## Diagnose in order

1. **Nothing moves:** resolve animation root and track target, inspect processing/active state, then look for a competing script/tree writer. Do not change all animation paths speculatively.
2. **Snaps:** compare previous state values, missing tracks/RESET, rest pose and crossfade; enter from each relevant state and sample intermediate values.
3. **Wrong event count:** inspect immediate/deferred policy, duplicate event keys, looping, interruption and old action token; count accepted gameplay effects independently from callbacks.
4. **Double distance:** compare direct root track application, extraction and controller movement. Remove the extra writer, then measure displacement against a known clip plus blocked motion.
5. **Reimport loses edits:** inspect library provenance and externalization, preserve generated versus authored data, reimport twice and replay saved clips.

On failed modification, restore the graph and its libraries as one contract. Do not erase RESET or mute all method tracks to hide a regression. Keep a failed capture and exact transition sequence.

Sources: [AnimationTree](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html), [state playback](https://docs.godotengine.org/en/4.7/classes/class_animationnodestatemachineplayback.html), [AnimationMixer](https://docs.godotengine.org/en/4.7/classes/class_animationmixer.html), [retargeting](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html).
