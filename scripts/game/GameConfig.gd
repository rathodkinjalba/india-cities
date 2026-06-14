class_name GameConfig
extends RefCounted
## Tiny holder to pass setup choices from the menu into the game scene.

static var player_count: int = 4
static var player_names: Array[String] = []

const TOKEN_COLORS: Array[Color] = [
	Color("#E0231F"), # red
	Color("#1F6FE0"), # blue
	Color("#1FA055"), # green
	Color("#F4C20D"), # yellow
	Color("#9B30E0"), # purple
	Color("#F08020"), # orange
]
