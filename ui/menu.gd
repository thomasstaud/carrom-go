extends Control

signal start_game

@onready var multiplayer_panel: MultiplayerPanel = $MultiplayerPanel


func _ready() -> void:
	multiplayer_panel.start_game.connect(_on_multiplayer_game)


func _on_hotseat_button_pressed() -> void:
	start_game.emit(Game.Player.HOTSEAT)

func _on_random_button_pressed() -> void:
	multiplayer_panel.random()

func _on_friend_button_pressed() -> void:
	multiplayer_panel.friend()

func _on_multiplayer_game(player) -> void:
	start_game.emit(player)
