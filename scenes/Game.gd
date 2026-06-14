extends Node3D
## First playable: 3D board, hopping tokens, dice, and the core turn loop.
## Built programmatically so it runs without hand-authored scene files.

const SPACING := 1.3
const HOP_TIME := 0.18

var state: GameState
var tokens: Dictionary = {}          # player_id -> MeshInstance3D
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
var player_rows: Array[Label] = []   # one cash label per player id

func _ready() -> void:
	state = GameState.new()
	state.setup(GameConfig.player_count, GameConfig.player_names)
	_build_environment()
	_build_board()
	_build_tokens()
	_build_hud()
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

# ----------------------------------------------------------------- scene building
func _build_environment() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 15.5, 13.5)
	cam.look_at_from_position(cam.position, Vector3.ZERO, Vector3.UP)
	cam.fov = 55.0
	add_child(cam)

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

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _build_board() -> void:
	for s in state.board.spaces:
		var tile := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(SPACING * 0.92, 0.1, SPACING * 0.92)
		tile.mesh = bm
		tile.position = _tile_world(s.index)
		tile.material_override = _mat(_tile_color(s))
		add_child(tile)

		# colour band for streets
		if s.type == SpaceData.Type.STREET:
			var g := state.board.get_group(s.color_group)
			if g != null:
				var band := MeshInstance3D.new()
				var bb := BoxMesh.new()
				bb.size = Vector3(SPACING * 0.92, 0.12, SPACING * 0.26)
				band.mesh = bb
				band.position = _tile_world(s.index) + Vector3(0, 0.02, -SPACING * 0.33)
				band.material_override = _mat(g.display_color)
				add_child(band)

		var label := Label3D.new()
		label.text = _tile_label(s)
		label.pixel_size = 0.0045
		label.font_size = 44
		label.modulate = Color.BLACK
		label.outline_size = 0
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
		var tok := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.16
		cm.bottom_radius = 0.16
		cm.height = 0.5
		tok.mesh = cm
		tok.material_override = _mat(p.token_color)
		tok.position = _tile_world(p.position) + _token_offset(p.id) + Vector3(0, 0.3, 0)
		add_child(tok)
		tokens[p.id] = tok

# ----------------------------------------------------------------------- HUD
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# top: turn label
	turn_label = Label.new()
	turn_label.add_theme_font_size_override("font_size", 34)
	turn_label.position = Vector2(20, 16)
	root.add_child(turn_label)

	# player cash list (top-right)
	var list := VBoxContainer.new()
	list.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	list.position = Vector2(-260, 14)
	list.add_theme_constant_override("separation", 4)
	root.add_child(list)
	player_rows.clear()
	for p in state.players:
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 22)
		row.modulate = p.token_color.lightened(0.2)
		list.add_child(row)
		player_rows.append(row)

	# center message
	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-300, 120)
	message_label.size = Vector2(600, 50)
	root.add_child(message_label)

	# bottom action bar
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(-320, -90)
	bar.add_theme_constant_override("separation", 14)
	root.add_child(bar)

	dice_label = Label.new()
	dice_label.add_theme_font_size_override("font_size", 28)
	dice_label.custom_minimum_size = Vector2(150, 56)
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

func _make_button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 26)
	b.custom_minimum_size = Vector2(120, 56)
	return b

func _update_hud() -> void:
	var cur := state.current_player()
	turn_label.text = "%s  —  $%d" % [cur.name, cur.cash]
	for i in state.players.size():
		var p := state.players[i]
		var tag := "  (OUT)" if p.bankrupt else ""
		var jail := "  [JAIL]" if p.in_jail else ""
		player_rows[i].text = "%s: $%d%s%s" % [p.name, p.cash, jail, tag]
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
	var tok: MeshInstance3D = tokens[p.id]
	var start: Vector3 = tok.position
	var end: Vector3 = _tile_world(to_index) + _token_offset(p.id) + Vector3(0, 0.3, 0)
	var mid: Vector3 = (start + end) * 0.5 + Vector3(0, 0.7, 0)
	var cb := func(t: float) -> void:
		tok.position = start.lerp(mid, t).lerp(mid.lerp(end, t), t)
	var tw := create_tween()
	tw.tween_method(cb, 0.0, 1.0, HOP_TIME)
	await tw.finished

# ------------------------------------------------------------------- landing
## Returns true if we're now waiting on a player buy/skip decision.
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
		_msg("🏆 %s wins the game!" % w.name)
