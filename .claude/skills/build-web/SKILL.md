---
name: build-web
description: unityroom 向けに Web 書き出しを作り、書き出した版でテストを回す。「ビルドして」「Web版を書き出して」「unityroom に上げるものを作って」で使う
---

# Web 書き出し(unityroom 向け)

1. `bash tools/check.sh --web --all` を回し、`== ALL OK` を確かめる
   - Web 書き出し(`export_presets.cfg` の「Web」、GL Compatibility・スレッドなし)を `build/web/` に出す
   - 書き出した `build/web/index.pck` に対してヘッドレステストを回す
2. NG なら `logs/check_export.log` / `logs/check_pck.log` を見て直す。直したら 1 からやり直す
3. ブラウザで動きを見るときは、Browser ペインの `preview_start` で `web-build`(`.claude/launch.json`)を起動する。
   1回目のクリックは canvas のフォーカスに使われてボタンに届かないことがある
4. 画面を撮ったら `SendUserFile` でユーザーに渡し、見た目の判断はユーザーに任せる
5. ユーザーに渡すもの: `build/web/` の中身一式(`index.html` `index.js` `index.wasm` `index.pck` ほか)。
   アップロードはユーザーが行う。`build/` は git に入れない
