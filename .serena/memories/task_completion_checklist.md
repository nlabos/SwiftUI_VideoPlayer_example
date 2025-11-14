# タスク完了時の実行手順

## 開発完了後のチェックリスト

### 0. テスト環境準備
```bash
# シミュレータのカメラロールに動画を注入
# 現在起動中のシミュレータのIDを取得
DEVICE_ID=$(xcrun simctl list devices | grep "Booted" | grep -o '[A-F0-9-]\{36\}')

# テスト用動画ファイルを追加
xcrun simctl addmedia "$DEVICE_ID" ~/Movies/*.mp4 ~/Movies/*.mov

# または手動でドラッグ&ドロップ
# 1. シミュレータの写真アプリを開く
# 2. Finderから動画ファイルをドラッグ&ドロップ
```

### 1. コード品質チェック
```bash
# Swiftコンパイルエラーのチェック
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build

# 静的解析の実行（SwiftLint使用可能な場合）
swiftlint lint

# フォーマットの確認（SwiftFormat使用可能な場合）
swift-format lint . --recursive
```

### 2. 機能テスト
- [ ] アプリ起動確認
- [ ] ビデオ選択機能の動作確認
- [ ] 再生/一時停止ボタンの動作確認
- [ ] リセットボタンの動作確認
- [ ] 異なるビデオファイル形式での動作確認

### 3. デバイステスト
```bash
# シミュレーターでのテスト
xcodebuild test -project VideoPlayer.xcodeproj -scheme VideoPlayer \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# 複数デバイスサイズでの確認
# iPhone SE、iPhone 15、iPad等での表示確認
```

### 4. パフォーマンスチェック
- メモリリーク検出（Xcode Instrumentsの使用）
- 大容量ビデオファイルでの動作確認
- バックグラウンド/フォアグラウンド切り替えテスト

### 5. プロジェクトクリーンアップ
```bash
# ビルドキャッシュのクリア
xcodebuild clean -project VideoPlayer.xcodeproj

# 不要なファイルの削除
find . -name ".DS_Store" -delete
```

### 6. バージョン管理
```bash
# 変更のコミット
git add .
git commit -m "作業内容の詳細な説明"

# プッシュ（リモートリポジトリがある場合）
git push origin main
```

## 追加考慮事項
- Info.plistでのプライバシー許可設定確認
- App Storeガイドライン準拠確認（配布予定の場合）
