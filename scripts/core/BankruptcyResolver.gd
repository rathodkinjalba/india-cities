class_name BankruptcyResolver
extends RefCounted
## Pure liquidation math: the max cash a player could raise before declaring bankruptcy.

## cash + mortgage value of each unmortgaged property + half-cost refund of every building.
static func liquidation_value(cash: int, props: Array, board: BoardData) -> int:
	var total: int = cash
	for ps in props:
		var space: SpaceData = board.get_space(ps.space_index)
		if space == null:
			continue
		if not ps.mortgaged:
			total += space.mortgage_value
		if ps.houses > 0:
			total += BuildRules.sell_refund(space.house_cost, ps.houses)
	return total

static func can_cover(cash: int, props: Array, board: BoardData, amount_due: int) -> bool:
	return liquidation_value(cash, props, board) >= amount_due
