class_name RentCalculator
extends RefCounted
## Pure rent math for streets, stations and utilities. No scene-tree access.

## Street rent. houses 0-5 (5 == hotel). A full unmortgaged monopoly with 0 houses pays double base.
static func street_rent(space: SpaceData, houses: int, owns_full_group: bool, mortgaged: bool) -> int:
	if mortgaged or space.rent_table.is_empty():
		return 0
	if houses <= 0:
		var base: int = space.rent_table[0]
		return base * 2 if owns_full_group else base
	var idx: int = clampi(houses, 1, space.rent_table.size() - 1)
	return space.rent_table[idx]

## Station rent scales with how many stations the owner holds.
static func station_rent(space: SpaceData, count_owned: int, mortgaged: bool) -> int:
	if mortgaged or space.station_rent.is_empty():
		return 0
	var c: int = clampi(count_owned, 1, space.station_rent.size())
	return space.station_rent[c - 1]

## Utility rent = dice total * multiplier (depends on how many utilities the owner holds).
static func utility_rent(space: SpaceData, dice_total: int, count_owned: int, mortgaged: bool) -> int:
	if mortgaged or space.utility_multiplier.is_empty():
		return 0
	var mult: int = space.utility_multiplier[0]
	if count_owned >= 2 and space.utility_multiplier.size() >= 2:
		mult = space.utility_multiplier[1]
	return dice_total * mult
