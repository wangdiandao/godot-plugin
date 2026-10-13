# 2D Worlds: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [TileMapLayer](https://docs.godotengine.org/en/4.7/classes/class_tilemaplayer.html)
- [TileSet](https://docs.godotengine.org/en/4.7/classes/class_tileset.html)
- [TileSetAtlasSource](https://docs.godotengine.org/en/4.7/classes/class_tilesetatlassource.html)
- [Camera2D](https://docs.godotengine.org/en/4.7/classes/class_camera2d.html)
- [Sprite2D](https://docs.godotengine.org/en/4.7/classes/class_sprite2d.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.


## Saving and Validation

Save TileSets and level scenes separately, preserving external references; check every consumer before changing a shared TileSet.
The example creates a tile source and cells through the API, then saves and reloads them to verify used cell counts and coordinates; the integration game checks viewport coverage and boundaries.

## Common Pitfalls and Recovery

- TileMapLayer updates may be deferred until the end of the frame; use the official synchronization API when immediate results are required.
- Do not apply the old TileMap multilayer API to TileMapLayer.

For missing cells, check source_id, atlas_coords, and alternative_tile first. For terrain seams, complete the terrain combinations instead of randomly replacing textures.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## TileSets and Terrain

TileSetAtlasSource.texture and texture_region_size define the atlas. After creating a tile with `create_tile(atlas_coords, size)`, call `TileSet.add_source(atlas)` to obtain source_id, then `TileMapLayer.set_cell(cell, source_id, atlas_coords, alternative)`. Cell, atlas, and world coordinates are three distinct spaces; convert with `local_to_map()`/`map_to_local()` and account for Node2D transforms.

Configure terrain with `TileSet.add_terrain_set()`, `set_terrain_set_mode()`, `add_terrain()`, and TileData.terrain_set/terrain/`set_terrain_peering_bit()`. Call `TileMapLayer.set_cells_terrain_connect(cells, terrain_set, terrain, ignore_empty_terrains)` only after preparing all adjacency combinations. Automatic connections cannot create missing edge/corner artwork. The minimal example tests only basic tile persistence; add acceptance images for terrain matching with the specific tileset.

Configure Camera2D.enabled, position_smoothing_enabled, and limits through node properties, capturing multiple boundary positions to verify the view. For pixel art, define texture filtering, integer scaling, and camera pixel alignment; changing one global setting cannot guarantee jitter-free rendering. Route collision layers, masks, and TileData collision shapes to godot-physics.


## Task recipes

Use [recipes.md](recipes.md) for complete development, modification and diagnosis flows. Fixture assertions and visual/platform checks have separate acceptance scopes.
