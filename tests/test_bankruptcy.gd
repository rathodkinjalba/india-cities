extends GutTest

func _board() -> BoardData:
	var b := BoardData.new()
	var dummy := SpaceData.new()  # index 0 placeholder
	var s := SpaceData.new()
	s.index = 1
	s.mortgage_value = 100
	s.house_cost = 50
	b.spaces = [dummy, s]
	return b

func test_liquidation_value() -> void:
	var b := _board()
	var ps := PropertyState.new(1)
	ps.owner_id = 0
	ps.houses = 2
	# cash 50 + mortgage 100 + (50*2)/2 refund 50 = 200
	assert_eq(BankruptcyResolver.liquidation_value(50, [ps], b), 200)

func test_mortgaged_property_not_counted() -> void:
	var b := _board()
	var ps := PropertyState.new(1)
	ps.owner_id = 0
	ps.mortgaged = true
	# cash 50 + nothing (already mortgaged, no houses) = 50
	assert_eq(BankruptcyResolver.liquidation_value(50, [ps], b), 50)

func test_can_cover() -> void:
	var b := _board()
	var ps := PropertyState.new(1)
	ps.owner_id = 0
	assert_true(BankruptcyResolver.can_cover(50, [ps], b, 150))   # 50+100 = 150
	assert_false(BankruptcyResolver.can_cover(50, [ps], b, 151))
