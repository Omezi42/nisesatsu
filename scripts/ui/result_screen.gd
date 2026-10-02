class_name ResultScreen
extends Control

## シフトの結果(GameDesign.md 6章)。1枚ずつ正誤と、偽札ならどの要素が欠けていたかを示す

signal retry_requested

const SCREEN_SIZE := Vector2(1280, 720)
const CONTENT_POS := Vector2(80, 40)
const LIST_SIZE := Vector2(1120, 420)
const VERDICT_LABELS := {
	GameEnums.Verdict.ACCEPT: "受理",
	GameEnums.Verdict.REJECT: "拒否",
}

var _summary: Label
var _best: Label
var _ranking: Label
var _retry: Button
var _list: VBoxContainer


func _ready() -> void:
	UiKit.fill_parent(self)
	_build()


func show_shift(shift: InspectionShift, new_record: bool) -> void:
	for child in _list.get_children():
		child.queue_free()
	_ranking.text = ""
	var correct := 0
	for i in shift.results.size():
		var result: Dictionary = shift.results[i]
		if result["correct"]:
			correct += 1
		_list.add_child(_row(shift, i, result))
	_summary.text = (
		"得点 %d　　正解 %d / %d　　偽札 %d 枚"
		% [shift.score, correct, shift.results.size(), shift.fake_count()]
	)
	if shift.measures_time():
		_summary.text += "　　合計 %.1f 秒" % shift.total_seconds()
	_best.add_theme_color_override("font_color", UiKit.HINT if new_record else UiKit.TEXT_DIM)
	if not shift.config.records_best_score:
		_best.text = "研修の得点はベストスコアに記録されません"
		_retry.text = "本番シフトへ"
		return
	_best.text = ("ベストスコア更新！" if new_record else "ベストスコア %d" % BestScore.best())
	_retry.text = "次のシフトへ"


func show_ranking(text: String, ok: bool) -> void:
	_ranking.text = text
	_ranking.add_theme_color_override("font_color", UiKit.TEXT_DIM if ok else UiKit.BAD)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), UiKit.DESK)


func _row(shift: InspectionShift, index: int, result: Dictionary) -> Control:
	var currency := shift.currency
	var note: Banknote = result["note"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var mark := "○" if result["correct"] else "×"
	row.add_child(UiKit.label(mark, 22, UiKit.GOOD if result["correct"] else UiKit.BAD))
	var value := currency.denominations[note.denomination_index].value
	var kind := "本物" if note.is_genuine() else "偽札"
	var verdict: String = VERDICT_LABELS[result["verdict"]]
	row.add_child(
		UiKit.label("%2d.　%d %s　%s　→ %s" % [index + 1, value, currency.unit, kind, verdict], 20)
	)
	var points: int = result["points"]
	row.add_child(UiKit.label("%+d" % points, 20, UiKit.GOOD if points > 0 else UiKit.BAD))
	if shift.measures_time():
		var timing := "%.1f 秒" % result["seconds"]
		if result["speed_bonus"] > 0:
			timing += "（速さ +%d）" % result["speed_bonus"]
		row.add_child(UiKit.label(timing, 18, UiKit.TEXT_DIM))
	if not note.is_genuine():
		var defects: Array[String] = []
		for feature in note.defects():
			var data := currency.feature_data(feature)
			defects.append(data.defect_description(note.level(feature)))
		row.add_child(UiKit.label("欠陥: " + "／".join(defects), 18, UiKit.TEXT_DIM))
	return row


func _build() -> void:
	var root := VBoxContainer.new()
	root.position = CONTENT_POS
	root.add_theme_constant_override("separation", 16)
	add_child(root)
	root.add_child(UiKit.label("シフト終了", 34))
	_summary = UiKit.label("", 24)
	root.add_child(_summary)
	_best = UiKit.label("", 22, UiKit.TEXT_DIM)
	root.add_child(_best)
	_ranking = UiKit.label("", 18, UiKit.TEXT_DIM)
	root.add_child(_ranking)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = LIST_SIZE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	_retry = UiKit.button("", 24, Vector2(260, 64), UiKit.ACCEPT)
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	root.add_child(_retry)
