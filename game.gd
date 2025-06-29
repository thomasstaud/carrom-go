extends Node2D

enum State {
	POSITIONING,
	AIMING,
	SHOOTING,
}

const STONE = preload("res://stone.tscn")
const STONE_DIAMETER: float = 55.0
const SHOOT_SPEED: float = 0.1
const MIN_SHOOT_SPEED: float = 0.25
# 1.0 is no friction, 0.0 is no movement
const SLICKNESS: float = 0.99
# 1.0 is full bounce, 0.0 is no bounce
const BOUNCINESS: float = 0.6
# higher value means worse performance but better collisions
const COLLISION_PRECISION: float = 2.0
# placement bounds
const X_BLACK: int = 261
const X_WHITE: int = 901
const Y_MIN: int = 63
const Y_MAX: int = 575
# shooting bounds
const SCREEN_BOUNDS := Vector4(-50, -50, 1200, 700)
const BOARD_BOUNDS := Vector4(326, 64, 836, 574)


var state: State
var turn_black := false
var current_stone: Node2D
var placed_stones: Array[Node2D] = []
var shooting_dir: Vector2
var shot_valid: bool

@onready var stone_container: Node2D = $StoneContainer


func _ready() -> void:
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
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shoot()

func shooting():
	shooting_dir *= SLICKNESS
	
	# too slow
	if shooting_dir.length() < MIN_SHOOT_SPEED:
		if shot_valid:
			# TODO: snap stone to grid
			placed_stones.append(current_stone)
		else:
			current_stone.queue_free()
		next_turn()
		return
	
	var movement: Vector2 = shooting_dir * SHOOT_SPEED
	var increments: int = ceil(movement.length() * COLLISION_PRECISION)
	
	for i in range(increments):
		current_stone.position += movement / increments
		
		# collide with other stones
		for stone in placed_stones:
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


func in_bounds(pos: Vector2, bounds: Vector4):
	return pos.x >= bounds.x \
		and pos.x <= bounds.z \
		and pos.y >= bounds.y \
		and pos.y <= bounds.w

func shoot():
	shooting_dir = get_viewport().get_mouse_position() - current_stone.position
	shot_valid = false
	state = State.SHOOTING

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
