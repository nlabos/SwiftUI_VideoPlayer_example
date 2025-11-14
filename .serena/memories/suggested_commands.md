# 開発コマンド集

## Xcode プロジェクト操作
```bash
# プロジェクトをXcodeで開く
open VideoPlayer.xcodeproj

# Xcodeワークスペースを開く（SPM使用時）
open VideoPlayer.xcodeproj/project.xcworkspace
```

## ビルドとテスト
```bash
# コマンドラインからビルド
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer -destination 'platform=iOS Simulator,name=iPhone 15' build

# シミュレーターでテスト実行
xcodebuild test -project VideoPlayer.xcodeproj -scheme VideoPlayer -destination 'platform=iOS Simulator,name=iPhone 15'

# デバイスでビルド
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer -destination 'generic/platform=iOS' build
```

## 静的解析とフォーマット
```bash
# SwiftLintの実行（インストール済みの場合）
swiftlint lint

# SwiftFormatの実行（インストール済みの場合）
swift-format . --recursive --in-place
```

## macOSシステム固有コマンド
```bash
# ファイル検索
find . -name "*.swift" -type f

# パターン検索
grep -r "import" --include="*.swift" .

# ディレクトリ内容確認
ls -la

# ファイルサイズ確認
du -sh VideoPlayer/
```

## 依存関係管理
現在のプロジェクトは標準的なAppleフレームワークのみを使用しているため、外部依存関係管理ツールは不要です。