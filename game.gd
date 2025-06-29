class_name Game
extends Node2D

enum State {
	POSITIONING,
	AIMING,
	SHOOTING,
}

const STONE = preload("res://stone.tscn")
const STONE_DIAMETER: float = 55.0

# --- physics ---
const SHOOT_SPEED: float = 0.05
const MIN_SHOOT_SPEED: float = 0.25
# 1.0 is no friction, 0.0 is no movement
const SLICKNESS: float = 0.99
# 1.0 is full bounce, 0.0 is no bounce
const BOUNCINESS: float = 0.6
# higher value means worse performance but better collisions
const COLLISION_PRECISION: float = 2.0

# TODO: tie this to its own node
# --- board ---
const BOARD_SIZE := Vector2(9, 9)
# placement bounds
const X_BLACK: int = 261
const X_WHITE: int = 901
const Y_MIN: int = 63
const Y_MAX: int = 575
# shooting bounds
const SCREEN_BOUNDS := Vector4(-50, -50, 1200, 700)
# TODO: increase bounds by stone radius
const BOARD_BOUNDS := Vector4(326, 64, 836, 574)

var state: State
var turn_black := false
var current_stone: Stone
# stores each stone by its board position
var placed_stones: Dictionary[Vector2i, Stone] = {}
var shooting_dir: Vector2
var shot_valid: bool

@onready var go: Go = $Go
@onready var stone_container: Node2D = $StoneContainer

func _ready() -> void:
	go.init(BOARD_SIZE)
	go.stone_captured.connect(stone_captured)
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
	# TODO: no red circle overlap
	var mouse_y = get_viewport().get_mouse_position().y
	current_stone.position.y = clamp(mouse_y, Y_MIN, Y_MAX)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		state = State.AIMING

func aiming():
	if Input.is_action_pressed("ui_cancel"):
		state = State.POSITIONING
	
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shoot()

func shooting():
	shooting_dir *= SLICKNESS
	
	# too slow
	if shooting_dir.length() < MIN_SHOOT_SPEED:
		if shot_valid:
			# snap in place
			var board_pos = world_to_board_pos(current_stone.position)
			current_stone.board_pos = board_pos
			current_stone.position = board_to_world_pos(board_pos)
			# make go move
			go.add_stone(board_pos, turn_black)
			placed_stones[board_pos] = current_stone
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
			if current_stone.position.x < BOARD_BOUNDS.x or current_stone.position.x > BOARD_BOUNDS.z:
				shooting_dir = shooting_dir.reflect(Vector2.UP) * BOUNCINESS
				return
			if current_stone.position.y < BOARD_BOUNDS.y or current_stone.position.y > BOARD_BOUNDS.w:
				shooting_dir = shooting_dir.reflect(Vector2.RIGHT) * BOUNCINESS
				return
		
		if not shot_valid:
			if in_bounds(current_stone.position, BOARD_BOUNDS):
				shot_valid = true
			if not in_bounds(current_stone.position, SCREEN_BOUNDS):
				current_stone.queue_free()
				next_turn()
				return


func shoot():
	shooting_dir = get_viewport().get_mouse_position() - current_stone.position
	shot_valid = false
	state = State.SHOOTING

func in_bounds(pos: Vector2, bounds: Vector4):
	return pos.x >= bounds.x \
		and pos.x <= bounds.z \
		and pos.y >= bounds.y \
		and pos.y <= bounds.w

func get_cell_size() -> Vector2:
	return Vector2(
		(BOARD_BOUNDS.z - BOARD_BOUNDS.x) / (BOARD_SIZE.x - 1),
		(BOARD_BOUNDS.w - BOARD_BOUNDS.y) / (BOARD_SIZE.y - 1)
	)

func world_to_board_pos(pos: Vector2) -> Vector2i:
	var cell_size: Vector2 = get_cell_size()
	
	return Vector2(
		round((pos.x - BOARD_BOUNDS.x) / cell_size.x),
		round((pos.y - BOARD_BOUNDS.y) / cell_size.y)
	)

func board_to_world_pos(pos: Vector2i) -> Vector2:
	var cell_size: Vector2 = get_cell_size()
	
	return Vector2(
		pos.x * cell_size.x + BOARD_BOUNDS.x,
		pos.y * cell_size.y + BOARD_BOUNDS.y
	)

func next_turn():
	turn_black = !turn_black
	current_stone = new_stone(turn_black)
	state = State.POSITIONING

func new_stone(black: bool):
	var stone = STONE.instantiate()
	stone_container.add_child(stone)
	stone.set_texture(black)
	stone.position.x = X_BLACK if black else X_WHITE
	return stone

func stone_captured(pos: Vector2i) -> void:
	placed_stones[pos].queue_free()
