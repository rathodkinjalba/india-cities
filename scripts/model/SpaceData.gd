class_name SpaceData
extends Resource
## One board space. Theme (names/prices) lives in data/board_classic.json — this is just the shape.

enum Type { GO, STREET, STATION, UTILITY, CHANCE, CHEST, TAX, JAIL, FREE_PARKING, GOTO_JAIL }

@export var index: int = 0
@export var type: Type = Type.STREET
@export var display_name: String = ""
@export var color_group: StringName = &""
@export var price: int = 0
@export var rent_table: Array[int] = []        # [base, 1house, 2, 3, 4, hotel]
@export var house_cost: int = 0
@export var mortgage_value: int = 0
@export var tax_amount: int = 0
@export var station_rent: Array[int] = []       # [1,2,3,4 stations owned]
@export var utility_multiplier: Array[int] = [] # [1 owned, 2 owned]

static func from_dict(d: Dictionary) -> SpaceData:
	var s := SpaceData.new()
	s.index = int(d.get("index", 0))
	s.type = _parse_type(String(d.get("type", "STREET")))
	s.display_name = String(d.get("name", ""))
	s.color_group = StringName(d.get("color_group", ""))
	s.price = int(d.get("price", 0))
	s.house_cost = int(d.get("house_cost", 0))
	s.mortgage_value = int(d.get("mortgage", 0))
	s.tax_amount = int(d.get("tax_amount", 0))
	s.rent_table = _to_int_array(d.get("rent", []))
	s.station_rent = _to_int_array(d.get("station_rent", []))
	s.utility_multiplier = _to_int_array(d.get("utility_multiplier", []))
	return s

static func _parse_type(t: String) -> Type:
	match t:
		"GO": return Type.GO
		"STREET": return Type.STREET
		"STATION": return Type.STATION
		"UTILITY": return Type.UTILITY
		"CHANCE": return Type.CHANCE
		"CHEST": return Type.CHEST
		"TAX": return Type.TAX
		"JAIL": return Type.JAIL
		"FREE_PARKING": return Type.FREE_PARKING
		"GOTO_JAIL": return Type.GOTO_JAIL
	return Type.STREET

static func _to_int_array(a) -> Array[int]:
	var out: Array[int] = []
	if a is Array:
		for v in a:
			out.append(int(v))
	return out

func is_ownable() -> bool:
	return type == Type.STREET or type == Type.STATION or type == Type.UTILITY
