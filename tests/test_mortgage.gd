extends GutTest

func _space() -> SpaceData:
	var s := SpaceData.new()
	s.mortgage_value = 100
	s.house_cost = 50
	return s

func _owned_state() -> PropertyState:
	var ps := PropertyState.new(1)
	ps.owner_id = 0
	return ps

func test_unmortgage_cost_has_interest() -> void:
	assert_eq(MortgageRules.unmortgage_cost(_space()), 110)

func test_mortgage_payout() -> void:
	assert_eq(MortgageRules.mortgage_payout(_space()), 100)

func test_can_mortgage_clean_property() -> void:
	assert_true(MortgageRules.can_mortgage(_owned_state(), false))

func test_cannot_mortgage_with_houses() -> void:
	var ps := _owned_state()
	ps.houses = 1
	assert_false(MortgageRules.can_mortgage(ps, false))

func test_cannot_mortgage_when_group_has_buildings() -> void:
	assert_false(MortgageRules.can_mortgage(_owned_state(), true))

func test_unmortgage_requires_mortgaged() -> void:
	var ps := _owned_state()
	assert_false(MortgageRules.can_unmortgage(ps))
	ps.mortgaged = true
	assert_true(MortgageRules.can_unmortgage(ps))
