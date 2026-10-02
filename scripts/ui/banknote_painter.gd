class_name BanknotePainter
extends Node2D

## 紙幣1枚をコードで描く(GameDesign.md 4・5章)。座標は論理サイズ BILL_SIZE で書き、px_scale 倍で描く

const BILL_SIZE := Vector2(600, 300)
const FONT := preload("res://assets/fonts/ZenKakuGothicNew-Bold.ttf")
const L := CurrencyData.MAX_LEVEL

const PAPER := Color(0.93, 0.90, 0.82)
const PAPER_TINT := 0.12
const SERIAL_INK := Color(0.42, 0.10, 0.09)
const BACKLIGHT_PAPER := Color(1.0, 0.96, 0.84)
const BACKLIGHT_INK_ALPHA := 0.4
const WATERMARK_SHADE := Color(0.62, 0.52, 0.36)
const UV_DARK := Color(0.09, 0.05, 0.18)
const UV_PAPER_GLOW := Color(0.78, 0.80, 1.0)
const UV_INK_ALPHA := 0.1
const UV_GLOW_GENUINE := Color(0.72, 1.0, 0.28)
const UV_GLOW_WRONG := Color(0.38, 0.62, 1.0)

## 色味の再現度ごとの色相のずれ(再現度 0, 1, 2, 3)
const HUE_SHIFT := [0.12, 0.06, 0.025, 0.0]

const SPECK_COUNT := 260
const BG_LINE_COUNT := 26
const BG_LINE_TOP := 34.0
const BG_LINE_GAP := 9.0
const BG_LINE_STEPS := 150
const BORDER_OUTER := 12.0
const BORDER_INNER := 19.0

const ROSETTE_CENTER := Vector2(300, 140)
const ROSETTE_RADIUS := 76.0
const ROSETTE_LAYERS := 6
const ROSETTE_STEPS := 480
const PETALS_GENUINE := 12
const ROSETTE_JITTER := 0.035
const LINE_FINE := 0.45
const LINE_SMEAR := 2.0

const EMBLEM_CENTER := Vector2(112, 150)
const EMBLEM_RADIUS := 50.0
const EMBLEM_TICKS := 90

const WINDOW_CENTER := Vector2(486, 148)
const WINDOW_RADII := Vector2(50, 70)
const WATERMARK_OFFSET := Vector2(13, 9)
const WATERMARK_BLUR_COPIES := 6
const WATERMARK_BLUR_SPREAD := 3.0
const WATERMARK_FAINT_ALPHA := 0.18
const WATERMARK_SCALE := 0.95

const MICRO_Y := 283.0
const MICRO_LEFT := 30.0
const MICRO_RIGHT := 570.0
const MICRO_SIZE := 3.0
const GARBLE_CHARS := "LUMERIA1|/\\-=#"

var currency: CurrencyData
var note: Banknote
var view_mode: GameEnums.ViewMode = GameEnums.ViewMode.NORMAL
var px_scale := 1.0

var _ink_alpha := 1.0
var _rng := RandomNumberGenerator.new()


func _draw() -> void:
	if note == null or currency == null:
		return
	_rng.seed = note.art_seed
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(px_scale, px_scale))
	_draw_paper()
	_draw_print()
	match view_mode:
		GameEnums.ViewMode.BACKLIGHT:
			_draw_watermark()
		GameEnums.ViewMode.UV:
			_draw_uv_glow()


func _level(feature: GameEnums.Feature) -> int:
	return note.level(feature)


func _base_color() -> Color:
	var color := currency.denominations[note.denomination_index].base_color
	var shift: float = HUE_SHIFT[_level(GameEnums.Feature.COLOR)]
	var direction := 1.0 if note.art_seed % 2 == 0 else -1.0
	return Color.from_hsv(fposmod(color.h + shift * direction, 1.0), color.s, color.v, color.a)


func _ink(color: Color, alpha := 1.0) -> Color:
	return Color(color, color.a * alpha * _ink_alpha)


