# Architecture

## 1. ディレクトリ
| 場所 | 中身 |
|---|---|
| `data/` | `.tres` のデータ。通貨 `lumeria.tres`、シフト設定 `shift_default.tres`、`features/` `tools/` `denominations/` |
| `scripts/data/` | Resource の定義と enum(`GameEnums`) |
| `scripts/core/` | UIから独立した規則。ヘッドレステストで回し、将来はサーバー側でも同じ判定を再現する |
| `scripts/ui/` | 画面。UIはコードで組み、シーンは `scenes/main.tscn` の1つだけ |
| `tools/` | `check.sh`、テスト、シーン編集用のパッチスクリプト |
| `tools/make_icon.sh` | unityroom のアイコンGIF。`render_icon_frames.gd` が本体と同じ描画でコマを書き出し、`make_icon_gif.py`(Pillow)がまとめる |
| `build/web/` | Web 書き出しの出力(git 管理外)。プリセットは `export_presets.cfg` の「Web」(スレッドなし) |

## 2. データ(`scripts/data/`)
| クラス | 役割 |
|---|---|
| `GameEnums` | `Feature` / `Tool` / `ViewMode` / `Verdict`。**値は末尾にだけ足す**(`.tres` が整数で保存する) |
| `FeatureData` | セキュリティ要素1つ。見る道具、1段あたりの費用、再現度ごとの欠陥の説明 |
| `ToolData` | 道具1つ。表示名 |
| `DenominationData` | 券種。額面と地色 |
| `CurrencyData` | 通貨。券種・要素・発行局コード一覧・微小文字。`MAX_LEVEL`(=3、本物の再現度) |
| `ScriptedBill` | 並びを固定する紙幣1枚(本物か、欠ける要素と再現度、ヒント) |
| `ShiftConfig` | 1シフトの枚数・偽札の割合・道具・得点(速さボーナスを含む)・CPUの予算。研修シフトは別の `.tres`(`shift_training.tres`)で、固定の紙幣の並びとヒントを持ち、秒数を計らない(`measures_time = false`) |

要素や道具を足すときは `.tres` を足して `CurrencyData` / `ShiftConfig` の配列へ入れる。描き分けだけは `BanknotePainter` に足す。

## 3. 規則(`scripts/core/`)
| クラス | 役割 |
|---|---|
| `Banknote` | 紙幣1枚。券種、記番号、要素ごとの再現度。全要素が `MAX_LEVEL` なら本物 |
| `BanknoteFactory` | 本物の生成と、CPUの偽造(GameDesign.md 6.1節)。予算で再現度を買い、記番号の再現度が足りなければ一覧外の発行局コードにする |
| `InspectionShift` | 1シフトの進行。紙幣の列、判定と得点。判定には経過秒数を渡し、正解なら速さボーナスを足す(秒数の計測はUI側)。紙幣の並びが `ShiftConfig` で固定されていればCPUの偽造の代わりにそれを使う |
| `BestScore` | ベストスコアの読み書き(`user://`)。研修シフトは記録しない |

乱数はすべて呼び出し側が渡す `RandomNumberGenerator` を使う(テストで再現できるようにするため)。

## 4. 画面(`scripts/ui/`)
| クラス | 役割 |
|---|---|
| `main.gd` | タイトル(研修 / 本番シフト・ベストスコア) → 鑑定シフト → 結果 の切り替え |
| `InspectorScreen` | 窓口。経過秒数、道具ボタン、受理/拒否、研修のヒント。道具ボタンは `ShiftConfig.tools` から作る。フォーカスを失ったら(`NOTIFICATION_APPLICATION_FOCUS_OUT`)計測を止めて紙幣を隠す一時停止画面を出す。1フレームで足す時間には上限を付ける(復帰直後の大きな `delta` を数えない) |
| `ReferenceBook` | 見本帳。固定の種で作った本物の見本と発行局コード一覧 |
| `ResultScreen` | 1枚ずつの正誤・秒数・速さボーナスと欠陥の説明、合計時間、ベストスコアと更新の表示 |
| `BanknoteView` | 紙幣の表示とルーペ。通常表示用(1.2倍)とルーペ用(4倍)の2つの SubViewport に同じ紙幣を描き、ルーペは高解像度側を円形に切り抜いて重ねる。描き直しは紙幣・表示モードが変わったときだけ |
| `BanknotePainter` | 紙幣をコードで描く。論理サイズ 600×300 の座標で書き、`px_scale` 倍で描く。文字は拡大後のピクセルサイズで描く(縮小した文字を拡大するとぼやけるため) |
| `UiKit` | ボタン・ラベル・色の共通部品 |

## 5. 検証
- `bash tools/check.sh`: gdformat → gdlint → `tools/tests/run_tests.gd` → 起動スモーク
- `bash tools/check.sh --web`: 上に加えて Web 書き出しと、書き出した pck に対する `run_tests.gd`
- 書き出した版をブラウザで見るときは `.claude/launch.json` の `web-build`(`build/web/` を 8060 番で配信)
- `run_tests.gd` は `scripts/core/` とデータの整合を見る(偽札は必ず欠陥を持つ、予算を超えない、得点と速さボーナス、研修の並び、ベストスコア)
