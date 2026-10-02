class_name ReferenceBook
extends Control

## 見本帳(GameDesign.md 6章)。本物の見本を道具ごとの見え方で見せ、発行局コード一覧を載せる。開いている間も時間は進む

const DIM := Color(0, 0, 0, 0.6)
const PANEL_RECT := Rect2(40, 40, 1200, 640)
const SAMPLE_SEED := 20261002
const TAB_SIZE := Vector2(130, 44)
const MODES := [
	[GameEnums.ViewMode.NORMAL, "目視"],
	[GameEnums.ViewMode.BACKLIGHT, "透過ライト"],
	[GameEnums.ViewMode.UV, "UVライト"],
]

var _currency: CurrencyData
var _samples: Array[Banknote] = []
var _view: BanknoteView
var _denom_box: HBoxContainer
var _codes_label: Label


func _ready() -> void:
	UiKit.fill_parent(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


func setup(currency: CurrencyData) -> void:
	_currency = currency
	_samples.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = SAMPLE_SEED
	for child in _denom_box.get_children():
		child.queue_free()
	for i in currency.denominations.size():
		var note := BanknoteFactory.make_genuine(currency, rng)
		note.denomination_index = i
		_samples.append(note)
		var label_text := "%d %s" % [currency.denominations[i].value, currency.unit]
		var button := UiKit.button(label_text, 18, TAB_SIZE)
		button.pressed.connect(_show_sample.bind(i))
		_denom_box.add_child(button)
	_codes_label.text = "発行局コード（記番号の先頭2文字）\n%s" % "　".join(currency.issuer_codes)
	_show_sample(0)


func _draw() -> void:
	draw_rect(get_rect(), DIM)
	draw_rect(PANEL_RECT, UiKit.PANEL)
	draw_rect(PANEL_RECT, UiKit.DESK_EDGE, false, 3.0)


func _show_sample(index: int) -> void:
	_view.show_note(_currency, _samples[index])


func _build() -> void:
	var root := VBoxContainer.new()
	root.position = PANEL_RECT.position + Vector2(32, 24)
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 24)
	root.add_child(title_row)
	title_row.add_child(UiKit.label("見本帳　— 本物の見本 —", 28))
	var close := UiKit.button("閉じる", 20, Vector2(120, 44))
	close.pressed.connect(func() -> void: visible = false)
	title_row.add_child(close)

	_denom_box = HBoxContainer.new()
	_denom_box.add_theme_constant_override("separation", 8)
	root.add_child(_denom_box)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	root.add_child(body)
	_view = BanknoteView.new()
	_view.loupe_enabled = true
	body.add_child(_view)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	body.add_child(side)
	side.add_child(UiKit.label("見え方", 18, UiKit.TEXT_DIM))
	for entry in MODES:
		var button := UiKit.button(entry[1], 18, TAB_SIZE)
		button.pressed.connect(_view.set_view_mode.bind(entry[0]))
		side.add_child(button)
	side.add_child(UiKit.label("見本帳ではルーペを\n自由に使えます", 16, UiKit.TEXT_DIM))

	_codes_label = UiKit.label("", 20)
	root.add_child(_codes_label)
