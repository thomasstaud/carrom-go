extends Node

const GAME = preload("res://game/game.tscn")

var _game: Game

@onready var menu: Control = $Menu


func _on_menu_start_game(player) -> void:
	menu.hide()
	_game = GAME.instantiate()
	_game.end_game.connect(_on_end_game)
	add_child(_game)
	_game.init(player)


func _on_end_game() -> void:
	_game.queue_free()
	menu.show()
