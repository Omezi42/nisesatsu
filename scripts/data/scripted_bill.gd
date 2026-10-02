class_name ScriptedBill
extends Resource

## 研修シフトなどで並びを固定する紙幣1枚(GameDesign.md 6.2節)

@export var fake := false
@export var defect_feature: GameEnums.Feature = GameEnums.Feature.PATTERN
@export var defect_level := 1
@export_multiline var hint := ""
