---
name: godot-2d
description: "Build Godot 2D content, including sprites, TileSets, TileMapLayer, terrain, level layouts, and Camera2D."
---

# 2D Worlds

## Purpose and Scope

2D visuals and maps. Coordinate movement and collision with physics, and complex animation with animation.

## Prerequisite Checks

Confirm world units, tile sizes, texture dimensions, coordinate systems, and rendering scale; use TileMapLayer for new maps.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Place sprites with Sprite2D/AnimatedSprite2D. Configure filtering and integer scaling for the specific pixel art project; do not force pixel art settings on all 2D games.
2. Create a TileSetAtlasSource, assign a unique source_id, then create tiles and TileMapLayer cells; terrain connections require a complete set of terrain combinations first.
3. Convert cell coordinates with map_to_local/local_to_map, distinguishing node-local, world, and screen coordinates.
4. Configure Camera2D bounds and a separate UI CanvasLayer; test multiple resolutions and map boundaries.

## File Changes, Saving, and Recovery

Save TileSets and level scenes separately, preserving external references; check every consumer before changing a shared TileSet.
For missing cells, check source_id, atlas_coords, and alternative_tile first. For terrain seams, complete the terrain combinations instead of randomly replacing textures.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example creates a tile source and cells through the API, then saves and reloads them to verify used cell counts and coordinates; the integration game checks viewport coverage and boundaries.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [complete task recipes and diagnostic paths](references/recipes.md) for developing, modifying or repairing this domain; choose the recipe matching the requested behavior.

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
