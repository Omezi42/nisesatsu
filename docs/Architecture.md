# Architecture

## 1. ディレクトリ
| 場所 | 中身 |
|---|---|
| `data/` | `.tres` のデータ。通貨 `lumeria.tres`、シフト設定 `shift_default.tres`、`features/` `tools/` `denominations/` |
| `scripts/data/` | Resource の定義と enum(`GameEnums`) |
| `scripts/core/` | UIから独立した規則。ヘッドレステストで回し、将来はサーバー側でも同じ判定を再現する |
| `scripts/ui/` | 画面。UIはコードで組み、シーンは `scenes/main.tscn` の1つだけ |
| `tools/` | `check.sh`、テスト、シーン編集用のパッチスクリプト |

## 2. データ(`scripts/data/`)
| クラス | 役割 |
|---|---|
| `GameEnums` | `Feature` / `Tool` / `ViewMode` / `Verdict`。**値は末尾にだけ足す**(`.tres` が整数で保存する) |
| `FeatureData` | セキュリティ要素1つ。見る道具、1段あたりの費用、再現度ごとの欠陥の説明 |
| `ToolData` | 道具1つ。シフトあたりの使用回数 |
| `DenominationData` | 券種。額面と地色 |
| `CurrencyData` | 通貨。券種・要素・発行局コード一覧・微小文字。`MAX_LEVEL`(=3、本物の再現度) |
| `ShiftConfig` | 1シフトの枚数・偽札の割合・持ち時間・道具・得点・CPUの予算 |

要素や道具を足すときは `.tres` を足して `CurrencyData` / `ShiftConfig` の配列へ入れる。描き分けだけは `BanknotePainter` に足す。

## 3. 規則(`scripts/core/`)
| クラス | 役割 |
|---|---|
| `Banknote` | 紙幣1枚。券種、記番号、要素ごとの再現度。全要素が `MAX_LEVEL` なら本物 |
| `BanknoteFactory` | 本物の生成と、CPUの偽造(GameDesign.md 6.1節)。予算で再現度を買い、記番号の再現度が足りなければ一覧外の発行局コードにする |
| `InspectionShift` | 1シフトの進行。紙幣の列、道具の残り回数と「この紙幣で使用済み」、判定と得点 |

乱数はすべて呼び出し側が渡す `RandomNumberGenerator` を使う(テストで再現できるようにするため)。

## 4. 画面(`scripts/ui/`)
| クラス | 役割 |
|---|---|
| `main.gd` | タイトル → 鑑定シフト → 結果 の切り替え |
| `InspectorScreen` | 窓口。持ち時間、道具ボタン、受理/拒否。道具ボタンは `ShiftConfig.tools` から作る |
| `ReferenceBook` | 見本帳。固定の種で作った本物の見本と発行局コード一覧 |
| `ResultScreen` | 1枚ずつの正誤と欠陥の説明 |
| `BanknoteView` | 紙幣の表示とルーペ。通常表示用(1.2倍)とルーペ用(4倍)の2つの SubViewport に同じ紙幣を描き、ルーペは高解像度側を円形に切り抜いて重ねる。描き直しは紙幣・表示モードが変わったときだけ |
| `BanknotePainter` | 紙幣をコードで描く。論理サイズ 600×300 の座標で書き、`px_scale` 倍で描く。文字は拡大後のピクセルサイズで描く(縮小した文字を拡大するとぼやけるため) |
| `UiKit` | ボタン・ラベル・色の共通部品 |

## 5. 検証
- `bash tools/check.sh`: gdformat → gdlint → `tools/tests/run_tests.gd` → 起動スモーク
- `run_tests.gd` は `scripts/core/` とデータの整合を見る(偽札は必ず欠陥を持つ、予算を超えない、道具の回数、得点)
