class_name TestRoomGraph
extends RefCounted

const RoomGraphScript := preload("res://room_graph.gd")


func run() -> int:
	var failures := 0
	failures += _test_same_room_no_occlusion()
	failures += _test_separated_by_wall()
	return failures


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


func _test_same_room_no_occlusion() -> int:
	var grid := _make_grid()
	var graph = RoomGraphScript.from_wall_grid(grid, _cell_for(1, 1))
	var db: float = graph.get_occlusion_db(Vector3.ZERO, Vector3.ONE, -18.0, -6.0)
	if not is_equal_approx(db, 0.0):
		push_error("Expected zero occlusion in same room")
		return 1
	return 0


func _test_separated_by_wall() -> int:
	var grid := _make_grid()
	var graph = RoomGraphScript.new()
	graph._wall_grid = grid
	graph._world_to_cell = func(pos: Vector3) -> Vector2i:
		if pos.x < 0.5:
			return Vector2i(1, 1)
		return Vector2i(3, 1)
	graph._build_rooms()
	var db: float = graph.get_occlusion_db(Vector3(-1, 0, 0), Vector3(1, 0, 0), -18.0, -6.0)
	if db >= -1.0:
		push_error("Expected wall occlusion between separated rooms")
		return 1
	return 0
