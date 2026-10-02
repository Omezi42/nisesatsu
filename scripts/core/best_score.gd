class_name BestScore
extends RefCounted

## 本番シフトの最高得点(GameDesign.md 6章)。保存先はテストから差し替えられる

const DEFAULT_PATH := "user://best_score.cfg"
const SECTION := "inspector"
const KEY := "best"


static func has_record(path := DEFAULT_PATH) -> bool:
	return _load(path).has_section_key(SECTION, KEY)


static func best(path := DEFAULT_PATH) -> int:
	return _load(path).get_value(SECTION, KEY, 0)


## 記録を更新したら true
static func submit(score: int, path := DEFAULT_PATH) -> bool:
	var file := _load(path)
	if file.has_section_key(SECTION, KEY) and score <= int(file.get_value(SECTION, KEY)):
		return false
	file.set_value(SECTION, KEY, score)
	file.save(path)
	return true


static func _load(path: String) -> ConfigFile:
	var file := ConfigFile.new()
	file.load(path)
	return file
