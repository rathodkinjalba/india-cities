class_name PropertyState
extends RefCounted
## Mutable per-space ownership/building state. Keyed by space_index in GameManager.

var space_index: int = 0
var owner_id: int = -1     # -1 == bank/unowned
var houses: int = 0        # 0-4 houses, 5 == hotel
var mortgaged: bool = false

func _init(p_index: int = 0) -> void:
	space_index = p_index

func is_owned() -> bool:
	return owner_id >= 0

func has_hotel() -> bool:
	return houses >= 5
