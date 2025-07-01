class_name UI
extends Control

signal player_passed

const TURN_BLACK_ANIM := "turn_black"
const TURN_WHITE_ANIM := "turn_white"

var _turn_black: bool

@onready var banner_black: TextureRect = $BannerBlack
@onready var banner_white: TextureRect = $BannerWhite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# TODO: display number of stones captured

func set_turn(black: bool):
	_turn_black = black
	var anim = TURN_BLACK_ANIM if black else TURN_WHITE_ANIM
	animation_player.play(anim)


func _on_pass_button_black_pressed() -> void:
	if not _turn_black:
		return
	player_passed.emit()

func _on_pass_button_white_pressed() -> void:
	if _turn_black:
		return
	player_passed.emit()
