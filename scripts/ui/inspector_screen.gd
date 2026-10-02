class_name InspectorScreen
extends Control

## 鑑定士モードの窓口画面(GameDesign.md 6章)

signal shift_finished(shift: InspectionShift)

const SCREEN_SIZE := Vector2(1280, 720)
const BILL_POS := Vector2(56, 168)
const MAT_MARGIN := 28.0
const MAT := Color(0.13, 0.19, 0.16)
const HEADER_POS := Vector2(56, 28)
const PANEL_POS := Vector2(860, 120)
const PANEL_WIDTH := 364.0
const TOOL_BUTTON_SIZE := Vector2(364, 50)
const VERDICT_BUTTON_SIZE := Vector2(176, 78)
const TIME_POS := Vector2(56, 92)
const STATUS_POS := Vector2(56, 640)
const HINT_POS := Vector2(56, 604)
## 裏のタブから戻った直後の大きな delta を数えない(docs/Pitfalls.md「Web版」)
const MAX_FRAME_SECONDS := 1.0
const PAUSE_SHADE := Color(0.05, 0.07, 0.06)
const PAUSE_BUTTON_SIZE := Vector2(280, 72)
const MODE_LABELS := {
	GameEnums.ViewMode.NORMAL: "目視",
	GameEnums.ViewMode.BACKLIGHT: "透過ライト",
	GameEnums.ViewMode.UV: "UVライト",
}

var _shift: InspectionShift
var _elapsed := 0.0
var _mode: GameEnums.ViewMode = GameEnums.ViewMode.NORMAL
var _view: BanknoteView
var _book: ReferenceBook
var _tool_box: VBoxContainer
var _tool_buttons := {}
var _progress_label: Label
var _score_label: Label
var _mode_label: Label
var _status_label: Label
var _time_label: Label
var _title_label: Label
var _hint_label: Label
var _pause: Control


func _ready() -> void:
	UiKit.fill_parent(self)
	_build()


func start(shift: InspectionShift) -> void:
	_shift = shift
	_title_label.text = shift.config.title
	_time_label.visible = shift.measures_time()
	_pause.visible = false
	_rebuild_tool_buttons()
	_book.setup(shift.currency)
	_book.visible = false
	_status_label.text = "窓口を開けました。持ち込まれた紙幣を確かめてください。"
	_show_current()


func _process(delta: float) -> void:
	if not _is_running() or _pause.visible or not _shift.measures_time():
		return
	_elapsed += minf(delta, MAX_FRAME_SECONDS)
	_update_time_label()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if _is_running():
				_pause.visible = true


func _is_running() -> bool:
	return _shift != null and not _shift.is_finished() and visible


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), UiKit.DESK)
	var bill_size := BanknotePainter.BILL_SIZE * BanknoteView.DISPLAY_SCALE
	var mat := Rect2(BILL_POS - Vector2.ONE * MAT_MARGIN, bill_size + Vector2.ONE * MAT_MARGIN * 2)
	draw_rect(mat, MAT)
	draw_rect(mat, UiKit.DESK_EDGE, false, 3.0)


func _show_current() -> void:
	var note := _shift.current_bill()
	_elapsed = 0.0
	_update_time_label()
	_view.loupe_enabled = false
	_view.show_note(_shift.currency, note)
	_set_mode(GameEnums.ViewMode.NORMAL)
	_progress_label.text = "%d / %d 枚目" % [_shift.current_index + 1, _shift.bills.size()]
	_score_label.text = "得点 %d" % _shift.score
	_hint_label.text = _shift.current_hint()
	_update_tools()


func _update_time_label() -> void:
	var bonus := InspectionShift.speed_bonus_for(_shift.config, _elapsed)
	_time_label.text = "経過 %.1f 秒　速さボーナス +%d" % [_elapsed, bonus]


func _on_tool_pressed(tool: GameEnums.Tool) -> void:
	if tool == GameEnums.Tool.NAKED_EYE:
		_view.loupe_enabled = false
		_set_mode(GameEnums.ViewMode.NORMAL)
		_update_tools()
		return
	match tool:
		GameEnums.Tool.LOUPE:
			_view.loupe_enabled = not _view.loupe_enabled
		GameEnums.Tool.BACKLIGHT:
			_toggle_mode(GameEnums.ViewMode.BACKLIGHT)
		GameEnums.Tool.UV:
			_toggle_mode(GameEnums.ViewMode.UV)
	_update_tools()


func _toggle_mode(mode: GameEnums.ViewMode) -> void:
	_set_mode(GameEnums.ViewMode.NORMAL if _mode == mode else mode)


func _set_mode(mode: GameEnums.ViewMode) -> void:
	_mode = mode
	_view.set_view_mode(mode)


func _judge(verdict: GameEnums.Verdict) -> void:
	_shift.judge(verdict, _elapsed)
	if verdict == GameEnums.Verdict.ACCEPT:
		_status_label.text = "紙幣を受け取りました。"
	else:
		_status_label.text = "紙幣を突き返しました。"
	if _shift.is_finished():
		_book.visible = false
		shift_finished.emit(_shift)
		return
	_show_current()


