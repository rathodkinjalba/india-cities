class_name DiceLogic
extends RefCounted
## Pure dice helpers. Roll takes an injected RNG so tests stay deterministic.

static func roll(rng: RandomNumberGenerator) -> Dictionary:
	return make(rng.randi_range(1, 6), rng.randi_range(1, 6))

static func make(d1: int, d2: int) -> Dictionary:
	return {
		"d1": d1,
		"d2": d2,
		"total": d1 + d2,
		"is_double": d1 == d2,
	}

## Three doubles in a row sends a player to jail.
static func should_go_to_jail(consecutive_doubles: int) -> bool:
	return consecutive_doubles >= 3
