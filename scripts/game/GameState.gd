class_name GameState
extends RefCounted
## Owns all mutable game data (players, ownership, turn pointer) and uses the pure
## rules modules. No scene-tree access here, so it can be unit-tested headlessly.

var board: BoardData
var chance: CardDeckData
var chest: CardDeckData
var players: Array[Player] = []
var props: Dictionary = {}          # space_index -> PropertyState (ownable spaces only)
var current_index: int = 0
var doubles_count: int = 0
var _chance_pos: int = 0
var _chest_pos: int = 0
var rng := RandomNumberGenerator.new()

func setup(num: int, names: Array, randomize_seed: bool = true) -> void:
	board = BoardData.load_from_json("res://data/board_india.json")
	chance = CardDeckData.load_from_json("res://data/deck_chance.json")
	chest = CardDeckData.load_from_json("res://data/deck_chest.json")
	if randomize_seed:
		rng.randomize()
	else:
		rng.seed = 1
	_shuffle(chance.cards)
	_shuffle(chest.cards)
	players.clear()
	for i in num:
		var nm: String = String(names[i]) if i < names.size() and String(names[i]) != "" else "Player %d" % (i + 1)
		var p := Player.new(i, nm, board.starting_cash)
		p.token_color = GameConfig.token_for_player(i).color
		players.append(p)
	props.clear()
	for s in board.spaces:
		if s.is_ownable():
			props[s.index] = PropertyState.new(s.index)

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

# --- accessors ----------------------------------------------------------------
func current_player() -> Player:
	return players[current_index]

func state_for(index: int) -> PropertyState:
	return props.get(index)

func owner_of(index: int) -> int:
	var ps: PropertyState = props.get(index)
	return ps.owner_id if ps != null else -1

func player_by_id(id: int) -> Player:
	for p in players:
		if p.id == id:
			return p
	return null

func active_players() -> Array:
	return players.filter(func(p: Player): return not p.bankrupt)

# --- ownership queries ---------------------------------------------------------
func count_owned_in_group(player_id: int, group: StringName) -> int:
	var c := 0
	for idx in board.group_member_indices(group):
		if owner_of(idx) == player_id:
			c += 1
	return c

func owns_full_group(player_id: int, group: StringName) -> bool:
	var members := board.group_member_indices(group)
	if members.is_empty():
		return false
	for idx in members:
		if owner_of(idx) != player_id:
			return false
	return true

func count_stations_owned(player_id: int) -> int:
	var c := 0
	for idx in board.station_indices():
		if owner_of(idx) == player_id:
			c += 1
	return c

func count_utilities_owned(player_id: int) -> int:
	var c := 0
	for idx in board.utility_indices():
		if owner_of(idx) == player_id:
			c += 1
	return c

func group_house_counts(group: StringName) -> Array[int]:
	var out: Array[int] = []
	for idx in board.group_member_indices(group):
		var ps: PropertyState = props.get(idx)
		out.append(ps.houses if ps != null else 0)
	return out

# --- money ---------------------------------------------------------------------
## Returns rent owed for landing on an ownable space (0 if own/unowned/mortgaged).
func rent_for(index: int, dice_total: int) -> int:
	var ps: PropertyState = props.get(index)
	if ps == null or not ps.is_owned():
		return 0
	var space := board.get_space(index)
	match space.type:
		SpaceData.Type.STREET:
			var full := owns_full_group(ps.owner_id, space.color_group)
			return RentCalculator.street_rent(space, ps.houses, full, ps.mortgaged)
		SpaceData.Type.STATION:
			return RentCalculator.station_rent(space, count_stations_owned(ps.owner_id), ps.mortgaged)
		SpaceData.Type.UTILITY:
			return RentCalculator.utility_rent(space, dice_total, count_utilities_owned(ps.owner_id), ps.mortgaged)
	return 0

func buy(player: Player, index: int) -> bool:
	var space := board.get_space(index)
	if space == null or not space.is_ownable():
		return false
	var ps: PropertyState = props.get(index)
	if ps == null or ps.is_owned() or player.cash < space.price:
		return false
	player.cash -= space.price
	ps.owner_id = player.id
	player.owned.append(index)
	return true

## Move cash from payer to payee (payee null = the bank). Returns the amount actually paid.
func transfer(payer: Player, payee: Player, amount: int) -> int:
	var paid: int = min(amount, payer.cash) if amount > payer.cash else amount
	payer.cash -= amount
	if payee != null:
		payee.cash += amount
	return paid

func can_afford(player: Player, amount: int) -> bool:
	# v1: liquidation via mortgage/sell is M4; for now compare raw cash.
	return player.cash >= amount

# --- turn flow -----------------------------------------------------------------
func advance_to_next_player() -> void:
	doubles_count = 0
	var n := players.size()
	for step in range(1, n + 1):
		var idx := (current_index + step) % n
		if not players[idx].bankrupt:
			current_index = idx
			return

func draw_chance() -> CardData:
	if chance.cards.is_empty():
		return null
	var c: CardData = chance.cards[_chance_pos % chance.cards.size()]
	_chance_pos += 1
	return c

func draw_chest() -> CardData:
	if chest.cards.is_empty():
		return null
	var c: CardData = chest.cards[_chest_pos % chest.cards.size()]
	_chest_pos += 1
	return c

func winner() -> Player:
	var alive := active_players()
	return alive[0] if alive.size() == 1 else null
