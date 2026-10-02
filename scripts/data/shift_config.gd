class_name ShiftConfig
extends Resource

@export var title := "鑑定窓口"

@export var bill_count := 12
@export var fake_min := 4
@export var fake_max := 6
## false なら判定までの秒数を計らず、速さボーナスも付けない
@export var measures_time := true
@export var tools: Array[ToolData] = []
@export var records_best_score := true
## 空でなければCPUの偽造の代わりにこの並びで出す(bill_count と偽札の割合は使わない)
@export var scripted_bills: Array[ScriptedBill] = []

@export_group("Score")
@export var score_reject_fake := 100
@export var score_accept_genuine := 50
@export var score_accept_fake := -150
@export var score_reject_genuine := -100
## 正解したときだけ足す。経過1秒ごとに減り、0未満にはしない
@export var speed_bonus_max := 50
@export var speed_bonus_per_second := 2

@export_group("CPU Forger")
@export var cpu_budget_start := 14
@export var cpu_budget_end := 24
## 0 なら目視で見られる要素から順に買う。大きいほど買う順がばらつく
@export var cpu_order_noise := 2.5
## 要素を本物まで上げずに1段手前で止める確率(わずかな欠陥の偽札を混ぜる)
@export var cpu_partial_chance := 0.3
