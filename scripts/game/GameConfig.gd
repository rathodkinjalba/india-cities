class_name GameConfig
extends RefCounted
## Holds setup choices passed from the menu/token-select screens into the game.

static var player_count: int = 4
static var player_names: Array[String] = []
static var player_tokens: Array[String] = []   # token id per player

## Themed tokens (stylized shapes built from primitives in Game.gd).
## Detailed 3D models come later with the landmark-art phase.
const TOKENS: Array[Dictionary] = [
	{ "id": "rickshaw", "name": "Rickshaw",     "color": Color("#F4C20D") },
	{ "id": "ball",     "name": "Cricket Ball", "color": Color("#E0231F") },
	{ "id": "kite",     "name": "Kite",         "color": Color("#D81B8C") },
	{ "id": "dhol",     "name": "Dhol",         "color": Color("#B5651D") },
	{ "id": "temple",   "name": "Temple",       "color": Color("#F08020") },
	{ "id": "top",      "name": "Spinning Top", "color": Color("#1FA055") },
	{ "id": "lamp",     "name": "Diya",         "color": Color("#FFD24D") },
	{ "id": "drum",     "name": "Tabla",        "color": Color("#7A4BC9") },
]

static func token_by_id(id: String) -> Dictionary:
	for t in TOKENS:
		if t.id == id:
			return t
	return TOKENS[0]

static func token_for_player(i: int) -> Dictionary:
	if i < player_tokens.size():
		return token_by_id(player_tokens[i])
	return TOKENS[i % TOKENS.size()]
