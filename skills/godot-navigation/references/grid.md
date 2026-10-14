# Authored tile maps and dynamic grid paths

## Choose the graph

Use AStarGrid2D for regular grid neighbors, AStar2D for explicit graph edges such as teleporters, and NavigationRegion/Agent for free-position navigation. Game AI chooses goals/actions; this skill answers routes and movement connectivity. Distinguish movement blocking from line-of-sight/attack blocking: a pit can prevent walking without blocking a shot.

## Build, modify and diagnose

Keep TileMapLayer cell coordinates as grid IDs, including a negative get_used_rect origin. Set region/cell size/diagonal policy, call update once, then apply authored solidity and weights. A structural update clears point data; replay authored rules plus runtime blockers/cost overlays after resize. Updating point solidity/weights does not require rebuilding the grid. If using costs, disable jumping_enabled because it ignores weight scaling in this baseline.

Use TileSet custom data for the game's walkability rule rather than inferring it from art IDs or assuming collision always means blocked movement. Decide how missing/empty tile data behaves. Validate finite positive cost values before writing them. Clearing a runtime blocker must reveal the authored rule, not blindly turn an authored wall into floor. Preserve runtime overlays independently so rebuilding does not lose a closed door.

Query only in-bounds/non-solid endpoints, define whether partial paths are acceptable, and reject a route that does not reach the requested goal when full arrival is required. Draw/move at `layer.to_global(layer.map_to_local(cell))`; mouse/world requests need the inverse transform before local_to_map. Grid offsets do not account for transformed parent nodes.

| Symptom | Repair and acceptance |
|---|---|
| Path shifted on a negative/translated map | Keep native region and transform cell centers; test nonzero origin, rotation and scale |
| Route ignores authored walls | Write solidity after update and check custom data; assert every route cell is legal |
| Opening a door opens a permanent wall | Compose blocker overlay with authored rules; assert permanent wall remains blocked |
| Resize loses closed doors/costs | Replay point data from persistent rule layers; test resize while blocked |
| AI walks through a hole | Make empty-cell policy explicit; test unpainted cells inside the used rectangle |

## Run the grid fixture

Copy the complete example directory to a fresh workspace, create OUT, then run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Use absolute paths. Inspect the exit code, full error log and named `GODOT_PLUGIN_RESULT:` assertions together. Outputs belong to OUT; do not run fixtures against a player's real saves.

The [tile-grid example](../assets/examples/tile-grid/project.godot) constructs a real TileSetAtlasSource and TileMapLayer, tests negative-origin wall detours, transformed cell roundtrip, dynamic disconnection/reopening, authored-wall preservation, empty cells, invalid endpoints, resize blocker/cost overlays, invalid cost rejection and a route avoiding an expensive cell. It tests paths and coordinates, not actual character movement or visual tile art. Use the existing moving-agent recipe for free-position navigation arrival.

Sources: [TileMapLayer](https://docs.godotengine.org/en/4.7/classes/class_tilemaplayer.html), [TileSet custom data](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilesets.html), [AStarGrid2D](https://docs.godotengine.org/en/4.7/classes/class_astargrid2d.html). Community design: [Vav Labs tile-grid bridge](https://vav-labs.com/blog/tilemap-to-navigation-grid-in-godot/) (4.7, 2026-06); [Shaggy Dev navigation choices](https://shaggydev.com/2025/05/19/udd-navigation/) (2025-05, old TileMap syntax adapted rather than copied).

Version evidence: [Godot 4.7.2 source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). Recheck the actual target binary. Community discussions supply use cases; official contracts and runtime checks determine supported behavior.
