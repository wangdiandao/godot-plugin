extends SceneTree
var checks: Array = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	output = args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
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
	var picture := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	picture.fill(Color.CORAL)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(picture)
	atlas.texture_region_size = Vector2i(16, 16)
	atlas.create_tile(Vector2i.ZERO)
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(16, 16)
	var source_id := tiles.add_source(atlas)
	var layer := TileMapLayer.new()
	layer.tile_set = tiles
	for x in range(4):
		layer.set_cell(Vector2i(x, 0), source_id, Vector2i.ZERO)
	expect(layer.get_used_cells().size() == 4, "tile_cells_created")
	var scene := PackedScene.new()
	expect(scene.pack(layer) == OK, "tile_layer_pack")
	var path := output.path_join("tiles.tscn")
	expect(ResourceSaver.save(scene, path) == OK, "tile_layer_save")
	var loaded := (ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as TileMapLayer
	expect(loaded.get_cell_source_id(Vector2i(3, 0)) == source_id, "tile_cell_roundtrip")
	loaded.free()
	layer.free()
	finish()
