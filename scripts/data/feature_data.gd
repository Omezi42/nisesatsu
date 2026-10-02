class_name FeatureData
extends Resource

@export var feature: GameEnums.Feature = GameEnums.Feature.PATTERN
@export var display_name := ""
@export var tool: GameEnums.Tool = GameEnums.Tool.NAKED_EYE
@export var cost_per_level := 1
## 再現度 0 / 1 / 2 のときの欠陥の説明(結果画面に出す)
@export var defect_descriptions: Array[String] = []


func defect_description(level: int) -> String:
	if level < 0 or level >= defect_descriptions.size():
		return ""
	return defect_descriptions[level]
