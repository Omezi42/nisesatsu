class_name CurrencyData
extends Resource

const MAX_LEVEL := 3

@export var currency_name := ""
@export var unit := ""
@export var denominations: Array[DenominationData] = []
@export var features: Array[FeatureData] = []
@export var issuer_codes: Array[String] = []
@export var microtext := ""


func feature_data(feature: GameEnums.Feature) -> FeatureData:
	for data in features:
		if data.feature == feature:
			return data
	return null


func full_cost() -> int:
	var total := 0
	for data in features:
		total += data.cost_per_level * MAX_LEVEL
	return total
