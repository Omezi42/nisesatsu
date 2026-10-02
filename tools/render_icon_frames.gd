extends SceneTree

## unityroom のアイコン(ルーペで紙幣を拡大するGIF)のコマを書き出す。tools/make_icon.sh から呼ぶ

const OUT_DIR := "res://build/icon_frames/"
const CANVAS := 512
const BILL_WIDTH := 460.0
const ZOOM_MAX := 5.0
const RADIUS := 84.0
const MARGIN := 60.0
const FRAMES := 72
const ROSETTE := Vector2(300, 140)
const MICRO_A := Vector2(170, 283)
const MICRO_B := Vector2(430, 283)

var _s := BILL_WIDTH / BanknotePainter.BILL_SIZE.x
var _origin: Vector2
var _main_vp: SubViewport
var _loupe_vp: SubViewport
var _canvas: SubViewport
var _drawer: Node2D
var _center := ROSETTE
var _zoom := 1.0
var _radius := 0.0


func _init() -> void:
	_run.call_deferred()


func _layer(px_scale: float, note: Banknote, currency: CurrencyData) -> SubViewport:
	var vp := SubViewport.new()
	var margin := MARGIN * px_scale
	vp.size = Vector2i((BanknotePainter.BILL_SIZE * px_scale + Vector2.ONE * margin * 2).ceil())
	var back := ColorRect.new()
	back.color = UiKit.DESK
	back.size = Vector2(vp.size)
	vp.add_child(back)
	var painter := BanknotePainter.new()
	painter.px_scale = px_scale
	painter.currency = currency
	painter.note = note
	painter.position = Vector2.ONE * margin
	vp.add_child(painter)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(vp)
	return vp


func _draw_frame() -> void:
	var bill := Rect2(_origin, BanknotePainter.BILL_SIZE * _s)
	_drawer.draw_rect(Rect2(Vector2.ZERO, Vector2(CANVAS, CANVAS)), UiKit.DESK)
	_drawer.draw_rect(
		Rect2(bill.position + BanknoteView.SHADOW_OFFSET * 0.6, bill.size), BanknoteView.SHADOW
	)
	_drawer.draw_texture(_main_vp.get_texture(), _origin - Vector2.ONE * MARGIN * _s)
	if _radius <= 0.5:
		return
	var loupe_scale := _s * ZOOM_MAX
	var tex_size := Vector2(_loupe_vp.size)
	var screen_center := _origin + _center * _s
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in BanknoteView.LOUPE_SEGMENTS:
		var dir := Vector2.from_angle(TAU * i / BanknoteView.LOUPE_SEGMENTS) * _radius
		points.append(screen_center + dir)
		var logical := _center + dir / (_s * _zoom)
		uvs.append((logical + Vector2.ONE * MARGIN) * loupe_scale / tex_size)
	_drawer.draw_circle(
		screen_center + BanknoteView.SHADOW_OFFSET,
		_radius + BanknoteView.LOUPE_RIM_WIDTH,
		BanknoteView.SHADOW
	)
	_drawer.draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, _loupe_vp.get_texture())
	_drawer.draw_arc(
		screen_center,
		_radius,
		0,
		TAU,
		BanknoteView.LOUPE_SEGMENTS,
		BanknoteView.LOUPE_RIM,
		BanknoteView.LOUPE_RIM_WIDTH,
		true
	)


func _ease(t: float) -> float:
	return smoothstep(0.0, 1.0, clampf(t, 0.0, 1.0))


func _pose(f: int) -> void:
	_center = ROSETTE
	_zoom = 1.0
	_radius = RADIUS
	if f < 8:
		_radius = RADIUS * _ease(f / 8.0)
	elif f < 26:
		_zoom = lerpf(1.0, ZOOM_MAX, _ease((f - 8) / 18.0))
	elif f < 32:
		_zoom = ZOOM_MAX
	elif f < 46:
		_zoom = ZOOM_MAX
		_center = ROSETTE.lerp(MICRO_A, _ease((f - 32) / 14.0))
	elif f < 62:
		_zoom = ZOOM_MAX
		_center = MICRO_A.lerp(MICRO_B, _ease((f - 46) / 16.0))
	else:
		_zoom = ZOOM_MAX
		_center = MICRO_B
		_radius = RADIUS * (1.0 - _ease((f - 62) / 8.0))


func _run() -> void:
	var currency: CurrencyData = load("res://data/lumeria.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var note := BanknoteFactory.make_genuine(currency, rng)
	note.denomination_index = 2
	_origin = (Vector2(CANVAS, CANVAS) - BanknotePainter.BILL_SIZE * _s) / 2.0
	_main_vp = _layer(_s, note, currency)
	_loupe_vp = _layer(_s * ZOOM_MAX, note, currency)
	_canvas = SubViewport.new()
	_canvas.size = Vector2i(CANVAS, CANVAS)
	_drawer = Node2D.new()
	_drawer.draw.connect(_draw_frame)
	_canvas.add_child(_drawer)
	root.add_child(_canvas)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for i in 4:
		await process_frame
	for f in FRAMES:
		_pose(f)
		_drawer.queue_redraw()
		_canvas.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		_canvas.get_texture().get_image().save_png(
			ProjectSettings.globalize_path(OUT_DIR) + "f_%03d.png" % f
		)
	quit()
