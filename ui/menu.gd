extends Control

signal start_game

@onready var panel: Control = $Panel


func _on_hotseat_button_pressed() -> void:
	start_game.emit()


func _on_random_button_pressed() -> void:
	ConnectionManager.connect_to_server()
	panel.show()


func _on_friend_button_pressed() -> void:
	ConnectionManager.connect_to_server()
	panel.show()
