extends Control
## Start menu: pick number of players (2-6), then launch the game.

var _count := 4

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
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)

	var title := Label.new()
	title.text = "MONOPOLY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("#f0a020"))
	v.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "India Edition · 2-6 players"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 26)
	subtitle.add_theme_color_override("font_color", Color("#cfd8dc"))
	v.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	v.add_child(spacer)

	var pick := Label.new()
	pick.text = "Number of players"
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick.add_theme_font_size_override("font_size", 28)
	v.add_child(pick)

	var opt := OptionButton.new()
	opt.add_theme_font_size_override("font_size", 28)
	for n in range(2, 7):
		opt.add_item("%d players" % n)
	opt.select(2) # default = 4 players
	opt.item_selected.connect(func(idx: int) -> void: _count = idx + 2)
	v.add_child(opt)

	var start := Button.new()
	start.text = "Start Game"
	start.add_theme_font_size_override("font_size", 32)
	start.custom_minimum_size = Vector2(260, 70)
	start.pressed.connect(func() -> void: Sfx.play("confirm"))
	start.pressed.connect(_on_start)
	v.add_child(start)

func _on_start() -> void:
	GameConfig.player_count = _count
	GameConfig.player_names = []
	GameConfig.player_tokens = []
	get_tree().change_scene_to_file("res://scenes/TokenSelect.tscn")
