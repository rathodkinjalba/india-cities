extends Control
## Pre-game screen: each player enters a name and picks a themed token.

var name_edits: Array[LineEdit] = []
var token_opts: Array[OptionButton] = []

func _ready() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("#0d1322")
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)

	var title := Label.new()
	title.text = "Choose Your Tokens"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("#f0a020"))
	v.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)

	for i in GameConfig.player_count:
		var pl := Label.new()
		pl.text = "Player %d" % (i + 1)
		pl.add_theme_font_size_override("font_size", 24)
		grid.add_child(pl)

		var ne := LineEdit.new()
		ne.placeholder_text = "Player %d" % (i + 1)
		ne.custom_minimum_size = Vector2(220, 46)
		ne.add_theme_font_size_override("font_size", 22)
		grid.add_child(ne)
		name_edits.append(ne)

		var opt := OptionButton.new()
		opt.add_theme_font_size_override("font_size", 22)
		opt.custom_minimum_size = Vector2(200, 46)
		for t in GameConfig.TOKENS:
			opt.add_item(String(t.name))
		opt.select(i % GameConfig.TOKENS.size())
		grid.add_child(opt)
		token_opts.append(opt)

		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(46, 46)
		sw.color = GameConfig.TOKENS[i % GameConfig.TOKENS.size()].color
		grid.add_child(sw)
		opt.item_selected.connect(func(idx: int) -> void: sw.color = GameConfig.TOKENS[idx].color)

	var start := Button.new()
	start.text = "Start Game"
	start.add_theme_font_size_override("font_size", 30)
	start.custom_minimum_size = Vector2(260, 64)
	start.pressed.connect(_on_start)
	v.add_child(start)

	var back := Button.new()
	back.text = "Back"
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	v.add_child(back)

func _on_start() -> void:
	var names: Array[String] = []
	var toks: Array[String] = []
	for i in GameConfig.player_count:
		var nm := name_edits[i].text.strip_edges()
		names.append(nm if nm != "" else "Player %d" % (i + 1))
		toks.append(String(GameConfig.TOKENS[token_opts[i].selected].id))
	GameConfig.player_names = names
	GameConfig.player_tokens = toks
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
