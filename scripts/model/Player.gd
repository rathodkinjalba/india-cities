class_name Player
extends RefCounted
## Runtime state for one player (pass-and-play). Not a Resource — created per game.

var id: int = 0
var name: String = ""
var cash: int = 1500
var position: int = 0
var in_jail: bool = false
var jail_turns: int = 0
var get_out_cards: int = 0
var owned: Array[int] = []   # space indices this player owns
var bankrupt: bool = false
var token_color: Color = Color.WHITE

func _init(p_id: int = 0, p_name: String = "", p_cash: int = 1500) -> void:
	id = p_id
	name = p_name
	cash = p_cash
