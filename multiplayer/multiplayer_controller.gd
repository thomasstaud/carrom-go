class_name MultiplayerController
extends Node

var _game: Game

func init(game: Game) -> void:
	_game = game
	GDSync.expose_node(self)

# TODO: update stone while positioning
# this can be done every second or so and smoothened out with tweens, i guess


func shooting_out(shooting_dir: Vector2, position: Vector2) -> void:
	GDSync.call_func(shooting_in, [shooting_dir, position])
func shooting_in(shooting_dir: Vector2, position: Vector2) -> void:
	_game.passing = false
	_game.current_stone.position = position
	_game.shooting_dir = shooting_dir
	_game.shot_valid = false
	_game.state = Game.State.SHOOTING


func snapping_out(board_pos: Vector2i) -> void:
	GDSync.call_func(snapping_in, [board_pos])
func snapping_in(board_pos: Vector2i) -> void:
	_game.snap_stone(board_pos)


func passing_out() -> void:
	GDSync.call_func(passing_in)
func passing_in() -> void:
	_game.player_passed()
