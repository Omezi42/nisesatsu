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
const TIMER_POS := Vector2(56, 104)
const TIMER_SIZE := Vector2(720, 14)
const TIMER_WARN_SECONDS := 5.0
const STATUS_POS := Vector2(56, 640)
const MODE_LABELS := {
	GameEnums.ViewMode.NORMAL: "目視",
	GameEnums.ViewMode.BACKLIGHT: "透過ライト",
	GameEnums.ViewMode.UV: "UVライト",
}

var _shift: InspectionShift
var _time_left := 0.0
var _mode: GameEnums.ViewMode = GameEnums.ViewMode.NORMAL
var _view: BanknoteView
var _book: ReferenceBook
var _tool_box: VBoxContainer
var _tool_buttons := {}
var _tool_names := {}
var _progress_label: Label
var _score_label: Label
var _mode_label: Label
var _status_label: Label
var _timer_bar: ProgressBar


func _ready() -> void:
	UiKit.fill_parent(self)
	_build()


func start(shift: InspectionShift) -> void:
	_shift = shift
	_rebuild_tool_buttons()
	_book.setup(shift.currency)
	_book.visible = false
	_status_label.text = "窓口を開けました。持ち込まれた紙幣を確かめてください。"
	_show_current()


func _process(delta: float) -> void:
	if _shift == null or _shift.is_finished() or not visible:
		return
	_time_left -= delta
	_timer_bar.value = _time_left
	_timer_bar.modulate = UiKit.BAD if _time_left <= TIMER_WARN_SECONDS else Color.WHITE
	if _time_left <= 0.0:
		_judge(GameEnums.Verdict.TIMEOUT)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), UiKit.DESK)
	var bill_size := BanknotePainter.BILL_SIZE * BanknoteView.DISPLAY_SCALE
	var mat := Rect2(BILL_POS - Vector2.ONE * MAT_MARGIN, bill_size + Vector2.ONE * MAT_MARGIN * 2)
	draw_rect(mat, MAT)
	draw_rect(mat, UiKit.DESK_EDGE, false, 3.0)


func _show_current() -> void:
	var note := _shift.current_bill()
	_time_left = _shift.config.seconds_per_bill
	_timer_bar.max_value = _shift.config.seconds_per_bill
	_view.loupe_enabled = false
	_view.show_note(_shift.currency, note)
	_set_mode(GameEnums.ViewMode.NORMAL)
	_progress_label.text = "%d / %d 枚目" % [_shift.current_index + 1, _shift.bills.size()]
	_score_label.text = "得点 %d" % _shift.score
	_update_tools()


func _on_tool_pressed(tool: GameEnums.Tool) -> void:
	if tool == GameEnums.Tool.NAKED_EYE:
		_view.loupe_enabled = false
		_set_mode(GameEnums.ViewMode.NORMAL)
		_update_tools()
		return
	if not _shift.use_tool(tool):
		_status_label.text = "%sはもう使えません。" % _tool_names[tool]
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
	_shift.judge(verdict)
	match verdict:
		GameEnums.Verdict.ACCEPT:
			_status_label.text = "紙幣を受け取りました。"
		GameEnums.Verdict.REJECT:
			_status_label.text = "紙幣を突き返しました。"
		_:
			_status_label.text = "時間切れ。客は待ちきれずに帰ってしまった。"
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
		if tool == GameEnums.Tool.NAKED_EYE:
			continue
		var unlocked := _shift.is_unlocked(tool)
		var suffix := "この紙幣は使用済み" if unlocked else "残り %d" % _shift.uses_left(tool)
		button.text = "%s　（%s）" % [_tool_names[tool], suffix]
		button.disabled = not unlocked and _shift.uses_left(tool) <= 0
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
	header.add_child(UiKit.label("鑑定窓口", 30))
	_progress_label = UiKit.label("", 24, UiKit.TEXT_DIM)
	header.add_child(_progress_label)
	_score_label = UiKit.label("", 24, UiKit.TEXT_DIM)
	header.add_child(_score_label)

	_timer_bar = ProgressBar.new()
	_timer_bar.position = TIMER_POS
	_timer_bar.size = TIMER_SIZE
	_timer_bar.show_percentage = false
	_timer_bar.add_theme_stylebox_override("background", UiKit.panel_style(UiKit.DESK_EDGE))
	_timer_bar.add_theme_stylebox_override("fill", UiKit.panel_style(UiKit.TEXT_DIM))
	add_child(_timer_bar)

	_view = BanknoteView.new()
	_view.position = BILL_POS
	add_child(_view)

	_mode_label = UiKit.label("", 18, UiKit.TEXT_DIM)
	_mode_label.position = Vector2(BILL_POS.x, BILL_POS.y + _view.custom_minimum_size.y + 40)
	add_child(_mode_label)

	_status_label = UiKit.label("", 20)
	_status_label.position = STATUS_POS
	add_child(_status_label)

	_build_panel()

	_book = ReferenceBook.new()
	add_child(_book)


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
	_tool_names.clear()
	_add_tool_button(_tool_box, GameEnums.Tool.NAKED_EYE, "目視")
	for tool_data in _shift.config.tools:
		_add_tool_button(_tool_box, tool_data.tool, tool_data.display_name)


func _add_tool_button(parent: Control, tool: GameEnums.Tool, label_text: String) -> void:
	var button := UiKit.button(label_text, 20, TOOL_BUTTON_SIZE)
	button.pressed.connect(_on_tool_pressed.bind(tool))
	parent.add_child(button)
	_tool_buttons[tool] = button
	_tool_names[tool] = label_text
