class_name InspectionShift
extends RefCounted

## 鑑定士モードの1シフト(GameDesign.md 6章)。UIから独立した規則だけを持つ

var config: ShiftConfig
var currency: CurrencyData
var bills: Array[Banknote] = []
var current_index := 0
var score := 0
## { "note": Banknote, "verdict": GameEnums.Verdict, "points": int, "correct": bool,
##   "seconds": float, "speed_bonus": int }
var results: Array[Dictionary] = []


func _init(
	shift_config: ShiftConfig, currency_data: CurrencyData, rng: RandomNumberGenerator
) -> void:
	config = shift_config
	currency = currency_data
	if config.scripted_bills.is_empty():
		_deal_cpu_bills(rng)
	else:
		_deal_scripted_bills(rng)


func current_bill() -> Banknote:
	if is_finished():
		return null
	return bills[current_index]


## いまの紙幣に添えるヒント。無ければ空
func current_hint() -> String:
	if is_finished() or config.scripted_bills.is_empty():
		return ""
	return config.scripted_bills[current_index].hint


func measures_time() -> bool:
	return config.measures_time


func is_finished() -> bool:
	return current_index >= bills.size()


## seconds は紙幣が出てから判定するまでの秒数(一時停止中を除く)
func judge(verdict: GameEnums.Verdict, seconds := 0.0) -> Dictionary:
	var note := current_bill()
	var correct := (
		(note.is_genuine() and verdict == GameEnums.Verdict.ACCEPT)
		or (not note.is_genuine() and verdict == GameEnums.Verdict.REJECT)
	)
	var bonus := speed_bonus_for(config, seconds) if correct and config.measures_time else 0
	var points := points_for(config, note.is_genuine(), verdict) + bonus
	var result := {
		"note": note,
		"verdict": verdict,
		"points": points,
		"correct": correct,
		"seconds": seconds,
		"speed_bonus": bonus,
	}
	results.append(result)
	score += points
	current_index += 1
	return result


func total_seconds() -> float:
	var total := 0.0
	for result in results:
		total += result["seconds"]
	return total


func fake_count() -> int:
	var count := 0
	for note in bills:
		if not note.is_genuine():
			count += 1
	return count


static func points_for(cfg: ShiftConfig, genuine: bool, verdict: GameEnums.Verdict) -> int:
	if verdict == GameEnums.Verdict.ACCEPT:
		return cfg.score_accept_genuine if genuine else cfg.score_accept_fake
	return cfg.score_reject_genuine if genuine else cfg.score_reject_fake


static func speed_bonus_for(cfg: ShiftConfig, seconds: float) -> int:
	return maxi(cfg.speed_bonus_max - cfg.speed_bonus_per_second * floori(seconds), 0)


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
