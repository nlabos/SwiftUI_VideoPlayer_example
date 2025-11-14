# コードスタイルと規約

## SwiftUIスタイル
- **命名規約**: 
  - 構造体名: PascalCase (例: `ContentView`, `VideoPlayerApp`)
  - プロパティ名: camelCase (例: `selectedItem`, `isPlaying`)
  - メソッド名: camelCase (例: `loadVideo(from:)`)

## 状態管理
- `@State` プロパティラッパーを使用してビューの状態を管理
- `@MainActor` 属性を非同期メソッドに適用してUIスレッドで実行

## コード構造
- 1ファイル1ビュー/構造体の原則
- プライベートメソッドには `private` アクセス修飾子を使用
- 非同期処理には `async/await` パターンを使用

## UI設計パターン
- VStackを使用した縦方向レイアウト
- システムアイコンの活用（SF Symbols）
- モディファイアチェーンによるスタイリング
- 角丸やシャドウを使用した現代的なデザイン

## エラーハンドリング
- do-catch文を使用した例外処理
- コンソールへのエラーログ出力
- ユーザーフレンドリーなエラー表示（必要に応じて）