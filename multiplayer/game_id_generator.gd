class_name GameIdGenerator

const ALPHABET: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# TODO: check for collisions
static func generate() -> String:
	if not GDSync.is_active():
		return ""
	
	var game_id = ""
	for _i in range(4):
		game_id += ALPHABET[randi_range(0, ALPHABET.length() - 1)]
	print(game_id)
	
	return game_id
