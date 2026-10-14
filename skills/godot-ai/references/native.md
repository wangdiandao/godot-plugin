# Game AI decision recipes (Godot 4.7)

## Develop an enemy decision module

Write a scenario table: no target→idle, hidden target→search/idle, visible distant target→chase, visible target in legal range→attack, critical health→flee when escape is legal. These are examples, not mandatory rules for every game. Specify cooldown, team, reachability and command ownership; do not let an attractive score make an illegal action executable.

Use Node for a tree-owned sensor/controller, RefCounted for pure scoring and immutable snapshots, and Resource for authored thresholds/actions. Shared definitions must not contain per-enemy mutable cooldown or current target. An enum fits a small exclusive behavior set; separate state modules only when dependencies and reuse justify them. AnimationTree states remain playback state, not the sole authority for combat decisions.

Gather bounded candidates using existing groups/sensors, check instance validity and tree membership, and turn observations into primitive data. A supplied visibility boolean is a test seam, not actual perception. For real sight, use physics raycasts at the correct physics boundary, with masks/self exclusions, and test walls, target exit and sensor update latency. Navigation owns reachability and paths; a missing path needs a fallback instead of an endless chase.

Filter legal actions, compute finite scores, and resolve ties by stable authored/entity identifiers when deterministic replays matter. The fixture uses instance IDs only for repeatable ordering within one session; it does not promise cross-run replay identity. Avoid a full state enter/exit cycle every tick when the state is unchanged. For fluctuating distance/health boundaries, use distinct entry/exit thresholds or a minimum dwell time, and bound the intentional response delay.

## Modify or diagnose decisions

Capture the observation snapshot, rejected-action reasons, scores, winner and state transition. Reproduce an unexpected choice with the same inputs before changing weights. Preserve command validation and public scene contracts. Inspect in order: sensor truth→legal candidates→score/tie→plan freshness→command acceptance→movement/animation. A stuck enemy can be a missing route or rejected command rather than a broken decision model.

| Symptom | Check and repair | Retest |
|---|---|---|
| Enemy attacks through a wall | Inspect actual sight observation and collision masks; remove occluded attack from legal candidates | Wall present/removed, same target/range |
| State flickers at range boundary | Compare entry/exit thresholds and transition counts; add justified hysteresis | Oscillating distances and deliberate threshold crossing |
| Targets disappear mid-plan | Use weak references or stable entity lookup and revision tokens; revalidate before commitment | Free/detach target and complete a delayed plan |
| Unit choices block teammates | Plan against a snapshot updated after each reserved action | Two units competing for one tile/action, no mutation during evaluation |
| UI freezes while AI thinks | Measure candidate count and per-operation cost; bound work per frame | Same final decision, observed reaction latency and frame tails |

## Budgeted planning and team decisions

Snapshot pure data before yielding. A count budget bounds operations but not milliseconds; one expensive query can exceed a frame budget. Measure elapsed microseconds between small work units and yield once the chosen budget is reached. Check cancellation/world revision before resuming and before applying a result. Worker threads may compute pure array data; keep unsafe scene/Godot API calls on their permitted thread and join workers on shutdown.

For team coordination, reserve destinations and scarce actions in a scratch snapshot, score a bounded set of orders, and commit through validated commands. Exhaustive permutations grow factorially; use a bounded search or seeded sampling when appropriate. Record seed/search bound and compare legal outcomes, not only a score increase. Team planning is a documented recipe, not tested by the single-actor fixture.

## Run the decision fixture

Copy the complete example directory to a fresh workspace, create OUT, then run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Use absolute paths. Inspect the exit code, full error log and named `GODOT_PLUGIN_RESULT:` assertions together. Outputs belong to OUT; do not run fixtures against a player's real saves.

The example tests idle/chase/attack/flee from supplied observations, nonfinite health rejection, same-session target ties, single state transition entry/exit, target deletion, copied planning snapshots, three candidates per frame, equivalence to serial scoring, stale-generation cancellation and custom monitor removal. It records result.json. It performs no actual path movement, sight raycast, combat animation or background threading.

Sources: [Node lifecycle](https://docs.godotengine.org/en/4.7/classes/class_node.html), [RefCounted](https://docs.godotengine.org/en/4.7/classes/class_refcounted.html), [thread safety](https://docs.godotengine.org/en/4.7/tutorials/performance/thread_safe_apis.html), [Performance](https://docs.godotengine.org/en/4.7/classes/class_performance.html). Community design source: [Shaggy Dev's unit AI and team planning](https://shaggydev.com/2025/03/17/unit-ai/), 2025-03-17. The bundled code is an original implementation, not a redistribution of that game's code or assets.

Version evidence: [Godot 4.7.2 source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). Recheck the actual target binary. Community discussions supply use cases; official contracts and runtime checks determine supported behavior.
