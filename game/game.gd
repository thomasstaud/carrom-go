class_name Game
extends Node2D

signal end_game

enum State {
	POSITIONING,
	AIMING,
	SHOOTING,
}

enum Player {
	HOTSEAT,
	BLACK,
	WHITE,
}

const MENU = preload("res://ui/menu.tscn")
const STONE = preload("res://stones/stone.tscn")
const STONE_DIAMETER: float = 38.0

# --- physics ---
const SHOOT_SPEED: float = 0.05
const MIN_SHOOT_SPEED: float = 0.25
# 1.0 is no friction, 0.0 is no movement
const SLICKNESS: float = 0.99
# 1.0 is full bounce, 0.0 is no bounce
const BOUNCINESS: float = 0.6
# higher value means worse performance but better collisions
const COLLISION_PRECISION: float = 4.0

# TODO: just use actual screen size + stone radius bounds
const SCREEN_BOUNDS := Vector4(-50, -50, 1200, 700)

var player: Player
var state: State
# true, if a player passed in the previous turn
var passing: bool
var turn_black := false
var current_stone: Stone
# stores each stone by its board position
var placed_stones: Dictionary[Vector2i, Stone] = {}
var shooting_dir: Vector2
var shot_valid: bool

@onready var multiplayer_controller: MultiplayerController = $MultiplayerController
@onready var go: Go = $Go
@onready var board: Board = $Board
@onready var stone_container: Node2D = $StoneContainer
@onready var ui: UI = $UI

func init(p_player: Player):
	print("starting game as %s" % p_player)
	
	player = p_player
	if player != Player.HOTSEAT:
		multiplayer_controller.init(self)
	
	go.init(board.size)
	go.stone_captured.connect(stone_captured)
	
	ui.init(player)
	ui.player_passed.connect(player_passed)
	
	next_turn()

func _process(_delta: float) -> void:
	match state:
		State.POSITIONING:
			positioning()
		State.AIMING:
			aiming()
		State.SHOOTING:
			shooting()


func positioning():
	if not acting():
		return
	
	# TODO: no red circle overlap
	var mouse_y = get_viewport().get_mouse_position().y
	current_stone.position.y = clamp(mouse_y, board.y_min, board.y_max)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		state = State.AIMING

func aiming():
	if not acting():
		return
	
	if Input.is_action_pressed("ui_cancel"):
		state = State.POSITIONING
	
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		passing = false
		shoot()

func shooting():
	shooting_dir *= SLICKNESS
	
	# too slow
	if shooting_dir.length() < MIN_SHOOT_SPEED and acting():
		if shot_valid:
			# snap in place
			var board_pos = closest_unoccupied_board_pos(current_stone.position)
			snap_stone(board_pos)
			
			if online():
				multiplayer_controller.snapping_out(board_pos)
		else:
			current_stone.queue_free()
			next_turn()
		return
	
	var movement: Vector2 = shooting_dir * SHOOT_SPEED
	var increments: int = ceil(movement.length() * COLLISION_PRECISION)
	
	for i in range(increments):
		current_stone.position += movement / increments
		
		# collide with other stones
		for stone in placed_stones.values():
			var vec = current_stone.position - stone.position
			if vec.length() <= STONE_DIAMETER:
				# collision
				shooting_dir = shooting_dir.reflect(vec.normalized().orthogonal()) * BOUNCINESS
				return
		
		# collide with border
		if shot_valid:
			if current_stone.position.x < board.bounds.x or current_stone.position.x > board.bounds.z:
				shooting_dir = shooting_dir.reflect(Vector2.UP) * BOUNCINESS
				return
			if current_stone.position.y < board.bounds.y or current_stone.position.y > board.bounds.w:
				shooting_dir = shooting_dir.reflect(Vector2.RIGHT) * BOUNCINESS
				return
		
		if not shot_valid:
			if in_bounds(current_stone.position, board.bounds):
				shot_valid = true
			if not in_bounds(current_stone.position, SCREEN_BOUNDS) and acting():
				current_stone.queue_free()
				next_turn()
				return


