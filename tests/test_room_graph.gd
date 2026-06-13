# GdUnit4 suite: room graph occlusion for proximity muffling.
extends GdUnitTestSuite


func _make_grid() -> Array:
	var grid: Array = []
	for x in 5:
		var row: Array = []
		for y in 5:
			row.append(1)
		grid.append(row)
	grid[1][1] = 0
	grid[3][1] = 0
	grid[2][1] = 1
	return grid


func _cell_for(x: int, y: int) -> Callable:
	return func(_world: Vector3) -> Vector2i:
		return Vector2i(x, y)


func test_same_room_no_occlusion() -> void:
	var grid := _make_grid()
	var graph = RoomGraph.from_wall_grid(grid, _cell_for(1, 1))
	var db: float = graph.get_occlusion_db(Vector3.ZERO, Vector3.ONE, -18.0, -6.0)
	assert_float(db).is_equal_approx(0.0, 0.001)


func test_separated_by_wall() -> void:
	var grid := _make_grid()
	var graph = RoomGraph.new()
	graph._wall_grid = grid
	graph._world_to_cell = func(pos: Vector3) -> Vector2i:
		if pos.x < 0.5:
			return Vector2i(1, 1)
		return Vector2i(3, 1)
	graph._build_rooms()
	var db: float = graph.get_occlusion_db(Vector3(-1, 0, 0), Vector3(1, 0, 0), -18.0, -6.0)
	assert_float(db).is_less(-1.0)
