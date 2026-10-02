extends SceneTree

const CURRENCY_PATH := "res://data/lumeria.tres"
const SHIFT_PATH := "res://data/shift_default.tres"
const TRAINING_PATH := "res://data/shift_training.tres"
const TEST_BEST_PATH := "user://test_best_score.cfg"
const SAMPLE_SHIFTS := 200

var _failures := 0
var _currency: CurrencyData
var _config: ShiftConfig


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_currency = load(CURRENCY_PATH)
	_config = load(SHIFT_PATH)
	_check(_currency != null and _config != null, "データが読める")
	if _failures == 0:
		_test_data()
		_test_genuine()
		_test_fakes()
		_test_shift_composition()
		_test_tools()
		_test_scoring()
		_test_training()
		_test_best_score()

	if _failures > 0:
		printerr("tests FAILED: ", _failures)
		quit(1)
		return
	print("tests passed")
	quit(0)


func _test_data() -> void:
	_check(_currency.features.size() == GameEnums.Feature.size(), "全要素のデータがある")
	_check(_currency.denominations.size() > 0, "券種がある")
	_check(_config.tools.size() > 0, "道具がある")
	for data in _currency.features:
		_check(data.defect_descriptions.size() == CurrencyData.MAX_LEVEL, "欠陥の説明が揃う")
	_check(_config.cpu_budget_end < _currency.full_cost(), "CPUの予算では本物を作れない")


func _test_genuine() -> void:
	var rng := _rng(1)
	for i in 50:
		var note := BanknoteFactory.make_genuine(_currency, rng)
		_check(note.is_genuine(), "本物に欠陥がない")
		_check(_currency.issuer_codes.has(note.issuer_code), "本物の発行局コードは一覧にある")


func _test_fakes() -> void:
	var rng := _rng(2)
	for budget in range(0, _currency.full_cost() + 1):
		var note := BanknoteFactory.make_fake(_currency, budget, _config, rng)
		_check(not note.is_genuine(), "偽札には欠陥がある (予算 %d)" % budget)
		_check(_cost_of(note) <= budget, "予算を超えない (予算 %d)" % budget)
		var serial_ok := _currency.issuer_codes.has(note.issuer_code)
		var serial_level := note.level(GameEnums.Feature.SERIAL)
		_check(serial_ok == (serial_level == CurrencyData.MAX_LEVEL), "記番号の再現度とコードが一致する")


func _test_shift_composition() -> void:
	for i in SAMPLE_SHIFTS:
		var shift := InspectionShift.new(_config, _currency, _rng(100 + i))
		_check(shift.bills.size() == _config.bill_count, "紙幣の枚数")
		var fakes := shift.fake_count()
		_check(fakes >= _config.fake_min and fakes <= _config.fake_max, "偽札の枚数が範囲内")


func _test_tools() -> void:
	for tool_data in _config.tools:
		_check(tool_data.tool != GameEnums.Tool.NAKED_EYE, "目視は道具の一覧に入れない")
		_check(not tool_data.display_name.is_empty(), "道具に表示名がある")


func _test_scoring() -> void:
	var shift := InspectionShift.new(_config, _currency, _rng(4))
	var expected := 0
	while not shift.is_finished():
		var genuine := shift.current_bill().is_genuine()
		var verdict := GameEnums.Verdict.ACCEPT if genuine else GameEnums.Verdict.REJECT
		var result := shift.judge(verdict)
		_check(result["correct"], "正しい判定は正解になる")
		expected += _config.score_accept_genuine if genuine else _config.score_reject_fake
		expected += _config.speed_bonus_max
	_check(shift.score == expected, "満点の得点")
	_check(
		(
			InspectionShift.points_for(_config, false, GameEnums.Verdict.ACCEPT)
			== _config.score_accept_fake
		),
		"見逃しの減点"
	)
	_check(
		(
			InspectionShift.points_for(_config, true, GameEnums.Verdict.REJECT)
			== _config.score_reject_genuine
		),
		"誤拒否の減点"
	)
	_test_speed_bonus()


func _test_speed_bonus() -> void:
	_check(InspectionShift.speed_bonus_for(_config, 0.0) == _config.speed_bonus_max, "即答は満額")
	var expected := _config.speed_bonus_max - _config.speed_bonus_per_second * 3
	_check(InspectionShift.speed_bonus_for(_config, 3.9) == expected, "速さボーナスは秒の切り捨てで減る")
	_check(InspectionShift.speed_bonus_for(_config, 999.0) == 0, "速さボーナスは0未満にならない")
	var shift := InspectionShift.new(_config, _currency, _rng(6))
	var genuine := shift.current_bill().is_genuine()
	var wrong := GameEnums.Verdict.REJECT if genuine else GameEnums.Verdict.ACCEPT
	_check(shift.judge(wrong, 1.0)["speed_bonus"] == 0, "間違いには速さボーナスを付けない")
	genuine = shift.current_bill().is_genuine()
	var right := GameEnums.Verdict.ACCEPT if genuine else GameEnums.Verdict.REJECT
	var bonus: int = shift.judge(right, 2.0)["speed_bonus"]
	_check(bonus == InspectionShift.speed_bonus_for(_config, 2.0), "正解には速さボーナス")
	_check(is_equal_approx(shift.total_seconds(), 3.0), "合計時間")


func _test_training() -> void:
	var training: ShiftConfig = load(TRAINING_PATH)
	_check(training != null, "研修シフトが読める")
	if training == null:
		return
	_check(not training.records_best_score, "研修はベストスコアに記録しない")
	var shift := InspectionShift.new(training, _currency, _rng(5))
	_check(not shift.measures_time(), "研修は秒数を計らない")
	_check(shift.bills.size() == training.scripted_bills.size(), "研修の枚数は固定の並びのとおり")
	var seen_tools := {}
	for i in shift.bills.size():
		var scripted: ScriptedBill = training.scripted_bills[i]
		var note := shift.bills[i]
		_check(not shift.current_hint().is_empty(), "研修の紙幣にはヒントがある")
		_check(note.is_genuine() != scripted.fake, "研修の本物・偽札が並びのとおり")
		if scripted.fake:
			_check(note.defects().size() == 1, "研修の偽札は欠陥が1か所")
			_check(note.level(scripted.defect_feature) == scripted.defect_level, "研修の再現度")
			seen_tools[_currency.feature_data(scripted.defect_feature).tool] = true
		shift.judge(GameEnums.Verdict.ACCEPT)
	_check(seen_tools.size() == GameEnums.Tool.size(), "研修で全ての道具を使う偽札が出る")


func _test_best_score() -> void:
	DirAccess.remove_absolute(TEST_BEST_PATH)
	_check(not BestScore.has_record(TEST_BEST_PATH), "初回は記録なし")
	_check(BestScore.submit(-50, TEST_BEST_PATH), "初回はマイナスでも記録する")
	_check(BestScore.submit(300, TEST_BEST_PATH), "上回れば更新")
	_check(not BestScore.submit(300, TEST_BEST_PATH), "同点は更新しない")
	_check(not BestScore.submit(100, TEST_BEST_PATH), "下回れば更新しない")
	_check(BestScore.best(TEST_BEST_PATH) == 300, "最高得点が残る")
	DirAccess.remove_absolute(TEST_BEST_PATH)


func _cost_of(note: Banknote) -> int:
	var total := 0
	for data in _currency.features:
		total += note.level(data.feature) * data.cost_per_level
	return total


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAILED: ", message)
