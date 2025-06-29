extends Node2D

const TEXTURE_BLACK = preload("res://stone_black.png")
const TEXTURE_WHITE = preload("res://stone_white.png")

@onready var sprite_2d: Sprite2D = $Sprite2D

func set_texture(black: bool):
	sprite_2d.texture = TEXTURE_BLACK if black else TEXTURE_WHITE
