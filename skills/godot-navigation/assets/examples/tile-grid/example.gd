extends SceneTree
var checks: Array[Dictionary] = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--out")
	if index < 0 or index + 1 >= args.size():
		push_error("OUTPUT_ARGUMENT_REQUIRED")
		quit(1)
		return
	output = args[index + 1].replace("\\", "/").simplify_path()
	if not output.is_absolute_path() or DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("OUTPUT_DIRECTORY_FAILED")
		quit(1)
		return
	call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks.append({"name": label, "status": "passed" if value else "failed"})
func finish() -> void:
	var passed := not checks.is_empty()
	for item: Dictionary in checks:
		passed = passed and item.status == "passed"
	var report := {"schema_version": 1, "status": "passed" if passed else "failed", "engine": Engine.get_version_info(), "platform": OS.get_name(), "display": DisplayServer.get_name(), "checks": checks, "artifacts": [output]}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		push_error("REPORT_WRITE_FAILED")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(report))
	quit(0 if passed else 1)


class GridBridge extends RefCounted:
	var grid := AStarGrid2D.new()
	var layer: TileMapLayer
	var blockers: Dictionary = {}
	var costs: Dictionary = {}
	func build(source: TileMapLayer) -> void:
		layer = source
		grid.region = layer.get_used_rect()
		grid.cell_size = Vector2(layer.tile_set.tile_size)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.jumping_enabled = false
		grid.update()
		replay()
	func replay() -> void:
		for y in range(grid.region.position.y, grid.region.end.y):
			for x in range(grid.region.position.x, grid.region.end.x):
				var cell := Vector2i(x, y)
				var data := layer.get_cell_tile_data(cell)
				var solid := data == null or not data.has_custom_data("walkable") or not bool(data.get_custom_data("walkable"))
				grid.set_point_solid(cell, solid or blockers.has(cell))
				grid.set_point_weight_scale(cell, float(costs.get(cell, 1.0)))
	func weight(cell: Vector2i, value: float) -> bool:
		if not grid.is_in_boundsv(cell) or not is_finite(value) or value <= 0.0:
			return false
		costs[cell] = value
		grid.set_point_weight_scale(cell, value)
		return true
	func block(cell: Vector2i, value: bool) -> bool:
		if not grid.is_in_boundsv(cell):
			return false
		if value:
			blockers[cell] = true
		else:
			blockers.erase(cell)
		# Reapply authored rules; opening a door must not open an authored wall.
		replay()
		return true
	func path(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
		if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b) or grid.is_point_solid(a) or grid.is_point_solid(b):
			return []
		return grid.get_id_path(a, b)

func _run() -> void:
	var image := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i(16, 16)
	atlas.create_tile(Vector2i.ZERO)
	atlas.create_tile(Vector2i(1, 0))
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(16, 16)
	tiles.add_custom_data_layer()
	tiles.set_custom_data_layer_name(0, "walkable")
	tiles.set_custom_data_layer_type(0, TYPE_BOOL)
	tiles.add_source(atlas, 0)
	atlas.get_tile_data(Vector2i.ZERO, 0).set_custom_data("walkable", true)
	atlas.get_tile_data(Vector2i(1, 0), 0).set_custom_data("walkable", false)
	var layer := TileMapLayer.new()
	layer.tile_set = tiles
	layer.position = Vector2(80, 40)
	layer.scale = Vector2(2, 1.5)
	layer.rotation = 0.2
	root.add_child(layer)
	for x in range(-3, 3):
		layer.set_cell(Vector2i(x, -2), 0, Vector2i.ZERO)
		layer.set_cell(Vector2i(x, -1), 0, Vector2i.ZERO)
	layer.set_cell(Vector2i(-1, -2), 0, Vector2i(1, 0))
	layer.erase_cell(Vector2i(0, -1))
	var bridge := GridBridge.new()
	bridge.build(layer)
	var start := Vector2i(-3, -2)
	var goal := Vector2i(2, -2)
	# Restore one lower tile so the authored wall can be detoured.
	layer.set_cell(Vector2i(0, -1), 0, Vector2i.ZERO)
	bridge.build(layer)
	var route := bridge.path(start, goal)
	expect(not route.is_empty() and route[0] == start and route[-1] == goal and Vector2i(-1, -2) not in route, "negative_origin_route_detours_authored_wall")
	var world := layer.to_global(layer.map_to_local(start))
	expect(layer.local_to_map(layer.to_local(world)) == start, "transformed_world_cell_roundtrip")
	bridge.block(Vector2i(-1, -1), true)
	expect(bridge.path(start, goal).is_empty(), "dynamic_blocker_disconnects_route")
	bridge.block(Vector2i(-1, -1), false)
	expect(bridge.path(start, goal) == route, "opening_restores_route_without_shape_update")
	bridge.block(Vector2i(-1, -2), false)
	expect(bridge.grid.is_point_solid(Vector2i(-1, -2)), "unblock_preserves_authored_wall")
	layer.erase_cell(Vector2i(0, -1))
	bridge.build(layer)
	expect(bridge.grid.is_point_solid(Vector2i(0, -1)) and bridge.path(start, goal).is_empty(), "empty_cell_policy_is_solid")
	expect(bridge.path(Vector2i(99, 99), goal).is_empty() and not bridge.block(Vector2i(99, 99), true), "out_of_bounds_rejected_without_engine_error")
	layer.set_cell(Vector2i(0, -1), 0, Vector2i.ZERO)
	bridge.block(Vector2i(1, -2), true)
	layer.set_cell(Vector2i(3, -2), 0, Vector2i.ZERO)
	bridge.build(layer)
	expect(bridge.grid.is_point_solid(Vector2i(1, -2)), "resize_replays_runtime_blockers")
	bridge.weight(Vector2i(0, -1), 3.0)
	expect(is_equal_approx(bridge.grid.get_point_weight_scale(Vector2i(0, -1)), 3.0), "point_weight_does_not_require_update")
	bridge.build(layer)
	expect(is_equal_approx(bridge.grid.get_point_weight_scale(Vector2i(0, -1)), 3.0), "resize_replays_runtime_costs")
	bridge.block(Vector2i(1, -2), false)
	bridge.weight(Vector2i(0, -1), 1.0)
	bridge.weight(Vector2i(0, -2), 100.0)
	var weighted := bridge.path(start, goal)
	expect(not weighted.is_empty() and weighted[-1] == goal and Vector2i(0, -2) not in weighted, "weighted_route_avoids_expensive_cell")
	expect(not bridge.weight(Vector2i(0, -2), NAN) and not bridge.weight(Vector2i(0, -2), -1.0) and bridge.grid.get_point_weight_scale(Vector2i(0, -2)) == 100.0, "invalid_cost_preserves_prior_weight")
	layer.free()
	finish()
