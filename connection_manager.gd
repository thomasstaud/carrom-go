extends Node

func connect_to_server():
	GDSync.connected.connect(connected)
	GDSync.connection_failed.connect(connection_failed)
	GDSync.disconnected.connect(disconnected)
	
	GDSync.start_multiplayer()


func connected():
	print("connection successful!")

func connection_failed(error : int):
	match(error):
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			push_error("public or private key is invalid")
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			push_error("unable to connect")

func disconnected():
	print("disconnected from server.")
