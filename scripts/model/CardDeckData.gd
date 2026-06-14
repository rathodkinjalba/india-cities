class_name CardDeckData
extends Resource
## An ordered deck of cards, loaded from JSON.

@export var id: StringName = &""
@export var cards: Array[CardData] = []

static func load_from_json(path: String) -> CardDeckData:
	if not FileAccess.file_exists(path):
		push_error("Deck JSON not found: %s" % path)
		return CardDeckData.new()
	var txt := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Deck JSON malformed: %s" % path)
		return CardDeckData.new()
	return from_dict(data)

static func from_dict(d: Dictionary) -> CardDeckData:
	var deck := CardDeckData.new()
	deck.id = StringName(d.get("id", ""))
	if d.get("cards", null) is Array:
		for cd in d["cards"]:
			deck.cards.append(CardData.from_dict(cd))
	return deck
