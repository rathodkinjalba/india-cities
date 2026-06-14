extends GutTest

func test_even_build_allowed_on_minimum() -> void:
	assert_true(BuildRules.can_build(0, [0, 0, 0], true, false))

func test_even_build_blocked_above_minimum() -> void:
	# target already has 1, group min is 0 -> must build the 0 first
	assert_false(BuildRules.can_build(1, [0, 1, 1], true, false))

func test_blocked_when_not_full_group() -> void:
	assert_false(BuildRules.can_build(0, [0, 0], false, false))

func test_blocked_when_mortgaged() -> void:
	assert_false(BuildRules.can_build(0, [0, 0], true, true))

func test_hotel_is_cap() -> void:
	assert_false(BuildRules.can_build(5, [5, 5], true, false))

func test_even_sell_from_maximum() -> void:
	assert_true(BuildRules.can_sell(3, [3, 2, 2]))
	assert_false(BuildRules.can_sell(2, [3, 2, 2]))

func test_sell_refund_is_half() -> void:
	assert_eq(BuildRules.sell_refund(100, 2), 100)
