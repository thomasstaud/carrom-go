class_name MultiplayerPanel
extends Control

var _hosting: bool

@onready var connecting: TextureRect = $Texture/Connecting
@onready var friend_selection: VBoxContainer = $Texture/FriendSelection
@onready var waiting: VBoxContainer = $Texture/Waiting
@onready var join_line_edit: LineEdit = %JoinLineEdit
@onready var host_line_edit: LineEdit = %HostLineEdit


func _ready() -> void:
	ConnectionManager.connected.connect(_on_connected)

func random():
	show()
	_hosting = false
	_connect()

func friend():
	show()
	connecting.hide()
	friend_selection.show()
	waiting.hide()


func _connect():
	connecting.show()
	friend_selection.hide()
	waiting.hide()
	
	ConnectionManager.connect_to_server()

func _disconnect():
	connecting.hide()
	friend_selection.hide()
	waiting.hide()
	hide()
	
	ConnectionManager.disconnect_from_server()

func _on_connected():
	connecting.hide()
	friend_selection.hide()
	waiting.show()
	
	if _hosting:
		host_line_edit.show()
		host_line_edit.text = "HANS"
	else:
		host_line_edit.hide()


func _on_host_button_pressed() -> void:
	_hosting = true
	_connect()

func _on_join_button_pressed() -> void:
	var game_id = join_line_edit.text
	if game_id == "":
		return
	
	_hosting = false
	_connect()

func _on_cancel_button_pressed() -> void:
	_disconnect()
