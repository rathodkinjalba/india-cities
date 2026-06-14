extends Control
## Start menu: pick number of players (2-6) via big buttons, then launch.

var _count := 4
var _count_buttons: Array[Button] = []

func _ready() -> void:
	theme = UITheme.get_theme()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("#0d1322")
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 28)
	center.add_child(v)

	var title := Label.new()
	title.text = "MONOPOLY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", Color("#f0a020"))
	v.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "India Edition"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 40)
	subtitle.add_theme_color_override("font_color", Color("#cfd8dc"))
	v.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	v.add_child(spacer)

	var pick := Label.new()
	pick.text = "NUMBER OF PLAYERS"
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick.add_theme_font_size_override("font_size", 40)
	v.add_child(pick)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	v.add_child(row)
	_count_buttons.clear()
	for n in range(2, 7):
		var b := Button.new()
		b.text = str(n)
		b.add_theme_font_size_override("font_size", 56)
		b.custom_minimum_size = Vector2(110, 110)
		b.pressed.connect(_on_count_pressed.bind(n))
		row.add_child(b)
		_count_buttons.append(b)
	_refresh_counts()

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	v.add_child(spacer2)

	var start := Button.new()
	start.text = "START GAME"
	start.add_theme_font_size_override("font_size", 60)
	start.custom_minimum_size = Vector2(620, 140)
	UITheme.style_primary(start)
	start.pressed.connect(func() -> void: Sfx.play("confirm"))
	start.pressed.connect(_on_start)
	v.add_child(start)

func _on_count_pressed(n: int) -> void:
	Sfx.play("click")
	_count = n
	_refresh_counts()

func _refresh_counts() -> void:
	for b in _count_buttons:
		if int(b.text) == _count:
			UITheme.style_primary(b)
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")
			b.remove_theme_stylebox_override("pressed")

func _on_start() -> void:
	GameConfig.player_count = _count
	GameConfig.player_names = []
	GameConfig.player_tokens = []
	get_tree().change_scene_to_file("res://scenes/TokenSelect.tscn")
