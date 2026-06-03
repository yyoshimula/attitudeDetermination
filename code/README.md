# code/ — 宇宙機の姿勢決定 サンプルプログラム

実験装置の制御と、固有空間法による姿勢推定・3軸比較のための MATLAB プログラム群です。
実験全体の概要・進め方はリポジトリ直下の [`README.md`](../README.md)、詳細な手順は [`docs/main.pdf`](../docs/main.pdf) を参照してください。

## 解析の流れ（3軸評価）

学習データに **CG レンダリング画像（配布済み）** と **実画像** の両方を使い、次の3軸で精度を比較します。

1. **CG学習 vs 実画像学習**（同一テスト条件）→ Sim2Real ドメインギャップ
2. **基準条件 vs 条件変更**（同一学習）→ 条件汎化性能
3. **CG学習 × 条件変更 vs 実画像学習 × 条件変更** → 学習ソースが頑健性に与える影響

実験室では基準条件・条件変更（光源方向を変える）の2セットの実画像評価データを取得します。

## ファイル構成

```
code/
├── controller.mlapp        # 実験装置制御 GUI（App Designer）
├── mainExp.m               # 実験実行のメインスクリプト
├── mainEigenSpace.mlx      # 固有空間法（基本版・Live Script）
├── eigenSpaceCG.m          # 固有空間法（CG/実画像 × 基準/条件変更の3軸比較）
├── eigenSpaceCG_result.png # eigenSpaceCG.m の出力例
├── eigenSpace/             # 固有空間法の補助スクリプト（testPCA.m など）
├── setCam.m / setRA.m      # カメラ / ロボットアームの初期設定
├── liveSnap.m              # ライブ撮影
├── updatePreview.m         # プレビュー更新
├── checkAPI.m              # 装置 API 接続確認
├── testRobotArm.m          # ロボットアーム動作テスト
├── changeNames.m           # 撮影画像のファイル名を連番に整理
├── imgaussian.m            # 画像ガウシアンフィルタ
└── testShot.jpeg           # テスト撮影画像
```

> 配布データ（CG学習画像・実験日別データ）はリポジトリ直下の `data/` にあります。
> CG学習データは `data/cg_train/`（画像 + `labels.csv`）として同梱済みです。

## 主要ファイル

### 実験
- **`controller.mlapp`** — 実験装置制御用の GUI アプリ。これを開いて撮影する。
- **`mainExp.m`** — 実験実行のメインスクリプト。
- **`setCam.m` / `setRA.m`** — カメラ・ロボットアームの初期設定。
- **`liveSnap.m` / `updatePreview.m`** — ライブ撮影・プレビュー。
- **`testRobotArm.m` / `checkAPI.m`** — 装置の動作・接続確認。

### 解析（姿勢推定）
- **`mainEigenSpace.mlx`** — 固有空間法の基本実装（Live Script）。手法の理解用。
- **`eigenSpaceCG.m`** — CG学習 / 実画像学習 × 基準 / 条件変更の **3軸比較**を行う解析スクリプト。
  学習データと評価データのパスを差し替えて実行する。

### ユーティリティ
- **`changeNames.m`** — 撮影画像のファイル名を連番に整理する。
- **`imgaussian.m`** — 画像にガウシアンフィルタを適用する関数。

## 使い方

1. `controller.mlapp` を開いて実験装置を制御し、基準条件・条件変更の評価画像を撮影
2. 撮影画像を `data/` 配下に保存し、必要なら `changeNames.m` でファイル名を整理
3. `eigenSpaceCG.m` を実行して、3軸の精度比較を確認

## 必要環境

- MATLAB（Image Processing Toolbox）
- 実験装置: ロボットアーム UFACTORY LITE 6 / 平行光源 / リニアレール上カメラ
