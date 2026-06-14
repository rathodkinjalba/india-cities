extends GutTest

func _street() -> SpaceData:
	var s := SpaceData.new()
	s.type = SpaceData.Type.STREET
	s.rent_table = [2, 10, 30, 90, 160, 250]
	return s

func test_base_rent() -> void:
	assert_eq(RentCalculator.street_rent(_street(), 0, false, false), 2)

func test_full_group_doubles_base() -> void:
	assert_eq(RentCalculator.street_rent(_street(), 0, true, false), 4)

func test_rent_with_three_houses() -> void:
	assert_eq(RentCalculator.street_rent(_street(), 3, false, false), 90)

func test_hotel_rent() -> void:
	assert_eq(RentCalculator.street_rent(_street(), 5, false, false), 250)

func test_mortgaged_pays_nothing() -> void:
	assert_eq(RentCalculator.street_rent(_street(), 3, false, true), 0)

func test_station_rent_scales() -> void:
	var s := SpaceData.new()
	s.station_rent = [25, 50, 100, 200]
	assert_eq(RentCalculator.station_rent(s, 1, false), 25)
	assert_eq(RentCalculator.station_rent(s, 4, false), 200)

func test_utility_rent() -> void:
	var s := SpaceData.new()
	s.utility_multiplier = [4, 10]
	assert_eq(RentCalculator.utility_rent(s, 8, 1, false), 32)
	assert_eq(RentCalculator.utility_rent(s, 8, 2, false), 80)
