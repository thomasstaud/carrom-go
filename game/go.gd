class_name Go
extends Node

signal stone_captured

enum Point {
	EMPTY,
	BLACK,
	WHITE,
}

var _board_size: Vector2i
var _points: Dictionary[Vector2i, Point]
var _captured: Dictionary[int, int]

func init(board_size: Vector2i) -> void:
	_board_size = board_size
	
	for x in board_size.x:
		for y in board_size.y:
			_points[Vector2i(x, y)] = Point.EMPTY
	
	_captured[Point.BLACK] = 0
	_captured[Point.WHITE] = 0

func add_stone(pos: Vector2i, black: bool) -> void:
	var color = Point.BLACK if black else Point.WHITE
	_points[pos] = color
	
	# check for captures
	var dead_self := true
	
	# 1. check all adjacent different-colored shapes
	for neighbor in _get_4_neighbors_bounded(pos):
		if _points[neighbor] == Point.EMPTY:
			dead_self = false
			continue
		if _points[neighbor] == color:
			continue
		var res = _capture_stones_if_dead(neighbor)
		if res:
			dead_self = false
	
	# 2. if nothing was captured and there are no surrounding empty points,
	#    check the stone's own chain
	if not dead_self:
		return
	_capture_stones_if_dead(pos)

## returns number of captured stones as {1: captured black stones, 2: captured white stones}
func get_captured() -> Dictionary[int, int]:
	return _captured


func _capture_stones_if_dead(pos: Vector2i) -> bool:
	var group: Array[Vector2i] = _get_group_if_dead(pos)
	if group.is_empty():
		return false
	
	_capture_stones(group)
	return true

# if the stone at this position is dead, this method returns an array of all
#    connected positions that are also dead (including the given one)
# if the stone is not dead, returns []
func _get_group_if_dead(pos: Vector2i) -> Array[Vector2i]:
	var color: Point = _points[pos]
	var checked: Array[Vector2i] = []
	var to_check: Array[Vector2i] = [pos]
	
	while not to_check.is_empty():
		var check_pos = to_check.pop_front()
		checked.append(check_pos)
		
		for neighbor in _get_4_neighbors_bounded(check_pos):
			if _points[neighbor] == Point.EMPTY:
				return []
			if _points[neighbor] != color \
				or neighbor in checked \
				or neighbor in to_check:
				continue
			to_check.append(neighbor)
	
	return checked

func _capture_stones(positions: Array[Vector2i]) -> void:
	for pos in positions:
		_captured[_points[pos]] += 1
		_points[pos] = Point.EMPTY
		stone_captured.emit(pos)

func _get_4_neighbors_bounded(pos: Vector2i) -> Array[Vector2i]:
	if _board_size == Vector2i.ZERO:
		printerr("ERROR: board size has not been configured")
		return []
	
	var res: Array[Vector2i] = []
	if pos.x > 0:
		res.append(Vector2i(pos.x - 1, pos.y))
	if pos.x < (_board_size.x - 1):
		res.append(Vector2i(pos.x + 1, pos.y))
	if pos.y > 0:
		res.append(Vector2i(pos.x, pos.y - 1))
	if pos.y < (_board_size.y - 1):
		res.append(Vector2i(pos.x, pos.y + 1))
	return res
