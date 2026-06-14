class_name CardData
extends Resource
## A single Chance / Community-Chest card.

enum Effect { MOVE_TO, MOVE_REL, COLLECT, PAY, GOTO_JAIL, GET_OUT_OF_JAIL_FREE, REPAIRS }

@export var id: StringName = &""
@export var text: String = ""
@export var effect: Effect = Effect.COLLECT
@export var amount: int = 0
@export var target_index: int = -1
@export var per_house: int = 0
@export var per_hotel: int = 0

static func from_dict(d: Dictionary) -> CardData:
	var c := CardData.new()
	c.id = StringName(d.get("id", ""))
	c.text = String(d.get("text", ""))
	c.effect = _parse_effect(String(d.get("effect", "COLLECT")))
	c.amount = int(d.get("amount", 0))
	c.target_index = int(d.get("target_index", -1))
	c.per_house = int(d.get("per_house", 0))
	c.per_hotel = int(d.get("per_hotel", 0))
	return c

static func _parse_effect(e: String) -> Effect:
	match e:
		"MOVE_TO": return Effect.MOVE_TO
		"MOVE_REL": return Effect.MOVE_REL
		"COLLECT": return Effect.COLLECT
		"PAY": return Effect.PAY
		"GOTO_JAIL": return Effect.GOTO_JAIL
		"GET_OUT_OF_JAIL_FREE": return Effect.GET_OUT_OF_JAIL_FREE
		"REPAIRS": return Effect.REPAIRS
	return Effect.COLLECT
