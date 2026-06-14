class_name UITheme
extends RefCounted
## Builds a shared Theme from the Kenney UI pack (CC0): styled buttons, Kenney font, panels.

const FONT_PATH := "res://assets/ui/kenney_ui/Font/Kenney Future Narrow.ttf"
const BTN_DIR := "res://assets/ui/kenney_ui/PNG/Blue/Default/"
const BTN_GREEN := "res://assets/ui/kenney_ui/PNG/Green/Default/"
const BTN_DISABLED := "res://assets/ui/kenney_ui/PNG/Grey/Default/button_rectangle_depth_flat.png"

## Style a single button as a big "primary" (green) call-to-action.
static func style_primary(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _btn(BTN_GREEN + "button_rectangle_depth_gradient.png"))
	b.add_theme_stylebox_override("hover", _btn(BTN_GREEN + "button_rectangle_depth_gloss.png"))
	b.add_theme_stylebox_override("pressed", _btn(BTN_GREEN + "button_rectangle_flat.png"))

static var _theme: Theme

static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	var f := font()
	if f != null:
		t.default_font = f
	t.default_font_size = 24

	t.set_stylebox("normal", "Button", _btn(BTN_DIR + "button_rectangle_depth_gradient.png"))
	t.set_stylebox("hover", "Button", _btn(BTN_DIR + "button_rectangle_depth_gloss.png"))
	t.set_stylebox("pressed", "Button", _btn(BTN_DIR + "button_rectangle_flat.png"))
	t.set_stylebox("disabled", "Button", _btn(BTN_DISABLED))
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color("#e0e0e0"))
	t.set_color("font_disabled_color", "Button", Color("#9aa0a6"))

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.14, 0.22, 0.96)
	ps.set_corner_radius_all(12)
	ps.set_border_width_all(2)
	ps.border_color = Color("#f0a020")
	ps.set_content_margin_all(14)
	t.set_stylebox("panel", "PanelContainer", ps)

	_theme = t
	return t

static func _btn(path: String, margin := 18) -> StyleBox:
	if not ResourceLoader.exists(path):
		return StyleBoxFlat.new()
	var s := StyleBoxTexture.new()
	s.texture = load(path)
	s.set_texture_margin_all(margin)
	s.set_content_margin_all(10)
	return s

static func font() -> Font:
	if ResourceLoader.exists(FONT_PATH):
		return load(FONT_PATH)
	return null
