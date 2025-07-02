class_name UI
extends Control

signal player_passed

const TURN_BLACK_ANIM := "turn_black"
const TURN_WHITE_ANIM := "turn_white"

var _turn_black: bool

@onready var captured_black: Label = $CapturedBlack
@onready var captured_white: Label = $CapturedWhite
@onready var pass_button_black: TextureButton = $PassButtonBlack
@onready var pass_button_white: TextureButton = $PassButtonWhite
@onready var banner_black: TextureRect = $BannerBlack
@onready var banner_white: TextureRect = $BannerWhite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func init(player: Game.Player):
	if player == Game.Player.BLACK:
		pass_button_white.hide()
	if player == Game.Player.WHITE:
		pass_button_black.hide()

func set_turn(black: bool):
	_turn_black = black
	var anim = TURN_BLACK_ANIM if black else TURN_WHITE_ANIM
	animation_player.play(anim)

# captured must look like this: {1: captured black stones, 2: captured white stones}
func update_captures(captures: Dictionary[int, int]):
	captured_black.set_text("Captured:\n%d" % captures[2])
	captured_white.set_text("Captured:\n%d" % captures[1])


func _on_pass_button_black_pressed() -> void:
	if not _turn_black:
		return
	player_passed.emit()

func _on_pass_button_white_pressed() -> void:
	if _turn_black:
		return
	player_passed.emit()