func _draw_paper() -> void:
	var rect := Rect2(Vector2.ZERO, BILL_SIZE)
	match view_mode:
		GameEnums.ViewMode.BACKLIGHT:
			draw_rect(rect, BACKLIGHT_PAPER)
			_ink_alpha = BACKLIGHT_INK_ALPHA
		GameEnums.ViewMode.UV:
			var glow := _level(GameEnums.Feature.UV_INK) == 1
			draw_rect(rect, UV_PAPER_GLOW if glow else UV_DARK)
			_ink_alpha = UV_INK_ALPHA
		_:
			draw_rect(rect, PAPER.lerp(_base_color(), PAPER_TINT))
			_ink_alpha = 1.0
	for i in SPECK_COUNT:
		var pos := Vector2(_rng.randf() * BILL_SIZE.x, _rng.randf() * BILL_SIZE.y)
		draw_circle(pos, _rng.randf_range(0.2, 0.7), _ink(Color(0.3, 0.25, 0.2), 0.12))


func _draw_print() -> void:
	var base := _base_color()
	_draw_background_lines(base)
	_draw_border(base)
	_draw_window(base)
	_draw_emblem(base)
	_draw_rosette(base)
	_draw_texts(base)
	_draw_microtext(base)


func _draw_background_lines(base: Color) -> void:
	for k in BG_LINE_COUNT:
		var points := PackedVector2Array()
		var y0 := BG_LINE_TOP + k * BG_LINE_GAP
		for i in BG_LINE_STEPS + 1:
			var x := lerpf(BORDER_INNER, BILL_SIZE.x - BORDER_INNER, float(i) / BG_LINE_STEPS)
			points.append(Vector2(x, y0 + 4.0 * sin(x * 0.045 + k * 0.7) + 2.0 * sin(x * 0.11)))
		draw_polyline(points, _ink(base, 0.22), LINE_FINE, true)


func _draw_border(base: Color) -> void:
	var outer := Rect2(Vector2.ONE * BORDER_OUTER, BILL_SIZE - Vector2.ONE * BORDER_OUTER * 2)
	var inner := Rect2(Vector2.ONE * BORDER_INNER, BILL_SIZE - Vector2.ONE * BORDER_INNER * 2)
	draw_rect(outer, _ink(base), false, 1.4, true)
	draw_rect(inner, _ink(base, 0.8), false, 0.6, true)
	var mid := (BORDER_OUTER + BORDER_INNER) * 0.5
	var amp := (BORDER_INNER - BORDER_OUTER) * 0.35
	for edge_y in [mid, BILL_SIZE.y - mid]:
		for phase in [0.0, PI]:
			var points := PackedVector2Array()
			for i in BG_LINE_STEPS + 1:
				var x := lerpf(BORDER_OUTER, BILL_SIZE.x - BORDER_OUTER, float(i) / BG_LINE_STEPS)
				points.append(Vector2(x, edge_y + amp * sin(x * 0.25 + phase)))
			draw_polyline(points, _ink(base, 0.7), LINE_FINE, true)


func _draw_window(base: Color) -> void:
	var fill := PAPER if view_mode == GameEnums.ViewMode.NORMAL else Color(0, 0, 0, 0)
	if fill.a > 0.0:
		draw_colored_polygon(_ellipse(WINDOW_CENTER, WINDOW_RADII), fill)
	var outline := _ellipse(WINDOW_CENTER, WINDOW_RADII)
	outline.append(outline[0])
	draw_polyline(outline, _ink(base, 0.35), LINE_FINE, true)