func _update_tools() -> void:
	for tool: GameEnums.Tool in _tool_buttons:
		var button: Button = _tool_buttons[tool]
		var active := _is_tool_active(tool)
		UiKit.set_button_color(button, UiKit.BUTTON_ACTIVE if active else UiKit.BUTTON)
	_mode_label.text = ("表示: %s%s" % [MODE_LABELS[_mode], "＋ルーペ" if _view.loupe_enabled else ""])


func _is_tool_active(tool: GameEnums.Tool) -> bool:
	match tool:
		GameEnums.Tool.NAKED_EYE:
			return _mode == GameEnums.ViewMode.NORMAL and not _view.loupe_enabled
		GameEnums.Tool.LOUPE:
			return _view.loupe_enabled
		GameEnums.Tool.BACKLIGHT:
			return _mode == GameEnums.ViewMode.BACKLIGHT
		GameEnums.Tool.UV:
			return _mode == GameEnums.ViewMode.UV
	return false


func _build() -> void:
	var header := HBoxContainer.new()
	header.position = HEADER_POS
	header.add_theme_constant_override("separation", 32)
	add_child(header)
	_title_label = UiKit.label("", 30)
	header.add_child(_title_label)
	_progress_label = UiKit.label("", 24, UiKit.TEXT_DIM)
	header.add_child(_progress_label)
	_score_label = UiKit.label("", 24, UiKit.TEXT_DIM)
	header.add_child(_score_label)

	_time_label = UiKit.label("", 20, UiKit.TEXT_DIM)
	_time_label.position = TIME_POS
	add_child(_time_label)

	_view = BanknoteView.new()
	_view.position = BILL_POS
	add_child(_view)

	_mode_label = UiKit.label("", 18, UiKit.TEXT_DIM)
	_mode_label.position = Vector2(BILL_POS.x, BILL_POS.y + _view.custom_minimum_size.y + 40)
	add_child(_mode_label)

	_hint_label = UiKit.label("", 20, UiKit.HINT)
	_hint_label.position = HINT_POS
	add_child(_hint_label)

	_status_label = UiKit.label("", 20)
	_status_label.position = STATUS_POS
	add_child(_status_label)

	_build_panel()

	_book = ReferenceBook.new()
	add_child(_book)

	_pause = _build_pause()
	add_child(_pause)


## 紙幣を隠して時間を止める。見本帳より手前に置く
func _build_pause() -> Control:
	var shade := ColorRect.new()
	shade.color = PAUSE_SHADE
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_top = 0.5
	box.anchor_right = 0.5
	box.anchor_bottom = 0.5
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	shade.add_child(box)
	var label := UiKit.label("一時停止中", 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var resume := UiKit.button("再開", 28, PAUSE_BUTTON_SIZE, UiKit.ACCEPT)
	resume.pressed.connect(func() -> void: _pause.visible = false)
	box.add_child(resume)
	shade.visible = false
	return shade


func _build_panel() -> void:
	var panel := VBoxContainer.new()
	panel.position = PANEL_POS
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.add_theme_constant_override("separation", 10)
	add_child(panel)

	panel.add_child(UiKit.label("道具", 20, UiKit.TEXT_DIM))
	_tool_box = VBoxContainer.new()
	_tool_box.add_theme_constant_override("separation", 10)
	panel.add_child(_tool_box)

	var book_button := UiKit.button("見本帳を開く", 20, TOOL_BUTTON_SIZE)
	book_button.pressed.connect(func() -> void: _book.visible = true)
	panel.add_child(book_button)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 24
	panel.add_child(spacer)

	var verdicts := HBoxContainer.new()
	verdicts.add_theme_constant_override("separation", 12)
	panel.add_child(verdicts)
	var accept := UiKit.button("受理", 28, VERDICT_BUTTON_SIZE, UiKit.ACCEPT)
	accept.pressed.connect(_judge.bind(GameEnums.Verdict.ACCEPT))
	verdicts.add_child(accept)
	var reject := UiKit.button("拒否", 28, VERDICT_BUTTON_SIZE, UiKit.REJECT)
	reject.pressed.connect(_judge.bind(GameEnums.Verdict.REJECT))
	verdicts.add_child(reject)


func _rebuild_tool_buttons() -> void:
	for child in _tool_box.get_children():
		child.queue_free()
	_tool_buttons.clear()
	_add_tool_button(_tool_box, GameEnums.Tool.NAKED_EYE, "目視")
	for tool_data in _shift.config.tools:
		_add_tool_button(_tool_box, tool_data.tool, tool_data.display_name)


func _add_tool_button(parent: Control, tool: GameEnums.Tool, label_text: String) -> void:
	var button := UiKit.button(label_text, 20, TOOL_BUTTON_SIZE)
	button.pressed.connect(_on_tool_pressed.bind(tool))
	parent.add_child(button)
	_tool_buttons[tool] = button
