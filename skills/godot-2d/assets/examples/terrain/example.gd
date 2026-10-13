extends SceneTree
var checks: Array = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	output = args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
	output = output.replace("\\", "/")
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("OUTPUT_DIRECTORY_FAILED")
		quit(1)
		return
	call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks.append({"name": label, "status": "passed" if value else "failed"})
func finish() -> void:
	var ok := not checks.is_empty()
	for item: Dictionary in checks:
		ok = ok and item.status == "passed"
	var result := {"schema_version": 1, "status": "passed" if ok else "failed", "engine": Engine.get_version_info(), "platform": OS.get_name(), "display": DisplayServer.get_name(), "checks": checks, "artifacts": [output]}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		push_error("REPORT_WRITE_FAILED")
		quit(1)
		return
	file.store_string(JSON.stringify(result, "	"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	quit(0 if ok else 1)

func _run() -> void:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.CORAL)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(16, 16)
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(16, 16)
	tiles.add_terrain_set()
	tiles.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tiles.add_terrain(0)
	tiles.add_source(source, 0)
	var sides := [TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE]
	for mask in range(16):
		var coordinate := Vector2i(mask % 4, mask / 4)
		source.create_tile(coordinate)
		var data := source.get_tile_data(coordinate, 0)
		data.terrain_set = 0
		data.terrain = 0
		for bit in range(4):
			data.set_terrain_peering_bit(sides[bit], 0 if mask & (1 << bit) else -1)
	var layer := TileMapLayer.new()
	layer.tile_set = tiles
	layer.position = Vector2(48, 32)
	var cells: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(2, 0)]
	layer.set_cells_terrain_connect(cells, 0, 0, false)
	expect(layer.get_used_cells().size() == 3, "terrain_painted_three_cells")
	var left := layer.get_cell_tile_data(Vector2i.ZERO)
	var middle := layer.get_cell_tile_data(Vector2i.RIGHT)
	expect(left != null and middle != null, "terrain_tiles_resolved")
	if left != null and middle != null:
		expect(left.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE) == -1, "empty_boundary_matches")
		expect(left.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE) == 0 and middle.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE) == 0, "neighbor_bits_connect")
	var packed := PackedScene.new()
	expect(packed.pack(layer) == OK, "pack_terrain")
	var path := output.path_join("terrain.tscn")
	expect(ResourceSaver.save(packed, path) == OK, "save_terrain")
	var resource := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	expect(resource != null, "reload_terrain")
	if resource != null:
		var loaded := resource.instantiate() as TileMapLayer
		expect(loaded.tile_set.get_terrain_set_mode(0) == TileSet.TERRAIN_MODE_MATCH_SIDES, "saved_terrain_mode")
		expect(loaded.get_used_cells().size() == 3, "saved_terrain_cells")
		root.add_child(loaded)
		var cell := Vector2i(2, 0)
		expect(loaded.local_to_map(loaded.to_local(loaded.to_global(loaded.map_to_local(cell)))) == cell, "world_local_map_roundtrip")
		loaded.queue_free()
	layer.free()
	await process_frame
	finish()