func _draw_emblem(base: Color) -> void:
	draw_arc(EMBLEM_CENTER, EMBLEM_RADIUS, 0, TAU, 96, _ink(base), 0.8, true)
	draw_arc(EMBLEM_CENTER, EMBLEM_RADIUS - 6.0, 0, TAU, 96, _ink(base), 0.5, true)
	for i in EMBLEM_TICKS:
		var dir := Vector2.from_angle(TAU * i / EMBLEM_TICKS)
		draw_line(
			EMBLEM_CENTER + dir * (EMBLEM_RADIUS - 5.5),
			EMBLEM_CENTER + dir * (EMBLEM_RADIUS - 0.5),
			_ink(base, 0.7),
			0.35,
			true
		)
	var tower := _lighthouse(EMBLEM_CENTER + Vector2(0, 4), 1.0)
	draw_colored_polygon(tower, _ink(base.darkened(0.25), 0.9))
	for y in range(-36, 48, 3):
		draw_line(
			EMBLEM_CENTER + Vector2(-16, y),
			EMBLEM_CENTER + Vector2(16, y),
			_ink(PAPER, 0.35),
			0.6,
			true
		)
	var lamp := EMBLEM_CENTER + Vector2(0, -26)
	for side in [-1.0, 1.0]:
		draw_colored_polygon(
			PackedVector2Array(
				[lamp, lamp + Vector2(side * 38, -12), lamp + Vector2(side * 38, 4)]
			),
			_ink(base, 0.25)
		)


func _draw_rosette(base: Color) -> void:
	var level := _level(GameEnums.Feature.PATTERN)
	var petals := PETALS_GENUINE - 1 if level == 2 else PETALS_GENUINE
	var width := LINE_SMEAR if level == 0 else LINE_FINE
	var alpha := 0.55 if level == 0 else 0.9
	for layer in ROSETTE_LAYERS:
		var points := PackedVector2Array()
		var radius := ROSETTE_RADIUS * (1.0 - layer * 0.07)
		for i in ROSETTE_STEPS + 1:
			var t := TAU * i / ROSETTE_STEPS
			var r := radius * (0.68 + 0.32 * cos(petals * t + layer * 0.55))
			if level == 1:
				r += radius * ROSETTE_JITTER * sin(t * 37.0 + layer) * sin(t * 11.0)
			points.append(ROSETTE_CENTER + Vector2.from_angle(t) * r)
		draw_polyline(points, _ink(base, alpha), width, true)
		if level == 0:
			points = _offset(points, Vector2(0.9, 0.6))
			draw_polyline(points, _ink(base, alpha * 0.5), width, true)


func _draw_texts(base: Color) -> void:
	var denomination := currency.denominations[note.denomination_index]
	var value := str(denomination.value)
	var dark := base.darkened(0.35)
	_text_centered(Vector2(300, 46), "%s中央銀行" % currency.currency_name, 13, _ink(dark))
	_text_centered(ROSETTE_CENTER + Vector2(0, 16), value, 44, _ink(dark))
	_text_centered(ROSETTE_CENTER + Vector2(0, 108), currency.unit, 15, _ink(dark))
	_text(Vector2(BILL_SIZE.x - 92, 62), value, 24, _ink(dark))
	_text(Vector2(34, 262), value, 24, _ink(dark))
	_text(Vector2(34, 48), note.serial_text(), 14, _ink(SERIAL_INK))
	_text(Vector2(BILL_SIZE.x - 152, 262), note.serial_text(), 14, _ink(SERIAL_INK))


func _draw_microtext(base: Color) -> void:
	var level := _level(GameEnums.Feature.MICROTEXT)
	var color := _ink(base.darkened(0.3))
	draw_line(Vector2(MICRO_LEFT, MICRO_Y - 4.0), Vector2(MICRO_RIGHT, MICRO_Y - 4.0), color, 0.3)
	draw_line(Vector2(MICRO_LEFT, MICRO_Y + 1.5), Vector2(MICRO_RIGHT, MICRO_Y + 1.5), color, 0.3)
	if level == 0:
		draw_line(
			Vector2(MICRO_LEFT, MICRO_Y - 1.2), Vector2(MICRO_RIGHT, MICRO_Y - 1.2), color, 1.4
		)
		return
	var word := currency.microtext
	if level == 2:
		word = _misspelled(word)
	var line := ""
	while line.length() * MICRO_SIZE * 0.62 < MICRO_RIGHT - MICRO_LEFT:
		line += (_garbled(word) if level == 1 else word) + " "
	_text(Vector2(MICRO_LEFT, MICRO_Y), line, MICRO_SIZE, color, MICRO_RIGHT - MICRO_LEFT)


