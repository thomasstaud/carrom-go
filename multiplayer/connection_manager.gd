extends Node

signal connected
signal hosted
signal game_ready

var _game_started: bool


func _ready() -> void:
	GDSync.connected.connect(_connected)
	GDSync.connection_failed.connect(_connection_failed)
	GDSync.disconnected.connect(_disconnected)
	
	GDSync.lobby_created.connect(_lobby_created)
	GDSync.lobby_creation_failed.connect(_lobby_creation_failed)
	
	GDSync.lobby_joined.connect(_lobby_joined)
	GDSync.lobby_join_failed.connect(_lobby_join_failed)
	
	GDSync.lobbies_received.connect(_lobbies_received)
	
	GDSync.client_joined.connect(_client_joined)


func connect_to_server() -> void:
	GDSync.start_multiplayer()

func disconnect_from_server() -> void:
	GDSync.stop_multiplayer()

func host_game(public: bool = false) -> void:
	var game_id = GameIdGenerator.generate()
	GDSync.lobby_create(game_id, "", public)

func join_game(game_id: String) -> void:
	# if there is a game id, join that game
	if game_id != "":
		_game_started = false
		GDSync.lobby_join(game_id)
		return
	
	# otherwise, try to join random game
	GDSync.get_public_lobbies()


func _connected():
	print("connected to server")
	connected.emit()

func _connection_failed(error: int):
	# TODO: tell this to the panel
	match(error):
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			push_error("public or private key is invalid")
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			push_error("unable to connect")

func _disconnected():
	print("disconnected from server.")

func _lobby_created(game_id: String):
	print("created game %s" % game_id)
	hosted.emit(game_id)
	join_game(game_id)

func _lobby_creation_failed(game_id: String, error: int):
	# TODO: tell this to the panel
	match(error):
		ENUMS.LOBBY_CREATION_ERROR.LOBBY_ALREADY_EXISTS:
			push_error("duplicate game id %s" % game_id)
		ENUMS.LOBBY_CREATION_ERROR.NAME_TOO_SHORT:
			push_error("invalid game id %s: too short" % game_id)
		ENUMS.LOBBY_CREATION_ERROR.NAME_TOO_LONG:
			push_error("invalid game id %s: too long" % game_id)
		ENUMS.LOBBY_CREATION_ERROR.ON_COOLDOWN:
			push_error("too many lobby requests")

func _lobby_joined(game_id: String):
	print("joined game %s" % game_id)

func _lobby_join_failed(game_id: String, error : int):
	# TODO: tell this to the panel
	match(error):
		ENUMS.LOBBY_JOIN_ERROR.LOBBY_DOES_NOT_EXIST:
			push_error("invalid game id %s" % game_id)
		ENUMS.LOBBY_JOIN_ERROR.DUPLICATE_USERNAME:
			push_error("duplicate username")
		_:
			push_error("error while joining game %s" % game_id)

func _lobbies_received(lobbies: Array):
	print("retrieved public lobby list")
	print(lobbies)
	# if there are no open games, host a new one
	var open_lobbies = lobbies.filter(func(lobby): return lobby["Open"])
	if open_lobbies.is_empty():
		host_game(true)
	else:
		join_game(lobbies[0]["Name"])

func _client_joined(_client_id : int):
	if _game_started:
		return
	
	print("game has %d players" % GDSync.lobby_get_player_count())
	if GDSync.lobby_get_player_count() == 2:
		print("closing lobby, game can begin")
		GDSync.lobby_close()
		game_ready.emit()
		_game_started = true