func shoot():
	shooting_dir = get_viewport().get_mouse_position() - current_stone.position
	shot_valid = false
	state = State.SHOOTING
	
	if online():
		multiplayer_controller.shooting_out(shooting_dir, current_stone.position)

func snap_stone(board_pos: Vector2i):
	current_stone.board_pos = board_pos
	current_stone.position = board_to_world_pos(board_pos)
	# make go move
	placed_stones[board_pos] = current_stone
	go.add_stone(board_pos, turn_black)
	next_turn()


func in_bounds(pos: Vector2, bounds: Vector4):
	return pos.x >= bounds.x \
		and pos.x <= bounds.z \
		and pos.y >= bounds.y \
		and pos.y <= bounds.w

func get_cell_size() -> Vector2:
	return Vector2(
		(board.bounds.z - board.bounds.x) / (board.size.x - 1),
		(board.bounds.w - board.bounds.y) / (board.size.y - 1)
	)

func closest_unoccupied_board_pos(pos: Vector2) -> Vector2i:
	var poss: Array[Vector2i] = four_closest_board_pos(pos)
	var actual: Vector2 = world_to_board_pos_unrounded(pos)
	
	poss.sort_custom(func(a: Vector2, b: Vector2): return a.distance_to(actual) < b.distance_to(actual))
	for check in poss:
		if check not in placed_stones:
			return check
	printerr("something has gone really wrong")
	return Vector2i(-1, -1)

func four_closest_board_pos(pos: Vector2) -> Array[Vector2i]:
	var cell_size: Vector2 = get_cell_size()
	var x = [
		floor((pos.x - board.bounds.x) / cell_size.x),
		ceil((pos.x - board.bounds.x) / cell_size.x)
	]
	var y = [
		floor((pos.y - board.bounds.y) / cell_size.y),
		ceil((pos.y - board.bounds.y) / cell_size.y)
	]
	
	var res: Array[Vector2i] = []
	for i in range(4):
		@warning_ignore("integer_division")
		res.append(Vector2i(x[i % 2], y[i / 2]))
	return res

func world_to_board_pos_unrounded(pos: Vector2) -> Vector2:
	var cell_size: Vector2 = get_cell_size()
	
	return Vector2(
		(pos.x - board.bounds.x) / cell_size.x,
		(pos.y - board.bounds.y) / cell_size.y
	)

func board_to_world_pos(pos: Vector2i) -> Vector2:
	var cell_size: Vector2 = get_cell_size()
	
	return Vector2(
		pos.x * cell_size.x + board.bounds.x,
		pos.y * cell_size.y + board.bounds.y
	)

func next_turn():
	turn_black = !turn_black
	current_stone = new_stone(turn_black)
	state = State.POSITIONING
	
	ui.set_turn(turn_black)

func new_stone(black: bool):
	var stone = STONE.instantiate()
	stone_container.add_child(stone)
	stone.set_texture(black)
	stone.position.x = board.x_black if black else board.x_white
	return stone

func stone_captured(pos: Vector2i) -> void:
	placed_stones[pos].queue_free()
	placed_stones.erase(pos)
	
	ui.update_captures(go.get_captured())

func player_passed() -> void:
	if online() and acting():
		multiplayer_controller.passing_out()
	
	if passing:
		# game is finished
		# TODO: display this on a nice panel
		var captured = go.get_captured()
		if captured[1] > captured[2]:
			print("White wins! %d to %d" % [captured[1], captured[2]])
		elif captured[2] > captured[1]:
			print("Black wins! %d to %d" % [captured[2], captured[1]])
		else:
			print("It's a tie! %d both" % captured[1])
		# back to menu (for now)
		# later, hook this up to a button on the nice panel
		end_game.emit()
	else:
		passing = true
		current_stone.queue_free()
		next_turn()


func online() -> bool:
	return player != Player.HOTSEAT
func acting() -> bool:
	if player == Player.HOTSEAT:
		return true
	if player == Player.BLACK and turn_black:
		return true
	if player == Player.WHITE and not turn_black:
		return true
	return false
