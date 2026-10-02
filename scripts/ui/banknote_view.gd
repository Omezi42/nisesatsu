class_name BanknoteView
extends Control

## 紙幣の表示とルーペ。ルーペは高解像度で描いた別の SubViewport を円形に切り抜いて重ねる

const DISPLAY_SCALE := 1.2
const LOUPE_SCALE := 4.0
const LOUPE_RADIUS := 92.0
const LOUPE_SEGMENTS := 64
const LOUPE_RIM := Color(0.12, 0.11, 0.10)
const LOUPE_RIM_WIDTH := 6.0
const SHADOW := Color(0, 0, 0, 0.45)
const SHADOW_OFFSET := Vector2(6, 8)

var loupe_enabled := false:
	set(value):
		loupe_enabled = value
		queue_redraw()

var _main := _make_layer(DISPLAY_SCALE)
var _loupe := _make_layer(LOUPE_SCALE)


func _ready() -> void:
	custom_minimum_size = BanknotePainter.BILL_SIZE * DISPLAY_SCALE
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_note(currency: CurrencyData, note: Banknote) -> void:
	for layer in [_main, _loupe]:
		layer.painter.currency = currency
		layer.painter.note = note
	_refresh()


func set_view_mode(mode: GameEnums.ViewMode) -> void:
	for layer in [_main, _loupe]:
		layer.painter.view_mode = mode
	_refresh()


func _gui_input(event: InputEvent) -> void:
	if loupe_enabled and event is InputEventMouseMotion:
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		queue_redraw()


func _draw() -> void:
	if _main.painter.note == null:
		return
	var bill_rect := Rect2(Vector2.ZERO, BanknotePainter.BILL_SIZE * DISPLAY_SCALE)
	draw_rect(Rect2(bill_rect.position + SHADOW_OFFSET, bill_rect.size), SHADOW)
	draw_texture(_main.viewport.get_texture(), Vector2.ZERO)
	var mouse := get_local_mouse_position()
	if loupe_enabled and bill_rect.has_point(mouse):
		_draw_loupe(mouse)


func _draw_loupe(center: Vector2) -> void:
	var texture_size := Vector2(_loupe.viewport.size)
	var focus := center / DISPLAY_SCALE * LOUPE_SCALE
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in LOUPE_SEGMENTS:
		var dir := Vector2.from_angle(TAU * i / LOUPE_SEGMENTS) * LOUPE_RADIUS
		points.append(center + dir)
		uvs.append((focus + dir) / texture_size)
	draw_circle(center + SHADOW_OFFSET, LOUPE_RADIUS + LOUPE_RIM_WIDTH, SHADOW)
	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, _loupe.viewport.get_texture())
	draw_arc(center, LOUPE_RADIUS, 0, TAU, LOUPE_SEGMENTS, LOUPE_RIM, LOUPE_RIM_WIDTH, true)


func _refresh() -> void:
	for layer in [_main, _loupe]:
		layer.painter.queue_redraw()
		layer.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	queue_redraw()


func _make_layer(px_scale: float) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = Vector2i((BanknotePainter.BILL_SIZE * px_scale).ceil())
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var painter := BanknotePainter.new()
	painter.px_scale = px_scale
	viewport.add_child(painter)
	add_child(viewport)
	return {"viewport": viewport, "painter": painter}
