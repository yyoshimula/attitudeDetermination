# 航空宇宙工学実験: 宇宙機の姿勢決定 資料

サンプルプログラムやデータを置いてます．

## フォルダ構成

```
attitudeDetermination/
├── docs/                    # 実験資料・ドキュメント
│   ├── main.tex            # 実験手順書LaTeX原稿
│   ├── main.pdf            # 実験手順書PDF
│   └── yoshimura.bib       # 参考文献データベース
├── data/                    # 実験データ
│   ├── 20250502/           # 実験日別データ（例：2025年5月2日）
│   ├── 20250507/           # 実験日別データ（例：2025年5月7日）
│   └── ...                 # その他の実験日データ
├── controller.mlapp        # MATLAB App Designer コントローラ
├── mainEigenSpace.mlx      # 固有空間法メインプログラム（Live Script）
├── mainExp.m               # 実験メインプログラム
├── changeNames.m           # ファイル名変更ツール
├── setCam.m               # カメラ設定
├── setRA.m                # ロボットアーム設定
├── liveSnap.m             # ライブ撮影
├── updatePreview.m        # プレビュー更新
├── testRobotArm.m         # ロボットアーム動作テスト
├── checkAPI.m             # API接続確認
├── imgaussian.m           # 画像ガウシアン処理
└── testShot.jpeg          # テスト撮影画像
```

## 主要ファイルの説明

### 実験関連
- `controller.mlapp`: 実験装置制御用のMATLAB GUI アプリケーション
- `mainExp.m`: 実験実行のメインスクリプト
- `mainEigenSpace.mlx`: 固有空間法による姿勢決定の実装（Live Script形式）

### データ処理
- `changeNames.m`: 撮影画像のファイル名を連番に変更するユーティリティ
- `imgaussian.m`: 画像にガウシアンフィルタを適用する関数

### ハードウェア制御
- `setCam.m`: カメラパラメータの設定
- `setRA.m`: ロボットアームの初期設定
- `liveSnap.m`: リアルタイム撮影機能
- `testRobotArm.m`: ロボットアーム動作の確認・テスト

### ドキュメント
- `docs/main.pdf`: 実験手順書（日本語）
- `docs/main.tex`: 実験手順書のLaTeX原稿

## 使用方法

1. `controller.mlapp`を開いて実験装置を制御
2. `mainExp.m`で実験を実行
3. `data/`フォルダに撮影画像を保存
4. `changeNames.m`でファイル名を整理
5. `mainEigenSpace.mlx`で姿勢決定を実行

詳細な実験手順は`docs/main.pdf`を参照してください。
