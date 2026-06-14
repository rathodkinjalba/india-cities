class_name MortgageRules
extends RefCounted
## Pure mortgage legality + values. No scene-tree access.

## A property can be mortgaged only if it's owned, not already mortgaged, has no buildings,
## and no other property in its group has buildings.
static func can_mortgage(state: PropertyState, group_has_buildings: bool) -> bool:
	return state.is_owned() and not state.mortgaged and state.houses == 0 and not group_has_buildings

static func can_unmortgage(state: PropertyState) -> bool:
	return state.is_owned() and state.mortgaged

## Cash received when mortgaging.
static func mortgage_payout(space: SpaceData) -> int:
	return space.mortgage_value

## Cost to lift a mortgage = mortgage value + 10% interest (rounded up).
## Integer math avoids float error (e.g. 100 * 1.1 == 110.00000001 -> would ceil to 111).
static func unmortgage_cost(space: SpaceData) -> int:
	return space.mortgage_value + int(ceil(space.mortgage_value / 10.0))
