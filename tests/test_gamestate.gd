extends GutTest
## Verifies the game-state core: setup, buying, ownership, rent, turn rotation, win.

var gs: GameState

func before_each() -> void:
	gs = GameState.new()
	gs.setup(4, [], false) # deterministic seed

func test_player_count_and_cash() -> void:
	assert_eq(gs.players.size(), 4)
	assert_eq(gs.players[0].cash, 1500)

func test_ownable_space_count() -> void:
	# 22 streets + 4 stations + 2 utilities
	assert_eq(gs.props.size(), 28)

func test_buy_property() -> void:
	var p := gs.players[0]
	assert_true(gs.buy(p, 1))        # Patna, ₹60
	assert_eq(p.cash, 1440)
	assert_eq(gs.owner_of(1), 0)
	assert_false(gs.buy(p, 1))       # already owned

func test_full_group_detection() -> void:
	var p := gs.players[0]
	gs.buy(p, 1)
	gs.buy(p, 3)
	assert_true(gs.owns_full_group(0, &"brown"))

func test_rent_single_vs_monopoly() -> void:
	var p := gs.players[0]
	gs.buy(p, 1)                     # only one brown -> base rent 2
	assert_eq(gs.rent_for(1, 7), 2)
	gs.buy(p, 3)                     # full brown group -> base doubled
	assert_eq(gs.rent_for(1, 7), 4)

func test_station_rent_by_count() -> void:
	var p := gs.players[0]
	gs.buy(p, 5)                     # one station
	assert_eq(gs.rent_for(5, 7), 25)
	gs.buy(p, 15)                    # two stations
	assert_eq(gs.rent_for(5, 7), 50)

func test_advance_skips_bankrupt() -> void:
	gs.current_index = 0
	gs.players[1].bankrupt = true
	gs.advance_to_next_player()
	assert_eq(gs.current_index, 2)

func test_winner_when_one_left() -> void:
	for i in range(1, 4):
		gs.players[i].bankrupt = true
	assert_eq(gs.winner(), gs.players[0])
