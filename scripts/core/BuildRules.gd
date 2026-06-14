class_name BuildRules
extends RefCounted
## Pure house/hotel building legality (the "even build" rule). No scene-tree access.

## Can a house/hotel be ADDED to the target property?
## - all_owned: the player owns every street in the colour group
## - any_mortgaged: any street in the group is mortgaged (blocks building)
## - target_houses: current building count on the target (0-4; 5 == already a hotel)
## - group_house_counts: building counts across the whole group
## Even-build: you may only build on a property tied for the FEWEST buildings in the group.
static func can_build(target_houses: int, group_house_counts: Array[int], all_owned: bool, any_mortgaged: bool) -> bool:
	if not all_owned or any_mortgaged:
		return false
	if target_houses >= 5:
		return false
	if group_house_counts.is_empty():
		return false
	var group_min: int = group_house_counts.min()
	return target_houses == group_min

## Can a house/hotel be SOLD from the target? Even-sell: only from a property tied for the MOST buildings.
static func can_sell(target_houses: int, group_house_counts: Array[int]) -> bool:
	if target_houses <= 0 or group_house_counts.is_empty():
		return false
	var group_max: int = group_house_counts.max()
	return target_houses == group_max

## Half the original house cost is refunded when selling a building back to the bank.
static func sell_refund(house_cost: int, count: int) -> int:
	return int(house_cost * count) / 2
