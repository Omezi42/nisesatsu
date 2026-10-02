class_name Banknote
extends RefCounted

const SERIAL_DIGITS := 6

var denomination_index := 0
var issuer_code := ""
var serial_number := 0
## GameEnums.Feature -> 再現度(0〜CurrencyData.MAX_LEVEL)
var levels := {}
## 紙の斑点や色ずれの向きなど、描画だけに使う揺らぎの種
var art_seed := 0


func level(feature: GameEnums.Feature) -> int:
	return levels.get(feature, CurrencyData.MAX_LEVEL)


func is_genuine() -> bool:
	return defects().is_empty()


func defects() -> Array[GameEnums.Feature]:
	var result: Array[GameEnums.Feature] = []
	for feature: GameEnums.Feature in levels:
		if levels[feature] < CurrencyData.MAX_LEVEL:
			result.append(feature)
	result.sort()
	return result


func serial_text() -> String:
	return "%s %0*d" % [issuer_code, SERIAL_DIGITS, serial_number]
