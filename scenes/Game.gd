extends Node3D
## Playable game: 3D board with a pan/zoom/rotate camera, tumbling 3D dice,
## themed tokens, tap-to-inspect property cards, and the core turn loop.

const SPACING := 1.3
const HOP_TIME := 0.18
const TOKEN_Y := 0.06

# Camera rig
const CAM_BASE := Vector3(0, 13.5, 11.0)
const ZOOM_MIN := 0.45
const ZOOM_MAX := 2.4
var cam: Camera3D
var cam_pivot: Node3D
var cam_yaw := 0.0
var cam_zoom := 1.0
var cam_target := Vector3.ZERO

# Touch / gesture state
var _touches: Dictionary = {}
var _pinch_prev := -1.0
var _twist_prev := 0.0
var _tap_candidate := false
var _tap_start := Vector2.ZERO
var _last_tap_ms := 0
var _last_tap_pos := Vector2.ZERO

# Dice
var die1: Node3D
var die2: Node3D

var state: GameState
var tokens: Dictionary = {}
var busy := false
var pending_buy_index := -1
var pending_double := false

# HUD
var turn_label: Label
var dice_label: Label
var message_label: Label
var roll_button: Button
var end_button: Button
var buy_button: Button
var skip_button: Button
var player_rows: Array[Label] = []
var card_panel: PanelContainer
var card_vbox: VBoxContainer
var build_button: Button
var build_panel: PanelContainer
var build_vbox: VBoxContainer
var build_cash_label: Label
var _house_nodes: Dictionary = {}

func _ready() -> void:
	state = GameState.new()
	state.setup(GameConfig.player_count, GameConfig.player_names)
	_build_environment()
	_build_board()
	_build_tokens()
	_build_dice()
	_build_hud()
	_apply_camera()
	_start_turn()

# ----------------------------------------------------------------- board geometry
func _tile_xz(i: int) -> Vector2:
	if i <= 10:
		return Vector2(10 - i, 10)
	elif i <= 20:
		return Vector2(0, 10 - (i - 10))
	elif i <= 30:
		return Vector2(i - 20, 0)
	else:
		return Vector2(10, i - 30)

func _tile_world(i: int) -> Vector3:
	var xz := _tile_xz(i)
	return Vector3((xz.x - 5.0) * SPACING, 0.0, (xz.y - 5.0) * SPACING)

func _token_offset(pid: int) -> Vector3:
	var a := float(pid) * TAU / 6.0
	return Vector3(cos(a), 0.0, sin(a)) * 0.24

