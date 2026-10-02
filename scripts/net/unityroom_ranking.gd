class_name UnityroomRanking
extends Node

## unityroom のスコアランキングへ得点を送る。Web 版でだけ動く

signal finished(ok: bool)

const CONFIG_PATH := "res://data/ranking.tres"
const SECRET_PATH := "res://data/secret/unityroom_secret.tres"
const API_ORIGIN := "https://unityroom.com"
const SCORE_PATH := "/gameplay_api/v1/scoreboards/%d/scores"
const TIMEOUT_SECONDS := 10.0

var _config: RankingConfig = load(CONFIG_PATH)
var _key := ""


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	var secret: RankingSecret = load(SECRET_PATH)
	if secret != null:
		_key = secret.hmac_key.strip_edges()


func is_available() -> bool:
	return not _key.is_empty()


func should_send(score: int) -> bool:
	return score >= _config.min_score


## 送り終えたら finished を出す。送れない環境では何もしない
func send(score: int) -> void:
	if not is_available():
		return
	var path := SCORE_PATH % _config.scoreboard_id
	var timestamp := str(int(Time.get_unix_time_from_system()))
	var score_text := str(score)
	var headers := PackedStringArray(
		[
			"Content-Type: application/x-www-form-urlencoded",
			"X-Unityroom-Signature: %s" % signature(_key, path, timestamp, score_text),
			"X-Unityroom-Timestamp: %s" % timestamp,
		]
	)
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_SECONDS
	add_child(http)
	var body := "score=%s" % score_text.uri_encode()
	if http.request(_origin() + path, headers, HTTPClient.METHOD_POST, body) != OK:
		http.queue_free()
		finished.emit(false)
		return
	var response: Array = await http.request_completed
	http.queue_free()
	var code: int = response[1]
	finished.emit(response[0] == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300)


## 署名の元は "POST\n{パス}\n{UNIX秒}\n{スコア}"。キーは Base64
static func signature(
	key_base64: String, path: String, timestamp: String, score_text: String
) -> String:
	var key := Marshalls.base64_to_raw(key_base64)
	if key.is_empty():
		return ""
	var hmac := HMACContext.new()
	if hmac.start(HashingContext.HASH_SHA256, key) != OK:
		return ""
	hmac.update(("POST\n%s\n%s\n%s" % [path, timestamp, score_text]).to_utf8_buffer())
	return hmac.finish().hex_encode()


## ゲームは unityroom のホストから配信されるので、同じホストへ送る
static func _origin() -> String:
	var host := str(JavaScriptBridge.eval("window.location.hostname"))
	return API_ORIGIN if host.is_empty() else "https://" + host
