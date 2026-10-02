class_name BanknoteFactory
extends RefCounted

const SERIAL_MAX := 999999
const CODE_LETTERS := "ABCDEFGHJKLMNPRSTUVWXYZ"


static func make_genuine(currency: CurrencyData, rng: RandomNumberGenerator) -> Banknote:
	var note := Banknote.new()
	note.denomination_index = rng.randi_range(0, currency.denominations.size() - 1)
	note.issuer_code = currency.issuer_codes[rng.randi_range(0, currency.issuer_codes.size() - 1)]
	note.serial_number = rng.randi_range(0, SERIAL_MAX)
	note.art_seed = rng.randi()
	for data in currency.features:
		note.levels[data.feature] = CurrencyData.MAX_LEVEL
	return note


## CPU の偽造者。予算を「目視で見られる要素」から優先して使う(GameDesign.md 6.1節)
static func make_fake(
	currency: CurrencyData, budget: int, config: ShiftConfig, rng: RandomNumberGenerator
) -> Banknote:
	var note := make_genuine(currency, rng)
	note.levels = buy_levels(currency, budget, config, rng)
	if note.level(GameEnums.Feature.SERIAL) < CurrencyData.MAX_LEVEL:
		note.issuer_code = invalid_issuer_code(currency, rng)
	return note


static func buy_levels(
	currency: CurrencyData, budget: int, config: ShiftConfig, rng: RandomNumberGenerator
) -> Dictionary:
	var order := currency.features.duplicate()
	var priority := {}
	for data in order:
		priority[data] = float(data.tool) + rng.randf() * config.cpu_order_noise
	order.sort_custom(
		func(a: FeatureData, b: FeatureData) -> bool: return priority[a] < priority[b]
	)

	var levels := {}
	var remaining := budget
	for data in order:
		var target := CurrencyData.MAX_LEVEL
		if rng.randf() < config.cpu_partial_chance:
			target -= 1
		var bought := mini(target, floori(float(remaining) / data.cost_per_level))
		levels[data.feature] = bought
		remaining -= bought * data.cost_per_level
	for data in order:
		var extra := mini(
			CurrencyData.MAX_LEVEL - levels[data.feature],
			floori(float(remaining) / data.cost_per_level)
		)
		levels[data.feature] += extra
		remaining -= extra * data.cost_per_level

	var last: FeatureData = order.back()
	if levels.values().min() == CurrencyData.MAX_LEVEL:
		levels[last.feature] -= 1
	return levels


static func invalid_issuer_code(currency: CurrencyData, rng: RandomNumberGenerator) -> String:
	var base: String = currency.issuer_codes[rng.randi_range(0, currency.issuer_codes.size() - 1)]
	var code := base
	while currency.issuer_codes.has(code):
		code = base
		var index := rng.randi_range(0, code.length() - 1)
		code[index] = CODE_LETTERS[rng.randi_range(0, CODE_LETTERS.length() - 1)]
	return code