# ----------------------------------------------------------------- primitives
func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _mesh(mesh: Mesh, color: Color, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	mi.rotation = rot
	return mi

func _box(size: Vector3, color: Color, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _mesh(m, color, pos, rot)

func _sphere(r: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	return _mesh(m, color, pos)

func _cyl(rt: float, rb: float, h: float, color: Color, pos: Vector3, rot := Vector3.ZERO, seg := 16) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = seg
	return _mesh(m, color, pos, rot)

# ----------------------------------------------------------------- scene building
func _build_environment() -> void:
	cam_pivot = Node3D.new()
	add_child(cam_pivot)
	cam = Camera3D.new()
	cam.fov = 55.0
	cam_pivot.add_child(cam)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.1
	light.shadow_enabled = true
	add_child(light)

	var amb := DirectionalLight3D.new()
	amb.rotation_degrees = Vector3(-30, 140, 0)
	amb.light_energy = 0.4
	add_child(amb)

	var felt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(11.6 * SPACING, 0.08, 11.6 * SPACING)
	felt.mesh = bm
	felt.position = Vector3(0, -0.06, 0)
	felt.material_override = _mat(Color("#0f5132"))
	add_child(felt)

func _build_board() -> void:
	for s in state.board.spaces:
		var tile := _box(Vector3(SPACING * 0.92, 0.1, SPACING * 0.92), _tile_color(s), _tile_world(s.index))
		add_child(tile)

		if s.type == SpaceData.Type.STREET:
			var g := state.board.get_group(s.color_group)
			if g != null:
				var band := _box(Vector3(SPACING * 0.92, 0.12, SPACING * 0.26), g.display_color,
					_tile_world(s.index) + Vector3(0, 0.02, -SPACING * 0.33))
				add_child(band)

		var label := Label3D.new()
		label.text = _tile_label(s)
		label.pixel_size = 0.0045
		label.font_size = 44
		var lf := UITheme.font()
		if lf != null:
			label.font = lf
		label.modulate = Color.BLACK
		label.rotation_degrees = Vector3(-90, 0, 0)
		label.position = _tile_world(s.index) + Vector3(0, 0.12, 0)
		add_child(label)

func _tile_color(s: SpaceData) -> Color:
	match s.type:
		SpaceData.Type.GO: return Color("#2e7d32")
		SpaceData.Type.JAIL: return Color("#757575")
		SpaceData.Type.FREE_PARKING: return Color("#455a64")
		SpaceData.Type.GOTO_JAIL: return Color("#b71c1c")
		SpaceData.Type.STATION: return Color("#37474f")
		SpaceData.Type.UTILITY: return Color("#00838f")
		SpaceData.Type.TAX: return Color("#6d4c41")
		SpaceData.Type.CHANCE: return Color("#f9a825")
		SpaceData.Type.CHEST: return Color("#1565c0")
		_: return Color("#efe6d0")

func _tile_label(s: SpaceData) -> String:
	match s.type:
		SpaceData.Type.GO: return "GO"
		SpaceData.Type.JAIL: return "JAIL"
		SpaceData.Type.FREE_PARKING: return "FREE\nPARKING"
		SpaceData.Type.GOTO_JAIL: return "GO TO\nJAIL"
		SpaceData.Type.CHANCE: return "CHANCE\n?"
		SpaceData.Type.CHEST: return "CHEST"
		SpaceData.Type.TAX: return "%s\n-%d" % [s.display_name, s.tax_amount]
		_: return "%s\n%d" % [s.display_name, s.price]

func _build_tokens() -> void:
	for p in state.players:
		var token_def := GameConfig.token_for_player(p.id)
		var tok := _make_token(token_def)
		tok.position = _tile_world(p.position) + _token_offset(p.id) + Vector3(0, TOKEN_Y, 0)
		add_child(tok)
		tokens[p.id] = tok

func _make_token(token: Dictionary) -> Node3D:
	var root := Node3D.new()
	var c: Color = token.color
	match String(token.id):
		"rickshaw":
			root.add_child(_box(Vector3(0.3, 0.16, 0.4), c, Vector3(0, 0.14, 0)))
			root.add_child(_box(Vector3(0.26, 0.2, 0.2), c.lightened(0.2), Vector3(0, 0.3, -0.06)))
			root.add_child(_cyl(0.07, 0.07, 0.05, Color.BLACK, Vector3(-0.16, 0.07, 0.12), Vector3(0, 0, PI / 2.0)))
			root.add_child(_cyl(0.07, 0.07, 0.05, Color.BLACK, Vector3(0.16, 0.07, 0.12), Vector3(0, 0, PI / 2.0)))
			root.add_child(_cyl(0.07, 0.07, 0.05, Color.BLACK, Vector3(0, 0.07, -0.16), Vector3(0, 0, PI / 2.0)))
		"ball":
			root.add_child(_sphere(0.2, c, Vector3(0, 0.2, 0)))
		"kite":
			root.add_child(_box(Vector3(0.28, 0.02, 0.28), c, Vector3(0, 0.34, 0), Vector3(0, 0, PI / 4.0)))
			root.add_child(_cyl(0.006, 0.006, 0.34, c.darkened(0.2), Vector3(0, 0.17, 0)))
		"dhol", "drum":
			root.add_child(_cyl(0.16, 0.16, 0.34, c, Vector3(0, 0.2, 0)))
		"temple":
			root.add_child(_box(Vector3(0.34, 0.22, 0.34), c, Vector3(0, 0.13, 0)))
			root.add_child(_cyl(0.0, 0.2, 0.28, c.lightened(0.2), Vector3(0, 0.38, 0), Vector3.ZERO, 4))
		"top":
			root.add_child(_cyl(0.18, 0.0, 0.3, c, Vector3(0, 0.2, 0)))
			root.add_child(_cyl(0.03, 0.03, 0.12, c.lightened(0.3), Vector3(0, 0.4, 0)))
		"lamp":
			root.add_child(_cyl(0.18, 0.1, 0.1, c, Vector3(0, 0.1, 0)))
			root.add_child(_sphere(0.05, Color("#FF8C00"), Vector3(0, 0.2, 0)))
		_:
			root.add_child(_cyl(0.14, 0.14, 0.4, c, Vector3(0, 0.2, 0)))
	return root

# ----------------------------------------------------------------- dice
func _build_dice() -> void:
	die1 = _make_die()
	die1.position = Vector3(-0.5, 0.9, 0)
	add_child(die1)
	die2 = _make_die()
	die2.position = Vector3(0.5, 0.9, 0)
	add_child(die2)

func _make_die() -> Node3D:
	var d := _box(Vector3(0.6, 0.6, 0.6), Color("#fafafa"), Vector3.ZERO)
	_add_face(d, 1, Vector3(0, 0.301, 0), Vector3(-90, 0, 0))
	_add_face(d, 6, Vector3(0, -0.301, 0), Vector3(90, 0, 0))
	_add_face(d, 3, Vector3(0.301, 0, 0), Vector3(0, 90, 0))
	_add_face(d, 4, Vector3(-0.301, 0, 0), Vector3(0, -90, 0))
	_add_face(d, 2, Vector3(0, 0, 0.301), Vector3(0, 0, 0))
	_add_face(d, 5, Vector3(0, 0, -0.301), Vector3(0, 180, 0))
	return d

func _add_face(die: Node3D, value: int, pos: Vector3, rot_deg: Vector3) -> void:
	# Kenney board-game pack dice faces (real dots) textured onto each cube face.
	var q := MeshInstance3D.new()
	var m := QuadMesh.new()
	m.size = Vector2(0.58, 0.58)
	q.mesh = m
	var mat := StandardMaterial3D.new()
	var path := "res://assets/models/kenney_boardgame/PNG/Dice/dieWhite%d.png" % value
	if ResourceLoader.exists(path):
		mat.albedo_texture = load(path)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material_override = mat
	q.position = pos
	q.rotation_degrees = rot_deg
	die.add_child(q)

func _die_target(v: int) -> Vector3:
	match v:
		1: return Vector3.ZERO
		6: return Vector3(PI, 0, 0)
		2: return Vector3(-PI / 2.0, 0, 0)
		5: return Vector3(PI / 2.0, 0, 0)
		3: return Vector3(0, 0, PI / 2.0)
		4: return Vector3(0, 0, -PI / 2.0)
	return Vector3.ZERO

func _animate_dice(v1: int, v2: int) -> void:
	die1.rotation = Vector3(state.rng.randf() * TAU, state.rng.randf() * TAU, state.rng.randf() * TAU)
	die2.rotation = Vector3(state.rng.randf() * TAU, state.rng.randf() * TAU, state.rng.randf() * TAU)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(die1, "rotation", _die_target(v1) + Vector3(TAU * 2, TAU * 3, 0), 0.7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(die2, "rotation", _die_target(v2) + Vector3(TAU * 3, TAU * 2, 0), 0.7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished

# ----------------------------------------------------------------------- camera
func _apply_camera() -> void:
	cam_zoom = clampf(cam_zoom, ZOOM_MIN, ZOOM_MAX)
	cam_target.x = clampf(cam_target.x, -10.0, 10.0)
	cam_target.z = clampf(cam_target.z, -10.0, 10.0)
	cam_pivot.position = cam_target
	cam_pivot.rotation = Vector3(0, cam_yaw, 0)
	cam.position = CAM_BASE * cam_zoom
	cam.look_at(cam_pivot.global_transform.origin, Vector3.UP)

func _recenter() -> void:
	cam_target = Vector3.ZERO
	cam_yaw = 0.0
	cam_zoom = 1.0
	_apply_camera()

func _focus_tile(idx: int) -> void:
	cam_target = _tile_world(idx)
	cam_zoom = 0.6
	_apply_camera()

func _unhandled_input(event: InputEvent) -> void:
	if cam == null or state == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_tap_candidate = true
				_tap_start = event.position
			else:
				_tap_candidate = false
				_pinch_prev = -1.0
		else:
			_touches.erase(event.index)
			if _touches.size() < 2:
				_pinch_prev = -1.0
			if _tap_candidate and _touches.is_empty():
				_handle_tap(event.position)
			_tap_candidate = false
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			_handle_two_finger()
		elif _touches.size() == 1:
			if event.position.distance_to(_tap_start) > 14.0:
				_tap_candidate = false
			_pan(event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cam_zoom *= 0.9
			_apply_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cam_zoom *= 1.1
			_apply_camera()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if _tap_candidate:
				_handle_tap(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_tap_candidate = true
			_tap_start = event.position
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if event.position.distance_to(_tap_start) > 6.0:
				_tap_candidate = false
			_pan(event.relative)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			cam_yaw += event.relative.x * 0.01
			_apply_camera()

func _pan(rel: Vector2) -> void:
	var basis := cam_pivot.transform.basis
	cam_target += (basis * Vector3(-rel.x, 0, -rel.y)) * (0.013 * cam_zoom)
	_apply_camera()

func _handle_two_finger() -> void:
	var pts := _touches.values()
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[1]
	var dist := a.distance_to(b)
	var ang := (b - a).angle()
	if _pinch_prev > 0.0:
		cam_zoom *= _pinch_prev / max(dist, 1.0)
		cam_yaw += ang - _twist_prev
		_apply_camera()
	_pinch_prev = dist
	_twist_prev = ang

func _handle_tap(pos: Vector2) -> void:
	var idx := _tile_at_screen(pos)
	if idx < 0:
		return
	var now := Time.get_ticks_msec()
	if now - _last_tap_ms < 350 and pos.distance_to(_last_tap_pos) < 40.0:
		_focus_tile(idx)
		_last_tap_ms = 0
	else:
		_show_property_card(idx)
		_last_tap_ms = now
		_last_tap_pos = pos

func _tile_at_screen(pos: Vector2) -> int:
	var from := cam.project_ray_origin(pos)
	var dir := cam.project_ray_normal(pos)
	if absf(dir.y) < 0.0001:
		return -1
	var t := -from.y / dir.y
	if t < 0:
		return -1
	var hit := from + dir * t
	var best := -1
	var best_d := 1e9
	for s in state.board.spaces:
		var d := hit.distance_squared_to(_tile_world(s.index))
		if d < best_d:
			best_d = d
			best = s.index
	if best_d > pow(SPACING * 0.7, 2):
		return -1
	return best

# ----------------------------------------------------------------------- HUD
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	layer.add_child(root)

	turn_label = Label.new()
	turn_label.add_theme_font_size_override("font_size", 32)
	turn_label.position = Vector2(20, 14)
	root.add_child(turn_label)

	var list := VBoxContainer.new()
	list.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	list.position = Vector2(-280, 12)
	list.add_theme_constant_override("separation", 3)
	root.add_child(list)
	player_rows.clear()
	for p in state.players:
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 22)
		row.modulate = p.token_color.lightened(0.2)
		list.add_child(row)
		player_rows.append(row)

	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 28)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-340, 60)
	message_label.size = Vector2(680, 44)
	root.add_child(message_label)

	# recenter button (top-left below turn)
	var rc := _make_button("Recenter")
	rc.custom_minimum_size = Vector2(120, 44)
	rc.position = Vector2(20, 58)
	rc.pressed.connect(_recenter)
	root.add_child(rc)

	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(-330, -84)
	bar.add_theme_constant_override("separation", 14)
	root.add_child(bar)

	dice_label = Label.new()
	dice_label.add_theme_font_size_override("font_size", 26)
	dice_label.custom_minimum_size = Vector2(140, 56)
	dice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(dice_label)

	roll_button = _make_button("Roll Dice")
	roll_button.pressed.connect(_on_roll_pressed)
	bar.add_child(roll_button)

	buy_button = _make_button("Buy")
	buy_button.pressed.connect(_on_buy_pressed)
	buy_button.visible = false
	bar.add_child(buy_button)

	skip_button = _make_button("Skip")
	skip_button.pressed.connect(_on_skip_pressed)
	skip_button.visible = false
	bar.add_child(skip_button)

	end_button = _make_button("End Turn")
	end_button.pressed.connect(_on_end_pressed)
	bar.add_child(end_button)

	build_button = _make_button("Build")
	build_button.pressed.connect(_open_build)
	bar.add_child(build_button)

	_build_card_panel(root)
	_build_build_panel(root)

func _make_button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(130, 60)
	b.pressed.connect(func() -> void: Sfx.play("click"))
	return b

func _build_card_panel(root: Control) -> void:
	card_panel = PanelContainer.new()
	card_panel.set_anchors_preset(Control.PRESET_CENTER)
	card_panel.position = Vector2(-170, -200)
	card_panel.custom_minimum_size = Vector2(340, 0)
	card_panel.visible = false
	root.add_child(card_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card_panel.add_child(margin)
	card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(card_vbox)

func _card_line(text: String, size := 20, color := Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	card_vbox.add_child(l)

func _show_property_card(idx: int) -> void:
	var s := state.board.get_space(idx)
	if s == null:
		return
	for c in card_vbox.get_children():
		c.queue_free()
	var header_color := Color.WHITE
	if s.type == SpaceData.Type.STREET:
		var g := state.board.get_group(s.color_group)
		if g != null:
			header_color = g.display_color
	_card_line(s.display_name if s.display_name != "" else _tile_label(s).replace("\n", " "), 26, header_color)
	if s.is_ownable():
		_card_line("Price: $%d" % s.price)
		var owner_id := state.owner_of(idx)
		var owner_txt := "Unowned"
		if owner_id >= 0:
			owner_txt = state.player_by_id(owner_id).name
		_card_line("Owner: %s" % owner_txt, 18, Color("#cfd8dc"))
		if s.type == SpaceData.Type.STREET:
			var names := ["Rent", "1 House", "2 Houses", "3 Houses", "4 Houses", "HOTEL"]
			for i in s.rent_table.size():
				_card_line("%s: $%d" % [names[i], s.rent_table[i]], 17, Color("#e0e0e0"))
		elif s.type == SpaceData.Type.STATION:
			for i in s.station_rent.size():
				_card_line("%d owned: $%d" % [i + 1, s.station_rent[i]], 17, Color("#e0e0e0"))
		elif s.type == SpaceData.Type.UTILITY:
			_card_line("Rent = dice x %d (1) / x %d (both)" % [s.utility_multiplier[0], s.utility_multiplier[1]], 16, Color("#e0e0e0"))
		_card_line("Mortgage: $%d" % s.mortgage_value, 17, Color("#bdbdbd"))
	elif s.type == SpaceData.Type.TAX:
		_card_line("Pay $%d" % s.tax_amount)
	else:
		_card_line(_tile_label(s).replace("\n", " "), 18, Color("#cfd8dc"))
	var close := Button.new()
	close.text = "Close"
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(func() -> void: card_panel.visible = false)
	card_vbox.add_child(close)
	card_panel.visible = true

# ----------------------------------------------------------------- build panel
func _build_build_panel(root: Control) -> void:
	build_panel = PanelContainer.new()
	build_panel.set_anchors_preset(Control.PRESET_CENTER)
	build_panel.custom_minimum_size = Vector2(660, 560)
	build_panel.position = Vector2(-330, -280)
	build_panel.visible = false
	root.add_child(build_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	build_panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var title := Label.new()
	title.text = "BUILD HOUSES & HOTELS"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#f0a020"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)

	build_cash_label = Label.new()
	build_cash_label.add_theme_font_size_override("font_size", 22)
	build_cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(build_cash_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	build_vbox = VBoxContainer.new()
	build_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(build_vbox)

	var close := Button.new()
	close.text = "Close"
	close.add_theme_font_size_override("font_size", 24)
	close.custom_minimum_size = Vector2(0, 56)
	close.pressed.connect(func() -> void:
		Sfx.play("click")
		build_panel.visible = false)
	outer.add_child(close)

func _open_build() -> void:
	if busy:
		return
	_populate_build()
	build_panel.visible = true

func _populate_build() -> void:
	for c in build_vbox.get_children():
		c.queue_free()
	var p := state.current_player()
	build_cash_label.text = "%s   ·   Cash $%d" % [p.name, p.cash]
	var groups := state.player_full_groups(p.id)
	if groups.is_empty():
		var info := Label.new()
		info.text = "Own a full colour group (monopoly) to build houses."
		info.add_theme_font_size_override("font_size", 20)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		build_vbox.add_child(info)
		return
	for gid in groups:
		var g := state.board.get_group(gid)
		for idx in g.member_indices:
			build_vbox.add_child(_build_row(p, g, idx))

func _build_row(p: Player, g: ColorGroupData, idx: int) -> Control:
	var s := state.board.get_space(idx)
	var ps: PropertyState = state.props.get(idx)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var sw := ColorRect.new()
	sw.custom_minimum_size = Vector2(14, 50)
	sw.color = g.display_color
	row.add_child(sw)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := Label.new()
	nm.text = s.display_name
	nm.add_theme_font_size_override("font_size", 22)
	info.add_child(nm)
	var sub := Label.new()
	var lvl := "HOTEL" if ps.houses >= 5 else ("Houses: %d" % ps.houses)
	var rent := RentCalculator.street_rent(s, ps.houses, true, false)
	sub.text = "%s   ·   Rent $%d" % [lvl, rent]
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color("#cfd8dc"))
	info.add_child(sub)
	row.add_child(info)

	var sell_b := Button.new()
	sell_b.text = "Sell"
	sell_b.add_theme_font_size_override("font_size", 18)
	sell_b.custom_minimum_size = Vector2(90, 54)
	sell_b.disabled = not state.can_sell_on(p.id, idx)
	sell_b.pressed.connect(_on_sell_pressed.bind(idx))
	row.add_child(sell_b)

	var build_b := Button.new()
	build_b.text = "Build $%d" % s.house_cost
	build_b.add_theme_font_size_override("font_size", 18)
	build_b.custom_minimum_size = Vector2(150, 54)
	build_b.disabled = not state.can_build_on(p.id, idx)
	build_b.pressed.connect(_on_build_pressed.bind(idx))
	row.add_child(build_b)
	return row

func _on_build_pressed(idx: int) -> void:
	var p := state.current_player()
	if state.build_house(p.id, idx):
		Sfx.play("cash")
		_refresh_houses(idx)
		_update_hud()
		_populate_build()

func _on_sell_pressed(idx: int) -> void:
	var p := state.current_player()
	if state.sell_house(p.id, idx):
		Sfx.play("click")
		_refresh_houses(idx)
		_update_hud()
		_populate_build()

func _refresh_houses(idx: int) -> void:
	if _house_nodes.has(idx):
		_house_nodes[idx].queue_free()
		_house_nodes.erase(idx)
	var ps: PropertyState = state.props.get(idx)
	if ps == null or ps.houses <= 0:
		return
	var cont := Node3D.new()
	add_child(cont)
	var base := _tile_world(idx) + Vector3(0, 0.11, 0)
	if ps.houses >= 5:
		cont.add_child(_box(Vector3(0.34, 0.2, 0.2), Color("#c62828"), base + Vector3(0, 0.1, 0)))
	else:
		for h in ps.houses:
			var x := (float(h) - float(ps.houses - 1) / 2.0) * 0.16
			cont.add_child(_box(Vector3(0.11, 0.14, 0.11), Color("#2e7d32"), base + Vector3(x, 0.07, 0)))
	_house_nodes[idx] = cont

func _update_hud() -> void:
	var cur := state.current_player()
	turn_label.text = "%s  —  $%d" % [cur.name, cur.cash]
	for i in state.players.size():
		var p := state.players[i]
		var tag := "  (OUT)" if p.bankrupt else ""
		var jail := "  [JAIL]" if p.in_jail else ""
		var tdef := GameConfig.token_for_player(p.id)
		player_rows[i].text = "%s (%s): $%d%s%s" % [p.name, String(tdef.name), p.cash, jail, tag]
		player_rows[i].modulate = Color("#666666") if p.bankrupt else p.token_color.lightened(0.2)

func _msg(t: String) -> void:
	message_label.text = t

# ------------------------------------------------------------------- turn flow
func _start_turn() -> void:
	busy = false
	var p := state.current_player()
	buy_button.visible = false
	skip_button.visible = false
	roll_button.disabled = false
	end_button.disabled = true
	dice_label.text = ""
	_update_hud()
	if p.in_jail:
		_msg("%s is in Jail. Roll for doubles (try %d/3)." % [p.name, p.jail_turns + 1])
	else:
		_msg("%s's turn. Roll the dice!" % p.name)

func _on_roll_pressed() -> void:
	if busy:
		return
	busy = true
	roll_button.disabled = true
	var p := state.current_player()
	var r := DiceLogic.roll(state.rng)
	dice_label.text = "%d + %d = %d" % [r.d1, r.d2, r.total]
	Sfx.play("dice")
	await _animate_dice(r.d1, r.d2)

	if p.in_jail:
		await _handle_jail_roll(p, r)
		return

	if r.is_double:
		state.doubles_count += 1
		if DiceLogic.should_go_to_jail(state.doubles_count):
			_msg("Three doubles! %s goes to Jail." % p.name)
			await _send_to_jail(p)
			_post_move(p, false)
			return
	else:
		state.doubles_count = 0

	await _move_player(p, r.total)
	var awaiting := await _resolve_landing(p, r.total)
	if not awaiting:
		_post_move(p, r.is_double)

func _handle_jail_roll(p: Player, r: Dictionary) -> void:
	if r.is_double:
		p.in_jail = false
		p.jail_turns = 0
		_msg("Doubles! %s leaves Jail." % p.name)
		await _move_player(p, r.total)
		var awaiting := await _resolve_landing(p, r.total)
		if not awaiting:
			_post_move(p, false)
	else:
		p.jail_turns += 1
		if p.jail_turns >= 3:
			_charge(p, null, state.board.jail_fine)
			p.in_jail = false
			p.jail_turns = 0
			_msg("%s pays $%d fine and moves." % [p.name, state.board.jail_fine])
			await _move_player(p, r.total)
			var awaiting := await _resolve_landing(p, r.total)
			if not awaiting:
				_post_move(p, false)
		else:
			_msg("%s stays in Jail (%d/3)." % [p.name, p.jail_turns])
			busy = false
			roll_button.disabled = true
			end_button.disabled = false

func _post_move(p: Player, was_double: bool) -> void:
	busy = false
	_update_hud()
	if state.winner() != null:
		_end_game()
		return
	if was_double and not p.bankrupt and not p.in_jail:
		roll_button.disabled = false
		end_button.disabled = true
		_msg("Doubles! %s rolls again." % p.name)
	else:
		roll_button.disabled = true
		end_button.disabled = false

func _on_end_pressed() -> void:
	if busy:
		return
	state.advance_to_next_player()
	_start_turn()

# ------------------------------------------------------------------- movement
func _move_player(p: Player, steps: int) -> void:
	for s in steps:
		var to := (p.position + 1) % 40
		if to == 0:
			p.cash += state.board.go_salary
			_msg("%s passed GO  +$%d" % [p.name, state.board.go_salary])
		await _hop(p, to)
		p.position = to
	_update_hud()

func _teleport(p: Player, to: int) -> void:
	await _hop(p, to)
	p.position = to
	_update_hud()

func _hop(p: Player, to_index: int) -> void:
	var tok: Node3D = tokens[p.id]
	var start: Vector3 = tok.position
	var end: Vector3 = _tile_world(to_index) + _token_offset(p.id) + Vector3(0, TOKEN_Y, 0)
	var mid: Vector3 = (start + end) * 0.5 + Vector3(0, 0.7, 0)
	var cb := func(t: float) -> void:
		tok.position = start.lerp(mid, t).lerp(mid.lerp(end, t), t)
	var tw := create_tween()
	tw.tween_method(cb, 0.0, 1.0, HOP_TIME)
	await tw.finished

# ------------------------------------------------------------------- landing
func _resolve_landing(p: Player, dice_total: int) -> bool:
	var s := state.board.get_space(p.position)
	match s.type:
		SpaceData.Type.STREET, SpaceData.Type.STATION, SpaceData.Type.UTILITY:
			var owner := state.owner_of(p.position)
			if owner == -1:
				if p.cash >= s.price:
					_offer_buy(p, p.position)
					return true
				_msg("%s can't afford %s ($%d)." % [p.name, s.display_name, s.price])
			elif owner != p.id:
				_pay_rent(p, p.position, dice_total)
		SpaceData.Type.TAX:
			_msg("%s pays %s of $%d." % [p.name, s.display_name, s.tax_amount])
			_charge(p, null, s.tax_amount)
		SpaceData.Type.CHANCE:
			return await _do_card(p, state.draw_chance(), dice_total)
		SpaceData.Type.CHEST:
			return await _do_card(p, state.draw_chest(), dice_total)
		SpaceData.Type.GOTO_JAIL:
			_msg("%s goes to Jail!" % p.name)
			await _send_to_jail(p)
	return false

func _offer_buy(p: Player, index: int) -> void:
	pending_buy_index = index
	pending_double = state.doubles_count > 0
	var s := state.board.get_space(index)
	_msg("%s landed on %s — buy for $%d?" % [p.name, s.display_name, s.price])
	buy_button.visible = true
	skip_button.visible = true
	roll_button.disabled = true
	end_button.disabled = true

func _on_buy_pressed() -> void:
	var p := state.current_player()
	if pending_buy_index >= 0:
		state.buy(p, pending_buy_index)
		Sfx.play("cash")
		_msg("%s bought %s." % [p.name, state.board.get_space(pending_buy_index).display_name])
	_finish_buy(p)

func _on_skip_pressed() -> void:
	var p := state.current_player()
	_msg("%s skipped the purchase." % p.name)
	_finish_buy(p)

func _finish_buy(p: Player) -> void:
	buy_button.visible = false
	skip_button.visible = false
	pending_buy_index = -1
	_post_move(p, pending_double)

func _pay_rent(p: Player, index: int, dice_total: int) -> void:
	var amount := state.rent_for(index, dice_total)
	var owner := state.player_by_id(state.owner_of(index))
	if amount <= 0 or owner == null:
		return
	_msg("%s pays $%d rent to %s." % [p.name, amount, owner.name])
	_charge(p, owner, amount)

func _charge(payer: Player, payee: Player, amount: int) -> void:
	Sfx.play("cash")
	if payer.cash >= amount:
		state.transfer(payer, payee, amount)
	else:
		_declare_bankrupt(payer, payee)
	_update_hud()

func _declare_bankrupt(p: Player, creditor: Player) -> void:
	p.bankrupt = true
	if creditor != null and p.cash > 0:
		creditor.cash += p.cash
	p.cash = 0
	for idx in p.owned:
		var ps: PropertyState = state.props.get(idx)
		if ps != null:
			ps.owner_id = -1
			ps.houses = 0
			ps.mortgaged = false
			_refresh_houses(idx)
	p.owned.clear()
	if tokens.has(p.id):
		tokens[p.id].visible = false
	_msg("%s is bankrupt and out of the game!" % p.name)

func _send_to_jail(p: Player) -> void:
	state.doubles_count = 0
	await _teleport(p, state.board.jail_index)
	p.in_jail = true
	p.jail_turns = 0

func _do_card(p: Player, card: CardData, dice_total: int) -> bool:
	if card == null:
		return false
	_msg(card.text)
	match card.effect:
		CardData.Effect.COLLECT:
			p.cash += card.amount
		CardData.Effect.PAY:
			_charge(p, null, card.amount)
		CardData.Effect.GET_OUT_OF_JAIL_FREE:
			p.get_out_cards += 1
		CardData.Effect.GOTO_JAIL:
			await _send_to_jail(p)
		CardData.Effect.MOVE_TO:
			if card.target_index < p.position:
				p.cash += state.board.go_salary
			await _teleport(p, card.target_index)
			return await _resolve_landing(p, dice_total)
		CardData.Effect.MOVE_REL:
			var np := (p.position + card.amount + 40) % 40
			await _teleport(p, np)
			return await _resolve_landing(p, dice_total)
		CardData.Effect.REPAIRS:
			_charge(p, null, _repair_cost(p, card.per_house, card.per_hotel))
	_update_hud()
	return false

func _repair_cost(p: Player, per_house: int, per_hotel: int) -> int:
	var cost := 0
	for idx in p.owned:
		var ps: PropertyState = state.props.get(idx)
		if ps == null:
			continue
		if ps.houses >= 5:
			cost += per_hotel
		else:
			cost += ps.houses * per_house
	return cost

func _end_game() -> void:
	var w := state.winner()
	roll_button.disabled = true
	end_button.disabled = true
	buy_button.visible = false
	skip_button.visible = false
	if w != null:
		_msg("%s wins the game!" % w.name)
