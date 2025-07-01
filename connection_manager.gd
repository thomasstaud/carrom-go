extends Node

signal connected


func _ready() -> void:
	GDSync.connected.connect(_connected)
	GDSync.connection_failed.connect(_connection_failed)
	GDSync.disconnected.connect(_disconnected)

func connect_to_server() -> void:
	GDSync.start_multiplayer()

func disconnect_from_server() -> void:
	GDSync.stop_multiplayer()


func _connected():
	print("connected to server")
	connected.emit()

func _connection_failed(error : int):
	match(error):
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			push_error("public or private key is invalid")
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			push_error("unable to connect")

func _disconnected():
	print("disconnected from server.")
