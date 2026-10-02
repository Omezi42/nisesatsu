class_name InspectionShift
extends RefCounted

## 鑑定士モードの1シフト(GameDesign.md 6章)。UIから独立した規則だけを持つ

var config: ShiftConfig
var currency: CurrencyData
var bills: Array[Banknote] = []
var current_index := 0
var score := 0
## { "note": Banknote, "verdict": GameEnums.Verdict, "points": int, "correct": bool }
var results: Array[Dictionary] = []

var _uses_left := {}
var _unlocked := {}


func _init(
	shift_config: ShiftConfig, currency_data: CurrencyData, rng: RandomNumberGenerator
) -> void:
	config = shift_config
	currency = currency_data
	if config.scripted_bills.is_empty():
		_deal_cpu_bills(rng)
	else:
		_deal_scripted_bills(rng)
	for tool_data in config.tools:
		_uses_left[tool_data.tool] = tool_data.uses_per_shift


func current_bill() -> Banknote:
	if is_finished():
		return null
	return bills[current_index]


## いまの紙幣に添えるヒント。無ければ空
func current_hint() -> String:
	if is_finished() or config.scripted_bills.is_empty():
		return ""
	return config.scripted_bills[current_index].hint


func has_time_limit() -> bool:
	return config.seconds_per_bill > 0.0


func is_finished() -> bool:
	return current_index >= bills.size()


func uses_left(tool: GameEnums.Tool) -> int:
	return _uses_left.get(tool, 0)


func is_unlocked(tool: GameEnums.Tool) -> bool:
	return tool == GameEnums.Tool.NAKED_EYE or _unlocked.has(tool)


## いま見ている紙幣で道具を使えるようにする。使えたら true
func use_tool(tool: GameEnums.Tool) -> bool:
	if is_unlocked(tool):
		return true
	if uses_left(tool) <= 0:
		return false
	_uses_left[tool] -= 1
	_unlocked[tool] = true
	return true


func judge(verdict: GameEnums.Verdict) -> Dictionary:
	var note := current_bill()
	var points := points_for(config, note.is_genuine(), verdict)
	var correct := (
		(note.is_genuine() and verdict == GameEnums.Verdict.ACCEPT)
		or (not note.is_genuine() and verdict == GameEnums.Verdict.REJECT)
	)
	var result := {"note": note, "verdict": verdict, "points": points, "correct": correct}
	results.append(result)
	score += points
	current_index += 1
	_unlocked.clear()
	return result


func fake_count() -> int:
	var count := 0
	for note in bills:
		if not note.is_genuine():
			count += 1
	return count


static func points_for(cfg: ShiftConfig, genuine: bool, verdict: GameEnums.Verdict) -> int:
	match verdict:
		GameEnums.Verdict.ACCEPT:
			return cfg.score_accept_genuine if genuine else cfg.score_accept_fake
		GameEnums.Verdict.REJECT:
			return cfg.score_reject_genuine if genuine else cfg.score_reject_fake
	return cfg.score_timeout


func _deal_cpu_bills(rng: RandomNumberGenerator) -> void:
	var fake_flags := _fake_flags(rng)
	var last_index := maxi(config.bill_count - 1, 1)
	for i in config.bill_count:
		if fake_flags[i]:
			var budget := roundi(
				lerpf(config.cpu_budget_start, config.cpu_budget_end, float(i) / last_index)
			)
			bills.append(BanknoteFactory.make_fake(currency, budget, config, rng))
		else:
			bills.append(BanknoteFactory.make_genuine(currency, rng))


func _deal_scripted_bills(rng: RandomNumberGenerator) -> void:
	for scripted in config.scripted_bills:
		if scripted.fake:
			bills.append(
				BanknoteFactory.make_with_defect(
					currency, scripted.defect_feature, scripted.defect_level, rng
				)
			)
		else:
			bills.append(BanknoteFactory.make_genuine(currency, rng))


func _fake_flags(rng: RandomNumberGenerator) -> Array[bool]:
	var fakes := mini(rng.randi_range(config.fake_min, config.fake_max), config.bill_count)
	var flags: Array[bool] = []
	for i in config.bill_count:
		flags.append(i < fakes)
	for i in range(flags.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := flags[i]
		flags[i] = flags[j]
		flags[j] = swap
	return flags
