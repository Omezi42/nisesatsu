#!/usr/bin/env bash
# 変更後の検証を1コマンドにまとめる: gdformat → gdlint → ヘッドレステスト → 起動スモーク。
# 引数なし: git で変更のある .gd だけを整形・lint する。--all: scripts/ と tools/ の全 .gd。
# --web: Web 書き出し(build/web/)と、書き出した pck に対するテストも回す(--all と併用可)。
# 出力は要点だけに絞る(ログ全文は logs/check_*.log)。
set -u
GODOT="${GODOT:-C:/Users/omezi/Documents/Godot_v4.6.2-stable_win64_console.exe}"
GODOT_TIMEOUT="${GODOT_TIMEOUT:-600}"
PY_SCRIPTS="C:/Users/omezi/AppData/Roaming/Python/Python314/Scripts"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p logs

ALL=0
WEB=0
for arg in "$@"; do
  case "$arg" in
    --all) ALL=1 ;;
    --web) WEB=1 ;;
  esac
done

if [ $ALL -eq 1 ]; then
  FILES=$(git ls-files -co --exclude-standard 'scripts/*.gd' 'scripts/**/*.gd' 'tools/*.gd' 'tools/**/*.gd' | grep -v '^tools/godot_apply_patch.gd$')
else
  FILES=$( (git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard) | sort -u | grep '\.gd$' | grep -v '^tools/godot_apply_patch.gd$' | grep -v '^\.agents/' | while read -r f; do [ -f "$f" ] && echo "$f"; done)
fi

status=0
if [ -n "$FILES" ]; then
  echo "== gdformat/gdlint ($(echo "$FILES" | wc -l) files)"
  "$PY_SCRIPTS/gdformat.exe" $FILES >/dev/null 2>&1 || true
  "$PY_SCRIPTS/gdlint.exe" $FILES > logs/check_lint.log 2>&1 || { status=1; cat logs/check_lint.log; }
else
  echo "== gdformat/gdlint: 変更された .gd なし"
fi

# 新しい class_name が .godot のキャッシュに無いと --script 起動が失敗する(docs/Pitfalls.md)
CLASS_CACHE=.godot/global_script_class_cache.cfg
missing=$(git ls-files -co --exclude-standard 'scripts/*.gd' 'scripts/**/*.gd' | xargs grep -h '^class_name ' | awk '{print $2}' | tr -d '\r' \
  | while read -r c; do grep -q "\"class\": &\"$c\"" "$CLASS_CACHE" 2>/dev/null || echo "$c"; done)
if [ -n "$missing" ]; then
  echo "== class_name の登録を更新 ($(echo "$missing" | wc -l) 件)"
  timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . --import > logs/check_import.log 2>&1
fi

echo "== headless tests"
timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . --script res://tools/tests/run_tests.gd > logs/check_tests.log 2>&1
grep -E "tests passed|FAILED|SCRIPT ERROR|Parse Error" logs/check_tests.log | head -20
grep -qE "FAILED|SCRIPT ERROR|Parse Error" logs/check_tests.log && status=1
grep -q "tests passed" logs/check_tests.log || status=1

echo "== startup smoke"
timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . --quit-after 120 > logs/check_smoke.log 2>&1
if grep -E "SCRIPT ERROR|Parse Error|Failed to load|ERROR:" logs/check_smoke.log | head -10 | grep -q .; then
  grep -E "SCRIPT ERROR|Parse Error|Failed to load|ERROR:" logs/check_smoke.log | head -10
  status=1
else
  echo "ok"
fi

if [ $WEB -eq 1 ]; then
  # .tres が .tres.remap になる差異は書き出した pck でしか出ない(docs/Pitfalls.md)
  echo "== web export"
  rm -rf build/web && mkdir -p build/web
  timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . --export-release "Web" build/web/index.html > logs/check_export.log 2>&1
  if [ -f build/web/index.pck ] && [ -f build/web/index.wasm ]; then
    echo "ok"
    echo "== tests on exported pck"
    timeout "$GODOT_TIMEOUT" "$GODOT" --headless --main-pack build/web/index.pck --script res://tools/tests/run_tests.gd > logs/check_pck.log 2>&1
    grep -E "tests passed|FAILED|SCRIPT ERROR|Parse Error" logs/check_pck.log | head -20
    grep -qE "FAILED|SCRIPT ERROR|Parse Error" logs/check_pck.log && status=1
    grep -q "tests passed" logs/check_pck.log || status=1
  else
    echo "書き出しに失敗 (logs/check_export.log)"
    status=1
  fi
fi

[ $status -eq 0 ] && echo "== ALL OK" || echo "== NG (logs/check_*.log)"
exit $status
