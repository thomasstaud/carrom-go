extends Node2D

enum State {
	POSITIONING,
	AIMING,
	SHOOTING,
}

const STONE = preload("res://stone.tscn")
const SHOOT_SPEED: float = 0.1
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
	# TODO: collide with borders and stones
	
	if shot_valid and not in_bounds(current_stone.position, BOARD_BOUNDS):
		next_turn()
		return
	
	if not shot_valid:
		if in_bounds(current_stone.position, BOARD_BOUNDS):
			shot_valid = true
		if not in_bounds(current_stone.position, SCREEN_BOUNDS):
			next_turn()
			return
	
	current_stone.position += shooting_dir * SHOOT_SPEED


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
