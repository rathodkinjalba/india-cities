class_name BoardData
extends Resource
## The whole board: 40 ordered spaces + colour groups + economy constants.
## Loaded from data/board_classic.json so the theme is pure data.

@export var spaces: Array[SpaceData] = []
@export var color_groups: Array[ColorGroupData] = []
@export var go_salary: int = 200
@export var starting_cash: int = 1500
@export var jail_index: int = 10
@export var goto_jail_index: int = 30
@export var jail_fine: int = 50

static func load_from_json(path: String) -> BoardData:
	if not FileAccess.file_exists(path):
		push_error("Board JSON not found: %s" % path)
		return BoardData.new()
	var txt := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Board JSON malformed: %s" % path)
		return BoardData.new()
	return from_dict(data)

static func from_dict(d: Dictionary) -> BoardData:
	var b := BoardData.new()
	b.go_salary = int(d.get("go_salary", 200))
	b.starting_cash = int(d.get("starting_cash", 1500))
	b.jail_index = int(d.get("jail_index", 10))
	b.goto_jail_index = int(d.get("goto_jail_index", 30))
	b.jail_fine = int(d.get("jail_fine", 50))
	if d.get("spaces", null) is Array:
		for sd in d["spaces"]:
			b.spaces.append(SpaceData.from_dict(sd))
	if d.get("color_groups", null) is Array:
		for gd in d["color_groups"]:
			b.color_groups.append(ColorGroupData.from_dict(gd))
	return b

func get_space(i: int) -> SpaceData:
	if i >= 0 and i < spaces.size():
		return spaces[i]
	return null

func get_group(id: StringName) -> ColorGroupData:
	for g in color_groups:
		if g.id == id:
			return g
	return null

## All street indices belonging to a colour group (computed from spaces).
func group_member_indices(group: StringName) -> Array[int]:
	var out: Array[int] = []
	for s in spaces:
		if s.type == SpaceData.Type.STREET and s.color_group == group:
			out.append(s.index)
	return out

func station_indices() -> Array[int]:
	var out: Array[int] = []
	for s in spaces:
		if s.type == SpaceData.Type.STATION:
			out.append(s.index)
	return out

func utility_indices() -> Array[int]:
	var out: Array[int] = []
	for s in spaces:
		if s.type == SpaceData.Type.UTILITY:
			out.append(s.index)
	return out
