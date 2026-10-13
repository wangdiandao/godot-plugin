# Moving agents, patrols, avoidance and links

Use [recipes.md](recipes.md) to establish baked topology and synchronized maps first. A path ending at the target is graph evidence; this workflow also observes the CharacterBody position.

## Develop a moving agent

1. Put NavigationAgent3D under the character. Configure path/target distances from speed, physics timestep and clearance. Avoid a stopping threshold smaller than one movement step unless the controller clamps its final step.
2. Wait for a nonzero map iteration and valid intended region owners before accepting movement. Set the target once per destination change. Call `get_next_path_position()` once in each active physics tick; do not query it recursively from waypoint signals.
3. Classify reachability after the path updates. A finished partial path is not target arrival. For this fixture, an unreachable route stops; a game may instead move to the reachable endpoint if that behavior is explicit.
4. Compute desired velocity from current position to the next waypoint. The controller owns one `move_and_slide()` per tick. Without avoidance, apply it directly; with avoidance, submit `agent.velocity` and apply only the `velocity_computed` value.
5. Keep collision shapes, gravity/floor behavior and stopping policy separate from navigation. Avoidance does not automatically keep the body on the floor or inside a navigation region.
6. On completion, stop future movement and zero requested avoidance velocity. On teleport, update the body and avoidance state deliberately using the verified API; do not keep an obsolete goal from the previous level.

Copy [moving-agent](../assets/examples/moving-agent/project.godot) in full. Run its example.gd with the command in native.md. `actor.gd` is a reusable controller with a capsule shape. The fixture excludes its region by layer, verifies no movement, repairs only the agent mask, then demonstrates a graph-reachable route blocked by a real collision wall. Removing that wall restores actual arrival. It enables avoidance and follows two more goals while detecting double motion application. An unreachable goal remains rejected. This establishes collision-aware movement and callback-based avoidance movement, not crowd collision avoidance quality.

## Modify into a patrol or click-to-move controller

Keep the motion owner unchanged. Patrol stores an ordered goal list and advances after actual target arrival, not merely navigation_finished. Decide pause duration and behavior on an unreachable waypoint. Click-to-move converts screen input through the active camera's ray into a world-space collision hit, then validates the target region; a UI-consumed click must not issue a world command. Reassign destinations only on user input or route completion.

Record original goal, speed, layers and connections. Change one policy, test arrival and excluded destinations, save the actor scene, then repeat after loading the real level. Preserve unrelated region costs and actor collision filters.

## Connect separate areas with a Link

1. Query the disconnected topology before adding a link; record the partial endpoint and region owners.
2. Place NavigationLink3D endpoints inside the intended regions. Set navigation layers, enabled/bidirectional policy and enter/travel cost explicitly. Link radius affects endpoint connection, not a physical jump clearance.
3. Wait for the map update and query both directions. A one-way link must reject the reverse route; disabling it must restore the unreachable control.
4. A navigation link supplies a graph edge, not jump/climb animation. In `link_reached`, capture metadata and queue the traversal decision. Do not recursively call next-path updates from the signal.
5. For a jump, suspend normal path movement, validate entry/exit, run a collision-aware traversal, then resume and verify the destination owner. Coordinate animation/root motion with one movement owner. If interrupted, cancel traversal and report the actual character location.

The [link fixture](../assets/examples/links/project.godot) verifies graph arrival with a one-way link, reverse exclusion, disablement and repaired forward routing. It does not move an actor across a gap or simulate jumping.

For 2D, author NavigationPolygon outlines and use NavigationAgent2D/NavigationLink2D with Vector2 coordinates; do not feed 3D triangle arrays into the 2D API. Repeat map readiness and actual-body arrival on a 2D fixture before claiming parity.

## Ordered failure branches

| Observation | Ordered checks | Repair and retained control |
|---|---|---|
| Valid path, stationary body | Controller enabled → next-path updates → requested velocity → callback → motion owner | Wire the missing stage; actual arrival and one movement per tick |
| Jitter or repeated path rebuild | Target assignment count → thresholds versus step distance → multiple writers | Stable target and one writer; several speeds and a reversal |
| Avoidance callback but no arrival | Safe velocity → collision obstruction → floor/edge constraints → reachability | Fix physical/route cause; keep an excluded goal |
| Link route exists but character cannot cross | Endpoint metadata → gameplay traversal state → collision → interruption | Implement explicit traversal; reject reverse/disabled link |
| Stops short yet reports finished | Final point versus target → reachable flag → stopping threshold | Classify partial path separately; inspect physical distance |

Sources: [NavigationAgent3D](https://docs.godotengine.org/en/4.7/classes/class_navigationagent3d.html), [agent movement](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationagents.html), [NavigationLink3D](https://docs.godotengine.org/en/4.7/classes/class_navigationlink3d.html), [NavigationAgent2D](https://docs.godotengine.org/en/4.7/classes/class_navigationagent2d.html).