func _draw_watermark() -> void:
	var level := _level(GameEnums.Feature.WATERMARK)
	if level == 0:
		return
	var center := WINDOW_CENTER + (WATERMARK_OFFSET if level == 2 else Vector2.ZERO)
	if level == 1:
		for i in WATERMARK_BLUR_COPIES:
			var jitter := (
				Vector2.from_angle(TAU * i / WATERMARK_BLUR_COPIES) * WATERMARK_BLUR_SPREAD
			)
			draw_colored_polygon(
				_lighthouse(center + jitter, WATERMARK_SCALE),
				Color(WATERMARK_SHADE, WATERMARK_FAINT_ALPHA * 0.5)
			)
		return
	draw_colored_polygon(_lighthouse(center, WATERMARK_SCALE), Color(WATERMARK_SHADE, 0.55))
	draw_colored_polygon(
		_lighthouse(center + Vector2(1.5, 1.5), WATERMARK_SCALE * 0.8),
		Color(WATERMARK_SHADE.darkened(0.15), 0.35)
	)


func _draw_uv_glow() -> void:
	var level := _level(GameEnums.Feature.UV_INK)
	if level == 0:
		return
	var glow := UV_GLOW_WRONG if level == 2 else UV_GLOW_GENUINE
	var value := str(currency.denominations[note.denomination_index].value)
	var pos := EMBLEM_CENTER + Vector2(0, 92)
	_ink_alpha = 1.0
	for spread in [6, 3]:
		_text_centered(pos, value, 30, Color(glow, 0.18), spread)
	_text_centered(pos, value, 30, glow)


func _text(pos: Vector2, text: String, size: float, color: Color, width := -1.0) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var px_width := width * px_scale if width > 0.0 else -1.0
	draw_string(
		FONT,
		pos * px_scale,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		px_width,
		maxi(1, roundi(size * px_scale)),
		color
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(px_scale, px_scale))


func _text_centered(center: Vector2, text: String, size: float, color: Color, outline := 0) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font_size := maxi(1, roundi(size * px_scale))
	var pos := Vector2(0.0, center.y * px_scale)
	if outline > 0:
		draw_string_outline(
			FONT,
			pos,
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			center.x * px_scale * 2.0,
			font_size,
			roundi(outline * px_scale),
			color
		)
	else:
		draw_string(
			FONT,
			pos,
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			center.x * px_scale * 2.0,
			font_size,
			color
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(px_scale, px_scale))


func _misspelled(word: String) -> String:
	var index := _rng.randi_range(1, word.length() - 1)
	var replacement := word[index]
	while replacement == word[index]:
		replacement = GARBLE_CHARS[_rng.randi_range(0, GARBLE_CHARS.length() - 1)]
	word[index] = replacement
	return word


func _garbled(word: String) -> String:
	var result := ""
	for i in word.length():
		result += GARBLE_CHARS[_rng.randi_range(0, GARBLE_CHARS.length() - 1)]
	return result


func _lighthouse(origin: Vector2, scale_factor: float) -> PackedVector2Array:
	var shape := [
		Vector2(-14, 44),
		Vector2(14, 44),
		Vector2(8, -18),
		Vector2(12, -18),
		Vector2(12, -23),
		Vector2(6, -23),
		Vector2(6, -34),
		Vector2(0, -40),
		Vector2(-6, -34),
		Vector2(-6, -23),
		Vector2(-12, -23),
		Vector2(-12, -18),
		Vector2(-8, -18),
	]
	var points := PackedVector2Array()
	for p: Vector2 in shape:
		points.append(origin + p * scale_factor)
	return points


func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 64
	for i in steps:
		var t := TAU * i / steps
		points.append(center + Vector2(cos(t) * radii.x, sin(t) * radii.y))
	return points


func _offset(points: PackedVector2Array, delta: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(p + delta)
	return result
