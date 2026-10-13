# Tile worlds, terrain and camera recipes

Read [native.md](native.md) for command paths. Choose a square/isometric/hexagonal layout before authoring a TileSet; neighbor directions and terrain combinations depend on that layout. World positioning, tile coordinates and viewport pixels are distinct spaces.

## Develop: a tile level with deterministic terrain

1. Create a TileSet with the intended tile size, a TileSetAtlasSource texture and region size. Allocate an explicit source ID and create atlas tiles before setting cells. Keep visual textures, collisions, navigation and custom tile data as separate decisions.
2. Choose the terrain matching mode: sides, corners, or both. Configure terrain sets and terrain IDs on each TileData. Supply every required peering-bit combination, including empty boundaries when empty terrain participates.
3. Paint via `set_cells_terrain_connect(cells, terrain_set, terrain, ignore_empty_terrains)`. The call can modify neighbors; compare the affected rectangle plus a neighbor border. Use `set_cells_terrain_path` when the intended ordered path differs from connecting a filled patch.
4. Save the scene and TileSet, then reload with CACHE_MODE_IGNORE. Assert used cells, source IDs, terrain mode, peering bits and collision/navigation data separately.
5. Add a Camera2D with deliberate limits/zoom. Keep HUD controls in CanvasLayer. Run small, wide and tall viewports; inspect actual screen center after smoothing instead of assuming the Camera2D node's position is the displayed center.

The [terrain fixture](../assets/examples/terrain/project.godot) generates all 16 four-side combinations for one square-grid terrain and paints three cells. It checks both joined neighbors and an empty boundary, scene readback and coordinate conversion. It proves terrain metadata, not artistic seams. Run the same native command with EXAMPLE pointing to `terrain/`.

## Modify: move the world without corrupting cell placement

Edit a copied level first. Convert the pointer through the layer transform, rather than passing a global point directly to `local_to_map`:

```gdscript
var cell := layer.local_to_map(layer.to_local(global_pointer))
var cell_center_global := layer.to_global(layer.map_to_local(cell))
```

Preserve source IDs and atlas coordinates when moving or adding atlas sources. For existing terrain, collect target cells as `Array[Vector2i]` and repatch the local neighborhood. TileMapLayer updates are batched; use `update_internals()` only when the task needs an immediate consistency check, rather than forcing it every frame. Runtime changes to a shared TileSet can alter every level that uses it; duplicate only the resources requiring independence.

Camera limits constrain the camera view, while offset can place the rendered center beyond limits. After a teleport, reset smoothing and force the intended camera scroll update; inspect `get_screen_center_position()`. Follow deadzones, smoothing and pixel snapping need a target-resolution test. Integer scaling is appropriate for a pixel-art game only when the chosen viewport and presentation policy support it.

## Diagnose and retest

| Symptom | Check | Cause | Repair | Retest |
|---|---|---|---|---|
| Cell disappears after reload | source ID, atlas tile and alternative index | Invalid source reference | Restore the correct source/tile | Fresh scene reload and used-cell IDs |
| Terrain edge chooses wrong tile | Mode, empty terrain and complete peering combinations | Missing candidate or wrong neighbor direction | Supply the required combination | Interior, border, corner and erase/repaint cases |
| Click paints offset tile | Layer transform and local/world conversion | Mixed coordinate spaces | Transform into layer-local space | Moved/scaled parent and known cell center |
| Camera drifts after teleport | Smoothing state and displayed center | Old interpolation state | Reset at teleport | Limits and one-frame/post-smoothing captures |
| Tile collider seems absent | TileSet physics layer, body filters, pending updates | Metadata/filter/sync issue | Fix intended layer and wait for physics sync | Ray or body contact, plus wrong-mask negative case |

Sources: [TileMapLayer](https://docs.godotengine.org/en/4.7/classes/class_tilemaplayer.html), [TileSet terrain](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilesets.html), [Camera2D](https://docs.godotengine.org/en/4.7/classes/class_camera2d.html), [TileMapLayer implementation](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/scene/2d/tile_map_layer.cpp).
