extends Control

signal start_game

@onready var multiplayer_panel: MultiplayerPanel = $MultiplayerPanel


func _on_hotseat_button_pressed() -> void:
	start_game.emit()


func _on_random_button_pressed() -> void:
	multiplayer_panel.random()


func _on_friend_button_pressed() -> void:
	multiplayer_panel.friend()
