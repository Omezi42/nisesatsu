#!/usr/bin/env bash
# unityroom のアイコン(build/unityroom_icon.gif)を作る。紙幣の描画は本体と同じ BanknotePainter を使う
set -eu
GODOT="${GODOT:-C:/Users/omezi/Documents/Godot_v4.6.2-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
rm -rf build/icon_frames
# 実際のピクセルが要るので --headless にしない(docs/Pitfalls.md)
timeout 300 "$GODOT" --path . -s res://tools/render_icon_frames.gd > /dev/null 2>&1
python tools/make_icon_gif.py
