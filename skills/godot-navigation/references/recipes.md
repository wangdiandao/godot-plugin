# Baking, connectivity, path following and avoidance

Use [native.md](native.md) for execution. Navigation reachability, avoidance and physical collision are separate systems. Record map, layers, dimensions, agent clearance and bake parameters before diagnosing a route.

## Develop: connected regions and a moving agent

1. Supply CPU triangles/collision geometry to source data. Parse scene geometry on the main thread; asynchronous baking completes through its callback. Choose cell size/height, agent radius, slope, climb and minimum region parameters according to real character dimensions.
2. Save the baked NavigationMesh or NavigationPolygon and reload it. Check vertices/polygons and bounds. Baking agent radius erodes traversable space; NavigationAgent radius controls avoidance, not mesh clearance.
3. Assign regions to the same active map with matching cell dimensions. Similar shared edges establish connections; overlapping polygon interiors alone do not. Bake erosion can separate adjacent regions, requiring coherent borders or a deliberately configured NavigationLink.
4. Wait for map iteration and intended closest-point owners before querying. Region iteration alone can become valid before the whole map is ready. Bound the wait and fail with map/region diagnostics rather than force updating every frame.
5. Query with the intended navigation bitmask. Check the final point against the requested target: an unreachable query can return a partial path, so a nonempty path alone is insufficient.
6. Set an agent target once per destination change. In each physics frame, call `get_next_path_position()` once, compute desired velocity, and move the CharacterBody once. With avoidance active, submit velocity and apply `velocity_computed` safe velocity through the controller. Retain physical collision and stop-distance handling.

The minimal fixture bakes and reloads CPU geometry, then uses two manually authored polygons with exact shared edges to isolate connectivity. It checks successful cross-region arrival, excluded navigation layers and disabled-region failure. It does not claim moving-agent avoidance acceptance.

## Modify: a corridor or target lifecycle

Copy the affected bake source and parameters; compare narrow-door clearance against character dimensions before reducing radius. Rebuild only the relevant region and wait for its map update. Retest the old route, a changed route and a blocked target. Keep region/link costs explicit when selecting alternate routes.

Avoid reassigning the same target each frame: it can reset path state and cause oscillation. Keep desired-path and safe-velocity debugging separate. RVO avoidance can choose a velocity outside the navmesh and cannot create a path around a missing region. Teleports need position/velocity state updates; validate the next path point and physical controller location afterwards.

For 2D, use NavigationPolygon outlines with valid winding, geometry/source baking and map synchronization; the old immediate outline helper is deprecated. The principle matches 3D, but 3D triangle input and 2D outline APIs are not interchangeable.

## Diagnose and retest

| Symptom | Check | Cause | Repair | Retest |
|---|---|---|---|---|
| Empty bake | Bounds, triangle winding, parse filters, clearance | No usable source or erosion removed it | Fix geometry/filters and justified agent parameters | Reload nonempty mesh and query endpoints |
| Route stops at border | Map identity, shared edges, erosion, layers | Regions disconnected | Correct borders or intended link | Final point reaches target across regions |
| First query errors | Map iteration and owners | Query before map sync | Wait on observable readiness with timeout | Cold startup and region replacement |
| Agent jitters | Target reassignment, path update count, distance thresholds | Controller/path state reset | Stable target and one path update per tick | Same route at several speeds |
| Avoidance agent leaves floor | Safe velocity versus mesh and collision | Avoidance ignores region topology | Physical movement constraints and valid path following | Corridor, obstacle and edge cases |

Sources: [NavigationServer3D](https://docs.godotengine.org/en/4.7/classes/class_navigationserver3d.html), [NavigationAgent3D](https://docs.godotengine.org/en/4.7/classes/class_navigationagent3d.html), [Navigation overview](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_introduction_3d.html), [Navigation source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079/servers/navigation).
