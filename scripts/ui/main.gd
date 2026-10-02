extends Control

## タイトル → 鑑定シフト → 結果 の画面切り替え

const CURRENCY_PATH := "res://data/lumeria.tres"
const SHIFT_PATH := "res://data/shift_default.tres"
const TRAINING_PATH := "res://data/shift_training.tres"
const START_BUTTON_SIZE := Vector2(280, 72)
const TITLE_POS := Vector2(120, 150)
const RULES := (
	"窓口に持ち込まれるルメリア紙幣を、1枚ずつ受理するか拒否するか決めてください。\n"
	+ "偽札が混ざっています。ルーペ・透過ライト・UVライトは回数に限りがあります。\n"
	+ "本物を拒否しても減点です。迷ったら見本帳と見比べましょう。"
)

var _currency: CurrencyData = load(CURRENCY_PATH)
var _config: ShiftConfig = load(SHIFT_PATH)
var _training: ShiftConfig = load(TRAINING_PATH)
var _best_label: Label
var _title: Control
var _inspector: InspectorScreen
var _result: ResultScreen


func _ready() -> void:
	UiKit.fill_parent(self)
	_title = _build_title()
	_inspector = InspectorScreen.new()
	_inspector.shift_finished.connect(_on_shift_finished)
	add_child(_inspector)
	_result = ResultScreen.new()
	_result.retry_requested.connect(_start_shift.bind(_config))
	add_child(_result)
	_show_title()


func _show_title() -> void:
	_best_label.text = "ベストスコア %d" % BestScore.best() if BestScore.has_record() else ""
	_show_only(_title)


func _start_shift(config: ShiftConfig) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_show_only(_inspector)
	_inspector.start(InspectionShift.new(config, _currency, rng))


func _on_shift_finished(shift: InspectionShift) -> void:
	var new_record := shift.config.records_best_score and BestScore.submit(shift.score)
	_result.show_shift(shift, new_record)
	_show_only(_result)


func _show_only(screen: Control) -> void:
	for child in [_title, _inspector, _result]:
		child.visible = child == screen


func _build_title() -> Control:
	var screen := ColorRect.new()
	screen.color = UiKit.DESK
	add_child(screen)
	UiKit.fill_parent(screen)
	var box := VBoxContainer.new()
	box.position = TITLE_POS
	box.add_theme_constant_override("separation", 24)
	screen.add_child(box)
	box.add_child(UiKit.label("ニセサツ", 64))
	box.add_child(UiKit.label("鑑定士モード（試作）", 28, UiKit.TEXT_DIM))
	box.add_child(UiKit.label(RULES, 20))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	box.add_child(buttons)
	var training := UiKit.button("研修", 28, START_BUTTON_SIZE)
	training.pressed.connect(_start_shift.bind(_training))
	buttons.add_child(training)
	var start := UiKit.button("本番シフト", 28, START_BUTTON_SIZE, UiKit.ACCEPT)
	start.pressed.connect(_start_shift.bind(_config))
	buttons.add_child(start)
	_best_label = UiKit.label("", 22, UiKit.TEXT_DIM)
	box.add_child(_best_label)
	return screen
