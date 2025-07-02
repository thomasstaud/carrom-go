class_name MultiplayerPanel
extends Control

signal start_game

var _hosting: bool
var _join_id: String

@onready var connecting: TextureRect = $Texture/Connecting
@onready var friend_selection: VBoxContainer = $Texture/FriendSelection
@onready var waiting: VBoxContainer = $Texture/Waiting
@onready var join_line_edit: LineEdit = %JoinLineEdit
@onready var host_line_edit: LineEdit = %HostLineEdit


func _ready() -> void:
	ConnectionManager.connected.connect(_on_connected)
	ConnectionManager.hosted.connect(_on_hosted)
	ConnectionManager.game_ready.connect(_on_game_ready)

func random():
	show()
	_hosting = false
	_join_id = ""
	_connect()

func friend():
	show()
	connecting.hide()
	friend_selection.show()
	waiting.hide()
	
	join_line_edit.text = ""


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
	
	host_line_edit.hide()
	if _hosting:
		ConnectionManager.host_game()
	else:
		ConnectionManager.join_game(_join_id)

func _on_hosted(game_id):
	host_line_edit.show()
	host_line_edit.text = game_id

func _on_game_ready():
	hide()
	start_game.emit()


func _on_host_button_pressed() -> void:
	_hosting = true
	_connect()

func _on_join_button_pressed() -> void:
	_join_id = join_line_edit.text.to_upper()
	if _join_id == "":
		return
	
	_hosting = false
	_connect()

func _on_cancel_button_pressed() -> void:
	_disconnect()
