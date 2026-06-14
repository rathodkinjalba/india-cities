class_name ColorGroupData
extends Resource
## A street colour group (e.g. all "yellow" cities). Drives building + monopoly rent.

@export var id: StringName = &""
@export var display_color: Color = Color.WHITE
@export var house_cost: int = 0
@export var member_indices: Array[int] = []

static func from_dict(d: Dictionary) -> ColorGroupData:
	var g := ColorGroupData.new()
	g.id = StringName(d.get("id", ""))
	g.display_color = Color(String(d.get("color", "#ffffff")))
	g.house_cost = int(d.get("house_cost", 0))
	var mi: Array[int] = []
	if d.get("members", null) is Array:
		for v in d["members"]:
			mi.append(int(v))
	g.member_indices = mi
	return g
