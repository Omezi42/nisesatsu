class_name UiKit
extends RefCounted

## コードで組むUIの共通部品(UIクロームはコード描画。CLAUDE.md)

const TEXT := Color(0.93, 0.90, 0.82)
const TEXT_DIM := Color(0.70, 0.66, 0.58)
const DESK := Color(0.16, 0.13, 0.11)
const DESK_EDGE := Color(0.10, 0.08, 0.07)
const PANEL := Color(0.22, 0.19, 0.16)
const BUTTON := Color(0.30, 0.26, 0.22)
const BUTTON_ACTIVE := Color(0.55, 0.44, 0.24)
const ACCEPT := Color(0.24, 0.42, 0.28)
const REJECT := Color(0.55, 0.20, 0.17)
const GOOD := Color(0.55, 0.85, 0.55)
const BAD := Color(0.95, 0.45, 0.40)
const CORNER := 6
const BORDER := 2


static func label(text: String, font_size: int, color := TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node


static func button(text: String, font_size: int, min_size: Vector2, color := BUTTON) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = min_size
	node.focus_mode = Control.FOCUS_NONE
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", TEXT)
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_color_override("font_pressed_color", Color.WHITE)
	node.add_theme_color_override("font_disabled_color", TEXT_DIM.darkened(0.3))
	node.add_theme_stylebox_override("normal", panel_style(color))
	node.add_theme_stylebox_override("hover", panel_style(color.lightened(0.12)))
	node.add_theme_stylebox_override("pressed", panel_style(color.darkened(0.15)))
	node.add_theme_stylebox_override("disabled", panel_style(color.darkened(0.45)))
	return node


static func set_button_color(node: Button, color: Color) -> void:
	node.add_theme_stylebox_override("normal", panel_style(color))
	node.add_theme_stylebox_override("hover", panel_style(color.lightened(0.12)))


static func panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.darkened(0.4)
	style.set_border_width_all(BORDER)
	style.set_corner_radius_all(CORNER)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


## 親いっぱいに広げる(生成直後に set_anchors_preset を使うと0サイズで固まる。docs/Pitfalls.md)
static func fill_parent(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0
