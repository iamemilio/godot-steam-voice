class_name RoomGraph
extends Resource

## Grid-based room connectivity for voice occlusion. Built once per maze/level.

var _wall_grid: Array = []
var _room_by_cell: Dictionary = {}
var _world_to_cell: Callable


static func from_wall_grid(wall_grid: Array, world_to_cell: Callable) -> Resource:
	var graph: Resource = load("res://room_graph.gd").new()
	graph._wall_grid = wall_grid
	graph._world_to_cell = world_to_cell
	graph._build_rooms()
	return graph


func get_occlusion_db(
	listener_position: Vector3,
	speaker_position: Vector3,
	closed_wall_db: float,
	open_door_db: float
) -> float:
	if _wall_grid.is_empty() or not _world_to_cell.is_valid():
		return 0.0
	var listener_cell: Vector2i = _world_to_cell.call(listener_position)
	var speaker_cell: Vector2i = _world_to_cell.call(speaker_position)
	if listener_cell == speaker_cell:
		return 0.0
	var listener_room: int = int(_room_by_cell.get(listener_cell, -1))
	var speaker_room: int = int(_room_by_cell.get(speaker_cell, -1))
	if listener_room < 0 or speaker_room < 0:
		return closed_wall_db
	if listener_room == speaker_room:
		return 0.0
	if _cells_adjacent_open(listener_cell, speaker_cell):
		return open_door_db
	return closed_wall_db


func _build_rooms() -> void:
	_room_by_cell.clear()
	var next_room := 0
	for gx in _wall_grid.size():
		for gy in _wall_grid[gx].size():
			var cell := Vector2i(gx, gy)
			if _room_by_cell.has(cell):
				continue
			if not _is_walkable(cell):
				continue
			_flood_fill_room(cell, next_room)
			next_room += 1


func _flood_fill_room(start: Vector2i, room_id: int) -> void:
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		if _room_by_cell.has(cell):
			continue
		if not _is_walkable(cell):
			continue
		_room_by_cell[cell] = room_id
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			stack.append(cell + offset)


func _is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false
	if cell.x >= _wall_grid.size():
		return false
	var row: Array = _wall_grid[cell.x]
	if cell.y >= row.size():
		return false
	return int(row[cell.y]) == 0


func _cells_adjacent_open(a: Vector2i, b: Vector2i) -> bool:
	if absi(a.x - b.x) + absi(a.y - b.y) != 1:
		return false
	return _is_walkable(a) and _is_walkable(b)
