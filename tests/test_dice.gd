extends GutTest

func test_double_detected() -> void:
	var r := DiceLogic.make(3, 3)
	assert_true(r.is_double, "3+3 is a double")
	assert_eq(r.total, 6)

func test_non_double() -> void:
	var r := DiceLogic.make(2, 5)
	assert_false(r.is_double)
	assert_eq(r.total, 7)

func test_three_doubles_jail() -> void:
	assert_false(DiceLogic.should_go_to_jail(2))
	assert_true(DiceLogic.should_go_to_jail(3))

func test_roll_in_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in 50:
		var r := DiceLogic.roll(rng)
		assert_between(r.d1, 1, 6)
		assert_between(r.d2, 1, 6)
