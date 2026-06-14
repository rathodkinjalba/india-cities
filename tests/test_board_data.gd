extends GutTest
## Verifies the Indian-cities board JSON loads into a complete, well-formed 40-space board.

var board: BoardData

func before_all() -> void:
	board = BoardData.load_from_json("res://data/board_classic.json")

func test_has_40_spaces() -> void:
	assert_eq(board.spaces.size(), 40, "board must have exactly 40 spaces")

func test_classic_names_and_economy() -> void:
	assert_eq(board.get_space(39).display_name, "Mayfair")
	assert_eq(board.get_space(37).display_name, "Park Lane")
	assert_eq(board.get_space(1).display_name, "Old Kent Road")
	assert_eq(board.go_salary, 2000)
	assert_eq(board.starting_cash, 15000)
	assert_eq(board.jail_fine, 500)

func test_indices_are_sequential() -> void:
	for i in board.spaces.size():
		assert_eq(board.spaces[i].index, i, "space %d index mismatch" % i)

func test_corners() -> void:
	assert_eq(board.get_space(0).type, SpaceData.Type.GO)
	assert_eq(board.get_space(10).type, SpaceData.Type.JAIL)
	assert_eq(board.get_space(20).type, SpaceData.Type.FREE_PARKING)
	assert_eq(board.get_space(30).type, SpaceData.Type.GOTO_JAIL)

func test_eight_color_groups() -> void:
	assert_eq(board.color_groups.size(), 8)

func test_each_street_belongs_to_a_known_group() -> void:
	for s in board.spaces:
		if s.type == SpaceData.Type.STREET:
			assert_not_null(board.get_group(s.color_group), "%s has unknown group" % s.display_name)

func test_group_membership_matches_streets() -> void:
	# darkblue has exactly New Delhi (37) and Mumbai (39)
	var members := board.group_member_indices(&"darkblue")
	assert_eq(members, [37, 39])

func test_four_stations_two_utilities() -> void:
	assert_eq(board.station_indices().size(), 4)
	assert_eq(board.utility_indices().size(), 2)

func test_decks_load() -> void:
	var chance := CardDeckData.load_from_json("res://data/deck_chance.json")
	var chest := CardDeckData.load_from_json("res://data/deck_chest.json")
	assert_gt(chance.cards.size(), 0, "chance deck not empty")
	assert_gt(chest.cards.size(), 0, "chest deck not empty")
